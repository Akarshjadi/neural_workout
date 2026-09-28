import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/force_layout.dart';
import '../theme_notebook.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<LayoutNode> _nodes = [];
  List<LayoutEdge> _edges = [];
  Map<int, double> _opacities = {};
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _layout();
      _ready = true;
    }
  }

  void _layout() {
    final state = context.read<AppState>();
    final notes = state.notes;
    final links = state.db.allLinks;
    final linkCounts = state.db.linkCountsByNote();
    
    _nodes = [];
    _edges = [];
    _opacities = {};
    
    final r = math.Random(42);
    
    for (final n in notes) {
      final c = linkCounts[n.id] ?? 0;
      final rad = 8.0 + (math.sqrt(c) * 4.5);
      _nodes.add(LayoutNode(n.id, radius: rad, x: 180 + r.nextDouble() * 180, y: 180 + r.nextDouble() * 260));
      
      final daysOld = DateTime.now().difference(n.updatedAt).inDays;
      final double op = 1.0 - (daysOld / 30);
      _opacities[n.id] = op.clamp(0.25, 1.0);
    }
    
    for (final l in links) {
      if (l.fromNoteId != null && l.toNoteId != null) {
        _edges.add(LayoutEdge(l.fromNoteId!, l.toNoteId!));
      }
    }
    
    ForceLayout.simulate(_nodes, _edges, width: 380, height: 500, iterations: 100);
    setState(() {});
  }

  void _onTapNode(LayoutNode node) async {
    final state = context.read<AppState>();
    if (state.activeSession == null) {
      await state.startSession('Review individual card', anchorNoteId: node.id);
    } else {
      state.activeWorkout = state.activeWorkout?.copyWith(anchorNoteId: node.id);
    }
    state.triggerPage(5);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KNOWLEDGE TOPOLOGY', style: Theme.of(context).textTheme.labelSmall),
              Text('${_nodes.length} CONCEPTS | ${_edges.length} LINKS',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: NotebookTheme.oxblood, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 8),
          Expanded(
            child: InteractiveViewer(
              child: GestureDetector(
                onTapUp: (details) {
                  final pos = details.localPosition;
                  for (final n in _nodes) {
                    final dx = n.x - pos.dx;
                    final dy = n.y - pos.dy;
                    if (math.sqrt(dx * dx + dy * dy) <= n.radius + 6) {
                      _onTapNode(n);
                      break;
                    }
                  }
                },
                child: CustomPaint(
                  painter: _GraphPainter(_nodes, _edges, _opacities),
                  size: const Size(double.infinity, double.infinity),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<LayoutNode> nodes;
  final List<LayoutEdge> edges;
  final Map<int, double> opacities;
  
  _GraphPainter(this.nodes, this.edges, this.opacities);
  
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    
    final edgePaint = Paint()
      ..color = NotebookTheme.graphite.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke;
      
    for (final e in edges) {
      final s = nodes.firstWhere((n) => n.id == e.source, orElse: () => LayoutNode(-1));
      final t = nodes.firstWhere((n) => n.id == e.target, orElse: () => LayoutNode(-1));
      if (s.id != -1 && t.id != -1) {
        edgePaint.strokeWidth = e.thickness;
        canvas.drawLine(Offset(s.x, s.y), Offset(t.x, t.y), edgePaint);
      }
    }
    
    for (final n in nodes) {
      final fillPaint = Paint()
        ..color = NotebookTheme.oxblood.withValues(alpha: opacities[n.id] ?? 0.5)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = NotebookTheme.graphite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(Offset(n.x, n.y), n.radius, fillPaint);
      canvas.drawCircle(Offset(n.x, n.y), n.radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}

