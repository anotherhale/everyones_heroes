import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/application/lab/presentation_creative_direction.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/creative_direction_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [CreativeDirectionPort] via EH AI proxy (Experiment A).
///
/// Never holds vendor credentials. Calls `POST /experience-creative-directions`.
final class ProxyCreativeDirectionAdapter implements CreativeDirectionPort {
  ProxyCreativeDirectionAdapter({
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
  Future<PresentationCreativeDirection> direct(
    CreativeDirectionRequest request,
  ) async {
    final uri = _baseUrl.resolve('/experience-creative-directions');
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
      'intention': request.intention.name,
      'coreMessage': request.coreMessage,
      'emotionalArc': request.emotionalArc.name,
      'musicDirection': {
        'mood': request.musicDirection.mood,
        'energy': request.musicDirection.energy,
        'style': request.musicDirection.style,
        'rationale': request.musicDirection.rationale,
      },
      'keyMomentLabels': request.keyMomentLabels,
      'sequenceStepTypes': request.sequenceStepTypes,
      if (request.reflectionPrompt != null)
        'reflectionPrompt': request.reflectionPrompt,
      if (request.targetDurationSeconds != null)
        'targetDurationSeconds': request.targetDurationSeconds,
      'processingVersion':
          request.processingVersion?.trim().isNotEmpty == true
              ? request.processingVersion!.trim()
              : PresentationCreativeDirection.defaultProcessingVersion,
      if (request.providerHint != null) 'provider': request.providerHint,
      if (request.modelHint != null) 'model': request.modelHint,
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      throw CreativeDirectionException(
        'Creative direction network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const CreativeDirectionException(
        'Creative direction authentication failed.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CreativeDirectionException(
        'Creative direction proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return CreativeDirectionResponseParser.parse(response.body);
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 240)}…';
  }
}
