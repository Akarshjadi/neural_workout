import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final w = state.activeWorkout;

    if (w == null || w.scorePct == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Complete a blurt first.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final scoreStr = w.scorePct!.toStringAsFixed(0);
    final matched = w.scoreMatched;
    final missed = w.scoreMissed;
    final blurtText = w.blurtText;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COMPARISON', style: Theme.of(context).textTheme.labelSmall),
              Text('$scoreStr%', style: const TextStyle(fontFamily: 'monospace', fontSize: 36, color: NotebookTheme.ink)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Text(
            state.plasticityProfile.difficulty.detail == 'balanced' 
                ? 'This was in the desirable-difficulty band' 
                : 'Try again in a few hours',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: NotebookTheme.oxblood),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Blurt
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      blurtText.isEmpty ? '(Empty blurt)' : blurtText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, color: NotebookTheme.graphite.withValues(alpha: 0.3)),
                const SizedBox(width: 16),
                // Right: Source concepts
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONCEPTS', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 8),
                        for (final m in matched)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: NotebookTheme.oxblood, width: 2)),
                              ),
                              child: Text(m, style: Theme.of(context).textTheme.bodyLarge),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (missed.isNotEmpty)
                          Text('You missed:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final m in missed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: NotebookTheme.graphite, width: 1.5),
                                borderRadius: BorderRadius.circular(20), // "circled in graphite" - using rounded border for circling effect
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(m, style: Theme.of(context).textTheme.bodyLarge),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
