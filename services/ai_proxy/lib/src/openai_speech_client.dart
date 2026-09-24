import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin OpenAI TTS client used only by the EH AI proxy (HS.12.6).
///
/// Implements ordinary synthetic narration — not voice cloning and not a
/// Hero-owned voice transformation. Vendor credentials stay server-side.
class OpenAiSpeechClient {
  OpenAiSpeechClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.voice = 'alloy',
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String apiKey;
  final String baseUrl;
  final String model;
  final String voice;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Returns MPEG audio bytes for [text].
  Future<OpenAiSpeechResult> synthesize({
    required String text,
    String responseFormat = 'mp3',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const OpenAiSpeechException('TTS input text cannot be empty.');
    }
    // OpenAI TTS input limit.
    if (trimmed.length > 4096) {
      throw const OpenAiSpeechException(
        'TTS input text exceeds the 4096 character limit.',
      );
    }

    final uri = Uri.parse('$baseUrl/audio/speech');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg, application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': trimmed,
        'voice': voice,
        'response_format': responseFormat,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body;
      throw OpenAiSpeechException(
        'OpenAI speech failed (${response.statusCode}): '
        '${body.length > 240 ? '${body.substring(0, 240)}…' : body}',
      );
    }

    final contentType =
        (response.headers['content-type'] ?? '').split(';').first.trim();
    if (contentType.isNotEmpty &&
        !contentType.startsWith('audio/') &&
        contentType != 'application/octet-stream') {
      throw OpenAiSpeechException(
        'Unexpected OpenAI speech content type: $contentType',
      );
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const OpenAiSpeechException('OpenAI speech returned empty audio.');
    }

    return OpenAiSpeechResult(
      audioBytes: bytes,
      contentType: contentType.isEmpty ? 'audio/mpeg' : contentType,
      model: model,
      voice: voice,
    );
  }
}

final class OpenAiSpeechResult {
  const OpenAiSpeechResult({
    required this.audioBytes,
    required this.contentType,
    required this.model,
    required this.voice,
  });

  final List<int> audioBytes;
  final String contentType;
  final String model;
  final String voice;
}

final class OpenAiSpeechException implements Exception {
  const OpenAiSpeechException(this.message);

  final String message;

  @override
  String toString() => 'OpenAiSpeechException: $message';
}
