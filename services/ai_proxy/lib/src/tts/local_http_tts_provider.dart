import 'dart:convert';

import 'package:ai_proxy/src/tts/tts_provider.dart';
import 'package:http/http.dart' as http;

/// HTTP client for a local TTS sidecar (Qwen3-TTS / CosyVoice) (HS.12.7).
///
/// The sidecar owns Python weights and device selection. This class only
/// forwards EH-owned complete-file synthesis requests and maps failures into
/// [TtsProviderException] — never leaking Python tracebacks to Flutter.
final class LocalHttpTtsProvider implements TtsProvider {
  LocalHttpTtsProvider({
    required this.providerKey,
    required this._baseUrl,
    this.timeout = const Duration(seconds: 300),
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  final String providerKey;

  final Uri _baseUrl;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<TtsSynthesisResult> synthesize(TtsSynthesisRequest request) async {
    final text = request.text.trim();
    if (text.isEmpty) {
      throw const TtsProviderException('TTS input text cannot be empty.');
    }

    final uri = _baseUrl.resolve('/synthesize');
    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text': text,
              'language': request.language,
              'provider': providerKey,
              if (request.modelHint?.trim().isNotEmpty == true)
                'modelHint': request.modelHint!.trim(),
            }),
          )
          .timeout(timeout);
    } on Exception catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('timeout') || message.contains('timed out')) {
        throw TtsProviderException(
          'Local TTS provider "$providerKey" timed out: $e',
        );
      }
      throw TtsProviderException(
        'Local TTS provider "$providerKey" unavailable: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TtsProviderException(
        'Local TTS provider "$providerKey" failed '
        '(${response.statusCode}): ${_safeBody(response.body)}',
      );
    }

    late final Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is! Map) {
        throw const FormatException('Expected JSON object.');
      }
      decoded = Map<String, dynamic>.from(raw);
    } catch (e) {
      throw TtsProviderException(
        'Local TTS provider "$providerKey" returned malformed JSON: $e',
      );
    }

    final audioBase64 = (decoded['audioBase64'] as String?)?.trim() ?? '';
    if (audioBase64.isEmpty) {
      throw TtsProviderException(
        'Local TTS provider "$providerKey" returned empty audio.',
      );
    }

    late final List<int> bytes;
    try {
      bytes = base64Decode(audioBase64);
    } catch (e) {
      throw TtsProviderException(
        'Local TTS provider "$providerKey" returned invalid base64 audio: $e',
      );
    }
    if (bytes.isEmpty) {
      throw TtsProviderException(
        'Local TTS provider "$providerKey" returned empty audio bytes.',
      );
    }

    final contentType =
        (decoded['contentType'] as String?)?.trim().isNotEmpty == true
            ? (decoded['contentType'] as String).trim()
            : 'audio/wav';
    final modelLabel =
        (decoded['modelLabel'] as String?)?.trim().isNotEmpty == true
            ? (decoded['modelLabel'] as String).trim()
            : (request.modelHint?.trim().isNotEmpty == true
                ? request.modelHint!.trim()
                : providerKey);

    return TtsSynthesisResult(
      audioBytes: bytes,
      contentType: contentType,
      modelLabel: modelLabel,
      providerLabelSuffix:
          (decoded['speaker'] as String?)?.trim().isNotEmpty == true
              ? (decoded['speaker'] as String).trim()
              : null,
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
