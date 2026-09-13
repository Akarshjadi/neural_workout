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

  /// Convenience with title embedded for simple list renders.
  Map<String, dynamic> toMap() => {
        'v': 1,
        'id': id,
        'note_id': noteId,
        'note_title': noteTitle,
        'date': date.toIso8601String(),
        'score_pct': scorePct,
        'matched': jsonEncode(matched),
        'missed': jsonEncode(missed),
        'recall_speed_ms': recallSpeedMs,
        'depth_score': depthScore,
        'clarity_score': clarityScore,
      };

  static List<String> _parseList(dynamic raw) {
    if (raw is List) return raw.cast<String>();
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {
        return raw.split('\n').where((e) => e.isNotEmpty).toList();
      }
    }
    return const [];
  }

  factory BlurtScore.fromMap(Map<String, dynamic> m) => BlurtScore(
        id: m['id'] as int,
        noteId: m['note_id'] as int,
        noteTitle: m['note_title'] as String? ?? '',
        date: DateTime.parse(m['date'] as String),
        scorePct: (m['score_pct'] as num).toDouble(),
        matched: _parseList(m['matched']),
        missed: _parseList(m['missed']),
        recallSpeedMs: m['recall_speed_ms'] as int?,
        depthScore: (m['depth_score'] as num?)?.toDouble(),
        clarityScore: (m['clarity_score'] as num?)?.toDouble(),
      );
}