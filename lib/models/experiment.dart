import 'intervention.dart';
import 'learning_enums.dart';

/// How much a comparison can actually support a causal claim (§29).
///
/// This is a first-class field, not a comment, because the UI must never label
/// an observational comparison as if it were controlled.
enum ComparisonQuality {
  controlled, // randomised assignment within a comparable population
  quasiControlled, // matched post-hoc on measurable covariates
  observational; // no control at all — association only

  String get label => switch (this) {
        ComparisonQuality.controlled => 'controlled (randomised)',
        ComparisonQuality.quasiControlled => 'quasi-controlled (matched)',
        ComparisonQuality.observational => 'observational (no control)',
      };

  /// Whether the system is allowed to phrase this as an effect of the
  /// intervention rather than a correlation with it.
  bool get supportsCausalClaim => this == ComparisonQuality.controlled;

  static ComparisonQuality? tryParse(String? name) {
    if (name == null) return null;
    for (final v in ComparisonQuality.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// One arm of an experiment (§28).
class ExperimentCondition {
  /// Stable key, used in the assignment hash. Never a display label.
  final String key;
  final String label;
  final InterventionAction action;

  const ExperimentCondition({
    required this.key,
    required this.label,
    required this.action,
  });
}

/// A personal experiment: does intervention B beat A *for this learner*, on a
/// delayed measure (§28).
class Experiment {
  final int id;
  final String hypothesis;
  final List<ExperimentCondition> conditions;

  /// Which delay buckets count as the outcome. Defaults to medium+long.
  final Set<DelayBucket> outcomeBuckets;

  final int? targetConceptTypeFilter; // ConceptType.index, null = any

  /// Minimum attempts per condition before any difference is reported at all.
  final int minAttemptsPerCondition;

  final DateTime startedAt;
  final DateTime? endedAt;
  final bool active;

  const Experiment({
    required this.id,
    required this.hypothesis,
    required this.conditions,
    this.outcomeBuckets = const {
      DelayBucket.mediumDelay,
      DelayBucket.longDelay,
      DelayBucket.transfer,
    },
    this.targetConceptTypeFilter,
    this.minAttemptsPerCondition = 4,
    required this.startedAt,
    this.endedAt,
    this.active = true,
  });

  ExperimentCondition? conditionByKey(String key) {
    for (final c in conditions) {
      if (c.key == key) return c;
    }
    return null;
  }

  ConceptType? get conceptTypeFilter {
    final i = targetConceptTypeFilter;
    if (i == null || i < 0 || i >= ConceptType.values.length) return null;
    return ConceptType.values[i];
  }

  /// A single-condition experiment cannot compare anything — guard so callers
  /// cannot accidentally create a "study" and read an effect out of it.
  bool get isComparable => conditions.length >= 2;

  /// Returns key timeline events for an experiment.
  static List<({DateTime at, String label})> timelineEvents(Experiment e) => [
        (at: e.startedAt, label: 'started'),
        if (e.endedAt != null) (at: e.endedAt!, label: 'ended'),
      ];

  /// Baseline accuracy for a specific condition within a comparison.
  static double? baselineAccuracy(
    ExperimentComparison c,
    String conditionKey,
  ) =>
      c.resultFor(conditionKey)?.delayedAccuracy;

  /// Single sentence summarizing the outcome of a comparison.
  static String outcomeSummary(ExperimentComparison c) {
    if (c.underpowered) {
      return 'Experiment is currently underpowered with insufficient delayed measurements (${c.quality.label}).';
    }
    final delta = c.delayedDelta;
    final deltaStr = delta != null
        ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}%'
        : 'no delta';
    return 'Comparison quality is ${c.quality.label} with delayed retention delta of $deltaStr.';
  }

  /// Difference in delayed retention delta from comparison.
  static double? delayedRetentionDelta(ExperimentComparison c) =>
      c.delayedDelta;
}

/// Measured result for one condition of one experiment.
class ConditionResult {
  final String conditionKey;
  final int delayedAttempts;
  final int successes;

  /// Mean score across the *delayed* attempts only.
  final double meanDelayedScore;

  /// Mean score across all immediate attempts in this condition — reported
  /// separately because an intervention that lifts immediate performance while
  /// leaving delayed performance flat has not achieved the goal (§30).
  final double meanImmediateScore;
  final int immediateAttempts;

  const ConditionResult({
    required this.conditionKey,
    required this.delayedAttempts,
    required this.successes,
    required this.meanDelayedScore,
    required this.meanImmediateScore,
    required this.immediateAttempts,
  });

  double get delayedAccuracy =>
      delayedAttempts == 0 ? 0 : successes / delayedAttempts;
}

/// Full comparison across conditions, with an explicit quality label.
class ExperimentComparison {
  final Experiment experiment;
  final List<ConditionResult> results;
  final ComparisonQuality quality;

  /// Why the quality label is what it is (shown to the user verbatim).
  final String qualityReason;

  /// Difference in delayed mean score between the first two conditions
  /// (condition[1] - condition[0]). Null when underpowered.
  final double? delayedDelta;

  /// Sample size guard: below `minAttemptsPerCondition` per arm, no delta is
  /// reported at all.
  final bool underpowered;

  const ExperimentComparison({
    required this.experiment,
    required this.results,
    required this.quality,
    required this.qualityReason,
    this.delayedDelta,
    this.underpowered = true,
  });

  ConditionResult? resultFor(String key) {
    for (final r in results) {
      if (r.conditionKey == key) return r;
    }
    return null;
  }
}
