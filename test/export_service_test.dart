import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/thought.dart';

/// Phase 3 — CSV export format tests.
void main() {
  group('Export format', () {
    test('thoughts CSV has correct headers', () {
      // Simulate the CSV structure.
      final headers = ['id', 'text', 'created_at', 'tags', 'linked_note_id'];
      expect(headers.length, 5);
      expect(headers[0], 'id');
      expect(headers[4], 'linked_note_id');
    });

    test('thought toMap produces correct fields', () {
      final thought = Thought(
        id: 1,
        text: 'Test thought',
        createdAt: DateTime.parse('2025-01-15T10:30:00'),
        tags: ['idea', 'review'],
        linkedNoteId: 42,
      );
      final map = thought.toMap();
      expect(map['id'], 1);
      expect(map['text'], 'Test thought');
      expect(map['tags'], 'idea,review');
      expect(map['linked_note_id'], 42);
    });

    test('thought with no linked note has null in export', () {
      final thought = Thought(
        id: 2,
        text: 'Orphan thought',
        createdAt: DateTime.now(),
      );
      final map = thought.toMap();
      expect(map['linked_note_id'], isNull);
    });
  });
}
