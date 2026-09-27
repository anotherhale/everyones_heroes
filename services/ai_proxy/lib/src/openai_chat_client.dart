import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin OpenAI chat client used only by the EH AI proxy (SB.7).
class OpenAiChatClient {
  OpenAiChatClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? client,
  })  : _client = client ?? http.Client(),
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

  Future<OpenAiChatResult> completeJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final bodyMap = buildChatRequest(
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );
    final body = jsonEncode(bodyMap);

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAiChatException(
        'OpenAI chat failed (${response.statusCode}): '
        '${_safe(response.body)}',
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
      throw OpenAiChatException('Malformed OpenAI chat response: $e');
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const OpenAiChatException('OpenAI chat returned no choices.');
    }
    final first = choices.first;
    if (first is! Map) {
      throw const OpenAiChatException('OpenAI chat choice was malformed.');
    }
    final message = first['message'];
    if (message is! Map) {
      throw const OpenAiChatException('OpenAI chat message was malformed.');
    }
    final content = (message['content'] as String?)?.trim() ?? '';
    if (content.isEmpty) {
      throw const OpenAiChatException('OpenAI chat returned empty content.');
    }

    return OpenAiChatResult(content: content, raw: json);
  }

  /// Builds the chat/completions JSON body for EH structured-output calls.
  ///
  /// Capability/model-aware: GPT-5 family models omit `temperature` because
  /// non-default values are rejected by the provider. Legacy chat models keep
  /// `temperature: 0.4`. Always preserves `model`, `response_format`, and
  /// the system/user messages contract.
  static Map<String, dynamic> buildChatRequest({
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
    };
    if (_supportsCustomTemperature(model)) {
      body['temperature'] = 0.4;
    }
    return body;
  }

  /// Whether this model accepts a non-default [temperature] on chat/completions.
  ///
  /// GPT-5 family reasoning models (including GPT-5.6 / Luna) only allow the
  /// default temperature; sending `0.4` yields an OpenAI `unsupported_value`
  /// error.
  static bool _supportsCustomTemperature(String model) {
    final normalized = model.trim().toLowerCase();
    return !normalized.startsWith('gpt-5');
  }

  static String _safe(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 240)}…';
  }
}

final class OpenAiChatResult {
  const OpenAiChatResult({required this.content, this.raw});

  final String content;
  final Map<String, dynamic>? raw;
}

final class OpenAiChatException implements Exception {
  const OpenAiChatException(this.message);

  final String message;

  @override
  String toString() => 'OpenAiChatException: $message';
}
