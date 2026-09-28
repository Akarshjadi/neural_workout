import 'package:flutter/material.dart';
import '../../models/learning_attempt.dart';
import '../../ui/theme_notebook.dart';

class CalibrationField extends StatelessWidget {
  final List<LearningAttempt> attempts;
  final double height;

  const CalibrationField({
    super.key,
    required this.attempts,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final valid = attempts.where((a) => a.confidence != null && !a.scorePct.isNaN).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CALIBRATION FIELD', style: Theme.of(context).textTheme.labelSmall),
            Text('CONFIDENCE vs OUTCOME', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
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
            painter: _CalibPainter(valid),
            size: Size(double.infinity, height),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('UNDERCONFIDENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 7.5)),
            Text('CALIBRATED (DIAGONAL)', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 7.5, color: NotebookTheme.oxblood)),
            Text('OVERCONFIDENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 7.5)),
          ],
        ),
      ],
    );
  }
}

class _CalibPainter extends CustomPainter {
  final List<LearningAttempt> attempts;
  _CalibPainter(this.attempts);

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 16.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    final diagPaint = Paint()
      ..color = NotebookTheme.oxblood.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(pad, size.height - pad), Offset(pad + w, pad), diagPaint);

    final gridPaint = Paint()
      ..color = NotebookTheme.graphite.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(pad, pad, w, h), gridPaint);

    if (attempts.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: 'NO CALIBRATION DATA RECORDED', style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: NotebookTheme.graphite)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }

    for (final a in attempts) {
      final conf = (a.confidence! / 100.0).clamp(0.0, 1.0);
      final score = (a.scorePct / 100.0).clamp(0.0, 1.0);
      final x = pad + (score * w);
      final y = pad + ((1.0 - conf) * h);
      final isOver = conf > (score + 0.15);
      final p = Paint()
        ..color = isOver ? NotebookTheme.oxblood : NotebookTheme.ink.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2.5, p);
    }
  }

  @override
  bool shouldRepaint(covariant _CalibPainter old) => old.attempts != attempts;
}
