import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../services/import_service.dart';
import '../../state/app_state.dart';
import '../theme.dart';

/// Knowledge tab — the Zettelkasten / second brain (UIUX §5).
/// List-first; searchable; shows FSRS due status; re-blurt entry.
class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.notes;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Knowledge',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${notes.length} notes',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 13)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Trash',
                  onPressed: () => _trashSheet(context, state),
                ),
                IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Import notes (markdown or plain text)',
                  onPressed: () => _importSheet(context, state),
                ),
              ],
            ),
          ),
          if (notes.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No notes yet. Complete a workout or import your cheat '
                    'sheet to seed your second brain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textDim, height: 1.5),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: notes.length,
                itemBuilder: (context, i) => _NoteTile(note: notes[i]),
              ),
            ),
        ],
      ),
    );
  }

  /// Import screen (issue 11): paste plain markdown or text. Structured
  /// `##`/`###` headings split into atomic notes; otherwise the whole blob
  /// becomes one note. Deterministic — no AI parsing.
  Future<void> _importSheet(BuildContext context, AppState state) async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import your cheat sheet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
                'Paste markdown (## / ### headings become separate notes) or '
                'plain text.',
                style: TextStyle(color: AppTheme.textDim, height: 1.5)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: '## Topic heading\nbody text...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                final sections = ImportService.splitMarkdown(text);
                if (sections.isEmpty) {
                  await state.addNote('Imported note', text,
                      kind: NoteKind.imported);
                } else {
                  for (final s in sections) {
                    await state.addNote(s.title, s.body,
                        kind: NoteKind.imported);
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content:
                      Text('Imported ${sections.isEmpty ? 1 : sections.length} '
                          'notes')),
                );
              },
              icon: const Icon(Icons.file_upload),
              label: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _trashSheet(BuildContext context, AppState state) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final deletedNotes = state.deletedNotes;
            final deletedThoughts = state.deletedThoughts;
            final isEmpty = deletedNotes.isEmpty && deletedThoughts.isEmpty;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trash & Recovery',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Recover soft-deleted notes and thoughts.',
                      style: TextStyle(color: AppTheme.textDim)),
                  const SizedBox(height: 16),
                  if (isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Trash is empty.',
                            style: TextStyle(color: AppTheme.textDim)),
                      ),
                    )
                  else ...[
                    if (deletedNotes.isNotEmpty) ...[
                      const Text('Deleted Notes',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final n in deletedNotes)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(n.title),
                          subtitle: Text(n.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Recover'),
                            onPressed: () async {
                              await state.recoverNote(n.id);
                              setModalState(() {});
                            },
                          ),
                        ),
                    ],
                    if (deletedThoughts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Deleted Thoughts',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final t in deletedThoughts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.text),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Recover'),
                            onPressed: () async {
                              await state.recoverThought(t.id);
                              setModalState(() {});
                            },
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final due = !note.card.due.isAfter(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Icon(
          due ? Icons.check_circle : Icons.hourglass_empty,
          color: due ? AppTheme.accent : AppTheme.textDim,
        ),
        title: Text(note.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${note.kind.name} · '
          '${note.createdAt.day}/${note.createdAt.month}',
          style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'rewrite', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
          ],
          onSelected: (v) async {
            if (v == 'view') {
              showModalBottomSheet(
                context: context,
                builder: (_) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(note.body,
                          style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              );
            } else if (v == 'rewrite') {
              // Edit in place via a simple prefilled dialog.
              _editDialog(context, state, note);
            } else if (v == 'delete') {
              await state.deleteNote(note.id);
            }
          },
        ),
      ),
      ),
    );
  }

  Future<void> _editDialog(
      BuildContext context, AppState state, Note note) async {
    final ctrl = TextEditingController(text: note.body);
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit note'),
        content: TextField(controller: ctrl, maxLines: 6),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await state.updateNote(
                  note.copyWith(body: ctrl.text, updatedAt: DateTime.now()));
              if (!dialogCtx.mounted) return;
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}