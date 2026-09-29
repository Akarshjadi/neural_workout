import '../models/pathway_record.dart';

/// Pathway activation formula (PLAN §8) — the single source of truth.
///
/// activation% = min(100, (steps_completed_this_week / weekly_target) )
///
/// Default weekly targets: Retrieval 7, Compression 5, Association 5,
/// Explanation 4, Context 4. User-adjustable in settings.
class PathwayService {
  static const Map<String, int> defaultTargets = {
    'retrieval': 7,
    'compression': 5,
    'association': 5,
    'explanation': 4,
    'context': 4,
  };

  final Map<String, int> _targets;

  PathwayService({Map<String, int>? targets})
      : _targets = {
          ...defaultTargets,
          if (targets != null) for (final e in targets.entries) e.key: e.value < 1 ? 1 : e.value,
        };

  /// Current weekly targets (read-only view for settings/UI, issue 12).
  Map<String, int> get targets => Map.unmodifiable(_targets);

  /// Returns each pathway's activation as a 0..100 value for the given week's
  /// activity records, plus a text label for accessibility (no color-only).
  Map<String, PathwayInfo> computeWeek(List<PathwayRecord> weekRecords) {
    final counts = <String, int>{
      'retrieval': 0,
      'compression': 0,
      'association': 0,
      'explanation': 0,
      'context': 0,
    };

    for (final r in weekRecords) {
      if (r.retrieval) counts['retrieval'] = counts['retrieval']! + 1;
      if (r.compression) counts['compression'] = counts['compression']! + 1;
      if (r.association) counts['association'] = counts['association']! + 1;
      if (r.explanation) counts['explanation'] = counts['explanation']! + 1;
      if (r.context) counts['context'] = counts['context']! + 1;
    }

    final out = <String, PathwayInfo>{};
    for (final name in counts.keys) {
      final target = _targets[name]!;
      final done = counts[name]!;
      final pct = (done / target * 100).clamp(0, 100).toDouble();
      out[name] = PathwayInfo(
        key: name,
        label: _labels[name]!,
        completed: done,
        target: target,
        percent: pct,
      );
    }
    return out;
  }

  static const Map<String, String> _labels = {
    'retrieval': 'Retrieval',
    'compression': 'Compression',
    'association': 'Association',
    'explanation': 'Explanation',
    'context': 'Context',
  };
}

class PathwayInfo {
  final String key;
  final String label;
  final int completed;
  final int target;
  final double percent;

  const PathwayInfo({
    required this.key,
    required this.label,
    required this.completed,
    required this.target,
    required this.percent,
  });

  /// Trend direction is computed externally (this object is weekly-scoped).
  String get barText => '$label $completed/$target';
}