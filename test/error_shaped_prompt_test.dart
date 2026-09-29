import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/services/adaptive_intervention_service.dart';
import 'package:neural_workout/services/session_policy_engine.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';

void main() {
  group('error-shaped prompt feature', () {
    final svc = AdaptiveInterventionService();
    final engine = SessionPolicyEngine();

    Note note() => Note(
          id: 1,
          title: 'x',
          body: 'Alpha is the first letter.\nAlpha precedes beta.',
          kind: NoteKind.cheatSheet,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          card: Card(cardId: 1),
        );

    KnowledgeEvidence evidence() => const KnowledgeEvidence(
          knowledgeTargetId: 1,
          state: KnowledgeState.developing,
          evidence: EvidenceSummary(retrievalAttempts: 1, retrievalSuccesses: 0),
          rationale: 'test fixture',
          confidence: 0.2,
        );

    ErrorRecord err(ErrorType type, int n) => ErrorRecord(
          id: n,
          attemptId: n,
          type: type,
          source: DiagnosisSource.deterministic,
          createdAt: DateTime(2026),
        );

    test('retrieval-family error on fresh target -> cued recall prompt', () {
      final intervention = svc.decideIntervention(
        targetId: 1,
        targetAttempts: [],
        targetErrors: [err(ErrorType.retrievalFailure, 1)],
        knowledgeState: KnowledgeState.developing,
      );
      expect(intervention.reason, InterventionReason.retrievalError);
      expect(intervention.testTypeOverride, TestType.cuedRecall);

      final step = engine.planStep(conceptType: ConceptType.definition,
        note: note(),
        noteAttempts: [],
        noteErrors: [err(ErrorType.retrievalFailure, 1)],
        noteDelayedOutcomes: [],
        knowledgeEvidence: evidence(),
        contrastNote: null,
      );
      expect(step.prompt.question, isNotEmpty);
      expect(intervention.effectiveTestType, TestType.cuedRecall);
    });

    test('attention-family error -> focusReset, timerSeconds == 60', () {
      final intervention = svc.decideIntervention(
        targetId: 1,
        targetAttempts: [],
        targetErrors: [err(ErrorType.carelessError, 1)],
        knowledgeState: KnowledgeState.developing,
      );
      expect(intervention.reason, InterventionReason.attentionError);
      expect(intervention.action, InterventionAction.focusReset);
      expect(intervention.testTypeOverride, TestType.freeRecall);

      final step = engine.planStep(conceptType: ConceptType.definition,
        note: note(),
        noteAttempts: [],
        noteErrors: [err(ErrorType.carelessError, 1)],
        noteDelayedOutcomes: [],
        knowledgeEvidence: evidence(),
        contrastNote: null,
      );
      expect(step.thresholds['timer_seconds'], 60);
    });

    test('three failures -> workedExample, no override', () {
      final intervention = svc.decideIntervention(
        targetId: 1,
        targetAttempts: [
          LearningAttempt(
            id: 1,
            knowledgeTargetId: 1,
            timestamp: DateTime(2026),
            testType: TestType.freeRecall,
            correctness: Correctness.incorrect,
            responseTimeMs: 10000,
          ),
          LearningAttempt(
            id: 2,
            knowledgeTargetId: 1,
            timestamp: DateTime(2026),
            testType: TestType.freeRecall,
            correctness: Correctness.incorrect,
            responseTimeMs: 10000,
          ),
          LearningAttempt(
            id: 3,
            knowledgeTargetId: 1,
            timestamp: DateTime(2026),
            testType: TestType.freeRecall,
            correctness: Correctness.incorrect,
            responseTimeMs: 10000,
          ),
        ],
        targetErrors: [
          err(ErrorType.factualRecallFailure, 1),
          err(ErrorType.factualRecallFailure, 2),
          err(ErrorType.factualRecallFailure, 3),
        ],
        knowledgeState: KnowledgeState.developing,
      );
      expect(intervention.action, InterventionAction.workedExample);
      expect(intervention.testTypeOverride, isNull);
    });

    test('confusedConcepts takes precedence over retrieval rule', () {
      final intervention = svc.decideIntervention(
        targetId: 1,
        targetAttempts: [],
        targetErrors: [
          err(ErrorType.factualRecallFailure, 1),
          err(ErrorType.confusedConcepts, 2),
        ],
        knowledgeState: KnowledgeState.developing,
        contrastTargetId: 2,
      );
      expect(intervention.action, InterventionAction.contrast);
    });

    test('clean target -> baseline concept-type match preserved', () {
      final intervention = svc.decideIntervention(
        targetId: 1,
        targetAttempts: [],
        targetErrors: [],
        knowledgeState: KnowledgeState.developing,
      );
      expect(intervention.action, InterventionAction.retrieve);
      expect(intervention.testTypeOverride, isNull);
    });

    test('intervention with no override uses action default', () {
      final intervention = Intervention(
        id: 0,
        createdAt: DateTime.now(),
        action: InterventionAction.workedExample,
        reason: InterventionReason.persistentFailure,
        explanation: 'test',
        thresholds: const {},
        testTypeOverride: null,
      );
      expect(intervention.effectiveTestType, TestType.workedExample);
    });
  });
}