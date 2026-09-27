import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/break_record.dart';
import '../theme_notebook.dart';

class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.todayReport()['streak'] as int;
    final breakStatus = state.breakStatus;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 32),
          Text(
            'FIELD NOTEBOOK',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Text(
            'A space for free recall, spaced repetition, and cognitive practice.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text('STREAK: $streak', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _BreakDot(
                label: 'MICRO',
                active: !breakStatus.microDue,
                onTap: () => state.logBreak(tier: BreakTier.micro, duration: const Duration(minutes: 5)),
              ),
              const SizedBox(width: 16),
              _BreakDot(
                label: 'MESO',
                active: !breakStatus.mesoDue,
                onTap: () => state.logBreak(tier: BreakTier.meso, duration: const Duration(hours: 1)),
              ),
              const SizedBox(width: 16),
              _BreakDot(
                label: 'MACRO',
                active: !breakStatus.macroDue,
                onTap: () => state.logBreak(tier: BreakTier.macroMonthly, duration: const Duration(days: 1)),
              ),
            ],
          ),
          const Spacer(),
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
          Text(active ? '●' : '○', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
