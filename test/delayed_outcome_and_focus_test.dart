import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/ai_scaffolding_service.dart';
import 'package:neural_workout/services/context_focus_service.dart';
import 'package:neural_workout/services/delayed_outcome_service.dart';
import 'package:neural_workout/services/experiment_service.dart';
import 'package:neural_workout/services/session_policy_engine.dart';

void main() {
  test('DelayedOutcomeService computes due status and retention curves', () {
    const svc = DelayedOutcomeService();
    final acquiredAt = DateTime.now().subtract(const Duration(days: 3));
    final attempt = LearningAttempt(
      id: 1,
      timestamp: acquiredAt,
      knowledgeTargetId: 10,
      testType: TestType.freeRecall,
      correctness: Correctness.correct,
      scorePct: 90,
    );

    final isDue = svc.isDueForDelayedTest(
      sourceAttempt: attempt,
      existingOutcomes: [],
      now: DateTime.now(),
    );
    expect(isDue, isTrue);

    final outcomes = [
      DelayedOutcome(
        id: 1,
        knowledgeTargetId: 10,
        attemptId: 2,
        measuredAt: DateTime.now(),
        bucket: DelayBucket.mediumDelay,
        elapsed: const Duration(days: 3),
        correctness: Correctness.correct,
        scorePct: 85.0,
      ),
    ];

    final curve = svc.computeRetentionCurve(outcomes);
    expect(curve.mediumDelayAccuracy, equals(85.0));
  });

  test('AiScaffoldingService escalates and fades assistance', () {
    const svc = AiScaffoldingService();
    expect(svc.escalate(ScaffoldingLevel.none), equals(ScaffoldingLevel.hint));
    expect(svc.escalate(ScaffoldingLevel.hint), equals(ScaffoldingLevel.targetedQuestion));
    expect(svc.fade(ScaffoldingLevel.targetedQuestion), equals(ScaffoldingLevel.hint));
    expect(svc.fade(ScaffoldingLevel.hint), equals(ScaffoldingLevel.none));
  });

  test('ContextFocusService calculates focus integrity and interruption cost', () {
    const svc = ContextFocusService();
    final focus = svc.evaluateSessionFocus(
      actualDuration: const Duration(minutes: 25),
      interruptions: 2,
      taskSwitches: 1,
      completed: true,
      abandoned: false,
    );
    expect(focus.completed, isTrue);
    expect(focus.interruptions, equals(2));

    final preAttempts = [
      LearningAttempt(id: 1, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90),
    ];
    final postAttempts = [
      LearningAttempt(id: 2, timestamp: DateTime.now(), testType: TestType.freeRecall, correctness: Correctness.partiallyCorrect, scorePct: 60),
    ];
    final cost = svc.calculateInterruptionCost(
      preInterruptionAttempts: preAttempts,
      postInterruptionAttempts: postAttempts,
    );
    expect(cost, equals(30.0));
  });

  test('ExperimentService evaluates personal A/B experiments with power guards', () {
    const expSvc = ExperimentService();
    final exp = Experiment(
      id: 1,
      hypothesis: 'Does contrastive retrieval improve 7-day retention?',
      conditions: const [
        ExperimentCondition(key: 'A', label: 'Standard Retrieval', action: InterventionAction.retrieve),
        ExperimentCondition(key: 'B', label: 'Contrastive Retrieval', action: InterventionAction.contrast),
      ],
      startedAt: DateTime(2026, 1, 1),
      minAttemptsPerCondition: 2,
    );

    final attempts = [
      LearningAttempt(id: 1, timestamp: DateTime(2026, 1, 1), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80, extras: {'experiment_condition': 'A'}),
      LearningAttempt(id: 2, timestamp: DateTime(2026, 1, 1), testType: TestType.discrimination, correctness: Correctness.correct, scorePct: 90, extras: {'experiment_condition': 'B'}),
    ];

    final comparison = expSvc.evaluateExperiment(
      experiment: exp,
      attempts: attempts,
      delayedOutcomes: [],
    );

    expect(comparison.underpowered, isTrue);
    expect(comparison.quality, equals(ComparisonQuality.observational));
  });

  test('SessionPolicyEngine plans integrated session step', () {
    const policy = SessionPolicyEngine();
    final note = Note(
      id: 1,
      title: 'Attention Mechanism',
      body: 'Query, Key, Value vectors compute attention weights via softmax.',
      kind: NoteKind.cheatSheet,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      card: Card(cardId: 1),
    );

    final step = policy.planStep(conceptType: ConceptType.definition,
      note: note,
      noteAttempts: [],
      noteErrors: [],
      noteDelayedOutcomes: [],
      knowledgeEvidence: const KnowledgeEvidence(
        knowledgeTargetId: 1,
        state: KnowledgeState.developing,
        evidence: EvidenceSummary(),
        rationale: 'Initial state',
        confidence: 0.1,
      ),
    );

    expect(step.targetNote.id, equals(1));
    expect(step.prompt.question.isNotEmpty, isTrue);
    expect(step.scaffoldLevel, equals(ScaffoldingLevel.none));
  });
}
