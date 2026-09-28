import 'learning_enums.dart';

/// Corrective feedback for one attempt (§11).
///
/// Deliberately fielded rather than a prose blob: the four questions the
/// learner actually needs answered (what was right / missing / wrong / next)
/// are separate so the UI can show them tersely and the analytics can track
/// which one recurs. AI may *fill* these fields; it does not own the shape.
class FeedbackRecord {
  final int id;
  final int attemptId;
  final DateTime createdAt;

  /// How the attempt was judged. Kept as the authoritative grade for the
  /// attempt — `LearningAttempt.correctness` mirrors it.
  final Correctness correctness;

  /// 0..100. For free recall this is the evaluator's semantic score; for a
  /// self-explanation it is the reasoning rubric score.
  final double scorePct;

  /// What the learner got right. Bounded list, not prose.
  final List<String> correctPoints;

  /// Concepts/steps that should have been present and were not.
  final List<String> missing;

  /// Statements that are actively wrong (as opposed to absent) — only ever
  /// populated when the evaluator can point at something specific.
  final List<String> incorrect;

  /// One actionable next step ("retrieve the 3 layers again in ~10 min").
  /// At most one: §11 says do not expose excessive AI prose.
  final String nextAction;

  /// True when this came from AI rather than the deterministic scorer, so
  /// analytics never blur the two.
  final bool fromAi;

  const FeedbackRecord({
    required this.id,
    required this.attemptId,
    required this.createdAt,
    required this.correctness,
    required this.scorePct,
    this.correctPoints = const [],
    this.missing = const [],
    this.incorrect = const [],
    this.nextAction = '',
    this.fromAi = false,
  });

  bool get isEmpty =>
      correctPoints.isEmpty &&
      missing.isEmpty &&
      incorrect.isEmpty &&
      nextAction.isEmpty;
}
