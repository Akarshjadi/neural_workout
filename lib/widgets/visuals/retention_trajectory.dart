import 'package:flutter/material.dart';
import '../../models/delayed_outcome.dart';
import '../../models/learning_enums.dart';
import '../../ui/theme_notebook.dart';

class RetentionTrajectoryWidget extends StatelessWidget {
  final List<DelayedOutcome> outcomes;
  final double height;

  const RetentionTrajectoryWidget({
    super.key,
    required this.outcomes,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RETENTION TRAJECTORY', style: Theme.of(context).textTheme.labelSmall),
            Text('T0 → T1 → T3 → T7 → T30', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: CustomPaint(
            painter: _TrajectoryPainter(outcomes),
            size: Size(double.infinity, height),
          ),
        ),
      ],
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  final List<DelayedOutcome> outcomes;
  _TrajectoryPainter(this.outcomes);

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    final buckets = ['T0', 'T1', 'T3', 'T7', 'T30'];
    final xs = List.generate(5, (i) => pad + (i / 4.0 * w));

    // Baseline grid & bucket labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(Offset(xs[i], pad), Offset(xs[i], pad + h), Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.1));
      tp.text = TextSpan(text: buckets[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: NotebookTheme.graphite));
      tp.layout();
      tp.paint(canvas, Offset(xs[i] - tp.width / 2, size.height - 14));
    }

    if (outcomes.isEmpty) {
      tp.text = const TextSpan(text: 'AWAITING DELAYED RETENTION SAMPLES', style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: NotebookTheme.graphite));
      tp.layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    // Connect observed outcomes
    final sorted = List<DelayedOutcome>.from(outcomes)..sort((a, b) => a.elapsed.compareTo(b.elapsed));
    final path = Path();
    bool started = false;

    for (final o in sorted) {
      final days = o.elapsed.inDays;
      int bIdx = 0;
      if (days >= 30) {
        bIdx = 4;
      } else if (days >= 7) {
        bIdx = 3;
      } else if (days >= 3) {
        bIdx = 2;
      } else if (days >= 1) {
        bIdx = 1;
      }
      
      final x = xs[bIdx];
      final y = pad + ((1.0 - (o.scorePct / 100.0).clamp(0.0, 1.0)) * h);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }

      final isRet = o.correctness == Correctness.correct || o.correctness == Correctness.partiallyCorrect;
      canvas.drawCircle(Offset(x, y), 3.0, Paint()..color = isRet ? NotebookTheme.oxblood : NotebookTheme.graphite);
    }

    canvas.drawPath(path, Paint()..color = NotebookTheme.oxblood.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) => old.outcomes != outcomes;
}
