import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/cognition_engine.dart';

void main() {
  final today = DateTime(2026, 9, 25);
  final engine = CognitionEngine(
    today: today,
    historyDays: 30,
    forecastDays: 14,
  );

  Note noteAt(DateTime d) => Note(
    id: d.day,
    title: 'N',
    body: 'b',
    kind: NoteKind.blurtSummary,
    createdAt: d,
    updatedAt: d,
    card: Card(cardId: d.day),
  );

  test('produces a 30-point history and 14-point forecast', () {
    final f = engine.neuroForecast(
      notes: const [],
      sessions: const [],
      blurts: const [],
      reviews: const [],
      breaks: const [],
    );
    expect(f.history.length, 30);
    expect(f.predicted.length, 14);
  });

  test('novelty factor responds to new notes', () {
    final notes = List.generate(3, (i) => noteAt(today));
    final f = engine.neuroFactorsFor(
      notes: notes,
      sessions: const [],
      blurts: const [],
      reviews: const [],
      breaks: const [],
    );
    final novelty = f.firstWhere((x) => x.name == 'Novelty');
    expect(novelty.value01, 1.0); // 3 notes saturates
  });

  test(
    'damped forecast never exceeds the historical max by more than 15 pts',
    () {
      // Feed a strong rising trend over 20 days.
      final notes = <Note>[];
      for (var i = 0; i < 20; i++) {
        notes.add(noteAt(today.subtract(Duration(days: 19 - i))));
        notes.add(noteAt(today.subtract(Duration(days: 19 - i))));
        notes.add(noteAt(today.subtract(Duration(days: 19 - i))));
      }
      final f = engine.neuroForecast(
        notes: notes,
        sessions: const [],
        blurts: const [],
        reviews: const [],
        breaks: const [],
      );
      final histMax = f.history
          .map((h) => h.value)
          .reduce((a, b) => a > b ? a : b);
      expect(f.predictedEnd, lessThanOrEqualTo(histMax + 15));
    },
  );

  test('memory forecast carries forward with decay on empty days', () {
    final bs = [
      BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'T',
        date: today.subtract(const Duration(days: 15)),
        scorePct: 85,
        matched: const [],
        missed: const [],
      ),
    ];
    final f = engine.memoryForecast(blurts: bs, reviews: const []);
    // After 15 days of decay the last point should still be below 85 and > 70.
    expect(f.history.last.value, lessThan(85));
    expect(f.history.last.value, greaterThan(70));
  });

  test('residual std is zero with a perfectly flat series', () {
    final f = engine.focusForecast(
      sessions: const [],
      blurts: const [],
      reviews: const [],
    );
    // All-zero history has no variance.
    expect(f.residualStd, 0);
  });

  test('factors sum to the day\'s neuro score', () {
    final notes = List.generate(2, (i) => noteAt(today));
    final f = engine.neuroFactorsFor(
      notes: notes,
      sessions: const [],
      blurts: const [],
      reviews: const [],
      breaks: const [],
    );
    final total = f.fold<double>(0, (a, x) => a + x.contribution);
    final series = engine.neuroForecast(
      notes: notes,
      sessions: const [],
      blurts: const [],
      reviews: const [],
      breaks: const [],
    );
    expect(total, closeTo(series.history.last.value, 0.01));
  });
}
