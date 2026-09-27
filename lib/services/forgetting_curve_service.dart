import 'dart:math' as math;
import '../models/note.dart';

/// Pure Dart science models for memory decay.
/// 
/// Ebbinghaus's forgetting curve describes how memory retention decreases over
/// time. Modern spaced repetition (FSRS) generalizes this using "stability" (S),
/// which is the time in days for retention to drop to exactly 90% (or in 
/// some formulas 1/e, but we map it directly referencing the standard exponential).
///
/// Here we use the classic decay: R = e^(-t / S), where S = card.stability. 
class ForgettingCurveService {
  /// Returns retention [0.0..1.0] given [stabilityDays] (S) and [elapsedDays] (t).
  /// If elapsed < 0, returns 1.0. If S is zero or <= 0, returns 0.
  double retentionAt(double stabilityDays, double elapsedDays) {
    if (elapsedDays <= 0) return 1.0;
    if (stabilityDays <= 0) return 0.0;
    return math.exp(-elapsedDays / stabilityDays);
  }

  /// Calculates a 30-day projection series using the given [note]'s stability.
  /// If the note is not reviewed yet (S = 0), falls back to [fallbackStability].
  List<({double x, double y, Note note})> decaySeries(Note note, {double fallbackStability = 1.0}) {
    final s = (note.card.stability != null && note.card.stability! > 0) ? note.card.stability! : fallbackStability;
    final series = <({double x, double y, Note note})>[];
    for (int i = 0; i <= 30; i++) { // x axis: 0 -> 30 days
      final r = retentionAt(s, i.toDouble());
      series.add((x: i.toDouble(), y: (r * 100).clamp(0.0, 100.0), note: note));
    }
    return series;
  }
}
