import 'dart:math' as math;
import '../models/learning_attempt.dart';
import '../models/learning_enums.dart';
import '../models/note.dart';

/// Prompt and configuration for a retrieval exercise.
class RetrievalPrompt {
  final TestType testType;
  final int? targetNoteId;
  final String targetTitle;
  final String question;
  final String contextCue;
  final List<String> expectedKeyPoints;
  final String? contrastTargetTitle;
  final int? contrastTargetId;
  final List<String> fadedSteps;

  const RetrievalPrompt({
    required this.testType,
    this.targetNoteId,
    required this.targetTitle,
    required this.question,
    this.contextCue = '',
    this.expectedKeyPoints = const [],
    this.contrastTargetTitle,
    this.contrastTargetId,
    this.fadedSteps = const [],
  });
}

/// Multi-format retrieval engine generating diverse cognitive practice exercises.
class RetrievalEngine {
  const RetrievalEngine();

  /// Generates a structured retrieval prompt based on test type and source note.
  RetrievalPrompt generatePrompt({
    required Note note,
    required TestType testType,
    Note? contrastNote,
    int fadedStepLevel = 1,
  }) {
    final title = note.title.trim();
    final body = note.body.trim();
    final keyPoints = _extractKeyPoints(body);

    switch (testType) {
      case TestType.freeRecall:
        return RetrievalPrompt(
          testType: TestType.freeRecall,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Recall everything you know about "$title" without looking at notes.',
          contextCue: 'Free recall (unprompted)',
          expectedKeyPoints: keyPoints,
        );

      case TestType.cuedRecall:
        final cue = keyPoints.isNotEmpty ? keyPoints.first : title;
        return RetrievalPrompt(
          testType: TestType.cuedRecall,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'What is the core definition and mechanism of "$title"?',
          contextCue: 'Cue: $cue',
          expectedKeyPoints: keyPoints,
        );

      case TestType.explanation:
        return RetrievalPrompt(
          testType: TestType.explanation,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Why does "$title" work the way it does? Explain the underlying cause as if teaching a peer.',
          contextCue: 'Self-Explanation / Feynman prompt',
          expectedKeyPoints: keyPoints,
        );

      case TestType.application:
        return RetrievalPrompt(
          testType: TestType.application,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'In a real-world scenario with a bottleneck related to "$title", how would you resolve it?',
          contextCue: 'Concrete Application',
          expectedKeyPoints: keyPoints,
        );

      case TestType.discrimination:
        final contrastTitle = contrastNote?.title.trim() ?? 'a related alternative concept';
        final contrastKeyPoints = contrastNote != null ? _extractKeyPoints(contrastNote.body) : <String>[];
        return RetrievalPrompt(
          testType: TestType.discrimination,
          targetNoteId: note.id,
          targetTitle: title,
          contrastTargetId: contrastNote?.id,
          contrastTargetTitle: contrastTitle,
          question: 'How does "$title" differ from "$contrastTitle"? Which conditions favor one over the other?',
          contextCue: 'Contrastive Discrimination',
          expectedKeyPoints: [...keyPoints, ...contrastKeyPoints],
        );

      case TestType.reconstruction:
        final steps = _extractSteps(body);
        final faded = _fadeSteps(steps, fadedStepLevel);
        return RetrievalPrompt(
          testType: TestType.reconstruction,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Complete the missing reasoning steps below for "$title":',
          contextCue: 'Faded Worked Example (Level $fadedStepLevel)',
          fadedSteps: faded,
          expectedKeyPoints: steps,
        );

      case TestType.pretest:
        return RetrievalPrompt(
          testType: TestType.pretest,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Before studying "$title": What do you predict are its primary rules or mechanisms?',
          contextCue: 'Prequestioning / Pretest',
          expectedKeyPoints: keyPoints,
        );

      case TestType.transfer:
        return RetrievalPrompt(
          testType: TestType.transfer,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Suppose the operating environment changes completely. How does the fundamental invariant of "$title" hold?',
          contextCue: 'Far-Transfer Retrieval',
          expectedKeyPoints: keyPoints,
        );

      case TestType.workedExample:
        return RetrievalPrompt(
          testType: TestType.workedExample,
          targetNoteId: note.id,
          targetTitle: title,
          question: 'Study this complete worked explanation of "$title":',
          contextCue: 'Worked Example Study',
          fadedSteps: _extractSteps(body),
          expectedKeyPoints: keyPoints,
        );
    }
  }

  /// Deterministic scoring helper when offline / AI unavailable.
  double evaluateDeterministicScore(String response, List<String> expectedKeyPoints) {
    final cleanResp = response.toLowerCase().trim();
    if (cleanResp.isEmpty) return 0.0;
    if (expectedKeyPoints.isEmpty) {
      final wordCount = cleanResp.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      return (wordCount / 30.0 * 100.0).clamp(10.0, 100.0);
    }

    int matched = 0;
    for (final point in expectedKeyPoints) {
      final terms = point.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 3);
      if (terms.isEmpty) continue;
      final termMatches = terms.where((t) => cleanResp.contains(t)).length;
      if (termMatches / terms.length >= 0.5) {
        matched++;
      }
    }

    final ratio = matched / expectedKeyPoints.length;
    return (ratio * 100.0).clamp(0.0, 100.0);
  }

  List<String> _extractKeyPoints(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final points = <String>[];
    for (final line in lines) {
      if (line.startsWith('-') || line.startsWith('*') || RegExp(r'^\d+\.').hasMatch(line)) {
        points.add(line.replaceAll(RegExp(r'^[-*\d\.\s]+'), '').trim());
      } else if (line.contains(':')) {
        points.add(line);
      }
    }
    if (points.isEmpty && lines.isNotEmpty) {
      return lines.take(5).toList();
    }
    return points.take(7).toList();
  }

  List<String> _extractSteps(String text) {
    final points = _extractKeyPoints(text);
    if (points.isNotEmpty) return points;
    return [
      'Understand core premise',
      'Identify governing constraints',
      'Derive intermediate relations',
      'Verify boundary conditions',
      'Synthesize conclusion',
    ];
  }

  List<String> _fadeSteps(List<String> steps, int fadeLevel) {
    final result = <String>[];
    final numToFade = math.min(fadeLevel, steps.length);
    final fadeStartIndex = math.max(0, steps.length - numToFade);

    for (int i = 0; i < steps.length; i++) {
      if (i >= fadeStartIndex) {
        result.add('Step ${i + 1}: [ ______ Complete this step ______ ]');
      } else {
        result.add('Step ${i + 1}: ${steps[i]}');
      }
    }
    return result;
  }

  /// Alias/helper: computes knowledge state string from note attempts.
  String computeState(Note note, List<LearningAttempt> attempts) {
    final noteAttempts =
        attempts.where((a) => a.knowledgeTargetId == note.id).toList();
    if (noteAttempts.isEmpty) return 'unknown';
    final successes = noteAttempts
        .where((a) => !a.correctness.isFail && !a.scorePct.isNaN)
        .toList();
    if (successes.isEmpty) return 'developing';
    final distinctSuccessTypes = successes.map((a) => a.testType).toSet();
    if (distinctSuccessTypes.length >= 2) return 'verified';

    final immediateSuccesses =
        successes.where((a) => a.delayBucket == DelayBucket.immediate).toList();
    final typeCounts = <TestType, int>{};
    for (final a in immediateSuccesses) {
      typeCounts[a.testType] = (typeCounts[a.testType] ?? 0) + 1;
    }
    if (typeCounts.values.any((c) => c >= 2)) return 'probable';
    return 'developing';
  }

  /// Alias/helper: identifies gaps where note concept keypoints were not recalled.
  List<String> identifyGaps(Note note, List<LearningAttempt> attempts) {
    final keyPoints = _extractKeyPoints(note.body);
    final noteAttempts =
        attempts.where((a) => a.knowledgeTargetId == note.id).toList();
    final gaps = <String>[];
    for (final point in keyPoints) {
      final pointLower = point.toLowerCase();
      final recalled =
          noteAttempts.any((a) => a.response.toLowerCase().contains(pointLower));
      if (!recalled) {
        gaps.add(point);
      }
    }
    return gaps;
  }

  /// Alias/helper: computes Jaccard word overlap between two strings for tokens > 3 chars.
  double calculateOverlap(String a, String b) {
    final wordsA = a
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 3)
        .toSet();
    final wordsB = b
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 3)
        .toSet();
    if (wordsA.isEmpty && wordsB.isEmpty) return 1.0;
    final union = wordsA.union(wordsB);
    if (union.isEmpty) return 0.0;
    final intersection = wordsA.intersection(wordsB);
    return intersection.length / union.length;
  }
}
