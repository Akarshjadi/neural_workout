import 'package:fsrs/fsrs.dart' hide State, Card;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../state/app_state.dart';
import '../theme.dart';

/// Review tab — FSRS spaced-repetition queue, interleaved (UIUX §6).
/// Rating Again/Hard/Good/Easy feeds FSRS; interleaving is always on.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final due = state.dueNotesList;
    final current = due.isEmpty ? null : due.first;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.autorenew, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Review',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${due.length} due',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: current == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Nothing due. Great work — check back later.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppTheme.textDim, height: 1.5)),
                    ),
                  )
                : _cardView(context, state, current, due),
          ),
        ],
      ),
    );
  }

  Widget _cardView(
      BuildContext context, AppState state, Note card, List<Note> due) {
    final retrievability = state.fsrs.retrievability(card.card);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('retrievability ${(retrievability * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 12)),
              const SizedBox(height: 24),
              if (_showAnswer) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(card.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.6)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _rateBtn(context, state, card, Rating.again, 'Again'),
                    const SizedBox(width: 8),
                    _rateBtn(context, state, card, Rating.hard, 'Hard'),
                    const SizedBox(width: 8),
                    _rateBtn(context, state, card, Rating.good, 'Good'),
                    const SizedBox(width: 8),
                    _rateBtn(context, state, card, Rating.easy, 'Easy'),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: () => setState(() => _showAnswer = true),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Answer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateBtn(BuildContext context, AppState state, Note card,
      Rating rating, String label) {
    final colors = {
      Rating.again: AppTheme.danger,
      Rating.hard: AppTheme.warm,
      Rating.good: AppTheme.accent,
      Rating.easy: AppTheme.primary,
    };
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: colors[rating]),
        onPressed: () async {
          await state.reviewNote(card, rating, interleaved: true);
          if (context.mounted) {
            // Reset showAnswer so the next card (if any) starts hidden.
            // The build() method will pick up the next due card automatically.
            setState(() {
              _showAnswer = false;
            });
          }
        },
        child: Text(label),
      ),
    );
  }
}