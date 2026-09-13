import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/streak_service.dart';

/// Tests for the streak grace-token logic (issue 7).
///
/// The plan locks in "1 free miss per 7-day window". The old implementation
/// used a single never-resetting `misses` counter, so only one miss was ever
/// allowed and a grace token was spent forever. These tests pin the rolling
/// 7-day-window behaviour.
void main() {
  final svc = StreakService();
  DateTime day(int d) => DateTime(2026, 9, d);

  test('fresh user with no sessions has a zero streak', () {
    final r = svc.compute([], now: day(10));
    expect(r.current, 0);
  });

  test('consecutive session days build the streak', () {
    final r = svc.compute([day(8), day(9), day(10)], now: day(10));
    expect(r.current, 3);
  });

  test('a single missed day is bridged by grace (does not break the streak)',
      () {
    // Sessions on 8, 9 and 11, missed 10.
    final r = svc.compute([day(8), day(9), day(11)], now: day(11));
    expect(r.current, 3, reason: 'the single miss must not end the run');
  });

  test('two misses within a 7-day window break the streak', () {
    // Sessions on 8 and 11, missed 9 and 10 (both within 6 days of each other).
    final r = svc.compute([day(8), day(11)], now: day(11));
    expect(r.current, 1, reason: 'two misses in one window end the run');
  });

  test('grace token is fresh again once the miss window passes', () {
    // Consecutive sessions day 5..11. The nearest miss (day 4) is 7 days back,
    // so a grace is available for today (the old bug never released it).
    final sessions = List.generate(7, (i) => day(5 + i));
    final r = svc.compute(sessions, now: day(11));
    expect(r.current, 7);
    expect(r.graceAvailable, isTrue,
        reason: 'a fresh grace token is available in the current window');
  });

  test('a recent miss still consumes the current window grace', () {
    // Sessions on 8,9,10 — but a miss on day 7 keeps the current window spent,
    // so the user cannot afford another miss right away.
    final r = svc.compute([day(8), day(9), day(10)], now: day(10));
    expect(r.graceAvailable, isFalse);
  });

  test('grace day after a recent miss does not extend streak (grace bridges but does not count)', () {
    // Sessions on days 5,6,8,9; grace used on day 7; today (day 10) missed.
    // The grace on day 7 bridges the gap between 6 and 8 but a fresh miss on
    // day 10 should stop the streak because the grace was already consumed.
    final sessions = [day(5), day(6), day(8), day(9)];
    final graceDays = {day(7)};
    final r = svc.compute(sessions, now: day(10), graceDays: graceDays);
    // Streak should be 4 (days 5,6,7-grace,8,9) — day 10 is a miss and
    // the grace was already used on day 7 so it cannot bridge day 10.
    expect(r.current, 4, reason: 'grace bridges but does not increment; fresh miss after grace stops streak');
    expect(r.graceAvailable, isFalse, reason: 'grace was consumed on day 7');
  });
}