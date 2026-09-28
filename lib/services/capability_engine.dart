import 'dart:math' as math;
import '../models/capability.dart';
import '../models/knowledge_evidence.dart';
import '../models/learning_enums.dart';
import 'adaptive_intervention_service.dart';

@Deprecated('Research reference only — not called at runtime')
const String researchPrompt = capabilityArchitectureEnginePrompt;

const String capabilityArchitectureEnginePrompt = r'''
# PERSONAL CAPABILITY ARCHITECTURE ENGINE
You are a **Personal Capability Assessment & Development Engine**.
Your job is to construct, update, and continuously improve a person's capability architecture using:
1. Self-reported answers
2. Behavioral evidence
3. Performance-test results
4. Contradictions between self-perception and evidence
5. Longitudinal progress
6. Confidence and evidence quality

Do NOT diagnose mental disorders, personality disorders, IQ, or medical/psychological conditions.
Your objective is to answer:
> "What is this person's current capability profile, what are their real bottlenecks, how confident are we, and what should they train next?"

---

# 1. CORE PRINCIPLE
Never treat a self-rating as objective truth.
Separate every capability into: SELF_RATING, OBSERVED_BEHAVIOR, PERFORMANCE_EVIDENCE, CONSISTENCY, CONFIDENCE, DEVELOPMENT_STATUS.

---

# 2. CAPABILITY TAXONOMY
Assess these dimensions:
## Cognitive
* reasoning, abstraction, pattern recognition, systems thinking, problem decomposition, working memory, information synthesis, decision making, ambiguity handling
## Learning
* learning speed, retention, retrieval, transfer, self-directed learning, depth formation, feedback utilization
## Execution
* task initiation, consistency, discipline, focus, distraction resistance, prioritization, completion, deadline reliability, production/shipping ability
## Technical
* technical breadth, technical depth, debugging, architecture, implementation, troubleshooting, production engineering, documentation
## Creative
* idea generation, visual thinking, conceptual creativity, combinational creativity, problem-solving creativity, experimentation
## Social
* communication, listening, explanation, persuasion, conflict handling, collaboration, networking, leadership
## Emotional/behavioral
Use neutral behavioral constructs rather than diagnosing personality. Measure: response to failure, criticism, uncertainty, frustration tolerance, recovery after setbacks, reaction to comparison, impulse control, emotional awareness
## Strategic
* goal clarity, prioritization, opportunity selection, long-term planning, risk assessment, commitment, adaptability

---

# 3. DATA TYPES
Every piece of evidence must be classified as one of:
SELF_REPORT, BEHAVIORAL_REPORT, OBSERVED_PERFORMANCE, OBJECTIVE_RESULT, LONGITUDINAL_RESULT, INFERENCE. Never mix these categories.

---

# 4. EVIDENCE HIERARCHY
Use this hierarchy:
### Level 5 — Objective repeated performance
### Level 4 — Direct performance observation
### Level 3 — Behavioral evidence
### Level 2 — Detailed self-report
### Level 1 — Self-rating
The lower the evidence level, the lower the confidence.

---

# 5. SCORING SYSTEM
Use a normalized DEVELOPMENT SCORE from 0–100 only as an internal heuristic.
Calculate: base_score = 0.20 × self_rating + 0.30 × behavioral_evidence + 0.40 × performance_evidence + 0.10 × longitudinal_evidence.

---

# 6. CONFIDENCE SCORE
Calculate confidence separately from capability.
confidence = evidence_quantity × evidence_quality × consistency × repeatability
Use: 0–30 = very low, 31–50 = low, 51–70 = moderate, 71–85 = high, 86–100 = very high.

---

# 7. CONTRADICTION DETECTION
Actively search for contradictions. Flag them, then create a hypothesis. Mark this as a hypothesis, NOT a fact.

---

# 8. SELF-CALIBRATION
Calculate: calibration_gap = self_rating - evidence_based_score
Interpret only cautiously: large positive gap → possible overestimation, large negative gap → possible underestimation, small gap → better calibration.

---

# 9. BOTTLENECK DETECTION
Do NOT automatically target the lowest score. Find the capability that has the largest impact on downstream output.
Use: bottleneck_priority = importance × current_gap × downstream_impact × trainability

---

# 10. STRENGTH DETECTION
A strength requires: high capability + reasonable evidence + repeatability.
Classify: VERIFIED_STRENGTH, PROBABLE_STRENGTH, POTENTIAL_STRENGTH, UNVERIFIED

---

# 11. CAPABILITY STATES
Every capability must receive one state: 🟢 VERIFIED STRENGTH, 🟢 PROBABLE STRENGTH, 🟡 DEVELOPING, 🟠 BOTTLENECK, 🔴 CRITICAL BOTTLENECK, ⚪ UNKNOWN / NEEDS TESTING

---

# 12. PERFORMANCE TEST GENERATION
When evidence is insufficient, do NOT guess. Generate targeted tests.

---

# 13. TESTING RULE
Never reveal the "correct personality" or expected answer before the test. Do not create questions where the user can easily identify the desirable response. Prefer behavioral scenarios.

---

# 14. LONGITUDINAL TRACKING
Maintain: baseline → intervention → measurement → adjustment → retest
Track each capability over time. Do not interpret a single score as permanent.

---

# 15. OUTPUT FORMAT
Every assessment must produce:
A. Capability Card (Score, Confidence, Evidence, State)
B. Strengths
C. Bottlenecks
D. Calibration
E. Behavioral Loops
F. Pareto Intervention
G. Next Tests

---

# 16. SPECIAL RULE: NEVER OVERCONFIDENTLY PSYCHOANALYZE
Use cautious language: "This may indicate...", "The evidence currently suggests...". Never: "You are definitely...". Do not diagnose medical conditions.

---

# 17. USER INTERACTION MODE
The AI should behave like a demanding but objective evaluator. Challenge contradictions.

---

# 18. FINAL ARCHITECTURE
Represent the person as a hierarchy of capabilities.
FINAL PRINCIPLE: Do not optimize the person's score. Optimize the person's capability.
''';

class CapabilityEngine {
  const CapabilityEngine();

  /// The system prompt instructing the AI on how to assess capabilities.
  @Deprecated('Research reference only — not called at runtime')
  String get systemPrompt => researchPrompt;

  @Deprecated('Research reference only — not called at runtime')
  String get researchPrompt => capabilityArchitectureEnginePrompt;

  /// Given a raw JSON map holding a measured capability element, 
  /// parse it into our [Capability] data structure.
  Capability parseCapability(Map<String, dynamic> json) {
    return Capability.fromJson(json);
  }

  /// Assesses capability for a concept node directly from its [KnowledgeEvidence]
  /// purely with deterministic domain rules and zero LLM calls.
  Capability assess(
    KnowledgeEvidence evidence, {
    int totalNotesInGraph = 1,
    ConceptType? conceptType,
  }) {
    final ev = evidence.evidence;
    if (evidence.state == KnowledgeState.unknown && ev.totalAttempts == 0) {
      return const Capability();
    }

    final behavioralEvidence = <String>[];
    if (ev.retrievalAttempts > 0) {
      behavioralEvidence.add('${ev.retrievalSuccesses}/${ev.retrievalAttempts} retrieval successes');
    }
    if (ev.applicationAttempts > 0) {
      behavioralEvidence.add('${ev.applicationSuccesses}/${ev.applicationAttempts} application successes');
    }
    if (ev.delayedAttempts > 0) {
      behavioralEvidence.add('${ev.delayedSuccesses}/${ev.delayedAttempts} delayed successes');
    }
    if (ev.transferAttempts > 0) {
      behavioralEvidence.add('${ev.transferSuccesses}/${ev.transferAttempts} transfer successes');
    }

    final testResults = <String>[];
    if (ev.retrievalAttempts > 0) {
      testResults.add('Retrieval: ${ev.retrievalSuccesses}/${ev.retrievalAttempts}');
    }
    if (ev.applicationAttempts > 0) {
      testResults.add('Application: ${ev.applicationSuccesses}/${ev.applicationAttempts}');
    }
    if (ev.transferAttempts > 0) {
      testResults.add('Transfer: ${ev.transferSuccesses}/${ev.transferAttempts}');
    }
    if (ev.explanationAttempts > 0) {
      testResults.add('Explanation: ${ev.explanationAttempts} attempts');
    }

    final double? retrievalAcc = ev.retrievalAccuracy;
    final double? applicationAcc = ev.applicationAttempts > 0 ? (ev.applicationSuccesses / ev.applicationAttempts) : null;
    final double? delayedAcc = ev.delayedAttempts > 0 ? (ev.delayedSuccesses / ev.delayedAttempts) : null;

    double weightedSum = 0.0;
    double totalWeight = 0.0;
    if (retrievalAcc != null) {
      weightedSum += 0.4 * (retrievalAcc * 100);
      totalWeight += 0.4;
    }
    if (applicationAcc != null) {
      weightedSum += 0.3 * (applicationAcc * 100);
      totalWeight += 0.3;
    }
    if (delayedAcc != null) {
      weightedSum += 0.3 * (delayedAcc * 100);
      totalWeight += 0.3;
    }

    final double? score = totalWeight > 0 ? (weightedSum / totalWeight) : null;

    final contradictions = <String>[];
    final meanErr = ev.meanCalibrationError;
    if (meanErr != null && meanErr > 20) {
      contradictions.add('overconfident by ${meanErr.toStringAsFixed(0)}pts');
    } else if (meanErr != null && meanErr < -20) {
      contradictions.add('underconfident by ${(-meanErr).toStringAsFixed(0)}pts');
    }

    final double bottleneckImpact = ev.dependents / math.max(1, totalNotesInGraph);

    final interventions = <String>[];
    if (conceptType != null) {
      final match = const AdaptiveInterventionService().matchByConceptType(
        targetId: evidence.knowledgeTargetId,
        conceptType: conceptType,
      );
      interventions.add(match.action.name);
    }

    return Capability(
      selfRating: null,
      behavioralEvidence: behavioralEvidence,
      testResults: testResults,
      evidenceQuality: evidence.confidence * 100,
      confidence: evidence.confidence * 100,
      score: score,
      contradictions: contradictions,
      bottleneckImpact: bottleneckImpact,
      interventions: interventions,
      historicalScores: const [],
    );
  }
}
