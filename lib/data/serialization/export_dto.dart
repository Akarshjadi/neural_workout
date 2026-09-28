/// Export serialization DTOs — the single source of truth for backup/export shapes.
///
/// Domain models (Note, Session, BlurtScore, PathwayRecord, Thought) no longer own
/// toMap/fromMap. Hive adapters own persistence; this file owns export formats.
library;

import '../../models/note.dart';
import '../../models/session.dart';
import '../../models/blurt_score.dart';
import '../../models/pathway_record.dart';
import '../../models/thought.dart';
import '../../models/learning_attempt.dart';
import '../../models/feedback_record.dart';
import '../../models/error_record.dart';
import '../../models/delayed_outcome.dart';
import '../../models/intervention.dart';
import '../../models/experiment.dart';
import '../../models/focus_integrity.dart';

/// Serialize a Note for JSON backup export.
Map<String, dynamic> noteToJson(Note n) => {
      'v': 1,
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'kind': n.kind.name,
      'created_at': n.createdAt.toIso8601String(),
      'updated_at': n.updatedAt.toIso8601String(),
      'card': n.card.toMap(),
    };

/// Serialize a Session for JSON backup export.
Map<String, dynamic> sessionToJson(Session s) => {
      'v': 1,
      'id': s.id,
      'date': s.date.toIso8601String(),
      'duration_ms': s.duration.inMilliseconds,
      'steps_completed': s.stepsCompleted,
      'anchor_note_id': s.anchorNoteId,
      'anchor_title': s.anchorTitle,
      'autosave_json': s.autosaveJson,
    };

/// Serialize a BlurtScore for JSON backup export.
Map<String, dynamic> blurtScoreToJson(BlurtScore b) => {
      'v': 1,
      'id': b.id,
      'note_id': b.noteId,
      'note_title': b.noteTitle,
      'date': b.date.toIso8601String(),
      'score_pct': b.scorePct,
      'matched': b.matched,
      'missed': b.missed,
      'recall_speed_ms': b.recallSpeedMs,
      'depth_score': b.depthScore,
      'clarity_score': b.clarityScore,
    };

/// Serialize a PathwayRecord for JSON backup export.
Map<String, dynamic> pathwayRecordToJson(PathwayRecord p) => {
      'v': 1,
      'id': p.id,
      'date': p.date.toIso8601String(),
      'retrieval': p.retrieval,
      'compression': p.compression,
      'association': p.association,
      'explanation': p.explanation,
      'context': p.context,
      'grace_used': p.graceUsed,
    };

/// Serialize a Thought for JSON backup export.
Map<String, dynamic> thoughtToJson(Thought t) => {
      'id': t.id,
      'text': t.text,
      'created_at': t.createdAt.toIso8601String(),
      'tags': t.tags,
      'linked_note_id': t.linkedNoteId,
    };

/// Serialize a LearningAttempt for JSON backup export.
Map<String, dynamic> attemptToJson(LearningAttempt a) => {
      'v': 1,
      'id': a.id,
      'timestamp': a.timestamp.toIso8601String(),
      'target_id': a.knowledgeTargetId,
      'session_id': a.sessionId,
      'test_type': a.testType.name,
      'response': a.response,
      'correctness': a.correctness.name,
      'score_pct': a.scorePct.isNaN ? null : a.scorePct,
      'response_time_ms': a.responseTimeMs,
      'confidence': a.confidence,
      'difficulty': a.difficulty,
      'extras': a.extras,
      'feedback_id': a.feedbackId,
      'error_ids': a.errorIds,
      'intervention_id': a.interventionId,
      'delayed_outcome_id': a.delayedOutcomeId,
      'was_interleaved': a.wasInterleaved,
      'interleave_group_id': a.interleaveGroupId,
      'interleave_reason': a.interleaveReason,
      'acquired_at': a.acquiredAt?.toIso8601String(),
    };

/// Serialize a FeedbackRecord for JSON backup export.
Map<String, dynamic> feedbackToJson(FeedbackRecord f) => {
      'v': 1,
      'id': f.id,
      'attempt_id': f.attemptId,
      'created_at': f.createdAt.toIso8601String(),
      'correctness': f.correctness.name,
      'score_pct': f.scorePct.isNaN ? null : f.scorePct,
      'correct_points': f.correctPoints,
      'missing': f.missing,
      'incorrect': f.incorrect,
      'next_action': f.nextAction,
      'from_ai': f.fromAi,
    };

/// Serialize an ErrorRecord for JSON backup export.
Map<String, dynamic> errorToJson(ErrorRecord e) => {
      'v': 1,
      'id': e.id,
      'attempt_id': e.attemptId,
      'type': e.type.name,
      'source': e.source.name,
      'confidence': e.confidence,
      'evidence': e.evidence,
      'created_at': e.createdAt.toIso8601String(),
    };

/// Serialize a DelayedOutcome for JSON backup export.
Map<String, dynamic> delayedOutcomeToJson(DelayedOutcome d) => {
      'v': 1,
      'id': d.id,
      'target_id': d.knowledgeTargetId,
      'attempt_id': d.attemptId,
      'measured_at': d.measuredAt.toIso8601String(),
      'source_attempt_id': d.sourceAttemptId,
      'bucket': d.bucket.name,
      'elapsed_ms': d.elapsed.inMilliseconds,
      'correctness': d.correctness.name,
      'score_pct': d.scorePct.isNaN ? null : d.scorePct,
      'experiment_id': d.experimentId,
    };

/// Serialize an Intervention for JSON backup export.
Map<String, dynamic> interventionToJson(Intervention i) => {
      'v': 1,
      'id': i.id,
      'created_at': i.createdAt.toIso8601String(),
      'action': i.action.name,
      'reason': i.reason.name,
      'explanation': i.explanation,
      'target_id': i.knowledgeTargetId,
      'contrast_target_id': i.contrastTargetId,
      'attempt_id': i.attemptId,
      'experiment_id': i.experimentId,
      'thresholds': i.thresholds,
    };

/// Serialize an Experiment for JSON backup export.
Map<String, dynamic> experimentToJson(Experiment x) => {
      'v': 1,
      'id': x.id,
      'hypothesis': x.hypothesis,
      'conditions': [
        for (final c in x.conditions)
          {'key': c.key, 'label': c.label, 'action': c.action.name},
      ],
      'outcome_buckets': x.outcomeBuckets.map((b) => b.name).toList(),
      'target_concept_type_filter': x.targetConceptTypeFilter,
      'min_attempts_per_condition': x.minAttemptsPerCondition,
      'started_at': x.startedAt.toIso8601String(),
      'ended_at': x.endedAt?.toIso8601String(),
      'active': x.active,
    };

/// Serialize a FocusIntegrity for JSON backup export.
Map<String, dynamic> focusIntegrityToJson(FocusIntegrity f) => {
      'v': 1,
      'session_id': f.sessionId,
      'planned_duration_ms': f.plannedDuration?.inMilliseconds,
      'actual_duration_ms': f.actualDuration.inMilliseconds,
      'interruptions': f.interruptions,
      'task_switches': f.taskSwitches,
      'abandoned': f.abandoned,
      'completed': f.completed,
      'longest_focus_ms': f.longestFocusMs,
    };
