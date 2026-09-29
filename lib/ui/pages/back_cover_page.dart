import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';
import '../../widgets/visuals/calibration_field.dart';
import '../../widgets/visuals/error_topology.dart';
import '../../widgets/visuals/retention_trajectory.dart';
import '../../widgets/visuals/circadian_performance_card.dart';
import '../../widgets/visuals/research_horizon.dart';
import '../../widgets/visuals/prediction_outcome_split.dart';
import '../../widgets/visuals/recovery_curve.dart';
import '../../widgets/visuals/performance_density.dart';
import '../../widgets/visuals/semantic_knowledge_topology.dart';

class BackCoverPage extends StatelessWidget {
  const BackCoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEARNING TRAJECTORY', style: Theme.of(context).textTheme.labelSmall),
              Text('EMPIRICAL OBSERVATIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: NotebookTheme.oxblood)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 12),
          CalibrationField(
            attempts: state.learningAttempts,
            height: 110,
          ),
          const SizedBox(height: 16),
          ErrorTopology(
            errorRecords: state.errorRecords,
            height: 120,
          ),
          if (state.recurringErrors.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: NotebookTheme.oxblood.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('RECURRING ERROR FAMILIES (14D)',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 8)),
                  const SizedBox(height: 2),
                  for (final r in state.recurringErrors.take(4))
                    Text('${r.count}× ${r.type.label}',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            color: NotebookTheme.graphite)),
                ],
              ),
            ),
          ],
          if (state.hyperCorrectedTargets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'HYPER-CORRECTION WATCH: ${state.hyperCorrectedTargets.length} TARGET(S) — '
              'confidence dropped after correction. Re-verify instead of re-teaching.',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: NotebookTheme.oxblood),
            ),
          ],
          const SizedBox(height: 16),
          RetentionTrajectoryWidget(
            outcomes: state.delayedOutcomes,
            height: 110,
          ),
          const SizedBox(height: 16),
          PredictionOutcomeSplit(
            attempts: state.learningAttempts,
            height: 110,
          ),
          const SizedBox(height: 16),
          RecoveryCurve(
            attempts: state.learningAttempts,
            height: 110,
          ),
          const SizedBox(height: 16),
          PerformanceDensity(
            attempts: state.learningAttempts,
          ),
          const SizedBox(height: 16),
          SemanticKnowledgeTopology(
            height: 200,
            nodes: [
              for (final note in state.notes)
                TopologyNode(
                  note: note,
                  state: state.getKnowledgeEvidence(note.id).state,
                ),
            ],
          ),
          const SizedBox(height: 16),
          CircadianPerformanceCard(
            attempts: state.learningAttempts,
            height: 110,
          ),
          const SizedBox(height: 16),
          ResearchHorizonWidget(
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
