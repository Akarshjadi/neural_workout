import 'package:flutter/material.dart';
import '../../models/learning_attempt.dart';
import '../../ui/theme_notebook.dart';

/// Item 234 — PredictionOutcomeSplit.
///
/// Splits every pretest prediction (an attempt made *before* instruction, i.e.
/// `wasPrediction`) against the outcome that followed it. The gap is the
/// prediction error that productive-failure and predictive-processing designs
/// depend on.
///
/// Deliberately reads only fields the app actually records: `confidence` is the
/// prediction (the learner's pre-answer estimate) and `scorePct` is the
/// outcome. Nothing here is fabricated — attempts without both are skipped.
class PredictionOutcomeSplit extends StatelessWidget {
  final List<LearningAttempt> attempts;
  final double height;

  const PredictionOutcomeSplit({
    super.key,
    required this.attempts,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = attempts
        .where((a) => a.confidence != null && !a.scorePct.isNaN)
        .toList();

    final meanGap = pairs.isEmpty
        ? 0.0
        : pairs.fold<double>(
                0.0, (acc, a) => acc + (a.confidence! - a.scorePct)) /
            pairs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PREDICTION / OUTCOME SPLIT',
                style: Theme.of(context).textTheme.labelSmall),
            Text(
              pairs.isEmpty
                  ? 'NO PAIRED DATA'
                  : 'MEAN GAP ${meanGap >= 0 ? '+' : ''}${meanGap.toStringAsFixed(1)} PTS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: meanGap.abs() > 20
                      ? NotebookTheme.oxblood
                      : NotebookTheme.graphite),
            ),
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
            painter: _SplitPainter(pairs),
            size: Size(double.infinity, height),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SOLID = OBSERVED OUTCOME   |   OUTLINE = PREDICTED',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 7.5, color: NotebookTheme.graphite),
        ),
      ],
    );
  }
}

class _SplitPainter extends CustomPainter {
  final List<LearningAttempt> pairs;
  _SplitPainter(this.pairs);

  @override
  void paint(Canvas canvas, Size size) {
    if (pairs.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
            text: 'NO PREDICTION/OUTCOME PAIRS RECORDED',
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

    // Most recent 40 pairs, newest on the right.
    final recent = pairs.length > 40 ? pairs.sublist(pairs.length - 40) : pairs;
    final pad = 12.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final slot = w / recent.length;

    final predicted = Paint()
      ..color = NotebookTheme.graphite.withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final observed = Paint()..color = NotebookTheme.oxblood;

    for (int i = 0; i < recent.length; i++) {
      final a = recent[i];
      final x = pad + slot * (i + 0.5);
      final predictedY = pad + (1 - (a.confidence! / 100).clamp(0.0, 1.0)) * h;
      final observedY = pad + (1 - (a.scorePct / 100).clamp(0.0, 1.0)) * h;

      // The gap itself is the prediction error.
      canvas.drawLine(
          Offset(x, predictedY),
          Offset(x, observedY),
          Paint()
            ..color = NotebookTheme.oxblood.withValues(alpha: 0.25)
            ..strokeWidth = 3.0);

      canvas.drawRect(
          Rect.fromCenter(center: Offset(x, predictedY), width: 7, height: 7),
          predicted);
      canvas.drawCircle(Offset(x, observedY), 3.0, observed);
    }
  }

  @override
  bool shouldRepaint(covariant _SplitPainter old) => old.pairs != pairs;
}
