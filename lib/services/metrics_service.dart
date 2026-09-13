import '../models/blurt_score.dart';
import '../models/session.dart';

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
}
