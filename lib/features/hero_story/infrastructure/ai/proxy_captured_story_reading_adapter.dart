import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/captured_story_reading_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [CapturedStoryReadingPort] via EH AI proxy (HS.12.3).
///
/// Never holds OpenAI credentials. Calls `POST /captured-story-readings`.
final class ProxyCapturedStoryReadingAdapter
    implements CapturedStoryReadingPort {
  ProxyCapturedStoryReadingAdapter({
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

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<CapturedStoryReadingDraft> generate(
    GenerateCapturedStoryReadingRequest request,
  ) async {
    final uri = _baseUrl.resolve('/captured-story-readings');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'storyId': request.storyId.value,
      'transcriptRepresentationId': request.transcriptRepresentationId.value,
      'transcriptText': request.transcriptText,
      'language': request.language.value,
      'processingVersion': request.processingVersion,
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw CapturedStoryReadingException(
          'Captured story reading timed out: $e',
        );
      }
      throw CapturedStoryReadingException(
        'Captured story reading network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const CapturedStoryReadingException(
        'Captured story reading authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const CapturedStoryReadingException(
        'Captured story reading rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CapturedStoryReadingException(
        'Captured story reading proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return CapturedStoryReadingResponseParser.parse(
      response.body,
      transcriptText: request.transcriptText,
    );
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) {
      return trimmed;
    }
    return '${trimmed.substring(0, 240)}…';
  }
}
