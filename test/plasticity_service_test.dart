import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/daily_checkin.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/session.dart';
import 'package:neural_workout/services/plasticity_service.dart';

void main() {
  group('PlasticityService', () {
    const service = PlasticityService();
    final now = DateTime(2026, 9, 25);

    test('cognitiveSpeed: strict descending series -> negative slope, sharpening', () {
      final blurts = [
        BlurtScore(id: 1, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 10)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 3000),
        BlurtScore(id: 2, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 9)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 2500),
        BlurtScore(id: 3, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 8)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 2000),
        BlurtScore(id: 4, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 7)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 1500),
        BlurtScore(id: 5, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 6)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 1000),
        BlurtScore(id: 6, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 5)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 800),
        BlurtScore(id: 7, noteId: 1, noteTitle: 'A', date: now.subtract(const Duration(days: 4)), scorePct: 1, matched: [], missed: [], recallSpeedMs: 600),
      ];
      final res = service.cognitiveSpeed(blurts, now: now);
      expect(res.slopePerDay < -10, isTrue);
      expect(res.trend, 'sharpening');
      expect(res.isLearning, isFalse);
    });

    test('recoveryReserve: empty -> 0 with learning flag', () {
      final res = service.recoveryReserve([], now: now);
      expect(res.index0to100, 0);
      expect(res.isLearning, isTrue);
    });
    
    test('recoveryReserve: all 5s -> 100', () {
      final checkins = List.generate(7, (i) => DailyCheckin(
        date: now.subtract(Duration(days: i)), sleep: 5, energy: 5, activity: 5,
      ));
      final res = service.recoveryReserve(checkins, now: now);
      expect(res.index0to100, 100.0);
      expect(res.isLearning, isFalse);
    });

    test('recoveryReserve: all 1s -> 0', () {
      final checkins = List.generate(7, (i) => DailyCheckin(
        date: now.subtract(Duration(days: i)), sleep: 1, energy: 1, activity: 1,
      ));
      final res = service.recoveryReserve(checkins, now: now);
      expect(res.index0to100, 0.0);
      expect(res.isLearning, isFalse);
    });

    test('desirableDifficulty: 77.5% accuracy + 35% hard + 3 interleaves -> near 100', () {
      final blurts = List.generate(7, (i) => BlurtScore(id: i, noteId: 1, noteTitle: '', date: now.subtract(Duration(days: i)), scorePct: 0.775, matched: [], missed: []));
      // To get 3/day we need 21 interleave reviews over 7 days
      final moreReviews = List.generate(21, (i) => <String, dynamic>{
        'date': now.subtract(Duration(days: i % 7)).toIso8601String(),
        'rating': (i % 3 == 0) ? 'hard' : 'good', // 33% hard
        'wasInterleaved': true
      });
      final res = service.desirableDifficulty(blurts, moreReviews, now: now);
      expect(res.index0to100 > 90, isTrue); // Close to peak on all three metrics
      expect(res.detail, 'balanced');
      expect(res.isLearning, isFalse);
    });

    test('networkIntegration: fully connected', () {
      final notes = [
        Note(id: 1, title: 'A', body: '', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 1)),
        Note(id: 2, title: 'B', body: '', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 2)),
      ];
      final counts = {1: 1, 2: 1};
      final res = service.networkIntegration(notes, counts);
      expect(res.linked, 2);
      expect(res.index0to100 > 50, isTrue); 
    });

    test('mindfulness: all primed -> 100', () {
      final sessions = List.generate(7, (i) => Session(
        id: i, date: now.subtract(Duration(days: i)), duration: const Duration(minutes: 5), stepsCompleted: 8, focusPrimed: true
      ));
      final res = service.mindfulness(sessions, now: now);
      expect(res.index0to100, 100.0);
      expect(res.isLearning, isFalse);
    });
  });
}
