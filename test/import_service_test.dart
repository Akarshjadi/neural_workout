import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/import_service.dart';

/// Tests for ImportService.splitMarkdown — the pure, testable markdown splitter.
void main() {
  test('single heading returns one section', () {
    final md = '## TCP/IP Model\n\nTransmission Control Protocol.';
    final sections = ImportService.splitMarkdown(md);
    expect(sections.length, 1);
    expect(sections[0].title, 'TCP/IP Model');
    expect(sections[0].body, contains('Transmission Control Protocol'));
  });

  test('multiple ## and ### headings split correctly', () {
    final md = '''
## Layer 1
Physical layer stuff.

### Sub-layer
Details about the sub-layer.

## Layer 2
Data link layer.
''';
    final sections = ImportService.splitMarkdown(md);
    expect(sections.length, 3);
    expect(sections[0].title, 'Layer 1');
    expect(sections[1].title, 'Sub-layer');
    expect(sections[2].title, 'Layer 2');
  });

  test('no headings returns empty list', () {
    final md = 'Just some text without any headings.';
    final sections = ImportService.splitMarkdown(md);
    expect(sections, isEmpty);
  });

  test('mixed content with code blocks and lists', () {
    final md = r'''
## Functions
Here are some functions:

```dart
void main() {}
```

- Point one
- Point two

## Classes
Class definitions go here.
''';
    final sections = ImportService.splitMarkdown(md);
    expect(sections.length, 2);
    expect(sections[0].title, 'Functions');
    expect(sections[0].body, contains('void main()'));
    expect(sections[1].title, 'Classes');
  });

  test('bodies with leading/trailing whitespace are trimmed', () {
    final md = '''
## Title
   
  
  Content with whitespace   
  
''';
    final sections = ImportService.splitMarkdown(md);
    expect(sections.length, 1);
    expect(sections[0].title, 'Title');
    expect(sections[0].body, equals('Content with whitespace'));
  });

  test('handles content before first heading', () {
    final md = '''
Some intro text.

## First Section
Content here.
''';
    final sections = ImportService.splitMarkdown(md);
    expect(sections.length, 1);
    expect(sections[0].title, 'First Section');
  });

  test('empty string returns empty list', () {
    expect(ImportService.splitMarkdown(''), isEmpty);
  });

  test('only whitespace returns empty list', () {
    expect(ImportService.splitMarkdown('   \n\n   '), isEmpty);
  });
}
