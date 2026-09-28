import '../models/error_record.dart';
import '../models/intervention.dart';
import '../models/knowledge_evidence.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import '../models/note.dart';

/// Interleaved block recommendation.
class InterleavedBlock {
  final List<Note> targetNotes;
  final String rationale;
  final String interleaveGroupId;

  const InterleavedBlock({
    required this.targetNotes,
    required this.rationale,
    required this.interleaveGroupId,
  });
}

/// Core Adaptive Intervention Service matching pedagogical actions to empirical evidence.
class AdaptiveInterventionService {
  const AdaptiveInterventionService();

  /// Determines optimal next intervention based on recent attempts, errors, and knowledge state.
  Intervention decideIntervention({
    required int? targetId,
    required List<LearningAttempt> targetAttempts,
    required List<ErrorRecord> targetErrors,
    required KnowledgeState knowledgeState,
    ConceptType conceptType = ConceptType.definition,
    int? contrastTargetId,
    List<InterventionConceptMatch> empirical = const [],
    List<InterventionConceptMatch>? empiricalMatches,
    int minSamples = 3,
  }) {
    final effectiveEmpirical = empiricalMatches ?? empirical;
    final now = DateTime.now();

    // 1. High confidence error -> Hyper-correction / calibration
    if (targetAttempts.isNotEmpty) {
      final last = targetAttempts.last;
      if (last.confidence != null && last.confidence! >= 80 && last.correctness.isFail) {
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.explain,
          reason: InterventionReason.overconfidence,
          explanation: 'Hyper-correction: You felt confident but made an error. Explain the underlying rule.',
          knowledgeTargetId: targetId,
          attemptId: last.id,
        );
      }
    }

    // 2. Confused concepts in recent error history -> Contrastive retrieval
    final hasConfusedError = targetErrors.any((e) => e.type == ErrorType.confusedConcepts);
    if (hasConfusedError && contrastTargetId != null) {
      return Intervention(
        id: 0,
        createdAt: now,
        action: InterventionAction.contrast,
        reason: InterventionReason.confusableTargets,
        explanation: 'Recent errors show concept confusion. Contrast these two concepts directly.',
        knowledgeTargetId: targetId,
        contrastTargetId: contrastTargetId,
      );
    }

    // 2b. Retrieval-family errors with few attempts → scaffold with a cue.
    // Rationale: the concept is known but not retrievable; a cue bridges the gap
    // before failure count escalates to worked-example territory.
    if (targetErrors.isNotEmpty &&
        targetErrors.last.family == ErrorFamily.retrieval &&
        targetAttempts.length <= 2) {
      return Intervention(
        id: 0,
        createdAt: now,
        action: InterventionAction.retrieve,
        reason: InterventionReason.retrievalError,
        explanation: 'Recent retrieval failure. Retrieving with a cue '
            'rebuilds the access path before testing it cold.',
        knowledgeTargetId: targetId,
        attemptId: targetAttempts.lastOrNull?.id,
        testTypeOverride: TestType.cuedRecall,
      );
    }

    // 2c. Attention-family errors → slow down. Timed free recall, not
    // speed pressure: the timer is a metronome, not a race.
    if (targetErrors.isNotEmpty &&
        targetErrors.last.family == ErrorFamily.attention) {
      return Intervention(
        id: 0,
        createdAt: now,
        action: InterventionAction.focusReset,
        reason: InterventionReason.attentionError,
        explanation: 'Recent careless or misread error. One slow, '
            'deliberate recall with the metronome running.',
        knowledgeTargetId: targetId,
        attemptId: targetAttempts.lastOrNull?.id,
        testTypeOverride: TestType.freeRecall,
        thresholds: const {'timer_seconds': 60},
      );
    }

    // 3. Persistent failures (3+) -> Worked example
    final recentFails = targetAttempts.take(3).where((a) => a.correctness.isFail).length;
    if (recentFails >= 3) {
      return Intervention(
        id: 0,
        createdAt: now,
        action: InterventionAction.workedExample,
        reason: InterventionReason.persistentFailure,
        explanation: '3 consecutive retrieval failures. Study a full worked example before trying again.',
        knowledgeTargetId: targetId,
      );
    }

    // 4. Repeated failures (2) -> Explanation
    if (recentFails >= 2) {
      return Intervention(
        id: 0,
        createdAt: now,
        action: InterventionAction.explain,
        reason: InterventionReason.repeatedFailure,
        explanation: '2 recent errors. Self-explain the core mechanism to resolve conceptual gaps.',
        knowledgeTargetId: targetId,
      );
    }

    // 5. Concept-type driven matching (empirical with heuristic fallback)
    if (effectiveEmpirical.isNotEmpty) {
      return matchByEmpiricalData(
        targetId: targetId,
        conceptType: conceptType,
        empirical: effectiveEmpirical,
        minSamples: minSamples,
        contrastTargetId: contrastTargetId,
      );
    }

    return matchByConceptType(
      targetId: targetId,
      conceptType: conceptType,
      contrastTargetId: contrastTargetId,
    );
  }

  /// Matches intervention using empirical delayed retention data across concepts.
  /// Falls back to heuristic switch if sample size < [minSamples].
  Intervention matchByEmpiricalData({
    required int? targetId,
    required ConceptType conceptType,
    required List<InterventionConceptMatch> empirical,
    int minSamples = 3,
    int? contrastTargetId,
  }) {
    final valid = empirical
        .where((m) => m.conceptType == conceptType && m.sampleSize >= minSamples)
        .toList();

    if (valid.isNotEmpty) {
      valid.sort((a, b) => b.meanDelayedScore.compareTo(a.meanDelayedScore));
      final best = valid.first;
      return Intervention(
        id: 0,
        createdAt: DateTime.now(),
        action: best.action,
        reason: InterventionReason.experimentAssignment,
        explanation:
            'Empirically selected ${best.action.label} (mean delayed score: ${best.meanDelayedScore.toStringAsFixed(1)}%, n=${best.sampleSize}).',
        knowledgeTargetId: targetId,
        contrastTargetId: contrastTargetId,
      );
    }

    return matchByConceptType(
      targetId: targetId,
      conceptType: conceptType,
      contrastTargetId: contrastTargetId,
    );
  }

  /// Policy mapping concept types to primary recommended interventions.
  Intervention matchByConceptType({
    required int? targetId,
    required ConceptType conceptType,
    int? contrastTargetId,
  }) {
    final now = DateTime.now();

    switch (conceptType) {
      case ConceptType.procedure:
      case ConceptType.algorithm:
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.application,
          reason: InterventionReason.baseline,
          explanation: 'Procedural concept: Practice application in a concrete step-by-step problem.',
          knowledgeTargetId: targetId,
        );

      case ConceptType.discrimination:
      case ConceptType.relationship:
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.contrast,
          reason: InterventionReason.baseline,
          explanation: 'Relational concept: Practice contrastive discrimination against neighboring concepts.',
          knowledgeTargetId: targetId,
          contrastTargetId: contrastTargetId,
        );

      case ConceptType.problemSolving:
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.application,
          reason: InterventionReason.baseline,
          explanation: 'Problem-solving concept: Engage in application retrieval.',
          knowledgeTargetId: targetId,
        );

      case ConceptType.conceptualModel:
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.explain,
          reason: InterventionReason.baseline,
          explanation: 'Conceptual model: Formulate a self-explanation of causal principles.',
          knowledgeTargetId: targetId,
        );

      case ConceptType.definition:
      case ConceptType.formula:
      case ConceptType.unclassified:
        return Intervention(
          id: 0,
          createdAt: now,
          action: InterventionAction.retrieve,
          reason: InterventionReason.baseline,
          explanation: 'Factual target: Active free/cued retrieval practice.',
          knowledgeTargetId: targetId,
        );
    }
  }

  /// Builds a meaningful interleaved study block on confusable or related concepts.
  InterleavedBlock? planMeaningfulInterleaving({
    required Note primaryNote,
    required List<Note> availableNotes,
    required Map<int, List<int>> graphAdjacency,
  }) {
    final relatedIds = graphAdjacency[primaryNote.id] ?? const [];
    final relatedNotes = availableNotes.where((n) => relatedIds.contains(n.id)).take(2).toList();

    if (relatedNotes.isEmpty) {
      return null;
    }

    final blockNotes = [primaryNote, ...relatedNotes];
    return InterleavedBlock(
      targetNotes: blockNotes,
      rationale: 'Interleaving ${blockNotes.map((n) => n.title).join(", ")} based on shared graph connections to sharpen discrimination.',
      interleaveGroupId: 'int_${primaryNote.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Computes the Net Friction Rule score for an intervention.
  /// Net Yield = (Delayed Retention Gain) - (Time Cost in Minutes * 0.1 + Friction Factor).
  double computeNetFrictionYield({
    required double delayedRetentionGainPct,
    required Duration timeSpent,
    double subjectiveFriction = 1.0,
  }) {
    final timeCost = timeSpent.inSeconds / 60.0 * 0.1;
    return delayedRetentionGainPct - (timeCost + subjectiveFriction);
  }
}
