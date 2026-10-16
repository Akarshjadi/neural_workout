import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:hive/hive.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/note.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('concurrent_id_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('concurrent insertNote calls do not produce duplicate IDs', () async {
    final futures = List.generate(20, (i) {
      return db.insertNote(Note(
        id: 0,
        title: 'Note $i',
        body: 'Body $i',
        kind: NoteKind.cheatSheet,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        card: Card(cardId: i),
      ));
    });

    final ids = await Future.wait(futures);
    expect(ids.toSet().length, equals(20));
  });
}

