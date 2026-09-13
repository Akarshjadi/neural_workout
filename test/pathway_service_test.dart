import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/pathway_service.dart';
import 'package:neural_workout/models/pathway_record.dart';

/// Tests for PathwayService — default target merging and week computation.
void main() {
  group('PathwayService', () {
    test('partial targets merge with defaults', () {
      final s = PathwayService(targets: {'retrieval': 10});
      expect(s.targets['retrieval'], 10);
      expect(s.targets['compression'], 5);
      expect(s.targets['association'], 5);
      expect(s.targets['explanation'], 4);
      expect(s.targets['context'], 4);
    });

    test('empty targets keeps full defaults', () {
      final s = PathwayService(targets: {});
      expect(s.targets['retrieval'], 7);
      expect(s.targets['compression'], 5);
      expect(s.targets['association'], 5);
      expect(s.targets['explanation'], 4);
      expect(s.targets['context'], 4);
    });

    test('computeWeek with a single retrieval record reports 100/7 for retrieval but 0/5 for compression', () {
      final now = DateTime.now();
      final records = [
        PathwayRecord(
          id: 1,
          date: now,
          retrieval: true,
          compression: false,
          association: false,
          explanation: false,
          context: false,
          graceUsed: false,
        ),
      ];
      final s = PathwayService();
      final result = s.computeWeek(records);

      expect(result['retrieval']!.completed, 1);
      expect(result['retrieval']!.target, 7);
      expect(result['retrieval']!.percent, closeTo(100 / 7, 1e-9));

      expect(result['compression']!.completed, 0);
      expect(result['compression']!.target, 5);
      expect(result['compression']!.percent, 0);
    });

    test('computeWeek with full activity shows correct percentages', () {
      final now = DateTime.now();
      final records = List.generate(7, (i) => PathwayRecord(
        id: i,
        date: now.subtract(Duration(days: i)),
        retrieval: true,
        compression: true,
        association: true,
        explanation: true,
        context: true,
        graceUsed: false,
      ));
      final s = PathwayService();
      final result = s.computeWeek(records);

      expect(result['retrieval']!.percent, 100);
      expect(result['compression']!.percent, 100);
      expect(result['association']!.percent, 100);
      expect(result['explanation']!.percent, 100);
      expect(result['context']!.percent, 100);
    });
  });
}
