import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'screens/today_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/knowledge_screen.dart';
import 'screens/review_screen.dart';
import 'screens/analytics_screen.dart';

/// Root navigation shell — 5 tabs (UIUX §2). Tab index lives in [AppState] so
/// any screen can switch tabs (e.g. "Start workout" from the dashboard).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _screens = [
    TodayScreen(),
    WorkoutScreen(),
    KnowledgeScreen(),
    ReviewScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(index: state.tabIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.selectTab,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: 'Workout'),
          NavigationDestination(
              icon: Icon(Icons.hub_outlined),
              selectedIcon: Icon(Icons.hub),
              label: 'Knowledge'),
          NavigationDestination(
              icon: Icon(Icons.autorenew),
              selectedIcon: Icon(Icons.autorenew),
              label: 'Review'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'You'),
        ],
      ),
    );
  }
}