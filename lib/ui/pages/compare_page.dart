import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/error_record.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  ErrorType? _selectedError;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final w = state.activeWorkout;

    if (w == null || w.scorePct == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text('Complete a recall session first.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    final scoreStr = w.scorePct!.toStringAsFixed(0);
    final matched = w.scoreMatched;
    final missed = w.scoreMissed;
    final blurtText = w.blurtText;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CONTRAST & CORRECTION', style: Theme.of(context).textTheme.labelSmall),
              Text('$scoreStr% RETRIEVED', style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: NotebookTheme.oxblood)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECALL TRACE', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(blurtText.isEmpty ? '(Empty)' : blurtText, style: const TextStyle(fontFamily: 'Georgia', fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KEYPOINTS', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      for (final m in matched)
                        Text('✓ $m', style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: NotebookTheme.oxblood)),
                      for (final m in missed)
                        Text('✕ $m', style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: NotebookTheme.graphite, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('ERROR TOPOLOGY SELF-DIAGNOSIS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final type in [ErrorType.factualRecallFailure, ErrorType.retrievalFailure, ErrorType.wrongMethod, ErrorType.conceptualMisunderstanding, ErrorType.confusedConcepts])
                ChoiceChip(
                  label: Text(type.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 8)),
                  selected: _selectedError == type,
                  selectedColor: NotebookTheme.oxblood.withValues(alpha: 0.15),
                  onSelected: (sel) {
                    setState(() => _selectedError = sel ? type : null);
                    if (sel) {
                      state.logErrorRecord(
                        conceptId: w.anchorNoteId?.toString() ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
                        errorType: type,
                        attemptId: '${state.activeSession?.id ?? 0}',
                        userResponse: blurtText,
                        expectedResponse: matched.join(', '),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error classified as ${type.name}.', style: const TextStyle(fontFamily: 'monospace'))),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

