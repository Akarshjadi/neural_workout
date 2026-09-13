import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/thought.dart';
import '../models/blurt_score.dart';
import '../models/note.dart';
import '../models/session.dart';
import '../models/pathway_record.dart';

/// Phase 3 — Export service for CSV and JSON backup exports.
class ExportService {
  /// Export thoughts to a CSV file.
  Future<String> exportThoughtsCsv(List<Thought> thoughts) async {
    final rows = <List<String>>[
      ['id', 'text', 'created_at', 'tags', 'linked_note_id'],
      for (final t in thoughts)
        [
          t.id.toString(),
          t.text,
          t.createdAt.toIso8601String(),
          t.tags.join(','),
          t.linkedNoteId?.toString() ?? '',
        ],
    ];
    return _writeFile('thoughts.csv', rows);
  }

  /// Export all app data into a combined CSV file.
  Future<String> exportAllCsv({
    required List<Thought> thoughts,
    required List<BlurtScore> blurtScores,
    required List<Note> notes,
    required List<Session> sessions,
    required List<PathwayRecord> pathways,
  }) async {
    final rows = <List<String>>[
      ['=== NOTES ==='],
      ['id', 'title', 'body', 'kind', 'created_at', 'updated_at'],
      for (final n in notes)
        [
          n.id.toString(),
          n.title,
          n.body,
          n.kind.name,
          n.createdAt.toIso8601String(),
          n.updatedAt.toIso8601String(),
        ],
      [],
      ['=== SESSIONS ==='],
      ['id', 'date', 'duration_ms', 'steps_completed', 'anchor_note_id', 'anchor_title'],
      for (final s in sessions)
        [
          s.id.toString(),
          s.date.toIso8601String(),
          s.duration.inMilliseconds.toString(),
          s.stepsCompleted.toString(),
          s.anchorNoteId?.toString() ?? '',
          s.anchorTitle ?? '',
        ],
      [],
      ['=== BLURT SCORES ==='],
      ['id', 'note_id', 'note_title', 'date', 'score_pct', 'matched', 'missed', 'recall_speed_ms', 'depth_score', 'clarity_score'],
      for (final b in blurtScores)
        [
          b.id.toString(),
          b.noteId.toString(),
          b.noteTitle,
          b.date.toIso8601String(),
          b.scorePct.toString(),
          b.matched.join('; '),
          b.missed.join('; '),
          b.recallSpeedMs?.toString() ?? '',
          b.depthScore?.toString() ?? '',
          b.clarityScore?.toString() ?? '',
        ],
      [],
      ['=== PATHWAYS ==='],
      ['id', 'date', 'retrieval', 'compression', 'association', 'explanation', 'context', 'grace_used'],
      for (final p in pathways)
        [
          p.id.toString(),
          p.date.toIso8601String(),
          p.retrieval.toString(),
          p.compression.toString(),
          p.association.toString(),
          p.explanation.toString(),
          p.context.toString(),
          p.graceUsed.toString(),
        ],
      [],
      ['=== THOUGHTS ==='],
      ['id', 'text', 'created_at', 'tags', 'linked_note_id'],
      for (final t in thoughts)
        [
          t.id.toString(),
          t.text,
          t.createdAt.toIso8601String(),
          t.tags.join(','),
          t.linkedNoteId?.toString() ?? '',
        ],
    ];
    return _writeFile('export_all.csv', rows);
  }

  /// Export complete app state as JSON backup.
  Future<String> exportBackup({
    required int schemaVersion,
    required List<Note> notes,
    required List<Session> sessions,
    required List<BlurtScore> blurtScores,
    required List<PathwayRecord> pathways,
    required List<Thought> thoughts,
  }) async {
    final backup = {
      'schemaVersion': schemaVersion,
      'notes': notes.map((n) => n.toMap()).toList(),
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'blurtScores': blurtScores.map((b) => b.toMap()).toList(),
      'pathways': pathways.map((p) => p.toMap()).toList(),
      'thoughts': thoughts.map((t) => t.toMap()).toList(),
    };
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/neural_workout_backup_$timestamp.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(backup));
    return path;
  }

  String _sanitize(String cell) {
    if (cell.startsWith('=') || cell.startsWith('+') || cell.startsWith('-') || cell.startsWith('@')) {
      return "'$cell";
    }
    return cell;
  }

  Future<String> _writeFile(String filename, List<List<String>> rows) async {
    final sanitizedRows = rows.map((row) => row.map(_sanitize).toList()).toList();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    final csv = const ListToCsvConverter().convert(sanitizedRows);
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}

