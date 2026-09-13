import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' hide Card;
import 'package:neural_workout/services/ranking_service.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/services/fsrs_engine.dart';
import 'package:neural_workout/state/app_state.dart';
/// Phase 5 — Ranking baseline math.
void main() {
  final rankingSvc = RankingService();

  group('RankingService', () {
    test('overall score is 0 with no blurts', () {
      final score = rankingSvc.overallScore(
        blurts: [],
        notes: [],
        pathways: [],
        linkCounts: {},
      );
      expect(score, 0);
    });

    test('overall score increases with better blurts', () {
      final low = rankingSvc.overallScore(
        blurts: [
          BlurtScore(
            id: 1,
            noteId: 1,
            noteTitle: 'T',
            date: DateTime.now(),
            scorePct: 30,
            matched: [],
            missed: ['a', 'b'],
          ),
        ],
        notes: [],
        pathways: [],
        linkCounts: {},
      );
      final high = rankingSvc.overallScore(
        blurts: [
          BlurtScore(
            id: 1,
            noteId: 1,
            noteTitle: 'T',
            date: DateTime.now(),
            scorePct: 90,
            matched: ['a', 'b'],
            missed: [],
            depthScore: 85,
            clarityScore: 90,
          ),
        ],
        notes: [],
        pathways: [],
        linkCounts: {},
      );
      expect(high, greaterThan(low));
    });

    test('weakest areas returns lowest-scoring areas', () {
      final areas = rankingSvc.weakestAreas(
        blurts: [
          BlurtScore(
            id: 1,
            noteId: 1,
            noteTitle: 'T',
            date: DateTime.now(),
            scorePct: 20,
            matched: [],
            missed: ['a', 'b', 'c'],
            depthScore: 10,
            clarityScore: 15,
          ),
        ],
        notes: [],
        pathways: [],
        linkCounts: {},
      );
      expect(areas.isNotEmpty, isTrue);
      // Depth and clarity are very low, so they should appear.
      expect(areas.any((a) => a.contains('Depth') || a.contains('Clarity') || a.contains('Retrieval')), isTrue);
    });

    test('mastered baseline constants are defined', () {
      expect(RankingService.masteredStabilityDays, 30);
      expect(RankingService.masteredDepth, 80);
      expect(RankingService.masteredClarity, 80);
    });

    // ── Core-loop regression: blurt score → FSRS rating ──
    // A 20% recall and a 95% recall MUST schedule differently, otherwise
    // FSRS can't adapt to the learner (spacing ignores difficulty).
    test('failed recall maps to again', () {
      expect(AppState.scoreToRating(20), Rating.again);
      expect(AppState.scoreToRating(0), Rating.again);
      expect(AppState.scoreToRating(39.9), Rating.again);
    });

    test('struggling recall maps to hard', () {
      expect(AppState.scoreToRating(40), Rating.hard);
      expect(AppState.scoreToRating(69.9), Rating.hard);
    });

    test('solid recall maps to good', () {
      expect(AppState.scoreToRating(70), Rating.good);
      expect(AppState.scoreToRating(89.9), Rating.good);
    });

    test('near-perfect recall maps to easy', () {
      expect(AppState.scoreToRating(90), Rating.easy);
      expect(AppState.scoreToRating(100), Rating.easy);
    });

    test('null score defaults to good', () {
      expect(AppState.scoreToRating(null), Rating.good);
    });

    test('FSRS schedules differently for different ratings', () {
      final engine = FsrsEngine();
      final card = engine.newCard();
      final easyResult = engine.review(card, Rating.easy);
      final againResult = engine.review(card, Rating.again);
      // Easy must schedule further out than again.
      expect(easyResult.interval, greaterThan(againResult.interval));
    });

    test('overall score does not double-count accuracy when no reviews', () {
      final b60 = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'T',
        date: DateTime.now(),
        scorePct: 60,
        matched: ['a'],
        missed: ['b'],
      );
      // With 0 reviews, retentionScore should be 0.0, not accuracy.
      final a = rankingSvc.overallScore(
        blurts: [b60],
        notes: [],
        pathways: [],
        linkCounts: {},
        totalReviews: 0,
        retrievableReviews: 0,
      );
      // With 10 reviews, retention contributes properly.
      final b = rankingSvc.overallScore(
        blurts: [b60],
        notes: [],
        pathways: [],
        linkCounts: {},
        totalReviews: 10,
        retrievableReviews: 6,
      );
      // a must be strictly less than b even though blurt accuracy is the same,
      // because b gets the extra 25% retention weight (60% * 0.25 = 15 points)
      // while a gets 0 for retention.
      expect(a, lessThan(b));
    });
  });
}
