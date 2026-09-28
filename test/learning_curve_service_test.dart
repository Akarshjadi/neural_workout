import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/services/learning_curve_service.dart';

void main() {
  const service = LearningCurveService();

  test('buildTargetLearningCurve sorts and returns sequential data points', () {
    final attempts = [
      LearningAttempt(
        id: 1,
        knowledgeTargetId: 10,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.freeRecall,
        correctness: Correctness.partiallyCorrect,
        scorePct: 50.0,
        responseTimeMs: 8000,
        confidence: 60,
      ),
      LearningAttempt(
        id: 2,
        knowledgeTargetId: 10,
        timestamp: DateTime(2026, 1, 2),
        testType: TestType.freeRecall,
        correctness: Correctness.correct,
        scorePct: 90.0,
        responseTimeMs: 5000,
        confidence: 85,
      ),
    ];

    final curve = service.buildTargetLearningCurve(targetId: 10, attempts: attempts);
    expect(curve.length, equals(2));
    expect(curve[0].attemptIndex, equals(1));
    expect(curve[0].scorePct, equals(50.0));
    expect(curve[1].attemptIndex, equals(2));
    expect(curve[1].scorePct, equals(90.0));
  });

  test('computeEffectivenessMatrix computes accurate intervention yield across concept types', () {
    final intervention = Intervention(
      id: 1,
      createdAt: DateTime(2026, 1, 1),
      action: InterventionAction.explain,
      reason: InterventionReason.repeatedFailure,
    );

    final attempts = [
      LearningAttempt(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.explanation,
        correctness: Correctness.correct,
        scorePct: 80.0,
        interventionId: 1,
      ),
    ];

    final delayed = [
      DelayedOutcome(
        id: 1,
        knowledgeTargetId: 10,
        attemptId: 1,
        measuredAt: DateTime(2026, 1, 4),
        bucket: DelayBucket.mediumDelay,
        elapsed: const Duration(days: 3),
        correctness: Correctness.correct,
        scorePct: 85.0,
      ),
    ];

    final matrix = service.computeEffectivenessMatrix(
      attempts: attempts,
      delayedOutcomes: delayed,
      interventions: [intervention],
    );

    expect(matrix.isNotEmpty, isTrue);
    final row = matrix.firstWhere((r) => r.action == InterventionAction.explain);
    expect(row.meanImmediateScore, equals(80.0));
    expect(row.meanDelayedScore, equals(85.0));
  });
}
