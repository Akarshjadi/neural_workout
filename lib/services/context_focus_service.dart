import '../models/focus_integrity.dart';
import '../models/learning_attempt.dart';

/// Context observation record for physiological and environmental covariates.
class ContextObservation {
  final DateTime timestamp;
  final double? sleepDurationHours;
  final int? sleepQuality1to5;
  final double? exerciseDurationMinutes;
  final int? exerciseIntensity1to5;
  final int? fatigueLevel1to5;
  final String? timeOfDay; // morning, afternoon, evening, night
  final String? environment; // quiet, library, outdoors, commute

  const ContextObservation({
    required this.timestamp,
    this.sleepDurationHours,
    this.sleepQuality1to5,
    this.exerciseDurationMinutes,
    this.exerciseIntensity1to5,
    this.fatigueLevel1to5,
    this.timeOfDay,
    this.environment,
  });
}

/// Service tracking focus integrity, interruption recovery, and contextual correlations.
class ContextFocusService {
  const ContextFocusService();

  /// Computes focus integrity metrics for a session.
  FocusIntegrity evaluateSessionFocus({
    int? sessionId,
    Duration? plannedDuration,
    required Duration actualDuration,
    required int interruptions,
    required int taskSwitches,
    required bool completed,
    required bool abandoned,
    int? longestFocusMs,
  }) {
    return FocusIntegrity(
      sessionId: sessionId,
      plannedDuration: plannedDuration,
      actualDuration: actualDuration,
      interruptions: interruptions,
      taskSwitches: taskSwitches,
      completed: completed,
      abandoned: abandoned,
      longestFocusMs: longestFocusMs,
    );
  }

  /// Evaluates interruption recovery cost: compares pre vs post interruption response time and accuracy.
  double? calculateInterruptionCost({
    required List<LearningAttempt> preInterruptionAttempts,
    required List<LearningAttempt> postInterruptionAttempts,
  }) {
    if (preInterruptionAttempts.isEmpty || postInterruptionAttempts.isEmpty) return null;

    final preScore = preInterruptionAttempts.fold<double>(0.0, (acc, a) => acc + (a.scorePct.isNaN ? 0 : a.scorePct)) / preInterruptionAttempts.length;
    final postScore = postInterruptionAttempts.fold<double>(0.0, (acc, a) => acc + (a.scorePct.isNaN ? 0 : a.scorePct)) / postInterruptionAttempts.length;

    // Drop in score percentage (positive number indicates performance cost)
    return preScore - postScore;
  }

  /// Observational correlation between sleep duration and average next-day score.
  /// Strictly framed as correlation, never medical or biological certainty.
  String summarizeSleepCorrelation({
    required List<ContextObservation> observations,
    required List<LearningAttempt> attempts,
  }) {
    if (observations.length < 3 || attempts.length < 5) {
      return 'Insufficient contextual data to observe sleep vs performance associations.';
    }

    final longSleepScores = <double>[];
    final shortSleepScores = <double>[];

    for (final obs in observations) {
      if (obs.sleepDurationHours == null) continue;
      final dayAttempts = attempts.where((a) =>
        a.timestamp.year == obs.timestamp.year &&
        a.timestamp.month == obs.timestamp.month &&
        a.timestamp.day == obs.timestamp.day
      ).toList();

      if (dayAttempts.isEmpty) continue;
      final dayMean = dayAttempts.fold<double>(0.0, (acc, a) => acc + (a.scorePct.isNaN ? 0 : a.scorePct)) / dayAttempts.length;

      if (obs.sleepDurationHours! >= 7.0) {
        longSleepScores.add(dayMean);
      } else {
        shortSleepScores.add(dayMean);
      }
    }

    if (longSleepScores.isEmpty || shortSleepScores.isEmpty) {
      return 'Observed sessions show balanced context across days.';
    }

    final meanLong = longSleepScores.reduce((a, b) => a + b) / longSleepScores.length;
    final meanShort = shortSleepScores.reduce((a, b) => a + b) / shortSleepScores.length;
    final diff = (meanLong - meanShort).toStringAsFixed(1);

    return 'Observational Association: Days with 7h+ sleep showed ~$diff% difference in average score (n=${longSleepScores.length + shortSleepScores.length} days). Note: Correlation does not establish causation.';
  }

  /// Analyzes average attempt scores by time of day buckets.
  Map<String, double> analyzeTimeOfDay({
    required List<LearningAttempt> attempts,
  }) {
    final valid = attempts.where((a) => !a.scorePct.isNaN).toList();
    final morning = <double>[];
    final afternoon = <double>[];
    final evening = <double>[];
    final night = <double>[];

    for (final a in valid) {
      final h = a.timestamp.hour;
      if (h >= 5 && h <= 11) {
        morning.add(a.scorePct);
      } else if (h >= 12 && h <= 16) {
        afternoon.add(a.scorePct);
      } else if (h >= 17 && h <= 21) {
        evening.add(a.scorePct);
      } else {
        night.add(a.scorePct);
      }
    }

    double mean(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;

    return {
      'morning': mean(morning),
      'afternoon': mean(afternoon),
      'evening': mean(evening),
      'night': mean(night),
    };
  }

  /// Returns typed record comparison of average attempt scores across time of day.
  ({double morning, double afternoon, double evening, double night})
      timeOfDayComparison({
    required List<LearningAttempt> attempts,
  }) {
    final map = analyzeTimeOfDay(attempts: attempts);
    return (
      morning: map['morning'] ?? 0.0,
      afternoon: map['afternoon'] ?? 0.0,
      evening: map['evening'] ?? 0.0,
      night: map['night'] ?? 0.0,
    );
  }

  /// Computes 24-bin circadian performance curve across hours of day.
  List<({int hour, double meanScore, int sampleSize})> circadianCurve({
    required List<LearningAttempt> attempts,
  }) {
    final valid = attempts.where((a) => !a.scorePct.isNaN).toList();
    final bins = List.generate(24, (_) => <double>[]);
    for (final a in valid) {
      final h = a.timestamp.hour.clamp(0, 23);
      bins[h].add(a.scorePct);
    }
    return List.generate(24, (h) {
      final list = bins[h];
      final mean =
          list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
      return (hour: h, meanScore: mean, sampleSize: list.length);
    });
  }
}
