/// Discriminator for *how* knowledge was exercised.
///
/// The audit (§4) found the old model conflated every attempt into one shape
/// (`BlurtScore` = always FREE_RECALL). Recall, application, explanation and
/// transfer are separate skills that decay at different rates and must stay
/// separable in analytics — so the operation is now a first-class field, not
/// an assumption.
///
/// Ranking of "strength of evidence" is intentionally NOT encoded here; that
/// lives in LearningEvidenceService where it can be argued about in one place.
enum TestType {
  freeRecall, // blurt: source hidden, unconstrained retrieval
  cuedRecall, // prompt/cue given, answer retrieved
  application, // use the concept in a novel situation
  explanation, // self-explanation: why is this true / why does this step follow
  reconstruction, // rebuild a structure from partial cues (worked-example fading)
  discrimination, // distinguish A from B (contrastive, needs a graph relation)
  pretest, // attempt before instruction, to surface prior knowledge
  workedExample, // study a fully worked solution (not scored as retrieval)
  transfer, // structurally different problem, same underlying principle
}

/// Human label for UI; kept generic (no subject assumptions).
extension TestTypeLabel on TestType {
  String get label => switch (this) {
        TestType.freeRecall => 'Free recall',
        TestType.cuedRecall => 'Cued recall',
        TestType.application => 'Application',
        TestType.explanation => 'Explanation',
        TestType.reconstruction => 'Reconstruction',
        TestType.discrimination => 'Discrimination',
        TestType.pretest => 'Pre-test',
        TestType.workedExample => 'Worked example',
        TestType.transfer => 'Transfer',
      };

  /// True when the learner must *produce* an answer from memory/understanding
  /// rather than study one. Only productive attempts yield retrieval evidence
  /// (worked examples are instruction, not evidence).
  bool get isProductive => this != TestType.workedExample;
}

/// How long after acquisition an outcome was measured.
///
/// §24: a concept is stronger on *repeated delayed* evidence, not one immediate
/// success. The bucket is derived deterministically from elapsed time, never
/// self-reported.
enum DelayBucket {
  immediate, // < 1 hour
  shortDelay, // < 1 day
  mediumDelay, // < 7 days
  longDelay, // >= 7 days
  transfer; // measured via a transfer-type attempt (orthogonal, wins outright)

  static DelayBucket fromElapsed(Duration elapsed) {
    if (elapsed.inMinutes < 60) return DelayBucket.immediate;
    if (elapsed.inHours < 24) return DelayBucket.shortDelay;
    if (elapsed.inDays < 7) return DelayBucket.mediumDelay;
    return DelayBucket.longDelay;
  }

  String get label => switch (this) {
        DelayBucket.immediate => 'immediate',
        DelayBucket.shortDelay => 'short delay (same day)',
        DelayBucket.mediumDelay => 'medium delay (1-6 days)',
        DelayBucket.longDelay => 'long delay (7+ days)',
        DelayBucket.transfer => 'transfer',
      };

  /// Delayed buckets are the ones that actually predict durable learning.
  bool get isDelayed => this == DelayBucket.mediumDelay ||
      this == DelayBucket.longDelay ||
      this == DelayBucket.transfer;
}

/// Structured outcome of one attempt.
///
/// `unknown` exists because "no evidence" must never be silently converted
/// into "zero" (§32) — a free recall with an unavailable evaluator is unknown,
/// not a failure.
enum Correctness {
  correct,
  partiallyCorrect,
  incorrect,
  incomplete,
  contradictory,
  unknown;

  /// 0..1 deterministic credit for a grade. `unknown` contributes no evidence.
  /// Returns NaN for unknown so callers must handle it explicitly rather than
  /// accidentally averaging a 0 in.
  double get credit => switch (this) {
        Correctness.correct => 1.0,
        Correctness.partiallyCorrect => 0.5,
        Correctness.incomplete => 0.5,
        Correctness.incorrect => 0.0,
        Correctness.contradictory => 0.0,
        Correctness.unknown => double.nan,
      };

  bool get isFail => this == Correctness.incorrect ||
      this == Correctness.contradictory ||
      this == Correctness.incomplete;

  /// Deterministic banding of a 0..100 semantic score. Thresholds are shared
  /// with `FeedbackEngine` so a score never means two different things.
  static Correctness fromScorePct(double pct) {
    if (pct.isNaN) return Correctness.unknown;
    if (pct >= 85) return Correctness.correct;
    if (pct >= 50) return Correctness.partiallyCorrect;
    if (pct > 0) return Correctness.incomplete;
    return Correctness.incorrect;
  }

  static Correctness? tryParse(String? name) {
    if (name == null) return null;
    for (final v in Correctness.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Who produced a diagnosis. §12: user, deterministic and AI signals are
/// stored separately so they can be *compared*, not merged into one truth.
enum DiagnosisSource {
  user,
  deterministic,
  ai;

  static DiagnosisSource? tryParse(String? name) {
    if (name == null) return null;
    for (final v in DiagnosisSource.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// What kind of thing the learner was working on. §31: the *most effective*
/// intervention may differ by target type; the system should find that out per
/// learner rather than hard-coding it.
enum ConceptType {
  definition,
  procedure,
  algorithm,
  relationship,
  discrimination,
  problemSolving,
  formula,
  conceptualModel,
  unclassified;

  static ConceptType? tryParse(String? name) {
    if (name == null) return null;
    for (final v in ConceptType.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  String get label => switch (this) {
        ConceptType.definition => 'Definition',
        ConceptType.procedure => 'Procedure',
        ConceptType.algorithm => 'Algorithm',
        ConceptType.relationship => 'Relationship',
        ConceptType.discrimination => 'Discrimination',
        ConceptType.problemSolving => 'Problem solving',
        ConceptType.formula => 'Formula',
        ConceptType.conceptualModel => 'Conceptual model',
        ConceptType.unclassified => 'Unclassified',
      };
}

/// Typedef alias for TestType.
typedef LearningAttemptType = TestType;
