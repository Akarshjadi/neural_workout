import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/error_record.dart';
import '../../ui/theme_notebook.dart';

class ErrorTopology extends StatefulWidget {
  final List<ErrorRecord> errorRecords;
  final double height;
  final ValueChanged<ErrorType>? onErrorSelected;

  const ErrorTopology({
    super.key,
    required this.errorRecords,
    this.height = 160,
    this.onErrorSelected,
  });

  @override
  State<ErrorTopology> createState() => _TopologyState();
}

class _TopologyState extends State<ErrorTopology> {
  ErrorType? _sel;

  @override
  Widget build(BuildContext context) {
    final counts = <ErrorType, int>{};
    for (final e in widget.errorRecords) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    final topTypes = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ERROR TOPOLOGY', style: Theme.of(context).textTheme.labelSmall),
            Text('${widget.errorRecords.length} TRACED ERRORS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: widget.errorRecords.isEmpty
              ? const Center(child: Text('NO SYSTEMATIC MISCONCEPTIONS DETECTED', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: NotebookTheme.graphite)))
              : CustomPaint(
                  painter: _TopologyPainter(topTypes.take(6).toList(), _sel),
                  child: GestureDetector(
                    onTapUp: (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null || topTypes.isEmpty) return;
                      final c = Offset(box.size.width / 2, widget.height / 2);
                      final tap = d.localPosition;
                      final n = math.min(topTypes.length, 6);
                      for (int i = 0; i < n; i++) {
                        final a = i * 2 * math.pi / n;
                        final r = 40.0;
                        final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
                        if ((tap - pt).distance < 20) {
                          setState(() => _sel = topTypes[i].key);
                          widget.onErrorSelected?.call(topTypes[i].key);
                          break;
                        }
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
            child: Text('DIAGNOSIS: ${_sel!.name} (${counts[_sel] ?? 0} occurrences)',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NotebookTheme.oxblood)),
          ),
        ],
      ],
    );
  }
}

class _TopologyPainter extends CustomPainter {
  final List<MapEntry<ErrorType, int>> types;
  final ErrorType? sel;
  _TopologyPainter(this.types, this.sel);

  @override
  void paint(Canvas canvas, Size size) {
    if (types.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    final n = types.length;
    final maxCount = types.first.value;

    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final r = math.min(size.width / 2 - 36, size.height / 2 - 20);
      pts.add(Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r));
    }

    // Connect co-occurrence edges
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        canvas.drawLine(pts[i], pts[j], Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.12));
      }
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final isS = sel == types[i].key;
      final count = types[i].value;
      final rad = 8.0 + (count / maxCount * 12.0);
      
      canvas.drawCircle(pts[i], rad, Paint()..color = isS ? NotebookTheme.oxblood : NotebookTheme.oxblood.withValues(alpha: 0.3));
    canvas.drawCircle(pts[i], rad, (Paint()..color = isS ? NotebookTheme.oxblood : NotebookTheme.graphite)..style = PaintingStyle.stroke..strokeWidth = 1.0);

      tp.text = TextSpan(
        text: types[i].key.name.substring(0, math.min(8, types[i].key.name.length)),
        style: TextStyle(fontFamily: 'monospace', fontSize: 7, color: isS ? NotebookTheme.oxblood : NotebookTheme.ink, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy + rad + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter old) => true;
}
