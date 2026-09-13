/// A quick thought / idea captured by the user.
class Thought {
  final int id;
  final String text;
  final DateTime createdAt;
  final List<String> tags;
  final int? linkedNoteId;

  const Thought({
    required this.id,
    required this.text,
    required this.createdAt,
    this.tags = const [],
    this.linkedNoteId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'tags': tags.join(','),
        'linked_note_id': linkedNoteId,
      };
}
