import 'learning_enums.dart';

/// Structured error taxonomy (§12).
///
/// Deliberately a closed enum, not free text: recurrence analytics ("do I keep
/// making this *kind* of mistake?") is impossible over prose, and the whole
/// point of diagnosis is to pick a different intervention, which requires a
/// stable key to branch on.
enum ErrorType {
  conceptualMisunderstanding,
  factualRecallFailure,
  retrievalFailure,
  formulaFailure,
  wrongMethod,
  wrongAssumption,
  calculationError,
  logicalError,
  misread,
  carelessError,
  confusedConcepts,
  incompleteReasoning,
  guessed,
  timePressure,
  unknown;

  String get label => switch (this) {
        ErrorType.conceptualMisunderstanding => 'Conceptual misunderstanding',
        ErrorType.factualRecallFailure => 'Factual recall failure',
        ErrorType.retrievalFailure => 'Knew it but could not retrieve it',
        ErrorType.formulaFailure => 'Formula failure',
        ErrorType.wrongMethod => 'Wrong method',
        ErrorType.wrongAssumption => "Wrong assumption",
        ErrorType.calculationError => 'Calculation error',
        ErrorType.logicalError => 'Logical error',
        ErrorType.misread => 'Misread the question',
        ErrorType.carelessError => 'Careless error',
        ErrorType.confusedConcepts => 'Confused two concepts',
        ErrorType.incompleteReasoning => 'Incomplete reasoning',
        ErrorType.guessed => 'Guessed',
        ErrorType.timePressure => 'Ran out of time',
        ErrorType.unknown => 'Unknown',
      };

  /// Which intervention this error family suggests. Consumed by
  /// InterventionEngine — kept beside the taxonomy so the mapping is auditable
  /// in one place instead of scattered through the UI.
  ErrorFamily get family => switch (this) {
        ErrorType.conceptualMisunderstanding => ErrorFamily.conceptual,
        ErrorType.confusedConcepts => ErrorFamily.conceptual,
        ErrorType.wrongAssumption => ErrorFamily.conceptual,
        ErrorType.logicalError => ErrorFamily.conceptual,
        ErrorType.wrongMethod => ErrorFamily.procedural,
        ErrorType.formulaFailure => ErrorFamily.procedural,
        ErrorType.calculationError => ErrorFamily.procedural,
        ErrorType.incompleteReasoning => ErrorFamily.procedural,
        ErrorType.factualRecallFailure => ErrorFamily.retrieval,
        ErrorType.retrievalFailure => ErrorFamily.retrieval,
        ErrorType.guessed => ErrorFamily.retrieval,
        ErrorType.misread => ErrorFamily.attention,
        ErrorType.carelessError => ErrorFamily.attention,
        ErrorType.timePressure => ErrorFamily.attention,
        ErrorType.unknown => ErrorFamily.unknown,
      };

  /// Self-diagnosis options offered to the learner after a failure (§14),
  /// in the order the UI shows them. `unknown` is intentionally absent — the
  /// learner picks "Other" which maps to it via [fromSelfDiagnosisLabel].
  static const List<ErrorType> selfDiagnosisOptions = [
    ErrorType.factualRecallFailure,
    ErrorType.retrievalFailure,
    ErrorType.wrongMethod,
    ErrorType.misread,
    ErrorType.confusedConcepts,
    ErrorType.calculationError,
    ErrorType.guessed,
    ErrorType.timePressure,
    ErrorType.carelessError,
  ];

  /// Maps the plain-language self-diagnosis strings to the taxonomy. Anything
  /// unrecognised becomes [ErrorType.unknown] rather than throwing — a free-text
  /// answer must never break the flow.
  static ErrorType fromSelfDiagnosisLabel(String label) {
    final l = label.trim().toLowerCase();
    if (l.isEmpty) return ErrorType.unknown;
    for (final e in ErrorType.values) {
      if (e.label.toLowerCase() == l) return e;
    }
    if (l.contains('didn\'t know') || l.contains('did not know')) {
      return ErrorType.factualRecallFailure;
    }
    if (l.contains('couldn\'t retrieve') || l.contains('knew it')) {
      return ErrorType.retrievalFailure;
    }
    if (l.contains('method')) return ErrorType.wrongMethod;
    if (l.contains('underst')) return ErrorType.conceptualMisunderstanding;
    if (l.contains('confus')) return ErrorType.confusedConcepts;
    if (l.contains('calculat')) return ErrorType.calculationError;
    if (l.contains('guess')) return ErrorType.guessed;
    if (l.contains('time')) return ErrorType.timePressure;
    if (l.contains('careless')) return ErrorType.carelessError;
    if (l.contains('misread')) return ErrorType.misread;
    return ErrorType.unknown;
  }

  static ErrorType? tryParse(String? name) {
    if (name == null) return null;
    for (final v in ErrorType.values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Coarse grouping used for intervention selection. Two errors in the same
/// family suggest the same next action, which is what makes the policy engine
/// stable across subjects.
enum ErrorFamily { conceptual, procedural, retrieval, attention, unknown }

/// One diagnosed error attached to one attempt.
///
/// Multiple errors per attempt are allowed (§12) and the learner is never
/// forced to pick one. The three sources stay separable so diagnostic
/// calibration (user said X, deterministic evidence said Y) is measurable.
class ErrorRecord {
  final int id;
  final int attemptId;
  final ErrorType type;
  final DiagnosisSource source;

  /// 0..1. Produced by the classifier; `user` source freely reports 1.0.
  final double confidence;

  /// Short human-readable justification ("3 of 9 concepts recalled", or the
  /// model's one-line reason). Bounded in length by the producers.
  final String evidence;

  final DateTime createdAt;
  final int? confusedConceptId;

  const ErrorRecord({
    required this.id,
    required this.attemptId,
    required this.type,
    required this.source,
    this.confidence = 1.0,
    this.evidence = '',
    required this.createdAt,
    this.confusedConceptId,
  });

  ErrorFamily get family => type.family;

  /// Alias for self-diagnosed error category from user source.
  ErrorType get selfDiagnosedCategory =>
      source == DiagnosisSource.user ? type : ErrorType.unknown;

  /// Alias for system-diagnosed error category from non-user source.
  ErrorType get systemDiagnosedCategory =>
      source != DiagnosisSource.user ? type : ErrorType.unknown;

  /// Requires a paired record on the same attemptId from a different source; this single record cannot detect disagreement on its own. Use `FeedbackDiagnosisService.compareDiagnosis` for that.
  bool get isDisagreement => false;
}

/// Typedef alias for ErrorType.
typedef CognitiveErrorCategory = ErrorType;
