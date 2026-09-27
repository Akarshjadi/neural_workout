import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/state/app_state.dart';

/// End-to-end workout flow test — the most important path in the app.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neural_workout_test_');
    Hive.init(tempDir.path);
    // Manually init boxes (ensureInitialized needs platform channel).
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HiveNoteAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HiveSessionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HiveBlurtScoreAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HivePathwayRecordAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HiveReviewAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(HiveLinkAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(HiveSettingAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(HiveThoughtAdapter());
    await Hive.openBox('notes');
    await Hive.openBox('sessions');
    await Hive.openBox('blurt_scores');
    await Hive.openBox('pathway_records');
    await Hive.openBox('reviews');
    await Hive.openBox('links');
    await Hive.openBox('settings');
    await Hive.openBox('meta');
    await Hive.openBox('thoughts');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('full workout session lifecycle: start → blurt → complete → analytics update', () async {
    final state = AppState(AppDatabase());

    // 1. Start a session (cold-start: no anchor note).
    await state.startSession('OSI Model');
    expect(state.activeSession, isNotNull);
    expect(state.activeWorkout, isNotNull);
    expect(state.activeWorkout!.anchorTitle, 'OSI Model');

    // 2. Capture blurt text and finish blurt.
    await state.setBlurt('The OSI model has seven layers');
    expect(state.activeWorkout!.blurtText, 'The OSI model has seven layers');
    await state.finishBlurt();

    // 3. Advance through remaining steps.
    await state.setCheatSheet('7 layers: app, presentation, session, transport, network, data link, physical');
    await state.setLinkText('Connects to TCP/IP because both are networking models');
    await state.setTeaching('Each layer serves the one above it');

    // Schedule step
    await state.scheduleAnchor();

    // 4. Advance to completion.
    while (state.activeSession != null) {
      await state.advanceStep();
    }
    expect(state.activeSession, isNull);
    expect(state.activeWorkout, isNull);
    expect(state.completedRecently, isTrue);

    // 5. Analytics updated after completion.
    expect(state.sessions.length, greaterThan(0));
    expect(state.pathwayRecords.length, greaterThan(0));
    expect(state.getOverallScore(), greaterThanOrEqualTo(0));

    // Wait, the review history should be updated if schedule step fired (regression test for anchor note persistence).
    // The previous bug lost the anchorId so it created multiple notes and never scheduled reviews.
    expect(state.db.reviewHistory(), isNotEmpty);
    final anchorNotes = state.notes.where((n) => n.title == 'OSI Model').toList();
    expect(anchorNotes.length, equals(1), reason: 'Should not create duplicate notes for the same anchor');
  });

  test('thoughts CRUD works end-to-end', () async {
    final state = AppState(AppDatabase());

    await state.addThought('Test thought', tags: ['idea']);
    expect(state.thoughts.length, 1);
    expect(state.thoughts.first.text, 'Test thought');

    final id = state.thoughts.first.id;
    await state.deleteThought(id);
    expect(state.thoughts.length, 0);

    // Recovery.
    await state.recoverThought(id);
    expect(state.thoughts.length, 1);
  });

  test('stale data detection does not delete automatically', () async {
    final state = AppState(AppDatabase());
    await state.addNote('Old note', 'body');
    final stale = state.findStaleData(days: 90);
    // Newly created note should not be stale.
    expect(stale.staleNotes.length, 0);
  });

  test('cold-start session with no blurt does not schedule a review', () async {
    final state = AppState(AppDatabase());
    final before = state.db.reviewHistory().length;
    await state.startSession('Empty anchor');
    await state.setBlurt('');          // blank
    await state.finishBlurt();         // no source, no text → no score
    await state.scheduleAnchor();      // must no-op
    while (state.activeSession != null) { await state.advanceStep(); }
    expect(state.db.reviewHistory().length, before);
  });
}
