import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/blurt_score.dart';
import 'package:neural_workout/services/ranking_service.dart';

void main() {
  group('Single Composite Evidence Score Integrity', () {
    final rankingSvc = RankingService();

    test('evidenceScore and overallScore return identical results', () {
      final now = DateTime.now();
      final blurts = [
        BlurtScore(
          id: 1,
          noteId: 1,
          noteTitle: 'Concept',
          date: now,
          scorePct: 85,
          matched: ['a'],
          missed: [],
          depthScore: 75,
          clarityScore: 80,
        ),
      ];

      final ev = rankingSvc.evidenceScore(
        blurts: blurts,
        notes: [],
        pathways: [],
        linkCounts: {},
      );

      final ov = rankingSvc.overallScore(
        blurts: blurts,
        notes: [],
        pathways: [],
        linkCounts: {},
      );

      expect(ev, ov);
    });

    test('identical blurts with AI on vs off differs by less than 2.0', () {
      final now = DateTime.now();
      final aiOn = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Title',
        date: now,
        scorePct: 80,
        matched: ['k1', 'k2'],
        missed: [],
        depthScore: 80,
        clarityScore: 80,
      );

      final aiOff = BlurtScore(
        id: 1,
        noteId: 1,
        noteTitle: 'Title',
        date: now,
        scorePct: 80,
        matched: ['k1', 'k2'],
        missed: [],
        depthScore: null,
        clarityScore: null,
      );

      final onScore = rankingSvc.evidenceScore(
        blurts: [aiOn],
        notes: [],
        pathways: [],
        linkCounts: {},
      );

      final offScore = rankingSvc.evidenceScore(
        blurts: [aiOff],
        notes: [],
        pathways: [],
        linkCounts: {},
      );

      expect((onScore - offScore).abs(), lessThan(2.0));
    });

    test('today_page.dart contains neither _calculateXP nor _getLevel', () {
      final todayPageFile = File('lib/ui/pages/today_page.dart');
      expect(todayPageFile.existsSync(), isTrue);
      final text = todayPageFile.readAsStringSync();

      expect(text.contains('_calculateXP'), isFalse);
      expect(text.contains('_getLevel'), isFalse);
    });
  });
}
