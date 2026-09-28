import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/adaptive_intervention_service.dart';
import 'package:neural_workout/services/session_policy_engine.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  group('Empirical Intervention Matching', () {
    const service = AdaptiveInterventionService();

    test('empty empirical list falls back to heuristic matching', () {
      final heuristic = service.matchByConceptType(
        targetId: 1,
        conceptType: ConceptType.definition,
      );
      final empirical = service.matchByEmpiricalData(
        targetId: 1,
        conceptType: ConceptType.definition,
        empirical: const [],
      );

      expect(empirical.action, heuristic.action);
      expect(empirical.action, InterventionAction.retrieve);
    });

    test('empirical match selects highest mean delayed score when sampleSize >= minSamples', () {
      final matches = [
        const InterventionConceptMatch(
          action: InterventionAction.contrast,
          conceptType: ConceptType.definition,
          meanDelayedScore: 82.0,
          sampleSize: 5,
        ),
        const InterventionConceptMatch(
          action: InterventionAction.retrieve,
          conceptType: ConceptType.definition,
          meanDelayedScore: 60.0,
          sampleSize: 4,
        ),
      ];

      final selected = service.matchByEmpiricalData(
        targetId: 1,
        conceptType: ConceptType.definition,
        empirical: matches,
        minSamples: 3,
      );

      expect(selected.action, InterventionAction.contrast);
      expect(selected.reason, InterventionReason.experimentAssignment);
      expect(selected.explanation, contains('82.0%'));
    });

    test('underpowered empirical sample (< minSamples) falls back to heuristic', () {
      final matches = [
        const InterventionConceptMatch(
          action: InterventionAction.contrast,
          conceptType: ConceptType.definition,
          meanDelayedScore: 95.0,
          sampleSize: 2, // below minSamples of 3
        ),
      ];

      final selected = service.matchByEmpiricalData(
        targetId: 1,
        conceptType: ConceptType.definition,
        empirical: matches,
        minSamples: 3,
      );

      expect(selected.action, InterventionAction.retrieve); // default definition heuristic
    });

    test('SessionPolicyEngine threads empirical matches', () {
      const engine = SessionPolicyEngine();
      final now = DateTime(2026, 1, 1);
      final note = Note(
        id: 1,
        title: 'Definition concept',
        body: 'Body',
        kind: NoteKind.blurtSummary,
        createdAt: now,
        updatedAt: now,
        card: fsrs.Card(cardId: 1),
      );
      const evidence = KnowledgeEvidence(
        knowledgeTargetId: 1,
        state: KnowledgeState.stable,
        evidence: EvidenceSummary(retrievalSuccesses: 3),
        rationale: 'Stable',
        confidence: 0.8,
      );

      final matches = [
        const InterventionConceptMatch(
          action: InterventionAction.explain,
          conceptType: ConceptType.definition,
          meanDelayedScore: 88.0,
          sampleSize: 5,
        ),
      ];

      final step = engine.planStep(
        note: note,
        noteAttempts: [],
        noteErrors: [],
        noteDelayedOutcomes: [],
        knowledgeEvidence: evidence,
        empirical: matches,
      );

      expect(step.intervention.action, InterventionAction.explain);
    });
  });
}
