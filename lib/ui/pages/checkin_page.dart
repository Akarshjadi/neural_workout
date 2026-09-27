import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  int _sleep = 3;
  int _energy = 3;
  int _activity = 3;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.hasCheckinToday) {
      return Center(
        child: Text('Check-in completed.', style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Text('DAILY CHECK-IN', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 32),
          _buildSlider('Sleep', _sleep, (val) => setState(() => _sleep = val)),
          _buildSlider('Energy', _energy, (val) => setState(() => _energy = val)),
          _buildSlider('Activity', _activity, (val) => setState(() => _activity = val)),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().logCheckin(sleep: _sleep, energy: _energy, activity: _activity);
            },
            child: const Text('SAVE CHECK-IN'),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: value.toString(),
          onChanged: (v) => onChanged(v.toInt()),
          activeColor: Colors.black87,
          inactiveColor: Colors.black12,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
