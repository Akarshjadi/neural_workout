import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('intervention_persistence_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('planAndRecordIntervention persists an intervention when policy triggers', () async {
    final now = DateTime.now();
    final note = Note(
      id: 1,
      title: 'Target Concept',
      body: 'Concept body',
      kind: NoteKind.blurtSummary,
      createdAt: now,
      updatedAt: now,
      card: fsrs.Card(cardId: 1),
    );
    await db.insertNote(note);

    // 1. No attempts -> inserts baseline intervention
    final id1 = await state.planAndRecordIntervention(1);
    expect(id1, isPositive);
    expect(db.allInterventions().length, 1);

    // 2. Three consecutive failures -> intervention action is workedExample
    for (int i = 1; i <= 3; i++) {
      await db.insertAttempt(LearningAttempt(
        id: i,
        timestamp: now.add(Duration(minutes: i)),
        knowledgeTargetId: 1,
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        scorePct: 0.0,
      ));
    }

    final id2 = await state.planAndRecordIntervention(1);
    expect(id2, isPositive);
    final all = db.allInterventions();
    expect(all.length, 2);
    expect(all.last.action, InterventionAction.workedExample);

    // 3. Calling it again appends another row without deduping
    final id3 = await state.planAndRecordIntervention(1);
    expect(id3, isPositive);
    expect(db.allInterventions().length, 3);
  });
}
