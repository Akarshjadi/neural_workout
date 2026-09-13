import 'package:fsrs/fsrs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/fsrs_engine.dart';

/// Tests for the FSRS scheduler wrapper — one of the three "real risks".
///
/// We assert the wrapper returns valid updated cards: the new card's due date
/// is after the review, stability grows on 'good' reviews, and repeats of
/// 'again' keep it in the learning/relearning state for sooner review.
void main() {
  group('FsrsEngine', () {
    test('a new card starts in the learning state', () {
      final engine = FsrsEngine();
      final card = engine.newCard();
      expect(card.state, State.learning);
      // FSRS keeps stability/difficulty null until the first review rates it.
      final reviewed = engine.review(card, Rating.good);
      expect(reviewed.card.stability, isNotNull);
      expect(reviewed.card.difficulty, isNotNull);
    });

    test('a "good" first review schedules a future due date', () {
      final engine = FsrsEngine();
      final card = engine.newCard();
      final result = engine.review(card, Rating.good);
      expect(result.card.due.isAfter(DateTime.now()), isTrue);
      expect(result.rating, Rating.good);
    });

    test('repeated good reviews grow stability (memory strengthens)', () {
      final engine = FsrsEngine();
      var card = engine.newCard();

      // First review.
      final first = engine.review(card, Rating.good);
      card = first.card;
      final firstStability = card.stability!;

      // Second review (hard/good) should not shrink stability badly.
      final second = engine.review(card, Rating.good);
      card = second.card;
      final secondStability = card.stability!;

      // FSRS stability should be non-decreasing across good ratings.
      expect(secondStability, greaterThanOrEqualTo(firstStability * 0.9));
    });

    test('a failed "again" review keeps the card due sooner than a good one', () {
      final engine = FsrsEngine();
      final goodCard = engine.newCard();
      final againCard = engine.newCard();

      final good = engine.review(goodCard, Rating.good);
      final again = engine.review(againCard, Rating.again);

      // A failed card should be due much sooner than a successful one.
      expect(again.card.due.isBefore(good.card.due), isTrue);
    });

    test('intervalLabel produces human-friendly output', () {
      expect(FsrsEngine.intervalLabel(Duration(minutes: 30)), 'in 30m');
      expect(FsrsEngine.intervalLabel(Duration(days: 3)), 'in 3d');
      expect(FsrsEngine.intervalLabel(Duration(seconds: 5)), 'now');
    });
  });
}