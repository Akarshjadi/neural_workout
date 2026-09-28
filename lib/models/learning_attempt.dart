import 'learning_enums.dart';

/// One meaningful learning attempt (§8).
///
/// This is the durable evidence atom: what target, what operation, what came
/// out, how confident the learner was, how long it took. Everything downstream
/// (feedback, errors, interventions, scheduling, analytics, experiments) keys
/// off [id].
///
/// Nullable fields are limited to those that genuinely may not exist (an
/// unmeasured response time, a cold-start attempt with no note yet). Where the
/// shape differs by mode, use [respondsWithText] / [extras] rather than adding
/// more nullable columns — the alternative was a 14-field all-nullable row.
class LearningAttempt {
  final int id;
  final DateTime timestamp;

  /// The concept being exercised. `null` only for a cold-start blurt that has
  /// not yet been promoted to a note.
  final int? knowledgeTargetId;
  final int? sessionId;

  final TestType testType;
  final String response;
  final Correctness correctness;

  /// 0..100 continuous credit — the same scale as `BlurtScore.scorePct` so old
  /// and new history are directly comparable. NaN = no evidence.
  final double scorePct;

  final int? responseTimeMs;

  /// 0..100 pre-answer confidence judgment, or null when not asked (§13).
  final int? confidence;

  final double? difficulty;

  /// Free-form, bounded extras (cues given, contrast pair, pretest prediction,
  /// which worked-example step was faded...). Kept as a map so the schema does
  /// not need a migration per feature.
  final Map<String, String> extras;

  // Produced after evaluation; linked rather than embedded so each artefact
  // keeps its own record and can be independently replaced/audited.
  final int? feedbackId;
  final List<int> errorIds;
  final int? interventionId;
  final int? delayedOutcomeId;

  /// Was this part of an interleaved block, and why (audit §8: the existing
  /// `wasInterleaved` column was written but never true).
  final bool wasInterleaved;
  final String? interleaveGroupId;
  final String? interleaveReason;

  /// When this attempt measures something first acquired, this is the origin
  /// time used to derive the [DelayBucket]. Null = not a delayed measurement.
  final DateTime? acquiredAt;

  const LearningAttempt({
    required this.id,
    required this.timestamp,
    this.knowledgeTargetId,
    this.sessionId,
    required this.testType,
    this.response = '',
    required this.correctness,
    this.scorePct = double.nan,
    this.responseTimeMs,
    this.confidence,
    this.difficulty,
    this.extras = const {},
    this.feedbackId,
    this.errorIds = const [],
    this.interventionId,
    this.delayedOutcomeId,
    this.wasInterleaved = false,
    this.interleaveGroupId,
    this.interleaveReason,
    this.acquiredAt,
  });

  bool get hasEvidence => !scorePct.isNaN;

  /// Alias for [responseTimeMs].
  int? get latencyMs => responseTimeMs;

  /// Alias for [scorePct].
  double get accuracyScore => scorePct;

  /// Alias for [confidence].
  int? get confidenceRating => confidence;

  /// Alias for [scorePct].
  double get immediateRecallRate => scorePct;

  /// Deterministic delay bucket for this attempt (§24). Transfer attempts win
  /// outright — they are measured for a different reason, not a different time.
  DelayBucket get delayBucket {
    if (testType == TestType.transfer) return DelayBucket.transfer;
    final origin = acquiredAt;
    if (origin == null) return DelayBucket.immediate;
    return DelayBucket.fromElapsed(timestamp.difference(origin));
  }

  bool get isDelayed => delayBucket.isDelayed;

  /// Calibration error in confidence points: positive = overconfident.
  /// NaN when either side is missing — callers must not treat that as zero.
  double get calibrationError {
    final c = confidence;
    if (c == null || scorePct.isNaN) return double.nan;
    return c - scorePct;
  }

  bool get respondsWithText => response.isNotEmpty;

  LearningAttempt copyWith({
    int? id,
    int? feedbackId,
    List<int>? errorIds,
    int? interventionId,
    int? delayedOutcomeId,
  }) =>
      LearningAttempt(
        id: id ?? this.id,
        timestamp: timestamp,
        knowledgeTargetId: knowledgeTargetId,
        sessionId: sessionId,
        testType: testType,
        response: response,
        correctness: correctness,
        scorePct: scorePct,
        responseTimeMs: responseTimeMs,
        confidence: confidence,
        difficulty: difficulty,
        extras: extras,
        feedbackId: feedbackId ?? this.feedbackId,
        errorIds: errorIds ?? this.errorIds,
        interventionId: interventionId ?? this.interventionId,
        delayedOutcomeId: delayedOutcomeId ?? this.delayedOutcomeId,
        wasInterleaved: wasInterleaved,
        interleaveGroupId: interleaveGroupId,
        interleaveReason: interleaveReason,
        acquiredAt: acquiredAt,
      );
}
