import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/suggestion_service.dart';
import 'package:neural_workout/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AppDatabase db;
  late AppState state;
  final service = SuggestionService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('evidence_suggestions_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('3 identical-family errors within 14 days produces Recurring error suggestion', () async {
    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      await db.insertError(ErrorRecord(
        id: i,
        attemptId: i,
        type: ErrorType.conceptualMisunderstanding,
        source: DiagnosisSource.deterministic,
        createdAt: now.subtract(Duration(days: i)),
      ));
    }

    final suggestions = service.generateEvidenceSuggestions(state);
    expect(suggestions.any((s) => s.contains('Recurring')), isTrue);
    expect(suggestions.first, contains('conceptual'));
  });

  test('no evidence falls back to default suggestions from generateSuggestions', () async {
    final note = Note(
      id: 1,
      title: 'Due note',
      body: 'Body',
      kind: NoteKind.blurtSummary,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      card: fsrs.Card(cardId: 1, due: DateTime.now().subtract(const Duration(days: 1))),
    );
    await db.insertNote(note);
    state.notes = db.allNotes();

    final evidenceSugg = service.generateEvidenceSuggestions(state);
    expect(evidenceSugg, isEmpty);

    final regularSugg = service.generateSuggestions(state);
    expect(regularSugg, isNotEmpty);
    expect(regularSugg.any((s) => s.contains('due')), isTrue);
  });

  test('cap of 2 is respected even when all three evidence rules trigger', () async {
    final now = DateTime.now();
    // Rule 1: 3 errors
    for (int i = 1; i <= 3; i++) {
      await db.insertError(ErrorRecord(
        id: i,
        attemptId: i,
        type: ErrorType.formulaFailure,
        source: DiagnosisSource.user,
        createdAt: now,
      ));
    }

    // Rule 2: 3 delayed outcomes with lagging retention
    for (int i = 1; i <= 3; i++) {
      await db.insertDelayedOutcome(DelayedOutcome(
        id: i,
        knowledgeTargetId: 1,
        attemptId: i,
        measuredAt: now,
        bucket: DelayBucket.mediumDelay,
        elapsed: const Duration(days: 2),
        correctness: Correctness.incorrect,
        scorePct: 0.0,
      ));
      await db.insertAttempt(LearningAttempt(
        id: i,
        timestamp: now,
        knowledgeTargetId: 1,
        testType: TestType.freeRecall,
        correctness: Correctness.correct,
        scorePct: 100.0,
      ));
    }

    // Rule 3: Powered experiment
    await db.insertExperiment(Experiment(
      id: 1,
      hypothesis: 'Testing interleaving effect',
      startedAt: now.subtract(const Duration(days: 7)),
      conditions: const [
        ExperimentCondition(key: 'A', label: 'A', action: InterventionAction.retrieve),
        ExperimentCondition(key: 'B', label: 'B', action: InterventionAction.contrast),
      ],
      minAttemptsPerCondition: 1,
    ));

    final suggestions = service.generateEvidenceSuggestions(state, limit: 2);
    expect(suggestions.length, 2);
  });
}
