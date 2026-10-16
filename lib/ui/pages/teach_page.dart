import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class TeachPage extends StatelessWidget {
  const TeachPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Teach this concept.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().finishTeach();
 context.read<AppState>().triggerPage(2);
            },
            child: const Text('Complete'),
          )
        ],
      ),
    );
  }
}