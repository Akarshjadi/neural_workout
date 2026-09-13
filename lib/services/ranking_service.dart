import '../models/blurt_score.dart';
import '../models/note.dart';
import '../models/pathway_record.dart';

/// Phase 5 — Ranking and cognitive profile.
class RankingService {
  /// "Mastered" baseline constants.
  static const int masteredStabilityDays = 30;
  static const double masteredDepth = 80;
  static const double masteredClarity = 80;

  /// Returns 0-100 aggregate score across all metrics.
  ///
  /// [linkCounts] is a map of noteId -> number of links for that note.
  /// [totalReviews] and [retrievableReviews] compute real retention from FSRS data.
  double overallScore({
    required List<BlurtScore> blurts,
    required List<Note> notes,
    required List<PathwayRecord> pathways,
    required Map<int, int> linkCounts,
    int totalReviews = 0,
    int retrievableReviews = 0,
  }) {
    if (blurts.isEmpty) return 0;

    final accuracy = blurts.fold<double>(0, (a, b) => a + b.scorePct) / blurts.length;

    final depths = blurts.map((b) => b.depthScore).whereType<double>().toList();
    final clarities = blurts.map((b) => b.clarityScore).whereType<double>().toList();
    final avgDepth = depths.isEmpty ? 0.0 : depths.reduce((a, b) => a + b) / depths.length;
    final avgClarity = clarities.isEmpty ? 0.0 : clarities.reduce((a, b) => a + b) / clarities.length;

    // Cross-link density: % of notes that have at least one link.
    // A well-organized knowledge base has most nodes connected, not all nodes
    // fully saturated (which would be a complete graph — unrealistic).
    final linkedNotes = linkCounts.values.where((c) => c > 0).length;
    final crossLinkScore = notes.isNotEmpty
        ? (linkedNotes / notes.length * 100).clamp(0.0, 100.0)
        : 0.0;

    // Real retention: % of reviews where card was retrievability > threshold.
    // When totalReviews == 0, set to 0.0 (do NOT substitute accuracy).
    final retentionScore = totalReviews > 0
        ? (retrievableReviews / totalReviews * 100).clamp(0.0, 100.0)
        : 0.0;

    // Pathway activation: average of all pathway booleans over last 7 days.
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecs = pathways.where((p) => !p.date.isBefore(weekAgo)).toList();
    final pathwayScore = weekRecs.isEmpty
        ? 0.0
        : weekRecs.fold<double>(0, (a, p) {
            int count = 0;
            if (p.retrieval) count++;
            if (p.compression) count++;
            if (p.association) count++;
            if (p.explanation) count++;
            if (p.context) count++;
            return a + (count / 5 * 100);
          }) / weekRecs.length;

    // Weighted average: renormalize when totalReviews == 0 to keep 0..100 scale.
    final weighted = totalReviews == 0
        ? accuracy * 0.40 +
            retentionScore * 0.0 +
            avgDepth * 0.20 +
            avgClarity * 0.15 +
            crossLinkScore * 0.125 +
            pathwayScore * 0.125
        : accuracy * 0.30 +
            retentionScore * 0.25 +
            avgDepth * 0.15 +
            avgClarity * 0.10 +
            crossLinkScore * 0.10 +
            pathwayScore * 0.10;

    return weighted.clamp(0, 100);
  }

  /// Returns weakest 3 areas as strings, for suggestions.
  List<String> weakestAreas({
    required List<BlurtScore> blurts,
    required List<Note> notes,
    required List<PathwayRecord> pathways,
    required Map<int, int> linkCounts,
    int totalReviews = 0,
    int retrievableReviews = 0,
  }) {
    final areas = <String, double>{};

    if (blurts.isNotEmpty) {
      final accuracy = blurts.fold<double>(0, (a, b) => a + b.scorePct) / blurts.length;
      areas['Retrieval accuracy'] = accuracy;

      final depths = blurts.map((b) => b.depthScore).whereType<double>().toList();
      if (depths.isNotEmpty) {
        areas['Depth of understanding'] = depths.reduce((a, b) => a + b) / depths.length;
      }
      final clarities = blurts.map((b) => b.clarityScore).whereType<double>().toList();
      if (clarities.isNotEmpty) {
        areas['Clarity of explanation'] = clarities.reduce((a, b) => a + b) / clarities.length;
      }
    }

    // Real retention score.
    // When totalReviews == 0, don't substitute blurts.avg — just use 0.
    final retentionScore = totalReviews > 0
        ? (retrievableReviews / totalReviews * 100).clamp(0.0, 100.0)
        : 0.0;
    areas['Retention'] = retentionScore;

    // Cross-link density: % of notes with at least one link.
    final linkedNotes = linkCounts.values.where((c) => c > 0).length;
    final crossLinkScore = notes.isNotEmpty
        ? (linkedNotes / notes.length * 100).clamp(0.0, 100.0)
        : 0.0;
    areas['Cross-link density'] = crossLinkScore;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekRecs = pathways.where((p) => !p.date.isBefore(weekAgo)).toList();
    if (weekRecs.isNotEmpty) {
      final pathwayScore = weekRecs.fold<double>(0, (a, p) {
            int count = 0;
            if (p.retrieval) count++;
            if (p.compression) count++;
            if (p.association) count++;
            if (p.explanation) count++;
            if (p.context) count++;
            return a + (count / 5 * 100);
          }) / weekRecs.length;
      areas['Pathway activation'] = pathwayScore;
    }

    final sorted = areas.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
}
