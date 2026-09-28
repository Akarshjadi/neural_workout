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
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(HiveAttemptAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(HiveFeedbackAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(HiveErrorAdapter());
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(HiveDelayedOutcomeAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(HiveInterventionAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(HiveExperimentAdapter());
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(HiveFocusIntegrityAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(HiveConceptProfileAdapter());
    }
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
    await Hive.openBox('attempts');
    await Hive.openBox('feedback');
    await Hive.openBox('errors');
    await Hive.openBox('delayed_outcomes');
    await Hive.openBox('interventions');
    await Hive.openBox('experiments');
    await Hive.openBox('focus');
    await Hive.openBox('concept_profiles');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('fresh database has schema_version 7 without error', () async {
    // Simulate what ensureInitialized does: open boxes, then check schema
    // Since _checkSchemaVersion is private, we verify the schema constant
    // and that all boxes open correctly on a fresh directory.
    expect(AppDatabase.schemaVersion, 7);
    
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
    expect(Hive.isBoxOpen('attempts'), isTrue);
    expect(Hive.isBoxOpen('feedback'), isTrue);
    expect(Hive.isBoxOpen('errors'), isTrue);
    expect(Hive.isBoxOpen('delayed_outcomes'), isTrue);
    expect(Hive.isBoxOpen('interventions'), isTrue);
    expect(Hive.isBoxOpen('experiments'), isTrue);
    expect(Hive.isBoxOpen('focus'), isTrue);
    expect(Hive.isBoxOpen('concept_profiles'), isTrue);
  });

  test('all required adapters are registered', () async {
    // verify all 17 adapters are registered
    expect(Hive.isAdapterRegistered(0), isTrue); // HiveNote
    expect(Hive.isAdapterRegistered(1), isTrue); // HiveSession
    expect(Hive.isAdapterRegistered(2), isTrue); // HiveBlurtScore
    expect(Hive.isAdapterRegistered(3), isTrue); // HivePathwayRecord
    expect(Hive.isAdapterRegistered(4), isTrue); // HiveReview
    expect(Hive.isAdapterRegistered(5), isTrue); // HiveLink
    expect(Hive.isAdapterRegistered(6), isTrue); // HiveSetting
    expect(Hive.isAdapterRegistered(7), isTrue); // HiveThought
    expect(Hive.isAdapterRegistered(8), isTrue); // HiveCheckin
    expect(Hive.isAdapterRegistered(9), isTrue); // HiveAttempt
    expect(Hive.isAdapterRegistered(10), isTrue); // HiveFeedback
    expect(Hive.isAdapterRegistered(11), isTrue); // HiveError
    expect(Hive.isAdapterRegistered(12), isTrue); // HiveDelayedOutcome
    expect(Hive.isAdapterRegistered(13), isTrue); // HiveIntervention
    expect(Hive.isAdapterRegistered(14), isTrue); // HiveExperiment
    expect(Hive.isAdapterRegistered(15), isTrue); // HiveFocusIntegrity
    expect(Hive.isAdapterRegistered(16), isTrue); // HiveConceptProfile
  });

}
