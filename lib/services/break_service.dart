import '../models/break_record.dart';

class BreakStatus {
  final int microToday;
  final int microTarget;
  final bool microDue;
  final int mesoThisWeek;
  final int mesoTarget;
  final bool mesoDue;
  final int macroThisMonth;
  final int macroTarget;
  final bool macroDue;

  const BreakStatus({
    required this.microToday,
    required this.microTarget,
    required this.microDue,
    required this.mesoThisWeek,
    required this.mesoTarget,
    required this.mesoDue,
    required this.macroThisMonth,
    required this.macroTarget,
    required this.macroDue,
  });
}

class BreakService {
  BreakStatus computeStatus({
    required List<BreakRecord> records,
    required DateTime now,
    int microTarget = 2,
    int mesoTarget = 1,
    int macroTarget = 1,
  }) {
    int microToday = 0;
    int mesoThisWeek = 0;
    int macroThisMonth = 0;

    for (final r in records) {
      if (!r.completed) continue;
      
      if (r.tier == BreakTier.micro && r.startedAt.year == now.year && r.startedAt.month == now.month && r.startedAt.day == now.day) {
        microToday++;
      } else if (r.tier == BreakTier.meso && _isSameWeek(r.startedAt, now)) {
        mesoThisWeek++;
      } else if (r.tier == BreakTier.macroMonthly && r.startedAt.year == now.year && r.startedAt.month == now.month) {
        macroThisMonth++;
      }
    }

    return BreakStatus(
      microToday: microToday,
      microTarget: microTarget,
      microDue: microToday < microTarget,
      mesoThisWeek: mesoThisWeek,
      mesoTarget: mesoTarget,
      mesoDue: mesoThisWeek < mesoTarget,
      macroThisMonth: macroThisMonth,
      macroTarget: macroTarget,
      macroDue: macroThisMonth < macroTarget,
    );
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final aMonday = DateTime(a.year, a.month, a.day).subtract(Duration(days: a.weekday - 1));
    final bMonday = DateTime(b.year, b.month, b.day).subtract(Duration(days: b.weekday - 1));
    return aMonday == bMonday;
  }
}
