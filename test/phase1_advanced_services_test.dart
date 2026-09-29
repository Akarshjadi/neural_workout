import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/experiment.dart';
import 'package:neural_workout/models/focus_integrity.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/services/context_focus_service.dart';
import 'package:neural_workout/services/experiment_service.dart';
import 'package:neural_workout/services/session_policy_engine.dart';

void main() {
  group('Phase 1 Advanced Services Parity', () {
    test('ExperimentService helpers and statistics', () {
      const service = ExperimentService();
      final now = DateTime(2026, 1, 1);
      final exp = Experiment(
        id: 1,
        hypothesis: 'Hypothesis',
        startedAt: now,
        conditions: const [
          ExperimentCondition(key: 'A', label: 'A', action: InterventionAction.retrieve),
          ExperimentCondition(key: 'B', label: 'B', action: InterventionAction.explain),
        ],
      );

      expect(service.assignIntervention(experiment: exp, attemptCount: 2).key, 'A');

      final d = service.computeCohenD(groupA: [100.0, 90.0, 95.0], groupB: [60.0, 70.0, 65.0]);
      expect(d, isNotNull);

      final ab = service.runABComparison(experiment: exp, attempts: [], delayedOutcomes: []);
      expect(ab.significant, isFalse);

      final responsiveness = service.computeInterventionResponsiveness(attempts: [], interventions: []);
      expect(responsiveness, 0.0);

      

    final ea = service.effectivenessByActionAndConcept(
      attempts: [],
      delayedOutcomes: [],
      interventions: [],
      conceptTypeByNote: {},
    );
    expect(ea.isEmpty, isTrue);
    });

    test('SessionPolicyEngine duration and break heuristics', () {
      const engine = SessionPolicyEngine();
      final evidence = const KnowledgeEvidence(
        knowledgeTargetId: 1,
        state: KnowledgeState.verified,
        evidence: EvidenceSummary(retrievalSuccesses: 5, delayedSuccesses: 3),
        rationale: 'Verified',
        confidence: 0.9,
      );
      final duration = engine.recommendSessionDuration(
        evidence: evidence,
        focusHistory: [const FocusIntegrity(actualDuration: Duration(minutes: 25))],
      );
      expect(duration.inMinutes, inInclusiveRange(10, 45));

      final timing = engine.recommendBreakTiming(
        sessionElapsed: const Duration(minutes: 30),
        evidence: evidence,
      );
      expect(timing.inMinutes, 35);
    });

    test('ContextFocusService time of day and circadian curves', () {
      const service = ContextFocusService();
      final attempts = [
        LearningAttempt(id: 1, timestamp: DateTime(2026, 1, 1, 8, 30), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80.0),
      ];
      final tod = service.analyzeTimeOfDay(attempts: attempts);
      expect(tod['morning'], 80.0);

      final todRec = service.timeOfDayComparison(attempts: attempts);
      expect(todRec.morning, 80.0);

      final curve = service.circadianCurve(attempts: attempts);
      expect(curve.length, 24);
      expect(curve[8].meanScore, 80.0);
    });
  });
}
