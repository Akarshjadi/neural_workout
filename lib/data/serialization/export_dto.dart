/// Export serialization DTOs — the single source of truth for backup/export shapes.
///
/// Domain models (Note, Session, BlurtScore, PathwayRecord, Thought) no longer own
/// toMap/fromMap. Hive adapters own persistence; this file owns export formats.
library;

import '../../models/note.dart';
import '../../models/session.dart';
import '../../models/blurt_score.dart';
import '../../models/pathway_record.dart';
import '../../models/thought.dart';

/// Serialize a Note for JSON backup export.
Map<String, dynamic> noteToJson(Note n) => {
      'v': 1,
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'kind': n.kind.name,
      'created_at': n.createdAt.toIso8601String(),
      'updated_at': n.updatedAt.toIso8601String(),
      'card': n.card.toMap(),
    };

/// Serialize a Session for JSON backup export.
Map<String, dynamic> sessionToJson(Session s) => {
      'v': 1,
      'id': s.id,
      'date': s.date.toIso8601String(),
      'duration_ms': s.duration.inMilliseconds,
      'steps_completed': s.stepsCompleted,
      'anchor_note_id': s.anchorNoteId,
      'anchor_title': s.anchorTitle,
      'autosave_json': s.autosaveJson,
    };

/// Serialize a BlurtScore for JSON backup export.
Map<String, dynamic> blurtScoreToJson(BlurtScore b) => {
      'v': 1,
      'id': b.id,
      'note_id': b.noteId,
      'note_title': b.noteTitle,
      'date': b.date.toIso8601String(),
      'score_pct': b.scorePct,
      'matched': b.matched,
      'missed': b.missed,
      'recall_speed_ms': b.recallSpeedMs,
      'depth_score': b.depthScore,
      'clarity_score': b.clarityScore,
    };

/// Serialize a PathwayRecord for JSON backup export.
Map<String, dynamic> pathwayRecordToJson(PathwayRecord p) => {
      'v': 1,
      'id': p.id,
      'date': p.date.toIso8601String(),
      'retrieval': p.retrieval,
      'compression': p.compression,
      'association': p.association,
      'explanation': p.explanation,
      'context': p.context,
      'grace_used': p.graceUsed,
    };

/// Serialize a Thought for JSON backup export.
Map<String, dynamic> thoughtToJson(Thought t) => {
      'id': t.id,
      'text': t.text,
      'created_at': t.createdAt.toIso8601String(),
      'tags': t.tags,
      'linked_note_id': t.linkedNoteId,
    };
