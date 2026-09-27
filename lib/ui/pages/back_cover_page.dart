import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/plasticity_service.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class BackCoverPage extends StatelessWidget {
  const BackCoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.plasticityProfile;
    
    // Normalize speed for display
    double speedSc = 100 - ((p.speed.currentMs - 500) / 4500 * 100);
    speedSc = speedSc.clamp(0.0, 100.0);
    
    final axes = [
      _AxisData('Speed', speedSc, p.speed.isLearning),
      _AxisData('Recovery', p.recovery.index0to100, p.recovery.isLearning),
      _AxisData('Difficulty', p.difficulty.index0to100, p.difficulty.isLearning),
      _AxisData('Network', p.network.index0to100, false), // Network doesn't have isLearning
      _AxisData('Mindfulness', p.mindfulness.index0to100, p.mindfulness.isLearning),
    ];

    double sum = 0.0;
    sum += speedSc;
    sum += p.recovery.index0to100;
    sum += p.difficulty.index0to100;
    sum += p.network.index0to100;
    sum += p.mindfulness.index0to100;
    double avg = sum / 5.0;
    int brainAge = 20 + ((100.0 - avg) * 40.0 / 100.0).round();
    int ageLower = brainAge - 2;
    int ageUpper = brainAge + 2;

    String insight = "Pattern detected: Gathering context...";
    if (speedSc > 75) {
      insight = "Your recall speed improved this month (${speedSc.toStringAsFixed(0)}/100) — cholinergic adaptation is working.";
    } else if (p.difficulty.index0to100 < 30 && !p.difficulty.isLearning) {
      insight = "Your desirable difficulty index is at ${p.difficulty.index0to100.round()}/100 — you're avoiding hard material.";
    } else if (p.network.index0to100 > 60) {
      insight = "Your network density crossed 60% (${p.network.index0to100.round()}/100) — your knowledge graph is connecting.";
    } else if (p.recovery.index0to100 < 40 && !p.recovery.isLearning) {
      insight = "Your recovery proxy is low (${p.recovery.index0to100.round()}/100). Ensure adequate rest for consolidation.";
    } else if (speedSc > 0) {
      insight = "Stable cognitive processing (${speedSc.toStringAsFixed(0)}/100). Keep up the variety.";
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text('PLASTICITY PROFILE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Cognitive Age Estimate: ', style: Theme.of(context).textTheme.bodyMedium),
              Text('$ageLower–$ageUpper', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: NotebookTheme.oxblood)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('* Estimate based on your behavioral data, not a clinical measurement.', style: TextStyle(fontSize: 10, color: NotebookTheme.graphite, fontFamily: 'monospace')),
          const SizedBox(height: 16),
          Expanded(
            flex: 3,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final axesStrings = axes.map((a) => '${a.label}: ${a.value.round()} out of 100').join(', ');
                return Semantics(
                  label: 'Radar chart displaying 5 plasticity metrics: $axesStrings',
                  child: CustomPaint(
                    painter: _RadarPainter(axes, growthFactor: value),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: NotebookTheme.oxblood.withValues(alpha: 0.3)),
              color: NotebookTheme.oxblood.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              insight,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NotebookTheme.oxblood),
            ),
          ),
          const SizedBox(height: 32),
          Text('TREND STREAM (30D)', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Semantics(
              label: '30-day Trend Stream graph of plasticity metrics',
              child: CustomPaint(
                painter: _TrendStreamPainter(state),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _AxisData {
  final String label;
  final double value; // 0..100
  final bool isLearning;
  _AxisData(this.label, this.value, this.isLearning);
}

class _RadarPainter extends CustomPainter {
  final List<_AxisData> axes;
  final double growthFactor;
  _RadarPainter(this.axes, {this.growthFactor = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2.5;

    final bgPaint = Paint()
      ..color = NotebookTheme.graphite.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final polygonPaint = Paint()
      ..color = NotebookTheme.oxblood.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
      
    final polygonStrokePaint = Paint()
      ..color = NotebookTheme.oxblood
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw grid
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxRadius * (ring / 4);
      final path = Path();
      for (int i = 0; i < axes.length; i++) {
        final angle = (i * 2 * math.pi / axes.length) - (math.pi / 2);
        final p = Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
        if (i == 0) path.moveTo(p.dx, p.dy);
        else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, bgPaint);
    }
    
    // Draw axes & labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < axes.length; i++) {
      final angle = (i * 2 * math.pi / axes.length) - (math.pi / 2);
      final p = Offset(center.dx + math.cos(angle) * maxRadius, center.dy + math.sin(angle) * maxRadius);
      canvas.drawLine(center, p, bgPaint);
      
      textPainter.text = TextSpan(
        text: axes[i].label + (axes[i].isLearning ? ' (l)' : ''),
        style: const TextStyle(fontSize: 10, color: NotebookTheme.graphite, fontFamily: 'monospace'),
      );
      textPainter.layout();
      
      final labelOffset = Offset(
        p.dx + (math.cos(angle) * 15) - (textPainter.width / 2),
        p.dy + (math.sin(angle) * 15) - (textPainter.height / 2),
      );
      textPainter.paint(canvas, labelOffset);
    }

    // Draw data polygon
    final path = Path();
    for (int i = 0; i < axes.length; i++) {
      final angle = (i * 2 * math.pi / axes.length) - (math.pi / 2);
      // If learning, we cap visualization max radius or dim it. For now, draw actual but dimmed.
      double val = axes[i].value.isNaN ? 0.0 : axes[i].value;
      final r = maxRadius * (val / 100.0).clamp(0.0, 1.0) * growthFactor;
      final p = Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
      if (i == 0) path.moveTo(p.dx, p.dy);
      else path.lineTo(p.dx, p.dy);
    }
    path.close();
    
    canvas.drawPath(path, polygonPaint);
    canvas.drawPath(path, polygonStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.growthFactor != growthFactor || old.axes != axes;
}



class _TrendStreamPainter extends CustomPainter {
  final AppState state;
  _TrendStreamPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    // We compute 30 daily profiles
    final now = DateTime.now();
    final svc = PlasticityService();
    final linkCounts = state.db.linkCountsByNote();
    final reviews = state.db.reviewHistory();

    final List<List<double>> layers = [[], [], [], [], []]; // Speed, Rec, Diff, Net, Mind

    for (int d = 30; d >= 0; d--) {
      final date = now.subtract(Duration(days: d));
      final p = svc.profile(
        blurts: state.blurtScores,
        checkins: state.checkins,
        reviews: reviews,
        notes: state.notes,
        linkCounts: linkCounts,
        sessions: state.sessions,
        now: date,
      );

      double speedSc = (100 - ((p.speed.currentMs - 500) / 4500 * 100)).clamp(0.0, 100.0).toDouble();
      double l1 = (speedSc * 0.20);
      double l2 = l1 + (p.recovery.index0to100 * 0.20);
      double l3 = l2 + (p.difficulty.index0to100 * 0.25);
      double l4 = l3 + (p.network.index0to100 * 0.25);
      double l5 = l4 + (p.mindfulness.index0to100 * 0.10); // max 100
      
      layers[0].add(l1);
      layers[1].add(l2);
      layers[2].add(l3);
      layers[3].add(l4);
      layers[4].add(l5);
    } // at this point we have 31 points per layer

    final colors = [
      NotebookTheme.oxblood.withValues(alpha: 0.9), // Speed
      NotebookTheme.oxblood.withValues(alpha: 0.7), // Rec
      NotebookTheme.oxblood.withValues(alpha: 0.5), // Diff
      NotebookTheme.oxblood.withValues(alpha: 0.3), // Net
      NotebookTheme.oxblood.withValues(alpha: 0.1), // Mind
    ];

    for (int l = 4; l >= 0; l--) {
      final path = Path();
      final points = layers[l];
      path.moveTo(0, size.height);
      for (int i = 0; i < points.length; i++) {
        final x = (i / (points.length - 1)) * size.width;
        final y = size.height - (points[i] / 100.0 * size.height);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, Paint()..color = colors[l]..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendStreamPainter old) => true; // naive repaint logic
}