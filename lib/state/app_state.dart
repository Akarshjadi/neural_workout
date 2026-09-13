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

class AppState extends ChangeNotifier {
  final AppDatabase db;
  final FsrsEngine fsrs = FsrsEngine();
  PathwayService pathways = const PathwayService();
  final StreakService streakSvc = StreakService();
  final LocalAiScorer _aiScorer = LocalAiScorer();
  final MetricsService metricsSvc = MetricsService();
  final RankingService rankingSvc = RankingService();

  /// Phase 6 — Notifications & suggestions.
  final NotificationService notificationSvc = NotificationService();
  final SuggestionService suggestionSvc = SuggestionService();

  /// Phase 3 — Export.
  final ExportService exportSvc = ExportService();

  /// Phase 1 — User toggle for AI scoring (persisted in settings).
  bool aiEnabled = true;

  /// Phase 5 — Cached overall score.
  double overallScore = 0;

  /// Phase 6 — Cached suggestions.
  List<String> suggestions = [];

  /// User-grown synonym/alias table (issue 10): kebab concept -> alternatives.
  /// Loaded from the settings box at startup; grown via [addSynonymAlias].
  /// Seeded with a tiny default set; passed through to the BlurtScorer.
  Map<String, List<String>> synonymAliases = {
    'gateway': ['bridge'],
    'encryption': ['ciphering'],
  };

  /// Persisted user aliases (survive restarts). Format: "concept=alt1,alt2" per key.
  void _loadSynonymAliases() {
    final raw = db.getSetting('synonym_aliases');
    if (raw == null || raw.isEmpty) return;
    for (final entry in raw.split(';')) {
      final parts = entry.split('=');
      if (parts.length != 2) continue;
      final concept = parts[0].trim();
      final alts = parts[1]
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (concept.isNotEmpty && alts.isNotEmpty) {
        final existing = synonymAliases[concept] ?? const [];
        synonymAliases[concept] = {...existing, ...alts}.toList();
      }
    }
  }

  /// Add a user-taught alias for a concept and persist it.
  Future<void> addSynonymAlias(String concept, String alias) async {
    final c = concept.trim().toLowerCase();
    final a = alias.trim().toLowerCase();
    if (c.isEmpty || a.isEmpty) return;
    final current = [...(synonymAliases[c] ?? const <String>[])];
    if (current.contains(a)) return;
    synonymAliases[c] = [...current, a];
    // Persist: merge existing setting with the new alias.
    final raw = db.getSetting('synonym_aliases') ?? '';
    final buffer = StringBuffer(raw.isEmpty ? '' : '$raw;');
    buffer.write('$c=$a');
    db.setSetting('synonym_aliases', buffer.toString());
    notifyListeners();
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

    // Restore user-adjustable weekly targets from settings (issue 12).
    pathways = PathwayService(targets: _loadPathwayTargets());
    // Restore user-grown synonym aliases so scoring rewards user vocabulary.
    _loadSynonymAliases();

    // Phase 1 — Load AI toggle and init AI scorer.
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
    final linkCounts = <int, int>{};
    for (final n in notes) {
      linkCounts[n.id] = db.linkCountForNote(n.id);
    }
    final reviewStats = computeReviewStats(db);
    overallScore = rankingSvc.overallScore(
      blurts: blurtScores,
      notes: notes,
      pathways: pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );

    // Phase 6 — Compute suggestions.
    suggestions = suggestionSvc.generateSuggestions(this);

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
    final linkCounts = <int, int>{};
    for (final n in notes) {
      linkCounts[n.id] = db.linkCountForNote(n.id);
    }
    final reviewStats = computeReviewStats(db);
    overallScore = rankingSvc.overallScore(
      blurts: blurtScores,
      notes: notes,
      pathways: pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );
    suggestions = suggestionSvc.generateSuggestions(this);
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
    final w = WorkoutSessionState(
      start: now,
      anchorNoteId: anchorNoteId,
      anchorTitle: anchorTitle,
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
  Future<BlurtScore?> finishBlurt({Note? source, int? recallSpeedMs}) async {
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
    blurtScores = db.allBlurtScores();
    _refreshAnalytics();
    notifyListeners();
    return bs;
  }

  // ── Review (FSRS) ──────────────────────────────────────
  Future<void> reviewNote(
    Note n,
    Rating rating, {
    bool interleaved = false,
  }) async {
    final result = fsrs.review(n.card, rating);
    await db.updateNote(n.copyWith(card: result.card));
    await db.insertReview(n.id, rating, wasInterleaved: interleaved);
    await _reloadNotes();
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
  double getOverallScore() => overallScore;

  List<String> getWeakestAreas() {
    final linkCounts = <int, int>{};
    for (final n in notes) {
      linkCounts[n.id] = db.linkCountForNote(n.id);
    }
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
  List<String> getSuggestions() => suggestions;

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
      anchorNote: anchor,
      linkCountForNote: db.linkCountForNote(blurt.noteId),
      totalNotes: notes.length,
    );
  }
}
