import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  int _calculateXP(AppState state) {
    int total = 0;
    total += state.blurtScores.length * 10;
    final reviewSessions = state.db.reviewHistory().length;
    total += reviewSessions * 5;
    for (var b in state.blurtScores) {
      if (b.scorePct >= 0.70 && b.scorePct <= 0.85) total += 5;
    }
    return total;
  }

  int _getLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 1000) return 4;
    return 5 + ((xp - 1000) ~/ 1000);
  }

  int _getXpForLevelStart(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 250;
    if (level == 4) return 500;
    return 1000 + ((level - 5) * 1000);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final resumable = state.activeSession != null;
    final dueCount = state.dueNotesList.length;
    final reserve = state.plasticityProfile.recovery;

    String heading = 'Rest.';
    String buttonText = '';

    if (reserve.index0to100 < 30) {
      heading = 'Rest and consolidate.';
      buttonText = resumable ? 'Resume (Optional)' : (dueCount > 0 ? 'Review (Optional)' : 'Practice (Optional)');
    } else if (resumable) {
      heading = 'Continue your blurt.';
      buttonText = 'Resume';
    } else if (dueCount > 0) {
      heading = 'Review $dueCount cards.';
      buttonText = 'Review cards';
    } else {
      heading = 'Write a blurt.';
      buttonText = 'Start practice';
    }

    // Plasticity Pulse
    final diff = state.plasticityProfile.difficulty;
    final stringStatus = reserve.index0to100 < 40 ? 'Consolidate today' : 'Push today';

    final xp = _calculateXP(state);
    final level = _getLevel(xp);
    final currentLevelXp = _getXpForLevelStart(level);
    final nextLevelXp = _getXpForLevelStart(level + 1);
    final progress = (xp - currentLevelXp) / (nextLevelXp - currentLevelXp).clamp(1, double.infinity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TODAY\'S PRACTICE', style: Theme.of(context).textTheme.labelSmall),
              _CognitiveWeatherWidget(reserveVal: reserve.index0to100),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
          // Sub-widget Plasticity Pulse
          Text('PLASTICITY PULSE', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _PulsePainter(diff.index0to100 / 100.0),
            ),
          ),
          const SizedBox(height: 8),
          Text(stringStatus, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
          const Spacer(),
          Text(
            heading,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: NotebookTheme.oxblood,
            ),
          ),
          const SizedBox(height: 48),
          if (buttonText.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                },
                child: Text(buttonText),
              ),
            ),
          const Spacer(),
          // XP Ladder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LVL $level', style: const TextStyle(color: NotebookTheme.oxblood, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              Text('$xp / $nextLevelXp XP', style: const TextStyle(color: NotebookTheme.graphite, fontSize: 12, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: NotebookTheme.graphite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [NotebookTheme.oxblood.withValues(alpha: 0.5), NotebookTheme.oxblood],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('XP is earned via effortful retrieval.', style: TextStyle(fontSize: 10, color: NotebookTheme.graphite)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double difficulty; // 0.0 to 1.0 mapping from desirableDifficulty 0-100
  _PulsePainter(this.difficulty);

  @override
  void paint(Canvas canvas, Size size) {
    if (difficulty <= 0) return;
    final paint = Paint()
      ..color = NotebookTheme.oxblood.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final points = 100;

    final freq = 1.0 + (difficulty * 4.0);
    final maxAmp = size.height / 2.0;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * size.width;
      final y = (size.height / 2) + math.sin(t * math.pi * 2 * freq) * maxAmp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.difficulty != difficulty;
}

class _CognitiveWeatherWidget extends StatelessWidget {
  final double reserveVal;
  const _CognitiveWeatherWidget({required this.reserveVal});

  @override
  Widget build(BuildContext context) {
    String label = 'Clear';
    Color color = NotebookTheme.paper;
    Color textColor = NotebookTheme.graphite;
    
    if (reserveVal < 30) {
      label = 'Storm';
      color = NotebookTheme.oxblood;
      textColor = NotebookTheme.paper;
    } else if (reserveVal < 60) {
      label = 'Overcast';
      color = NotebookTheme.graphite;
      textColor = NotebookTheme.paper;
    } else {
      label = 'Clear';
      color = const Color(0xFFF9F6E8); // soft yellow tint
      textColor = NotebookTheme.graphite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
