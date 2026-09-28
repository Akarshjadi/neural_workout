import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/services/cognition_engine.dart';
import 'package:neural_workout/state/app_state.dart';
import 'package:neural_workout/ui/pages/today_page.dart';
import 'package:neural_workout/ui/theme_notebook.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cognition_factors_test_');
    await AppDatabase.ensureInitializedForTesting(tempDir.path);
    db = AppDatabase();
    state = AppState(db);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('todayNeuroFactors on empty state returns 5 factors with value01 == 0.0 and no NaN', () {
    final factors = state.todayNeuroFactors;
    expect(factors.length, 5);
    for (final f in factors) {
      expect(f.value01, 0.0);
      expect(f.value01.isNaN, isFalse);
      expect(f.contribution, 0.0);
      expect(f.detail, isNotEmpty);
    }
  });

  test('one note today and one blurt today produces positive Novelty and Retrieval factors', () async {
    final now = DateTime.now();
    final note = Note(
      id: 1,
      title: 'New note',
      body: 'Body text',
      kind: NoteKind.blurtSummary,
      createdAt: now,
      updatedAt: now,
      card: fsrs.Card(cardId: 1),
    );
    await state.db.insertNote(note);

    final blurt = BlurtScore(
      id: 1,
      noteId: 1,
      noteTitle: 'New note',
      date: now,
      scorePct: 90,
      matched: ['a'],
      missed: [],
      recallSpeedMs: 5000,
    );
    await state.db.insertBlurtScore(blurt);

    // Refresh state notes and blurts
    state.notes = state.db.allNotes();
    state.blurtScores = state.db.allBlurtScores();

    final factors = CognitionEngine(today: now).neuroFactorsFor(
      notes: state.notes,
      sessions: state.db.allSessions(),
      blurts: state.blurtScores,
      reviews: state.db.reviewHistory(),
      breaks: state.breaks,
    );

    final novelty = factors.firstWhere((f) => f.name == 'Novelty');
    final retrieval = factors.firstWhere((f) => f.name == 'Retrieval');

    expect(novelty.value01, greaterThan(0.0));
    expect(retrieval.value01, greaterThan(0.0));
  });

  testWidgets('today_page renders CONTRIBUTING FACTORS and does not render sum', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.theme,
        home: Scaffold(
          body: ChangeNotifierProvider<AppState>.value(
            value: state,
            child: const TodayPage(),
          ),
        ),
      ),
    );

    expect(find.text('CONTRIBUTING FACTORS'), findsOneWidget);
    // Ensure no summed overall / total score is displayed in this card
    expect(find.text('TOTAL COGNITIVE SCORE'), findsNothing);
    expect(find.text('NEURO SCORE'), findsNothing);
  });
}
