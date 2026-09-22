import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_authoring_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [StoryAuthoringTransport] via EH AI proxy (SB.11).
///
/// Never holds OpenAI credentials. Calls `POST /story-authoring`.
/// Does not mutate sessions, persist proposals, or contain UI logic.
final class ProxyStoryShaperAdapter implements StoryAuthoringTransport {
  ProxyStoryShaperAdapter({
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

  /// Endpoint path relative to the proxy base URL.
  static const String endpointPath = '/story-authoring';

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<StoryAuthoringResponse> author(StoryAuthoringRequest request) async {
    final uri = _baseUrl.resolve(endpointPath);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode(toEhRequestJson(request));

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw StoryShaperException(
          'AI story authoring timed out: $e',
        );
      }
      throw StoryShaperException(
        'AI story authoring network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const StoryShaperException(
        'AI story authoring authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const StoryShaperException(
        'AI story authoring rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryShaperException(
        'AI story authoring proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return StoryAuthoringResponseParser.parse(response.body);
  }

  /// EH-owned request JSON — minimal authoring payload only.
  static Map<String, dynamic> toEhRequestJson(StoryAuthoringRequest request) {
    return {
      'purpose': request.purpose?.name,
      'themes': [for (final theme in request.themes) theme.name],
      'themesUnsure': request.themesUnsure,
      'title': request.title,
      'summary': request.summary,
      'understandingSummary': request.understandingSummary,
      'sections': [
        for (final section in request.sections)
          {
            'role': section.role.name,
            'content': section.content,
            'sourceResponseIds': [
              for (final id in section.sourceResponseIds) id.value,
            ],
            'contentOrigin': section.contentOrigin.name,
            'wasSkipped': section.wasSkipped,
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
