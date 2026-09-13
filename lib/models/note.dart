import 'package:fsrs/fsrs.dart';

/// How a note was created — feeds the cold-start logic in the workflow.
enum NoteKind { cheatSheet, blurtSummary, imported }

/// A single atomic "concept" note in the Zettelkasten.
///
/// Each note is one idea. Its body becomes the "source" that later Blurt
/// sessions are diffed against (see BlurtScorer). Its FSRS state lives in
/// [card], which drives spaced repetition in the Review tab.
class Note {
  final int id;
  final String title;
  final String body;
  final NoteKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Card card; // FSRS per-card state (difficulty/stability/retrievability)

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    required this.card,
  });

  Note copyWith({
    int? id,
    String? title,
    String? body,
    NoteKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    Card? card,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      card: card ?? this.card,
    );
  }

  /// Persistence: see HiveNoteAdapter in app_database.g.dart.
  /// Export: see data/serialization/export_dto.dart.
}