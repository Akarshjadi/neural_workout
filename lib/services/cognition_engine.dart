import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../models/blurt_score.dart';
import '../models/break_record.dart';
import '../models/note.dart';
import '../models/session.dart';

/// A single day's value for one cognitive index (0..100).
class DailyMetric {
  final DateTime date;
  final double value;
  const DailyMetric(this.date, this.value);
  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 'v': value};
}

/// A forecast produced by damped linear regression on the smoothed series.
///
/// "Damped" means the slope is multiplied by 0.92^i at step i, so we don't
/// naively extrapolate a 3-day uptick into a 14-day vertical line. This is
/// the honest, defensible choice — real cognitive trends regress to the mean.
class MetricForecast {
  final List<DailyMetric> history;
  final List<DailyMetric> predicted;
  final double slopePerDay;
  final double residualStd;
  final DateTime horizonEnd;
  final double predictedEnd;

  const MetricForecast({
    required this.history,
    required this.predicted,
    required this.slopePerDay,
    required this.residualStd,
    required this.horizonEnd,
    required this.predictedEnd,
  });

  double get currentValue => history.isEmpty ? 0 : history.last.value;

  double get delta7d {
    if (history.length < 8) return 0;
    return history.last.value - history[history.length - 8].value;
  }

  double get horizonDelta =>
      history.isEmpty || predicted.isEmpty ? 0 : predictedEnd - currentValue;

  /// Plain-language direction label. No hype.
  String get trend {
    if (slopePerDay.abs() < 0.08) return 'steady';
    return slopePerDay > 0 ? 'rising' : 'falling';
  }

  /// 80% confidence interval half-width at the horizon end.
  double get band80 => 1.28 * residualStd * math.sqrt(predicted.length);

  bool get hasForecast => predicted.isNotEmpty;
}

/// A decomposed factor of a cognitive score. `weight` sums to 1 across the
/// factors for one day; `contribution` is `weight * value * 100`.
class CognitiveFactor {
  final String name;
  final double weight;
  final double value01; // raw 0..1 input for the day
  final String detail; // human sentence, no jargon

  const CognitiveFactor({
    required this.name,
    required this.weight,
    required this.value01,
    required this.detail,
  });

  double get contribution => weight * value01 * 100;
}

class CognitionEngine {
  final DateTime today;
  final int historyDays;
  final int forecastDays;

  const CognitionEngine({
    required this.today,
    this.historyDays = 30,
    this.forecastDays = 14,
  });

  // ── Public API ───────────────────────────────────────────────────────────
  //
  // The three forecasts below are deprecated as a *surface* (no fourth composite
  // score is shown). The math is unchanged and remains the basis for
  // [neuroFactorsFor], which is what the UI actually renders.

  /// Neuroplasticity proxy: novelty load + desirable difficulty + retrieval
  /// practice + consistency + recovery. All five are real levers research
  /// links to synapse remodelling (LTP, BDNF, sleep consolidation).
  @Deprecated('Forecast total not surfaced — use the factor decomposition to avoid a fourth composite score')
  MetricForecast neuroForecast({
    required List<Note> notes,
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
    required List<BreakRecord> breaks,
  }) {
    final raw = List<DailyMetric>.generate(historyDays, (i) {
      final day = _dateOnly(
        today.subtract(Duration(days: historyDays - 1 - i)),
      );
      return DailyMetric(
        day,
        _neuroForDay(
          day,
          notes: notes,
          sessions: sessions,
          blurts: blurts,
          reviews: reviews,
          breaks: breaks,
        ),
      );
    });
    return _forecast(raw);
  }

  /// Focus proxy: depth (uninterrupted time), retrieval fluency (recall
  /// speed), step completion, interleave fit. Interleaving helps *learning*
  /// but too much of it fragments focus, so we target ~3 interleaves/session.
  @Deprecated('Forecast total not surfaced — use the factor decomposition to avoid a fourth composite score')
  MetricForecast focusForecast({
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final raw = List<DailyMetric>.generate(historyDays, (i) {
      final day = _dateOnly(
        today.subtract(Duration(days: historyDays - 1 - i)),
      );
      return DailyMetric(
        day,
        _focusForDay(day, sessions: sessions, blurts: blurts, reviews: reviews),
      );
    });
    return _forecast(raw);
  }

  /// Memory-power proxy: mean retrievability on review days, stability
  /// proxy from blurt depth, and accuracy. Uses FSRS ratings as the source
  /// of truth for retrievability — no self-report.
  @Deprecated('Forecast total not surfaced — use the factor decomposition to avoid a fourth composite score')
  MetricForecast memoryForecast({
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final raw = <DailyMetric>[];
    double? carry;
    for (var i = 0; i < historyDays; i++) {
      final day = _dateOnly(
        today.subtract(Duration(days: historyDays - 1 - i)),
      );
      final v = _memoryForDay(day, blurts: blurts, reviews: reviews);
      if (v == null) {
        // No data — carry forward with 0.5% daily decay (honest memory decay).
        carry = carry == null ? 0 : (carry * 0.995).clamp(0, 100);
        raw.add(DailyMetric(day, carry));
      } else {
        carry = v;
        raw.add(DailyMetric(day, v));
      }
    }
    return _forecast(raw);
  }

  /// Ranked contributors for today's neuro score (top 3 by contribution).
  List<CognitiveFactor> neuroFactorsFor({
    required List<Note> notes,
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
    required List<BreakRecord> breaks,
  }) {
    return _neuroFactors(
      _dateOnly(today),
      notes: notes,
      sessions: sessions,
      blurts: blurts,
      reviews: reviews,
      breaks: breaks,
    );
  }

  List<CognitiveFactor> focusFactorsFor({
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    return _focusFactors(
      _dateOnly(today),
      sessions: sessions,
      blurts: blurts,
      reviews: reviews,
    );
  }

  List<CognitiveFactor> memoryFactorsFor({
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    return _memoryFactors(_dateOnly(today), blurts: blurts, reviews: reviews);
  }

  // ── Day-level computations ───────────────────────────────────────────────

  double _neuroForDay(
    DateTime day, {
    required List<Note> notes,
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
    required List<BreakRecord> breaks,
  }) {
    final factors = _neuroFactors(
      day,
      notes: notes,
      sessions: sessions,
      blurts: blurts,
      reviews: reviews,
      breaks: breaks,
    );
    final total = factors.fold<double>(0, (a, f) => a + f.contribution);
    return total.clamp(0, 100);
  }

  List<CognitiveFactor> _neuroFactors(
    DateTime day, {
    required List<Note> notes,
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
    required List<BreakRecord> breaks,
  }) {
    // Novelty load: new notes this day, saturating at 3.
    final notesToday = notes.where((n) => _sameDay(n.createdAt, day)).length;
    final novelty = (notesToday / 3).clamp(0.0, 1.0);

    // Desirable difficulty: fraction of reviews this day rated again/hard.
    final revs = reviews
        .where((r) => _sameDay(_parse(r['date']), day))
        .toList();
    final hardCount = revs
        .where((r) => r['rating'] == 'again' || r['rating'] == 'hard')
        .length;
    final difficulty = revs.isEmpty
        ? 0.0
        : (hardCount / revs.length).clamp(0.0, 1.0);

    // Retrieval practice: blurts x quality.
    final bs = blurts.where((b) => _sameDay(b.date, day)).toList();
    final retrievalQuality = bs.isEmpty
        ? 0.0
        : (bs.map((b) => b.scorePct).reduce((a, b) => a + b) / bs.length / 100)
              .clamp(0.0, 1.0);
    final retrieval = bs.isEmpty
        ? 0.0
        : ((bs.length / 3).clamp(0.0, 1.0) * 0.5 + retrievalQuality * 0.5)
              .clamp(0.0, 1.0);

    // Consistency: 1 − normalised stddev of last-7-day minutes.
    final weekMinutes = List<int>.generate(7, (i) {
      final d = day.subtract(Duration(days: i));
      return sessions
          .where((s) => _sameDay(s.date, d))
          .fold<int>(0, (a, s) => a + s.duration.inMinutes);
    });
    final mean = weekMinutes.reduce((a, b) => a + b) / 7;
    final variance =
        weekMinutes.map((m) => math.pow(m - mean, 2)).reduce((a, b) => a + b) /
        7;
    final std = math.sqrt(variance);
    final consistency = mean == 0 ? 0.0 : (1 - (std / 20).clamp(0.0, 1.0));

    // Recovery: breaks in the last 7 days, saturating at 7.
    final weekBreaks = breaks
        .where(
          (b) =>
              !b.startedAt.isBefore(day.subtract(const Duration(days: 7))) &&
              !b.startedAt.isAfter(day),
        )
        .length;
    final recovery = (weekBreaks / 7).clamp(0.0, 1.0);

    return [
      CognitiveFactor(
        name: 'Novelty',
        weight: 0.30,
        value01: novelty,
        detail: '$notesToday new note${notesToday == 1 ? '' : 's'} today',
      ),
      CognitiveFactor(
        name: 'Desirable difficulty',
        weight: 0.20,
        value01: difficulty,
        detail: revs.isEmpty
            ? 'no reviews today'
            : '$hardCount of ${revs.length} reviews were hard',
      ),
      CognitiveFactor(
        name: 'Retrieval',
        weight: 0.20,
        value01: retrieval,
        detail: bs.isEmpty
            ? 'no blurts today'
            : '${bs.length} blurt${bs.length == 1 ? '' : 's'} · avg ${(retrievalQuality * 100).round()}%',
      ),
      CognitiveFactor(
        name: 'Consistency',
        weight: 0.15,
        value01: consistency,
        detail: '7-day minutes: mean ${mean.round()}, σ ${std.round()}',
      ),
      CognitiveFactor(
        name: 'Recovery',
        weight: 0.15,
        value01: recovery,
        detail: '$weekBreaks break${weekBreaks == 1 ? '' : 's'} this week',
      ),
    ];
  }

  double _focusForDay(
    DateTime day, {
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final f = _focusFactors(
      day,
      sessions: sessions,
      blurts: blurts,
      reviews: reviews,
    );
    return f.fold<double>(0, (a, x) => a + x.contribution).clamp(0, 100);
  }

  List<CognitiveFactor> _focusFactors(
    DateTime day, {
    required List<Session> sessions,
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final ss = sessions.where((s) => _sameDay(s.date, day)).toList();
    final avgDuration = ss.isEmpty
        ? 0.0
        : ss.map((s) => s.duration.inMinutes).reduce((a, b) => a + b) /
              ss.length;
    final depth = (avgDuration / 25).clamp(0.0, 1.0);

    final bs = blurts
        .where((b) => _sameDay(b.date, day) && b.recallSpeedMs != null)
        .toList();
    double fluency = 0;
    if (bs.isNotEmpty) {
      final avgMs =
          bs.map((b) => b.recallSpeedMs!.toDouble()).reduce((a, b) => a + b) /
          bs.length;
      // 15 s = fluent (1.0), 90 s+ = laboured (0.0).
      fluency = (1 - ((avgMs - 15000) / 75000).clamp(0.0, 1.0));
    }

    final completion = ss.isEmpty
        ? 0.0
        : ss.map((s) => s.stepsCompleted / 8).reduce((a, b) => a + b) /
              ss.length;

    final revs = reviews
        .where((r) => _sameDay(_parse(r['date']), day))
        .toList();
    final interleaved = revs.where((r) => r['was_interleaved'] == 1).length;
    // Ideal: ~3 interleaves/day. Too few or too many both reduce focus.
    final interleaveFit = revs.isEmpty
        ? 0.0
        : (1 - ((interleaved - 3).abs() / 5).clamp(0.0, 1.0));

    return [
      CognitiveFactor(
        name: 'Session depth',
        weight: 0.35,
        value01: depth,
        detail: 'avg session ${avgDuration.round()} min',
      ),
      CognitiveFactor(
        name: 'Retrieval fluency',
        weight: 0.20,
        value01: fluency,
        detail: bs.isEmpty
            ? 'no timed blurts'
            : 'avg recall ${(bs.map((b) => b.recallSpeedMs!).reduce((a, b) => a + b) / bs.length / 1000).round()} s',
      ),
      CognitiveFactor(
        name: 'Step completion',
        weight: 0.25,
        value01: completion,
        detail: '${(completion * 8).toStringAsFixed(1)}/8 steps avg',
      ),
      CognitiveFactor(
        name: 'Interleave fit',
        weight: 0.20,
        value01: interleaveFit,
        detail: '$interleaved interleaved reviews (target ~3)',
      ),
    ];
  }

  /// Returns null when there is no data for the day (caller carries forward).
  double? _memoryForDay(
    DateTime day, {
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final bs = blurts.where((b) => _sameDay(b.date, day)).toList();
    final revs = reviews
        .where((r) => _sameDay(_parse(r['date']), day))
        .toList();
    if (bs.isEmpty && revs.isEmpty) return null;

    // Retrievability from FSRS rating bands (not self-report).
    double retrievability = 0;
    if (revs.isNotEmpty) {
      retrievability =
          revs
              .map((r) {
                switch (r['rating']) {
                  case 'again':
                    return 0.15;
                  case 'hard':
                    return 0.45;
                  case 'good':
                    return 0.80;
                  case 'easy':
                    return 0.97;
                  default:
                    return 0.50;
                }
              })
              .reduce((a, b) => a + b) /
          revs.length;
    } else {
      retrievability =
          bs.map((b) => b.scorePct).reduce((a, b) => a + b) / bs.length / 100;
    }

    // Stability proxy: fraction of blurts with depth ≥ 75.
    final stability = bs.isEmpty
        ? retrievability
        : (bs.where((b) => (b.depthScore ?? b.scorePct) >= 75).length /
                  bs.length)
              .clamp(0.0, 1.0);

    final accuracy = bs.isEmpty
        ? retrievability * 100
        : bs.map((b) => b.scorePct).reduce((a, b) => a + b) / bs.length;

    return (100 *
            (0.45 * retrievability + 0.25 * stability + 0.30 * accuracy / 100))
        .clamp(0, 100);
  }

  List<CognitiveFactor> _memoryFactors(
    DateTime day, {
    required List<BlurtScore> blurts,
    required List<Map<String, dynamic>> reviews,
  }) {
    final bs = blurts.where((b) => _sameDay(b.date, day)).toList();
    final revs = reviews
        .where((r) => _sameDay(_parse(r['date']), day))
        .toList();

    double retrievability = 0;
    if (revs.isNotEmpty) {
      retrievability =
          revs
              .map((r) {
                switch (r['rating']) {
                  case 'again':
                    return 0.15;
                  case 'hard':
                    return 0.45;
                  case 'good':
                    return 0.80;
                  case 'easy':
                    return 0.97;
                  default:
                    return 0.50;
                }
              })
              .reduce((a, b) => a + b) /
          revs.length;
    } else if (bs.isNotEmpty) {
      retrievability =
          bs.map((b) => b.scorePct).reduce((a, b) => a + b) / bs.length / 100;
    }

    final stability = bs.isEmpty
        ? retrievability
        : (bs.where((b) => (b.depthScore ?? b.scorePct) >= 75).length /
                  bs.length)
              .clamp(0.0, 1.0);

    final accuracy = bs.isEmpty
        ? retrievability * 100
        : bs.map((b) => b.scorePct).reduce((a, b) => a + b) / bs.length;

    return [
      CognitiveFactor(
        name: 'Retrievability',
        weight: 0.45,
        value01: retrievability,
        detail: revs.isEmpty
            ? 'no reviews — inferred from blurts'
            : '${revs.length} FSRS review${revs.length == 1 ? '' : 's'}',
      ),
      CognitiveFactor(
        name: 'Depth stability',
        weight: 0.25,
        value01: stability,
        detail: '${(stability * 100).round()}% of blurts scored deep',
      ),
      CognitiveFactor(
        name: 'Recall accuracy',
        weight: 0.30,
        value01: (accuracy / 100).clamp(0.0, 1.0),
        detail: 'avg blurt ${accuracy.round()}%',
      ),
    ];
  }

  // ── Forecast maths ───────────────────────────────────────────────────────

  MetricForecast _forecast(List<DailyMetric> raw) {
    if (raw.length < 3) {
      return MetricForecast(
        history: raw,
        predicted: const [],
        slopePerDay: 0,
        residualStd: 0,
        horizonEnd: raw.isEmpty ? today : raw.last.date,
        predictedEnd: raw.isEmpty ? 0 : raw.last.value,
      );
    }

    final smoothed = _ewma(raw.map((p) => p.value).toList(), 0.35);

    // Ordinary least squares on the smoothed series.
    final n = smoothed.length;
    final mx = (n - 1) / 2;
    final my = smoothed.reduce((a, b) => a + b) / n;
    double num = 0, den = 0;
    for (var i = 0; i < n; i++) {
      num += (i - mx) * (smoothed[i] - my);
      den += (i - mx) * (i - mx);
    }
    final slope = den == 0 ? 0.0 : num / den;
    final intercept = my - slope * mx;
    double ss = 0;
    for (var i = 0; i < n; i++) {
      final r = raw[i].value - (intercept + slope * i);
      ss += r * r;
    }
    final residual = n > 2 ? math.sqrt(ss / (n - 2)) : 0.0;

    // Damped extrapolation: slope decays by 0.92^i, so a recent up-tick
    // fades into the mean instead of rocketing off the chart.
    final predicted = <DailyMetric>[];
    var cursor = smoothed.last;
    for (var i = 1; i <= forecastDays; i++) {
      cursor += slope * math.pow(0.92, i);
      predicted.add(
        DailyMetric(
          raw.last.date.add(Duration(days: i)),
          cursor.clamp(0.0, 100.0),
        ),
      );
    }

    return MetricForecast(
      history: raw,
      predicted: predicted,
      slopePerDay: slope,
      residualStd: residual,
      horizonEnd: predicted.last.date,
      predictedEnd: predicted.last.value,
    );
  }

  List<double> _ewma(List<double> xs, double alpha) {
    final out = <double>[];
    double? prev;
    for (final x in xs) {
      prev = prev == null ? x : alpha * x + (1 - alpha) * prev;
      out.add(prev);
    }
    return out;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  static DateTime? _parse(dynamic iso) {
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) debugPrint('Dropping malformed row with date: $iso');
      return parsed;
    }
    return null;
  }
}
