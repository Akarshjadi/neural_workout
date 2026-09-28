import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/services/feedback_diagnosis_service.dart';

void main() {
  const service = FeedbackDiagnosisService();

  test('generateFeedback builds structured FeedbackRecord with correct and missing points', () {
    final fb = service.generateFeedback(
      attemptId: 10,
      response: 'We apply chain rule to gradients',
      expectedPoints: ['Compute gradient of loss', 'Apply chain rule across layers', 'Update weights'],
    );
    expect(fb.attemptId, equals(10));
    expect(fb.correctPoints.isNotEmpty, isTrue);
    expect(fb.missing.isNotEmpty, isTrue);
    expect(fb.nextAction.isNotEmpty, isTrue);
  });

  test('diagnoseError identifies error categories deterministically', () {
    final err1 = service.diagnoseError(response: '', scorePct: 0);
    expect(err1, equals(ErrorType.factualRecallFailure));

    final err2 = service.diagnoseError(response: 'idk', scorePct: 0);
    expect(err2, equals(ErrorType.retrievalFailure));

    final err3 = service.diagnoseError(
      response: 'Totally wrong premise',
      scorePct: 20,
      confidence: 90,
    );
    expect(err3, equals(ErrorType.conceptualMisunderstanding));
  });

  test('compareDiagnosis tracks agreement and disagreement', () {
    final comp1 = service.compareDiagnosis(
      attemptId: 1,
      userDiagnosis: ErrorType.conceptualMisunderstanding,
      systemDiagnosis: ErrorType.confusedConcepts,
    );
    expect(comp1.isAgreed, isTrue, reason: 'Both are in the conceptual family');

    final comp2 = service.compareDiagnosis(
      attemptId: 2,
      userDiagnosis: ErrorType.carelessError,
      systemDiagnosis: ErrorType.conceptualMisunderstanding,
    );
    expect(comp2.isAgreed, isFalse);
  });

  test('calculateCalibration produces Brier score and over/underconfidence counts', () {
    final attempts = [
      LearningAttempt(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.freeRecall,
        correctness: Correctness.correct,
        scorePct: 90.0,
        confidence: 90,
      ),
      LearningAttempt(
        id: 2,
        timestamp: DateTime(2026, 1, 2),
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        scorePct: 10.0,
        confidence: 80, // overconfident
      ),
      LearningAttempt(
        id: 3,
        timestamp: DateTime(2026, 1, 3),
        testType: TestType.freeRecall,
        correctness: Correctness.correct,
        scorePct: 95.0,
        confidence: 40, // underconfident
      ),
    ];

    final metrics = service.calculateCalibration(attempts);
    expect(metrics.totalJudgments, equals(3));
    expect(metrics.overconfidentCount, equals(1));
    expect(metrics.underconfidentCount, equals(1));
    expect(metrics.wellCalibratedCount, equals(1));
    expect(metrics.brierScore, greaterThan(0.0));
  });

  test('detectMetacognitiveLaziness flags consecutive low-effort responses', () {
    final attempts = [
      LearningAttempt(
        id: 1,
        timestamp: DateTime(2026, 1, 1),
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        response: 'idk',
      ),
      LearningAttempt(
        id: 2,
        timestamp: DateTime(2026, 1, 2),
        testType: TestType.freeRecall,
        correctness: Correctness.incorrect,
        response: 'dunno',
      ),
    ];

    final alert = service.detectMetacognitiveLaziness(attempts);
    expect(alert, isNotNull);
    expect(alert, contains('Friction Rule Triggered'));
  });
}
