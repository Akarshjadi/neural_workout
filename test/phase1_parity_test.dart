import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/plasticity_service.dart';
import 'package:neural_workout/utils/force_layout.dart';
import 'package:neural_workout/widgets/visuals/visual_semantics.dart';

void main() {
  group('Phase 1 Models and Visual Parity', () {
    test('LearningAttempt alias getters', () {
      final attempt = LearningAttempt(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.freeRecall,
        correctness: Correctness.correct,
        scorePct: 85.0,
        responseTimeMs: 2500,
        confidence: 90,
      );
      expect(attempt.latencyMs, 2500);
      expect(attempt.accuracyScore, 85.0);
      expect(attempt.confidenceRating, 90);
      expect(attempt.immediateRecallRate, 85.0);
    });

    test('ErrorRecord aliases and confusedConceptId', () {
      final userErr = ErrorRecord(
        id: 1,
        attemptId: 10,
        type: ErrorType.confusedConcepts,
        source: DiagnosisSource.user,
        createdAt: DateTime(2026, 1, 1),
        confusedConceptId: 42,
      );
      expect(userErr.selfDiagnosedCategory, ErrorType.confusedConcepts);
      expect(userErr.systemDiagnosedCategory, ErrorType.unknown);
      expect(userErr.isDisagreement, isFalse);
      expect(userErr.confusedConceptId, 42);

      final sysErr = ErrorRecord(
        id: 2,
        attemptId: 10,
        type: ErrorType.retrievalFailure,
        source: DiagnosisSource.deterministic,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(sysErr.selfDiagnosedCategory, ErrorType.unknown);
      expect(sysErr.systemDiagnosedCategory, ErrorType.retrievalFailure);
    });

    test('Intervention cascade and helper models', () {
      expect(cascadeStageFor(0), InterventionCascadeStage.none);
      expect(cascadeStageFor(1), InterventionCascadeStage.firstFailure);
      expect(cascadeStageFor(2), InterventionCascadeStage.repeated);
      expect(cascadeStageFor(3), InterventionCascadeStage.persistent);
      expect(cascadeStageFor(4), InterventionCascadeStage.workedExample);

      const outcome = InterventionOutcome(
        interventionId: 1,
        sampleSize: 5,
        delayedDelta: 10.5,
      );
      expect(outcome.delayedDelta, 10.5);

      const match = InterventionConceptMatch(
        action: InterventionAction.explain,
        conceptType: ConceptType.definition,
        meanDelayedScore: 85.0,
        sampleSize: 4,
      );
      expect(match.meanDelayedScore, 85.0);
    });

    test('VisualSemantics paint factory aliases', () {
      expect(VisualSemantics.observedPaint().style, PaintingStyle.stroke);
      expect(VisualSemantics.estimatedPaint().style, PaintingStyle.stroke);
      expect(VisualSemantics.projectedPaint().style, PaintingStyle.fill);
      expect(VisualSemantics.hypotheticalPaint().style, PaintingStyle.fill);
    });

    test('ForceLayout clusterNodes and generateLayout', () {
      final nodes = [LayoutNode(1), LayoutNode(2), LayoutNode(3), LayoutNode(4)];
      final edges = [LayoutEdge(1, 2), LayoutEdge(3, 4)];
      expect(ForceLayout.clusterNodes(nodes, edges).length, 2);
      ForceLayout.generateLayout(nodes, edges);
      expect(nodes[0].x.isFinite, isTrue);
    });

    test('Experiment static helper methods', () {
      final now = DateTime(2026, 1, 1);
      final exp = Experiment(
        id: 1,
        hypothesis: 'Hypothesis',
        startedAt: now,
        endedAt: now.add(const Duration(days: 3)),
        conditions: const [
          ExperimentCondition(key: 'A', label: 'Arm A', action: InterventionAction.retrieve),
        ],
      );
      expect(Experiment.timelineEvents(exp).length, 2);

      final comp = ExperimentComparison(
        experiment: exp,
        quality: ComparisonQuality.controlled,
        qualityReason: 'Ok',
        underpowered: false,
        delayedDelta: 8.0,
        results: const [
          ConditionResult(
            conditionKey: 'A',
            delayedAttempts: 5,
            successes: 4,
            meanDelayedScore: 80.0,
            meanImmediateScore: 85.0,
            immediateAttempts: 5,
          ),
        ],
      );
      expect(Experiment.baselineAccuracy(comp, 'A'), 4 / 5);
      expect(Experiment.delayedRetentionDelta(comp), 8.0);
      expect(Experiment.outcomeSummary(comp), contains('controlled'));
    });

    test('PlasticityProfile disclaimer property', () {
      const profile = PlasticityProfile(
        speed: CognitiveSpeedResult(currentMs: 2000, slopePerDay: -5, trend: 'stable', isLearning: false),
        recovery: RecoveryReserveResult(index0to100: 80, isLearning: false),
        difficulty: DifficultyResult(index0to100: 75, detail: 'balanced', isLearning: false),
        network: NetworkResult(index0to100: 60, linked: 3, total: 5, components: 1),
        mindfulness: MindfulnessResult(index0to100: 90, isLearning: false),
        overall0to100: 78,
      );
      expect(profile.disclaimer, contains('Behavioral proxies only'));
      expect(profile.toJson()['disclaimer'], contains('Behavioral proxies only'));
    });

    test('Note linkIds property and copyWith', () {
      final now = DateTime(2026, 1, 1);
      final note = Note(
        id: 1,
        title: 'QC',
        body: 'Qubits',
        kind: NoteKind.blurtSummary,
        createdAt: now,
        updatedAt: now,
        card: Card(cardId: 1),
        linkIds: const [2, 3],
      );
      expect(note.linkIds, [2, 3]);
      expect(note.copyWith(linkIds: [2, 3, 4]).linkIds, [2, 3, 4]);
    });
  });
}
