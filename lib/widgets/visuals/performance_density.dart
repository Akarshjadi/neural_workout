import 'package:flutter/material.dart';
import '../../models/learning_attempt.dart';
import '../../ui/theme_notebook.dart';

/// Item 238 — PerformanceDensity.
///
/// Attempts-per-active-day over the last [weeks] weeks. This is the honest
/// "am I actually practising?" view: it counts recorded attempts, not time
/// spent staring at the app, and it makes gaps visible instead of averaging
/// them away the way a single retention percentage would.
class PerformanceDensity extends StatelessWidget {
  final List<LearningAttempt> attempts;
  final int weeks;

  const PerformanceDensity({
    super.key,
    required this.attempts,
    this.weeks = 8,
  });

  /// Returns attempts-per-day for the trailing [weeks] weeks, oldest first.
  /// Days with no attempts are `0`, not skipped.
  static List<({DateTime day, int count})> dailyCounts(
    List<LearningAttempt> attempts, {
    int weeks = 8,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(Duration(days: weeks * 7 - 1));

    final counts = <String, int>{};
    for (final a in attempts) {
      final d = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      if (d.isBefore(start) || d.isAfter(end)) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final out = <({DateTime day, int count})>[];
    for (int i = 0; i < weeks * 7; i++) {
      final day = start.add(Duration(days: i));
      out.add((day: day, count: counts['${day.year}-${day.month}-${day.day}'] ?? 0));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final days = dailyCounts(attempts, weeks: weeks);
    final total = days.fold<int>(0, (a, d) => a + d.count);
    final active = days.where((d) => d.count > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PERFORMANCE DENSITY',
                style: Theme.of(context).textTheme.labelSmall),
            Text('$active / ${weeks * 7} ACTIVE DAYS',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border:
                Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int w = 0; w < weeks; w++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      for (int d = 0; d < 7; d++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: _cell(days[w * 7 + d].count),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$total ATTEMPTS IN ${weeks}W · EACH CELL = 1 DAY',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 7.5, color: NotebookTheme.graphite),
        ),
      ],
    );
  }

  Widget _cell(int count) {
    if (count == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(
              color: NotebookTheme.graphite.withValues(alpha: 0.25),
              width: 0.5),
        ),
      );
    }
    // Saturates at 10 attempts/day; beyond that the difference is noise.
    final intensity = (count / 10).clamp(0.15, 1.0);
    return Container(
      height: 10,
      color: NotebookTheme.oxblood.withValues(alpha: intensity),
    );
  }
}
