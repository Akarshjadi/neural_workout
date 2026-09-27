import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/models/note.dart';
import 'package:neural_workout/models/session.dart';
import 'package:neural_workout/services/strategy_profile_service.dart';

void main() {
  final service = StrategyProfileService();

  test('synthetic AppState-like inputs → known scores', () {
    final blurts = [
      BlurtScore(id: 1, noteId: 1, noteTitle: '', date: DateTime.now(), scorePct: 80.0, matched: [], missed: [], depthScore: 60.0),
      BlurtScore(id: 2, noteId: 2, noteTitle: '', date: DateTime.now(), scorePct: 100.0, matched: [], missed: [], depthScore: 80.0),
    ];
    final notes = [
      Note(id: 1, title: '', body: '', kind: NoteKind.cheatSheet, createdAt: DateTime.now(), updatedAt: DateTime.now(), card: Card(cardId: 1)),
      Note(id: 2, title: '', body: '', kind: NoteKind.cheatSheet, createdAt: DateTime.now(), updatedAt: DateTime.now(), card: Card(cardId: 1)),
    ];
    final sessions = [
      Session(id: 1, date: DateTime.now(), duration: Duration.zero, stepsCompleted: 8, autosaveJson: '{"teachingText": "Analogies!"}'),
      Session(id: 2, date: DateTime.now(), duration: Duration.zero, stepsCompleted: 8, autosaveJson: '{}'),
    ];
    final reviewRows = [
      {'date': '2023-10-01'},
      {'date': '2023-10-02'},
    ];
    
    final profile = service.compute(
      blurts: blurts,
      notes: notes,
      sessions: sessions,
      reviewRows: reviewRows,
      interleavedCount: 1,
      totalReviewCount: 4,
      linkCounts: {1: 1, 2: 0},
    );

    expect(profile.retrieval, equals(90.0)); // (80 + 100) / 2
    expect(profile.interleaving, equals(25.0)); // 1 / 4
    expect(profile.concreteExamples, equals(50.0)); // 1 / 2
    
    // Elaboration: depth (70) * 0.5 + crossLink (50) * 0.5 = 60
    expect(profile.elaboration, equals(60.0));
    
    expect(profile.dualCoding, equals(0.0));
    expect(profile.dualCodingEvidence, equals('Not tracked yet'));
  });

  test('empty inputs → all zeros, no NaN', () {
    final profile = service.compute(
      blurts: [],
      notes: [],
      sessions: [],
      reviewRows: [],
      interleavedCount: 0,
      totalReviewCount: 0,
      linkCounts: {},
    );

    expect(profile.retrieval, equals(0.0));
    expect(profile.spacing, equals(0.0));
    expect(profile.interleaving, equals(0.0));
    expect(profile.elaboration, equals(0.0));
    expect(profile.concreteExamples, equals(0.0));
    expect(profile.dualCoding, equals(0.0));
  });
}
