import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/models/error_record.dart';
import 'package:neural_workout/models/knowledge_evidence.dart';
import 'package:neural_workout/models/learning_attempt.dart';
import 'package:neural_workout/models/learning_enums.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/feedback_diagnosis_service.dart';
import 'package:neural_workout/ui/theme_notebook.dart';
import 'package:neural_workout/widgets/visuals/performance_density.dart';
import 'package:neural_workout/widgets/visuals/prediction_outcome_split.dart';
import 'package:neural_workout/widgets/visuals/recovery_curve.dart';
import 'package:neural_workout/widgets/visuals/semantic_knowledge_topology.dart';

Note _note(int id, {List<int> links = const []}) => Note(
      id: id,
      title: 'Concept $id',
      body: 'Body $id',
      kind: NoteKind.cheatSheet,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      card: fsrs.Card(cardId: id),
      linkIds: links,
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: NotebookTheme.theme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('PredictionOutcomeSplit', () {
    testWidgets('renders header and reports mean gap', (tester) async {
      await tester.pumpWidget(wrap(PredictionOutcomeSplit(attempts: [
        LearningAttempt(
          id: 1,
          timestamp: DateTime(2026),
          testType: TestType.freeRecall,
          correctness: Correctness.partiallyCorrect,
          scorePct: 40.0,
          confidence: 80,
        ),
      ])));
      expect(find.text('PREDICTION / OUTCOME SPLIT'), findsOneWidget);
      // 80 confidence vs 40 outcome => +40 point gap, overconfident.
      expect(find.textContaining('MEAN GAP +40.0'), findsOneWidget);
    });

    testWidgets('ignores attempts missing confidence or score', (tester) async {
      await tester.pumpWidget(wrap(PredictionOutcomeSplit(attempts: [
        LearningAttempt(
          id: 1,
          timestamp: DateTime(2026),
          testType: TestType.freeRecall,
          correctness: Correctness.correct,
          scorePct: 90.0, // no confidence => excluded
        ),
      ])));
      expect(find.text('NO PAIRED DATA'), findsOneWidget);
    });
  });

  group('RecoveryCurve', () {
    test('buckets attempts into 5-minute slots per session', () {
      final start = DateTime(2026, 1, 1, 9, 0);
      final data = RecoveryCurve.buckets([
        LearningAttempt(id: 1, sessionId: 7, timestamp: start, testType: TestType.freeRecall, correctness: Correctness.incorrect, scorePct: 20.0),
        LearningAttempt(id: 2, sessionId: 7, timestamp: start.add(const Duration(minutes: 12)), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 80.0),
      ]);
      expect(data.length, 2);
      expect(data.first.minute, 0);
      expect(data.first.score, 20.0);
      expect(data.last.minute, 10);
      expect(data.last.score, 80.0);
    });

    test('drops single-attempt sessions — a curve needs before and after', () {
      final data = RecoveryCurve.buckets([
        LearningAttempt(id: 1, sessionId: 1, timestamp: DateTime(2026), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
        LearningAttempt(id: 2, timestamp: DateTime(2026), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
      ]);
      expect(data, isEmpty);
    });

    testWidgets('renders with no data', (tester) async {
      await tester.pumpWidget(wrap(const RecoveryCurve(attempts: [])));
      expect(find.text('RECOVERY CURVE'), findsOneWidget);
      expect(find.text('NOT ENOUGH MULTI-ATTEMPT SESSIONS'), findsOneWidget);
    });
  });

  group('PerformanceDensity', () {
    test('returns a dense day-by-day series with zero-filled gaps', () {
      final now = DateTime(2026, 3, 10);
      final days = PerformanceDensity.dailyCounts(
        [
          LearningAttempt(id: 1, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
          LearningAttempt(id: 2, timestamp: now, testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
        ],
        weeks: 2,
        now: now,
      );
      expect(days.length, 14);
      expect(days.last.count, 2);
      expect(days.where((d) => d.count == 0).length, 13);
    });

    test('excludes attempts older than the window', () {
      final now = DateTime(2026, 3, 10);
      final days = PerformanceDensity.dailyCounts(
        [
          LearningAttempt(id: 1, timestamp: DateTime(2020), testType: TestType.freeRecall, correctness: Correctness.correct, scorePct: 90.0),
        ],
        weeks: 2,
        now: now,
      );
      expect(days.fold<int>(0, (a, d) => a + d.count), 0);
    });

    testWidgets('renders header', (tester) async {
      await tester.pumpWidget(wrap(const PerformanceDensity(attempts: [])));
      expect(find.text('PERFORMANCE DENSITY'), findsOneWidget);
    });
  });

  group('SemanticKnowledgeTopology', () {
    testWidgets('renders node count and legend', (tester) async {
      await tester.pumpWidget(wrap(SemanticKnowledgeTopology(
        nodes: [
          TopologyNode(note: _note(1, links: [2]), state: KnowledgeState.verified),
          TopologyNode(note: _note(2), state: KnowledgeState.bottleneck),
        ],
      )));
      expect(find.text('SEMANTIC KNOWLEDGE TOPOLOGY'), findsOneWidget);
      expect(find.text('2 CONCEPTS'), findsOneWidget);
      expect(find.text('Bottleneck'), findsOneWidget);
    });

    testWidgets('handles the empty graph', (tester) async {
      await tester.pumpWidget(wrap(const SemanticKnowledgeTopology(nodes: [])));
      expect(find.text('NO CONCEPTS YET'), findsOneWidget);
    });

    test('layout is deterministic — same count, same positions', () {
      const size = Size(300, 200);
      final a = SemanticKnowledgeTopology.layout(5, size);
      final b = SemanticKnowledgeTopology.layout(5, size);
      expect(a, equals(b));
      for (final p in a) {
        expect(p.dx, inInclusiveRange(0, size.width));
        expect(p.dy, inInclusiveRange(0, size.height));
      }
    });
  });

  group('FeedbackDiagnosisService error recurrence (item 34)', () {
    ErrorRecord err(ErrorType t, {int daysAgo = 0}) => ErrorRecord(
          id: 0,
          attemptId: 1,
          type: t,
          source: DiagnosisSource.deterministic,
          createdAt: DateTime(2026, 6, 10).subtract(Duration(days: daysAgo)),
        );

    test('counts descending, ties broken deterministically', () {
      final out = FeedbackDiagnosisService.errorRecurrence([
        err(ErrorType.guessed),
        err(ErrorType.guessed),
        err(ErrorType.misread),
        err(ErrorType.logicalError),
      ]);
      expect(out.first.type, ErrorType.guessed);
      expect(out.first.count, 2);
      expect(out.length, 3);
    });

    test('recurringErrors filters by window and minimum occurrences', () {
      final out = FeedbackDiagnosisService.recurringErrors(
        [
          err(ErrorType.guessed, daysAgo: 1),
          err(ErrorType.guessed, daysAgo: 2),
          err(ErrorType.misread, daysAgo: 1), // only once => not recurring
          err(ErrorType.logicalError, daysAgo: 90), // outside 14d window
          err(ErrorType.logicalError, daysAgo: 91),
        ],
        window: 14,
        minOccurrences: 2,
        now: DateTime(2026, 6, 10),
      );
      expect(out.length, 1);
      expect(out.first.type, ErrorType.guessed);
    });

    test('a single one-off error is never a pattern', () {
      final out = FeedbackDiagnosisService.recurringErrors(
        [err(ErrorType.misread)],
        now: DateTime(2026, 6, 10),
      );
      expect(out, isEmpty);
    });
  });

  group('FeedbackDiagnosisService hyper-correction (item 33)', () {
    LearningAttempt a(int id, int day, Correctness c, int? conf) =>
        LearningAttempt(
          id: id,
          knowledgeTargetId: 1,
          timestamp: DateTime(2026, 6, day),
          testType: TestType.freeRecall,
          correctness: c,
          scorePct: c.isFail ? 10.0 : 90.0,
          confidence: conf,
        );

    test('flags pass -> failure -> confidence collapse', () {
      final flagged = FeedbackDiagnosisService.hyperCorrectedTargets([
        a(1, 1, Correctness.correct, 90),
        a(2, 2, Correctness.incorrect, 85),
        a(3, 3, Correctness.incorrect, 60),
      ]);
      expect(flagged, [1]);
    });

    test('does not flag a stable passer', () {
      final flagged = FeedbackDiagnosisService.hyperCorrectedTargets([
        a(1, 1, Correctness.correct, 90),
        a(2, 2, Correctness.correct, 88),
        a(3, 3, Correctness.correct, 86),
      ]);
      expect(flagged, isEmpty);
    });

    test('does not flag failure without a confidence crash', () {
      final flagged = FeedbackDiagnosisService.hyperCorrectedTargets([
        a(1, 1, Correctness.correct, 70),
        a(2, 2, Correctness.incorrect, 70),
        a(3, 3, Correctness.correct, 70),
      ]);
      expect(flagged, isEmpty);
    });

    test('needs at least three attempts', () {
      expect(
        FeedbackDiagnosisService.hyperCorrectedTargets([
          a(1, 1, Correctness.correct, 90),
          a(2, 2, Correctness.incorrect, 50),
        ]),
        isEmpty,
      );
    });
  });
}
