import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Live state of an in-progress workout wizard, decoupled from the persisted
/// [Session] record used by analytics.
///
/// Unlike the old design (which reused one TextEditingController and never
/// persisted step content), this captures each wizard step's own input so a
/// phone-call / OS kill loses seconds, not the whole session. It serializes to
/// a compact JSON string that [Session.autosaveJson] carries for resume.
///
/// `stepsCompleted` runs 0..7: 0 blurt · 1 compare · 2 cheat sheet · 3 link ·
/// 4 teach · 5 interleave · 6 schedule, and 7 is the terminal "done"
/// transition at which the session is finalized (persisted as 8/8).
class WorkoutSessionState {
  final DateTime start;
  final int stepsCompleted; // 0..8
  final int? anchorNoteId; // resolved source note id (null for a cold-start blurt)
  final String anchorTitle;

  String blurtText; // step 1 raw input
  String cheatSheetText; // step 3 condensed summary
  String linkText; // step 4 relation ("connects to ___ because ___")
  String teachingText; // step 5 explanation

  // Result of the step-1 Blurt analyse, persisted so a resume after the score
  // step (e.g. Compare) rehydrates the score instead of showing a blank gap.
  double? scorePct;
  List<String> scoreMatched;
  List<String> scoreMissed;

  // Phase 6/7 — error-shaped session prompts. Populated by AppState.startSession
  // when planStep produces a non-baseline intervention. Empty strings = no
  // shaped prompt; the blurt page falls back to its default placeholder.
  final String promptQuestion;
  final String promptCue;
  final String interventionExplanation;
  final int? timerSeconds;

  WorkoutSessionState({
    required this.start,
    this.stepsCompleted = 0,
    this.anchorNoteId,
    required this.anchorTitle,
    this.blurtText = '',
    this.cheatSheetText = '',
    this.linkText = '',
    this.teachingText = '',
    this.scorePct,
    this.scoreMatched = const [],
    this.scoreMissed = const [],
    this.promptQuestion = '',
    this.promptCue = '',
    this.interventionExplanation = '',
    this.timerSeconds,
  });

  bool get isComplete => stepsCompleted >= 8;

  Duration elapsed(DateTime at) => at.difference(start);

  static const _unset = Object();

  /// A copy with the given overrides (immutable-style updates).
  /// Uses sentinel `_unset` for nullable/resettable fields so callers can
  /// explicitly pass `null` to clear them.
  WorkoutSessionState copyWith({
    int? stepsCompleted,
    Object? anchorNoteId = _unset,
    String? anchorTitle,
    Object? blurtText = _unset,
    Object? cheatSheetText = _unset,
    Object? linkText = _unset,
    Object? teachingText = _unset,
    Object? scorePct = _unset,
    Object? scoreMatched = _unset,
    Object? scoreMissed = _unset,
    Object? promptQuestion = _unset,
    Object? promptCue = _unset,
    Object? interventionExplanation = _unset,
    Object? timerSeconds = _unset,
  }) =>
      WorkoutSessionState(
        start: start,
        stepsCompleted: stepsCompleted ?? this.stepsCompleted,
        anchorNoteId: identical(anchorNoteId, _unset)
            ? this.anchorNoteId
            : anchorNoteId as int?,
        anchorTitle: anchorTitle ?? this.anchorTitle,
        blurtText: identical(blurtText, _unset)
            ? this.blurtText
            : (blurtText as String? ?? ''),
        cheatSheetText: identical(cheatSheetText, _unset)
            ? this.cheatSheetText
            : (cheatSheetText as String? ?? ''),
        linkText: identical(linkText, _unset)
            ? this.linkText
            : (linkText as String? ?? ''),
        teachingText: identical(teachingText, _unset)
            ? this.teachingText
            : (teachingText as String? ?? ''),
        scorePct: identical(scorePct, _unset)
            ? this.scorePct
            : scorePct as double?,
        scoreMatched: identical(scoreMatched, _unset)
            ? this.scoreMatched
            : (scoreMatched as List<String>? ?? const []),
        scoreMissed: identical(scoreMissed, _unset)
            ? this.scoreMissed
            : (scoreMissed as List<String>? ?? const []),
        promptQuestion: identical(promptQuestion, _unset)
            ? this.promptQuestion
            : (promptQuestion as String? ?? ''),
        promptCue: identical(promptCue, _unset)
            ? this.promptCue
            : (promptCue as String? ?? ''),
        interventionExplanation: identical(interventionExplanation, _unset)
            ? this.interventionExplanation
            : (interventionExplanation as String? ?? ''),
        timerSeconds: identical(timerSeconds, _unset)
            ? this.timerSeconds
            : timerSeconds as int?,
      );

  /// Lossless, escaped JSON (fixes the old hand-rolled, un-escaped serializer).
  String toJson() => jsonEncode({
        'v': 3,
        'start': start.toIso8601String(),
        'stepsCompleted': stepsCompleted,
        'anchorNoteId': anchorNoteId,
        'anchorTitle': anchorTitle,
        'blurt': blurtText,
        'cheatSheet': cheatSheetText,
        'link': linkText,
        'teaching': teachingText,
        'scorePct': scorePct,
        'scoreMatched': scoreMatched,
        'scoreMissed': scoreMissed,
        'promptQuestion': promptQuestion,
        'promptCue': promptCue,
        'interventionExplanation': interventionExplanation,
        'timerSeconds': timerSeconds,
      });

  /// Parses an autosaved blob; returns null for anything malformed/missing.
  static WorkoutSessionState? fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final v = m['v'];
      if (v != 1 && v != 2 && v != 3) return null; // unknown schema — caller falls back to fresh state
      final required = ['v', 'start', 'stepsCompleted', 'anchorTitle'];
      if (!required.every((k) => m.containsKey(k))) return null;
      return WorkoutSessionState(
        start: DateTime.parse(m['start'] as String),
        stepsCompleted: (m['stepsCompleted'] as num).toInt(),
        anchorNoteId: m['anchorNoteId'] as int?,
        anchorTitle: m['anchorTitle'] as String,
        blurtText: m['blurt'] as String? ?? '',
        cheatSheetText: m['cheatSheet'] as String? ?? '',
        linkText: m['link'] as String? ?? '',
        teachingText: m['teaching'] as String? ?? '',
        scorePct: (m['scorePct'] as num?)?.toDouble(),
        scoreMatched: ((m['scoreMatched'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        scoreMissed: ((m['scoreMissed'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        promptQuestion: m['promptQuestion'] as String? ?? '',
        promptCue: m['promptCue'] as String? ?? '',
        interventionExplanation: m['interventionExplanation'] as String? ?? '',
        timerSeconds: (m['timerSeconds'] as num?)?.toInt(),
      );
    } catch (e, st) {
      // Catch ALL errors (TypeError, CastError, FormatException, etc.) — a
      // malformed autosave blob must never crash cold boot. Log for debugging.
      debugPrint('WorkoutSessionState.fromJson: malformed blob: $e\n$st');
      return null;
    }
  }
}