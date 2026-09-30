import 'dart:convert';

import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_script_generator.dart';
import 'package:http/http.dart' as http;

/// Production [StoryScriptGenerator] via EH AI proxy (SB.8).
///
/// Never holds OpenAI credentials. Calls `POST /story-builder-scripts`.
/// Reuses [EH_AI_PROXY_URL] / [EH_AI_PROXY_AUTH_TOKEN] conventions.
final class ProxyStoryScriptGenerator implements StoryScriptGenerator {
  ProxyStoryScriptGenerator({
    required Uri baseUrl,
    http.Client? client,
    this.authToken,
    this.timeout = const Duration(seconds: 90),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String? authToken;
  final Duration timeout;

  static const String endpointPath = '/story-builder-scripts';

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<StoryScriptGenerationDraft> generate(
    StoryScriptGenerationMaterial material,
  ) async {
    final uri = _baseUrl.resolve(endpointPath);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode(toEhRequestJson(material));

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw StoryScriptGeneratorException(
          'Story script generation timed out: $e',
        );
      }
      throw StoryScriptGeneratorException(
        'Story script generation network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const StoryScriptGeneratorException(
        'Story script generation authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const StoryScriptGeneratorException(
        'Story script generation rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryScriptGeneratorException(
        'Story script generation proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return parseResponse(response.body, fallbackLanguage: material.language);
  }

  static Map<String, dynamic> toEhRequestJson(
    StoryScriptGenerationMaterial material,
  ) {
    return {
      'purpose': material.purpose?.name,
      'themes': [for (final theme in material.themes) theme.name],
      'themesUnsure': material.themesUnsure,
      'language': material.language?.value,
      'answers': [
        for (final answer in material.answers)
          {
            'question': answer.question,
            'answer': answer.answer,
            if (answer.responseId != null) 'responseId': answer.responseId,
          },
      ],
    };
  }

  static StoryScriptGenerationDraft parseResponse(
    String body, {
    LanguageCode? fallbackLanguage,
  }) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw StoryScriptGeneratorException(
        'Malformed story script response: $e',
      );
    }

    if (decoded is! Map) {
      throw const StoryScriptGeneratorException(
        'Story script response must be a JSON object.',
      );
    }

    final map = Map<String, dynamic>.from(decoded);
    final content = (map['content'] ?? map['script'] ?? map['narrative'])
        ?.toString()
        .trim();
    if (content == null || content.isEmpty) {
      throw const StoryScriptGeneratorException(
        'Story script response contained empty narrative content.',
      );
    }

    final languageRaw = map['language']?.toString().trim();
    final language = (languageRaw != null && languageRaw.isNotEmpty)
        ? LanguageCode(languageRaw)
        : (fallbackLanguage ?? LanguageCode('en'));

    final processingVersion =
        map['promptOrTemplateVersion']?.toString().trim().isNotEmpty == true
            ? map['promptOrTemplateVersion'].toString().trim()
            : StoryScriptGenerationDraft.defaultProcessingVersion;

    return StoryScriptGenerationDraft(
      content: content,
      language: language,
      providerLabel: map['providerLabel']?.toString(),
      processingVersion: processingVersion,
    );
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 240)}…';
  }
}
