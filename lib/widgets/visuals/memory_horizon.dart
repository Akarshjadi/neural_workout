import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../ui/theme_notebook.dart';

class MemoryHorizon extends StatefulWidget {
  final List<Note> notes;
  final ValueChanged<Note>? onNoteSelected;
  final double height;

  const MemoryHorizon({
    super.key,
    required this.notes,
    this.onNoteSelected,
    this.height = 140,
  });

  @override
  State<MemoryHorizon> createState() => _HorizonState();
}

class _HorizonState extends State<MemoryHorizon> {
  Note? _sel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bands = <List<Note>>[[], [], [], []]; // Due/Now, Near (1-3d), Mid (4-14d), Long (15d+)

    for (final n in widget.notes) {
      final d = n.card.due.difference(now).inDays;
      if (d <= 0) {
        bands[0].add(n);
      } else if (d <= 3) {
        bands[1].add(n);
      } else if (d <= 14) {
        bands[2].add(n);
      } else {
        bands[3].add(n);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MEMORY HORIZON', style: Theme.of(context).textTheme.labelSmall),
            Text('FSRS TEMPORAL FIELD', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2))),
          child: CustomPaint(
            painter: _HorizonPainter(bands, _sel),
            child: GestureDetector(
              onTapUp: (d) {
                final r = (d.localPosition.dy / (widget.height / 4)).floor().clamp(0, 3);
                if (bands[r].isNotEmpty) {
                  setState(() => _sel = bands[r].first);
                  widget.onNoteSelected?.call(bands[r].first);
                }
              },
            ),
          ),
        ),
        if (_sel != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: NotebookTheme.oxblood)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('${_sel!.title} (S: ${_sel!.card.stability?.toStringAsFixed(1) ?? "0.0"}d)',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NotebookTheme.ink), overflow: TextOverflow.ellipsis),
                ),
                Text('DUE: ${_sel!.card.due.difference(now).inDays}d', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NotebookTheme.oxblood, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HorizonPainter extends CustomPainter {
  final List<List<Note>> bands;
  final Note? sel;
  _HorizonPainter(this.bands, this.sel);

  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['DUE/NOW', '1-3d NEAR', '4-14d MID', '15d+ LONG'];
    final rH = size.height / 4;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 4; i++) {
      final y = i * rH;
      canvas.drawLine(Offset(60, y + rH / 2), Offset(size.width, y + rH / 2), Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.12));
      tp.text = TextSpan(
        text: labels[i],
        style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: i == 0 ? NotebookTheme.oxblood : NotebookTheme.graphite, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(2, y + (rH - tp.height) / 2));

      final notes = bands[i];
      for (int n = 0; n < notes.length && n < 15; n++) {
        final x = 68.0 + (n * 12.0);
        final isS = sel?.id == notes[n].id;
        final p = Paint()..color = isS ? NotebookTheme.oxblood : (i == 0 ? NotebookTheme.oxblood : NotebookTheme.ink.withValues(alpha: 0.6));
        canvas.drawCircle(Offset(x, y + rH / 2), isS ? 3.5 : 2.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter old) => true;
}
