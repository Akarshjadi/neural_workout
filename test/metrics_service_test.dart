import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/metrics_service.dart';
import 'package:neural_workout/models/blurt_score.dart';

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
  });
}
