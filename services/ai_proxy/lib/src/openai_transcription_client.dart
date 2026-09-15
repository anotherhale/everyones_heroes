import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin OpenAI STT client used only by the EH AI proxy (HS-ADR-068).
final class OpenAiTranscriptionClient {
  OpenAiTranscriptionClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<OpenAiTranscriptionResult> transcribe({
    required List<int> audioBytes,
    required String contentType,
    required String filename,
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..fields['response_format'] = 'json';
    if (language != null && language.isNotEmpty) {
      // OpenAI accepts ISO-639-1; strip region if present.
      request.fields['language'] = language.split('-').first;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: filename,
      ),
    );

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw OpenAiTranscriptionException(
        'OpenAI transcription failed (${streamed.statusCode}): '
        '${body.length > 240 ? '${body.substring(0, 240)}…' : body}',
      );
    }

    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw OpenAiTranscriptionException(
        'Malformed OpenAI transcription response: $e',
      );
    }

    final text = (json['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const OpenAiTranscriptionException(
        'OpenAI returned empty transcript text.',
      );
    }

    return OpenAiTranscriptionResult(
      text: text,
      language: language,
      raw: json,
    );
  }
}

final class OpenAiTranscriptionResult {
  const OpenAiTranscriptionResult({
    required this.text,
    this.language,
    this.raw,
  });

  final String text;
  final String? language;
  final Map<String, dynamic>? raw;
}

final class OpenAiTranscriptionException implements Exception {
  const OpenAiTranscriptionException(this.message);

  final String message;

  @override
  String toString() => 'OpenAiTranscriptionException: $message';
}
