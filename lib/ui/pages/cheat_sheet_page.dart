import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class CheatSheetPage extends StatelessWidget {
  const CheatSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Write a cheat sheet to help remember this concept.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().finishCheatSheet();
              context.read<AppState>().triggerPage(8); // or whatever next
            },
            child: const Text('Save & Next'),
          )
        ],
      ),
    );
  }
}
