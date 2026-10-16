import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../theme_notebook.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  int _sleep = 3;
  int _energy = 3;
  int _activity = 3;
  final String _intention = 'When I start my practice session, I will retrieve key concepts without checking source notes first.';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DAILY CHECK-IN', style: Theme.of(context).textTheme.labelSmall),
              Text(state.hasCheckinToday ? 'CALIBRATED' : 'PENDING',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: state.hasCheckinToday ? NotebookTheme.oxblood : NotebookTheme.graphite, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 12),
          const Text(
            'Calibrate contextual covariates (sleep, physiological priming, executive fatigue) against subsequent retrieval latency.',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 13, color: NotebookTheme.ink),
          ),
          const SizedBox(height: 20),
          _buildSlider('Sleep duration & quality', _sleep, '1 (Restless / <5h)', '5 (Consolidated / 8h+)', (val) => setState(() => _sleep = val)),
          _buildSlider('Energy & executive focus', _energy, '1 (Depleted)', '5 (High alertness)', (val) => setState(() => _energy = val)),
          _buildSlider('Physical activity priming', _activity, '1 (Sedentary)', '5 (Active aerobic)', (val) => setState(() => _activity = val)),
          const SizedBox(height: 12),
          Text('IMPLEMENTATION INTENTION (EXECUTION CHAIN)', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.3)),
              color: NotebookTheme.paper,
            ),
            child: Text(
              _intention,
              style: const TextStyle(fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontSize: 12, color: NotebookTheme.ink),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<AppState>().logCheckin(sleep: _sleep, energy: _energy, activity: _activity);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Context covariates logged.', style: TextStyle(fontFamily: 'monospace'))),
              );
              context.read<AppState>().triggerPage(2);
            },
            child: Text(state.hasCheckinToday ? 'UPDATE CALIBRATION' : 'LOG CONTEXT CALIBRATION'),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, int value, String minDesc, String maxDesc, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
            Text('$value / 5', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: NotebookTheme.oxblood)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (v) => onChanged(v.toInt()),
          activeColor: NotebookTheme.oxblood,
          inactiveColor: NotebookTheme.graphite.withValues(alpha: 0.2),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minDesc, style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.graphite)),
            Text(maxDesc, style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: NotebookTheme.graphite)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

