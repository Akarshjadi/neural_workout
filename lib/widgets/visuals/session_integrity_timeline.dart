import 'package:flutter/material.dart';
import '../../models/focus_integrity.dart';
import '../../ui/theme_notebook.dart';

class SessionIntegrityTimelineWidget extends StatelessWidget {
  final FocusIntegrity? integrity;
  final double height;

  const SessionIntegrityTimelineWidget({
    super.key,
    this.integrity,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    final fi = integrity;
    final unbrokenMin = fi?.longestFocusMs != null ? (fi!.longestFocusMs! ~/ 60000) : 0;
    final interruptions = fi?.interruptions ?? 0;
    final completion = fi?.completionRatio != null ? (fi!.completionRatio! * 100).round() : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FOCUS INTEGRITY', style: Theme.of(context).textTheme.labelSmall),
            Text('LONGEST BLOCK: ${unbrokenMin}m | $interruptions BREAKS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: CustomPaint(
            painter: _TimelinePainter(fi),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('START', style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.graphite)),
            Text('COMPLETION: $completion%', style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.oxblood, fontWeight: FontWeight.bold)),
            const Text('END', style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.graphite)),
          ],
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final FocusIntegrity? integrity;
  _TimelinePainter(this.integrity);

  @override
  void paint(Canvas canvas, Size size) {
    if (integrity == null || integrity!.actualDuration.inSeconds <= 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = NotebookTheme.oxblood.withValues(alpha: 0.7));
      return;
    }

    final totalSec = integrity!.actualDuration.inSeconds.toDouble();
    final unbrokenSec = (integrity!.longestFocusMs ?? 0) / 1000.0;
    final unbrokenFrac = (unbrokenSec / (totalSec > 0 ? totalSec : 1)).clamp(0.1, 1.0);

    // Continuous retrieval block
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * unbrokenFrac, size.height), Paint()..color = NotebookTheme.oxblood.withValues(alpha: 0.7));

    // Interruption segments
    final count = integrity!.interruptions;
    if (count > 0 && unbrokenFrac < 1.0) {
      final remW = size.width * (1.0 - unbrokenFrac);
      for (int i = 0; i < count; i++) {
        final startX = size.width * unbrokenFrac + (i / count * remW);
        canvas.drawRect(Rect.fromLTWH(startX, 0, remW / count * 0.4, size.height), Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.25));
        canvas.drawRect(Rect.fromLTWH(startX + remW / count * 0.4, 0, remW / count * 0.6, size.height), Paint()..color = NotebookTheme.oxblood.withValues(alpha: 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) => old.integrity != integrity;
}

