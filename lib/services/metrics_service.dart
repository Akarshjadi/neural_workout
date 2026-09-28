import '../models/blurt_score.dart';
import '../models/delayed_outcome.dart';
import '../models/intervention.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import '../models/session.dart';
import 'feedback_diagnosis_service.dart';

/// Per-blurt deterministic metrics (Phase 2).
/// AI only scores depthScore and clarityScore; everything else is computed here.
class BlurtMetrics {
  final double recallAccuracy; // 0..100 from BlurtScore.scorePct
  final int? recallSpeedMs; // time from session start to blurt submit
  final double? retentionOverTime; // delta per day between consecutive blurts
  final double crossLinkDensity; // % of other notes linked to this one (0..100)
  final double? lossRate; // inverse of retention slope

  const BlurtMetrics({
    required this.recallAccuracy,
    this.recallSpeedMs,
    this.retentionOverTime,
    this.crossLinkDensity = 0,
    this.lossRate,
  });
}

class MetricsService {
  /// Compute metrics for a single blurt against historical data.
  BlurtMetrics compute({
    required BlurtScore blurt,
    required List<BlurtScore> allScores,
    required List<Session> sessions,
    required int linkCountForNote,
    required int totalNotes,
  }) {
    final recallAccuracy = blurt.scorePct;
    final recallSpeedMs = blurt.recallSpeedMs;

    // Retention: compare to previous blurt on same note.
    final prev = allScores
        .where((s) => s.noteId == blurt.noteId && s.date.isBefore(blurt.date))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double? retentionOverTime;
    double? lossRate;
    if (prev.isNotEmpty) {
      final days = blurt.date.difference(prev.first.date).inDays;
      if (days > 0) {
        final delta = blurt.scorePct - prev.first.scorePct;
        retentionOverTime = delta / days;
        lossRate = retentionOverTime < 0 ? -retentionOverTime : 0;
      }
    }

    // Cross-link density: % of other notes this note is linked to.
    final crossLinkDensity = totalNotes > 1
        ? (linkCountForNote / (totalNotes - 1) * 100).clamp(0.0, 100.0)
        : 0.0;

    return BlurtMetrics(
      recallAccuracy: recallAccuracy,
      recallSpeedMs: recallSpeedMs,
      retentionOverTime: retentionOverTime,
      crossLinkDensity: crossLinkDensity,
      lossRate: lossRate,
    );
  }

  /// Alias/helper: computes Brier score across confidence-rated attempts.
  double calculateBrierScore(List<LearningAttempt> attempts) =>
      const FeedbackDiagnosisService().calculateCalibration(attempts).brierScore;

  /// Alias/helper: computes mean transfer score from delayed outcomes.
  double? computeTransferScore(List<DelayedOutcome> outcomes) {
    final transferOutcomes = outcomes
        .where((o) => o.bucket == DelayBucket.transfer && !o.scorePct.isNaN)
        .toList();
    if (transferOutcomes.isEmpty) return null;
    return transferOutcomes.fold<double>(0.0, (acc, o) => acc + o.scorePct) /
        transferOutcomes.length;
  }

  /// Alias/helper: computes failure error rate fraction across valid attempts.
  double calculateErrorRate(List<LearningAttempt> attempts) {
    final valid = attempts.where((a) => !a.scorePct.isNaN).toList();
    if (valid.isEmpty) return 0.0;
    return valid.where((a) => a.correctness.isFail).length / valid.length;
  }

  /// Alias/helper: computes steps per minute across completed sessions.
  double calculatePerformanceDensity(List<Session> sessions) {
    final totalMinutes =
        sessions.fold<int>(0, (acc, s) => acc + s.duration.inMinutes);
    if (totalMinutes == 0) return 0.0;
    final totalSteps =
        sessions.fold<int>(0, (acc, s) => acc + s.stepsCompleted);
    return totalSteps / totalMinutes;
  }

  /// Alias/helper: computes delayed mean score across intervention-linked attempts.
  double computeInterventionResponsiveness(
    List<LearningAttempt> attempts,
    List<Intervention> interventions,
  ) {
    final interventionIds = interventions.map((i) => i.id).toSet();
    final valid = attempts
        .where((a) =>
            a.interventionId != null &&
            (interventionIds.isEmpty || interventionIds.contains(a.interventionId)) &&
            a.isDelayed &&
            !a.scorePct.isNaN)
        .toList();
    if (valid.isEmpty) return 0.0;
    return valid.fold<double>(0.0, (acc, a) => acc + a.scorePct) / valid.length;
  }
}
