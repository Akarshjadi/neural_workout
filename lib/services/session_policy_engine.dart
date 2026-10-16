import '../models/delayed_outcome.dart';
import '../models/error_record.dart';
import '../models/focus_integrity.dart';
import '../models/intervention.dart';
import '../models/knowledge_evidence.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import '../models/note.dart';
import 'adaptive_intervention_service.dart';
import 'ai_scaffolding_service.dart';
import 'delayed_outcome_service.dart';
import 'feedback_diagnosis_service.dart';
import 'retrieval_engine.dart';

/// Recommendation for an upcoming session step.
class SessionPlanStep {
  final Note targetNote;
  final TestType testType;
  final ScaffoldingLevel scaffoldLevel;
  final Intervention intervention;
  final RetrievalPrompt prompt;
  final Map<String, int> thresholds;

  const SessionPlanStep({
    required this.targetNote,
    required this.testType,
    required this.scaffoldLevel,
    required this.intervention,
    required this.prompt,
    this.thresholds = const {},
  });
}

/// Central Policy Engine orchestrating the research-driven study workflow.
class SessionPolicyEngine {
  final RetrievalEngine retrievalEngine;
  final FeedbackDiagnosisService feedbackService;
  final AdaptiveInterventionService interventionService;
  final AiScaffoldingService scaffoldingService;
  final DelayedOutcomeService delayedService;

  const SessionPolicyEngine({
    this.retrievalEngine = const RetrievalEngine(),
    this.feedbackService = const FeedbackDiagnosisService(),
    this.interventionService = const AdaptiveInterventionService(),
    this.scaffoldingService = const AiScaffoldingService(),
    this.delayedService = const DelayedOutcomeService(),
  });

  /// Plans the next learning step for a targeted note based on all evidence.
  SessionPlanStep planStep({
    required Note note,
    required ConceptType conceptType,
    required List<LearningAttempt> noteAttempts,
    required List<ErrorRecord> noteErrors,
    required List<DelayedOutcome> noteDelayedOutcomes,
    required KnowledgeEvidence knowledgeEvidence,
    Note? contrastNote,
    DateTime? now,
    List<InterventionConceptMatch> empirical = const [],
  }) {
    final currentTime = now ?? DateTime.now();

    // 1. Check if due for a delayed test
    final isDueDelayed = noteAttempts.isNotEmpty && delayedService.isDueForDelayedTest(
      sourceAttempt: noteAttempts.last,
      existingOutcomes: noteDelayedOutcomes,
      now: currentTime,
    );

    // 2. Select intervention
    final intervention = isDueDelayed
        ? (empirical.isNotEmpty 
            ? interventionService.matchByEmpiricalData(
                targetId: note.id,
            conceptType: conceptType,
                empirical: empirical,
                contrastTargetId: contrastNote?.id,
              )
            : Intervention(
                id: 0,
                createdAt: currentTime,
                action: InterventionAction.retrieve,
                reason: InterventionReason.dueForDelayedTest,
                explanation: 'Concept is due for a delayed retention test.',
                knowledgeTargetId: note.id,
              ))
        : interventionService.decideIntervention(
            targetId: note.id,
            targetAttempts: noteAttempts,
            targetErrors: noteErrors,
            knowledgeState: knowledgeEvidence.state,
            contrastTargetId: contrastNote?.id,
            empirical: empirical,
          );

    // 3. Map action to test type
    final testType = isDueDelayed
        ? TestType.freeRecall
        : (intervention.effectiveTestType ?? TestType.cuedRecall);

    // 4. Determine AI scaffolding level
    final scaffoldLevel = scaffoldingService.determineInitialScaffold(knowledgeEvidence.state);

    // 5. Generate prompt
    final prompt = retrievalEngine.generatePrompt(
      note: note,
      testType: testType,
      contrastNote: contrastNote,
    );

    return SessionPlanStep(
      targetNote: note,
      testType: testType,
      scaffoldLevel: scaffoldLevel,
      intervention: intervention,
      prompt: prompt,
      thresholds: intervention.thresholds,
    );
  }

  /// Generates a warm-up prompt for session readiness & baseline calibration.
  RetrievalPrompt generateWarmup({
    required Note note,
  }) {
    return retrievalEngine.generatePrompt(
      note: note,
      testType: TestType.cuedRecall,
    );
  }

  /// Alias/heuristic: Recommends session duration based on knowledge state and focus history.
  /// Note: This is a pedagogical heuristic, not a physiological measurement.
  Duration recommendSessionDuration({
    required KnowledgeEvidence evidence,
    required List<FocusIntegrity> focusHistory,
  }) {
    double minutes = 20.0;
    if (evidence.state == KnowledgeState.stable ||
        evidence.state == KnowledgeState.verified) {
      minutes += 10.0;
    } else if (evidence.state == KnowledgeState.developing ||
        evidence.state == KnowledgeState.unstable) {
      minutes -= 10.0;
    }

    if (focusHistory.isNotEmpty) {
      final meanActual = focusHistory.fold<double>(
              0.0, (acc, f) => acc + f.actualDuration.inMinutes) /
          focusHistory.length;
      minutes = (minutes * 0.7) + (meanActual * 0.3);
    }

    final clampedMinutes = minutes.clamp(10.0, 45.0).round();
    return Duration(minutes: clampedMinutes);
  }

  /// Alias/heuristic: Recommends next break timing.
  /// Note: Pedagogical rule-of-thumb; there is no physiological sensor behind this.
  Duration recommendBreakTiming({
    required Duration sessionElapsed,
    required KnowledgeEvidence evidence,
  }) {
    if (sessionElapsed.inMinutes >= 25) {
      return sessionElapsed + const Duration(minutes: 5);
    }
    return const Duration(minutes: 25);
  }
}
