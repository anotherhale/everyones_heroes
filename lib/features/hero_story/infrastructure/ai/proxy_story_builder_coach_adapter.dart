import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_coach_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [StoryBuilderCoachPort] via EH AI proxy (SB.7).
///
/// Never holds OpenAI credentials. Calls `POST /story-builder-questions`.
final class ProxyStoryBuilderCoachAdapter implements StoryBuilderCoachPort {
  ProxyStoryBuilderCoachAdapter({
    required Uri baseUrl,
    http.Client? client,
    this.authToken,
    this.timeout = const Duration(seconds: 60),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String? authToken;
  final Duration timeout;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<StoryBuilderCoachSuggestion> suggestNextQuestion(
    StoryBuilderCoachRequest request,
  ) async {
    final uri = _baseUrl.resolve('/story-builder-questions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode(_toEhRequestJson(request));

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw StoryBuilderCoachException(
          'AI Story Coach timed out: $e',
        );
      }
      throw StoryBuilderCoachException(
        'AI Story Coach network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const StoryBuilderCoachException(
        'AI Story Coach authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const StoryBuilderCoachException(
        'AI Story Coach rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryBuilderCoachException(
        'AI Story Coach proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return StoryBuilderCoachResponseParser.parse(response.body);
  }

  static Map<String, dynamic> _toEhRequestJson(StoryBuilderCoachRequest request) {
    return {
      'purpose': request.purpose?.name,
      'themes': [for (final theme in request.themes) theme.name],
      'themesUnsure': request.themesUnsure,
      'presentedNarrativeRoles': [
        for (final role in request.presentedNarrativeRoles) role.name,
      ],
      'turns': [
        for (final turn in request.turns)
          {
            'promptText': turn.promptText,
            'ordinal': turn.ordinal,
            'narrativeRole': turn.narrativeRole?.name,
            'responseText': turn.responseText,
            'skipped': turn.skipped,
          },
      ],
    };
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) {
      return trimmed;
    }
    return '${trimmed.substring(0, 240)}…';
  }
}
