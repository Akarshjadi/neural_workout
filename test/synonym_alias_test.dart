import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/state/app_state.dart';

/// Tests for synonym alias JSON persistence and special character handling.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('neural_workout_alias_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HiveNoteAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(HiveSettingAdapter());
    await Hive.openBox('notes');
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('synonym aliases round-trip with special characters (=, comma, semicolon)', () async {
    final db = AppDatabase();
    final state = AppState(db);

    // Add an alias containing =, ,, and ;
    await state.addSynonymAlias('test', 'a=b,c;d');

    // Verify the alias is stored
    expect(state.synonymAliases['test'], contains('a=b,c;d'));

    // Reload state to simulate app restart and verify persistence
    final state2 = AppState(db);
    await state2.load();
    expect(state2.synonymAliases['test'], contains('a=b,c;d'));
  });

  test('removeSynonymAlias removes the alias and persists', () async {
    final db = AppDatabase();
    final state = AppState(db);

    await state.addSynonymAlias('concept', 'alias1');
    await state.addSynonymAlias('concept', 'alias2');
    expect(state.synonymAliases['concept'], containsAll(['alias1', 'alias2']));

    await state.removeSynonymAlias('concept', 'alias1');
    final aliases = state.synonymAliases['concept'];
    if (aliases != null) {
      expect(aliases, isNot(contains('alias1')));
    }

    // Verify persistence
    final raw = db.getSetting('synonym_aliases');
    final decoded = jsonDecode(raw!) as Map<String, dynamic>;
    expect(decoded['concept'].cast<String>(), isNot(contains('alias1')));
  });
}
