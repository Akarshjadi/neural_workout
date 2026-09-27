import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/utils/force_layout.dart';
import 'dart:math';

void main() {
  test('ForceLayout simulation ensures minimum distance and keeps nodes in bounds', () {
    final nodes = [
      LayoutNode(1, radius: 20, x: 50, y: 50),
      LayoutNode(2, radius: 30, x: 50, y: 50), // overlap intentionally
      LayoutNode(3, radius: 20, x: 1000, y: 1000), // out of initial cluster
      LayoutNode(4, radius: 40, x: 400, y: 400),
      LayoutNode(5, radius: 20, x: 410, y: 400), // overlap intentionally
    ];

    final edges = [
      LayoutEdge(1, 2),
      LayoutEdge(2, 4),
      LayoutEdge(4, 5),
    ];

    ForceLayout.simulate(nodes, edges, width: 800, height: 800, iterations: 30, minDistance: 10);

    // Assert minimum distance between any pair
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final n1 = nodes[i];
        final n2 = nodes[j];
        final dist = sqrt(pow(n1.x - n2.x, 2) + pow(n1.y - n2.y, 2));
        final minimumAllowed = n1.radius + n2.radius + 10;
        
        // Use a small epsilon for floating point error
        expect(dist >= minimumAllowed - 0.1, isTrue, 
          reason: 'Node ${n1.id} and ${n2.id} are too close: dist=$dist, min=$minimumAllowed');
      }
    }

    // Assert inside bounds
    for (final n in nodes) {
      expect(n.x, greaterThanOrEqualTo(n.radius));
      expect(n.x, lessThanOrEqualTo(800 - n.radius));
      expect(n.y, greaterThanOrEqualTo(n.radius));
      expect(n.y, lessThanOrEqualTo(800 - n.radius));
    }
  });
}
