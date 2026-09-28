import 'error_record.dart';

/// Explainable state of a knowledge target (§33).
///
/// There is deliberately no `knowledgeScore = 82`. A single number collapses
/// six different kinds of evidence into one figure that cannot be argued with;
/// this enum is derived *from* those six counts and always ships with the
/// counts that produced it, so the label is falsifiable.
enum KnowledgeState {
  unknown, // no evidence at all
  developing, // some evidence, not yet reliable
  probable, // consistent success, but only immediate / single-mode
  verified, // repeated success across more than one mode
  stable, // delayed success sustained over time
  unstable, // was strong, recent evidence regressed
  bottleneck; // weak *and* blocking other targets in the graph

  String get label => switch (this) {
        KnowledgeState.unknown => 'Unknown',
        KnowledgeState.developing => 'Developing',
        KnowledgeState.probable => 'Probable',
        KnowledgeState.verified => 'Verified',
        KnowledgeState.stable => 'Stable',
        KnowledgeState.unstable => 'Unstable',
        KnowledgeState.bottleneck => 'Bottleneck',
      };
}

/// The evidence counts behind a [KnowledgeState]. Every field is a count or a
/// measured value from the evidence tables — nothing here is inferred or
/// weighted. "Explainable state" means exactly this: you can print the object.
class EvidenceSummary {
  final int retrievalAttempts;
  final int retrievalSuccesses;
  final int delayedAttempts;
  final int delayedSuccesses;
  final int applicationAttempts;
  final int applicationSuccesses;
  final int transferAttempts;
  final int transferSuccesses;
  final int explanationAttempts;

  /// Records where correctness was `unknown` — evaluated as "no evidence"
  /// rather than folded in as failures.
  final int unknownOutcomes;

  /// Mean calibration error across attempts that had both a confidence
  /// judgment and a score. Null when never measured.
  final double? meanCalibrationError;

  /// Most recent conceptual-family error, if any (used for the unstable /
  /// bottleneck distinctions).
  final ErrorType? lastConceptualError;

  /// How many other targets link to this one in the knowledge graph.
  final int dependents;

  const EvidenceSummary({
    this.retrievalAttempts = 0,
    this.retrievalSuccesses = 0,
    this.delayedAttempts = 0,
    this.delayedSuccesses = 0,
    this.applicationAttempts = 0,
    this.applicationSuccesses = 0,
    this.transferAttempts = 0,
    this.transferSuccesses = 0,
    this.explanationAttempts = 0,
    this.unknownOutcomes = 0,
    this.meanCalibrationError,
    this.lastConceptualError,
    this.dependents = 0,
  });

  int get totalAttempts =>
      retrievalAttempts + applicationAttempts + transferAttempts + explanationAttempts;

  int get totalSuccesses =>
      retrievalSuccesses + applicationSuccesses + transferSuccesses;

  double? get retrievalAccuracy =>
      retrievalAttempts == 0 ? null : retrievalSuccesses / retrievalAttempts;

  double? get applicationAccuracy =>
      applicationAttempts == 0 ? null : applicationSuccesses / applicationAttempts;

  double? get transferAccuracy =>
      transferAttempts == 0 ? null : transferSuccesses / transferAttempts;

  double? get delayedAccuracy =>
      delayedAttempts == 0 ? null : delayedSuccesses / delayedAttempts;

  /// How many distinct modes have at least one success. `>= 2` is what
  /// separates probable from verified.
  int get successfulModes {
    var n = 0;
    if (retrievalSuccesses > 0) n++;
    if (applicationSuccesses > 0) n++;
    if (transferSuccesses > 0) n++;
    if (explanationAttempts > 0 && retrievalSuccesses > 0) n++;
    return n;
  }

  bool get isOverconfident =>
      meanCalibrationError != null && meanCalibrationError! > 20;

  bool get isUnderconfident =>
      meanCalibrationError != null && meanCalibrationError! < -20;
}

/// A state plus the evidence that produced it — the only shape the UI should
/// ever consume when it needs to say "how well do I know this?".
class KnowledgeEvidence {
  final int knowledgeTargetId;
  final KnowledgeState state;
  final EvidenceSummary evidence;

  /// One-sentence justification assembled from the counts, e.g.
  /// "8 retrieval attempts, 6 delayed successes, 3 application successes".
  final String rationale;

  /// 0..1 how much to trust [state]. Grows with evidence *breadth*, never
  /// invented: no evidence -> 0.
  final double confidence;

  const KnowledgeEvidence({
    required this.knowledgeTargetId,
    required this.state,
    required this.evidence,
    required this.rationale,
    required this.confidence,
  });

  bool get isActionable =>
      state == KnowledgeState.unstable ||
      state == KnowledgeState.bottleneck ||
      state == KnowledgeState.developing;
}
