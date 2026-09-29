import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/services/adaptive_intervention_service.dart';
import 'package:neural_workout/services/delayed_outcome_service.dart';
import 'dart:io';

void main() {
  group('learner trajectory', () {
    late Directory tempDir;
    late AdaptiveInterventionService adaptive;
    late DelayedOutcomeService delayedService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('learner_trajectory_test_');
      await AppDatabase.ensureInitializedForTesting(tempDir.path);
      adaptive = const AdaptiveInterventionService();
      delayedService = const DelayedOutcomeService();
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('Failure cascade escalates correctly', () {
      final t0 = DateTime(2026, 1, 1);
      final attempts = [
        LearningAttempt(id: 3, timestamp: t0.add(const Duration(days: 2)), correctness: Correctness.incorrect, scorePct: 10, testType: TestType.freeRecall, response: ''),
        LearningAttempt(id: 2, timestamp: t0.add(const Duration(days: 1)), correctness: Correctness.incorrect, scorePct: 20, testType: TestType.freeRecall, response: ''),
        LearningAttempt(id: 1, timestamp: t0, correctness: Correctness.incorrect, scorePct: 15, testType: TestType.freeRecall, response: ''),
      ];
      final res = adaptive.decideIntervention(
        targetId: 1,
        targetAttempts: attempts,
        targetErrors: [],
        knowledgeState: KnowledgeState.developing,
      );
      expect(res.action, InterventionAction.workedExample);
      expect(res.reason, InterventionReason.persistentFailure);
    });

    test('Confusion routes to contrast, not retry', () {
      final t0 = DateTime(2026, 1, 1);
      final attempt = LearningAttempt(id: 1, timestamp: t0, correctness: Correctness.incorrect, scorePct: 20, testType: TestType.freeRecall, response: '');
      
      final error1 = ErrorRecord(id: 1, attemptId: 1, type: ErrorType.confusedConcepts, source: DiagnosisSource.deterministic, confidence: 1.0, evidence: '', createdAt: t0, confusedConceptId: 2);
      
      final res1 = adaptive.decideIntervention(
        targetId: 1,
        targetAttempts: [attempt],
        targetErrors: [error1],
        knowledgeState: KnowledgeState.developing,
        contrastTargetId: 2,
      );
      expect(res1.action, InterventionAction.contrast);
      expect(res1.reason, InterventionReason.confusableTargets);

      final error2 = ErrorRecord(id: 2, attemptId: 1, type: ErrorType.misread, source: DiagnosisSource.deterministic, confidence: 1.0, evidence: '', createdAt: t0);
      final res2 = adaptive.decideIntervention(
        targetId: 1,
        targetAttempts: [attempt],
        targetErrors: [error2],
        knowledgeState: KnowledgeState.developing,
        contrastTargetId: 2,
      );
      expect(res2.action, InterventionAction.focusReset, reason: 'calculationError should flip to focusReset');

      final error3 = ErrorRecord(id: 3, attemptId: 1, type: ErrorType.retrievalFailure, source: DiagnosisSource.deterministic, confidence: 1.0, evidence: '', createdAt: t0);
      final res3 = adaptive.decideIntervention(
        targetId: 1,
        targetAttempts: [attempt],
        targetErrors: [error3],
        knowledgeState: KnowledgeState.developing,
        contrastTargetId: 2,
      );
      expect(res3.testTypeOverride, TestType.cuedRecall);
    });

    test('Delayed test becomes due at the right boundary', () {
      final t0 = DateTime(2026, 1, 1);
      final attempt = LearningAttempt(id: 1, timestamp: t0, correctness: Correctness.correct, scorePct: 100, testType: TestType.freeRecall, response: '');
      
      final due0 = delayedService.isDueForDelayedTest(sourceAttempt: attempt, existingOutcomes: [], now: t0);
      expect(due0, isFalse);

      final t3 = t0.add(const Duration(days: 3));
      final due3 = delayedService.isDueForDelayedTest(sourceAttempt: attempt, existingOutcomes: [], now: t3);
      expect(due3, isTrue);

      final outcome = DelayedOutcome(id: 1, knowledgeTargetId: 1, attemptId: 1, measuredAt: t3, bucket: DelayBucket.mediumDelay, elapsed: const Duration(days: 3), correctness: Correctness.correct, scorePct: 100);
      final due3b = delayedService.isDueForDelayedTest(sourceAttempt: attempt, existingOutcomes: [outcome], now: t3);
      expect(due3b, isFalse);
    });

    test('Empirical matching beats heuristic once n >= 3', () {
      final m1 = InterventionConceptMatch(action: InterventionAction.workedExample, conceptType: ConceptType.procedure, meanDelayedScore: 0.9, sampleSize: 3);
      final m2Match = InterventionConceptMatch(action: InterventionAction.application, conceptType: ConceptType.procedure, meanDelayedScore: 0.4, sampleSize: 3);
      
      final res1 = adaptive.matchByEmpiricalData(targetId: 1, conceptType: ConceptType.procedure, empirical: [m1, m2Match], minSamples: 3);
      expect(res1.action, InterventionAction.workedExample);

      final res2 = adaptive.decideIntervention(
        targetId: 1,
        targetAttempts: [],
        targetErrors: [],
        knowledgeState: KnowledgeState.developing,
        conceptType: ConceptType.procedure,
        empiricalMatches: [m1, m2Match],
        minSamples: 5,
      );
      expect(res2.action, InterventionAction.application);
    });
  });
}