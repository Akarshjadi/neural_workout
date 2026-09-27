import 'dart:convert';
import '../models/blurt_score.dart';
import '../models/note.dart';
import '../models/session.dart';

class StrategyProfile {
  final double retrieval;
  final double spacing;
  final double interleaving;
  final double elaboration;
  final double concreteExamples;
  final double dualCoding;

  final String retrievalEvidence;
  final String spacingEvidence;
  final String interleavingEvidence;
  final String elaborationEvidence;
  final String concreteExamplesEvidence;
  final String dualCodingEvidence;

  const StrategyProfile({
    required this.retrieval,
    required this.spacing,
    required this.interleaving,
    required this.elaboration,
    required this.concreteExamples,
    required this.dualCoding,
    required this.retrievalEvidence,
    required this.spacingEvidence,
    required this.interleavingEvidence,
    required this.elaborationEvidence,
    required this.concreteExamplesEvidence,
    required this.dualCodingEvidence,
  });
}

class StrategyProfileService {
  /// Computes a StrategyProfile yielding six 0-100 scores and honest evidence text based entirely on local analytics data.
  StrategyProfile compute({
    required List<BlurtScore> blurts,
    required List<Note> notes,
    required List<Session> sessions,
    required List<Map<String, dynamic>> reviewRows,
    required int interleavedCount,
    required int totalReviewCount,
    required Map<int, int> linkCounts,
  }) {
    // 1. Retrieval
    double retrieval = 0.0;
    if (blurts.isNotEmpty) {
      retrieval = blurts.fold<double>(0, (sum, b) => sum + b.scorePct) / blurts.length;
    }
    final retrievalEv = blurts.isEmpty
        ? 'No recall practice yet'
        : 'Avg ${retrieval.toStringAsFixed(0)}% semantic match in blurts';

    // 2. Spacing
    // Metric: approximate with session-day distribution, or simply unique dates from review history.
    double spacing = 0.0;
    if (totalReviewCount > 0) {
      final uniqueDays = reviewRows.map((r) {
        final d = DateTime.tryParse(r['date'] as String? ?? '');
        return d == null ? '' : '${d.year}-${d.month}-${d.day}';
      }).where((s) => s.isNotEmpty).toSet().length;
      spacing = (uniqueDays / (totalReviewCount > 30 ? 30 : totalReviewCount) * 100).clamp(0.0, 100.0);
    }
    final spacingEv = totalReviewCount == 0
        ? 'No reviews yet'
        : 'Spaced across ${spacing > 50 ? "most" : "few"} active days (approximated)';

    // 3. Interleaving
    double interleaving = 0.0;
    if (totalReviewCount > 0) {
      interleaving = (interleavedCount / totalReviewCount * 100).clamp(0.0, 100.0);
    }
    final interleavingEv = totalReviewCount == 0
        ? 'No reviews yet'
        : '${interleaving.toStringAsFixed(0)}% of reviews were interleaved';

    // 4. Elaboration
    // Avg depthScore blended with cross-link density (per RankingService).
    double avgDepth = 0.0;
    final depths = blurts.map((b) => b.depthScore).whereType<double>().toList();
    if (depths.isNotEmpty) {
      avgDepth = depths.reduce((a, b) => a + b) / depths.length;
    }
    
    int linkedNotes = 0;
    for (final c in linkCounts.values) {
      if (c > 0) linkedNotes++;
    }
    double crossLinkScore = notes.isNotEmpty
        ? (linkedNotes / notes.length * 100).clamp(0.0, 100.0)
        : 0.0;
    
    double elaboration = (avgDepth * 0.5 + crossLinkScore * 0.5).clamp(0.0, 100.0);
    final elaborationEv = notes.isEmpty
        ? 'No notes to elaborate on'
        : 'AI depth ${avgDepth.toStringAsFixed(0)} & ${crossLinkScore.toStringAsFixed(0)}% linked';

    // 5. Concrete Examples
    double concreteExamples = 0.0;
    int sessionsWithExamples = 0;
    for (final s in sessions) {
      if (s.autosaveJson != null && s.autosaveJson!.isNotEmpty) {
        try {
          final map = jsonDecode(s.autosaveJson!);
          final teachingText = map['teachingText'] as String?;
          if (teachingText != null && teachingText.trim().isNotEmpty) {
            sessionsWithExamples++;
          }
        } catch (_) {}
      }
    }
    if (sessions.isNotEmpty) {
      concreteExamples = (sessionsWithExamples / sessions.length * 100).clamp(0.0, 100.0);
    }
    final concreteExamplesEv = sessions.isEmpty
        ? 'No sessions completed'
        : '${concreteExamples.toStringAsFixed(0)}% of sessions used analogies';

    // 6. Dual Coding (Unused currently as per prompt "honest, per the app's no-fake-data rule")
    return StrategyProfile(
      retrieval: retrieval,
      spacing: spacing,
      interleaving: interleaving,
      elaboration: elaboration,
      concreteExamples: concreteExamples,
      dualCoding: 0.0,
      retrievalEvidence: retrievalEv,
      spacingEvidence: spacingEv,
      interleavingEvidence: interleavingEv,
      elaborationEvidence: elaborationEv,
      concreteExamplesEvidence: concreteExamplesEv,
      dualCodingEvidence: 'Not tracked yet',
    );
  }
}
