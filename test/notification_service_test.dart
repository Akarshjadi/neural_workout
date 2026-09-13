import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/notification_service.dart';

/// Tests for NotificationService — trust-critical path.
void main() {
  group('NotificationService', () {
    test('scheduleDaily returns false when not ready', () async {
      final svc = NotificationService();
      // Service not initialized — _ready is false.
      final ok = await svc.scheduleDaily(
        hour: 22,
        minute: 30,
        title: 'Night review',
        body: 'Test',
        id: 101,
      );
      expect(ok, isFalse);
    });

    test('scheduleForDueCards returns false when not ready', () async {
      final svc = NotificationService();
      final ok = await svc.scheduleForDueCards([]);
      expect(ok, isFalse);
    });
  });
}
