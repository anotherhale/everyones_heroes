import 'dart:convert';

import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/analysis_support_level.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:http/http.dart' as http;

/// Production [StoryTranscriptionPort] that calls the EH AI backend proxy.
///
/// Never holds OpenAI credentials. Provider-specific details stay server-side
/// (HS-ADR-067 / HS-ADR-068).
final class ProxyStoryTranscriptionAdapter implements StoryTranscriptionPort {
  ProxyStoryTranscriptionAdapter({
    required Uri baseUrl,
    http.Client? client,
    this.authToken,
    this.timeout = const Duration(seconds: 120),
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
  Future<StoryTranscriptionResult> transcribe(
    TranscribeStoryMediaRequest request,
  ) async {
    final bytes = request.mediaBytes;
    if (bytes == null || bytes.isEmpty) {
      throw const StoryTranscriptionException(
        'Media bytes are required for proxy transcription.',
      );
    }

    final uri = _baseUrl.resolve('/story-transcriptions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty)
        'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'storyId': request.storyId.value,
      'sourceRepresentationId': request.sourceRepresentationId.value,
      'mediaReferenceUri': request.mediaReference.uri,
      'language': request.language.value,
      'processingVersion': request.processingVersion,
      'requestId': request.requestId,
      'mediaBase64': base64Encode(bytes),
      'contentType': _guessContentType(request.mediaReference.uri),
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw StoryTranscriptionException(
          'Transcription proxy timed out: $e',
        );
      }
      throw StoryTranscriptionException(
        'Transcription proxy network failure: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoryTranscriptionException(
        'Transcription proxy failed (${response.statusCode}): '
        '${_safeBody(response.body)}',
      );
    }

    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw StoryTranscriptionException(
        'Malformed transcription proxy response: $e',
      );
    }

    final text = (json['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const StoryTranscriptionException(
        'Transcription proxy returned empty text.',
      );
    }

    final languageRaw = json['language'] as String? ?? request.language.value;
    final supportRaw = json['supportLevel'] as String?;
    AnalysisSupportLevel? support;
    if (supportRaw != null) {
      for (final value in AnalysisSupportLevel.values) {
        if (value.name == supportRaw) {
          support = value;
          break;
        }
      }
    }

    return StoryTranscriptionResult(
      text: text,
      language: LanguageCode(languageRaw),
      sourceMediaReference: request.mediaReference,
      providerLabel: json['providerLabel'] as String? ?? 'eh_ai_proxy',
      supportLevel: support,
      opaqueProviderConfidence: json['opaqueProviderConfidence'],
    );
  }

  static String _guessContentType(String uri) {
    final lower = uri.toLowerCase();
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) return 'audio/mp4';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mp4';
  }

  static String _safeBody(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) {
      return trimmed;
    }
    return '${trimmed.substring(0, 240)}…';
  }
}
