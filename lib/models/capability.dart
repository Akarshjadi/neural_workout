/// Represents a measured capability in the Personal Capability Architecture Engine.
class Capability {
  final double? selfRating;
  final List<String> behavioralEvidence;
  final List<String> testResults;
  final double? evidenceQuality;
  final double? confidence;
  final double? score;
  final List<String> contradictions;
  final double? bottleneckImpact;
  final List<String> interventions;
  final List<double> historicalScores;

  const Capability({
    this.selfRating,
    this.behavioralEvidence = const [],
    this.testResults = const [],
    this.evidenceQuality,
    this.confidence,
    this.score,
    this.contradictions = const [],
    this.bottleneckImpact,
    this.interventions = const [],
    this.historicalScores = const [],
  });

  Map<String, dynamic> toJson() => {
        'self_rating': selfRating,
        'behavioral_evidence': behavioralEvidence,
        'test_results': testResults,
        'evidence_quality': evidenceQuality,
        'confidence': confidence,
        'score': score,
        'contradictions': contradictions,
        'bottleneck_impact': bottleneckImpact,
        'interventions': interventions,
        'historical_scores': historicalScores,
      };

  factory Capability.fromJson(Map<String, dynamic> json) {
    return Capability(
      selfRating: (json['self_rating'] as num?)?.toDouble(),
      behavioralEvidence: (json['behavioral_evidence'] as List?)?.map((e) => e.toString()).toList() ?? [],
      testResults: (json['test_results'] as List?)?.map((e) => e.toString()).toList() ?? [],
      evidenceQuality: (json['evidence_quality'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
      contradictions: (json['contradictions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      bottleneckImpact: (json['bottleneck_impact'] as num?)?.toDouble(),
      interventions: (json['interventions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      historicalScores: (json['historical_scores'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
}
