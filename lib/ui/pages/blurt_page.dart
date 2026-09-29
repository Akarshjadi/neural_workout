import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/ai_scaffolding_service.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';
import '../../widgets/visuals/cue_gradient.dart';
import '../../models/workout_session.dart';

class BlurtPage extends StatefulWidget {
  const BlurtPage({super.key});
  @override
  State<BlurtPage> createState() => _BlurtPageState();
}

class _BlurtPageState extends State<BlurtPage> {
  final TextEditingController _ctrl = TextEditingController();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  double _confidence = 0.75;
  ScaffoldingLevel _scaffolding = ScaffoldingLevel.none;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
    _stopwatch.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    if (state.activeWorkout != null && _ctrl.text.isEmpty) {
      _ctrl.text = state.activeWorkout!.blurtText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _stopwatch.stop();
    _timer?.cancel();
    super.dispose();
  }

  bool _isConverting = false;

  void _finish(AppState state) async {
    if (_isConverting || _ctrl.text.trim().isEmpty) return;
    setState(() => _isConverting = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (state.activeSession == null) {
      await state.startSession('Quick note');
    }
    await state.setBlurt(_ctrl.text);

    await state.finishBlurt(
      recallSpeedMs: _stopwatch.elapsedMilliseconds,
      confidenceJudgement: _confidence,
      scaffoldingLevel: _scaffolding,
    );

    if (mounted) {
      setState(() => _isConverting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recall recorded. Turn page for contrast analysis.', style: TextStyle(fontFamily: 'monospace'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConverting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: NotebookTheme.oxblood),
            SizedBox(height: 16),
            Text('Analyzing semantic recall...', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: NotebookTheme.graphite)),
          ],
        ),
      );
    }

    final state = context.watch<AppState>();
    final elapsed = _stopwatch.elapsed;
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final w = state.activeWorkout;
    final hasPrompt = w != null && w.promptQuestion.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, mm, ss, w),
          const SizedBox(height: 6),
          CueGradientWidget(
            currentLevel: _scaffolding,
            onLevelSelected: (lvl) => setState(() => _scaffolding = lvl),
          ),
          const SizedBox(height: 6),
          _buildConfidenceRow(),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 0.8),
          if (hasPrompt) _buildPromptShape(context, w),
          _buildTextField(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String mm, String ss, WorkoutSessionState? w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('RECALL FIELD  [$mm:$ss]', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        if (w?.timerSeconds != null)
          Text(
            'PACED: ${w!.timerSeconds}s metronome',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              color: NotebookTheme.oxblood,
              fontWeight: FontWeight.bold,
            ),
          ),
        TextButton(
          onPressed: () => _finish(context.read<AppState>()),
          child: const Text('Commit recall →'),
        ),
      ],
    );
  }

  Widget _buildConfidenceRow() {
    return Row(
      children: [
        Text('CONFIDENCE: ${(_confidence * 100).round()}%', style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.graphite)),
        Expanded(
          child: Slider(
            value: _confidence,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: NotebookTheme.oxblood,
            inactiveColor: NotebookTheme.graphite.withValues(alpha: 0.2),
            onChanged: (v) => setState(() => _confidence = v),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptShape(BuildContext context, WorkoutSessionState w) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: NotebookTheme.oxblood.withValues(alpha: 0.3)),
        color: NotebookTheme.paper,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROMPT SHAPE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5),
          ),
          const SizedBox(height: 6),
          Text(
            w.promptQuestion,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: NotebookTheme.ink,
            ),
          ),
          if (w.promptCue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              w.promptCue,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: NotebookTheme.graphite,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (w.interventionExplanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'why: ${w.interventionExplanation}',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 10,
                color: NotebookTheme.graphite,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: _ctrl,
        expands: true,
        maxLines: null,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Reconstruct concepts from memory without looking at notes...',
          hintStyle: TextStyle(fontFamily: 'Georgia', fontStyle: FontStyle.italic, color: NotebookTheme.graphite, fontSize: 13),
        ),
      ),
    );
  }
}
