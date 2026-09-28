import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/metrics_service.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/focus_integrity.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';

/// Phase 2 — Deterministic metrics calculations.
void main() {
  final metricsSvc = MetricsService();

  group('MetricsService', () {
    test('computes recall accuracy from blurt score', () {
      final blurt = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now(),
        scorePct: 75,
        matched: ['a'],
        missed: ['b'],
      );
      final result = metricsSvc.compute(
        blurt: blurt,
        allScores: [blurt],
        sessions: [],
        linkCountForNote: 3,
        totalNotes: 10,
      );
      expect(result.recallAccuracy, 75);
    });

    test('computes cross-link density', () {
      final blurt = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now(),
        scorePct: 50,
        matched: [],
        missed: [],
      );
      final result = metricsSvc.compute(
        blurt: blurt,
        allScores: [blurt],
        sessions: [],
        linkCountForNote: 5,
        totalNotes: 10,
      );
      // 5 links out of 9 possible = ~55.6%.
      expect(result.crossLinkDensity, closeTo(55.6, 0.1));
    });

    test('computes retention over time', () {
      final prev = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now().subtract(const Duration(days: 7)),
        scorePct: 60,
        matched: ['a'],
        missed: ['b'],
      );
      final current = BlurtScore(
        id: 2,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now(),
        scorePct: 80,
        matched: ['a', 'b'],
        missed: [],
      );
      final result = metricsSvc.compute(
        blurt: current,
        allScores: [prev, current],
        sessions: [],
        linkCountForNote: 0,
        totalNotes: 1,
      );
      expect(result.retentionOverTime, isNotNull);
      // Delta = 20 over 7 days ≈ 2.86 per day.
      expect(result.retentionOverTime! > 0, isTrue);
    });

    test('loss rate is zero when retention is positive', () {
      final prev = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now().subtract(const Duration(days: 7)),
        scorePct: 60,
        matched: ['a'],
        missed: ['b'],
      );
      final current = BlurtScore(
        id: 2,
        noteId: 1,
        noteTitle: 'Test',
        date: DateTime.now(),
        scorePct: 80,
        matched: ['a', 'b'],
        missed: [],
      );
      final result = metricsSvc.compute(
        blurt: current,
        allScores: [prev, current],
        sessions: [],
        linkCountForNote: 0,
        totalNotes: 1,
      );
      expect(result.lossRate, 0);
    });

    test('calculateAverageDepth avoids NaN on sparse data', () {
      expect(metricsSvc.calculateAverageDepth([]), 0.0);
      expect(metricsSvc.calculateAverageDepth([
        BlurtScore(id: 1, noteId: 1, noteTitle: '', date: DateTime.now(), scorePct: 0, matched: [], missed: [], depthScore: double.nan),
        BlurtScore(id: 2, noteId: 1, noteTitle: '', date: DateTime.now(), scorePct: 0, matched: [], missed: [], depthScore: null),
      ]), 0.0);
      expect(metricsSvc.calculateAverageDepth([
        BlurtScore(id: 3, noteId: 1, noteTitle: '', date: DateTime.now(), scorePct: 0, matched: [], missed: [], depthScore: 80.0),
        BlurtScore(id: 4, noteId: 1, noteTitle: '', date: DateTime.now(), scorePct: 0, matched: [], missed: [], depthScore: 90.0),
      ]), 85.0);
    });

    test('calculateFocusRatio avoids NaN on sparse data', () {
      expect(metricsSvc.calculateFocusRatio([]), 0.0);
      expect(metricsSvc.calculateFocusRatio([
        FocusIntegrity(longestFocusMs: 0), // no plannedDuration, ratio is null
      ]), 0.0);
      expect(metricsSvc.calculateFocusRatio([
        FocusIntegrity(plannedDuration: Duration(minutes: 10), actualDuration: Duration(minutes: 5)),
        FocusIntegrity(plannedDuration: Duration(minutes: 10), actualDuration: Duration(minutes: 10)),
      ]), 0.75); // 0.5 and 1.0 => avg 0.75
    });

    test('calculateBaselineScore avoids NaN on sparse data', () {
      expect(metricsSvc.calculateBaselineScore([]), 0.0);
      expect(metricsSvc.calculateBaselineScore([
        LearningAttempt(id: 1, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.correct), // defaults to NaN scorePct
      ]), 0.0);
      expect(metricsSvc.calculateBaselineScore([
        LearningAttempt(id: 1, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 70),
        LearningAttempt(id: 2, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90),
      ]), 80.0);
    });
  });
}

