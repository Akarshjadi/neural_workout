import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/workout_session.dart';

/// Tests for the workflow WIP model — the guarantee that a phone-call / OS
/// kill loses seconds, not the whole session (autosave round-trip preserves
/// per-step content and progress, and never leaks text across steps).
void main() {
  group('WorkoutSessionState', () {
    test('autosave round-trips progress and per-step content', () {
      final start = DateTime(2026, 9, 9, 9, 0);
      final live = WorkoutSessionState(
        start: start,
        stepsCompleted: 3,
        anchorNoteId: 7,
        anchorTitle: 'TCP',
        blurtText: 'TCP is reliable',
        cheatSheetText: 'Reliable transport',
        linkText: 'connects to IP',
        teachingText: 'like a letter with delivery confirmation',
      );
      final restored = WorkoutSessionState.fromJson(live.toJson())!;
      expect(restored.start, start);
      expect(restored.stepsCompleted, 3);
      expect(restored.anchorNoteId, 7);
      expect(restored.anchorTitle, 'TCP');
      // Each step's own content survives independently (issue #4 / #3).
      expect(restored.blurtText, 'TCP is reliable');
      expect(restored.cheatSheetText, 'Reliable transport');
      expect(restored.linkText, 'connects to IP');
      expect(restored.teachingText,
          'like a letter with delivery confirmation');
      expect(restored.isComplete, isFalse);
    });

    test('content containing JSON-hostile characters survives', () {
      final w = WorkoutSessionState(
        start: DateTime(2026, 9, 9),
        anchorTitle: 'A "special" card',
        blurtText: 'line one\nline "two" with \\ backslash',
      );
      final restored = WorkoutSessionState.fromJson(w.toJson())!;
      expect(restored.anchorTitle, 'A "special" card');
      expect(restored.blurtText, 'line one\nline "two" with \\ backslash');
    });

    test('completed session flags and elapsed math', () {
      final start = DateTime(2026, 9, 9, 9, 0);
      final done = WorkoutSessionState(
        start: start,
        stepsCompleted: 8,
        anchorTitle: 'x',
      );
      expect(done.isComplete, isTrue);
      expect(done.elapsed(DateTime(2026, 9, 9, 9, 5)), const Duration(minutes: 5));
    });

    test('malformed / missing JSON yields null (safe resume fallback)', () {
      expect(WorkoutSessionState.fromJson(null), isNull);
      expect(WorkoutSessionState.fromJson('not json'), isNull);
      expect(WorkoutSessionState.fromJson('{"foo":1}'), isNull);
    });

    test('unknown schema version returns null (version check)', () {
      // A session with v=2 should be rejected since we only support v=1.
      final json = '{"v":2,"start":"2026-09-09T09:00:00.000","stepsCompleted":0,"anchorTitle":"x"}';
      expect(WorkoutSessionState.fromJson(json), isNull);
    });

    test('empty content is independent per field (no cross-step leakage)', () {
      final w = WorkoutSessionState(
        start: DateTime.now(),
        anchorTitle: 'x',
        blurtText: 'only blur',
      );
      expect(w.cheatSheetText, '');
      expect(w.linkText, '');
      expect(w.teachingText, '');
    });
  });
}