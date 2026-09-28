import 'package:flutter/material.dart';
import '../../models/learning_attempt.dart';
import '../../services/context_focus_service.dart';
import '../../ui/theme_notebook.dart';
import 'visual_semantics.dart';

/// Renders empirical 24-hour circadian performance distribution.
class CircadianPerformanceCard extends StatelessWidget {
  final List<LearningAttempt> attempts;
  final double height;

  const CircadianPerformanceCard({
    super.key,
    required this.attempts,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    const service = ContextFocusService();
    final curve = service.circadianCurve(attempts: attempts);
    final measuredHours = curve.where((b) => b.sampleSize > 0).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NotebookTheme.paper,
        border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CIRCADIAN PERFORMANCE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5),
              ),
              const Text(
                '24H DISTRIBUTION',
                style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: NotebookTheme.oxblood),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height - 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _CircadianBarsPainter(curve),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$measuredHours measured hours · observational, not causal',
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 8.5, color: NotebookTheme.graphite, fontStyle: FontStyle.italic),
              ),
              const Text(
                '0h ─── 12h ─── 23h',
                style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.graphite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircadianBarsPainter extends CustomPainter {
  final List<({int hour, double meanScore, int sampleSize})> curve;

  _CircadianBarsPainter(this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    if (curve.isEmpty) return;

    final solidPaint = Paint()
      ..color = NotebookTheme.oxblood
      ..style = PaintingStyle.fill;

    final dashedPaint = VisualSemantics.estimatedPaint(
      color: NotebookTheme.graphite.withValues(alpha: 0.3),
      width: 1.0,
    );

    final slotWidth = size.width / 24.0;
    final barWidth = (slotWidth * 0.65).clamp(2.0, 12.0);

    for (int h = 0; h < 24; h++) {
      final bin = curve[h];
      final cx = (h + 0.5) * slotWidth;

      if (bin.sampleSize == 0) {
        // Faint dashed vertical baseline
        VisualSemantics.drawDashedLine(
          canvas,
          Offset(cx, size.height),
          Offset(cx, size.height * 0.5),
          dashedPaint,
          dashWidth: 2.0,
          dashSpace: 2.0,
        );
      } else {
        // Solid bar with height proportional to meanScore (0..100)
        final barHeight = (bin.meanScore / 100.0 * size.height).clamp(4.0, size.height);
        final rect = Rect.fromCenter(
          center: Offset(cx, size.height - (barHeight / 2)),
          width: barWidth,
          height: barHeight,
        );
        canvas.drawRect(rect, solidPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircadianBarsPainter old) => old.curve != curve;
}
