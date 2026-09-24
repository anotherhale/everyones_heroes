import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_experience_plan_response_parser.dart';
import 'package:http/http.dart' as http;

/// Production [StoryExperiencePlannerPort] via EH AI proxy (HS.12.4).
///
/// Never holds OpenAI credentials. Calls `POST /story-experience-plans`.
final class ProxyStoryExperiencePlannerAdapter
    implements StoryExperiencePlannerPort {
  ProxyStoryExperiencePlannerAdapter({
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
  Future<StoryExperiencePlanDraft> generate({
    required Story story,
    required CapturedStoryReading reading,
    required String transcriptText,
  }) async {
    final uri = _baseUrl.resolve('/story-experience-plans');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'storyId': story.id.value,
      'transcriptRepresentationId': reading.transcriptRepresentationId.value,
      'transcriptText': transcriptText,
      'processingVersion': StoryExperiencePlan.defaultProcessingVersion,
      'reading': {
        'movement': {
          'text': reading.movement.text,
          'startOffset': reading.movement.sourceSpan.startOffset,
          'endOffset': reading.movement.sourceSpan.endOffset,
        },
        'themes': [
          for (final theme in reading.themes)
            {
              'label': theme.label,
              'startOffset': theme.sourceSpan.startOffset,
              'endOffset': theme.sourceSpan.endOffset,
            },
        ],
        'challenge': {
          'text': reading.challenge.text,
          'startOffset': reading.challenge.sourceSpan.startOffset,
          'endOffset': reading.challenge.sourceSpan.endOffset,
        },
        'turningPoint': {
          'text': reading.turningPoint.text,
          'startOffset': reading.turningPoint.sourceSpan.startOffset,
          'endOffset': reading.turningPoint.sourceSpan.endOffset,
        },
        'outcome': {
          'text': reading.outcome.text,
          'startOffset': reading.outcome.sourceSpan.startOffset,
          'endOffset': reading.outcome.sourceSpan.endOffset,
        },
      },
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw StoryExperiencePlannerException(
          'Story Experience Plan timed out: $e',
        );
      }
      throw StoryExperiencePlannerException(
        'Story Experience Plan network failure: $e',
      );
    }

    if (response.statusCode == 401) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan authentication failed.',
      );
    }
    if (response.statusCode == 429) {
      throw const StoryExperiencePlannerException(
        'Story Experience Plan rate limit exceeded. Please try again shortly.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryExperiencePlannerException(
        'Story Experience Plan proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    return StoryExperiencePlanResponseParser.parse(
      response.body,
      transcriptText: transcriptText,
      storyId: story.id.value,
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
