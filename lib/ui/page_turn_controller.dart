import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

import 'theme_notebook.dart';
import 'pages/cover_page.dart';
import 'pages/today_page.dart';
import 'pages/blurt_page.dart';
import 'pages/compare_page.dart';
import 'pages/card_page.dart';
import 'pages/index_page.dart';
import 'pages/back_cover_page.dart';

import 'pages/checkin_page.dart';
import 'pages/graph_page.dart';

class NotebookShell extends StatefulWidget {
  const NotebookShell({super.key});
  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class _NotebookShellState extends State<NotebookShell> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = const [
    CoverPage(), CheckinPage(), TodayPage(), BlurtPage(), ComparePage(),
    CardPage(), GraphPage(), IndexPage(), BackCoverPage(),
  ];

  void _turnPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _pageController.animateToPage(
      index, duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
    );
  }
  void _nextPage() => _turnPage(_currentPage + 1);
  void _prevPage() => _turnPage(_currentPage - 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.pageTrigger != null) {
      final target = appState.pageTrigger!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.consumePageTrigger();
        if (_currentPage != target) _turnPage(target);
      });
    }

    return Scaffold(
      backgroundColor: NotebookTheme.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Container(
                color: NotebookTheme.paper, // No image asset to prevent missing asset crash
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 300) _prevPage();
              },
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                      }
                      double angle = 0.0;
                      if (value < 0 && value >= -1) angle = value * 0.05;
                      return Transform(
                        transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateZ(angle),
                        alignment: Alignment.bottomLeft,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: NotebookTheme.paper,
                        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(1, 0))],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _pages[index]),
                          if (index > 0)
                            Positioned(
                              top: 16, left: 16,
                              child: TextButton(
                                onPressed: _prevPage,
                                child: const Text('←', style: TextStyle(fontFamily: 'monospace', fontSize: 24)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentPage < _pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nextPage,
                        child: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Turn page →')),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(i == _currentPage ? '●' : '◦', style: const TextStyle(fontFamily: 'monospace', color: NotebookTheme.graphite, fontSize: 14)),
                    );
                  }),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}