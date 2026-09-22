import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_understanding_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [StoryBuilderUnderstandingPort] via EH AI proxy (SB.8).
///
/// Never holds OpenAI credentials. Calls `POST /story-understanding`.
final class ProxyStoryBuilderUnderstandingAdapter
    implements StoryBuilderUnderstandingPort {
  ProxyStoryBuilderUnderstandingAdapter({
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
  Future<StoryBuilderUnderstandingDraft> analyze(
    StoryBuilderUnderstandingRequest request,
  ) async {
    final uri = _baseUrl.resolve('/story-understanding');
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
        throw StoryBuilderUnderstandingException(
          'AI Story Understanding timed out: $e',
        );
      }
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const StoryBuilderUnderstandingException(
        'AI Story Understanding rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryBuilderUnderstandingException(
        'AI Story Understanding proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return StoryBuilderUnderstandingResponseParser.parse(response.body);
  }

  static Map<String, dynamic> _toEhRequestJson(
    StoryBuilderUnderstandingRequest request,
  ) {
    return {
      'purpose': request.purpose?.name,
      'themes': [for (final theme in request.themes) theme.name],
      'themesUnsure': request.themesUnsure,
      'structureSections': [
        for (final section in request.structureSections)
          {
            'narrativeRole': section.narrativeRole.name,
            'order': section.order,
            'sourceResponseIds': [
              for (final id in section.sourceResponseIds) id.value,
            ],
            'wasSkipped': section.wasSkipped,
            'hasSourceMaterial': section.hasSourceMaterial,
          },
      ],
      'responses': [
        for (final response in request.responses)
          {
            'id': response.id.value,
            'ordinal': response.ordinal,
            'narrativeRole': response.narrativeRole?.name,
            'text': response.text,
            'skipped': response.skipped,
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
