import 'dart:math';

class LayoutNode {
  final int id;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double radius;

  LayoutNode(this.id, {this.radius = 20, this.x = 0, this.y = 0});
}

class LayoutEdge {
  final int source;
  final int target;
  final double thickness;
  LayoutEdge(this.source, this.target, {this.thickness = 2.0});
}

class ForceLayout {
  static void simulate(
    List<LayoutNode> nodes,
    List<LayoutEdge> edges, {
    double width = 2000,
    double height = 2000,
    int iterations = 20,
    double minDistance = 20,
  }) {
    if (nodes.isEmpty) return;

    final cx = width / 2;
    final cy = height / 2;
    final k = sqrt(width * height / nodes.length) * 0.5;

    for (int iter = 0; iter < iterations; iter++) {
      // Repulsion
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final n1 = nodes[i];
          final n2 = nodes[j];
          double dx = n1.x - n2.x;
          double dy = n1.y - n2.y;
          double dist = sqrt(dx * dx + dy * dy);
          if (dist == 0) {
            dx = Random().nextDouble() * 10 - 5;
            dy = Random().nextDouble() * 10 - 5;
            dist = sqrt(dx * dx + dy * dy);
          }
          final minDist = n1.radius + n2.radius + minDistance;
          if (dist < minDist * 2) {
            final force = (k * k) / dist * 0.5;
            final mx = (dx / dist) * force;
            final my = (dy / dist) * force;
            n1.vx += mx;
            n1.vy += my;
            n2.vx -= mx;
            n2.vy -= my;
          }
        }
      }

      // Attraction (Edges)
      for (final e in edges) {
        LayoutNode? sourceNode;
        LayoutNode? targetNode;
        for (final n in nodes) {
          if (n.id == e.source) sourceNode = n;
          if (n.id == e.target) targetNode = n;
        }
        if (sourceNode != null && targetNode != null) {
          final double dx = sourceNode.x - targetNode.x;
          final double dy = sourceNode.y - targetNode.y;
          final double dist = sqrt(dx * dx + dy * dy);
          if (dist > 0) {
            final force = (dist * dist) / k * 0.005; // weak spring
            final mx = (dx / dist) * force;
            final my = (dy / dist) * force;
            sourceNode.vx -= mx;
            sourceNode.vy -= my;
            targetNode.vx += mx;
            targetNode.vy += my;
          }
        }
      }

      // Gravity towards center + velocity application
      for (final n in nodes) {
        final double dx = cx - n.x;
        final double dy = cy - n.y;
        final double dist = sqrt(dx * dx + dy * dy);
        if (dist > 0) {
          n.vx += (dx / dist) * (dist * 0.005);
          n.vy += (dy / dist) * (dist * 0.005);
        }

        // Apply velocity with damping
        n.x += n.vx;
        n.y += n.vy;
        n.vx *= 0.5;
        n.vy *= 0.5;

        // Bounding box constrain to prevent flying out
        final halfW = width / 2;
        final halfH = height / 2;
        n.x = n.x.clamp(cx - halfW + n.radius, cx + halfW - n.radius);
        n.y = n.y.clamp(cy - halfH + n.radius, cy + halfH - n.radius);
      }
    }
    
    // Hard constraint: remove overlaps
    for (int iter = 0; iter < 5; iter++) {
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final n1 = nodes[i];
          final n2 = nodes[j];
          final dx = n1.x - n2.x;
          final dy = n1.y - n2.y;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = n1.radius + n2.radius + minDistance;
          if (dist < minDist && dist > 0) {
            final overlap = minDist - dist;
            final shiftX = (dx / dist) * (overlap / 2.0);
            final shiftY = (dy / dist) * (overlap / 2.0);
            n1.x += shiftX;
            n1.y += shiftY;
            n2.x -= shiftX;
            n2.y -= shiftY;
          }
        }
      }
    }
  }

  /// Alias/helper: generates layout simulation with default dimensions.
  static void generateLayout(
    List<LayoutNode> nodes,
    List<LayoutEdge> edges, {
    double width = 800,
    double height = 800,
  }) =>
      simulate(nodes, edges, width: width, height: height);

  /// Clusters nodes into connected components using union-find over edges.
  static List<List<int>> clusterNodes(
    List<LayoutNode> nodes,
    List<LayoutEdge> edges,
  ) {
    if (nodes.isEmpty) return [];
    final parent = <int, int>{};
    int find(int i) {
      parent.putIfAbsent(i, () => i);
      if (parent[i] == i) return i;
      return parent[i] = find(parent[i]!);
    }

    void union(int i, int j) {
      final rootI = find(i);
      final rootJ = find(j);
      if (rootI != rootJ) {
        parent[rootI] = rootJ;
      }
    }

    for (final n in nodes) {
      parent[n.id] = n.id;
    }
    for (final e in edges) {
      union(e.source, e.target);
    }
    final clusters = <int, List<int>>{};
    for (final n in nodes) {
      final root = find(n.id);
      clusters.putIfAbsent(root, () => []).add(n.id);
    }
    return clusters.values.toList();
  }
}
