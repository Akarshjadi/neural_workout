import 'package:flutter/material.dart';
import '../../models/learning_attempt.dart';
import '../../ui/theme_notebook.dart';

/// Item 241 — RecoveryCurve, and item 140 — Recovery measurement.
///
/// Plots retrieval accuracy by minutes-since-session-start. The shape answers
/// the only question the focus system actually cares about: after a break or an
/// interruption, how long until performance returns to its in-session baseline?
///
/// Observational only. There is no sensor here — every point is a real attempt.
class RecoveryCurve extends StatelessWidget {
  final List<LearningAttempt> attempts;
  final double height;

  const RecoveryCurve({
    super.key,
    required this.attempts,
    this.height = 140,
  });

  /// Buckets attempts into 5-minute slots from their session start and returns
  /// the mean score per slot. Sessions with one attempt are ignored because a
  /// curve needs at least a before and an after.
  static List<({int minute, double score, int n})> buckets(
      List<LearningAttempt> attempts) {
    final bySession = <int, List<LearningAttempt>>{};
    for (final a in attempts) {
      final sid = a.sessionId;
      if (sid == null || a.scorePct.isNaN) continue;
      bySession.putIfAbsent(sid, () => []).add(a);
    }

    final sums = <int, double>{};
    final counts = <int, int>{};
    for (final group in bySession.values) {
      if (group.length < 2) continue;
      group.sort((x, y) => x.timestamp.compareTo(y.timestamp));
      final start = group.first.timestamp;
      for (final a in group) {
        final minute = a.timestamp.difference(start).inMinutes;
        final slot = (minute ~/ 5) * 5;
        sums[slot] = (sums[slot] ?? 0) + a.scorePct;
        counts[slot] = (counts[slot] ?? 0) + 1;
      }
    }

    final slots = sums.keys.toList()..sort();
    return [
      for (final s in slots)
        (minute: s, score: sums[s]! / counts[s]!, n: counts[s]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = buckets(attempts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECOVERY CURVE', style: Theme.of(context).textTheme.labelSmall),
            Text('ACCURACY BY ELAPSED MINUTE',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            border:
                Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: CustomPaint(
            painter: _RecoveryPainter(data),
            size: Size(double.infinity, height),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.isEmpty
              ? 'NOT ENOUGH MULTI-ATTEMPT SESSIONS'
              : '${data.length} 5-MIN BINS FROM OBSERVED ATTEMPTS',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 7.5, color: NotebookTheme.graphite),
        ),
      ],
    );
  }
}

class _RecoveryPainter extends CustomPainter {
  final List<({int minute, double score, int n})> data;
  _RecoveryPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 16.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    // Grid at 0/50/100.
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = pad + frac * h;
      canvas.drawLine(
        Offset(pad, y),
        Offset(pad + w, y),
        Paint()
          ..color = NotebookTheme.graphite.withValues(alpha: 0.12)
          ..strokeWidth = 1.0,
      );
    }

    if (data.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
            text: 'NO RECOVERY DATA RECORDED',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: NotebookTheme.graphite)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    final maxMinute = data.last.minute == 0 ? 1 : data.last.minute;
    Offset pointFor(({int minute, double score, int n}) d) => Offset(
          pad + (d.minute / maxMinute) * w,
          pad + (1 - (d.score / 100).clamp(0.0, 1.0)) * h,
        );

    final path = Path()..moveTo(pointFor(data.first).dx, pointFor(data.first).dy);
    for (final d in data.skip(1)) {
      final p = pointFor(d);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = NotebookTheme.oxblood
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    for (final d in data) {
      canvas.drawCircle(pointFor(d), 2.5 + (d.n.clamp(0, 5) * 0.4),
          Paint()..color = NotebookTheme.oxblood);
    }
  }

  @override
  bool shouldRepaint(covariant _RecoveryPainter old) => old.data != data;
}
