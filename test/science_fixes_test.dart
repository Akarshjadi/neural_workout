import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/state/app_state.dart';

/// Regression tests for the science fixes — specifically the claims that
/// previously had NO test coverage:
///   * score→rating bands (FSRS rating must reflect retrieval difficulty)
///   * cold-start guard (null score must NOT silently inflate the interval)
void main() {
  group('scoreToRating boundaries (FSRS bands)', () {
    test('failed recall (<40) maps to again — shortest interval', () {
      expect(AppState.scoreToRating(0), Rating.again);
      expect(AppState.scoreToRating(20), Rating.again);
      expect(AppState.scoreToRating(39.9), Rating.again);
    });

    test('rocky recall (40–70) maps to hard', () {
      expect(AppState.scoreToRating(40), Rating.hard);
      expect(AppState.scoreToRating(69.9), Rating.hard);
    });

    test('solid recall (70–90) maps to good', () {
      expect(AppState.scoreToRating(70), Rating.good);
      expect(AppState.scoreToRating(89.9), Rating.good);
    });

    test('mastered recall (≥90) maps to easy — longest interval', () {
      expect(AppState.scoreToRating(90), Rating.easy);
      expect(AppState.scoreToRating(100), Rating.easy);
    });

    test('null score maps to good, NOT easy (cold-start guard)', () {
      // A cold-start blurt that never got scored must not be treated as
      // mastered — that would silently inflate the FSRS interval.
      final rating = AppState.scoreToRating(null);
      expect(rating, isNot(Rating.easy));
      expect(rating, Rating.good);
    });

    test('rating bands are ordered so easy schedules further out than again', () {
      final easyScore = AppState.scoreToRating(95);
      final againScore = AppState.scoreToRating(15);
      expect(easyScore, Rating.easy);
      expect(againScore, Rating.again);
      // fsrs Rating enum: again=1, hard=2, good=3, easy=4 — higher = further.
      expect(easyScore.index, greaterThan(againScore.index));
    });
  });

  test('scoreToRating(NaN) maps to again, never easy', () {
    expect(AppState.scoreToRating(double.nan), Rating.again);
  });

  test('scoreToRating(NaN) maps to again, never easy', () {
    expect(AppState.scoreToRating(double.nan), Rating.again);
  });
}
