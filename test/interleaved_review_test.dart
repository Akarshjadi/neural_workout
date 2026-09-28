import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('interleave_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('Interleaved review derives flag based on session anchor note ID', () async {
    final now = DateTime(2026, 1, 1);
    final note1 = Note(
      id: 1,
      title: 'Anchor Note A',
      body: 'Concept A body',
      kind: NoteKind.blurtSummary,
      createdAt: now,
      updatedAt: now,
      card: fsrs.Card(cardId: 1),
    );
    final note2 = Note(
      id: 2,
      title: 'Interleaved Note B',
      body: 'Concept B body',
      kind: NoteKind.blurtSummary,
      createdAt: now,
      updatedAt: now,
      card: fsrs.Card(cardId: 2),
    );

    await db.insertNote(note1);
    await db.insertNote(note2);

    // Start a session anchored on note 1
    await state.startSession('Anchor Note A', anchorNoteId: 1);
    expect(state.activeWorkout?.anchorNoteId, 1);

    // Review note 2 during note 1's session -> wasInterleaved = true (1)
    await state.reviewNote(note2, fsrs.Rating.good);
    final history1 = db.reviewHistory();
    expect(history1.last['was_interleaved'], 1);

    // Review note 1 during note 1's session -> wasInterleaved = false (0)
    await state.reviewNote(note1, fsrs.Rating.good);
    final history2 = db.reviewHistory();
    expect(history2.last['was_interleaved'], 0);
  });
}
