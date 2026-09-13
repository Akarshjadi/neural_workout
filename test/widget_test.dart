import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/main.dart';
import 'package:neural_workout/state/app_state.dart';

void main() {
  testWidgets('App boots with the 5-tab shell', (WidgetTester tester) async {
    // No Hive init / DB load: rendering the shell reads in-memory state only,
    // so the test stays fast and deterministic. The heavy DB layer is covered
    // by the pure-Dart model tests.
    final state = AppState(AppDatabase());
    // Start on the Today tab. The old framework assertion on decorated
    // ListTiles is resolved by wrapping them in Material (issue 20).
    state.tabIndex = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const NeuralWorkoutApp(),
      ),
    );
    await tester.pump();

    // The shell renders the Today tab welcome and all five destinations.
    expect(find.text('Day 0 of streak'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget); // nav destination
    expect(find.text('Workout'), findsOneWidget); // nav destination
    expect(find.text('Knowledge'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('Analytics screen shows AI toggle', (WidgetTester tester) async {
    final state = AppState(AppDatabase());
    state.tabIndex = 4; // You tab

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const NeuralWorkoutApp(),
      ),
    );
    await tester.pump();

    // Scroll down to reveal the Settings card with AI toggle.
    await tester.scrollUntilVisible(
      find.text('Use AI scoring'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Use AI scoring'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
