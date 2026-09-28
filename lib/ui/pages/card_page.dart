import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class CardPage extends StatelessWidget {
  const CardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final anchorId = state.activeSession?.anchorNoteId;
    final note = anchorId != null ? state.notes.where((n) => n.id == anchorId).firstOrNull : null;
    final cap = note != null ? state.capabilityFor(note.id) : null;

    if (note == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text('No active card selected.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    final dueDays = note.card.due.difference(DateTime.now()).inDays;
    final stabilityStr = note.card.stability?.toStringAsFixed(1) ?? '0.0';
    final diffStr = note.card.difficulty?.toStringAsFixed(1) ?? '5.0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EVIDENCE CARD', style: Theme.of(context).textTheme.labelSmall),
              Text(dueDays <= 0 ? 'DUE NOW' : 'HORIZON: +${dueDays}d',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.bold, color: dueDays <= 0 ? NotebookTheme.oxblood : NotebookTheme.graphite)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text(note.body, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, color: NotebookTheme.graphite.withValues(alpha: 0.2)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 84,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STABILITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                      Text('${stabilityStr}d', style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold, color: NotebookTheme.oxblood)),
                      const SizedBox(height: 10),
                      Text('DIFFICULTY', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                      Text('$diffStr / 10', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: NotebookTheme.ink)),
                      const SizedBox(height: 10),
                      Text('STATE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                      Text(note.card.state.name.toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NotebookTheme.ink)),
                      if (cap != null) ...[
                        const SizedBox(height: 10),
                        Text('CAPABILITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
                        Text(cap.score != null ? '${cap.score!.toStringAsFixed(0)}%' : '—', style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
                        Text(cap.confidence != null ? '${cap.confidence!.toStringAsFixed(0)}% conf' : 'no conf', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: NotebookTheme.graphite)),
                        Text(cap.contradictions.isEmpty ? 'no contradictions' : cap.contradictions.first, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: NotebookTheme.oxblood), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 0.8),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RateLink('Again', () => state.reviewNote(note, fsrs.Rating.again)),
              _RateLink('Hard', () => state.reviewNote(note, fsrs.Rating.hard)),
              _RateLink('Good', () => state.reviewNote(note, fsrs.Rating.good)),
              _RateLink('Easy', () => state.reviewNote(note, fsrs.Rating.easy)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RateLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FSRS spacing updated.', style: TextStyle(fontFamily: 'monospace'))),
        );
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: NotebookTheme.oxblood,
          decoration: TextDecoration.underline,
          decorationColor: NotebookTheme.oxblood,
        ),
      ),
    );
  }
}

