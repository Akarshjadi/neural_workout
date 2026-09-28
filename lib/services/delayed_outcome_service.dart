import '../models/delayed_outcome.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';

/// Retention metrics across time delay buckets.
class RetentionCurveData {
  final double immediateAccuracy;
  final double shortDelayAccuracy;
  final double mediumDelayAccuracy;
  final double longDelayAccuracy;
  final double transferAccuracy;
  final int totalMeasuredAttempts;

  const RetentionCurveData({
    required this.immediateAccuracy,
    required this.shortDelayAccuracy,
    required this.mediumDelayAccuracy,
    required this.longDelayAccuracy,
    required this.transferAccuracy,
    required this.totalMeasuredAttempts,
  });
}

/// Service managing delayed outcome re-testing and retention curve tracking.
class DelayedOutcomeService {
  const DelayedOutcomeService();

  /// Standard scheduled intervals for delayed tests (in days).
  static const List<int> standardIntervalDays = [1, 3, 7, 30];

  /// Determines if an acquired attempt is due for a delayed outcome test.
  bool isDueForDelayedTest({
    required LearningAttempt sourceAttempt,
    required List<DelayedOutcome> existingOutcomes,
    required DateTime now,
  }) {
    if (!sourceAttempt.correctness.isFail && sourceAttempt.hasEvidence) {
      final elapsed = now.difference(sourceAttempt.timestamp);
      final currentBucket = DelayBucket.fromElapsed(elapsed);

      // If at least shortDelay reached and no outcome yet for this bucket
      if (currentBucket.isDelayed) {
        final alreadyTestedInBucket = existingOutcomes.any(
          (o) =>
              (o.sourceAttemptId == sourceAttempt.id ||
                  o.attemptId == sourceAttempt.id) &&
              o.bucket == currentBucket,
        );
        return !alreadyTestedInBucket;
      }
    }
    return false;
  }

  /// Records a newly completed delayed outcome test.
  DelayedOutcome recordDelayedOutcome({
    required int id,
    required int targetId,
    required int attemptId,
    required DateTime measuredAt,
    required DateTime acquiredAt,
    required Correctness correctness,
    required double scorePct,
    int? sourceAttemptId,
    int? experimentId,
  }) {
    final elapsed = measuredAt.difference(acquiredAt);
    final bucket = DelayBucket.fromElapsed(elapsed);

    return DelayedOutcome(
      id: id,
      knowledgeTargetId: targetId,
      attemptId: attemptId,
      measuredAt: measuredAt,
      sourceAttemptId: sourceAttemptId,
      bucket: bucket,
      elapsed: elapsed,
      correctness: correctness,
      scorePct: scorePct,
      experimentId: experimentId,
    );
  }

  /// Aggregates delayed outcomes to construct empirical retention curve data.
  RetentionCurveData computeRetentionCurve(List<DelayedOutcome> outcomes) {
    if (outcomes.isEmpty) {
      return const RetentionCurveData(
        immediateAccuracy: 0,
        shortDelayAccuracy: 0,
        mediumDelayAccuracy: 0,
        longDelayAccuracy: 0,
        transferAccuracy: 0,
        totalMeasuredAttempts: 0,
      );
    }

    double calcMean(DelayBucket bucket) {
      final matches = outcomes.where((o) => o.bucket == bucket && !o.scorePct.isNaN).toList();
      if (matches.isEmpty) return 0.0;
      final sum = matches.fold<double>(0.0, (acc, o) => acc + o.scorePct);
      return sum / matches.length;
    }

    return RetentionCurveData(
      immediateAccuracy: calcMean(DelayBucket.immediate),
      shortDelayAccuracy: calcMean(DelayBucket.shortDelay),
      mediumDelayAccuracy: calcMean(DelayBucket.mediumDelay),
      longDelayAccuracy: calcMean(DelayBucket.longDelay),
      transferAccuracy: calcMean(DelayBucket.transfer),
      totalMeasuredAttempts: outcomes.length,
    );
  }
}
