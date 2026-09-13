/// Streak tracking with a grace-token system (PLAN §6).
/// Choice (a) selected: persistence implemented via AppState.useGraceToken() writing PathwayRecord.graceUsed = true.
///
/// Rules locked in the plan:
///   - 1 free "miss day" per 7-day window that does NOT break the streak.
///   - A day counts toward the streak if it has a session OR a used grace.
///   - Never guilt-shame: consumers render a neutral "resume when ready".
///
/// Algorithm: walk backward from today, counting days that had a session.
/// Allow at most ONE missing day in the run; the first miss is bridged via
/// grace. A second miss stops the streak. O(days-back) — fine for a personal
/// app (a year is ~365 iterations at most).
///
/// The grace token is persisted in PathwayRecord.graceUsed so it survives
/// app restarts and is auditable.
class StreakService {
  StreakInfo compute(
    List<DateTime> sessionDays, {
    DateTime? now,
    bool hasSessionToday = false,
    Set<DateTime>? graceDays,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final daySet = sessionDays.map(_dateOnly).toSet();
    if (hasSessionToday) daySet.add(today);

    final graceDaySet = (graceDays ?? {}).map(_dateOnly).toSet();

    var streak = 0;
    var cursor = today;
    final missOffsets = <int>[];
    final graceOffsets = <int>[];
    const maxBack = 3660;

    for (var i = 0; i < maxBack; i++) {
      if (daySet.contains(cursor)) {
        streak++;
      } else if (graceDaySet.contains(cursor)) {
        // grace day bridges but does not increment streak
        graceOffsets.add(i);
      } else {
        // break if a miss OR a grace (which consumed the token) is within window
        final blockedByMiss  = missOffsets.any((d) => (i - d).abs() <= 6);
        final blockedByGrace = graceOffsets.any((d) => (i - d).abs() <= 6);
        if (blockedByMiss || blockedByGrace) break;
        missOffsets.add(i);
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final graceUsed = missOffsets.any((d) => d.abs() <= 6) ||
                    graceOffsets.any((d) => d.abs() <= 6);
    return StreakInfo(current: streak, graceAvailable: !graceUsed);
  }
}

class StreakInfo {
  final int current;
  final bool graceAvailable;

  const StreakInfo({required this.current, required this.graceAvailable});
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);