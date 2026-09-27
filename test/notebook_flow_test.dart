import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:neural_workout/state/app_state.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/ui/page_turn_controller.dart';
import 'package:neural_workout/ui/theme_notebook.dart';

void main() {
  testWidgets('Notebook shell starts on Cover and next button turns pages', (WidgetTester tester) async {
    final db = AppDatabase();
    final state = AppState(db);

    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.theme,
        home: ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const NotebookShell(),
        ),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();
    expect(find.text('FIELD NOTEBOOK'), findsOneWidget);

    // Tap 'Turn page ->'
    await tester.tap(find.text('Turn page →'));
    await tester.pumpAndSettle();
    
    expect(find.text("DAILY CHECK-IN"), findsWidgets); await tester.tap(find.text("Turn page →")); await tester.pumpAndSettle(); expect(find.text("TODAY'S PRACTICE"), findsWidgets); // using widgets in case "TODAY'S PRACTICE" label is duplicated or not
  });
}

