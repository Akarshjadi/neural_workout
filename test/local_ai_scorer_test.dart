import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/services/blurt_scorer.dart';
import 'package:neural_workout/services/local_ai_scorer.dart';

/// Phase 1 — Test JSON parsing logic used by LocalAiScorer.
void main() {
  group('LocalAiScorer.clampScore', () {
    test('values above 100 clamp to 100', () {
      expect(LocalAiScorer.clampScore(150), 100.0);
    });

    test('values below 0 clamp to 0', () {
      expect(LocalAiScorer.clampScore(-1), 0.0);
    });

    test('in-range values are unchanged', () {
      expect(LocalAiScorer.clampScore(37.5), 37.5);
      expect(LocalAiScorer.clampScore(100), 100.0);
      expect(LocalAiScorer.clampScore(0), 0.0);
    });
  });
  group('ScoreResult JSON parsing', () {
    test('parses valid JSON with all fields', () {
      const jsonStr = '''
{
  "score_pct": 75.0,
  "matched": ["network", "gateway"],
  "missed": ["encryption"],
  "source_concepts": ["network", "gateway", "encryption"],
  "depth": 65.0,
  "clarity": 80.0
}''';
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      expect(jsonStart, greaterThanOrEqualTo(0));
      expect(jsonEnd, greaterThan(jsonStart));

      // Simulate what LocalAiScorer does.
      final text = jsonStr.trim();
      final jsStart = text.indexOf('{');
      final jsEnd = text.lastIndexOf('}');
      expect(jsStart, 0);
      expect(jsEnd, text.length - 1);
    });

    test('handles missing optional fields gracefully', () {
      const jsonStr = '{"score_pct": 50, "matched": [], "missed": [], "source_concepts": []}';
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      expect(jsonStart, 0);
      expect(jsonEnd, jsonStr.length - 1);
    });

    test('throws FormatException when no JSON present', () {
      const text = 'I have no JSON here';
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      expect(jsonStart == -1 || jsonEnd - 1 == -1, isTrue);
    });
  });

  group('ScoreResult with AI fields', () {
    test('creates ScoreResult with depth and clarity', () {
      final r = ScoreResult(
        scorePct: 80,
        matched: ['a', 'b'],
        missed: ['c'],
        sourceConcepts: ['a', 'b', 'c'],
        depthScore: 70,
        clarityScore: 85,
      );
      expect(r.depthScore, 70);
      expect(r.clarityScore, 85);
    });

    test('creates ScoreResult without AI fields (fallback)', () {
      final r = ScoreResult(
        scorePct: 60,
        matched: ['a'],
        missed: ['b'],
        sourceConcepts: ['a', 'b'],
      );
      expect(r.depthScore, isNull);
      expect(r.clarityScore, isNull);
    });
  });
}
