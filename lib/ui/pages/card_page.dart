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

    if (note == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text('No active card.', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    final dueStr = '${note.card.due.year}-${note.card.due.month.toString().padLeft(2, '0')}-${note.card.due.day.toString().padLeft(2, '0')}';
    final stabilityStr = note.card.stability?.toStringAsFixed(1) ?? '0.0';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INDEX CARD', style: Theme.of(context).textTheme.labelSmall),
              Text('DUE: $dueStr', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        Text(note.body, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, color: NotebookTheme.graphite.withValues(alpha: 0.3)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STABILITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(stabilityStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: NotebookTheme.ink)),
                      const Spacer(),
                      // Absorbed optional step reminders
                      Text('Link', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                      Text('Teach', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                      Text('Cheat sheet', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
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
          const SnackBar(content: Text('Card rated.', style: TextStyle(fontFamily: 'monospace'))),
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
