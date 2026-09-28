import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fsrs/fsrs.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';
import '../models/pathway_record.dart';
import '../models/session.dart';
import '../models/daily_checkin.dart';
import '../models/blurt_score.dart';
import '../models/thought.dart';
import '../models/learning_enums.dart';
import '../models/learning_attempt.dart';
import '../models/feedback_record.dart';
import '../models/error_record.dart';
import '../models/delayed_outcome.dart';
import '../models/intervention.dart';
import '../models/experiment.dart';
import '../models/focus_integrity.dart';
import '../models/knowledge_evidence.dart';

part 'app_database.g.dart';


@HiveType(typeId: 0)
class HiveNote {
  @HiveField(0) int? id;
  @HiveField(1) String? title;
  @HiveField(2) String? body;
  @HiveField(3) String? kind;
  @HiveField(4) String? createdAt;
  @HiveField(5) String? updatedAt;
  @HiveField(6) String? cardState;
  @HiveField(7) String? cardDue;
  @HiveField(8) String? deletedAt; // Phase 4 — soft delete
  @HiveField(9) List<int>? linkIds;
}

@HiveType(typeId: 1)
class HiveSession {
  @HiveField(0) int? id;
  @HiveField(1) String? date;
  @HiveField(2) int? durationMs;
  @HiveField(3) int? stepsCompleted;
  @HiveField(4) int? anchorNoteId;
  @HiveField(5) String? anchorTitle;
  @HiveField(6) String? autosaveJson;
  @HiveField(7) bool? focusPrimed;
}

@HiveType(typeId: 2)
class HiveBlurtScore {
  @HiveField(0) int? id;
  @HiveField(1) int? noteId;
  @HiveField(2) String? noteTitle;
  @HiveField(3) String? date;
  @HiveField(4) double? scorePct;
  @HiveField(5) List<String>? matched;
  @HiveField(6) List<String>? missed;
  @HiveField(7) int? recallSpeedMs;
  @HiveField(8) double? depthScore;
  @HiveField(9) double? clarityScore;
}

@HiveType(typeId: 3)
class HivePathwayRecord {
  @HiveField(0) int? id;
  @HiveField(1) String? date;
  @HiveField(2) bool? retrieval;
  @HiveField(3) bool? compression;
  @HiveField(4) bool? association;
  @HiveField(5) bool? explanation;
  @HiveField(6) bool? context;
  @HiveField(7) bool? graceUsed;
}

@HiveType(typeId: 4)
class HiveReview {
  @HiveField(0) int? id;
  @HiveField(1) int? noteId;
  @HiveField(2) String? date;
  @HiveField(3) String? rating;
  @HiveField(4) bool? wasInterleaved;
}

@HiveType(typeId: 5)
class HiveLink {
  @HiveField(0) int? id;
  @HiveField(1) int? fromNoteId;
  @HiveField(2) int? toNoteId;
  @HiveField(3) String? relationText;
  @HiveField(4) String? createdAt;
}

@HiveType(typeId: 6)
class HiveSetting {
  @HiveField(0) String? key;
  @HiveField(1) String? value;
}

@HiveType(typeId: 7)
class HiveThought {
  @HiveField(0) int? id;
  @HiveField(1) String? text;
  @HiveField(2) String? createdAt;
  @HiveField(3) List<String>? tags;
  @HiveField(4) int? linkedNoteId;
  @HiveField(5) String? deletedAt; // soft delete
}

@HiveType(typeId: 8)
class HiveCheckin {
  @HiveField(0) String? date;
  @HiveField(1) int? sleep;
  @HiveField(2) int? energy;
  @HiveField(3) int? activity;
}

@HiveType(typeId: 9)
class HiveAttempt {
  @HiveField(0) int? id;
  @HiveField(1) String? timestamp;
  @HiveField(2) int? knowledgeTargetId;
  @HiveField(3) int? sessionId;
  @HiveField(4) String? testType;
  @HiveField(5) String? response;
  @HiveField(6) String? correctness;
  @HiveField(7) double? scorePct;
  @HiveField(8) int? responseTimeMs;
  @HiveField(9) int? confidence;
  @HiveField(10) double? difficulty;
  @HiveField(11) Map<String, String>? extras;
  @HiveField(12) int? feedbackId;
  @HiveField(13) List<int>? errorIds;
  @HiveField(14) int? interventionId;
  @HiveField(15) int? delayedOutcomeId;
  @HiveField(16) bool? wasInterleaved;
  @HiveField(17) String? interleaveGroupId;
  @HiveField(18) String? interleaveReason;
  @HiveField(19) String? acquiredAt;
}

@HiveType(typeId: 10)
class HiveFeedback {
  @HiveField(0) int? id;
  @HiveField(1) int? attemptId;
  @HiveField(2) String? createdAt;
  @HiveField(3) String? correctness;
  @HiveField(4) double? scorePct;
  @HiveField(5) List<String>? correctPoints;
  @HiveField(6) List<String>? missing;
  @HiveField(7) List<String>? incorrect;
  @HiveField(8) String? nextAction;
  @HiveField(9) bool? fromAi;
}

@HiveType(typeId: 11)
class HiveError {
  @HiveField(0) int? id;
  @HiveField(1) int? attemptId;
  @HiveField(2) String? type;
  @HiveField(3) String? source;
  @HiveField(4) double? confidence;
  @HiveField(5) String? evidence;
  @HiveField(6) String? createdAt;
}

@HiveType(typeId: 12)
class HiveDelayedOutcome {
  @HiveField(0) int? id;
  @HiveField(1) int? knowledgeTargetId;
  @HiveField(2) int? attemptId;
  @HiveField(3) String? measuredAt;
  @HiveField(4) int? sourceAttemptId;
  @HiveField(5) String? bucket;
  @HiveField(6) int? elapsedMs;
  @HiveField(7) String? correctness;
  @HiveField(8) double? scorePct;
  @HiveField(9) int? experimentId;
}

@HiveType(typeId: 13)
class HiveIntervention {
  @HiveField(0) int? id;
  @HiveField(1) String? createdAt;
  @HiveField(2) String? action;
  @HiveField(3) String? reason;
  @HiveField(4) String? explanation;
  @HiveField(5) int? knowledgeTargetId;
  @HiveField(6) int? contrastTargetId;
  @HiveField(7) int? attemptId;
  @HiveField(8) int? experimentId;
  @HiveField(9) Map<String, int>? thresholds;
}

@HiveType(typeId: 14)
class HiveExperiment {
  @HiveField(0) int? id;
  @HiveField(1) String? hypothesis;
  @HiveField(2) String? conditionsJson;
  @HiveField(3) List<String>? outcomeBuckets;
  @HiveField(4) int? targetConceptTypeFilter;
  @HiveField(5) int? minAttemptsPerCondition;
  @HiveField(6) String? startedAt;
  @HiveField(7) String? endedAt;
  @HiveField(8) bool? active;
}

@HiveType(typeId: 15)
class HiveFocusIntegrity {
  @HiveField(0) int? sessionId;
  @HiveField(1) int? plannedDurationMs;
  @HiveField(2) int? actualDurationMs;
  @HiveField(3) int? interruptions;
  @HiveField(4) int? taskSwitches;
  @HiveField(5) bool? abandoned;
  @HiveField(6) bool? completed;
  @HiveField(7) int? longestFocusMs;
}

@HiveType(typeId: 16)
class HiveConceptProfile {
  @HiveField(0) int? noteId;
  @HiveField(1) String? conceptType;
  @HiveField(2) String? updatedAt;
}


/// Local database access using Hive.
///
/// Precondition: Readers and writers assume Hive boxes have been opened via
/// [AppDatabase.ensureInitialized()]. Reader methods include defensive checks
/// (`Hive.isBoxOpen`) returning empty results if called prior to initialization.
class AppDatabase {
  static const _nb = 'notes', _sb = 'sessions', _bb = 'blurt_scores', _pb = 'pathway_records', _rb = 'reviews', _lb = 'links', _stb = 'settings', _mb = 'meta', _tb = 'thoughts', _cb = 'checkins';

  // Phase 1+ evidence layer boxes (additive: never renames or drops an old box).
  static const _ab = 'attempts', _fb = 'feedback', _eb = 'errors',
      _db = 'delayed_outcomes', _ib = 'interventions', _xb = 'experiments',
      _fob = 'focus', _cpb = 'concept_profiles';

  /// Schema version — bump when adding/removing fields or boxes.
  /// 1: initial  2: +deletedAt on Note  3: +metrics on BlurtScore  4: +Thought box
  /// 5: +Checkins +focusPrimed  6: +LearningEvidence layer (8 new boxes, no row rewrite)
  /// 7: +linkIds on Note (backfilled from links box)
  static const int schemaVersion = 7;

  /// Registers each adapter independently (guarding on its own typeId) so a
  /// partially-registered runtime can't silently skip the rest (issue #17).
  static void _ensureAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HiveNoteAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HiveSessionAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HiveBlurtScoreAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HivePathwayRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HiveReviewAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HiveLinkAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(HiveSettingAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(HiveThoughtAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(HiveCheckinAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(HiveAttemptAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(HiveFeedbackAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(HiveErrorAdapter());
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(HiveDelayedOutcomeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(HiveInterventionAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(HiveExperimentAdapter());
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(HiveFocusIntegrityAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(HiveConceptProfileAdapter());
    }
  }

  static Future<void> ensureInitialized() async {
    await Hive.initFlutter();
    await _initBoxesAndMigrations();
  }

  /// Initializer for headless unit/integration tests running in pure Dart VM.
  static Future<void> ensureInitializedForTesting(String path) async {
    Hive.init(path);
    await _initBoxesAndMigrations();
  }

  static Future<void> _initBoxesAndMigrations() async {
    _ensureAdapters();
    await Hive.openBox(_nb);
    await Hive.openBox(_sb);
    await Hive.openBox(_bb);
    await Hive.openBox(_pb);
    await Hive.openBox(_rb);
    await Hive.openBox(_lb);
    await Hive.openBox(_stb);
    await Hive.openBox(_mb);
    await Hive.openBox(_tb);
    await Hive.openBox(_cb);
    // Evidence-layer boxes. Opening a never-seen box is already a no-op
    // migration, but they are opened here so readers never hit a closed box.
    await Hive.openBox(_ab);
    await Hive.openBox(_fb);
    await Hive.openBox(_eb);
    await Hive.openBox(_db);
    await Hive.openBox(_ib);
    await Hive.openBox(_xb);
    await Hive.openBox(_fob);
    await Hive.openBox(_cpb);
    _checkSchemaVersion();
  }

  /// Runs idempotent migrations when schema version changes.
  static void _checkSchemaVersion() {
    final meta = Hive.box(_mb);
    final stored = meta.get('schema_version') as int? ?? 0;
    if (stored < schemaVersion) {
      debugPrint('AppDatabase: migrating schema v$stored → v$schemaVersion');
      _runMigrations(stored);
      meta.put('schema_version', schemaVersion);
    }
  }

  /// Idempotent migrations — each step upgrades from N to N+1.
  static void _runMigrations(int fromVersion) {
    if (fromVersion < 2) _migrateV1ToV2();
    if (fromVersion < 3) _migrateV2ToV3();
    if (fromVersion < 4) _migrateV3ToV4();
    if (fromVersion < 5) _migrateV4ToV5();
    if (fromVersion < 6) _migrateV5ToV6();
    if (fromVersion < 7) _migrateV6ToV7();
  }

  /// v6 → v7: backfill linkIds on Note from the links box.
  static void _migrateV6ToV7() {
    final meta = Hive.box(_mb);
    if (!Hive.isBoxOpen(_nb) || !Hive.isBoxOpen(_lb)) return;
    if (meta.get('backfilled_linkids') == true) return;
    try {
      final linksBox = Hive.box(_lb);
      final notesBox = Hive.box(_nb);
      final linksByNote = <int, Set<int>>{};
      for (final raw in linksBox.values) {
        if (raw is HiveLink) {
          final f = raw.fromNoteId;
          final t = raw.toNoteId;
          if (f != null && t != null) {
            linksByNote.putIfAbsent(f, () => <int>{}).add(t);
            linksByNote.putIfAbsent(t, () => <int>{}).add(f);
          }
        }
      }
      for (final raw in notesBox.values) {
        if (raw is HiveNote && raw.id != null) {
          final noteId = raw.id!;
          final linked = linksByNote[noteId];
          if (linked != null && linked.isNotEmpty) {
            final existing = (raw.linkIds ?? []).toSet();
            existing.addAll(linked);
            raw.linkIds = existing.toList();
            notesBox.put(noteId, raw);
          }
        }
      }
      meta.put('backfilled_linkids', true);
      debugPrint('AppDatabase: v7 backfilled linkIds');
    } catch (e) {
      debugPrint('AppDatabase: v7 backfill skipped: $e');
    }
  }

  /// v5 → v6: introduce the LearningEvidence layer.
  ///
  /// Purely additive: no existing row is touched, so a v5 database either
  /// resumes unchanged (new boxes empty) or is *backfilled* once from the
  /// legacy history so old learning still counts as evidence. Backfill markers
  /// live in `meta` so re-running is a no-op.
  static void _migrateV5ToV6() {
    final meta = Hive.box(_mb);
    // Boxes are opened by ensureInitialized; guard in case of a direct call.
    for (final b in [_ab, _fb, _eb, _db, _ib, _xb, _fob, _cpb]) {
      if (!Hive.isBoxOpen(b)) return;
    }
    if (meta.get('backfilled_attempts') == true) return;
    try {
      var attempts = _backfillAttemptsFromBlurts();
      attempts += _backfillAttemptsFromReviews();
      meta.put('backfilled_attempts', true);
      debugPrint('AppDatabase: v6 backfilled $attempts legacy evidence rows');
    } catch (e) {
      // Backfill must never block boot; the new boxes simply stay empty and
      // fresh practice populates them from here on.
      debugPrint('AppDatabase: v6 backfill skipped: $e');
    }
  }

  /// Converts every legacy [HiveBlurtScore] + [HiveReview] into an attempt so
  /// "existing history survives" is literally true in the new analytics.
  ///
  /// Idempotent via `meta` markers written by the caller. Legacy rows are the
  /// *origin* of all this evidence, so nothing is reinterpreted: a blurt stays
  /// a free recall, an FSRS review stays a cued recall with its rating grade.
  static int _safeNextId(String b) {
    final m = Hive.box('meta');
    final c = m.get('seq_$b', defaultValue: 0) as int;
    m.put('seq_$b', c + 1);
    return c + 1;
  }

  static int _backfillAttemptsFromBlurts() {
    final src = Hive.box(_bb);
    final dst = Hive.box(_ab);
    if (src.isEmpty) return 0;
    var n = 0;
    for (final key in src.keys) {
      final e = src.get(key);
      if (e is! HiveBlurtScore) continue;
      final b = e;
      final ts = DateTime.tryParse(b.date ?? '') ?? DateTime.now();
      final pct = b.scorePct ?? 0.0;
      final freshId = _safeNextId(_ab);
      dst.put(freshId, HiveAttempt()
        ..id = freshId
        ..timestamp = ts.toIso8601String()
        ..knowledgeTargetId = b.noteId
        ..testType = 'freeRecall'
        ..correctness = Correctness.fromScorePct(pct).name
        ..scorePct = pct
        ..responseTimeMs = b.recallSpeedMs
        ..extras = {
          'legacy': 'blurt',
          if (b.matched != null && b.matched!.isNotEmpty)
            'matched': b.matched!.join('|'),
          if (b.missed != null && b.missed!.isNotEmpty)
            'missed': b.missed!.join('|'),
        });
      n++;
    }
    return n;
  }

  static int _backfillAttemptsFromReviews() {
    final src = Hive.box(_rb);
    final dst = Hive.box(_ab);
    var n = 0;
    for (final key in src.keys) {
      final e = src.get(key);
      if (e is! HiveReview) continue;
      final r = e;
      final ts = DateTime.tryParse(r.date ?? '') ?? DateTime.now();
      final freshId = _safeNextId(_ab);
      dst.put(freshId, HiveAttempt()
        ..id = freshId
        ..timestamp = ts.toIso8601String()
        ..knowledgeTargetId = r.noteId
        ..testType = 'cuedRecall'
        ..correctness = _ratingToCorrectness(r.rating).name
        ..scorePct = _ratingToScore(r.rating)
        ..extras = {'legacy': 'review', 'rating': r.rating ?? 'good'}
        ..wasInterleaved = r.wasInterleaved ?? false);
      n++;
    }
    return n;
  }

  static double _ratingToScore(String? rating) => switch (rating) {
        'again' => 0.0,
        'hard' => 60.0,
        'good' => 85.0,
        'easy' => 100.0,
        _ => double.nan,
      };

  static Correctness _ratingToCorrectness(String? rating) => switch (rating) {
        'again' => Correctness.incorrect,
        'hard' => Correctness.partiallyCorrect,
        'good' => Correctness.correct,
        'easy' => Correctness.correct,
        _ => Correctness.unknown,
      };

  /// v1 → v2: Add deletedAt field to existing notes (defaults to null = not deleted).
  static void _migrateV1ToV2() {
    if (!Hive.isBoxOpen(_nb)) return;
    final box = Hive.box(_nb);
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw is! HiveNote) {
        debugPrint('_migrateV1ToV2: skipping non-HiveNote at $key');
        continue;
      }
      if (raw.deletedAt == null) {
        box.put(key, raw);
      }
    }
  }

  /// v2 → v3: Add metrics fields to existing BlurtScore records.
  static void _migrateV2ToV3() {
    if (!Hive.isBoxOpen(_bb)) return;
    final box = Hive.box(_bb);
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw is! HiveBlurtScore) {
        debugPrint('_migrateV2ToV3: skipping non-HiveBlurtScore at $key');
        continue;
      }
      box.put(key, raw);
    }
  }

  /// v3 → v4: Open thoughts box (new box, no data migration needed).
  static void _migrateV3ToV4() {
    // Thoughts box is new; nothing to migrate.
  }

  /// v4 → v5: Add focusPrimed field to existing sessions (backfill to false).
  static void _migrateV4ToV5() {
    if (!Hive.isBoxOpen(_sb)) return;
    final box = Hive.box(_sb);
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw is! HiveSession) {
        debugPrint('_migrateV4ToV5: skipping non-HiveSession at $key');
        continue;
      }
      if (raw.focusPrimed == null) {
        raw.focusPrimed = false;
        box.put(key, raw);
      }
    }
  }

  int _nextId(String b) {
    final m = Hive.box(_mb);
    final c = m.get('seq_$b', defaultValue: 0) as int;
    m.put('seq_$b', c + 1);
    return c + 1;
  }

  Box get _n => Hive.box(_nb);
  Box get _s => Hive.box(_sb);
  Box get _b => Hive.box(_bb);
  Box get _p => Hive.box(_pb);
  Box get _r => Hive.box(_rb);
  Box get _l => Hive.box(_lb);
  Box get _st => Hive.box(_stb);
  Box get _t => Hive.box(_tb);
  Box get _c => Hive.box(_cb);
  Box get _a => Hive.box(_ab);
  Box get _f => Hive.box(_fb);
  Box get _e => Hive.box(_eb);
  Box get _do => Hive.box(_db);
  Box get _i => Hive.box(_ib);
  Box get _x => Hive.box(_xb);
  Box get _fo => Hive.box(_fob);
  Box get _cp => Hive.box(_cpb);

  /// Direct access to settings box.
  Box get settingsBox => _st;

  /// Returns non-deleted notes only (Phase 4 — soft delete filter).
  List<Note> allNotes({bool includeDeleted = false}) {
    if (!Hive.isBoxOpen(_nb)) return [];
    return _n.values
        .map((e) => e as HiveNote)
        .where((h) => includeDeleted || h.deletedAt == null)
        .map((e) => _nF(e))
        .toList();
  }

  /// Returns soft-deleted notes only.
  List<Note> deletedNotes() {
    if (!Hive.isBoxOpen(_nb)) return [];
    return _n.values
        .map((e) => e as HiveNote)
        .where((h) => h.deletedAt != null)
        .map((e) => _nF(e))
        .toList();
  }

  List<Note> dueNotes({DateTime? at}) {
    final now = at ?? DateTime.now();
    return allNotes().where((n) => !n.card.due.isAfter(now)).toList();
  }

  /// Soft-delete: set deletedAt timestamp instead of removing.
  Future<void> softDeleteNote(int id) async {
    final h = _n.get(id) as HiveNote?;
    if (h != null) {
      h.deletedAt = DateTime.now().toIso8601String();
      await _n.put(id, h);
    }
  }

  /// Recover a soft-deleted note.
  Future<void> recoverNote(int id) async {
    final h = _n.get(id) as HiveNote?;
    if (h != null) {
      h.deletedAt = null;
      await _n.put(id, h);
    }
  }

  Future<int> insertNote(Note note) async {
    final id = _nextId(_nb);
    await _n.put(id, _nT(note, id));
    return id;
  }

  Future<void> updateNote(Note note) async => await _n.put(note.id, _nT(note, note.id));
  /// Soft-delete by default (recoverable). Use hardDeleteNote() for permanent removal.
  Future<void> deleteNote(int id) async => await softDeleteNote(id);
  /// Permanent removal — also cleans up links, reviews, blurt scores, and thought links for this note.
  Future<void> hardDeleteNote(int id) async {
    await _n.delete(id);
    // Clean up orphaned links.
    if (Hive.isBoxOpen(_lb)) {
      final linkBox = Hive.box(_lb);
      for (final key in linkBox.keys.toList()) {
        final link = linkBox.get(key) as HiveLink?;
        if (link != null && (link.fromNoteId == id || link.toNoteId == id)) {
          await linkBox.delete(key);
        }
      }
    }
    // Clean up orphaned reviews.
    if (Hive.isBoxOpen(_rb)) {
      final reviewBox = Hive.box(_rb);
      for (final key in reviewBox.keys.toList()) {
        final review = reviewBox.get(key) as HiveReview?;
        if (review != null && review.noteId == id) {
          await reviewBox.delete(key);
        }
      }
    }
    // Clean up orphaned blurt scores.
    if (Hive.isBoxOpen(_bb)) {
      final blurtBox = Hive.box(_bb);
      for (final key in blurtBox.keys.toList()) {
        final score = blurtBox.get(key) as HiveBlurtScore?;
        if (score != null && score.noteId == id) {
          await blurtBox.delete(key);
        }
      }
    }
    // Clean up linkedNoteId on thoughts.
    if (Hive.isBoxOpen(_tb)) {
      final thoughtBox = Hive.box(_tb);
      for (final key in thoughtBox.keys.toList()) {
        final thought = thoughtBox.get(key) as HiveThought?;
        if (thought != null && thought.linkedNoteId == id) {
          thought.linkedNoteId = null;
          await thoughtBox.put(key, thought);
        }
      }
    }
  }

  Future<int> insertSession(Session s) async {
    final id = _nextId(_sb);
    await _s.put(id, _sT(s, id));
    return id;
  }

  Future<void> updateSession(Session s) async => await _s.put(s.id, _sT(s, s.id));
  /// Legacy alias for updateSession.
  Future<void> updateSessionAutosave(Session s) async => await updateSession(s);

  List<Session> allSessions() {
    if (!Hive.isBoxOpen(_sb)) return [];
    return _s.values.map((e) => _sR(e as HiveSession)).toList();
  }

  /// Deterministic "latest" — max by start date, not by Hive insertion order.
  Session? latestSession() {
    if (!Hive.isBoxOpen(_sb) || _s.isEmpty) return null;
    var latest = _sR(_s.values.first as HiveSession);
    for (final e in _s.values.skip(1)) {
      final s = _sR(e as HiveSession);
      if (s.date.isAfter(latest.date)) latest = s;
    }
    return latest;
  }

  /// The most recent still-in-progress session (stepsCompleted < 8) across ALL
  /// sessions, regardless of whether a later one completed.
  Session? latestInProgressSession() {
    if (!Hive.isBoxOpen(_sb)) return null;
    Session? best;
    for (final e in _s.values) {
      final s = _sR(e as HiveSession);
      if (s.stepsCompleted >= 8) continue;
      if (best == null || s.date.isAfter(best.date)) best = s;
    }
    return best;
  }
  HiveCheckin _cT(DailyCheckin c) => HiveCheckin()
    ..date = c.date.toIso8601String()
    ..sleep = c.sleep
    ..energy = c.energy
    ..activity = c.activity;

  DailyCheckin _cF(HiveCheckin h) => DailyCheckin(
    date: DateTime.tryParse(h.date ?? '') ?? DateTime.now(),
    sleep: h.sleep ?? 1,
    energy: h.energy ?? 1,
    activity: h.activity ?? 1,
  );

  List<DailyCheckin> allCheckins() {
    if (!Hive.isBoxOpen(_cb)) return [];
    return _c.values.map((e) => _cF(e as HiveCheckin)).toList();
  }

  Future<void> insertCheckin(DailyCheckin c) async {
    // using ISO8601 date string (YYYY-MM-DD) as key for uniqueness per day
    final key = "${c.date.year}-${c.date.month.toString().padLeft(2, '0')}-${c.date.day.toString().padLeft(2, '0')}";
    await _c.put(key, _cT(c));
  }


  Future<int> insertBlurtScore(BlurtScore bs) async {
    final id = _nextId(_bb);
    await _b.put(id, _bT(bs, id));
    return id;
  }

  List<BlurtScore> allBlurtScores() {
    if (!Hive.isBoxOpen(_bb)) return [];
    return _b.values.map((e) => _bF(e as HiveBlurtScore)).toList();
  }

  Future<int> insertPathway(PathwayRecord pr) async {
    final id = _nextId(_pb);
    await _p.put(id, _pT(pr, id));
    return id;
  }

  List<PathwayRecord> pathwayRecords() {
    if (!Hive.isBoxOpen(_pb)) return [];
    return _p.values.map((e) => _pF(e as HivePathwayRecord)).toList();
  }

  Future<int> insertReview(int noteId, Rating rating, {bool wasInterleaved = false}) async {
    final id = _nextId(_rb);
    await _r.put(id, HiveReview()
      ..id = id ..noteId = noteId ..date = DateTime.now().toIso8601String()
      ..rating = rating.name ..wasInterleaved = wasInterleaved);
    return id;
  }

  List<Map<String, dynamic>> reviewHistory() {
    // Guard: the widget test (and any pre-init path) may not have opened the
    // reviews box yet; return empty instead of throwing (issue 13).
    if (!Hive.isBoxOpen(_rb)) return [];
    return _r.values.map((e) {
    final r = e as HiveReview;
    return {'id': r.id, 'note_id': r.noteId, 'date': r.date, 'rating': r.rating, 'was_interleaved': (r.wasInterleaved ?? false) ? 1 : 0};
  }).toList();
  }

  Future<int> addLink(int f, int t, String rel) async {
    final id = _nextId(_lb);
    await _l.put(id, HiveLink()..id = id ..fromNoteId = f ..toNoteId = t ..relationText = rel ..createdAt = DateTime.now().toIso8601String());
    return id;
  }

  String? getSetting(String k) {
    final v = _st.get(k);
    return v is HiveSetting ? v.value : null;
  }
  void setSetting(String k, String v) => _st.put(k, HiveSetting()..key = k..value = v);
  Future<void> close() async => Hive.close();

  // ── Thoughts (Phase 3) ───────────────────────────────────
  List<Thought> allThoughts({bool includeDeleted = false}) {
    if (!Hive.isBoxOpen(_tb)) return [];
    return _t.values
        .map((e) => e as HiveThought)
        .where((h) => includeDeleted || h.deletedAt == null)
        .map((h) => Thought(
              id: h.id ?? 0,
              text: h.text ?? '',
              createdAt: DateTime.tryParse(h.createdAt ?? '') ?? DateTime.now(),
              tags: h.tags ?? [],
              linkedNoteId: h.linkedNoteId,
            ))
        .toList();
  }
  List<Thought> deletedThoughts() {
    if (!Hive.isBoxOpen(_tb)) return [];
    return _t.values
        .map((e) => e as HiveThought)
        .where((h) => h.deletedAt != null)
        .map((h) => Thought(
              id: h.id ?? 0,
              text: h.text ?? '',
              createdAt: DateTime.tryParse(h.createdAt ?? '') ?? DateTime.now(),
              tags: h.tags ?? [],
              linkedNoteId: h.linkedNoteId,
            ))
        .toList();
  }

  Future<int> insertThought(Thought thought) async {
    final id = _nextId(_tb);
    await _t.put(id, HiveThought()
      ..id = id
      ..text = thought.text
      ..createdAt = thought.createdAt.toIso8601String()
      ..tags = thought.tags
      ..linkedNoteId = thought.linkedNoteId
      ..deletedAt = null);
    return id;
  }

  Future<void> softDeleteThought(int id) async {
    final h = _t.get(id) as HiveThought?;
    if (h != null) {
      h.deletedAt = DateTime.now().toIso8601String();
      await _t.put(id, h);
    }
  }

  Future<void> recoverThought(int id) async {
    final h = _t.get(id) as HiveThought?;
    if (h != null) {
      h.deletedAt = null;
      await _t.put(id, h);
    }
  }

  List<Thought> thoughtsInRange(DateTime from, DateTime to) {
    return allThoughts()
        .where((t) => !t.createdAt.isBefore(from) && !t.createdAt.isAfter(to))
        .toList();
  }

  List<Thought> searchThoughts(String query) {
    final q = query.toLowerCase();
    return allThoughts().where((t) => t.text.toLowerCase().contains(q)).toList();
  }

  // ── Link counts for cross-link density (Phase 2) ─────────
  int linkCountForNote(int noteId) {
    if (!Hive.isBoxOpen(_lb)) return 0;
    return _l.values
        .where((e) {
          final link = e as HiveLink;
          return link.fromNoteId == noteId || link.toNoteId == noteId;
        })
        .length;
  }

  /// Returns a map of note id -> link count for all notes, computed once.
  List<HiveLink> get allLinks => Hive.isBoxOpen(_lb) ? _l.values.cast<HiveLink>().toList() : [];


  Map<int, int> linkCountsByNote() {
    if (!Hive.isBoxOpen(_lb)) return {};
    final m = <int, int>{};
    for (final e in _l.values) {
      final l = e as HiveLink;
      final f = l.fromNoteId, t = l.toNoteId;
      if (f != null) m[f] = (m[f] ?? 0) + 1;
      if (t != null) m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }

  HiveNote _nT(Note n, int id) => HiveNote()
    ..id = id
    ..title = n.title
    ..body = n.body
    ..kind = n.kind.name
    ..createdAt = n.createdAt.toIso8601String()
    ..updatedAt = n.updatedAt.toIso8601String()
    ..cardState = _eC(n.card.toMap())
    ..cardDue = n.card.due.toIso8601String()
    ..linkIds = n.linkIds;

  Note _nF(HiveNote h) => Note(
    id: h.id ?? 0,
    title: h.title ?? '(untitled)',
    body: h.body ?? '',
    kind: NoteKind.values.byName(h.kind ?? NoteKind.blurtSummary.name),
    createdAt: DateTime.tryParse(h.createdAt ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(h.updatedAt ?? '') ?? DateTime.now(),
    card: Card.fromMap(_dC(h.cardState ?? '')),
    linkIds: (h.linkIds ?? const []).cast<int>(),
  );

  HiveSession _sT(Session s, int id) => HiveSession()
    ..id = id
    ..date = s.date.toIso8601String()
    ..durationMs = s.duration.inMilliseconds
    ..stepsCompleted = s.stepsCompleted
    ..anchorNoteId = s.anchorNoteId
    ..anchorTitle = s.anchorTitle
    ..autosaveJson = s.autosaveJson
    ..focusPrimed = s.focusPrimed;

  Session _sR(HiveSession h) => Session(
    id: h.id ?? 0,
    date: DateTime.tryParse(h.date ?? '') ?? DateTime.now(),
    duration: Duration(milliseconds: h.durationMs ?? 0),
    stepsCompleted: h.stepsCompleted ?? 0,
    anchorNoteId: h.anchorNoteId,
    anchorTitle: h.anchorTitle ?? '',
    autosaveJson: h.autosaveJson,
    focusPrimed: h.focusPrimed ?? false,
  );

  HiveBlurtScore _bT(BlurtScore b, int id) => HiveBlurtScore()
    ..id = id
    ..noteId = b.noteId
    ..noteTitle = b.noteTitle
    ..date = b.date.toIso8601String()
    ..scorePct = b.scorePct
    ..matched = b.matched
    ..missed = b.missed
    ..recallSpeedMs = b.recallSpeedMs
    ..depthScore = b.depthScore
    ..clarityScore = b.clarityScore;

  BlurtScore _bF(HiveBlurtScore h) => BlurtScore(
    id: h.id ?? 0,
    noteId: h.noteId ?? 0,
    noteTitle: h.noteTitle ?? '',
    date: DateTime.tryParse(h.date ?? '') ?? DateTime.now(),
    scorePct: h.scorePct ?? 0.0,
    matched: h.matched ?? [],
    missed: h.missed ?? [],
    recallSpeedMs: h.recallSpeedMs,
    depthScore: h.depthScore,
    clarityScore: h.clarityScore,
  );

  HivePathwayRecord _pT(PathwayRecord p, int id) => HivePathwayRecord()
    ..id = id
    ..date = p.date.toIso8601String()
    ..retrieval = p.retrieval
    ..compression = p.compression
    ..association = p.association
    ..explanation = p.explanation
    ..context = p.context
    ..graceUsed = p.graceUsed;

  PathwayRecord _pF(HivePathwayRecord h) => PathwayRecord(
    id: h.id ?? 0,
    date: DateTime.tryParse(h.date ?? '') ?? DateTime.now(),
    retrieval: h.retrieval ?? false,
    compression: h.compression ?? false,
    association: h.association ?? false,
    explanation: h.explanation ?? false,
    context: h.context ?? false,
    graceUsed: h.graceUsed ?? false,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LearningEvidence layer (schema v6).
  // ══════════════════════════════════════════════════════════════════════════

  // ── Attempts ────────────────────────────────────────────────────────────
  Future<int> insertAttempt(LearningAttempt a) async {
    if (!Hive.isBoxOpen(_ab)) return -1;
    final id = _nextId(_ab);
    await _a.put(id, _attemptToHive(a, id));
    return id;
  }

  /// Alias for [insertAttempt].
  Future<int> recordLearningAttempt(LearningAttempt a) => insertAttempt(a);

  Future<void> updateAttempt(LearningAttempt a) async {
    if (!Hive.isBoxOpen(_ab)) return;
    await _a.put(a.id, _attemptToHive(a, a.id));
  }

  List<LearningAttempt> allAttempts() {
    if (!Hive.isBoxOpen(_ab)) return [];
    final out = <LearningAttempt>[];
    for (final e in _a.values) {
      final h = e is HiveAttempt ? e : null;
      final parsed = h == null ? null : _attemptFromHive(h);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  LearningAttempt? attemptById(int id) {
    if (!Hive.isBoxOpen(_ab)) return null;
    final h = _a.get(id);
    return h is HiveAttempt ? _attemptFromHive(h) : null;
  }

  List<LearningAttempt> attemptsForTarget(int targetId) =>
      allAttempts().where((a) => a.knowledgeTargetId == targetId).toList();

  List<LearningAttempt> recentAttempts({int limit = 200}) {
    final all = allAttempts()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  HiveAttempt _attemptToHive(LearningAttempt a, int id) => HiveAttempt()
    ..id = id
    ..timestamp = a.timestamp.toIso8601String()
    ..knowledgeTargetId = a.knowledgeTargetId
    ..sessionId = a.sessionId
    ..testType = a.testType.name
    ..response = a.response
    ..correctness = a.correctness.name
    ..scorePct = a.scorePct.isNaN ? null : a.scorePct
    ..responseTimeMs = a.responseTimeMs
    ..confidence = a.confidence
    ..difficulty = a.difficulty
    ..extras = a.extras
    ..feedbackId = a.feedbackId
    ..errorIds = a.errorIds
    ..interventionId = a.interventionId
    ..delayedOutcomeId = a.delayedOutcomeId
    ..wasInterleaved = a.wasInterleaved
    ..interleaveGroupId = a.interleaveGroupId
    ..interleaveReason = a.interleaveReason
    ..acquiredAt = a.acquiredAt?.toIso8601String();

  static LearningAttempt? _attemptFromHive(HiveAttempt h) {
    final testType = _testTypeFrom(h.testType);
    if (testType == null) return null;
    final ts = DateTime.tryParse(h.timestamp ?? '');
    if (ts == null) return null;
    return LearningAttempt(
      id: h.id ?? 0,
      timestamp: ts,
      knowledgeTargetId: h.knowledgeTargetId,
      sessionId: h.sessionId,
      testType: testType,
      response: h.response ?? '',
      correctness: Correctness.tryParse(h.correctness) ?? Correctness.unknown,
      scorePct: h.scorePct ?? double.nan,
      responseTimeMs: h.responseTimeMs,
      confidence: h.confidence,
      difficulty: h.difficulty,
      extras: h.extras ?? const {},
      feedbackId: h.feedbackId,
      errorIds: h.errorIds ?? const [],
      interventionId: h.interventionId,
      delayedOutcomeId: h.delayedOutcomeId,
      wasInterleaved: h.wasInterleaved ?? false,
      interleaveGroupId: h.interleaveGroupId,
      interleaveReason: h.interleaveReason,
      acquiredAt: h.acquiredAt == null ? null : DateTime.tryParse(h.acquiredAt!),
    );
  }

  static TestType? _testTypeFrom(String? name) {
    if (name == null) return null;
    for (final t in TestType.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  // ── Feedback ────────────────────────────────────────────────────────────
  Future<int> insertFeedback(FeedbackRecord f) async {
    if (!Hive.isBoxOpen(_fb)) return -1;
    final id = _nextId(_fb);
    await _f.put(id, HiveFeedback()
      ..id = id
      ..attemptId = f.attemptId
      ..createdAt = f.createdAt.toIso8601String()
      ..correctness = f.correctness.name
      ..scorePct = f.scorePct
      ..correctPoints = f.correctPoints
      ..missing = f.missing
      ..incorrect = f.incorrect
      ..nextAction = f.nextAction
      ..fromAi = f.fromAi);
    return id;
  }

  FeedbackRecord? feedbackForAttempt(int attemptId) {
    if (!Hive.isBoxOpen(_fb)) return null;
    for (final e in _f.values) {
      if (e is! HiveFeedback || e.attemptId != attemptId) continue;
      final ts = DateTime.tryParse(e.createdAt ?? '');
      if (ts == null) continue;
      return FeedbackRecord(
        id: e.id ?? 0,
        attemptId: attemptId,
        createdAt: ts,
        correctness: Correctness.tryParse(e.correctness) ?? Correctness.unknown,
        scorePct: e.scorePct ?? double.nan,
        correctPoints: e.correctPoints ?? const [],
        missing: e.missing ?? const [],
        incorrect: e.incorrect ?? const [],
        nextAction: e.nextAction ?? '',
        fromAi: e.fromAi ?? false,
      );
    }
    return null;
  }

  // ── Errors ──────────────────────────────────────────────────────────────
  Future<int> insertError(ErrorRecord err) async {
    if (!Hive.isBoxOpen(_eb)) return -1;
    final id = _nextId(_eb);
    await _e.put(id, HiveError()
      ..id = id
      ..attemptId = err.attemptId
      ..type = err.type.name
      ..source = err.source.name
      ..confidence = err.confidence
      ..evidence = err.evidence
      ..createdAt = err.createdAt.toIso8601String());
    return id;
  }

  List<ErrorRecord> errorsForAttempt(int attemptId) {
    if (!Hive.isBoxOpen(_eb)) return [];
    final out = <ErrorRecord>[];
    for (final e in _e.values) {
      if (e is! HiveError || e.attemptId != attemptId) continue;
      final type = ErrorType.tryParse(e.type);
      final ts = DateTime.tryParse(e.createdAt ?? '');
      if (type == null || ts == null) continue;
      out.add(ErrorRecord(
        id: e.id ?? 0,
        attemptId: attemptId,
        type: type,
        source: DiagnosisSource.tryParse(e.source) ?? DiagnosisSource.deterministic,
        confidence: e.confidence ?? 1.0,
        evidence: e.evidence ?? '',
        createdAt: ts,
      ));
    }
    return out;
  }

  List<ErrorRecord> allErrors() {
    if (!Hive.isBoxOpen(_eb)) return [];
    final out = <ErrorRecord>[];
    for (final e in _e.values) {
      if (e is! HiveError) continue;
      final type = ErrorType.tryParse(e.type);
      final ts = DateTime.tryParse(e.createdAt ?? '');
      if (type == null || ts == null) continue;
      out.add(ErrorRecord(
        id: e.id ?? 0,
        attemptId: e.attemptId ?? 0,
        type: type,
        source: DiagnosisSource.tryParse(e.source) ?? DiagnosisSource.deterministic,
        confidence: e.confidence ?? 1.0,
        evidence: e.evidence ?? '',
        createdAt: ts,
      ));
    }
    return out;
  }

  // ── Delayed outcomes ────────────────────────────────────────────────────
  Future<int> insertDelayedOutcome(DelayedOutcome o) async {
    if (!Hive.isBoxOpen(_db)) return -1;
    final id = _nextId(_db);
    await _do.put(id, HiveDelayedOutcome()
      ..id = id
      ..knowledgeTargetId = o.knowledgeTargetId
      ..attemptId = o.attemptId
      ..measuredAt = o.measuredAt.toIso8601String()
      ..sourceAttemptId = o.sourceAttemptId
      ..bucket = o.bucket.name
      ..elapsedMs = o.elapsed.inMilliseconds
      ..correctness = o.correctness.name
      ..scorePct = o.scorePct
      ..experimentId = o.experimentId);
    return id;
  }

  List<DelayedOutcome> allDelayedOutcomes() {
    if (!Hive.isBoxOpen(_db)) return [];
    final out = <DelayedOutcome>[];
    for (final e in _do.values) {
      if (e is! HiveDelayedOutcome) continue;
      final measuredAt = DateTime.tryParse(e.measuredAt ?? '');
      final bucket = _delayBucketFrom(e.bucket);
      if (measuredAt == null || bucket == null) continue;
      out.add(DelayedOutcome(
        id: e.id ?? 0,
        knowledgeTargetId: e.knowledgeTargetId ?? 0,
        attemptId: e.attemptId ?? 0,
        measuredAt: measuredAt,
        sourceAttemptId: e.sourceAttemptId,
        bucket: bucket,
        elapsed: Duration(milliseconds: e.elapsedMs ?? 0),
        correctness: Correctness.tryParse(e.correctness) ?? Correctness.unknown,
        scorePct: e.scorePct ?? double.nan,
        experimentId: e.experimentId,
      ));
    }
    return out;
  }

  List<DelayedOutcome> delayedOutcomesForTarget(int targetId) =>
      allDelayedOutcomes().where((o) => o.knowledgeTargetId == targetId).toList();

  static DelayBucket? _delayBucketFrom(String? name) {
    if (name == null) return null;
    for (final b in DelayBucket.values) {
      if (b.name == name) return b;
    }
    return null;
  }

  // ── Interventions ───────────────────────────────────────────────────────
  Future<int> insertIntervention(Intervention i) async {
    if (!Hive.isBoxOpen(_ib)) return -1;
    final id = _nextId(_ib);
    await _i.put(id, HiveIntervention()
      ..id = id
      ..createdAt = i.createdAt.toIso8601String()
      ..action = i.action.name
      ..reason = i.reason.name
      ..explanation = i.explanation
      ..knowledgeTargetId = i.knowledgeTargetId
      ..contrastTargetId = i.contrastTargetId
      ..attemptId = i.attemptId
      ..experimentId = i.experimentId
      ..thresholds = i.thresholds);
    return id;
  }

  List<Intervention> allInterventions() {
    if (!Hive.isBoxOpen(_ib)) return [];
    final out = <Intervention>[];
    for (final e in _i.values) {
      if (e is! HiveIntervention) continue;
      final action = _interventionActionFrom(e.action);
      final reason = _interventionReasonFrom(e.reason);
      final ts = DateTime.tryParse(e.createdAt ?? '');
      if (action == null || reason == null || ts == null) continue;
      out.add(Intervention(
        id: e.id ?? 0,
        createdAt: ts,
        action: action,
        reason: reason,
        explanation: e.explanation ?? '',
        knowledgeTargetId: e.knowledgeTargetId,
        contrastTargetId: e.contrastTargetId,
        attemptId: e.attemptId,
        experimentId: e.experimentId,
        thresholds: e.thresholds ?? const {},
      ));
    }
    return out;
  }

  static InterventionAction? _interventionActionFrom(String? name) {
    if (name == null) return null;
    for (final a in InterventionAction.values) {
      if (a.name == name) return a;
    }
    return null;
  }

  static InterventionReason? _interventionReasonFrom(String? name) {
    if (name == null) return null;
    for (final r in InterventionReason.values) {
      if (r.name == name) return r;
    }
    return null;
  }

  // ── Experiments ─────────────────────────────────────────────────────────
  Future<int> insertExperiment(Experiment x) async {
    if (!Hive.isBoxOpen(_xb)) return -1;
    final id = _nextId(_xb);
    await _x.put(id, HiveExperiment()
      ..id = id
      ..hypothesis = x.hypothesis
      ..conditionsJson = jsonEncode([
        for (final c in x.conditions)
          {'key': c.key, 'label': c.label, 'action': c.action.name},
      ])
      ..outcomeBuckets = x.outcomeBuckets.map((b) => b.name).toList()
      ..targetConceptTypeFilter = x.targetConceptTypeFilter
      ..minAttemptsPerCondition = x.minAttemptsPerCondition
      ..startedAt = x.startedAt.toIso8601String()
      ..endedAt = x.endedAt?.toIso8601String()
      ..active = x.active);
    return id;
  }

  Future<void> updateExperiment(Experiment x) async {
    if (!Hive.isBoxOpen(_xb)) return;
    await _x.put(x.id, HiveExperiment()
      ..id = x.id
      ..hypothesis = x.hypothesis
      ..conditionsJson = jsonEncode([
        for (final c in x.conditions)
          {'key': c.key, 'label': c.label, 'action': c.action.name},
      ])
      ..outcomeBuckets = x.outcomeBuckets.map((b) => b.name).toList()
      ..targetConceptTypeFilter = x.targetConceptTypeFilter
      ..minAttemptsPerCondition = x.minAttemptsPerCondition
      ..startedAt = x.startedAt.toIso8601String()
      ..endedAt = x.endedAt?.toIso8601String()
      ..active = x.active);
  }

  List<Experiment> allExperiments() {
    if (!Hive.isBoxOpen(_xb)) return [];
    final out = <Experiment>[];
    for (final e in _x.values) {
      if (e is! HiveExperiment) continue;
      final started = DateTime.tryParse(e.startedAt ?? '');
      if (started == null) continue;
      out.add(Experiment(
        id: e.id ?? 0,
        hypothesis: e.hypothesis ?? '',
        conditions: _conditionsFrom(e.conditionsJson),
        outcomeBuckets: _bucketsFrom(e.outcomeBuckets),
        targetConceptTypeFilter: e.targetConceptTypeFilter,
        minAttemptsPerCondition: e.minAttemptsPerCondition ?? 4,
        startedAt: started,
        endedAt: e.endedAt == null ? null : DateTime.tryParse(e.endedAt!),
        active: e.active ?? false,
      ));
    }
    return out;
  }

  List<Experiment> activeExperiments() =>
      allExperiments().where((x) => x.active).toList();

  static List<ExperimentCondition> _conditionsFrom(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final raw = jsonDecode(json);
      if (raw is! List) return const [];
      final out = <ExperimentCondition>[];
      for (final c in raw) {
        if (c is! Map) continue;
        final key = c['key']?.toString() ?? '';
        final actionName = c['action']?.toString();
        final action = _interventionActionFrom(actionName);
        if (key.isEmpty || action == null) continue;
        out.add(ExperimentCondition(
          key: key,
          label: c['label']?.toString() ?? key,
          action: action,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('_conditionsFrom: malformed conditions JSON: $e');
      return const [];
    }
  }

  static Set<DelayBucket> _bucketsFrom(List<String>? names) {
    if (names == null || names.isEmpty) {
      return const {DelayBucket.mediumDelay, DelayBucket.longDelay};
    }
    final out = <DelayBucket>{};
    for (final n in names) {
      final b = _delayBucketFrom(n);
      if (b != null) out.add(b);
    }
    return out.isEmpty
        ? const {DelayBucket.mediumDelay, DelayBucket.longDelay}
        : out;
  }

  // ── Focus integrity ─────────────────────────────────────────────────────
  Future<void> upsertFocus(FocusIntegrity f) async {
    if (!Hive.isBoxOpen(_fob)) return;
    final key = f.sessionId ?? 0;
    await _fo.put(key, HiveFocusIntegrity()
      ..sessionId = f.sessionId
      ..plannedDurationMs = f.plannedDuration?.inMilliseconds
      ..actualDurationMs = f.actualDuration.inMilliseconds
      ..interruptions = f.interruptions
      ..taskSwitches = f.taskSwitches
      ..abandoned = f.abandoned
      ..completed = f.completed
      ..longestFocusMs = f.longestFocusMs);
  }

  List<FocusIntegrity> allFocus() {
    if (!Hive.isBoxOpen(_fob)) return [];
    final out = <FocusIntegrity>[];
    for (final e in _fo.values) {
      if (e is! HiveFocusIntegrity) continue;
      out.add(FocusIntegrity(
        sessionId: e.sessionId,
        plannedDuration: e.plannedDurationMs == null
            ? null
            : Duration(milliseconds: e.plannedDurationMs!),
        actualDuration: Duration(milliseconds: e.actualDurationMs ?? 0),
        interruptions: e.interruptions ?? 0,
        taskSwitches: e.taskSwitches ?? 0,
        abandoned: e.abandoned ?? false,
        completed: e.completed ?? false,
        longestFocusMs: e.longestFocusMs,
      ));
    }
    return out;
  }

  FocusIntegrity? focusForSession(int sessionId) {
    if (!Hive.isBoxOpen(_fob)) return null;
    for (final f in allFocus()) {
      if (f.sessionId == sessionId) return f;
    }
    return null;
  }

  // ── Concept profiles (target type; §31) ─────────────────────────────────
  Future<void> setConceptType(int noteId, ConceptType type) async {
    if (!Hive.isBoxOpen(_cpb)) return;
    await _cp.put(noteId, HiveConceptProfile()
      ..noteId = noteId
      ..conceptType = type.name
      ..updatedAt = DateTime.now().toIso8601String());
  }

  ConceptType conceptTypeFor(int noteId) {
    if (!Hive.isBoxOpen(_cpb)) return ConceptType.unclassified;
    final h = _cp.get(noteId);
    if (h is! HiveConceptProfile) return ConceptType.unclassified;
    return ConceptType.tryParse(h.conceptType) ?? ConceptType.unclassified;
  }
  // ── Knowledge Evidence (§33) ──────────────────────────────────────────
  KnowledgeEvidence summarizeKnowledgeEvidence(int noteId) {
    final attempts = attemptsForTarget(noteId);
    final delayed = delayedOutcomesForTarget(noteId);
    final linkCounts = linkCountsByNote();
    final dependents = linkCounts[noteId] ?? 0;

    int retAtt = 0, retSucc = 0;
    int delAtt = 0, delSucc = 0;
    int appAtt = 0, appSucc = 0;
    int traAtt = 0, traSucc = 0;
    int expAtt = 0;
    int unkOut = 0;
    double sumCalError = 0;
    int calCount = 0;

    for (final a in attempts) {
      if (a.correctness == Correctness.unknown) {
        unkOut++;
        continue;
      }
      if (a.confidence != null && !a.scorePct.isNaN) {
        sumCalError += (a.confidence! - a.scorePct);
        calCount++;
      }

      switch (a.testType) {
        case TestType.freeRecall:
        case TestType.cuedRecall:
        case TestType.pretest:
          retAtt++;
          if (!a.correctness.isFail) retSucc++;
          break;
        case TestType.application:
          appAtt++;
          if (!a.correctness.isFail) appSucc++;
          break;
        case TestType.transfer:
          traAtt++;
          if (!a.correctness.isFail) traSucc++;
          break;
        case TestType.explanation:
          expAtt++;
          break;
        case TestType.reconstruction:
        case TestType.discrimination:
        case TestType.workedExample:
          retAtt++;
          if (!a.correctness.isFail) retSucc++;
          break;
      }
    }

    for (final d in delayed) {
      delAtt++;
      if (!d.correctness.isFail) delSucc++;
    }

    final summary = EvidenceSummary(
      retrievalAttempts: retAtt,
      retrievalSuccesses: retSucc,
      delayedAttempts: delAtt,
      delayedSuccesses: delSucc,
      applicationAttempts: appAtt,
      applicationSuccesses: appSucc,
      transferAttempts: traAtt,
      transferSuccesses: traSucc,
      explanationAttempts: expAtt,
      unknownOutcomes: unkOut,
      meanCalibrationError: calCount > 0 ? sumCalError / calCount : null,
      dependents: dependents,
    );

    KnowledgeState state = KnowledgeState.unknown;
    if (summary.totalAttempts == 0) {
      state = KnowledgeState.unknown;
    } else if (delSucc >= 2) {
      state = KnowledgeState.stable;
    } else if (summary.successfulModes >= 2) {
      state = KnowledgeState.verified;
    } else if (retSucc >= 2) {
      state = KnowledgeState.probable;
    } else if (dependents > 2 && (retAtt > 0 && retSucc == 0)) {
      state = KnowledgeState.bottleneck;
    } else {
      state = KnowledgeState.developing;
    }

    final confidence = (summary.totalAttempts / 10.0).clamp(0.0, 1.0);
    final rationale = '${summary.retrievalAttempts} retrieval attempts, ${summary.delayedSuccesses} delayed successes, ${summary.applicationSuccesses} application successes';

    return KnowledgeEvidence(
      knowledgeTargetId: noteId,
      state: state,
      evidence: summary,
      rationale: rationale,
      confidence: confidence,
    );
  }


  String _eC(Map<String, dynamic> m) => jsonEncode(m);

  Map<String, dynamic> _dC(String s) {
    if (s.trim().isEmpty) return <String, dynamic>{};
    try {
      return (jsonDecode(s) as Map).cast<String, dynamic>();
    } catch (e) {
      debugPrint('_dC: corrupt cardState JSON: $e');
      return <String, dynamic>{};
    }
  }
}