import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/adaptive_intervention_service.dart';

void main() {
  const service = AdaptiveInterventionService();

  test('failure-triggered switching switches to explanation on repeated errors', () {
    final attempts = [
      LearningAttempt(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        scorePct: 20,
      ),
      LearningAttempt(
        id: 2,
        timestamp: DateTime(2026, 1, 2),
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        scorePct: 30,
      ),
    ];

    final inv = service.decideIntervention(
      targetId: 1,
      targetAttempts: attempts,
      targetErrors: [],
      knowledgeState: KnowledgeState.developing,
    );

    expect(inv.action, equals(InterventionAction.explain));
    expect(inv.reason, equals(InterventionReason.repeatedFailure));
  });

  test('switches to worked example on persistent (3+) failures', () {
    final attempts = [
      LearningAttempt(id: 1, timestamp: DateTime(2026, 1, 1), testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 10),
      LearningAttempt(id: 2, timestamp: DateTime(2026, 1, 2), testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 10),
      LearningAttempt(id: 3, timestamp: DateTime(2026, 1, 3), testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 10),
    ];

    final inv = service.decideIntervention(
      targetId: 1,
      targetAttempts: attempts,
      targetErrors: [],
      knowledgeState: KnowledgeState.developing,
    );

    expect(inv.action, equals(InterventionAction.workedExample));
    expect(inv.reason, equals(InterventionReason.persistentFailure));
  });

  test('switches to contrastive retrieval when errors show confused concepts', () {
    final attempts = [
      LearningAttempt(id: 1, timestamp: DateTime(2026, 1, 1), testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 40),
    ];
    final errors = [
      ErrorRecord(
        id: 1,
        attemptId: 1,
        type: ErrorType.confusedConcepts,
        source: DiagnosisSource.deterministic,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final inv = service.decideIntervention(
      targetId: 1,
      targetAttempts: attempts,
      targetErrors: errors,
      knowledgeState: KnowledgeState.developing,
      contrastTargetId: 2,
    );

    expect(inv.action, equals(InterventionAction.contrast));
    expect(inv.reason, equals(InterventionReason.confusableTargets));
  });

  test('concept type matching maps procedural concepts to application', () {
    final inv = service.matchByConceptType(
      targetId: 1,
      conceptType: ConceptType.procedure,
    );
    expect(inv.action, equals(InterventionAction.application));
  });

  test('planMeaningfulInterleaving groups related graph notes with rationale', () {
    final note1 = Note(id: 1, title: 'BFS', body: 'Breadth first search', kind: NoteKind.cheatSheet, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1), card: Card(cardId: 1));
    final note2 = Note(id: 2, title: 'DFS', body: 'Depth first search', kind: NoteKind.cheatSheet, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1), card: Card(cardId: 2));

    final block = service.planMeaningfulInterleaving(
      primaryNote: note1,
      availableNotes: [note1, note2],
      graphAdjacency: {1: [2], 2: [1]},
    );

    expect(block, isNotNull);
    expect(block!.targetNotes.length, equals(2));
    expect(block.rationale, contains('graph connections'));
  });

  test('computeNetFrictionYield calculates net intervention gain', () {
    final yieldScore = service.computeNetFrictionYield(
      delayedRetentionGainPct: 15.0,
      timeSpent: const Duration(minutes: 10),
      subjectiveFriction: 1.5,
    );
    // 15.0 - (10 * 0.1 + 1.5) = 15.0 - 2.5 = 12.5
    expect(yieldScore, closeTo(12.5, 0.01));
  });
}
