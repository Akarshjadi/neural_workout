/// Captures one completed (or in-progress) 8-step workout session.
///
/// The whole point of tracking sessions is to feed the analytics tab
/// (timeline + history + reports) and to compute pathway activation. The
/// `autosaveJson` field carries the wizard's in-progress state (wip_json in
/// the architecture doc) so a phone call / OS kill loses seconds, not a
/// whole session.
class Session {
  final int id;
  final DateTime date;
  final Duration duration;
  final int stepsCompleted; // 0..8
  final int? anchorNoteId;
  final String? anchorTitle;
  final String? autosaveJson; // serialized wizard WIP for resume
  final bool focusPrimed;

  const Session({
    required this.id,
    required this.date,
    required this.duration,
    required this.stepsCompleted,
    this.anchorNoteId,
    this.anchorTitle,
    this.autosaveJson,
    this.focusPrimed = false,
  });

  /// Persistence: see HiveSessionAdapter in app_database.g.dart.
  /// Export: see data/serialization/export_dto.dart.
}