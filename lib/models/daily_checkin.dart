class DailyCheckin {
  final DateTime date;
  final int sleep; // 1..5
  final int energy; // 1..5
  final int activity; // 1..5

  const DailyCheckin({
    required this.date,
    required this.sleep,
    required this.energy,
    required this.activity,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'sleep': sleep,
        'energy': energy,
        'activity': activity,
      };

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      date: DateTime.parse(json['date'] as String),
      sleep: json['sleep'] as int,
      energy: json['energy'] as int,
      activity: json['activity'] as int,
    );
  }
}
