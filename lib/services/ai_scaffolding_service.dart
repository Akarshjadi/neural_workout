import '../models/knowledge_evidence.dart';
import '../models/note.dart';

/// Levels of AI assistance in pedagogical scaffolding.
enum ScaffoldingLevel {
  none, // human only (independent retrieval)
  hint, // single keyword or boundary hint
  targetedQuestion, // socratic guiding question
  partialExplanation, // partial reasoning structure
  workedExample, // step-by-step worked demonstration
  fullExplanation; // complete answer revelation

  String get label => switch (this) {
        ScaffoldingLevel.none => 'No Help (Independent)',
        ScaffoldingLevel.hint => 'Subtle Hint',
        ScaffoldingLevel.targetedQuestion => 'Socratic Question',
        ScaffoldingLevel.partialExplanation => 'Partial Explanation',
        ScaffoldingLevel.workedExample => 'Worked Example',
        ScaffoldingLevel.fullExplanation => 'Full Solution',
      };
}

/// Source attribution for a learning response.
enum AttributionSource {
  humanRetrieved,
  aiAssisted,
  aiGenerated,
  copiedImported;

  bool get countsAsIndependentHumanEvidence =>
      this == AttributionSource.humanRetrieved;
}

/// Scaffolding state for a learning prompt.
class ScaffoldingState {
  final ScaffoldingLevel currentLevel;
  final String text;
  final AttributionSource attribution;

  const ScaffoldingState({
    required this.currentLevel,
    required this.text,
    required this.attribution,
  });
}

/// Service managing dynamic AI assistance fading and Socratic dialogue.
class AiScaffoldingService {
  const AiScaffoldingService();

  /// Determines appropriate starting scaffold level based on knowledge state.
  ScaffoldingLevel determineInitialScaffold(KnowledgeState state) {
    switch (state) {
      case KnowledgeState.stable:
      case KnowledgeState.verified:
        return ScaffoldingLevel.none;
      case KnowledgeState.probable:
      case KnowledgeState.developing:
        return ScaffoldingLevel.none;
      case KnowledgeState.unstable:
      case KnowledgeState.bottleneck:
        return ScaffoldingLevel.hint;
      case KnowledgeState.unknown:
        return ScaffoldingLevel.none;
    }
  }

  /// Generates scaffolded assistance text for a note at a specific level.
  ScaffoldingState generateScaffold({
    required Note note,
    required ScaffoldingLevel level,
  }) {
    final title = note.title.trim();
    final body = note.body.trim();

    switch (level) {
      case ScaffoldingLevel.none:
        return const ScaffoldingState(
          currentLevel: ScaffoldingLevel.none,
          text: '',
          attribution: AttributionSource.humanRetrieved,
        );

      case ScaffoldingLevel.hint:
        final firstSentence = body.split(RegExp(r'[.\n]')).first.trim();
        final words = firstSentence.split(' ').take(5).join(' ');
        return ScaffoldingState(
          currentLevel: ScaffoldingLevel.hint,
          text: 'Hint: Think about "$title" in connection with: $words...',
          attribution: AttributionSource.aiAssisted,
        );

      case ScaffoldingLevel.targetedQuestion:
        return ScaffoldingState(
          currentLevel: ScaffoldingLevel.targetedQuestion,
          text: 'Socratic Prompt: What is the primary operational rule or assumption governing "$title"?',
          attribution: AttributionSource.aiAssisted,
        );

      case ScaffoldingLevel.partialExplanation:
        final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final partial = lines.take(2).join('\n');
        return ScaffoldingState(
          currentLevel: ScaffoldingLevel.partialExplanation,
          text: 'Partial outline:\n$partial\n[Complete the remaining mechanism]',
          attribution: AttributionSource.aiAssisted,
        );

      case ScaffoldingLevel.workedExample:
        return ScaffoldingState(
          currentLevel: ScaffoldingLevel.workedExample,
          text: 'Worked Example for "$title":\n$body',
          attribution: AttributionSource.aiAssisted,
        );

      case ScaffoldingLevel.fullExplanation:
        return ScaffoldingState(
          currentLevel: ScaffoldingLevel.fullExplanation,
          text: 'Complete Reference:\n$body',
          attribution: AttributionSource.aiGenerated,
        );
    }
  }

  /// Escalates scaffold level on failure or struggle.
  ScaffoldingLevel escalate(ScaffoldingLevel current) {
    return switch (current) {
      ScaffoldingLevel.none => ScaffoldingLevel.hint,
      ScaffoldingLevel.hint => ScaffoldingLevel.targetedQuestion,
      ScaffoldingLevel.targetedQuestion => ScaffoldingLevel.partialExplanation,
      ScaffoldingLevel.partialExplanation => ScaffoldingLevel.workedExample,
      ScaffoldingLevel.workedExample => ScaffoldingLevel.fullExplanation,
      ScaffoldingLevel.fullExplanation => ScaffoldingLevel.fullExplanation,
    };
  }

  /// Fades scaffold level when learner demonstrates success.
  ScaffoldingLevel fade(ScaffoldingLevel current) {
    return switch (current) {
      ScaffoldingLevel.fullExplanation => ScaffoldingLevel.partialExplanation,
      ScaffoldingLevel.workedExample => ScaffoldingLevel.targetedQuestion,
      ScaffoldingLevel.partialExplanation => ScaffoldingLevel.hint,
      ScaffoldingLevel.targetedQuestion => ScaffoldingLevel.hint,
      ScaffoldingLevel.hint => ScaffoldingLevel.none,
      ScaffoldingLevel.none => ScaffoldingLevel.none,
    };
  }

  /// Alias for generating scaffolded prompt text.
  String generateScaffoldPrompt({
    required Note note,
    required ScaffoldingLevel level,
  }) =>
      generateScaffold(note: note, level: level).text;

  /// Alias for generating discrimination contrast prompt between two notes.
  String generateContrastPrompt({
    required Note a,
    required Note b,
  }) =>
      'How does "${a.title}" differ from "${b.title}"?';

  /// Alias for generating analogy bridge between source and target notes.
  String generateAnalogyBridge({
    required Note source,
    required Note target,
  }) =>
      'Consider the structural analogy bridging "${source.title}" and "${target.title}".';
}
