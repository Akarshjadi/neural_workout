import '../state/app_state.dart';
import 'ranking_service.dart';

/// Phase 6 — Rule-based suggestions with priority ordering.
class SuggestionService {
  final RankingService _ranking = RankingService();

  /// Generate 1-2 actionable suggestions, prioritized by importance.
  List<String> generateSuggestions(AppState state) {
    final critical = <String>[];
    final high = <String>[];
    final medium = <String>[];
    final low = <String>[];

    final now = DateTime.now();
    final hasToday = state.sessions.any((s) =>
        s.date.year == now.year && s.date.month == now.month && s.date.day == now.day);

    // Streak at risk: no session today, after 8 PM. Grace-token aware.
    if (!hasToday && now.hour >= 20) {
      critical.add('No session yet today — quick 2-min blurt keeps it going, or use a grace token');
    }

    // High: many due cards.
    if (state.dueNotesList.isNotEmpty) {
      if (state.dueNotesList.length >= 10) {
        high.add('${state.dueNotesList.length} notes due — review session recommended');
      } else {
        medium.add('${state.dueNotesList.length} notes due for review');
      }
    }

    // Medium: weakest area to focus on.
    final linkCounts = state.db.linkCountsByNote();
    final reviewStats = AppState.computeReviewStats(state.db);
    final weakest = _ranking.weakestAreas(
      blurts: state.blurtScores,
      notes: state.notes,
      pathways: state.pathwayRecords,
      linkCounts: linkCounts,
      totalReviews: reviewStats.total,
      retrievableReviews: reviewStats.retrievable,
    );
    if (weakest.isNotEmpty) {
      medium.add('Focus on: ${weakest.first}');
    }

    // Low: streak at risk (after 6 PM but before 8 PM).
    if (!hasToday && now.hour >= 18 && now.hour < 20) {
      low.add('Quick session — keep your streak alive');
    }

    // Return top 2 by priority.
    final all = [...critical, ...high, ...medium, ...low];
    return all.take(2).toList();
  }
}
