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


/// Local database access using Hive.
///
/// Precondition: Readers and writers assume Hive boxes have been opened via
/// [AppDatabase.ensureInitialized()]. Reader methods include defensive checks
/// (`Hive.isBoxOpen`) returning empty results if called prior to initialization.
class AppDatabase {
  static const _nb = 'notes', _sb = 'sessions', _bb = 'blurt_scores', _pb = 'pathway_records', _rb = 'reviews', _lb = 'links', _stb = 'settings', _mb = 'meta', _tb = 'thoughts', _cb = 'checkins';

  /// Schema version — bump when adding/removing fields or boxes.
  /// 1: initial  2: +deletedAt on Note  3: +metrics on BlurtScore  4: +Thought box 5: +Checkins +focusPrimed
  static const int schemaVersion = 5;

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
  }

  static Future<void> ensureInitialized() async {
    await Hive.initFlutter();
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
  }

  /// v1 → v2: Add deletedAt field to existing notes (defaults to null = not deleted).
  static void _migrateV1ToV2() {
    if (!Hive.isBoxOpen(_nb)) return;
    final box = Hive.box(_nb);
    for (final key in box.keys) {
      final note = box.get(key) as HiveNote?;
      if (note != null && note.deletedAt == null) {
        // Field already defaults to null; just ensure it's written.
        box.put(key, note);
      }
    }
  }

  /// v2 → v3: Add metrics fields to existing BlurtScore records.
  static void _migrateV2ToV3() {
    if (!Hive.isBoxOpen(_bb)) return;
    final box = Hive.box(_bb);
    for (final key in box.keys) {
      final score = box.get(key) as HiveBlurtScore?;
      if (score != null) {
        // New fields default to null; just rewrite to ensure schema consistency.
        box.put(key, score);
      }
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
    for (final key in box.keys) {
      final session = box.get(key) as HiveSession?;
      if (session != null && session.focusPrimed == null) {
        session.focusPrimed = false;
        box.put(key, session);
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
      _n.put(id, h);
    }
  }

  /// Recover a soft-deleted note.
  Future<void> recoverNote(int id) async {
    final h = _n.get(id) as HiveNote?;
    if (h != null) {
      h.deletedAt = null;
      _n.put(id, h);
    }
  }

  Future<int> insertNote(Note note) async {
    final id = _nextId(_nb);
    _n.put(id, _nT(note, id));
    return id;
  }

  Future<void> updateNote(Note note) async => _n.put(note.id, _nT(note, note.id));
  /// Soft-delete by default (recoverable). Use hardDeleteNote() for permanent removal.
  Future<void> deleteNote(int id) async => softDeleteNote(id);
  /// Permanent removal — also cleans up links, reviews, blurt scores, and thought links for this note.
  Future<void> hardDeleteNote(int id) async {
    _n.delete(id);
    // Clean up orphaned links.
    if (Hive.isBoxOpen(_lb)) {
      final linkBox = Hive.box(_lb);
      for (final key in linkBox.keys.toList()) {
        final link = linkBox.get(key) as HiveLink?;
        if (link != null && (link.fromNoteId == id || link.toNoteId == id)) {
          linkBox.delete(key);
        }
      }
    }
    // Clean up orphaned reviews.
    if (Hive.isBoxOpen(_rb)) {
      final reviewBox = Hive.box(_rb);
      for (final key in reviewBox.keys.toList()) {
        final review = reviewBox.get(key) as HiveReview?;
        if (review != null && review.noteId == id) {
          reviewBox.delete(key);
        }
      }
    }
    // Clean up orphaned blurt scores.
    if (Hive.isBoxOpen(_bb)) {
      final blurtBox = Hive.box(_bb);
      for (final key in blurtBox.keys.toList()) {
        final score = blurtBox.get(key) as HiveBlurtScore?;
        if (score != null && score.noteId == id) {
          blurtBox.delete(key);
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
          thoughtBox.put(key, thought);
        }
      }
    }
  }

  Future<int> insertSession(Session s) async {
    final id = _nextId(_sb);
    _s.put(id, _sT(s, id));
    return id;
  }

  Future<void> updateSession(Session s) async => _s.put(s.id, _sT(s, s.id));
  /// Legacy alias for updateSession.
  Future<void> updateSessionAutosave(Session s) async => updateSession(s);

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
    _b.put(id, _bT(bs, id));
    return id;
  }

  List<BlurtScore> allBlurtScores() {
    if (!Hive.isBoxOpen(_bb)) return [];
    return _b.values.map((e) => _bF(e as HiveBlurtScore)).toList();
  }

  Future<int> insertPathway(PathwayRecord pr) async {
    final id = _nextId(_pb);
    _p.put(id, _pT(pr, id));
    return id;
  }

  List<PathwayRecord> pathwayRecords() {
    if (!Hive.isBoxOpen(_pb)) return [];
    return _p.values.map((e) => _pF(e as HivePathwayRecord)).toList();
  }

  Future<int> insertReview(int noteId, Rating rating, {bool wasInterleaved = false}) async {
    final id = _nextId(_rb);
    _r.put(id, HiveReview()
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
    _l.put(id, HiveLink()..id = id ..fromNoteId = f ..toNoteId = t ..relationText = rel ..createdAt = DateTime.now().toIso8601String());
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
    _t.put(id, HiveThought()
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
      _t.put(id, h);
    }
  }

  Future<void> recoverThought(int id) async {
    final h = _t.get(id) as HiveThought?;
    if (h != null) {
      h.deletedAt = null;
      _t.put(id, h);
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

  HiveNote _nT(Note n, int id) => HiveNote()..id = id..title = n.title..body = n.body..kind = n.kind.name
    ..createdAt = n.createdAt.toIso8601String()..updatedAt = n.updatedAt.toIso8601String()
    ..cardState = _eC(n.card.toMap())..cardDue = n.card.due.toIso8601String();

  Note _nF(HiveNote h) => Note(
    id: h.id ?? 0,
    title: h.title ?? '(untitled)',
    body: h.body ?? '',
    kind: NoteKind.values.byName(h.kind ?? NoteKind.blurtSummary.name),
    createdAt: DateTime.tryParse(h.createdAt ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(h.updatedAt ?? '') ?? DateTime.now(),
    card: Card.fromMap(_dC(h.cardState ?? '')),
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