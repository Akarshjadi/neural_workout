
enum BreakTier { micro, meso, macroMonthly }

class BreakRecord {
  final int id;
  final BreakTier tier;
  final DateTime startedAt;
  final Duration duration;
  final String? note;
  final bool completed;

  const BreakRecord({
    required this.id,
    required this.tier,
    required this.startedAt,
    required this.duration,
    this.note,
    this.completed = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tier': tier.index,
    'startedAt': startedAt.toIso8601String(),
    'duration': duration.inMilliseconds,
    'note': note,
    'completed': completed,
  };

  factory BreakRecord.fromJson(Map<String, dynamic> json) {
    return BreakRecord(
      id: json['id'] as int,
      tier: BreakTier.values[json['tier'] as int],
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
      note: json['note'] as String?,
      completed: json['completed'] as bool? ?? true,
    );
  }
}

