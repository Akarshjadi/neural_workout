import 'dart:math';

import 'package:fsrs/fsrs.dart' hide State, Card;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../services/fsrs_engine.dart';
import '../../state/app_state.dart';
import '../../models/blurt_score.dart';
import '../theme.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _anchorCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Note? _source;
  BlurtScore? _lastScore;
  int? _syncedStep; // which step's text we last loaded into _bodyCtrl (resume)
  Stopwatch? _blurtStopwatch; // tracks retrieval speed for recall scoring
  int _blurtBaseMs = 0; // elapsed time already recorded before this stopwatch started (FIX 5)

  @override
  void dispose() {
    _anchorCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncInterleaveState();
  }

  void _syncInterleaveState() {
    final state = context.read<AppState>();
    final step = state.activeStep.clamp(0, 8);
    final sessionActive = state.activeSession != null;
    if (!sessionActive || step != 5) {
      _interleaveQueue = null;
      _showInterleaveAnswer = false;
    } else if (_interleaveQueue == null) {
      final others = state.notes
          .where((n) => n.id != state.activeSession!.anchorNoteId)
          .toList();
      _interleaveQueue = _buildInterleaveQueue(others, state.fsrs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final step = state.activeStep.clamp(0, 8);
    final sessionActive = state.activeSession != null;
    final done = state.completedRecently;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sessionActive ? 'Workout · Step ${step + 2}/8' : 'Workout',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (sessionActive)
                  Flexible(
                    child: Text(
                      state.activeSession!.anchorTitle ?? 'no anchor',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: sessionActive ? (step + 2) / 8 : 0,
            backgroundColor: AppTheme.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          ),
          Expanded(
            child: done
                ? _stepDone(state)
                : (!sessionActive
                      ? _welcome(state)
                      : _stepBody(state, context, step)),
          ),
        ],
      ),
    );
  }

  Widget _welcome(AppState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Begin your neural workout',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick an anchor — any topic you learned today. Then you will blurt, '
          'compare, condense, link, teach, and schedule it.',
          style: TextStyle(color: AppTheme.textDim, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Step 1 · Anchor',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _anchorCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. OSI Model — 7 layers',
          ),
          textInputAction: TextInputAction.next,
          // Reset _source when user edits the title so we don't score against
          // the wrong note (FIX 2).
          onChanged: (text) {
            setState(() {
              if (_source != null && text.trim() != _source!.title) {
                _source = null;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        if (state.notes.isNotEmpty)
          TextButton.icon(
            onPressed: () => _pickNote(context, state),
            icon: const Icon(Icons.library_books),
            label: const Text('Pick an existing note'),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _anchorCtrl.text.trim().isEmpty && _source == null
              ? null
              : () => _start(state),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Begin Blurt'),
        ),
      ],
    );
  }

  Future<void> _pickNote(BuildContext context, AppState state) async {
    final chosen = await showModalBottomSheet<Note>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final n in state.notes)
            ListTile(
              title: Text(n.title),
              onTap: () => Navigator.pop(context, n),
            ),
        ],
      ),
    );
    if (chosen != null) {
      // Reset transient state when picking a different note so a previous
      // session's score/link data does not leak into the new one.
      setState(() {
        _lastScore = null;
        _linkToId = null;
        _syncedStep = null;
        _blurtStopwatch = null;
        _blurtBaseMs = 0;
        _source = chosen;
        _anchorCtrl.text = chosen.title;
      });
    }
  }

  Future<void> _start(AppState state) async {
    // Reset transient state from any previous session so stale score/link data
    // cannot leak into a fresh workout.
    setState(() {
      _lastScore = null;
      _linkToId = null;
      _syncedStep = null;
      _blurtStopwatch = null;
      _blurtBaseMs = 0;
    });
    final typed = _anchorCtrl.text.trim();
    final useExisting = _source != null && typed == _source!.title;
    final title = typed.isNotEmpty ? typed : (_source?.title ?? 'Untitled');
    final anchorId = useExisting ? _source!.id : null;
    await state.startSession(title, anchorNoteId: anchorId);
  }

  Widget _stepBody(AppState state, BuildContext context, int step) {
    _syncBodyFromState(state, step);
    switch (step) {
      case 0:
        return _stepBlurt(state);
      case 1:
        return _stepCompare(state);
      case 2:
        return _stepCheatSheet(state);
      case 3:
        return _stepLink(context, state);
      case 4:
        return _stepTeach(state);
      case 5:
        return _stepInterleave(context, state);
      case 6:
        return _stepSchedule(state);
      default:
        return _stepDone(state);
    }
  }

  Widget _stepWrap(Widget child) =>
      Padding(padding: const EdgeInsets.all(20), child: child);

  /// Restores the persisted text into [_bodyCtrl] exactly once per step so a
  /// resumed session shows the user's earlier input (issue 3). The shared
  /// controller doubles as the active step's scratchpad.
  void _syncBodyFromState(AppState state, int step) {
    if (_syncedStep == step) return;
    _syncedStep = step;
    final w = state.activeWorkout;
    _bodyCtrl.text = switch (step) {
      0 => w?.blurtText ?? '',
      2 => w?.cheatSheetText ?? '',
      3 => w?.linkText ?? '',
      4 => w?.teachingText ?? '',
      _ => '',
    };
    // Start retrieval-speed timer when entering the Blurt step.
    // Only for a fresh blurt (no text yet); if resumed from autosave, carry
    // the already-elapsed time so recall speed isn't reset to zero (FIX 5).
    if (step == 0 && _blurtStopwatch == null) {
      final w = state.activeWorkout;
      if (w == null || w.blurtText.isEmpty) {
        _blurtBaseMs = 0;
        _blurtStopwatch = Stopwatch()..start();
      } else if (w.blurtText.isNotEmpty) {
        _blurtBaseMs = w.elapsed(DateTime.now()).inMilliseconds;
        _blurtStopwatch = Stopwatch()..start();
      }
    }
  }

  // Step 2 — Blurt.
  Widget _stepBlurt(AppState state) {
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 2 · Blurt',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Type everything you remember about '
            '${state.activeSession!.anchorTitle}. No stopping — empty dump is fine.',
            style: const TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Everything you remember…',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final elapsedMs = _blurtStopwatch == null
                  ? null
                  : _blurtBaseMs + _blurtStopwatch!.elapsedMilliseconds;
              _blurtStopwatch?.stop();
              await state.setBlurt(_bodyCtrl.text);
              final score = await state.finishBlurt(source: _source, recallSpeedMs: elapsedMs);
              if (score != null) {
                setState(() => _lastScore = score);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Stop & Compare'),
          ),
        ],
      ),
    );
  }

  /// Teach the scorer a user synonym for a missed concept (issue 10).
  Future<void> _teachSynonym(
      BuildContext context, AppState state, String concept) async {
    final ctrl = TextEditingController();
    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('What did you call "$concept"?'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. bridge, cipher…'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip')),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  await state.addSynonymAlias(concept, ctrl.text);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Teach'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Widget _stepCompare(AppState state) {
    // Prefer the just-computed in-memory score; fall back to what was
    // persisted in wizard state so a resume shows the number (issue 4).
    final w = state.activeWorkout;
    final score =
        _lastScore ??
        (w?.scorePct == null
            ? null
            : BlurtScore(
                id: 0,
                noteId: w!.anchorNoteId ?? 0,
                noteTitle: w.anchorTitle,
                date: w.start,
                scorePct: w.scorePct!,
                matched: w.scoreMatched,
                missed: w.scoreMissed,
              ));
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 3 · Compare & Score',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (score != null) ...[
            Text(
              '${score.scorePct.round()}% retrieved',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isAiAvailable ? 'Scored by AI' : 'Scored by keyword match',
              style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              '✅ Matched',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              score.matched.isEmpty ? '—' : score.matched.join(', '),
              style: const TextStyle(color: AppTheme.accent),
            ),
            const SizedBox(height: 8),
            const Text(
              '🔴 Missed',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (score.missed.isEmpty)
              Text('—', style: const TextStyle(color: AppTheme.danger))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final concept in score.missed)
                    ActionChip(
                      label: Text(concept, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                      tooltip: 'Teach scorer: "$concept" was said as…',
                      onPressed: () => _teachSynonym(context, state, concept),
                    ),
                ],
              ),
          ] else
            const Text('Compare against your source note and see gaps.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              _bodyCtrl.clear();
              await state.advanceStep();
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next: Cheat Sheet'),
          ),
        ],
      ),
    );
  }

  Widget _stepCheatSheet(AppState state) {
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 4 · Cheat Sheet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Condense this concept into the tightest one-screen summary. '
            'Would a stranger understand? Cut more.',
            style: TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            decoration: const InputDecoration(hintText: 'One-screen summary…'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await state.setCheatSheet(_bodyCtrl.text);
              _bodyCtrl.clear();
              await state.finishCheatSheet();
            },
            icon: const Icon(Icons.save),
            label: const Text('Save & continue'),
          ),
        ],
      ),
    );
  }

  Widget _stepLink(BuildContext context, AppState state) {
    final candidates = state.notes
        .where((n) => n.id != state.activeSession!.anchorNoteId)
        .toList();
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 5 · Link',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'This concept connects to ______ because ______.',
            style: TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Relation…'),
          ),
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _pickLinkTarget(context, state),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Pick what it links to'),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await state.setLinkText(_bodyCtrl.text);
              _bodyCtrl.clear();
              await state.finishLink(_linkToId);
              setState(() => _linkToId = null);
            },
            icon: const Icon(Icons.link),
            label: const Text('Done linking'),
          ),
        ],
      ),
    );
  }

  int? _linkToId;

  Future<void> _pickLinkTarget(BuildContext context, AppState state) async {
    final chosen = await showModalBottomSheet<({String title, int id})>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final n in state.notes.where(
            (n) => n.id != state.activeSession!.anchorNoteId,
          ))
            ListTile(
              title: Text(n.title),
              onTap: () => Navigator.pop(context, (title: n.title, id: n.id)),
            ),
        ],
      ),
    );
    if (chosen != null) {
      setState(() => _linkToId = chosen.id);
    }
  }

  Widget _stepTeach(AppState state) {
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 6 · Teach',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explain this concept to a 5-year-old. Did you define every '
            'term you used? Type it out.',
            style: TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            decoration: const InputDecoration(hintText: 'Explain it simply…'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await state.setTeaching(_bodyCtrl.text);
              _bodyCtrl.clear();
              await state.finishTeach();
            },
            icon: const Icon(Icons.record_voice_over),
            label: const Text('I explained it'),
          ),
        ],
      ),
    );
  }

  Widget _stepInterleave(BuildContext context, AppState state) {
    // Interleave notes weighted toward low retrievability (decaying memories).
    // Shuffle for variety — the interleaving effect requires varied, unpredictable order.
    final queue = _interleaveQueue ?? const <Note>[];
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 7 · Interleaved Review',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mixing subjects — recall this note before you rate it. Try to '
            'recite the body from memory first (issue 6).',
            style: TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 12),
          if (queue.isEmpty)
            const Text(
              'No past notes to interleave yet. Coming soon.',
              style: TextStyle(color: AppTheme.textDim),
            )
          else ...[
            Text(
              queue.first.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_showInterleaveAnswer) ...[
              Text(
                queue.first.body,
                style: const TextStyle(height: 1.5, color: AppTheme.textDim),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _rateButton(
                    context,
                    state,
                    queue.first,
                    Rating.again,
                    'Again',
                    AppTheme.danger,
                  ),
                  _rateButton(
                    context,
                    state,
                    queue.first,
                    Rating.hard,
                    'Hard',
                    AppTheme.warm,
                  ),
                  _rateButton(
                    context,
                    state,
                    queue.first,
                    Rating.good,
                    'Good',
                    AppTheme.accent,
                  ),
                  _rateButton(
                    context,
                    state,
                    queue.first,
                    Rating.easy,
                    'Easy',
                    AppTheme.primary,
                  ),
                ],
              ),
            ] else
              FilledButton.icon(
                onPressed: () => setState(() => _showInterleaveAnswer = true),
                icon: const Icon(Icons.visibility),
                label: const Text('Reveal answer & rate'),
              ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async => await state.advanceStep(),
            child: const Text('Skip & continue'),
          ),
        ],
      ),
    );
  }

  List<Note>? _interleaveQueue;
  bool _showInterleaveAnswer = false;

  /// Build interleave queue with BOTH properties the science needs:
  ///   1. Variety — sample a random pool (shuffle must not be undone by sorting)
  ///   2. Decay-priority — within that pool, review the least-retrievable first
  /// (shuffle-then-sort would undo the shuffle; we shuffle, sample, then sort
  /// only the sampled subset.)
  List<Note> _buildInterleaveQueue(List<Note> candidates, FsrsEngine engine) {
    if (candidates.length <= 3) return candidates;
    final rng = Random();
    final shuffled = List<Note>.from(candidates)..shuffle(rng);
    // Random pool 2x the needed size, THEN sort by decay. Order within the
    // final 3 is genuinely varied because the pool itself was random.
    final pool = shuffled.take((candidates.length / 2).ceil().clamp(3, 12)).toList();
    pool.sort((a, b) =>
        engine.retrievability(a.card).compareTo(engine.retrievability(b.card)));
    return pool.take(3).toList();
  }

  Widget _rateButton(
    BuildContext context,
    AppState state,
    Note card,
    Rating rating,
    String label,
    Color color,
  ) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: color),
      onPressed: () async {
          await state.reviewNote(card, rating, interleaved: true);
          if (context.mounted) {
            final remaining = _interleaveQueue ?? <Note>[];
            if (remaining.length > 1) {
              setState(() {
                _interleaveQueue = remaining.sublist(1);
                _showInterleaveAnswer =
                    false; // next card stays hidden until recalled
              });
            } else {
              _interleaveQueue = null;
              _showInterleaveAnswer = false;
              await state.advanceStep();
            }
          }
        },
      icon: const Icon(Icons.check),
      label: Text(label),
    );
  }

  Widget _stepSchedule(AppState state) {
    return _stepWrap(
      ListView(
        children: [
          const Text(
            'Step 8 · Schedule',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            'This concept enters your spaced-repetition queue.',
            style: TextStyle(color: AppTheme.textDim),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await state.scheduleAnchor();
              await state.advanceStep();
            },
            icon: const Icon(Icons.done_all),
            label: const Text('Complete session'),
          ),
        ],
      ),
    );
  }

  Widget _stepDone(AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.accent, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Session complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'All 8 steps done. Streak updated — see you tomorrow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDim),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                state.dismissComplete();
                state.selectTab(0);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
