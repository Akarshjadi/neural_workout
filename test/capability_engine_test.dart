import 'package:flutter_test/flutter_test.dart';
import 'package:neural_workout/models/capability.dart';
import 'package:neural_workout/services/capability_engine.dart';

void main() {
  group('Capability Model', () {
    test('serializes and deserializes correctly', () {
      const capability = Capability(
        selfRating: 85.0,
        behavioralEvidence: ['Completed 3 tasks on time', 'Ignored distraction'],
        testResults: ['Score 90 on decomposition test'],
        evidenceQuality: 80.0,
        confidence: 75.0,
        score: 82.0,
        contradictions: ['High confidence but slow recall'],
        bottleneckImpact: 60.0,
        interventions: ['Timeboxing', 'Spaced repetition'],
        historicalScores: [70.0, 75.0, 82.0],
      );

      final json = capability.toJson();
      expect(json['self_rating'], 85.0);
      expect(json['behavioral_evidence'], hasLength(2));
      expect(json['test_results'], hasLength(1));
      expect(json['evidence_quality'], 80.0);
      expect(json['confidence'], 75.0);
      expect(json['score'], 82.0);
      expect(json['contradictions'], hasLength(1));
      expect(json['bottleneck_impact'], 60.0);
      expect(json['interventions'], hasLength(2));
      expect(json['historical_scores'], [70.0, 75.0, 82.0]);

      final fromJson = Capability.fromJson(json);
      expect(fromJson.selfRating, 85.0);
      expect(fromJson.behavioralEvidence, ['Completed 3 tasks on time', 'Ignored distraction']);
      expect(fromJson.testResults, ['Score 90 on decomposition test']);
      expect(fromJson.evidenceQuality, 80.0);
      expect(fromJson.confidence, 75.0);
      expect(fromJson.score, 82.0);
      expect(fromJson.contradictions, ['High confidence but slow recall']);
      expect(fromJson.bottleneckImpact, 60.0);
      expect(fromJson.interventions, ['Timeboxing', 'Spaced repetition']);
      expect(fromJson.historicalScores, [70.0, 75.0, 82.0]);
    });

    test('handles empty / default fields properly', () {
      final capability = Capability.fromJson(const {});
      expect(capability.selfRating, isNull);
      expect(capability.behavioralEvidence, isEmpty);
      expect(capability.testResults, isEmpty);
      expect(capability.evidenceQuality, isNull);
      expect(capability.confidence, isNull);
      expect(capability.score, isNull);
      expect(capability.contradictions, isEmpty);
      expect(capability.bottleneckImpact, isNull);
      expect(capability.interventions, isEmpty);
      expect(capability.historicalScores, isEmpty);
    });
  });

  group('CapabilityEngine', () {
    test('contains valid system prompt and parses json', () {
      final engine = CapabilityEngine();
      expect(engine.systemPrompt, contains('PERSONAL CAPABILITY ARCHITECTURE ENGINE'));
      expect(engine.systemPrompt, contains('CAPABILITY TAXONOMY'));
      expect(engine.systemPrompt, contains('EVIDENCE HIERARCHY'));

      final parsed = engine.parseCapability({
        'self_rating': 90.0,
        'score': 85.5,
        'confidence': 70.0,
        'behavioral_evidence': ['Consistent execution'],
      });

      expect(parsed.selfRating, 90.0);
      expect(parsed.score, 85.5);
      expect(parsed.confidence, 70.0);
      expect(parsed.behavioralEvidence, ['Consistent execution']);
    });
  });
}
