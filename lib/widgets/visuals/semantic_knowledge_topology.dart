import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/knowledge_evidence.dart';
import '../../models/note.dart';
import '../../ui/theme_notebook.dart';

/// One node of the semantic topology: a note plus its derived evidence state.
class TopologyNode {
  final Note note;
  final KnowledgeState state;

  const TopologyNode({required this.note, required this.state});
}

/// Item 248 — SemanticKnowledgeTopology.
///
/// The knowledge graph plus the *derived* state of each concept, so you can see
/// which part of your knowledge structure is load-bearing and which is thin.
/// Node fill encodes evidence state; edges come from real `Note.linkIds`.
///
/// Layout is deterministic so the same graph always looks the same — a graph
/// that reshuffles every rebuild is unreadable.
class SemanticKnowledgeTopology extends StatefulWidget {
  final List<TopologyNode> nodes;
  final double height;
  final void Function(Note note)? onNodeSelected;

  const SemanticKnowledgeTopology({
    super.key,
    required this.nodes,
    this.height = 220,
    this.onNodeSelected,
  });

  /// Deterministic circular layout. Same node count in, same positions out, so
  /// a rebuild or a page turn never reshuffles the graph.
  static List<Offset> layout(int n, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 24;
    return [
      for (int i = 0; i < n; i++)
        Offset(
          c.dx + math.cos(i * 2 * math.pi / math.max(n, 1)) * r,
          c.dy + math.sin(i * 2 * math.pi / math.max(n, 1)) * r,
        ),
    ];
  }

  @override
  State<SemanticKnowledgeTopology> createState() =>
      _SemanticKnowledgeTopologyState();
}

class _SemanticKnowledgeTopologyState extends State<SemanticKnowledgeTopology> {
  int? _selected;

  static Color _stateColor(KnowledgeState s) => switch (s) {
        KnowledgeState.stable => const Color(0xFF2E5D3A),
        KnowledgeState.verified => const Color(0xFF456E52),
        KnowledgeState.probable => const Color(0xFF7A8A6E),
        KnowledgeState.developing => NotebookTheme.graphite,
        KnowledgeState.bottleneck => NotebookTheme.oxblood,
        KnowledgeState.unstable => const Color(0xFFB5651D),
        KnowledgeState.unknown => const Color(0xFFBFBFBF),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SEMANTIC KNOWLEDGE TOPOLOGY',
                style: Theme.of(context).textTheme.labelSmall),
            Text('${widget.nodes.length} CONCEPTS',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 8)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border:
                Border.all(color: NotebookTheme.graphite.withValues(alpha: 0.2)),
            color: NotebookTheme.paper,
          ),
          child: widget.nodes.isEmpty
              ? const Center(
                  child: Text('NO CONCEPTS YET',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: NotebookTheme.graphite)))
              : GestureDetector(
                  onTapUp: (d) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final pts = SemanticKnowledgeTopology.layout(
                        widget.nodes.length, Size(box.size.width, widget.height));
                    for (int i = 0; i < pts.length; i++) {
                      if ((d.localPosition - pts[i]).distance < 16) {
                        setState(() => _selected = i);
                        widget.onNodeSelected?.call(widget.nodes[i].note);
                        return;
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: _TopologyPainter(
                      nodes: widget.nodes,
                      selected: _selected,
                      colorOf: _stateColor,
                    ),
                    size: Size(double.infinity, widget.height),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final s in KnowledgeState.values)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _stateColor(s), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text(s.label,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7.5,
                        color: NotebookTheme.graphite)),
              ]),
          ],
        ),
      ],
    );
  }
}

class _TopologyPainter extends CustomPainter {
  final List<TopologyNode> nodes;
  final int? selected;
  final Color Function(KnowledgeState) colorOf;

  _TopologyPainter({
    required this.nodes,
    required this.selected,
    required this.colorOf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final pts = SemanticKnowledgeTopology.layout(nodes.length, size);

    final indexById = <int, int>{};
    for (int i = 0; i < nodes.length; i++) {
      indexById[nodes[i].note.id] = i;
    }

    // Real links only.
    for (int i = 0; i < nodes.length; i++) {
      for (final linkId in nodes[i].note.linkIds) {
        final j = indexById[linkId];
        if (j == null || j == i) continue;
        canvas.drawLine(
          pts[i],
          pts[j],
          Paint()..color = NotebookTheme.graphite.withValues(alpha: 0.25),
        );
      }
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isSel = selected == i;
      // Bottlenecks and unstable concepts read larger: they are what to fix.
      final emphasis = (node.state == KnowledgeState.bottleneck ||
              node.state == KnowledgeState.unstable)
          ? 3.0
          : 0.0;
      final radius = 6.0 + emphasis + (isSel ? 3.0 : 0.0);

      canvas.drawCircle(pts[i], radius,
          Paint()..color = colorOf(node.state).withValues(alpha: 0.85));
      canvas.drawCircle(
        pts[i],
        radius,
        Paint()
          ..color = isSel ? NotebookTheme.ink : NotebookTheme.graphite
          ..strokeWidth = isSel ? 2.0 : 0.8
          ..style = PaintingStyle.stroke,
      );

      final label = node.note.title;
      tp.text = TextSpan(
        text: label.length > 14 ? '${label.substring(0, 14)}…' : label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: NotebookTheme.ink,
        ),
      );
      tp.layout(maxWidth: 70);
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy + radius + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter old) =>
      old.nodes != nodes || old.selected != selected;
}
