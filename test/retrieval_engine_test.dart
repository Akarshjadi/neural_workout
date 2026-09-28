import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/retrieval_engine.dart';

void main() {
  const engine = RetrievalEngine();
  final testNote = Note(
    id: 1,
    title: 'Backpropagation',
    body: '- Compute gradient of the loss function\n- Apply chain rule across layers\n- Update weights with learning rate',
    kind: NoteKind.cheatSheet,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    card: Card(cardId: 1),
  );

  test('generates free recall prompt', () {
    final prompt = engine.generatePrompt(note: testNote, testType: TestType.freeRecall);
    expect(prompt.testType, equals(TestType.freeRecall));
    expect(prompt.targetTitle, equals('Backpropagation'));
    expect(prompt.question, contains('Recall everything'));
  });

  test('generates cued recall prompt with expected key points', () {
    final prompt = engine.generatePrompt(note: testNote, testType: TestType.cuedRecall);
    expect(prompt.testType, equals(TestType.cuedRecall));
    expect(prompt.expectedKeyPoints.isNotEmpty, isTrue);
  });

  test('generates contrastive discrimination prompt with contrast note', () {
    final contrastNote = Note(
      id: 2,
      title: 'Feedforward',
      body: 'Propagate inputs forward through layers',
      kind: NoteKind.cheatSheet,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      card: Card(cardId: 2),
    );

    final prompt = engine.generatePrompt(
      note: testNote,
      testType: TestType.discrimination,
      contrastNote: contrastNote,
    );
    expect(prompt.testType, equals(TestType.discrimination));
    expect(prompt.contrastTargetTitle, equals('Feedforward'));
    expect(prompt.question, contains('differ from "Feedforward"'));
  });

  test('generates reconstruction faded steps prompt', () {
    final prompt = engine.generatePrompt(
      note: testNote,
      testType: TestType.reconstruction,
      fadedStepLevel: 1,
    );
    expect(prompt.testType, equals(TestType.reconstruction));
    expect(prompt.fadedSteps.last, contains('Complete this step'));
  });

  test('evaluateDeterministicScore awards partial and full credit', () {
    final keyPoints = ['Compute gradient of loss', 'Apply chain rule'];
    final score1 = engine.evaluateDeterministicScore(
      'We compute the gradient of loss and apply the chain rule.',
      keyPoints,
    );
    expect(score1, equals(100.0));

    final score2 = engine.evaluateDeterministicScore(
      'We only compute gradient of loss.',
      keyPoints,
    );
    expect(score2, equals(50.0));

    final score3 = engine.evaluateDeterministicScore('', keyPoints);
    expect(score3, equals(0.0));
  });
}
