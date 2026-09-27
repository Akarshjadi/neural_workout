/// Semantic (NOT verbatim) scoring of a Blurt against a source note.
///
/// The whole point is to reward RECALL — recalling a concept in your own words
/// should score correctly. We are deliberately NOT rewarding copy-paste
/// fidelity (that would punish the Feynman "explain in your own words" skill
/// this app exists to build).
///
/// Matching is three-tiered, each counts as "recalled":
///   1. exact keyword present in the blur
///   2. stemmed form matches (networks ~ network)
///   3. a known synonym/alias of the concept is present
///
/// This is one of the three "real risks" in the plan (silent logic bugs that
/// quietly miscalculate for months), so it gets direct unit tests.
class BlurtScorer {
  /// Default threshold for Levenshtein fuzzy similarity matching (0.8 = at most ~20% character difference).
  static const double defaultFuzzyThreshold = 0.8;

  /// Minimum concept keyword length required to attempt fuzzy matching (avoids matching short noise).
  static const int _minConceptLengthForFuzzy = 5;

  /// Minimum word length required for fuzzy matching (prevents tiny word false positives).
  static const int _minWordLengthForFuzzy = 3;

  /// Concept keywords extracted from the source note body.
  final List<String> sourceConcepts;

  /// User-grown alias table: kebab concept -> list of acceptable alternatives.
  final Map<String, List<String>> synonymAliases;

  /// Fuzzy containment threshold: 0..1 Levenshtein ratio above which we count
  /// a near-match as recalled (handles typos / light paraphrase).
  final double fuzzyThreshold;

  BlurtScorer({
    required String sourceBody,
    this.synonymAliases = const {},
    this.fuzzyThreshold = defaultFuzzyThreshold,
  }) : sourceConcepts = extractConcepts(sourceBody);

  /// Pulls candidate concept keywords out of a body of text.
  static List<String> extractConcepts(String body) {
    final tokens = body
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 2)
        .toList();
    const stop = {
      'the', 'and', 'for', 'are', 'you', 'that', 'with', 'this', 'from',
      'your', 'have', 'will', 'what', 'when', 'why', 'how', 'per', 'its',
      'each', 'these', 'their', 'into', 'over', 'about', 'does',
    };
    return tokens.where((t) => !stop.contains(t)).toSet().toList();
  }

  /// Core scoring entry point.
  ScoreResult score(String blurt) {
    final blurWords = _normalize(blurt);
    final matched = <String>[];
    final missed = <String>[];

    for (final concept in sourceConcepts) {
      final stemmed = stem(concept);
      final aliases = synonymAliases[concept] ?? const <String>[];

      bool found = blurWords.contains(concept) ||
          blurWords.contains(stemmed) ||
          aliases.any((a) => blurWords.contains(a) || blurWords.contains(stem(a)));

      if (!found && concept.length >= _minConceptLengthForFuzzy && blurWords.isNotEmpty) {
        for (final w in blurWords) {
          // Cheap pre-filter: skip words whose length differs too much from the
          // concept — Levenshtein ratio can never exceed 1 - delta/maxLen.
          if ((w.length - concept.length).abs() > 2) continue;
          // Similarity = 1 - normalized edit distance. A 0.8 threshold means
          // at most ~20% of characters differ (typos / light inflection).
          final maxLen = w.length > concept.length ? w.length : concept.length;
          final similarity = 1 - _levenshtein(w, concept) / maxLen;
          if (w.length >= _minWordLengthForFuzzy && similarity >= fuzzyThreshold) {
            found = true;
            break;
          }
        }
      }

      found ? matched.add(concept) : missed.add(concept);
    }

    final pct = sourceConcepts.isEmpty
        ? 0.0
        : (matched.length / sourceConcepts.length * 100);
    return ScoreResult(
      scorePct: pct,
      matched: matched,
      missed: missed,
      sourceConcepts: sourceConcepts,
    );
  }

  /// Coarse suffix stripping so plural/tense variants unify.
  /// 'ies' -> 'y' (studies -> study), else strip 'es'/'s'/'ed'/'ing'.
  static String stem(String w) {
    final s = w.toLowerCase();
    if (s.length > 4 && s.endsWith('ies')) {
      return '${s.substring(0, s.length - 3)}y';
    }
    for (final suffix in const ['es', 'ed', 'ing', 's']) {
      if (s.length > 4 && s.endsWith(suffix)) {
        return s.substring(0, s.length - suffix.length);
      }
    }
    return s;
  }

  Set<String> _normalize(String s) => s
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toSet();

  /// Standard Levenshtein distance (edit distance) using a two-row rolling buffer.
  static int _levenshtein(String a, String b) {
    if (a.length < b.length) { final t = a; a = b; b = t; }
    final m = a.length, n = b.length;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      final t = prev; prev = curr; curr = t;
    }
    return prev[n];
  }
}

/// Plain-result holder (no id/note wiring — the data layer adds those).
class ScoreResult {
  final double scorePct;
  final List<String> matched;
  final List<String> missed;
  final List<String> sourceConcepts;
  /// AI-only subjective metrics (null when computed by BlurtScorer fallback).
  final double? depthScore;
  final double? clarityScore;

  const ScoreResult({
    required this.scorePct,
    required this.matched,
    required this.missed,
    required this.sourceConcepts,
    this.depthScore,
    this.clarityScore,
  });
}