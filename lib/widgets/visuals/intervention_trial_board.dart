import 'package:flutter/material.dart';
import '../../models/experiment.dart';
import '../../ui/theme_notebook.dart';

class InterventionTrialBoardWidget extends StatelessWidget {
  final Experiment? activeExperiment;

  const InterventionTrialBoardWidget({
    super.key,
    this.activeExperiment,
  });

  @override
  Widget build(BuildContext context) {
    final exp = activeExperiment;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
        color: NotebookTheme.paper,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVE INVESTIGATION', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
              Text(exp != null ? 'STATUS: ACTIVE' : 'NO ACTIVE TRIAL',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: exp != null ? NotebookTheme.oxblood : NotebookTheme.graphite, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          if (exp == null)
            const Text('No randomized A/B condition running. Tap to create experimental trial.',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 11, color: NotebookTheme.graphite))
          else ...[
            Text('H1: ${exp.hypothesis}', style: const TextStyle(fontFamily: 'Georgia', fontSize: 11, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
            const SizedBox(height: 4),
            Row(
              children: [
                for (int i = 0; i < exp.conditions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: i == 0 ? NotebookTheme.graphite.withValues(alpha: 0.08) : NotebookTheme.oxblood.withValues(alpha: 0.08),
                      child: Text(exp.conditions[i].label.toUpperCase(),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: i == 0 ? NotebookTheme.graphite : NotebookTheme.oxblood, fontWeight: i == 0 ? FontWeight.normal : FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

