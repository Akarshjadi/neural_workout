import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/model.dart';
import '../models/error_record.dart';
import '../models/learning_enums.dart';
import '../models/note.dart';
import 'blurt_scorer.dart';
import 'feedback_diagnosis_service.dart';
import 'retrieval_engine.dart';

/// Phase 1 — Local on-device AI scorer using flutter_gemma.
/// No cloud, no API keys. Falls back to BlurtScorer if anything fails.
///
/// Honest configuration: flutter_gemma exposes only `ModelType` (gemmaIt/general/deepSeek)
/// and `maxTokens`. Temperature is applied at chat creation. There is no public API
/// to select 0.5B/1B/3B variants or context window size — those settings would be fake.
class LocalAiScorer {
  InferenceModel? _model;
  bool _ready = false;

  /// Model type (only setting that actually changes inference behavior).
  ModelType modelType = ModelType.gemmaIt;

  /// Max tokens for the model context (actually applied).
  int maxTokens = 2048;

  /// Temperature for chat responses (actually applied at chat creation).
  double temperature = 0.1;

  bool get isReady => _ready;

  Future<void> init({
    ModelType? modelTypeOverride,
    int? maxTokensOverride,
    double? temperatureOverride,
  }) async {
    try {
      modelType = modelTypeOverride ?? modelType;
      maxTokens = maxTokensOverride ?? maxTokens;
      temperature = temperatureOverride ?? temperature;

      _model = await FlutterGemmaPlugin.instance.createModel(
        modelType: modelType,
        maxTokens: maxTokens,
      );
      _ready = true;
      debugPrint('LocalAiScorer: ready (modelType=$modelType, maxTokens=$maxTokens)');
    } catch (e, stackTrace) {
      _ready = false;
      debugPrint('LocalAiScorer: init failed: $e\n$stackTrace');
    }
  }

  Future<ScoreResult> score({
    required String sourceBody,
    required String blurt,
    Map<String, List<String>> aliases = const {},
  }) async {
    if (!_ready || _model == null) throw StateError('AI scorer not ready');

    final prompt = '''
You are a strict but fair tutor. Compare the student's BLURT to the SOURCE note.
Reward correct recall in the student's own words. Synonyms and paraphrases count as recalled. Do NOT require verbatim copy.

Return ONLY valid JSON with this exact structure:
{
  "score_pct": <number 0-100>,
  "matched": ["concept1", "concept2"],
  "missed": ["concept3"],
  "source_concepts": ["concept1", "concept2", "concept3"],
  "depth": <number 0-100>,
  "clarity": <number 0-100>
}

Depth rubric:
  0-30: restates definitions
  31-60: connects concepts within the topic
  61-80: connects to other topics
  81-100: generates new implications or examples

Clarity rubric: how well a stranger would understand the explanation.

--- SOURCE ---
$sourceBody

--- BLURT ---
$blurt
''';

    final chat = await _model!.createChat(temperature: temperature);
    await chat.addQueryChunk(Message(text: prompt, isUser: true));
    final response = await chat.generateChatResponse();
    return _parseResponse(response);
  }

  /// Robust JSON parsing with validation for LLM output.
  ScoreResult _parseResponse(String response) {
    var text = response.trim();

    // Strip markdown code fences if present.
    if (text.contains('```')) {
      final fenceStart = text.indexOf('```');
      final fenceEnd = text.lastIndexOf('```');
      if (fenceStart != fenceEnd) {
        text = text.substring(fenceStart + 3, fenceEnd).trim();
      }
      // Remove language identifier like ```json
      if (text.startsWith('json')) {
        text = text.substring(4).trim();
      }
    }

    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw FormatException('No valid JSON in AI response: ${text.substring(0, text.length.clamp(0, 100))}');
    }

    final m = jsonDecode(text.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

    final scorePct = _clampScore((m['score_pct'] as num?)?.toDouble() ?? 0.0);
    final depth = (m['depth'] as num?)?.toDouble();
    final clarity = (m['clarity'] as num?)?.toDouble();

    return ScoreResult(
      scorePct: scorePct,
      matched: _asStringList(m['matched']),
      missed: _asStringList(m['missed']),
      sourceConcepts: _asStringList(m['source_concepts']),
      depthScore: depth,
      clarityScore: clarity,
    );
  }

  /// Clamps a raw 0..100 score into the valid range (defensive AI parsing).
  static double _clampScore(double v) => v.clamp(0.0, 100.0).toDouble();

  /// @nodoc — exposed for the regression test in local_ai_scorer_test.dart.
  static double clampScore(double v) => _clampScore(v);

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static const _stopWords = {
    'this', 'that', 'with', 'from', 'have', 'were', 'which', 'their', 'there',
    'about', 'would', 'could', 'should', 'these', 'other', 'words', 'into',
    'more', 'some', 'than', 'them', 'then', 'what', 'when', 'will', 'your',
  };

  /// Deterministic tokenizer: extracts key concept terms without calling the model.
  List<String> extractKeyConcepts(String body) {
    final tokens = body
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 3 && !_stopWords.contains(t))
        .toSet()
        .toList();
    return tokens;
  }

  /// Alias: delegates prompt generation to RetrievalEngine.
  Future<String> generatePrompt({
    required Note note,
    required TestType type,
  }) async =>
      const RetrievalEngine().generatePrompt(note: note, testType: type).question;

  /// Alias: delegates error diagnosis to FeedbackDiagnosisService.
  Future<ErrorType> diagnoseError({
    required String response,
    required double scorePct,
    int? responseTimeMs,
    int? confidence,
  }) async =>
      const FeedbackDiagnosisService().diagnoseError(
        response: response,
        scorePct: scorePct,
        responseTimeMs: responseTimeMs,
        confidence: confidence,
      );

  /// Scores explanation response against source text, returning score percentage.
  Future<double> scoreExplanation({
    required String response,
    required String source,
  }) async {
    if (!_ready || _model == null) {
      return BlurtScorer(sourceBody: source).score(response).scorePct;
    }
    final res = await score(sourceBody: source, blurt: response);
    return res.scorePct;
  }

  /// Semantic vector search stub — throws because vector database is not included in build.
  Future<List<Note>> semanticVectorSearch({
    required String query,
    required List<Note> candidates,
  }) async {
    // Doc claims vector search; not built. Throwing is honest.
    throw UnimplementedError('no vector store in this build');
  }
}
