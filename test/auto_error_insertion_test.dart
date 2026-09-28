import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_error_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
    state.aiEnabled = false; // deterministic testing
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('Blurt scoring 0% with empty response auto-inserts factualRecallFailure', () async {
    final note = Note(
      id: 1,
      title: 'Operating Systems',
      body: 'Kernel manages CPU memory and I/O devices.',
      kind: NoteKind.blurtSummary,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      card: fsrs.Card(cardId: 1),
    );
    await db.insertNote(note);

    await state.scoreBlurt(note, '');
    final errors = db.allErrors();
    expect(errors.length, 1);
    expect(errors.first.type, ErrorType.factualRecallFailure);
  });

  test('Blurt scoring 20% with confidence 90 auto-inserts conceptualMisunderstanding', () async {
    final note = Note(
      id: 2,
      title: 'Recursion',
      body: 'A function that calls itself with a base case to terminate execution.',
      kind: NoteKind.blurtSummary,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      card: fsrs.Card(cardId: 2),
    );
    await db.insertNote(note);

    // Provide response that only matches one minor word so score is low (< 50)
    await state.scoreBlurt(
      note,
      'execution of loops',
      confidenceJudgement: 0.90,
    );

    final errors = db.allErrors();
    expect(errors.length, 1);
    expect(errors.first.type, ErrorType.conceptualMisunderstanding);
  });

  test('Blurt scoring 80% (success/partially correct) does not auto-insert error', () async {
    final note = Note(
      id: 3,
      title: 'Binary Search',
      body: 'Divide and conquer algorithm searching sorted array by halving search space.',
      kind: NoteKind.blurtSummary,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      card: fsrs.Card(cardId: 3),
    );
    await db.insertNote(note);

    await state.scoreBlurt(
      note,
      'divide and conquer algorithm searching sorted array halving space',
    );

    final errors = db.allErrors();
    expect(errors, isEmpty);
  });

  test('Blurt scoring 20% followed by manual self-diagnosis yields two errors with same attemptId', () async {
    final note = Note(
      id: 4,
      title: 'Deadlock',
      body: 'Mutual exclusion hold and wait no preemption circular wait conditions.',
      kind: NoteKind.blurtSummary,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      card: fsrs.Card(cardId: 4),
    );
    await db.insertNote(note);

    await state.scoreBlurt(
      note,
      'deadlock happens when programs freeze',
      confidenceJudgement: 0.90,
    );

    final autoErrors = db.allErrors();
    expect(autoErrors.length, 1);
    final attemptId = autoErrors.first.attemptId;

    // Manual self-diagnosis from compare page
    await state.logErrorRecord(
      attemptId: attemptId.toString(),
      conceptId: '4',
      errorType: ErrorType.misread,
      userResponse: 'deadlock happens when programs freeze',
      expectedResponse: note.body,
    );

    final allErrors = db.allErrors();
    expect(allErrors.length, 2);
    expect(allErrors[0].attemptId, attemptId);
    expect(allErrors[1].attemptId, attemptId);
    expect(allErrors[0].type, ErrorType.conceptualMisunderstanding);
    expect(allErrors[1].type, ErrorType.misread);
  });
}
