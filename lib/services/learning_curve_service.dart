import '../models/delayed_outcome.dart';
import '../models/intervention.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';

/// Single point in an individual learning trajectory.
class LearningCurvePoint {
  final int attemptIndex;
  final DateTime timestamp;
  final double scorePct;
  final int? responseTimeMs;
  final int? confidence;

  const LearningCurvePoint({
    required this.attemptIndex,
    required this.timestamp,
    required this.scorePct,
    this.responseTimeMs,
    this.confidence,
  });
}

/// Intervention effectiveness matrix entry.
class InterventionEffectivenessRow {
  final InterventionAction action;
  final ConceptType conceptType;
  final int totalAttempts;
  final double meanImmediateScore;
  final double meanDelayedScore;
  final double meanTransferScore;
  final int sampleSize;

  const InterventionEffectivenessRow({
    required this.action,
    required this.conceptType,
    required this.totalAttempts,
    required this.meanImmediateScore,
    required this.meanDelayedScore,
    required this.meanTransferScore,
    required this.sampleSize,
  });
}

/// Service computing empirical individual learning curves and intervention effectiveness matrix.
@Deprecated('Kept frozen for research reference; visual decay curves are rendered via RetentionDecay and HorizonCurve')
class LearningCurveService {
  const LearningCurveService();

  /// Builds a sequential learning curve for a specific knowledge target.
  List<LearningCurvePoint> buildTargetLearningCurve({
    required int targetId,
    required List<LearningAttempt> attempts,
  }) {
    final targetAttempts = attempts
        .where((a) => a.knowledgeTargetId == targetId && !a.scorePct.isNaN)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return List.generate(targetAttempts.length, (i) {
      final a = targetAttempts[i];
      return LearningCurvePoint(
        attemptIndex: i + 1,
        timestamp: a.timestamp,
        scorePct: a.scorePct,
        responseTimeMs: a.responseTimeMs,
        confidence: a.confidence,
      );
    });
  }

  /// Builds the personalized Intervention x ConceptType effectiveness matrix.
  List<InterventionEffectivenessRow> computeEffectivenessMatrix({
    required List<LearningAttempt> attempts,
    required List<DelayedOutcome> delayedOutcomes,
    required List<Intervention> interventions,
  }) {
    final rows = <InterventionEffectivenessRow>[];

    for (final action in InterventionAction.values) {
      for (final conceptType in ConceptType.values) {
        final matchingInterventions = interventions.where((inv) => inv.action == action).map((i) => i.id).toSet();
        if (matchingInterventions.isEmpty) continue;

        final matchingAttempts = attempts.where((a) =>
          a.interventionId != null && matchingInterventions.contains(a.interventionId) && !a.scorePct.isNaN
        ).toList();

        if (matchingAttempts.isEmpty) continue;

        final immMean = matchingAttempts.fold<double>(0.0, (acc, a) => acc + a.scorePct) / matchingAttempts.length;

        // Delayed outcomes for these attempts
        final matchingAttemptIds = matchingAttempts.map((a) => a.id).toSet();
        final delayedMatches = delayedOutcomes.where((o) =>
          matchingAttemptIds.contains(o.attemptId) && o.bucket != DelayBucket.transfer && !o.scorePct.isNaN
        ).toList();

        final transferMatches = delayedOutcomes.where((o) =>
          matchingAttemptIds.contains(o.attemptId) && o.bucket == DelayBucket.transfer && !o.scorePct.isNaN
        ).toList();

        final delMean = delayedMatches.isNotEmpty
            ? delayedMatches.fold<double>(0.0, (acc, o) => acc + o.scorePct) / delayedMatches.length
            : 0.0;

        final transferMean = transferMatches.isNotEmpty
            ? transferMatches.fold<double>(0.0, (acc, o) => acc + o.scorePct) / transferMatches.length
            : 0.0;

        rows.add(InterventionEffectivenessRow(
          action: action,
          conceptType: conceptType,
          totalAttempts: matchingAttempts.length,
          meanImmediateScore: immMean,
          meanDelayedScore: delMean,
          meanTransferScore: transferMean,
          sampleSize: matchingAttempts.length,
        ));
      }
    }

    return rows;
  }
}
