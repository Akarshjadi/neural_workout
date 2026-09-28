import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final resumable = state.activeSession != null;
    final dueCount = state.dueNotesList.length;
    final reserve = state.plasticityProfile.recovery;
    final diff = state.plasticityProfile.difficulty;

    String heading = 'Rest.';
    String buttonText = '';

    if (reserve.index0to100 < 30) {
      heading = 'Rest and consolidate.';
      buttonText = resumable ? 'Resume (Optional)' : (dueCount > 0 ? 'Review (Optional)' : 'Practice (Optional)');
    } else if (resumable) {
      heading = 'Continue active retrieval session.';
      buttonText = 'Resume session';
    } else if (dueCount > 0) {
      heading = 'Execute spaced retrieval for $dueCount cards.';
      buttonText = 'Start retrieval queue';
    } else {
      heading = 'Write a blurt.';
      buttonText = 'Start practice';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TODAY\'S PRACTICE', style: Theme.of(context).textTheme.labelSmall),
              Text(reserve.index0to100 < 35 ? 'HIGH RECOVERY NEED' : 'OPTIMAL ADAPTATION',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: reserve.index0to100 < 35 ? NotebookTheme.oxblood : NotebookTheme.graphite, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 12),
          Text(
            'DESIRABLE DIFFICULTY WAVEFORM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _DifficultyWavePainter(diff.index0to100 / 100.0),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DIFFICULTY INDEX: ${(diff.index0to100).round()}/100', style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.graphite)),
              Text(diff.detail.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.oxblood, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text('SESSION POLICY RECOMMENDATION', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
              color: NotebookTheme.paper,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: const TextStyle(fontFamily: 'Georgia', fontSize: 13, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
                const SizedBox(height: 4),
                Text(
                  dueCount > 0
                      ? 'Interleaved FSRS review to prevent retrograde interference and reinforce temporal stability.'
                      : 'Free recall blurt to induce generation effect and map semantic keypoints.',
                  style: const TextStyle(fontFamily: 'Georgia', fontSize: 11, color: NotebookTheme.graphite),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('CONTRIBUTING FACTORS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
              color: NotebookTheme.paper,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final factor in (state.todayNeuroFactors.toList()..sort((a, b) => b.contribution.compareTo(a.contribution))).take(3)) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(factor.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
                      Text('${(factor.value01 * 100).round()}%', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: NotebookTheme.graphite)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: factor.value01.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: NotebookTheme.graphite.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(NotebookTheme.oxblood),
                  ),
                  const SizedBox(height: 3),
                  Text(factor.detail, style: const TextStyle(fontFamily: 'Georgia', fontSize: 9, color: NotebookTheme.graphite)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          if (state.notesDueForDelayedTest.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('DELAYED TESTS DUE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: NotebookTheme.oxblood.withValues(alpha: 0.3)),
                color: NotebookTheme.paper,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final noteId in state.notesDueForDelayedTest) ...[
                    Builder(builder: (context) {
                      final n = state.notes.where((note) => note.id == noteId).firstOrNull;
                      if (n == null) return const SizedBox.shrink();
                      final attempts = state.db.attemptsForTarget(n.id);
                      final lastAttempt = attempts.isNotEmpty ? attempts.last : null;
                      final days = lastAttempt != null ? DateTime.now().difference(lastAttempt.timestamp).inDays : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
                                  Text('${days}d since acquisition', style: const TextStyle(fontFamily: 'Georgia', fontSize: 9, color: NotebookTheme.graphite, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                state.startSession(n.title, anchorNoteId: n.id);
                                state.triggerPage(3);
                              },
                              child: const Text(
                                'Test now',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: NotebookTheme.oxblood,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (resumable) {
                  state.triggerPage(3);
                } else if (dueCount > 0) {
                  final first = state.dueNotesList.first;
                  state.startSession('Review: ${first.title}', anchorNoteId: first.id);
                  state.triggerPage(5);
                } else {
                  state.startSession('Daily Practice');
                  state.triggerPage(3);
                }
              },
              child: Text(buttonText),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DifficultyWavePainter extends CustomPainter {
  final double diff;
  _DifficultyWavePainter(this.diff);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = NotebookTheme.oxblood.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    final pts = 60;
    final freq = 1.0 + (diff * 3.5);

    for (int i = 0; i <= pts; i++) {
      final t = i / pts;
      final x = t * size.width;
      final y = (size.height / 2) + math.sin(t * math.pi * 2 * freq) * (size.height / 2.5);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _DifficultyWavePainter old) => old.diff != diff;
}

