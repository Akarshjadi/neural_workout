import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/state/app_state.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  test('startSession guard prevents multiple rapid executions', () async {
    final dir = Directory('./test_db_rapid');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync();
    await AppDatabase.ensureInitializedForTesting('./test_db_rapid');
    final db = AppDatabase();
    final state = AppState(db);

    // Call twice rapidly without awaiting the first
    final future1 = state.startSession('Anchor 1');
    final future2 = state.startSession('Anchor 2');

    await Future.wait([future1, future2]);
    
    // Output should prefer first entry and run once!
    expect(state.activeSession?.anchorTitle, 'Anchor 1');
    expect(state.sessions.length, 1);
  });
}
