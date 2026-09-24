import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/enums/voice_rendering_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/voice_rendering_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [VoiceRenderingPort] via EH AI proxy (HS.12.6).
///
/// Never holds OpenAI/vendor credentials. Calls `POST /story-voice-renderings`.
final class ProxyVoiceRenderingAdapter implements VoiceRenderingPort {
  ProxyVoiceRenderingAdapter({
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
  Future<VoiceRenderingDraft> render(VoiceRenderingRequest request) async {
    if (request.renderingMode != VoiceRenderingMode.syntheticNarration) {
      throw VoiceRenderingException(
        'Unsupported voice rendering mode: ${request.renderingMode.name}',
      );
    }

    final sourceText = request.sourceText.trim();
    if (sourceText.isEmpty) {
      throw const VoiceRenderingException(
        'sourceText is required for voice rendering.',
      );
    }

    final uri = _baseUrl.resolve('/story-voice-renderings');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'storyId': request.storyId.value,
      'experiencePlanId': request.experiencePlanId.value,
      'experiencePlanProcessingVersion':
          request.experiencePlanProcessingVersion,
      'sourceRepresentationId': request.sourceRepresentationId.value,
      'sourceText': sourceText,
      'renderingMode': request.renderingMode.name,
      'processingVersion':
          request.processingVersion?.trim().isNotEmpty == true
              ? request.processingVersion!.trim()
              : StoryVoiceRendering.defaultProcessingVersion,
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw VoiceRenderingException(
          'Voice rendering timed out: $e',
        );
      }
      throw VoiceRenderingException(
        'Voice rendering network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const VoiceRenderingException(
        'Voice rendering authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const VoiceRenderingException(
        'Voice rendering rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VoiceRenderingException(
        'Voice rendering proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return VoiceRenderingResponseParser.parse(response.body);
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) {
      return trimmed;
    }
    return '${trimmed.substring(0, 240)}…';
  }
}
