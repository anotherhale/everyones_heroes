import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/music_generation_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [MusicGenerationPort] via EH AI proxy (Experiment A).
///
/// Never holds Stable Audio credentials. Calls `POST /story-music-generations`.
final class ProxyMusicGenerationAdapter implements MusicGenerationPort {
  ProxyMusicGenerationAdapter({
    required Uri baseUrl,
    http.Client? client,
    this.authToken,
    this.timeout = const Duration(seconds: 180),
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
  Future<MusicGenerationDraft> generate(MusicGenerationRequest request) async {
    final prompt = request.prompt.trim();
    if (prompt.isEmpty) {
      throw const MusicGenerationException('Music prompt cannot be empty.');
    }
    if (request.instrumentalPreferred) {
      final lower = prompt.toLowerCase();
      if (!lower.contains('instrumental') &&
          !lower.contains('no vocals') &&
          !lower.contains('no lyrics')) {
        throw const MusicGenerationException(
          'Instrumental constraint missing from music prompt.',
        );
      }
    }

    final uri = _baseUrl.resolve('/story-music-generations');
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
      'prompt': prompt,
      'targetDurationSeconds': request.targetDurationSeconds,
      if (request.mood != null) 'mood': request.mood,
      if (request.energy != null) 'energy': request.energy,
      if (request.style != null) 'style': request.style,
      'instrumentalPreferred': request.instrumentalPreferred,
      'intensityCurveHints': request.intensityCurveHints,
      'processingVersion':
          request.processingVersion?.trim().isNotEmpty == true
              ? request.processingVersion!.trim()
              : MusicRendering.defaultProcessingVersion,
      if (request.providerHint != null) 'provider': request.providerHint,
      if (request.modelHint != null) 'model': request.modelHint,
      if (request.experimentId != null) 'experimentId': request.experimentId,
      if (request.requestId != null) 'requestId': request.requestId,
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      throw MusicGenerationException(
        'Music generation network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const MusicGenerationException(
        'Music generation authentication failed.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MusicGenerationException(
        'Music generation proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return MusicGenerationResponseParser.parse(response.body);
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 240)}…';
  }
}
