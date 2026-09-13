/// One row of pathway activity logging.
///
/// Feeds the "pathway activation bars" on the Today dashboard and the weekly
/// report. Each session appends whose pathways it touched (the 5 pathways),
/// and whether a grace token was consumed that day.
class PathwayRecord {
  final int id;
  final DateTime date;
  final bool retrieval;
  final bool compression;
  final bool association;
  final bool explanation;
  final bool context;
  final bool graceUsed;

  const PathwayRecord({
    required this.id,
    required this.date,
    required this.retrieval,
    required this.compression,
    required this.association,
    required this.explanation,
    required this.context,
    required this.graceUsed,
  });

  Map<String, dynamic> toMap() => {
        'v': 1,
        'id': id,
        'date': date.toIso8601String(),
        'retrieval': retrieval ? 1 : 0,
        'compression': compression ? 1 : 0,
        'association': association ? 1 : 0,
        'explanation': explanation ? 1 : 0,
        'context': context ? 1 : 0,
        'grace_used': graceUsed ? 1 : 0,
      };

  factory PathwayRecord.fromMap(Map<String, dynamic> m) => PathwayRecord(
        id: m['id'] as int,
        date: DateTime.parse(m['date'] as String),
        retrieval: (m['retrieval'] as int) == 1,
        compression: (m['compression'] as int) == 1,
        association: (m['association'] as int) == 1,
        explanation: (m['explanation'] as int) == 1,
        context: (m['context'] as int) == 1,
        graceUsed: (m['grace_used'] as int) == 1,
      );
}