import '../models/error_record.dart';
import '../models/feedback_record.dart';
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';

/// Metacognitive calibration metrics summarizing confidence accuracy.
class CalibrationMetrics {
  final int totalJudgments;
  final double meanConfidence;
  final double meanScorePct;
  final double meanCalibrationError; // positive = overconfident, negative = underconfident
  final double brierScore; // 0..1 (lower is better calibrated)
  final int overconfidentCount;
  final int underconfidentCount;
  final int wellCalibratedCount;

  const CalibrationMetrics({
    required this.totalJudgments,
    required this.meanConfidence,
    required this.meanScorePct,
    required this.meanCalibrationError,
    required this.brierScore,
    required this.overconfidentCount,
    required this.underconfidentCount,
    required this.wellCalibratedCount,
  });

  bool get hasSufficientData => totalJudgments >= 3;
}

/// Diagnosis comparison comparing user self-diagnosis against system/AI diagnosis.
class DiagnosisComparison {
  final int attemptId;
  final ErrorType userDiagnosis;
  final ErrorType systemDiagnosis;
  final bool isAgreed;
  final String note;

  const DiagnosisComparison({
    required this.attemptId,
    required this.userDiagnosis,
    required this.systemDiagnosis,
    required this.isAgreed,
    required this.note,
  });
}

/// Service providing corrective feedback, error classification, and metacognitive calibration.
class FeedbackDiagnosisService {
  const FeedbackDiagnosisService();

  /// Evaluates and builds a structured FeedbackRecord from attempt response and expected points.
  FeedbackRecord generateFeedback({
    required int attemptId,
    required String response,
    required List<String> expectedPoints,
    double? customScore,
    bool fromAi = false,
  }) {
    final cleanResp = response.toLowerCase().trim();
    final correct = <String>[];
    final missing = <String>[];
    final incorrect = <String>[];

    for (final point in expectedPoints) {
      final terms = point.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 3);
      if (terms.isEmpty) continue;
      final termMatches = terms.where((t) => cleanResp.contains(t)).length;
      if (termMatches / terms.length >= 0.5) {
        correct.add(point);
      } else {
        missing.add(point);
      }
    }

    // Score determination
    final double scorePct;
    if (customScore != null) {
      scorePct = customScore.clamp(0.0, 100.0);
    } else if (expectedPoints.isNotEmpty) {
      scorePct = (correct.length / expectedPoints.length * 100.0).clamp(0.0, 100.0);
    } else {
      scorePct = cleanResp.isNotEmpty ? 70.0 : 0.0;
    }

    final correctness = Correctness.fromScorePct(scorePct);

    // Next actionable step
    final String nextAction;
    if (scorePct >= 85) {
      nextAction = 'Verified. Schedule delayed test in FSRS queue.';
    } else if (missing.isNotEmpty) {
      nextAction = 'Review missing concepts: "${missing.first}". Retest in 10 minutes.';
    } else {
      nextAction = 'Perform a self-explanation of the core rule.';
    }

    return FeedbackRecord(
      id: 0,
      attemptId: attemptId,
      createdAt: DateTime.now(),
      correctness: correctness,
      scorePct: scorePct,
      correctPoints: correct,
      missing: missing,
      incorrect: incorrect,
      nextAction: nextAction,
      fromAi: fromAi,
    );
  }

  /// Deterministically infers an ErrorType based on response patterns and score.
  ErrorType diagnoseError({
    required String response,
    required double scorePct,
    int? responseTimeMs,
    int? confidence,
  }) {
    final clean = response.trim().toLowerCase();
    if (clean.isEmpty) return ErrorType.factualRecallFailure;
    if (clean == 'idk' || clean.contains("don't know") || clean.contains('dont know')) {
      return ErrorType.retrievalFailure;
    }
    if (responseTimeMs != null && responseTimeMs < 3000 && clean.split(' ').length < 3) {
      return ErrorType.guessed;
    }
    if (responseTimeMs != null && responseTimeMs > 45000 && scorePct < 50) {
      return ErrorType.timePressure;
    }
    if (confidence != null && confidence >= 80 && scorePct < 50) {
      return ErrorType.conceptualMisunderstanding;
    }
    if (scorePct >= 50 && scorePct < 85) {
      return ErrorType.incompleteReasoning;
    }
    return ErrorType.unknown;
  }

  /// Compares user self-diagnosis against system diagnosis to evaluate diagnostic calibration.
  DiagnosisComparison compareDiagnosis({
    required int attemptId,
    required ErrorType userDiagnosis,
    required ErrorType systemDiagnosis,
  }) {
    final agreed = userDiagnosis == systemDiagnosis ||
        userDiagnosis.family == systemDiagnosis.family;

    final note = agreed
        ? 'Learner and system agree on ${userDiagnosis.family.name} failure pattern.'
        : 'Disagreement: learner diagnosed "${userDiagnosis.label}", system inferred "${systemDiagnosis.label}".';

    return DiagnosisComparison(
      attemptId: attemptId,
      userDiagnosis: userDiagnosis,
      systemDiagnosis: systemDiagnosis,
      isAgreed: agreed,
      note: note,
    );
  }

  /// Calculates calibration metrics across attempts.
  CalibrationMetrics calculateCalibration(List<LearningAttempt> attempts) {
    final withConf = attempts.where((a) => a.confidence != null && !a.scorePct.isNaN).toList();
    if (withConf.isEmpty) {
      return const CalibrationMetrics(
        totalJudgments: 0,
        meanConfidence: 0,
        meanScorePct: 0,
        meanCalibrationError: 0,
        brierScore: 0,
        overconfidentCount: 0,
        underconfidentCount: 0,
        wellCalibratedCount: 0,
      );
    }

    double sumConf = 0;
    double sumScore = 0;
    double sumError = 0;
    double sumBrier = 0;
    int over = 0;
    int under = 0;
    int well = 0;

    for (final a in withConf) {
      final conf = a.confidence!.toDouble();
      final score = a.scorePct;
      final error = conf - score;

      sumConf += conf;
      sumScore += score;
      sumError += error;

      final p = conf / 100.0;
      final o = (score / 100.0).clamp(0.0, 1.0);
      sumBrier += (p - o) * (p - o);

      if (error > 20) {
        over++;
      } else if (error < -20) {
        under++;
      } else {
        well++;
      }
    }

    final count = withConf.length;
    return CalibrationMetrics(
      totalJudgments: count,
      meanConfidence: sumConf / count,
      meanScorePct: sumScore / count,
      meanCalibrationError: sumError / count,
      brierScore: sumBrier / count,
      overconfidentCount: over,
      underconfidentCount: under,
      wellCalibratedCount: well,
    );
  }

  /// Detects metacognitive laziness patterns.
  String? detectMetacognitiveLaziness(List<LearningAttempt> recentAttempts) {
    if (recentAttempts.length < 2) return null;
    final lastThree = recentAttempts.take(3).toList();

    int lowEffortCount = 0;
    for (final a in lastThree) {
      final text = a.response.trim().toLowerCase();
      if (text.isEmpty || text == 'idk' || text.split(' ').length <= 2) {
        lowEffortCount++;
      }
    }

    if (lowEffortCount >= 2) {
      return 'Friction Rule Triggered: Commit to a 1-sentence retrieval hypothesis before viewing feedback.';
    }
    return null;
  }

  /// Item 34 — error recurrence tracking.
  ///
  /// Counts how often each [ErrorType] (and each [ErrorFamily]) reappears, so
  /// "do I keep making the same *kind* of mistake?" is answerable. Sorted
  /// descending by count; ties broken by enum order for determinism.
  static List<({ErrorType type, int count})> errorRecurrence(
      List<ErrorRecord> errors) {
    final counts = <ErrorType, int>{};
    for (final e in errors) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    final out = [
      for (final entry in counts.entries)
        (type: entry.key, count: entry.value),
    ];
    out.sort((a, b) => b.count != a.count
        ? b.count.compareTo(a.count)
        : a.type.index.compareTo(b.type.index));
    return out;
  }

  /// Errors still recurring inside the last [window] days — the ones worth
  /// intervening on. A single historical occurrence is not a pattern.
  static List<({ErrorType type, int count})> recurringErrors(
    List<ErrorRecord> errors, {
    int window = 14,
    int minOccurrences = 2,
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: window));
    final recent = errors.where((e) => e.createdAt.isAfter(cutoff)).toList();
    return errorRecurrence(recent)
        .where((r) => r.count >= minOccurrences)
        .toList();
  }

  /// Item 33 — hyper-correction tracking.
  ///
  /// Hyper-correction is the failure mode where corrective feedback overshoots:
  /// the learner *knew* it, was told they were wrong, and now over-hedges or
  /// drops the correct answer. Detected as a post-correction reversal on the
  /// same target — a pass, then a confident failure, then a loss of confidence
  /// on the following attempt.
  ///
  /// Returned per target so the caller can decide whether to stop correcting
  /// and instead re-verify. Pure and deterministic.
  static List<int> hyperCorrectedTargets(List<LearningAttempt> attempts) {
    final byTarget = <int, List<LearningAttempt>>{};
    for (final a in attempts) {
      final id = a.knowledgeTargetId;
      if (id == null) continue;
      byTarget.putIfAbsent(id, () => []).add(a);
    }

    final flagged = <int>[];
    for (final entry in byTarget.entries) {
      final list = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (list.length < 3) continue;

      for (int i = 2; i < list.length; i++) {
        final first = list[i - 2];
        final second = list[i - 1];
        final third = list[i];

        final hadIt = !first.correctness.isFail;
        final confidenceCrash = (first.confidence ?? 0) -
                (third.confidence ?? 0) >=
            20;
        final reversedIntoFailure =
            hadIt && second.correctness.isFail && confidenceCrash;

        if (reversedIntoFailure) {
          flagged.add(entry.key);
          break; // one occurrence is enough to flag the target
        }
      }
    }
    return flagged;
  }
}

