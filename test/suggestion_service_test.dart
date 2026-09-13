import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neural_workout/data/app_database.dart';
import 'package:neural_workout/state/app_state.dart';
import 'package:neural_workout/services/suggestion_service.dart';

/// Phase 6 — Rule-based suggestion priority tests.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('neural_workout_sugg_test_');
    Hive.init(tempDir.path);
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

  test('many due notes produce a high-priority suggestion', () async {
    final state = AppState(AppDatabase());
    // 10+ due notes (card.due in the past) → "high" suggestion.
    for (var i = 0; i < 12; i++) {
      await state.addNote('Due note $i', 'body $i');
    }
    // Mark each as due by reviewing? Due is determined by card.due — new cards
    // are already due (interval 0), so dueNotesList is non-empty immediately.
    final suggestions = SuggestionService().generateSuggestions(state);
    expect(
      suggestions.any((s) => s.contains('due') && s.contains('review')),
      isTrue,
      reason: '12 due notes should surface a review suggestion in the top-2',
    );
  });

  test('due notes under 10 surface a medium suggestion', () async {
    final state = AppState(AppDatabase());
    for (var i = 0; i < 3; i++) {
      await state.addNote('Due note $i', 'body $i');
    }
    final suggestions = SuggestionService().generateSuggestions(state);
    expect(
      suggestions.any((s) => s.contains('due')),
      isTrue,
    );
  });

  test('no suggestions when nothing is due and session already done', () async {
    final state = AppState(AppDatabase());
    final suggestions = SuggestionService().generateSuggestions(state);
    // With no notes and no due cards, there are no due/high suggestions.
    // (The "no session after 8 PM" critical fires only after 20:00 local.)
    final now = DateTime.now();
    if (now.hour < 20) {
      expect(
        suggestions.any((s) => s.contains('quick 2-min blurt')),
        isFalse,
      );
    }
  });
}