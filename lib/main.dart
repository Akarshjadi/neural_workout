import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'state/app_state.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Hive box layer (FFI on desktop; IndexedDB on the web).
  // On some browsers (e.g. Safari with strict privacy settings) IndexedDB is
  // blocked, which would otherwise throw before runApp and leave a blank page.
  // Fall back to an empty in-memory store and surface the error in a banner so
  // the UI still renders instead of silently going blank.
  String? initError;
  final db = AppDatabase();
  final state = AppState(db);
  try {
    await AppDatabase.ensureInitialized();
    await state.load();
    // Defer AI scorer and notification init off the startup path so the first
    // frame renders promptly even if model download is slow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.initDeferredServices();
    });
  } catch (e) {
    initError = e.toString();
  }

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: NeuralWorkoutApp(initError: initError),
    ),
  );
}

class NeuralWorkoutApp extends StatefulWidget {
  final String? initError;

  const NeuralWorkoutApp({super.key, this.initError});

  @override
  State<NeuralWorkoutApp> createState() => _NeuralWorkoutAppState();
}

class _NeuralWorkoutAppState extends State<NeuralWorkoutApp> {
  bool _warned = false; // one-shot so the boot SnackBar fires at most once

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neural Workout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: (context, child) {
        final messenger = ScaffoldMessenger.of(context);
        // If storage failed on boot (e.g. IndexedDB blocked in Safari), flash a
        // visible reason at the bottom instead of silently going blank.
        if (widget.initError != null && !_warned) {
          _warned = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Startup warning:\n${widget.initError}',
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.danger.withValues(alpha: 0.9),
              ),
            );
          });
        }
        return child!;
      },
      home: const AppShell(),
    );
  }
}
