import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../services/pathway_service.dart';
import '../theme.dart';
import '../widgets/pathway_bar.dart';

/// You tab — analytics, reports, timeline/history, settings (UIUX §7).
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final report = state.todayReport();
    final pathways = report['pathways'] as Map<String, PathwayInfo>;
    final streak = report['streak'] as int;
    final weekSessions = report['sessionsThisWeek'] as int;

    final scores = state.blurtScores;
    final avg = scores.isEmpty
        ? 0.0
        : scores.fold<double>(0, (a, s) => a + s.scorePct) / scores.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('You',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('streak $streak',
                  style: const TextStyle(
                      color: AppTheme.warm, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _reportCard(
            title: 'Weekly Report',
            lines: [
              '$weekSessions/7 sessions this week',
              '${scores.length} blurts scored',
              'Avg blurt score ${avg.round()}%',
              '${state.notes.length} notes · ${state.pathwayRecords.length} sessions logged',
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pathway activation',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                for (final p in const [
                  'retrieval',
                  'compression',
                  'association',
                  'explanation',
                  'context'
                ])
                  PathwayBar(info: pathways[p]!, trend: '→'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _cognitiveProfile(state),
          const SizedBox(height: 16),
          _recentBlurts(state),
          const SizedBox(height: 16),
          _timeline(state),
          const SizedBox(height: 16),
          _reviewHistory(state),
          const SizedBox(height: 16),
          _SettingsCard(state: state),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Review history — the one analytics query that was defined but never shown
  /// (issue 13). Renders the most recent reviews, newest first.
  Widget _reviewHistory(AppState state) {
    final rows = state.sortedReviewHistory;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review history',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text('No reviews yet.',
                style: TextStyle(color: AppTheme.textDim))
          else
            for (final r in rows.take(10))
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    r['was_interleaved'] == 1
                        ? Icons.shuffle
                        : Icons.rotate_right,
                    color: AppTheme.primary,
                  ),
                  title: Text('${r['rating']}'),
                  subtitle: Text(
                    '${_fmtDate(r['date'])} · ${r['was_interleaved'] == 1 ? 'interleaved' : 'scheduled'}',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 12),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _fmtDate(dynamic iso) {
    if (iso is! String || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    return d == null ? '—' : '${d.day}/${d.month}/${d.year}';
  }

  Widget _reportCard({required String title, required List<String> lines}) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _recentBlurts(AppState state) {
    final sorted = state.sortedRecentBlurts;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent blurts',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            const Text('No blurts yet.',
                style: TextStyle(color: AppTheme.textDim))
          else
            for (final s in sorted.take(8))
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text('${s.scorePct.round()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: s.scorePct >= 60
                              ? AppTheme.accent
                              : AppTheme.danger)),
                  title: Text(s.noteTitle),
                  subtitle: Text(
                    '${s.matched.length} matched · ${s.missed.length} missed',
                    style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _timeline(AppState state) {
    final timeline = [...state.sessions]
        ..sort((a, b) => b.date.compareTo(a.date));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (state.sessions.isEmpty)
            const Text('No sessions yet.',
                style: TextStyle(color: AppTheme.textDim))
          else
            for (final s in timeline.take(10))
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt, color: AppTheme.primary),
                  title: Text(s.anchorTitle ?? 'session'),
                  subtitle: Text(
                    '${s.date.day}/${s.date.month} · ${s.stepsCompleted}/8 steps · ${s.duration.inMinutes}m',
                    style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// Phase 5 — Cognitive profile card showing overall score.
  Widget _cognitiveProfile(AppState state) {
    final score = state.overallScore.round();
    final weakest = state.getWeakestAreas();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cognitive profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$score',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.accent)),
              const Text('/100',
                  style: TextStyle(color: AppTheme.textDim, fontSize: 16)),
            ],
          ),
          if (weakest.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Focus areas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            for (final w in weakest)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $w',
                    style: const TextStyle(color: AppTheme.textDim, fontSize: 13)),
              ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHigh),
      ),
      child: child,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final AppState state;
  const _SettingsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    // Weekly pathway targets are now user-adjustable (issue 12).
    final targets = state.pathways.targets;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Weekly targets',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          for (final name in const [
            'retrieval',
            'compression',
            'association',
            'explanation',
            'context'
          ])
            _row(
              Icons.flag,
              _targetLabel(name),
              '${targets[name] ?? '—'}/week',
              onTap: () => _editTarget(context, name, targets[name] ?? 0),
            ),
          const SizedBox(height: 12),
          const Text('Local AI',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          _AiToggleRow(state: state),
          const SizedBox(height: 8),
          _row(Icons.download_outlined, 'Export data', 'CSV files',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final path = await state.exportAllCsv();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Exported to $path')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }),
        ],
      ),
    );
  }

  static String _targetLabel(String name) {
    final labels = {
      'retrieval': 'Retrieval',
      'compression': 'Compression',
      'association': 'Association',
      'explanation': 'Explanation',
      'context': 'Context',
    };
    return labels[name] ?? name;
  }

  Future<void> _editTarget(
      BuildContext context, String name, int current) async {
    final ctrl = TextEditingController(text: '$current');
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Weekly target · ${_targetLabel(name)}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'sessions per week'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v > 0) {
                await state.updatePathwayTarget(name, v);
              }
              if (!dialogCtx.mounted) return;
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        Icon(icon, color: AppTheme.textDim, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 13)),
        if (onTap != null) const Icon(Icons.edit, size: 16),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}

/// Phase 1 — AI scoring toggle with availability subtitle.
class _AiToggleRow extends StatelessWidget {
  final AppState state;
  const _AiToggleRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final available = state.isAiAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.psychology_outlined, color: AppTheme.textDim, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Use AI scoring')),
          if (!available && state.aiEnabled)
            const Text('Model not loaded',
                style: TextStyle(color: AppTheme.danger, fontSize: 11)),
          Switch(
            value: state.aiEnabled,
            onChanged: (v) => state.setAiEnabled(v),
          ),
        ],
      ),
    );
  }
}
