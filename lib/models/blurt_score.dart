import 'dart:convert';

/// Result of one Blurt → Compare & Score step.
///
/// Stores what the semantic scorer found so the analytics tab can show a
/// "blurt accuracy trend" over time (perfect for the timeline/history report).
class BlurtScore {
  final int id;
  final int noteId;
  final String noteTitle;
  final DateTime date;
  final double scorePct; // 0..100
  final List<String> matched;
  final List<String> missed;
  // Phase 2 — deterministic + AI metrics
  final int? recallSpeedMs; // time from session start to blurt submit
  final double? depthScore; // AI-only, 0..100
  final double? clarityScore; // AI-only, 0..100

  const BlurtScore({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.date,
    required this.scorePct,
    required this.matched,
    required this.missed,
    this.recallSpeedMs,
    this.depthScore,
    this.clarityScore,
  });

  /// Persistence: see HiveBlurtScoreAdapter in app_database.g.dart.
  /// Export: see data/serialization/export_dto.dart.
}