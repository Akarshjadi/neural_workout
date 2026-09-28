import 'learning_enums.dart';

/// What the learner should do next (§22).
///
/// This is a *decision*, not a UI mode: the engine emits one of these plus the
/// reason it chose it, and the UI maps it onto an existing screen. Keeping the
/// vocabulary small is what makes the policy inspectable.
enum InterventionAction {
  retrieve, // plain retrieval practice
  retry, // repeat the same operation
  explain, // self-explanation
  contrast, // discrimination vs a confusable concept
  application, // use it in a novel situation
  workedExample, // study a full solution (repeated failure)
  interleave, // mix confusable targets
  delay, // stop; let forgetting do its work
  reflect, // metacognitive reflection / self-diagnosis
  focusReset, // attention-family errors: slow down / re-read
}

extension InterventionActionLabel on InterventionAction {
  String get label => switch (this) {
        InterventionAction.retrieve => 'Retrieve',
        InterventionAction.retry => 'Try again',
        InterventionAction.explain => 'Explain',
        InterventionAction.contrast => 'Contrast',
        InterventionAction.application => 'Apply',
        InterventionAction.workedExample => 'Worked example',
        InterventionAction.interleave => 'Interleave',
        InterventionAction.delay => 'Delay',
        InterventionAction.reflect => 'Reflect',
        InterventionAction.focusReset => 'Slow down',
      };

  /// Test type this action produces, when it produces an attempt. `delay` and
  /// `reflect` produce no attempt; `interleave` reuses the base type.
  TestType? get testType => switch (this) {
        InterventionAction.retrieve => TestType.freeRecall,
        InterventionAction.retry => TestType.freeRecall,
        InterventionAction.explain => TestType.explanation,
        InterventionAction.contrast => TestType.discrimination,
        InterventionAction.application => TestType.application,
        InterventionAction.workedExample => TestType.workedExample,
        InterventionAction.interleave => null, // caller supplies
        InterventionAction.delay => null,
        InterventionAction.reflect => null,
        InterventionAction.focusReset => null,
      };
}

/// Why the action was chosen. Machine-readable so the same reason can be
/// counted later ("how often did the engine invoke a worked example?").
enum InterventionReason {
  baseline, // no signal — default practice
  recentFailure, // 1 failure
  repeatedFailure, // 2 failures
  persistentFailure, // 3+ failures
  lowConfidence, // retrieval failed while the learner felt confident
  overconfidence, // calibrated: confident but wrong
  underconfidence, // correct but low confidence
  conceptualError, // error family = conceptual
  proceduralError, // error family = procedural
  retrievalError, // error family = retrieval
  attentionError, // error family = attention
  confusableTargets, // graph relation marked confusable
  transferWeak, // delayed/transfer evidence lagging recall
  dueForDelayedTest, // FSRS says revisitable, evidence says untested
  experimentAssignment, // an active experiment assigned this
}

extension InterventionReasonLabel on InterventionReason {
  String get label => switch (this) {
        InterventionReason.baseline => 'no recent difficulty',
        InterventionReason.recentFailure => '1 recent failure',
        InterventionReason.repeatedFailure => '2 recent failures',
        InterventionReason.persistentFailure => '3+ recent failures',
        InterventionReason.lowConfidence => 'failed while confident',
        InterventionReason.overconfidence => 'overconfident',
        InterventionReason.underconfidence => 'underconfident',
        InterventionReason.conceptualError => 'conceptual errors',
        InterventionReason.proceduralError => 'procedural errors',
        InterventionReason.retrievalError => 'retrieval errors',
        InterventionReason.attentionError => 'attention errors',
        InterventionReason.confusableTargets => 'confusable targets',
        InterventionReason.transferWeak => 'transfer lagging recall',
        InterventionReason.dueForDelayedTest => 'delayed test due',
        InterventionReason.experimentAssignment => 'experiment assignment',
      };
}

/// A chosen intervention, with the evidence that produced it (§22).
///
/// [explanation] is the inspectable string the UI shows. If the engine cannot
/// explain a decision, it should not be making it.
class Intervention {
  final int id;
  final DateTime createdAt;
  final InterventionAction action;
  final InterventionReason reason;
  final String explanation;
  final int? knowledgeTargetId;
  final int? contrastTargetId;
  final int? attemptId;
  final int? experimentId;

  /// Thresholds that were in force when this was chosen. Recorded so a policy
  /// change does not silently rewrite history.
  final Map<String, int> thresholds;

  /// Overrides [action.testType] when the recent error family suggests a
  /// different shape than the action's default. Example: `retrieve` normally
  /// produces free recall, but a `retrievalFailure` error suggests cued recall.
  final TestType? testTypeOverride;

  const Intervention({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.reason,
    this.explanation = '',
    this.knowledgeTargetId,
    this.contrastTargetId,
    this.attemptId,
    this.experimentId,
    this.thresholds = const {},
    this.testTypeOverride,
  });

  /// The test type this intervention should produce, preferring the override.
  TestType? get effectiveTestType => testTypeOverride ?? action.testType;

  bool get isInstructional =>
      action == InterventionAction.workedExample;
}

/// Aggregated outcome of an intervention.
class InterventionOutcome {
  final int interventionId;
  final double? delayedDelta;
  final int sampleSize;

  const InterventionOutcome({
    required this.interventionId,
    this.delayedDelta,
    required this.sampleSize,
  });
}

/// Progressive cascade stages when failures repeat.
enum InterventionCascadeStage {
  none,
  firstFailure,
  repeated,
  persistent,
  workedExample,
}

/// Helper mapping consecutive failures to an intervention cascade stage.
InterventionCascadeStage cascadeStageFor(int consecutiveFailures) {
  if (consecutiveFailures <= 0) return InterventionCascadeStage.none;
  if (consecutiveFailures == 1) return InterventionCascadeStage.firstFailure;
  if (consecutiveFailures == 2) return InterventionCascadeStage.repeated;
  if (consecutiveFailures == 3) return InterventionCascadeStage.persistent;
  return InterventionCascadeStage.workedExample;
}

/// Empirical match score between an intervention action and a concept type.
class InterventionConceptMatch {
  final InterventionAction action;
  final ConceptType conceptType;
  final double meanDelayedScore;
  final int sampleSize;

  const InterventionConceptMatch({
    required this.action,
    required this.conceptType,
    required this.meanDelayedScore,
    required this.sampleSize,
  });
}

/// Typedef alias for InterventionAction.
typedef AdaptiveInterventionType = InterventionAction;
