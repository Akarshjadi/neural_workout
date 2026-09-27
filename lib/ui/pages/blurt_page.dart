import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class BlurtPage extends StatefulWidget {
  const BlurtPage({super.key});
  @override
  State<BlurtPage> createState() => _BlurtPageState();
}

class _BlurtPageState extends State<BlurtPage> {
  final TextEditingController _ctrl = TextEditingController();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  
  bool _showBreathing = true;
  int _breathingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    // Start stopwatch only when breathing finishes or is skipped
    // _timer is used for both breathing and stopwatch
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer t) {
    if (_showBreathing) {
      setState(() {
        if (_breathingSeconds > 0) {
          _breathingSeconds--;
        } else {
          _finishBreathing();
        }
      });
    } else {
      setState(() {}); // repaint stopwatch
    }
  }

  void _finishBreathing() {
    setState(() {
      _showBreathing = false;
      context.read<AppState>().markFocusPrimed();
      _stopwatch.start();
    });
  }

  void _skipBreathing() {
    setState(() {
      _showBreathing = false;
      _stopwatch.start();
    });
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
    
    // Anticipation Phase (1.5s delay)
    setState(() {
      _isConverting = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));

    if (state.activeSession == null) {
      await state.startSession('Quick note');
      state.activeWorkout = state.activeWorkout?.copyWith(blurtText: _ctrl.text);
    } else {
      state.activeWorkout = state.activeWorkout?.copyWith(blurtText: _ctrl.text);
    }
    await state.finishBlurt(recallSpeedMs: _stopwatch.elapsedMilliseconds);
    
    if (mounted) {
      setState(() => _isConverting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blurt saved. Turn the page.', style: TextStyle(fontFamily: 'monospace'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showBreathing) {
      final m = _breathingSeconds ~/ 60;
      final s = (_breathingSeconds % 60).toString().padLeft(2, '0');
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text('MINDFULNESS PRIMING', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
            const Spacer(),
            Text('$m:$s', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: 'monospace'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Breathe deeply to prime executive control.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const Spacer(),
            ElevatedButton(
              onPressed: _skipBreathing,
              style: ElevatedButton.styleFrom(backgroundColor: NotebookTheme.paper, foregroundColor: NotebookTheme.graphite, elevation: 0),
              child: const Text('SKIP'),
            ),
            const SizedBox(height: 48),
          ],
        ),
      );
    }

    if (_isConverting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: NotebookTheme.oxblood),
            SizedBox(height: 24),
            Text('Synthesizing...', style: TextStyle(fontFamily: 'monospace', color: NotebookTheme.graphite)),
          ],
        ),
      );
    }

    final state = context.watch<AppState>();
    final elapsed = _stopwatch.elapsed;
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$mm:$ss', style: Theme.of(context).textTheme.labelSmall),
              TextButton(
                onPressed: () => _finish(state),
                child: const Text('Done'),
              ),
            ],
          ),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          Expanded(
            child: TextField(
              controller: _ctrl,
              expands: true,
              maxLines: null,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
