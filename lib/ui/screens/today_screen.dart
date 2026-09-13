import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../services/pathway_service.dart';
import '../theme.dart';
import '../widgets/pathway_bar.dart';

/// Today dashboard (UIUX §3): streak, pathway bars, due reviews, start CTA,
/// night/morning cards, quick capture.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final report = state.todayReport();
    final pathways = report['pathways'] as Map<String, PathwayInfo>;
    final streak = report['streak'] as int;
    final graceOk = report['graceAvailable'] as bool;
    final dueCount = report['dueCount'] as int;
    final weekSessions = report['sessionsThisWeek'] as int;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(streak, graceOk, weekSessions),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pathways this week',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
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
          _startCard(context, state),
          const SizedBox(height: 12),
          _dueCard(context, state, dueCount),
          const SizedBox(height: 12),
          _suggestionsCard(state),
          const SizedBox(height: 12),
          _routineRow(),
          const SizedBox(height: 12),
          _QuickCaptureField(),
          const SizedBox(height: 12),
          _ThoughtsSection(),
        ],
      ),
    );
  }

  Widget _header(int streak, bool graceOk, int week) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.local_fire_department,
            color: AppTheme.warm, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day $streak of streak',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Neural Workout · $week sessions this week',
                  style:
                      const TextStyle(color: AppTheme.textDim, fontSize: 13)),
            ],
          ),
        ),
        if (!graceOk)
          const Tooltip(
            message: 'Grace token used this window',
            child: Icon(Icons.shield, color: AppTheme.textDim, size: 20),
          ),
      ],
    );
  }

  Widget _startCard(BuildContext context, AppState state) {
    if (state.activeSession != null) {
      return _Card(
        color: AppTheme.surfaceHigh,
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            title: const Text('Resume in-progress session',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(state.activeSession!.anchorTitle ?? ''),
            trailing: const Icon(Icons.play_circle_fill,
                color: AppTheme.primary, size: 32),
            onTap: () => state.selectTab(1),
          ),
        ),
      );
    }
    return _Card(
      color: AppTheme.surfaceHigh,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => state.selectTab(1),
          icon: const Icon(Icons.play_arrow),
          label: const Text("Start Today's Workout"),
        ),
      ),
    );
  }

  Widget _dueCard(BuildContext context, AppState state, int dueCount) {
    return _Card(
      color: dueCount > 0 ? AppTheme.surfaceHigh : AppTheme.surface,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          leading: Icon(Icons.rotate_right,
              color: dueCount > 0 ? AppTheme.accent : AppTheme.textDim),
          title: Text(dueCount > 0
              ? '$dueCount item${dueCount == 1 ? '' : 's'} due for review'
              : 'All caught up — nothing due'),
          subtitle: const Text('Spaced repetition queue'),
          trailing: dueCount > 0 ? const Icon(Icons.chevron_right) : null,
          onTap: () => state.selectTab(3),
        ),
      ),
    );
  }

  Widget _routineRow() {
    return Row(
      children: [
        Expanded(
          child: _Card(
            child: _RoutineTile(
              icon: Icons.nightlight,
              label: 'Night review',
              hint: '5 min before bed',
              color: AppTheme.warm,
              onTap: (ctx) => _scheduleRoutine(ctx, hour: 22, minute: 30, id: 101,
                  title: 'Night review', body: '5 minutes before bed — review today\'s blurts'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            child: _RoutineTile(
              icon: Icons.wb_sunny_outlined,
              label: 'Morning wake',
              hint: '5 min after wake',
              color: AppTheme.accent,
              onTap: (ctx) => _scheduleRoutine(ctx, hour: 7, minute: 0, id: 102,
                  title: 'Morning wake', body: '5 minutes after waking — recall yesterday\'s material'),
            ),
          ),
        ),
      ],
    );
  }

  /// Wire a routine card to a persisted daily reminder (sleep-consolidation
  /// review: night + morning spaced review around sleep).
  Future<void> _scheduleRoutine(
    BuildContext ctx, {
    required int hour,
    required int minute,
    required int id,
    required String title,
    required String body,
  }) async {
    final state = ctx.read<AppState>();
    final messenger = ScaffoldMessenger.of(ctx);
    final ok = await state.notificationSvc.scheduleDaily(
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      id: id,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Daily $title reminder set for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
            : 'Could not set $title reminder — notifications not available'),
        backgroundColor: ok ? null : AppTheme.danger,
      ),
    );
  }
  /// Phase 6 — Suggestions card at top of Today screen.
  Widget _suggestionsCard(AppState state) {
    final suggestions = state.suggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return _Card(
      color: AppTheme.surfaceHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggestions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $s',
                  style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Phase 3 — Thoughts stream section on Today screen.
class _ThoughtsSection extends StatefulWidget {
  @override
  State<_ThoughtsSection> createState() => _ThoughtsSectionState();
}

class _ThoughtsSectionState extends State<_ThoughtsSection> {
  final _ctrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    _tagCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allThoughts = state.thoughts;
    final filtered = _searchQuery.isEmpty
        ? allThoughts
        : allThoughts.where((t) => t.text.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Thoughts',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search, size: 20),
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }
                }),
              ),
            ],
          ),
          if (_showSearch)
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search thoughts...',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'New thought...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                    hintText: 'tags',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.accent),
                onPressed: () async {
                  if (_ctrl.text.trim().isEmpty) return;
                  final tags = _tagCtrl.text.isEmpty
                      ? <String>[]
                      : _tagCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                  await state.addThought(_ctrl.text.trim(), tags: tags);
                  _ctrl.clear();
                  _tagCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Text('No thoughts yet.',
                style: TextStyle(color: AppTheme.textDim, fontSize: 13))
          else
            for (final t in filtered.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.text, style: const TextStyle(fontSize: 13)),
                          if (t.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(t.tags.join(', '),
                                  style: const TextStyle(
                                      color: AppTheme.textDim, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.textDim),
                      onPressed: () => state.deleteThought(t.id),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _QuickCaptureField extends StatefulWidget {
  @override
  State<_QuickCaptureField> createState() => _QuickCaptureFieldState();
}

class _QuickCaptureFieldState extends State<_QuickCaptureField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return _Card(
      child: TextField(
        controller: _ctrl,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: '✍️ Quick note — what did you just learn? Capture it.',
          border: InputBorder.none,
        ),
        onSubmitted: (v) async {
          if (v.trim().isEmpty) return;
          final messenger = ScaffoldMessenger.of(context);
          await state.addNote('Quick note', v.trim());
          _ctrl.clear(); // don't leave stale text behind (issue 16)
          messenger.showSnackBar(
            const SnackBar(content: Text('Captured — added to notes')),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _Card({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHigh),
      ),
      child: child,
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final void Function(BuildContext) onTap;
  const _RoutineTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(hint,
              style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}
