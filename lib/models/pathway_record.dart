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

  /// Persistence: see HivePathwayRecordAdapter in app_database.g.dart.
  /// Export: see data/serialization/export_dto.dart.
}