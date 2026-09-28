import '../models/error_record.dart';
import '../models/learning_enums.dart';
import '../state/app_state.dart';
import 'experiment_service.dart';
import 'ranking_service.dart';

/// Phase 6 — Rule-based suggestions with priority ordering.
class SuggestionService {
  final RankingService _ranking = RankingService();

  /// Generates evidence-driven pedagogical suggestions from errors, delayed retention, and experiments.
  List<String> generateEvidenceSuggestions(AppState state, {int limit = 2}) {
    final suggestions = <String>[];
    final now = DateTime.now();

    // 1. Recurring errors by family (>= 3 in trailing 14 days)
    final cutoff = now.subtract(const Duration(days: 14));
    final recentErrors =
        state.errorRecords.where((e) => !e.createdAt.isBefore(cutoff)).toList();
    final familyCounts = <ErrorFamily, int>{};
    for (final err in recentErrors) {
      if (err.family != ErrorFamily.unknown) {
        familyCounts[err.family] = (familyCounts[err.family] ?? 0) + 1;
      }
    }
    for (final entry in familyCounts.entries) {
      if (entry.value >= 3) {
        final action = switch (entry.key) {
          ErrorFamily.conceptual => 'explain',
          ErrorFamily.procedural => 'apply',
          ErrorFamily.retrieval => 'contrast',
          ErrorFamily.attention => 'slow down',
          ErrorFamily.unknown => 'retrieve',
        };
        suggestions.add('Recurring ${entry.key.name} errors — try $action');
        break;
      }
    }

    // 2. Delayed retention lagging retrieval accuracy by > 20 pts
    if (state.delayedOutcomes.length >= 3) {
      final delayedSuccesses =
          state.delayedOutcomes.where((o) => !o.correctness.isFail).length;
      final delayedAcc =
          (delayedSuccesses / state.delayedOutcomes.length * 100);
      final productiveAttempts = state.learningAttempts
          .where((a) => a.testType.isProductive && !a.scorePct.isNaN)
          .toList();
      final retrievalAcc = productiveAttempts.isEmpty
          ? 0.0
          : (productiveAttempts.fold<double>(
                  0.0, (acc, a) => acc + a.scorePct) /
              productiveAttempts.length);
      final delta = (retrievalAcc - delayedAcc).round();
      if (delta > 20) {
        suggestions.add(
            'Retention lagging recall by ${delta}pts — schedule a delayed test');
      }
    }

    // 3. Powered experiment with enough data
    final activeExperiments =
        state.db.allExperiments().where((e) => e.active);
    for (final exp in activeExperiments) {
      final comparison = const ExperimentService().evaluateExperiment(
        experiment: exp,
        attempts: state.learningAttempts,
        delayedOutcomes: state.delayedOutcomes,
      );
      if (!comparison.underpowered) {
        suggestions.add(
            'Experiment "${exp.hypothesis}" has enough data — view comparison');
        break;
      }
    }

    return suggestions.take(limit).toList();
  }

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
