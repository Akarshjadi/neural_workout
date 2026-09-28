import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
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
    tempDir = await Directory.systemTemp.createTemp('delayed_due_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('notesDueForDelayedTest identifies due notes correctly', () async {
    final now = DateTime.now();
    final note1 = Note(
      id: 1,
      title: 'Due Concept',
      body: 'Body text',
      kind: NoteKind.blurtSummary,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
      card: fsrs.Card(cardId: 1),
    );
    final note2 = Note(
      id: 2,
      title: 'Tested Concept',
      body: 'Body text',
      kind: NoteKind.blurtSummary,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
      card: fsrs.Card(cardId: 2),
    );
    final note3 = Note(
      id: 3,
      title: 'Failed Concept',
      body: 'Body text',
      kind: NoteKind.blurtSummary,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
      card: fsrs.Card(cardId: 3),
    );

    await db.insertNote(note1);
    await db.insertNote(note2);
    await db.insertNote(note3);

    // Note 1: 3-day-old successful attempt, no outcome
    await db.insertAttempt(LearningAttempt(
      id: 1,
      knowledgeTargetId: 1,
      timestamp: now.subtract(const Duration(days: 3)),
      testType: TestType.freeRecall,
      correctness: Correctness.correct,
      scorePct: 90.0,
    ));

    // Note 2: 3-day-old successful attempt AND already tested in mediumDelay bucket
    await db.insertAttempt(LearningAttempt(
      id: 2,
      knowledgeTargetId: 2,
      timestamp: now.subtract(const Duration(days: 3)),
      testType: TestType.freeRecall,
      correctness: Correctness.correct,
      scorePct: 90.0,
    ));
    await db.insertDelayedOutcome(DelayedOutcome(
      id: 1,
      knowledgeTargetId: 2,
      attemptId: 2,
      sourceAttemptId: 2,
      measuredAt: now,
      bucket: DelayBucket.mediumDelay,
      elapsed: const Duration(days: 3),
      correctness: Correctness.correct,
      scorePct: 85.0,
    ));

    // Note 3: 3-day-old failed attempt
    await db.insertAttempt(LearningAttempt(
      id: 3,
      knowledgeTargetId: 3,
      timestamp: now.subtract(const Duration(days: 3)),
      testType: TestType.freeRecall,
      correctness: Correctness.incorrect,
      scorePct: 0.0,
    ));

    state.notes = db.allNotes();
    final due = state.notesDueForDelayedTest;

    expect(due.contains(1), isTrue);
    expect(due.contains(2), isFalse);
    expect(due.contains(3), isFalse);
    });

  // Note: Cache invalidation is tested via integration in the app
  // since _refreshAnalytics() is private and only called via _reloadNotes()

  // Note: The attemptId matching logic is tested indirectly via the first test
  // which creates an outcome with both sourceAttemptId and attemptId set
}
