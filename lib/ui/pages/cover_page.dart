import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/break_record.dart';
import '../theme_notebook.dart';
import '../../widgets/visuals/multidimensional_evidence_profile.dart';
import '../../widgets/visuals/memory_horizon.dart';

class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.todayReport()['streak'] as int;
    final breakStatus = state.breakStatus;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final dimensions = state.evidenceProfileDimensions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
              Text('STREAK: $streak-DAY TRACE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: NotebookTheme.oxblood)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'FIELD NOTEBOOK',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'LEARNING OBSERVATORY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: NotebookTheme.oxblood, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 12),
          Text(
            'Personal empirical evidence model across retrieval, retention, calibration, and error topology.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          MultidimensionalEvidenceProfile(
            dimensions: dimensions,
            height: 190,
          ),
          const SizedBox(height: 16),
          MemoryHorizon(
            notes: state.notes,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BreakDot(
                label: 'MICRO',
                active: !breakStatus.microDue,
                onTap: () => state.logBreak(tier: BreakTier.micro, duration: const Duration(minutes: 5)),
              ),
              _BreakDot(
                label: 'MESO',
                active: !breakStatus.mesoDue,
                onTap: () => state.logBreak(tier: BreakTier.meso, duration: const Duration(hours: 1)),
              ),
              _BreakDot(
                label: 'MACRO',
                active: !breakStatus.macroDue,
                onTap: () => state.logBreak(tier: BreakTier.macroMonthly, duration: const Duration(days: 1)),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _BreakDot extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BreakDot({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(active ? '●' : '○', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: active ? NotebookTheme.oxblood : NotebookTheme.graphite)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

