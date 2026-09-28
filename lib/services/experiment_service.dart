import 'dart:math' as math;
import '../models/delayed_outcome.dart';
import '../models/experiment.dart';
import '../models/intervention.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import 'metrics_service.dart';

/// Service managing personal experiments and A/B comparison analysis.
class ExperimentService {
  const ExperimentService();

  /// Assigns an experiment condition deterministically/alternatingly.
  ExperimentCondition assignCondition({
    required Experiment experiment,
    required int attemptCount,
  }) {
    if (experiment.conditions.isEmpty) {
      throw StateError('Experiment has no conditions defined.');
    }
    final index = attemptCount % experiment.conditions.length;
    return experiment.conditions[index];
  }

  /// Evaluates an active or completed experiment across its conditions.
  ExperimentComparison evaluateExperiment({
    required Experiment experiment,
    required List<LearningAttempt> attempts,
    required List<DelayedOutcome> delayedOutcomes,
  }) {
    final conditionResults = <ConditionResult>[];

    for (final condition in experiment.conditions) {
      // Immediate attempts matching condition
      final conditionAttempts = attempts.where((a) =>
        a.extras['experiment_condition'] == condition.key && !a.scorePct.isNaN
      ).toList();

      // Delayed outcomes linked to this experiment and condition
      final conditionDelayed = delayedOutcomes.where((o) =>
        o.experimentId == experiment.id &&
        attempts.any((a) => a.id == o.attemptId && a.extras['experiment_condition'] == condition.key) &&
        !o.scorePct.isNaN
      ).toList();

      final immMean = conditionAttempts.isNotEmpty
          ? conditionAttempts.fold<double>(0.0, (acc, a) => acc + a.scorePct) / conditionAttempts.length
          : 0.0;

      final delMean = conditionDelayed.isNotEmpty
          ? conditionDelayed.fold<double>(0.0, (acc, o) => acc + o.scorePct) / conditionDelayed.length
          : 0.0;

      final successes = conditionDelayed.where((o) => !o.correctness.isFail).length;

      conditionResults.add(ConditionResult(
        conditionKey: condition.key,
        delayedAttempts: conditionDelayed.length,
        successes: successes,
        meanDelayedScore: delMean,
        meanImmediateScore: immMean,
        immediateAttempts: conditionAttempts.length,
      ));
    }

    // Power guard check
    final bool underpowered = conditionResults.any(
      (r) => r.delayedAttempts < experiment.minAttemptsPerCondition,
    );

    double? delayedDelta;
    if (!underpowered && conditionResults.length >= 2) {
      delayedDelta = conditionResults[1].meanDelayedScore - conditionResults[0].meanDelayedScore;
    }

    final quality = conditionResults.every((r) => r.delayedAttempts >= experiment.minAttemptsPerCondition * 2)
        ? ComparisonQuality.controlled
        : (underpowered ? ComparisonQuality.observational : ComparisonQuality.quasiControlled);

    final qualityReason = underpowered
        ? 'Underpowered personal sample: fewer than ${experiment.minAttemptsPerCondition} delayed measurements per arm.'
        : 'Sufficient personal sample (${conditionResults.map((r) => "${r.conditionKey}: ${r.delayedAttempts}").join(", ")}).';

    return ExperimentComparison(
      experiment: experiment,
      results: conditionResults,
      quality: quality,
      qualityReason: qualityReason,
      delayedDelta: delayedDelta,
      underpowered: underpowered,
    );
  }

  /// Alias: runs an A/B comparison and returns delta and significance.
  ({double? delta, bool significant}) runABComparison({
    required Experiment experiment,
    required List<LearningAttempt> attempts,
    required List<DelayedOutcome> delayedOutcomes,
  }) {
    final comparison = evaluateExperiment(
      experiment: experiment,
      attempts: attempts,
      delayedOutcomes: delayedOutcomes,
    );
    return (
      delta: comparison.delayedDelta,
      significant: !comparison.underpowered &&
          (comparison.delayedDelta?.abs() ?? 0) > 5,
    );
  }

  /// Alias: assigns intervention condition.
  ExperimentCondition assignIntervention({
    required Experiment experiment,
    required int attemptCount,
  }) =>
      assignCondition(experiment: experiment, attemptCount: attemptCount);

  /// Computes pooled-standard-deviation Cohen's d between two sample groups.
  double? computeCohenD({
    required List<double> groupA,
    required List<double> groupB,
  }) {
    if (groupA.length < 2 || groupB.length < 2) return null;
    final n1 = groupA.length;
    final n2 = groupB.length;
    final mean1 = groupA.reduce((a, b) => a + b) / n1;
    final mean2 = groupB.reduce((a, b) => a + b) / n2;
    final var1 = groupA.fold<double>(
            0.0, (acc, x) => acc + (x - mean1) * (x - mean1)) /
        (n1 - 1);
    final var2 = groupB.fold<double>(
            0.0, (acc, x) => acc + (x - mean2) * (x - mean2)) /
        (n2 - 1);
    final pooledVariance =
        ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2);
    final pooledSD = math.sqrt(pooledVariance);
    if (pooledSD == 0) return 0.0;
    return (mean1 - mean2) / pooledSD;
  }

  /// Computes effect size (Cohen's d) between the first two conditions of a comparison.
  double? computeEffectSize({
    required ExperimentComparison comparison,
  }) {
    if (comparison.underpowered || comparison.results.length < 2) return null;
    final r0 = comparison.results[0];
    final r1 = comparison.results[1];
    if (r0.delayedAttempts < 2 || r1.delayedAttempts < 2) return null;
    final group0 = List.generate(
        r0.delayedAttempts, (i) => i < r0.successes ? 100.0 : 0.0);
    final group1 = List.generate(
        r1.delayedAttempts, (i) => i < r1.successes ? 100.0 : 0.0);
    return computeCohenD(groupA: group1, groupB: group0);
  }

  /// Computes mean delayed score broken down by ConceptType index for intervention-linked attempts.
  Map<int, ({double mean, int n})> effectivenessByConceptType({
    required List<LearningAttempt> attempts,
    required List<DelayedOutcome> delayedOutcomes,
    required List<Intervention> interventions,
    required Map<int, ConceptType> conceptTypeByNote,
  }) {
    final typeScores = <int, List<double>>{};
    for (final a in attempts) {
      if (a.interventionId != null &&
          a.knowledgeTargetId != null &&
          !a.scorePct.isNaN &&
          a.isDelayed) {
        final cType = conceptTypeByNote[a.knowledgeTargetId!];
        if (cType != null) {
          typeScores.putIfAbsent(cType.index, () => []).add(a.scorePct);
        }
      }
    }
    final result = <int, ({double mean, int n})>{};
    for (final entry in typeScores.entries) {
      if (entry.value.isNotEmpty) {
        result[entry.key] = (
          mean: entry.value.reduce((a, b) => a + b) / entry.value.length,
          n: entry.value.length,
        );
      }
    }
    return result;
  }

  /// Alias: delegates intervention responsiveness calculation to MetricsService.
  double computeInterventionResponsiveness({
    required List<LearningAttempt> attempts,
    required List<Intervention> interventions,
  }) =>
      MetricsService().computeInterventionResponsiveness(attempts, interventions);
}
