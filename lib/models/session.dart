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

  const Session({
    required this.id,
    required this.date,
    required this.duration,
    required this.stepsCompleted,
    this.anchorNoteId,
    this.anchorTitle,
    this.autosaveJson,
  });

  Map<String, dynamic> toMap() => {
        'v': 1,
        'id': id,
        'date': date.toIso8601String(),
        'duration_ms': duration.inMilliseconds,
        'steps_completed': stepsCompleted,
        'anchor_note_id': anchorNoteId,
        'anchor_title': anchorTitle,
        'autosave_json': autosaveJson,
      };

  factory Session.fromMap(Map<String, dynamic> m) => Session(
        id: m['id'] as int,
        date: DateTime.parse(m['date'] as String),
        duration: Duration(milliseconds: m['duration_ms'] as int),
        stepsCompleted: m['steps_completed'] as int,
        anchorNoteId: m['anchor_note_id'] as int?,
        anchorTitle: m['anchor_title'] as String?,
        autosaveJson: m['autosave_json'] as String?,
      );
}