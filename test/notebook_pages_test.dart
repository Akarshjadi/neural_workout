import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:neural_workout/state/app_state.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/ui/pages/cover_page.dart';
import 'package:neural_workout/ui/pages/today_page.dart';
import 'package:neural_workout/ui/theme_notebook.dart';

void main() {
  testWidgets('Cover pages loads correctly', (tester) async {
    final db = AppDatabase();
    final state = AppState(db);

    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.theme,
        home: Scaffold(
          body: ChangeNotifierProvider<AppState>.value(
            value: state,
            child: const CoverPage(),
          ),
        ),
      ),
    );

    expect(find.text('FIELD NOTEBOOK'), findsOneWidget);
    expect(find.text('MICRO'), findsOneWidget);
  });

  testWidgets('Today page prompts for new blurt by default', (tester) async {
    final db = AppDatabase();
    final state = AppState(db);

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

    expect(find.text('Rest and consolidate.'), findsOneWidget);
    expect(find.text('Practice (Optional)'), findsOneWidget);
  });
}

