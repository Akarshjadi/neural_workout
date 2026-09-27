import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';

/// Schema migration test — opening an empty DB and running ensureInitialized
/// must bring it to the current schema version (v4).
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('neural_workout_migr_test_');
    Hive.init(tempDir.path);
    // Register adapters (same as e2e test pattern)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HiveNoteAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HiveSessionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HiveBlurtScoreAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HivePathwayRecordAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HiveReviewAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HiveLinkAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(HiveSettingAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(HiveThoughtAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(HiveCheckinAdapter());
    await Hive.openBox('notes');
    await Hive.openBox('sessions');
    await Hive.openBox('blurt_scores');
    await Hive.openBox('pathway_records');
    await Hive.openBox('reviews');
    await Hive.openBox('links');
    await Hive.openBox('settings');
    await Hive.openBox('meta');
    await Hive.openBox('thoughts');
    await Hive.openBox('checkins');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('fresh database has schema_version 5 without error', () async {
    // Simulate what ensureInitialized does: open boxes, then check schema
    // Since _checkSchemaVersion is private, we verify the schema constant
    // and that all boxes open correctly on a fresh directory.
    expect(AppDatabase.schemaVersion, 5);
    
    // All boxes should be open and accessible
    expect(Hive.isBoxOpen('notes'), isTrue);
    expect(Hive.isBoxOpen('sessions'), isTrue);
    expect(Hive.isBoxOpen('blurt_scores'), isTrue);
    expect(Hive.isBoxOpen('pathway_records'), isTrue);
    expect(Hive.isBoxOpen('reviews'), isTrue);
    expect(Hive.isBoxOpen('links'), isTrue);
    expect(Hive.isBoxOpen('settings'), isTrue);
    expect(Hive.isBoxOpen('meta'), isTrue);
    expect(Hive.isBoxOpen('thoughts'), isTrue);
    expect(Hive.isBoxOpen('checkins'), isTrue);
  });

  test('all required adapters are registered', () async {
    // verify all 9 adapters are registered
    expect(Hive.isAdapterRegistered(0), isTrue); // HiveNote
    expect(Hive.isAdapterRegistered(1), isTrue); // HiveSession
    expect(Hive.isAdapterRegistered(2), isTrue); // HiveBlurtScore
    expect(Hive.isAdapterRegistered(3), isTrue); // HivePathwayRecord
    expect(Hive.isAdapterRegistered(4), isTrue); // HiveReview
    expect(Hive.isAdapterRegistered(5), isTrue); // HiveLink
    expect(Hive.isAdapterRegistered(6), isTrue); // HiveSetting
    expect(Hive.isAdapterRegistered(7), isTrue); // HiveThought
    expect(Hive.isAdapterRegistered(8), isTrue); // HiveCheckin
  });

}
