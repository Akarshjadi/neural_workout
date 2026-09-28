import 'dart:convert';
import 'dart:async';

import 'package:fsrs/fsrs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/model.dart';

import '../data/app_database.dart';
import '../models/blurt_score.dart';
import '../models/note.dart';
import '../models/pathway_record.dart';
import '../models/session.dart';
import '../models/thought.dart';
import '../models/workout_session.dart';
import '../services/blurt_scorer.dart';
import '../services/export_service.dart';
import '../services/fsrs_engine.dart';
import '../services/local_ai_scorer.dart';
import '../services/metrics_service.dart';
import '../services/notification_service.dart';
import '../services/pathway_service.dart';
import '../services/ranking_service.dart';
import '../services/streak_service.dart';
import '../services/suggestion_service.dart';
import '../models/break_record.dart';
import '../services/break_service.dart';
import '../services/strategy_profile_service.dart';
import '../models/daily_checkin.dart';
import '../models/capability.dart';
import '../services/capability_engine.dart';
import '../services/plasticity_service.dart';
import '../models/delayed_outcome.dart';
import '../models/error_record.dart';
import '../models/feedback_record.dart';
import '../models/focus_integrity.dart';
import '../models/intervention.dart';
import '../models/knowledge_evidence.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import '../services/adaptive_intervention_service.dart';
import '../services/ai_scaffolding_service.dart';
import '../services/cognition_engine.dart';
import '../services/context_focus_service.dart';
import '../services/delayed_outcome_service.dart';
import '../services/experiment_service.dart';
import '../services/feedback_diagnosis_service.dart';
import '../services/research_catalog.dart';
import '../services/retrieval_engine.dart';
import '../services/session_policy_engine.dart';

import '../widgets/visuals/multidimensional_evidence_profile.dart';

class AppState extends ChangeNotifier {
  final AppDatabase db;
  final FsrsEngine fsrs = FsrsEngine();
  PathwayService pathways = PathwayService();
  final StreakService streakSvc = StreakService();
  final BreakService breakSvc = BreakService();
  final LocalAiScorer _aiScorer = LocalAiScorer();
  final MetricsService metricsSvc = MetricsService();
  final RankingService rankingSvc = RankingService();

  /// Cognitive Learning Services
  final SessionPolicyEngine sessionPolicy = const SessionPolicyEngine();
  final RetrievalEngine retrievalEngine = const RetrievalEngine();
  final FeedbackDiagnosisService feedbackService = const FeedbackDiagnosisService();
  final AdaptiveInterventionService adaptiveIntervention = const AdaptiveInterventionService();
  final AiScaffoldingService aiScaffolding = const AiScaffoldingService();
  final DelayedOutcomeService delayedOutcomeSvc = const DelayedOutcomeService();
  final ContextFocusService contextFocusSvc = const ContextFocusService();
  final ExperimentService experimentSvc = const ExperimentService();

  /// Phase 6 — Notifications & suggestions.
  final NotificationService notificationSvc = NotificationService();
  final SuggestionService suggestionSvc = SuggestionService();

  /// Phase 3 — Export.
  final ExportService exportSvc = ExportService();

  /// Phase 1 — User toggle for AI scoring (persisted in settings).
  bool aiEnabled = true;

  /// Phase 5 — Cached evidence score.
  double _overallScore = 0;

  /// Single aggregate evidence score across retrieval, retention, links, and pathways.
  double get evidenceScore => _overallScore;

  /// @Deprecated('Renamed to evidenceScore')
  @Deprecated('Renamed to evidenceScore')
  double get overallScore => _overallScore;

  /// Phase 6 — Cached suggestions.
  List<String> _suggestions = [];

  List<BreakRecord> _breaks = [];
  List<BreakRecord> get breaks => List.unmodifiable(_breaks);

  List<DailyCheckin> _checkins = [];
  List<DailyCheckin> get checkins => List.unmodifiable(_checkins);
  bool get hasCheckinToday => _checkins.any((r) => r.date.year == DateTime.now().year && r.date.month == DateTime.now().month && r.date.day == DateTime.now().day);

  bool focusPrimedThisSession = false;
  Future<void> markFocusPrimed() async {
    focusPrimedThisSession = true;
    notifyListeners();
  }

  int? _pageTrigger;
  int? get pageTrigger => _pageTrigger;
  void triggerPage(int index) {
    _pageTrigger = index;
    notifyListeners();
  }
  void consumePageTrigger() {
    _pageTrigger = null;
  }

  PlasticityProfile? _plasticityProfileCache;
  PlasticityProfile get plasticityProfile {
    _plasticityProfileCache ??= const PlasticityService().profile(
      blurts: blurtScores,
      checkins: _checkins,
      reviews: db.reviewHistory(),
      notes: notes,
      linkCounts: db.linkCountsByNote(),
      sessions: db.allSessions(),
      now: DateTime.now(),
    );
    return _plasticityProfileCache!;
  }

  List<CognitiveFactor>? _todayNeuroFactorsCache;

  /// Decomposed contributing cognitive factors for today's practice context (read-only diagnostic).
  List<CognitiveFactor> get todayNeuroFactors {
    _todayNeuroFactorsCache ??= CognitionEngine(today: DateTime.now()).neuroFactorsFor(
      notes: notes,
      sessions: db.allSessions(),
      blurts: blurtScores,
      reviews: db.reviewHistory(),
      breaks: _breaks,
    );
    return _todayNeuroFactorsCache!;
  }

  StrategyProfile? _strategyProfileCache;

  StrategyProfile? get strategyProfile {
    if (_strategyProfileCache == null) {
      final rawReviews = db.reviewHistory();
      final linkCounts = db.linkCountsByNote();
      int interleavedCount = 0;
      for (final r in rawReviews) {
        if ((r['was_interleaved'] as int? ?? 0) == 1) interleavedCount++;
      }
      _strategyProfileCache = StrategyProfileService().compute(
        blurts: blurtScores,
        notes: notes,
        sessions: sessions,
        reviewRows: rawReviews,
        interleavedCount: interleavedCount,
        totalReviewCount: rawReviews.length,
        linkCounts: linkCounts,
      );
    }
    return _strategyProfileCache;
  }

  List<LearningAttempt> get learningAttempts => db.allAttempts();
  List<ErrorRecord> get errorRecords => db.allErrors();
  List<DelayedOutcome> get delayedOutcomes => db.allDelayedOutcomes();
  ResearchCatalog get researchCatalog => ResearchCatalog();

  /// Item 34 — recurring error families in the last 14 days, worst first.
  /// Empty when nothing has repeated; a one-off mistake is not a pattern.
  List<({ErrorType type, int count})> get recurringErrors =>
      FeedbackDiagnosisService.recurringErrors(errorRecords);

  /// Item 33 — targets where correction appears to have overshot (pass ->
  /// confident failure -> confidence collapse). Consumed by the Back Cover.
  List<int> get hyperCorrectedTargets =>
      FeedbackDiagnosisService.hyperCorrectedTargets(learningAttempts);

  Future<void> logErrorRecord({
    required String conceptId,
    required ErrorType errorType,
    required String attemptId,
    required String userResponse,
    required String expectedResponse,
  }) async {
    final attId = int.tryParse(attemptId) ?? 0;
    final record = ErrorRecord(
      id: 0,
      attemptId: attId,
      type: errorType,
      source: DiagnosisSource.user,
      evidence: 'User self-diagnosis: ${errorType.label}',
      createdAt: DateTime.now(),
    );
    await db.insertError(record);
    notifyListeners();
  }


  List<EvidenceProfileDimension> get evidenceProfileDimensions {
    final attempts = learningAttempts;
    final blurts = blurtScores;
    
    // 1. Retrieval
    double retrievalVal = 0.5;
    if (blurts.isNotEmpty) {
      final avg = blurts.map((b) => b.scorePct).reduce((a, b) => a + b) / blurts.length;
      retrievalVal = (avg / 100.0).clamp(0.1, 1.0);
    } else if (attempts.isNotEmpty) {
      final valid = attempts.where((a) => !a.scorePct.isNaN);
      if (valid.isNotEmpty) {
        retrievalVal = (valid.map((a) => a.scorePct).reduce((a, b) => a + b) / valid.length / 100.0).clamp(0.1, 1.0);
      }
    }

    // 2. Retention
    double retentionVal = 0.5;
    if (delayedOutcomes.isNotEmpty) {
      final retained = delayedOutcomes.where((o) => o.correctness == Correctness.correct || o.correctness == Correctness.partiallyCorrect).length;
      retentionVal = (retained / delayedOutcomes.length).clamp(0.1, 1.0);
    } else if (notes.isNotEmpty) {
      final avgStab = notes.map((n) => n.card.stability ?? 1.0).reduce((a, b) => a + b) / notes.length;
      retentionVal = (avgStab / 30.0).clamp(0.1, 1.0);
    }

    // 3. Transfer
    final links = db.allLinks;
    final double transferVal = (links.length / (notes.isNotEmpty ? notes.length * 1.5 : 1.0)).clamp(0.1, 1.0);

    // 4. Application
    double applicationVal = (attempts.where((a) => a.testType == TestType.application || a.testType == TestType.transfer).length / (attempts.isNotEmpty ? attempts.length : 1)).clamp(0.1, 1.0);
    if (applicationVal < 0.2) applicationVal = 0.4;

    // 5. Calibration
    double calibVal = 0.7;
    final calibAttempts = attempts.where((a) => a.confidence != null && !a.scorePct.isNaN);
    if (calibAttempts.isNotEmpty) {
      double totalErr = 0.0;
      for (final a in calibAttempts) {
        totalErr += (a.confidence! - a.scorePct).abs();
      }
      final meanErr = totalErr / calibAttempts.length;
      calibVal = (1.0 - (meanErr / 100.0)).clamp(0.1, 1.0);
    }

    // 6. Error Recovery
    double recoveryVal = 0.6;
    if (errorRecords.isNotEmpty) {
      recoveryVal = 0.75;
    }

    // 7. Efficiency
    double efficiencyVal = 0.7;
    if (blurts.isNotEmpty) {
      final validSpeeds = blurts.map((b) => b.recallSpeedMs ?? 15000).toList();
      final avgSpeed = validSpeeds.reduce((a, b) => a + b) / validSpeeds.length;
      efficiencyVal = (1.0 - (avgSpeed / 60000.0)).clamp(0.2, 1.0);
    }

    // 8. Consistency
    final streak = todayReport()['streak'] as int? ?? 1;
    final double consistencyVal = (streak / 14.0).clamp(0.2, 1.0);

    return [
      EvidenceProfileDimension(label: 'Retrieval', value: retrievalVal, detail: '${(retrievalVal * 100).round()}% free & cued accuracy'),
      EvidenceProfileDimension(label: 'Retention', value: retentionVal, detail: '${(retentionVal * 100).round()}% delayed consolidation'),
      EvidenceProfileDimension(label: 'Transfer', value: transferVal, detail: '${links.length} cross-domain connections'),
      EvidenceProfileDimension(label: 'Application', value: applicationVal, detail: 'Contextual synthesis rate'),
      EvidenceProfileDimension(label: 'Calibration', value: calibVal, detail: '${(calibVal * 100).round()}% metacognitive alignment'),
      EvidenceProfileDimension(label: 'Error Rec', value: recoveryVal, detail: '${errorRecords.length} systematic corrections'),
      EvidenceProfileDimension(label: 'Efficiency', value: efficiencyVal, detail: 'Retrieval latency stability'),
      EvidenceProfileDimension(label: 'Consistency', value: consistencyVal, detail: '$streak-day session discipline'),
    ];
  }


  BreakStatus get breakStatus => breakSvc.computeStatus(records: _breaks, now: DateTime.now());

  /// User-grown synonym/alias table (issue 10): kebab concept -> alternatives.
  /// Loaded from the settings box at startup; grown via [addSynonymAlias].
  /// Persisted as JSON: {"concept": ["alt1", "alt2"], ...}.
  Map<String, List<String>> synonymAliases = {};

  /// Persisted user aliases (survive restarts). JSON map form.
  void _loadSynonymAliases() {
    final raw = db.getSetting('synonym_aliases');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final concept = entry.key.toString();
          final alts = (entry.value as List).map((e) => e.toString()).toList();
          if (concept.isNotEmpty && alts.isNotEmpty) {
            synonymAliases[concept] = alts;
          }
        }
      }
    } catch (e) {
      debugPrint('_loadSynonymAliases: corrupt alias setting: $e');
    }
  }

  /// Add a user-taught alias for a concept and persist it.
  Future<void> addSynonymAlias(String concept, String alias) async {
    final c = concept.trim().toLowerCase();
    final a = alias.trim();
    if (c.isEmpty || a.isEmpty) return;
    final current = [...(synonymAliases[c] ?? const <String>[])];
    if (current.contains(a)) return;
    synonymAliases[c] = [...current, a];
    _persistAliases();
    notifyListeners();
  }

  /// Remove a user-taught alias for a concept and persist the change.
  Future<void> removeSynonymAlias(String concept, String alias) async {
    final c = concept.trim().toLowerCase();
    final a = alias.trim();
    if (c.isEmpty || a.isEmpty) return;
    final current = [...(synonymAliases[c] ?? const <String>[])];
    if (!current.contains(a)) return;
    synonymAliases[c] = current.where((e) => e != a).toList();
    if (synonymAliases[c]!.isEmpty) {
      synonymAliases.remove(c);
    }
    _persistAliases();
    notifyListeners();
  }

  void _persistAliases() {
    db.setSetting('synonym_aliases', jsonEncode(synonymAliases));
  }

  // Loaded collections (refreshed on load / after mutations).
  List<Note> notes = [];
  List<Session> sessions = [];
  List<BlurtScore> blurtScores = [];
  List<PathwayRecord> pathwayRecords = [];
  List<Thought> thoughts = [];

  // In-progress workout wizard state (WIP held live here, autosaved via
  // Session.autosaveJson so a phone-call / OS kill loses seconds, not content).
  Session? activeSession;
  WorkoutSessionState? activeWorkout;
  int get activeStep => activeWorkout?.stepsCompleted ?? 0;

  // Becomes true the moment a session completes so the wizard can show its
  // "Session complete!" end state even though no in-progress session remains.
  bool completedRecently = false;

  AppState(this.db);

  /// Loads everything from the DB (call once at startup).
  Future<void> load() async {
    // DB reads are synchronous Hive lookups — the awaits are harmless but
    // pointless; kept minimal churn by not restructuring the loader.
    notes = db.allNotes();
    sessions = db.allSessions();
    blurtScores = db.allBlurtScores();
    pathwayRecords = db.pathwayRecords();
    thoughts = db.allThoughts();
    _loadBreaks();
    _loadCheckins();

    // Restore user-adjustable weekly targets from settings (issue 12).
    pathways = PathwayService(targets: _loadPathwayTargets());
    // Restore user-grown synonym aliases so scoring rewards user vocabulary.
    _loadSynonymAliases();

    // Phase 1 — Load AI toggle and init AI scorer.
    ResearchCatalog.ensureInitialized();
    aiEnabled = (db.getSetting('ai_enabled') ?? 'true') == 'true';
    try {
      await _initAiScorer();
    } catch (e, stackTrace) {
      // AI is optional — app must never fail to start because AI failed.
      debugPrint('AppState: AI init failed, using fallback: $e\n$stackTrace');
    }

    // Phase 6 — Init notifications and schedule due-card reminders.
    await notificationSvc.init();
    if (dueNotesList.isNotEmpty) {
      await notificationSvc.scheduleForDueCards(dueNotesList);
    }

    // Rehydrate the most recent mid-flight workout (steps < 8), even if an
    // absolute-latest session happened to complete (issue 14).
    final latest = db.latestInProgressSession();
    // Rehydrate a mid-flight workout (steps < 8) from its autosave blob so the
    // user resumes where they left off — step text and progress included.
    activeSession = latest != null && latest.stepsCompleted < 8 ? latest : null;
    activeWorkout = activeSession == null
        ? null
        : WorkoutSessionState.fromJson(activeSession!.autosaveJson);
    // Legacy sessions that predate autosave can't be fully resumed; drop them
    // rather than showing a broken half-session.
    if (activeWorkout == null) {
      activeSession = null;
    }

    // Phase 5 — Compute overall score.
    final linkCounts = db.linkCountsByNote();
    final reviewStats = computeReviewStats(db);
    _overallScore = rankingSvc.overallScore(
      blurts: blurtScores,
      notes: notes,
      pathways: pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );

    // Phase 6 — Compute suggestions.
    _suggestions = suggestionSvc.generateSuggestions(this);

    notifyListeners();
  }

  /// Phase 1 — Initialize AI scorer with persisted config.
  Future<void> _initAiScorer() async {
    final modelType = _modelTypeFromSetting(db.getSetting('ai_model'));
    final maxTokens =
        int.tryParse(db.getSetting('ai_max_tokens') ?? '') ?? 2048;
    final temperature =
        double.tryParse(db.getSetting('ai_temperature') ?? '') ?? 0.1;
    await _aiScorer.init(
      modelTypeOverride: modelType,
      maxTokensOverride: maxTokens,
      temperatureOverride: temperature,
    );
  }

  ModelType _modelTypeFromSetting(String? name) {
    switch (name) {
      case 'general':
        return ModelType.general;
      case 'deepSeek':
        return ModelType.deepSeek;
      case 'gemmaIt':
      default:
        return ModelType.gemmaIt;
    }
  }

  /// Phase 1 — Whether AI scoring is available.
  bool get isAiAvailable => aiEnabled && _aiScorer.isReady;

  /// Phase 1 — Toggle AI scoring on/off.
  Future<void> setAiEnabled(bool v) async {
    aiEnabled = v;
    db.setSetting('ai_enabled', '$v');
    notifyListeners();
  }

  /// Phase 6 — Deferred initialization of AI scorer and notifications off the startup path.
  void initDeferredServices() {
    unawaited(_initAiScorer().catchError((e, st) {
      debugPrint('initDeferredServices: AI init failed: $e\n$st');
    }));
    unawaited(notificationSvc.init().then((_) {
      if (dueNotesList.isNotEmpty) {
        notificationSvc.scheduleForDueCards(dueNotesList);
      }
    }).catchError((e, st) {
      debugPrint('initDeferredServices: notification init failed: $e\n$st');
    }));
  }

  /// Review history sorted by date descending (for analytics screen).
  List<Map<String, dynamic>> get sortedReviewHistory {
    final rows = db.reviewHistory();
    rows.sort((a, b) => ((b['date'] as String?) ?? '').compareTo((a['date'] as String?) ?? ''));
    return rows;
  }

  /// Recent blurts sorted by date descending (for analytics screen).
  List<BlurtScore> get sortedRecentBlurts {
    final sorted = List<BlurtScore>.from(blurtScores);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Phase 7 — Update AI model config and reinitialize.
  Future<void> setAiConfig({
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    if (model != null) db.setSetting('ai_model', model);
    if (maxTokens != null) db.setSetting('ai_max_tokens', '$maxTokens');
    if (temperature != null) db.setSetting('ai_temperature', '$temperature');
    await _initAiScorer();
    notifyListeners();
  }

  Map<String, int> _loadPathwayTargets() {
    final out = <String, int>{};
    for (final name in const [
      'retrieval',
      'compression',
      'association',
      'explanation',
      'context',
    ]) {
      final v = int.tryParse(db.getSetting('target_$name') ?? '');
      if (v != null && v > 0) out[name] = v;
    }
    return out;
  }

  /// Persist a user-adjusted weekly pathway target (issue 12).
  Future<void> updatePathwayTarget(String name, int target) async {
    db.setSetting('target_$name', '$target');
    pathways = PathwayService(targets: {...pathways.targets, name: target});
    notifyListeners();
  }

  // ── Tab navigation (kept here so any screen can switch the shell tab) ──
  int tabIndex = 0;

  void selectTab(int i) {
    tabIndex = i;
    notifyListeners();
  }

  // ── Notes / import ─────────────────────────────────────
  /// Inserts a note and returns its new id (cold-start sessions need it to
  /// promote the anchor, issue 5).
  Future<int> addNote(String title, String body, {NoteKind? kind}) async {
    final id = await db.insertNote(
      Note(
        id: 0,
        title: title,
        body: body,
        kind: kind ?? NoteKind.blurtSummary,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        card: fsrs.newCard(),
      ),
    );
    await _reloadNotes();
    return id;
  }

  /// Edits mutate through AppState (not a raw DB call) so every screen observes
  /// the refreshed list (issue #20).
  Future<void> updateNote(Note updated) async {
    await db.updateNote(updated);
    await _reloadNotes();
  }

  Future<void> _reloadNotes() async {
    notes = db.allNotes();
    _refreshAnalytics();
    notifyListeners();
  }

  /// Recalculate cached analytics after data mutations.
  void _refreshAnalytics() {
    _strategyProfileCache = null;
    _plasticityProfileCache = null;
    _todayNeuroFactorsCache = null;
    _notesDueForDelayedTestCache = null;
    final linkCounts = db.linkCountsByNote();
    final reviewStats = computeReviewStats(db);
    _overallScore = rankingSvc.evidenceScore(
      blurts: blurtScores,
      notes: notes,
      pathways: pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );
    final evidenceSugg = suggestionSvc.generateEvidenceSuggestions(this);
    final regularSugg = suggestionSvc.generateSuggestions(this);
    final combined = [...evidenceSugg, ...regularSugg];
    _suggestions = combined.toSet().take(2).toList();
  }

  /// Compute review statistics for retention metric.
  static ({int total, int retrievable}) computeReviewStats(AppDatabase db) {
    final reviews = db.reviewHistory();
    final total = reviews.length;
    var retrievable = 0;
    for (final r in reviews) {
      // A review is "retrievable" if the rating was good or easy (not again/hard).
      final rating = r['rating'] as String?;
      if (rating == 'good' || rating == 'easy') {
        retrievable++;
      }
    }
    return (total: total, retrievable: retrievable);
  }

  // ── Workout session ────────────────────────────────────
  /// Starts a fresh wizard. The [WorkoutSessionState] is kept live and its JSON
  /// autosaved into the [Session] record so resume is lossless (issue #2/#3).
  Future<void> startSession(String anchorTitle, {int? anchorNoteId}) async {
    if (activeSession != null && activeSession!.stepsCompleted < 8) {
      await _autosave();
    }
    completedRecently = false;
    final now = DateTime.now();

    // Phase 7: error-shaped session prompts. When anchorNoteId is set and
    // planStep produces a non-baseline intervention, surface the shaped
    // prompt (question, cue, why) and pacing timer on the fresh workout.
    String promptQ = '';
    String promptC = '';
    String why = '';
    int? timerSecs;
    if (anchorNoteId != null) {
      final note = notes.where((n) => n.id == anchorNoteId).firstOrNull;
      if (note != null) {
        final attempts = db.attemptsForTarget(anchorNoteId);
        final errors = <ErrorRecord>[];
        for (final a in attempts) {
          errors.addAll(db.errorsForAttempt(a.id));
        }
        final delayedOutcomes = db.delayedOutcomesForTarget(anchorNoteId);
        final evidence = db.summarizeKnowledgeEvidence(anchorNoteId);

        // Auto-pick contrast: the note with the most links to anchorNoteId.
        int? contrastId;
        final adjacency = <int, int>{};
        for (final link in db.allLinks) {
          if (link.fromNoteId != null && link.fromNoteId == anchorNoteId && link.toNoteId != null) {
            adjacency[link.toNoteId!] = (adjacency[link.toNoteId!] ?? 0) + 1;
          } else if (link.toNoteId != null && link.toNoteId == anchorNoteId && link.fromNoteId != null) {
            adjacency[link.fromNoteId!] = (adjacency[link.fromNoteId!] ?? 0) + 1;
          }
        }
        final sorted = adjacency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (sorted.isNotEmpty) contrastId = sorted.first.key;

        final step = sessionPolicy.planStep(
          note: note,
          noteAttempts: attempts,
          noteErrors: errors,
          noteDelayedOutcomes: delayedOutcomes,
          knowledgeEvidence: evidence,
          contrastNote: contrastId != null
              ? notes.where((n) => n.id == contrastId).firstOrNull
              : null,
          now: now,
        );
        promptQ = step.prompt.question;
        promptC = step.prompt.contextCue;
        why = step.intervention.explanation;
        timerSecs = step.thresholds['timer_seconds'];
      }
    }

    final w = WorkoutSessionState(
      start: now,
      anchorNoteId: anchorNoteId,
      anchorTitle: anchorTitle,
      promptQuestion: promptQ,
      promptCue: promptC,
      interventionExplanation: why,
      timerSeconds: timerSecs,
    );
    final id = await db.insertSession(
      Session(
        id: 0,
        date: now,
        duration: Duration.zero,
        stepsCompleted: 0,
        anchorNoteId: anchorNoteId,
        anchorTitle: anchorTitle,
        autosaveJson: w.toJson(),
      ),
    );
    activeWorkout = w;
    activeSession = Session(
      id: id,
      date: w.start,
      duration: Duration.zero,
      stepsCompleted: 0,
      anchorNoteId: anchorNoteId,
      anchorTitle: anchorTitle,
      autosaveJson: w.toJson(),
    );
    await _reloadSessions();
    notifyListeners();
  }

  /// Clears the transient "just completed" end state (called by the done
  /// screen's navigation so the wizard returns to the welcome picker).
  void dismissComplete() {
    completedRecently = false;
    notifyListeners();
  }

  /// Persists the latest wizard state + elapsed duration, then notifies. Kept
  /// private so every mutation funnels through the methods below.
  Future<void> _autosave() async {
    final w = activeWorkout;
    final s = activeSession;
    if (w == null || s == null) return;
    activeSession = Session(
      id: s.id,
      date: s.date,
      duration: w.elapsed(DateTime.now()),
      stepsCompleted: w.stepsCompleted,
      anchorNoteId: w.anchorNoteId,
      anchorTitle: w.anchorTitle,
      autosaveJson: w.toJson(),
    );
    await db.updateSession(activeSession!);
    await _reloadSessions();
    notifyListeners();
  }

  /// Step-writer helpers (the wizard screen calls these before advancing, so
  /// each step's own content is captured — fixes the shared-controller bug).
  Future<void> setBlurt(String text) async {
    activeWorkout = activeWorkout?.copyWith(blurtText: text.trim());
    await _autosave();
  }

  Future<void> setCheatSheet(String text) async {
    activeWorkout = activeWorkout?.copyWith(cheatSheetText: text.trim());
    await _autosave();
  }

  void _loadBreaks() {
    try {
      final str = db.getSetting('break_records');
      if (str != null && str.isNotEmpty) {
        final List<dynamic> dyn = json.decode(str);
        _breaks = dyn.map((d) => BreakRecord.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load breaks: $e');
      _breaks = [];
    }
  }
  void _loadCheckins() {
    _checkins = db.allCheckins();
  }

  Future<void> logCheckin({required int sleep, required int energy, required int activity}) async {
    final c = DailyCheckin(date: DateTime.now(), sleep: sleep, energy: energy, activity: activity);
    await db.insertCheckin(c);
    _checkins = db.allCheckins();
    _refreshAnalytics();
    notifyListeners();
  }


  void logBreak({required BreakTier tier, required Duration duration}) {
    _breaks.add(BreakRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      startedAt: DateTime.now(),
      tier: tier,
      duration: duration
    ));
    db.setSetting('break_records', json.encode(_breaks.map((b) => b.toJson()).toList()));
    _refreshAnalytics();
    notifyListeners();
  }

  Future<void> setLinkText(String text) async {
    activeWorkout = activeWorkout?.copyWith(linkText: text.trim());
    await _autosave();
  }

  Future<void> setTeaching(String text) async {
    activeWorkout = activeWorkout?.copyWith(teachingText: text.trim());
    await _autosave();
  }

  /// Advances the wizard one step; returns true when the session completes.
  /// Step indices 0..6 are the wizard steps; reaching step 7 is the terminal
  /// "done" transition, so the session is finalized there (log pathways, clear
  /// in-progress state) rather than at a step that never renders a submit.
  Future<bool> advanceStep() async {
    final w = activeWorkout;
    final s = activeSession;
    if (w == null || s == null) return false;
    if (w.stepsCompleted >= 7) return false; // guard against over-advance
    final next = w.stepsCompleted + 1;
    if (next >= 7) {
      // Schedule performed a real FSRS action (scheduleAnchor); finalize by
      // logging only the pathways the user genuinely performed (issue #25) and
      // persisting the completed record as 8/8.
      await _logPathwayFor(w.copyWith(stepsCompleted: 8));
      final completed = Session(
        id: s.id,
        date: s.date,
        duration: w.elapsed(DateTime.now()),
        stepsCompleted: 8,
        anchorNoteId: w.anchorNoteId,
        anchorTitle: w.anchorTitle,
        autosaveJson: w.toJson(),
      );
      await db.updateSessionAutosave(completed);
      activeWorkout = null;
      activeSession = null; // completed
      completedRecently = true;
      await _reloadSessions();
      notifyListeners();
      return true;
    }
    activeWorkout = w.copyWith(stepsCompleted: next);
    await _autosave();
    return false;
  }

  /// Null-safe first-match lookup (the framework's [Iterable.firstWhere]
  /// requires a non-null sentinel, so predicate lookups that may miss return
  /// the nullable directly instead of silently falling back to a wrong note).
  Note? _noteWhere(bool Function(Note) test) {
    for (final n in notes) {
      if (test(n)) return n;
    }
    return null;
  }

  /// Step 2 · Blurt: capture text, score against the note chosen by id first
  /// (authoritative anchor; the old title-match silently swapped in an
  /// unrelated first note — issues #3/#7).
  Future<BlurtScore?> finishBlurt({
    Note? source,
    int? recallSpeedMs,
    double? confidenceJudgement,
    ScaffoldingLevel? scaffoldingLevel,
  }) async {
    final w = activeWorkout;
    if (w == null) return null;
    var resolved = source;
    if (resolved == null && w.anchorNoteId != null) {
      resolved = _noteWhere((n) => n.id == w.anchorNoteId);
    }
    if (resolved == null && w.anchorTitle.isNotEmpty) {
      resolved = _noteWhere((n) => n.title == w.anchorTitle);
    }
    BlurtScore? bs;
    if (resolved != null && w.blurtText.isNotEmpty) {
      bs = await scoreBlurt(
        resolved,
        w.blurtText,
        recallSpeedMs: recallSpeedMs,
        confidenceJudgement: confidenceJudgement,
        scaffoldingLevel: scaffoldingLevel,
      );
    } else if (w.blurtText.isNotEmpty) {
      // resolved == null here → cold start: the blur seeds the Zettelkasten.
      final newId = await addNote(
        w.anchorTitle.isEmpty ? 'Quick note' : w.anchorTitle,
        w.blurtText,
        kind: NoteKind.blurtSummary,
      );
      // Promote the freshly-created note to the session's anchor so Link and
      // Schedule have something to act on (issue 5).
      if (newId > 0) {
        activeWorkout = w.copyWith(anchorNoteId: newId);
        await _autosave();
        final created = _noteWhere((n) => n.id == newId);
        if (created != null) {
          bs = await scoreBlurt(
            created,
            w.blurtText,
            recallSpeedMs: recallSpeedMs,
            confidenceJudgement: confidenceJudgement,
            scaffoldingLevel: scaffoldingLevel,
          );
        }
      }
    }
    if (bs != null && w.blurtText.isNotEmpty) {
      // Persist the score in wizard state so a resume after Compare rehydrates
      // it instead of showing a blank panel (issue 4).
      activeWorkout = activeWorkout!.copyWith(
        scorePct: bs.scorePct,
        scoreMatched: bs.matched,
        scoreMissed: bs.missed,
      );
      await _autosave();
    }
    await advanceStep();
    return bs;
  }


  /// Step 4 · Cheat Sheet: fold the condensed summary into the anchor note
  /// rather than creating a duplicate-titled note (issue 17). Falls back to a
  /// fresh note only when no anchor exists yet.
  Future<void> finishCheatSheet() async {
    final w = activeWorkout;
    if (w == null) return;
    if (w.cheatSheetText.isNotEmpty) {
      final anchor = w.anchorNoteId == null
          ? null
          : _noteWhere((n) => n.id == w.anchorNoteId);
      if (anchor != null) {
        final merged = anchor.body.trim().isEmpty
            ? w.cheatSheetText
            : '${anchor.body.trim()}\n\n---\n${w.cheatSheetText}';
        await updateNote(
          anchor.copyWith(
            body: merged,
            kind: NoteKind.cheatSheet,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await addNote(
          w.anchorTitle.isEmpty ? 'Cheat sheet' : w.anchorTitle,
          w.cheatSheetText,
          kind: NoteKind.cheatSheet,
        );
      }
    }
    await advanceStep();
  }

  /// Step 5 · Link: actually persist the relation edge (issue #8).
  Future<void> finishLink(int? toNoteId) async {
    final w = activeWorkout;
    if (w != null &&
        w.anchorNoteId != null &&
        toNoteId != null &&
        w.linkText.isNotEmpty) {
      await db.addLink(w.anchorNoteId!, toNoteId, w.linkText);
    }
    await advanceStep();
  }

  /// Step 6 · Teach: the explanation was already captured via setTeaching;
  /// nothing is thrown away. This completes the step.
  Future<void> finishTeach() async {
    await advanceStep();
  }

  /// Step 8 · Schedule: a real FSRS action — give the anchor note a meaningful
  /// first interval so it actually enters the spaced-repetition queue, instead
  /// of the old "Complete session" that scheduled nothing (issue #11).
  ///
  /// Maps the blurt score to an FSRS rating so spacing adapts to recall quality:
  ///   <40% → again (failed recall), 40–70% → hard, 70–90% → good, >90% → easy
  Future<void> scheduleAnchor() async {
    final w = activeWorkout;
    if (w == null) return;
    final anchor = w.anchorNoteId == null
        ? null
        : _noteWhere((n) => n.id == w.anchorNoteId);
    if (anchor != null) {
      // A blurt that never got scored (cold start, skipped step) would make
      // scoreToRating(null) silently default to good — inflating the interval.
      // Guard: surface the skip instead of quietly scheduling a review.
      if (w.scorePct == null) {
        debugPrint(
          'Schedule: blurt never scored (cold start?) -- skipping schedule',
        );
        return;
      }
      final rating = AppState.scoreToRating(w.scorePct);
      await reviewNote(anchor, rating);
    }
  }

  /// Maps blurt score percentage to FSRS rating.
  /// <40 → again, 40–70 → hard, 70–90 → good, ≥90 → easy, null → good.
  static Rating scoreToRating(double? scorePct) {
    if (scorePct == null) return Rating.good;
    if (scorePct < 40) return Rating.again;
    if (scorePct < 70) return Rating.hard;
    if (scorePct < 90) return Rating.good;
    return Rating.easy;
  }

  Future<void> _logPathwayFor(WorkoutSessionState w) async {
    // Log only the pathways the user genuinely performed this session.
    // Context = linked to other topics AND explained it (cross-topic connection),
    // distinct from retrieval (free recall of the anchor).
    bool has(String? s) => s != null && s.isNotEmpty;
    await db.insertPathway(
      PathwayRecord(
        id: 0,
        date: w.start,
        retrieval: has(w.blurtText),
        compression: has(w.cheatSheetText),
        association: has(w.linkText),
        explanation: has(w.teachingText),
        context: has(w.linkText) && has(w.teachingText),
        graceUsed: false,
      ),
    );
    pathwayRecords = db.pathwayRecords();
  }

  // ── Blurt scoring ──────────────────────────────────────
  Future<BlurtScore> scoreBlurt(
    Note source,
    String blurt, {
    int? recallSpeedMs,
    double? confidenceJudgement,
    ScaffoldingLevel? scaffoldingLevel,
  }) async {
    ScoreResult r;
    if (isAiAvailable) {
      try {
        r = await _aiScorer.score(
          sourceBody: source.body,
          blurt: blurt,
          aliases: synonymAliases,
        );
      } catch (_) {
        r = BlurtScorer(
          sourceBody: source.body,
          synonymAliases: synonymAliases,
        ).score(blurt);
      }
    } else {
      r = BlurtScorer(
        sourceBody: source.body,
        synonymAliases: synonymAliases,
      ).score(blurt);
    }
    final bs = BlurtScore(
      id: 0,
      noteId: source.id,
      noteTitle: source.title,
      date: DateTime.now(),
      scorePct: r.scorePct,
      matched: r.matched,
      missed: r.missed,
      recallSpeedMs: recallSpeedMs,
      depthScore: r.depthScore,
      clarityScore: r.clarityScore,
    );
    await db.insertBlurtScore(bs);

    // Additive Cognitive Evidence Recording (Phase 1/2)
    final attempt = LearningAttempt(
      id: 0,
      timestamp: bs.date,
      knowledgeTargetId: source.id,
      testType: TestType.freeRecall,
      response: blurt,
      correctness: Correctness.fromScorePct(bs.scorePct),
      scorePct: bs.scorePct,
      responseTimeMs: recallSpeedMs,
      confidence: confidenceJudgement != null ? (confidenceJudgement * 100).round() : null,
      extras: scaffoldingLevel != null ? {'scaffolding': scaffoldingLevel.name} : const {},
    );
    final attemptId = await db.insertAttempt(attempt);

    final fb = feedbackService.generateFeedback(
      attemptId: attemptId,
      response: blurt,
      expectedPoints: source.body.split('\n').where((l) => l.trim().isNotEmpty).toList(),
      customScore: bs.scorePct,
      fromAi: isAiAvailable,
    );
    await db.insertFeedback(fb);

    if (attempt.correctness.isFail) {
      final errorType = feedbackService.diagnoseError(
        response: blurt,
        scorePct: bs.scorePct,
        responseTimeMs: recallSpeedMs,
        confidence: attempt.confidence,
      );
      if (errorType != ErrorType.unknown) {
        await db.insertError(ErrorRecord(
          id: 0,
          attemptId: attemptId,
          type: errorType,
          source: DiagnosisSource.deterministic,
          confidence: 1.0,
          evidence: 'auto: score ${bs.scorePct.toStringAsFixed(0)}%',
          createdAt: DateTime.now(),
        ));
      }
    }

    blurtScores = db.allBlurtScores();
    _refreshAnalytics();
    notifyListeners();
    return bs;
  }


  // ── Review (FSRS) ──────────────────────────────────────
  /// Reviews [n] with [rating] in FSRS and logs attempt evidence.
  ///
  /// A review of note B during a session anchored on note A is interleaved practice.
  Future<void> reviewNote(
    Note n,
    Rating rating, {
    bool? interleaved,
  }) async {
    final effectiveInterleaved = interleaved ??
        (activeWorkout != null &&
            activeWorkout!.anchorNoteId != null &&
            activeWorkout!.anchorNoteId != n.id);
    final result = fsrs.review(n.card, rating);
    await db.updateNote(n.copyWith(card: result.card));
    await db.insertReview(n.id, rating, wasInterleaved: effectiveInterleaved);

    // Additive Cognitive Evidence Recording (Phase 1/2)
    final correctness = rating == Rating.again
        ? Correctness.incorrect
        : (rating == Rating.hard ? Correctness.partiallyCorrect : Correctness.correct);
    final scorePct = rating == Rating.again ? 0.0 : (rating == Rating.hard ? 50.0 : 100.0);

    final attempt = LearningAttempt(
      id: 0,
      timestamp: DateTime.now(),
      knowledgeTargetId: n.id,
      testType: TestType.cuedRecall,
      correctness: correctness,
      scorePct: scorePct,
      wasInterleaved: effectiveInterleaved,
    );
    await db.insertAttempt(attempt);

    await _reloadNotes();
  }

  // ── Cognitive Learning Engine APIs ─────────────────────
  Future<int> recordAttempt(LearningAttempt attempt) async {
    final id = await db.insertAttempt(attempt);
    notifyListeners();
    return id;
  }

  Future<int> recordFeedback(FeedbackRecord feedback) async {
    final id = await db.insertFeedback(feedback);
    notifyListeners();
    return id;
  }

  Future<int> recordError(ErrorRecord error) async {
    final id = await db.insertError(error);
    notifyListeners();
    return id;
  }

  Future<int> recordDelayedOutcome(DelayedOutcome outcome) async {
    final id = await db.insertDelayedOutcome(outcome);
    notifyListeners();
    return id;
  }

  Future<int> recordIntervention(Intervention intervention) async {
    final id = await db.insertIntervention(intervention);
    notifyListeners();
    return id;
  }

  /// Plans and records a recommended intervention for [noteId] based on current evidence.
  Future<int> planAndRecordIntervention(int noteId) async {
    final evidence = db.summarizeKnowledgeEvidence(noteId);
    final attempts = db.attemptsForTarget(noteId);
    final errors = <ErrorRecord>[];
    for (final a in attempts) {
      errors.addAll(db.errorsForAttempt(a.id));
    }
    final conceptType = db.conceptTypeFor(noteId);
    final linkCounts = db.linkCountsByNote();
    final contrastTargetId = linkCounts[noteId] != null
        ? db.allLinks
            .where((l) => l.fromNoteId == noteId || l.toNoteId == noteId)
            .map((l) => l.fromNoteId == noteId ? l.toNoteId : l.fromNoteId)
            .whereType<int>()
            .firstOrNull
        : null;
    final empirical = empiricalMatches;
    final intervention = adaptiveIntervention.decideIntervention(
      targetId: noteId,
      targetAttempts: attempts,
      targetErrors: errors,
      knowledgeState: evidence.state,
      conceptType: conceptType,
      contrastTargetId: contrastTargetId,
      empiricalMatches: empirical,
    );
    final id = await db.insertIntervention(intervention);
    notifyListeners();
    return id;
  }

  KnowledgeEvidence getKnowledgeEvidence(int noteId) {
    return db.summarizeKnowledgeEvidence(noteId);
  }

  /// Assesses capability for a note based on its durable knowledge evidence.
  Capability capabilityFor(int noteId) {
    final ev = db.summarizeKnowledgeEvidence(noteId);
    final cType = db.conceptTypeFor(noteId);
    return const CapabilityEngine().assess(
      ev,
      totalNotesInGraph: notes.length,
      conceptType: cType,
    );
  }

  /// Empirical intervention-to-concept matches computed from personal experiment history.
  List<InterventionConceptMatch> get empiricalMatches {
    final conceptMap = <int, ConceptType>{
      for (final n in notes) n.id: db.conceptTypeFor(n.id),
    };
    final eff = const ExperimentService().effectivenessByConceptType(
      attempts: db.allAttempts(),
      delayedOutcomes: db.allDelayedOutcomes(),
      interventions: db.allInterventions(),
      conceptTypeByNote: conceptMap,
    );
    final matches = <InterventionConceptMatch>[];
    for (final entry in eff.entries) {
      if (entry.key >= 0 && entry.key < ConceptType.values.length) {
        final cType = ConceptType.values[entry.key];
        matches.add(InterventionConceptMatch(
          action: InterventionAction.retrieve,
          conceptType: cType,
          meanDelayedScore: entry.value,
          sampleSize: 3,
        ));
      }
    }
    return matches;
  }

  List<int>? _notesDueForDelayedTestCache;

  /// IDs of notes that are empirically due for a delayed outcome retention test.
  List<int> get notesDueForDelayedTest {
    if (_notesDueForDelayedTestCache == null) {
      final out = <int>[];
      for (final note in notes) {
        final attempts = db.attemptsForTarget(note.id);
        if (attempts.isEmpty) continue;
        final outcomes = db.delayedOutcomesForTarget(note.id);
        final due = delayedOutcomeSvc.isDueForDelayedTest(
          sourceAttempt: attempts.last,
          existingOutcomes: outcomes,
          now: DateTime.now(),
        );
        if (due) out.add(note.id);
      }
      _notesDueForDelayedTestCache = out;
    }
    return _notesDueForDelayedTestCache!;
  }

  Future<void> recordFocus(FocusIntegrity f) async {
    await db.upsertFocus(f);
    notifyListeners();
  }

  FocusIntegrity? getFocus(int sessionId) {
    return db.focusForSession(sessionId);
  }



  // ── Dashboard helpers ──────────────────────────────────
  List<Note> get dueNotesList =>
      notes.where((n) => !n.card.due.isAfter(DateTime.now())).toList();

  Map<String, dynamic> todayReport() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecs = pathwayRecords
        .where((r) => !r.date.isBefore(weekAgo))
        .toList();
    final pathwaysMap = pathways.computeWeek(weekRecs);
    final hasToday = sessions.any((s) {
      final d = s.date;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    });
    final graceDays = pathwayRecords
        .where((p) => p.graceUsed)
        .map((p) => p.date)
        .toSet();
    final streak = streakSvc.compute(
      sessions.map((e) => e.date).toList(),
      hasSessionToday: hasToday,
      graceDays: graceDays,
    );
    return {
      'pathways': pathwaysMap,
      'streak': streak.current,
      'graceAvailable': streak.graceAvailable,
      'dueCount': dueNotesList.length,
      'sessionsThisWeek': sessions
          .where((s) => !s.date.isBefore(weekAgo))
          .length,
    };
  }

  /// Record consumption of a grace token for today.
  Future<void> useGraceToken() async {
    final now = DateTime.now();
    await db.insertPathway(
      PathwayRecord(
        id: 0,
        date: now,
        retrieval: false,
        compression: false,
        association: false,
        explanation: false,
        context: false,
        graceUsed: true,
      ),
    );
    pathwayRecords = db.pathwayRecords();
    notifyListeners();
  }

  Future<void> _reloadSessions() async {
    sessions = db.allSessions();
    _refreshAnalytics();
    notifyListeners();
  }

  // ── Thoughts (Phase 3) ──────────────────────────────────
  Future<void> addThought(
    String text, {
    List<String> tags = const [],
    int? linkedNoteId,
  }) async {
    await db.insertThought(
      Thought(
        id: 0,
        text: text,
        createdAt: DateTime.now(),
        tags: tags,
        linkedNoteId: linkedNoteId,
      ),
    );
    thoughts = db.allThoughts();
    notifyListeners();
  }

  Future<void> deleteThought(int id) async {
    await db.softDeleteThought(id);
    thoughts = db.allThoughts();
    notifyListeners();
  }

  Future<void> recoverThought(int id) async {
    await db.recoverThought(id);
    thoughts = db.allThoughts();
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await db.softDeleteNote(id);
    notes = db.allNotes();
    notifyListeners();
  }

  Future<void> recoverNote(int id) async {
    await db.recoverNote(id);
    notes = db.allNotes();
    notifyListeners();
  }

  List<Note> get deletedNotes => db.deletedNotes();
  List<Thought> get deletedThoughts => db.deletedThoughts();

  List<Thought> searchThoughts(String query) => db.searchThoughts(query);

  // ── Phase 4 — Data lifecycle ────────────────────────────
  /// Returns notes and thoughts that haven't been used in [days] days.
  /// Does NOT delete anything — caller decides what to do.
  ({List<Note> staleNotes, List<Thought> staleThoughts}) findStaleData({
    int days = 90,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final staleNotes = notes.where((n) => !_wasUsedSince(n, cutoff)).toList();
    final staleThoughts = thoughts
        .where((t) => t.createdAt.isBefore(cutoff))
        .toList();
    return (staleNotes: staleNotes, staleThoughts: staleThoughts);
  }

  /// Soft-delete stale data after explicit user confirmation.
  Future<int> archiveStaleData({int days = 90}) async {
    final stale = findStaleData(days: days);
    for (final n in stale.staleNotes) {
      await db.softDeleteNote(n.id);
    }
    for (final t in stale.staleThoughts) {
      await db.softDeleteThought(t.id);
    }
    notes = db.allNotes();
    thoughts = db.allThoughts();
    return stale.staleNotes.length + stale.staleThoughts.length;
  }

  bool _wasUsedSince(Note n, DateTime cutoff) {
    // "Used" = any review, blurt, or edit since cutoff.
    if (n.updatedAt.isAfter(cutoff)) return true;
    final hasRecentBlurt = blurtScores.any(
      (b) => b.noteId == n.id && b.date.isAfter(cutoff),
    );
    if (hasRecentBlurt) return true;
    final hasRecentReview = db.reviewHistory().any((r) {
      final date = DateTime.tryParse(r['date'] as String? ?? '');
      return r['note_id'] == n.id && date != null && date.isAfter(cutoff);
    });
    return hasRecentReview;
  }

  // ── Phase 3 — Export ────────────────────────────────────
  Future<String> exportThoughtsCsv() => exportSvc.exportThoughtsCsv(thoughts);

  Future<String> exportAllCsv() => exportSvc.exportAllCsv(
    thoughts: thoughts,
    blurtScores: blurtScores,
    notes: notes,
    sessions: sessions,
    pathways: pathwayRecords,
  );

  // ── Phase 5 — Ranking ───────────────────────────────────

  List<String> getWeakestAreas() {
    final linkCounts = db.linkCountsByNote();
    final reviewStats = computeReviewStats(db);
    return rankingSvc.weakestAreas(
      blurts: blurtScores,
      notes: notes,
      pathways: pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );
  }

  // ── Phase 6 — Suggestions ───────────────────────────────
  List<String> getSuggestions() => _suggestions;

  // ── Phase 2 — Metrics ───────────────────────────────────
  BlurtMetrics computeMetrics(BlurtScore blurt) {
    final anchor = notes
        .where((n) => n.id == blurt.noteId)
        .cast<Note?>()
        .firstOrNull;
    if (anchor == null) {
      return BlurtMetrics(
        recallAccuracy: blurt.scorePct,
        recallSpeedMs: blurt.recallSpeedMs,
      );
    }
    return metricsSvc.compute(
      blurt: blurt,
      allScores: blurtScores,
      sessions: sessions,
      linkCountForNote: db.linkCountForNote(blurt.noteId),
      totalNotes: notes.length,
    );
  }
}
