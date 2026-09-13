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

  /// Laziest serialization that still round-trips for a personal app.
  /// The FSRS `Card` knows how to serialize itself via toMap/fromMap.
  Map<String, dynamic> toMap() => {
        'v': 1,
        'id': id,
        'title': title,
        'body': body,
        'kind': kind.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'card': card.toMap(),
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as int,
        title: m['title'] as String,
        body: m['body'] as String,
        kind: NoteKind.values.byName(m['kind'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        card: Card.fromMap((m['card'] as Map).cast<String, dynamic>()),
      );
}