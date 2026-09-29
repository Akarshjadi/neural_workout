import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/workout_session.dart';

void main() {
  test('attemptId survives an autosave round-trip', () {
    final live = WorkoutSessionState(start: DateTime(2026), anchorTitle: 'x').copyWith(attemptId: 42);
    expect(WorkoutSessionState.fromJson(live.toJson())!.attemptId, 42);
  });
}
