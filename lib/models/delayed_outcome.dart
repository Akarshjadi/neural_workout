import 'learning_enums.dart';

/// The result of re-testing a concept after a delay (§24).
///
/// The whole point of the delayed-outcome system is that it is a *separate
/// record* from the acquisition attempt: the same target can have many
/// immediate attempts and a handful of delayed ones, and only the latter
/// justify calling something "stable".
class DelayedOutcome {
  final int id;
  final int knowledgeTargetId;
  final int attemptId;
  final DateTime measuredAt;

  /// The attempt whose learning this outcome tests. Null when the concept was
  /// acquired before the evidence layer existed (imported history).
  final int? sourceAttemptId;

  final DelayBucket bucket;
  final Duration elapsed;

  final Correctness correctness;
  final double scorePct;

  /// Set by the experiment service when this measurement is being used to
  /// evaluate an intervention (§28). Independent of the attempt's own
  /// intervention link, because the outcome may belong to a different session.
  final int? experimentId;

  const DelayedOutcome({
    required this.id,
    required this.knowledgeTargetId,
    required this.attemptId,
    required this.measuredAt,
    this.sourceAttemptId,
    required this.bucket,
    required this.elapsed,
    required this.correctness,
    required this.scorePct,
    this.experimentId,
  });

  bool get isTransfer => bucket == DelayBucket.transfer;
}
