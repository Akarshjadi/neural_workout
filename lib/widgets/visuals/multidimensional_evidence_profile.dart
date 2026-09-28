import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/theme_notebook.dart';
import 'visual_semantics.dart';

class EvidenceProfileDimension {
  final String label;
  final double value;
  final EvidenceState state;
  final String detail;

  const EvidenceProfileDimension({
    required this.label,
    required this.value,
    this.state = EvidenceState.observed,
    required this.detail,
  });
}

class MultidimensionalEvidenceProfile extends StatefulWidget {
  final List<EvidenceProfileDimension> dimensions;
  final double height;
  final ValueChanged<EvidenceProfileDimension>? onDimensionSelected;

  const MultidimensionalEvidenceProfile({
    super.key,
    required this.dimensions,
    this.height = 200,
    this.onDimensionSelected,
  });

  @override
  State<MultidimensionalEvidenceProfile> createState() => _ProfileState();
}

class _ProfileState extends State<MultidimensionalEvidenceProfile> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    if (widget.dimensions.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('GATHERING EVIDENCE...', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NotebookTheme.graphite))),
      );
    }
    final sel = _sel != null && _sel! < widget.dimensions.length ? widget.dimensions[_sel!] : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: GestureDetector(
            onTapUp: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final c = Offset(box.size.width / 2, widget.height / 2);
              final tap = d.localPosition;
              double a = math.atan2(tap.dy - c.dy, tap.dx - c.dx) + (math.pi / 2);
              if (a < 0) a += 2 * math.pi;
              final count = widget.dimensions.length;
              final idx = ((a + math.pi / count) % (2 * math.pi) ~/ (2 * math.pi / count)) % count;
              setState(() => _sel = idx);
              widget.onDimensionSelected?.call(widget.dimensions[idx]);
            },
            child: CustomPaint(
              painter: _Painter(widget.dimensions, _sel),
              size: Size(double.infinity, widget.height),
            ),
          ),
        ),
        if (sel != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('${sel.label.toUpperCase()}: ${sel.detail}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NotebookTheme.oxblood), overflow: TextOverflow.ellipsis),
                ),
                Text('${(sel.value * 100).round()}%', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: NotebookTheme.ink)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Painter extends CustomPainter {
  final List<EvidenceProfileDimension> dims;
  final int? sel;
  _Painter(this.dims, this.sel);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width / 2 - 32, size.height / 2 - 12);
    if (maxR <= 0) return;
    final n = dims.length;

    for (int r = 1; r <= 3; r++) {
      final rad = maxR * (r / 3.0);
      final p = Path();
      for (int i = 0; i < n; i++) {
        final a = (i * 2 * math.pi / n) - (math.pi / 2);
        final pt = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      p.close();
      canvas.drawPath(p, Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.1)..style = PaintingStyle.stroke);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final a = (i * 2 * math.pi / n) - (math.pi / 2);
      canvas.drawLine(c, Offset(c.dx + math.cos(a) * maxR, c.dy + math.sin(a) * maxR), Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.2));
      final isS = sel == i;
      tp.text = TextSpan(
        text: dims[i].label,
        style: TextStyle(fontFamily: 'monospace', fontSize: 8, fontWeight: isS ? FontWeight.bold : FontWeight.normal, color: isS ? NotebookTheme.oxblood : NotebookTheme.graphite),
      );
      tp.layout();
      tp.paint(canvas, Offset(c.dx + math.cos(a) * (maxR + 10) - tp.width / 2, c.dy + math.sin(a) * (maxR + 10) - tp.height / 2));
    }

    final poly = Path();
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = (i * 2 * math.pi / n) - (math.pi / 2);
      final r = maxR * dims[i].value.clamp(0.05, 1.0);
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      pts.add(pt);
      if (i == 0) {
        poly.moveTo(pt.dx, pt.dy);
      } else {
        poly.lineTo(pt.dx, pt.dy);
      }
    }
    poly.close();
    canvas.drawPath(poly, Paint()..color = NotebookTheme.oxblood.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawPath(poly, Paint()..color = NotebookTheme.oxblood..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], sel == i ? 3.5 : 2.0, Paint()..color = sel == i ? NotebookTheme.oxblood : NotebookTheme.ink);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => old.dims != dims || old.sel != sel;
}
