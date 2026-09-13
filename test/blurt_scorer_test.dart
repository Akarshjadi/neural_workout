import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/blurt_scorer.dart';

/// Tests for the blurt scorer — one of the three "real risks".
///
/// The critical guarantee (ARCH §8): reward RECALL, not verbatim copy.
/// Paraphrasing / synonyms / stemmed forms must score correctly, otherwise
/// the app punishes the exact skill it's meant to build (Feynman style).
void main() {
  const source =
      'The OSI model has seven layers: application gateway presentation '
      'encryption session checkpoint transport segment TCP Ethernet frame '
      'MAC data link';

  group('BlurtScorer', () {
    test('exact recall scores high', () {
      final scorer = BlurtScorer(sourceBody: source);
      final r = scorer.score(
          'OSI model seven layers application gateway presentation encryption '
          'session checkpoint transport segment TCP ethernet frame MAC data link');
      expect(r.scorePct, greaterThanOrEqualTo(90));
      expect(r.matched, isNotEmpty);
    });

    test('recall in own words scores well (synonyms/stemming)', () {
      final scorer = BlurtScorer(
        sourceBody: source,
        synonymAliases: const {
          'gateway': ['bridge'],
          'encryption': ['ciphering'],
        },
      );
      final r = scorer.score(
          'The OSI model has seven layers. The application and presentation '
          'layers do work. The session has a checkpoint. The transport has a '
          'segment and TCP. The data link has ethernet frames and MAC. The '
          'network layer is between them. A bridge connects and ciphering '
          'protects data.');
      // "bridge" maps to gateway via alias; "ciphering" maps to encryption;
      // "sessions" stems to session. Paraphrase covers most core concepts.
      expect(r.scorePct, greaterThanOrEqualTo(60),
          reason: 'paraphrase must not be marked as total failure');
    });

    test('wrong-topic answer scores low', () {
      final scorer = BlurtScorer(sourceBody: source);
      final r = scorer.score('I know nothing about networks today, sorry.');
      expect(r.scorePct, lessThan(30));
    });

    test('stemming unifies plurals', () {
      expect(BlurtScorer.stem('networks'), 'network');
      expect(BlurtScorer.stem('transmitting'), 'transmitt');
      expect(BlurtScorer.stem('studies'), 'study');
    });

    test('empty blur scores zero', () {
      final scorer = BlurtScorer(sourceBody: source);
      expect(scorer.score('').scorePct, 0.0);
    });
  });
}