import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/forgetting_curve_service.dart';

void main() {
  final service = ForgettingCurveService();

  test('retentionAt(1.5, 0) == 1.0', () {
    expect(service.retentionAt(1.5, 0), equals(1.0));
  });

  test('monotonic decrease', () {
    final t1 = service.retentionAt(2.0, 1.0);
    final t2 = service.retentionAt(2.0, 2.0);
    final t3 = service.retentionAt(2.0, 3.0);
    expect(t1 > t2, isTrue);
    expect(t2 > t3, isTrue);
  });

  test('retentionAt(S, S)≈0.37 (1/e — pin the math)', () {
    final ret = service.retentionAt(5.0, 5.0);
    expect(ret, closeTo(0.3678, 0.001));
  });

  test('empty/decay series edge cases', () {
    final defaultNote = Note(
      id: 1,
      title: 'A',
      body: 'B',
      kind: NoteKind.cheatSheet,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      card: Card(cardId: 1), // Default card has stability = 0 (or close) often in FSRS init.
    );
    final series = service.decaySeries(defaultNote, fallbackStability: 1.0);
    
    expect(series.length, equals(31)); // 0 to 30 days
    expect(series.first.x, equals(0.0));
    expect(series.first.y, equals(100.0));
    expect(series.last.x, equals(30.0));
    // Since fallback S=1.0, e^(-30/1) should be near 0
    expect(series.last.y, closeTo(0.0, 0.001));
  });
}
