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

  /// Persistence: see HiveThoughtAdapter in app_database.g.dart.
  /// Export: see data/serialization/export_dto.dart.
}
