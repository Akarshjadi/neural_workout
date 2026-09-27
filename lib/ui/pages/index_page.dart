import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../state/app_state.dart';
import '../theme_notebook.dart';
import '../../utils/force_layout.dart';
import '../../models/note.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notes = state.notes;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TABLE OF CONTENTS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          const Divider(color: NotebookTheme.graphite, height: 1, thickness: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: 150, 
            child: _BrainBloom(notes, state.db.allLinks.map((l) => {'source': l.fromNoteId, 'target': l.toNoteId}).toList()),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      state.startSession(note.title, anchorNoteId: note.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note activated for practice.', style: TextStyle(fontFamily: 'monospace'))),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (index + 1).toString().padLeft(3, '0'),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty ? note.title : 'Untitled',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _BrainBloom extends StatefulWidget {
  final List<Note> notes;
  final List<Map<String, dynamic>> rawLinks;
  
  const _BrainBloom(this.notes, this.rawLinks);

  @override
  State<_BrainBloom> createState() => _BrainBloomState();
}

class _BrainBloomState extends State<_BrainBloom> {
  late List<LayoutNode> _nodes;
  late List<LayoutEdge> _edges;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(covariant _BrainBloom old) {
    super.didUpdateWidget(old);
    if (old.notes.length != widget.notes.length || old.rawLinks.length != widget.rawLinks.length) {
      _computeLayout();
    }
  }

  void _computeLayout() {
    _nodes = widget.notes.map((n) {
      final linkCount = widget.rawLinks.where((l) => l['source'] == n.id || l['target'] == n.id).length;
      return LayoutNode(
        n.id, 
        radius: 10.0 + (linkCount * 3.0),
        x: math.Random().nextDouble() * 200 - 100,
        y: math.Random().nextDouble() * 200 - 100,
      );
    }).toList();

    _edges = widget.rawLinks.map((l) => LayoutEdge(l['source'], l['target'])).toList();
    
    // Simulate immediately rather than animating, for visual consistency with notebook theme
    ForceLayout.simulate(_nodes, _edges, width: 400, height: 400, iterations: 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_nodes.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _BrainBloomPainter(_nodes, _edges),
    );
  }
}

class _BrainBloomPainter extends CustomPainter {
  final List<LayoutNode> nodes;
  final List<LayoutEdge> edges;

  _BrainBloomPainter(this.nodes, this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final edgePaint = Paint()
      ..color = NotebookTheme.graphite.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final nodePaint = Paint()
      ..color = NotebookTheme.oxblood.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final nodeCorePaint = Paint()
      ..color = NotebookTheme.oxblood
      ..style = PaintingStyle.fill;

    // Shift to fit
    double minX = nodes.first.x, maxX = nodes.first.x;
    double minY = nodes.first.y, maxY = nodes.first.y;
    for (final n in nodes) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.y < minY) minY = n.y;
      if (n.y > maxY) maxY = n.y;
    }

    final dX = maxX - minX == 0 ? 1 : maxX - minX;
    final dY = maxY - minY == 0 ? 1 : maxY - minY;
    
    final scale = math.min(size.width / (dX + 80), size.height / (dY + 80));
    canvas.translate(size.width / 2 - ((minX + maxX)/2)*scale, size.height / 2 - ((minY + maxY)/2)*scale);

    for (final edge in edges) {
      final s = nodes.firstWhere((n) => n.id == edge.source, orElse: () => nodes.first);
      final t = nodes.firstWhere((n) => n.id == edge.target, orElse: () => nodes.first);
      if (s.id == t.id && s != nodes.first) continue;
      canvas.drawLine(Offset(s.x * scale, s.y * scale), Offset(t.x * scale, t.y * scale), edgePaint);
    }

    for (final node in nodes) {
      final r = node.radius * scale * 0.5;
      final c = Offset(node.x * scale, node.y * scale);
      
      canvas.drawCircle(c, r, nodePaint);
      canvas.drawCircle(c, math.max(1, r/3), nodeCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainBloomPainter old) => true;
}

