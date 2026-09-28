import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/feedback_record.dart';
import 'package:neural_workout/models/focus_integrity.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cognitive_db_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Cognitive Engine Persistence & CRUD', () {
    test('Attempts insert, fetch, and filter by target', () async {
      final attempt = LearningAttempt(
        id: 0,
        timestamp: DateTime(2026, 3, 1, 10, 0),
        knowledgeTargetId: 42,
        testType: TestType.freeRecall,
        response: 'Active recall summary test',
        correctness: Correctness.correct,
        scorePct: 85.0,
        responseTimeMs: 14000,
        confidence: 4,
        difficulty: 3,
        wasInterleaved: true,
        interleaveGroupId: 'group_A',
      );

      final id = await db.insertAttempt(attempt);
      expect(id, isPositive);

      final fetched = db.attemptById(id);
      expect(fetched, isNotNull);
      expect(fetched!.knowledgeTargetId, 42);
      expect(fetched.testType, TestType.freeRecall);
      expect(fetched.correctness, Correctness.correct);
      expect(fetched.scorePct, 85.0);
      expect(fetched.responseTimeMs, 14000);
      expect(fetched.wasInterleaved, isTrue);
      expect(fetched.interleaveGroupId, 'group_A');

      final forTarget = db.attemptsForTarget(42);
      expect(forTarget.length, 1);
      expect(forTarget.first.id, id);
    });

    test('Feedback and Error records associate with attempts', () async {
      final attemptId = await db.insertAttempt(LearningAttempt(
        id: 0,
        timestamp: DateTime.now(),
        knowledgeTargetId: 10,
        testType: TestType.explanation,
        response: 'Partial explanation',
        correctness: Correctness.partiallyCorrect,
        scorePct: 50.0,
      ));

      final feedback = FeedbackRecord(
        id: 0,
        attemptId: attemptId,
        createdAt: DateTime.now(),
        correctness: Correctness.partiallyCorrect,
        scorePct: 50.0,
        correctPoints: ['Defined core term'],
        missing: ['Missed edge case'],
        incorrect: ['Reversed premise'],
        nextAction: 'Contrast with counter-example',
      );
      final fbId = await db.insertFeedback(feedback);
      expect(fbId, isPositive);

      final fetchedFb = db.feedbackForAttempt(attemptId);
      expect(fetchedFb, isNotNull);
      expect(fetchedFb!.correctPoints, ['Defined core term']);
      expect(fetchedFb.missing, ['Missed edge case']);
      expect(fetchedFb.incorrect, ['Reversed premise']);

      final error = ErrorRecord(
        id: 0,
        attemptId: attemptId,
        type: ErrorType.conceptualMisunderstanding,
        source: DiagnosisSource.deterministic,
        confidence: 0.9,
        evidence: 'Confused correlation with causation',
        createdAt: DateTime.now(),
      );
      await db.insertError(error);

      final errors = db.errorsForAttempt(attemptId);
      expect(errors.length, 1);
      expect(errors.first.type, ErrorType.conceptualMisunderstanding);
      expect(errors.first.evidence, contains('causation'));
    });
    test('Delayed outcomes and Interventions round-trip', () async {
      final outcome = DelayedOutcome(
        id: 0,
        knowledgeTargetId: 101,
        attemptId: 1,
        measuredAt: DateTime.now(),
        bucket: DelayBucket.mediumDelay,
        elapsed: const Duration(days: 3),
        correctness: Correctness.correct,
        scorePct: 90.0,
      );
      final oId = await db.insertDelayedOutcome(outcome);
      expect(oId, isPositive);

      final targetOutcomes = db.delayedOutcomesForTarget(101);
      expect(targetOutcomes.length, 1);
      expect(targetOutcomes.first.bucket, DelayBucket.mediumDelay);
      expect(targetOutcomes.first.elapsed.inDays, 3);

      final intervention = Intervention(
        id: 0,
        createdAt: DateTime.now(),
        action: InterventionAction.interleave,
        reason: InterventionReason.overconfidence,
        explanation: 'High confidence but poor delayed retention',
        knowledgeTargetId: 101,
      );
      final intId = await db.insertIntervention(intervention);
      expect(intId, isPositive);

      final allInts = db.allInterventions();
      expect(allInts.length, 1);
      expect(allInts.first.action, InterventionAction.interleave);
      expect(allInts.first.reason, InterventionReason.overconfidence);
    });

    test('Experiments and FocusIntegrity persistence', () async {
      final exp = Experiment(
        id: 0,
        hypothesis: 'Interleaving improves delayed transfer',
        conditions: const [
          ExperimentCondition(
            key: 'blocked',
            label: 'Blocked Practice',
            action: InterventionAction.retry,
          ),
          ExperimentCondition(
            key: 'interleaved',
            label: 'Interleaved Practice',
            action: InterventionAction.interleave,
          ),
        ],
        startedAt: DateTime.now(),
        active: true,
      );
      final expId = await db.insertExperiment(exp);
      expect(expId, isPositive);

      final activeExps = db.activeExperiments();
      expect(activeExps.length, 1);
      expect(activeExps.first.conditions.length, 2);
      expect(activeExps.first.hypothesis, contains('delayed transfer'));

      final focus = FocusIntegrity(
        sessionId: 77,
        plannedDuration: const Duration(minutes: 25),
        actualDuration: const Duration(minutes: 24),
        interruptions: 1,
        taskSwitches: 2,
        completed: true,
      );
      await db.upsertFocus(focus);

      final fetchedFocus = db.focusForSession(77);
      expect(fetchedFocus, isNotNull);
      expect(fetchedFocus!.interruptions, 1);
      expect(fetchedFocus.taskSwitches, 2);
      expect(fetchedFocus.completed, isTrue);

      await db.setConceptType(42, ConceptType.conceptualModel);
      expect(db.conceptTypeFor(42), ConceptType.conceptualModel);
    });
  });

  group('Migration v5 to v6 backfill', () {
    test('backfills legacy blurts and reviews into attempts box', () async {
      // Insert legacy blurt
      await db.insertBlurtScore(BlurtScore(
        id: 1,
        noteId: 5,
        noteTitle: 'Quantum Mechanics',
        date: DateTime(2026, 1, 1),
        scorePct: 80.0,
        matched: ['superposition'],
        missed: ['entanglement'],
        recallSpeedMs: 5000,
        depthScore: 70.0,
        clarityScore: 75.0,
      ));

      // Insert legacy review
      await db.insertReview(5, Rating.good);

      // Clear the backfill flag and set schema_version to 5 to simulate upgrade
      final meta = Hive.box('meta');
      await meta.put('schema_version', 5);
      await meta.delete('backfilled_attempts');
      final attemptsBox = Hive.box('attempts');
      await attemptsBox.clear();

      // Trigger ensureInitialized which invokes _migrateV5ToV6()
      await AppDatabase.ensureInitializedForTesting(tempDir.path);

      final backfilledAttempts = db.allAttempts();
      expect(backfilledAttempts.length, greaterThanOrEqualTo(2));

      final blurtAttempt = backfilledAttempts.firstWhere(
        (a) => a.testType == TestType.freeRecall && a.knowledgeTargetId == 5,
      );
      expect(blurtAttempt.scorePct, 80.0);
      expect(blurtAttempt.responseTimeMs, 5000);

      final reviewAttempt = backfilledAttempts.firstWhere(
        (a) => a.testType == TestType.cuedRecall && a.knowledgeTargetId == 5,
      );
      expect(reviewAttempt.correctness, Correctness.correct);
    });
  });
}

