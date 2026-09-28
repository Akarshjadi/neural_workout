import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/delayed_outcome.dart';
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/intervention.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/session.dart';
import 'package:neural_workout/services/ai_scaffolding_service.dart';
import 'package:neural_workout/services/fsrs_engine.dart';
import 'package:neural_workout/services/local_ai_scorer.dart';
import 'package:neural_workout/services/metrics_service.dart';
import 'package:neural_workout/services/retrieval_engine.dart';

void main() {
  group('Phase 1 Core Services Parity', () {
    test('MetricsService alias and helper methods', () {
      final service = MetricsService();
      final now = DateTime(2026, 1, 1);
      final attempts = [
        LearningAttempt(id: 1, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 100.0, confidence: 100),
        LearningAttempt(id: 2, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 0.0, confidence: 80),
      ];
      expect(service.calculateBrierScore(attempts), greaterThanOrEqualTo(0.0));
      expect(service.calculateErrorRate(attempts), 0.5);

      final outcomes = [
        DelayedOutcome(
          id: 1,
          attemptId: 1,
          knowledgeTargetId: 1,
          bucket: DelayBucket.transfer,
          correctness: Correctness.correct,
          scorePct: 90.0,
          measuredAt: now,
          elapsed: const Duration(days: 7),
        ),
      ];
      expect(service.computeTransferScore(outcomes), 90.0);

      final sessions = [
        Session(id: 1, date: now, duration: const Duration(minutes: 20), stepsCompleted: 10),
      ];
      expect(service.calculatePerformanceDensity(sessions), 0.5);

      final interventions = [
        Intervention(id: 99, createdAt: now, action: InterventionAction.contrast, reason: InterventionReason.confusableTargets),
      ];
      final delayedAttempts = [
        LearningAttempt(id: 3, timestamp: now.add(const Duration(days: 2)), acquiredAt: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80.0, interventionId: 99),
      ];
      expect(service.computeInterventionResponsiveness(delayedAttempts, interventions), 80.0);
    });

    test('FsrsEngine aliases', () {
      final engine = FsrsEngine();
      final card = engine.newCard();
      expect(engine.computeStability(card), isNotNull);
      final nextReview = engine.calculateNextReview(card, Rating.good);
      expect(nextReview.card, isNotNull);
      expect(nextReview.rating, Rating.good);
    });

    test('RetrievalEngine computeState, identifyGaps, calculateOverlap', () {
      const engine = RetrievalEngine();
      final now = DateTime(2026, 1, 1);
      final note = Note(id: 1, title: 'Photosynthesis', body: 'Chloroplasts absorb sunlight.', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 1));

      expect(engine.computeState(note, []), 'unknown');
      final probable = [
        LearningAttempt(id: 1, knowledgeTargetId: 1, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
        LearningAttempt(id: 2, knowledgeTargetId: 1, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 95.0),
      ];
      expect(engine.computeState(note, probable), 'probable');
      expect(engine.identifyGaps(note, []), isNotEmpty);
      expect(engine.calculateOverlap('apple banana', 'banana orange'), greaterThan(0.0));
      expect(engine.calculateOverlap('', ''), 1.0);
    });

    test('AiScaffoldingService aliases', () {
      const service = AiScaffoldingService();
      final now = DateTime(2026, 1, 1);
      final noteA = Note(id: 1, title: 'A', body: 'Body A', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 1));
      final noteB = Note(id: 2, title: 'B', body: 'Body B', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 2));

      expect(service.generateScaffoldPrompt(note: noteA, level: ScaffoldingLevel.hint), contains('Hint:'));
      expect(service.generateContrastPrompt(a: noteA, b: noteB), 'How does "A" differ from "B"?');
      expect(service.generateAnalogyBridge(source: noteA, target: noteB), contains('structural analogy'));
    });

    test('LocalAiScorer key concepts, generatePrompt, diagnoseError, scoreExplanation', () async {
      final scorer = LocalAiScorer();
      expect(scorer.extractKeyConcepts('Photosynthesis converts sunlight'), contains('photosynthesis'));

      final now = DateTime(2026, 1, 1);
      final note = Note(id: 1, title: 'Concept', body: 'Body text', kind: NoteKind.blurtSummary, createdAt: now, updatedAt: now, card: Card(cardId: 1));
      expect(await scorer.generatePrompt(note: note, type: TestType.cuedRecall), isNotEmpty);
      expect(await scorer.diagnoseError(response: '', scorePct: 0), ErrorType.factualRecallFailure);
      expect(await scorer.scoreExplanation(response: 'test', source: 'test'), isA<double>());
      expect(() => scorer.semanticVectorSearch(query: 'q', candidates: [note]), throwsUnimplementedError);
    });
  });
}
