import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin Stability Stable Audio 3.0 client used only by the EH AI proxy.
///
/// Credentials stay server-side. Injectable for tests via subclassing or a
/// custom [http.Client].
class StableAudioClient {
  StableAudioClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? client,
    this.pollInterval = const Duration(seconds: 2),
    this.pollTimeout = const Duration(minutes: 3),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String apiKey;
  final String baseUrl;
  final String model;
  final Duration pollInterval;
  final Duration pollTimeout;
  final http.Client _client;
  final bool _ownsClient;

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Generates instrumental audio bytes for [prompt].
  ///
  /// Duration must be in 1–380 seconds (Stable Audio 3.0 contract).
  Future<StableAudioResult> generate({
    required String prompt,
    required int durationSeconds,
    String outputFormat = 'mp3',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const StableAudioException(
        'STABILITY_API_KEY is not configured for story music generation.',
      );
    }
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      throw const StableAudioException('Music prompt cannot be empty.');
    }
    if (durationSeconds < 1 || durationSeconds > 380) {
      throw StableAudioException(
        'durationSeconds must be between 1 and 380 (got $durationSeconds).',
      );
    }

    final uri = Uri.parse(
      '${_trimTrailingSlash(baseUrl)}/v2beta/audio/stable-audio/text-to-audio',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $trimmedKey'
      ..headers['Accept'] = 'audio/*, application/json'
      ..fields['prompt'] = trimmedPrompt
      ..fields['model'] = model
      ..fields['duration'] = durationSeconds.toString()
      ..fields['output_format'] = outputFormat;

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _resolveResponse(
      response,
      outputFormat: outputFormat,
      requestedDurationSeconds: durationSeconds,
    );
  }

  Future<StableAudioResult> _resolveResponse(
    http.Response response, {
    required String outputFormat,
    required int requestedDurationSeconds,
  }) async {
    if (response.statusCode == 202) {
      final id = _parseGenerationId(response.body);
      return _pollUntilReady(
        id,
        outputFormat: outputFormat,
        requestedDurationSeconds: requestedDurationSeconds,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StableAudioException(
        'Stable Audio failed (${response.statusCode}): '
        '${_safe(response.body)}',
      );
    }

    final contentType =
        (response.headers['content-type'] ?? '').split(';').first.trim();
    if (contentType.startsWith('audio/') ||
        contentType == 'application/octet-stream') {
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw const StableAudioException(
          'Stable Audio returned empty audio.',
        );
      }
      return StableAudioResult(
        audioBytes: bytes,
        contentType: contentType.isEmpty
            ? _contentTypeForFormat(outputFormat)
            : contentType,
        model: model,
        generationId: response.headers['x-request-id'],
        durationSeconds: requestedDurationSeconds,
      );
    }

    // Some deployments may return JSON synchronously.
    return _resultFromJsonBody(
      response.body,
      outputFormat: outputFormat,
      requestedDurationSeconds: requestedDurationSeconds,
    );
  }

  Future<StableAudioResult> _pollUntilReady(
    String generationId, {
    required String outputFormat,
    required int requestedDurationSeconds,
  }) async {
    final deadline = DateTime.now().add(pollTimeout);
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw StableAudioException(
          'Stable Audio poll timed out waiting for generation "$generationId".',
        );
      }
      await Future<void>.delayed(pollInterval);

      final uri = Uri.parse(
        '${_trimTrailingSlash(baseUrl)}/v2beta/audio/results/$generationId',
      );
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Accept': 'audio/*, application/json',
        },
      );

      if (response.statusCode == 202) {
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StableAudioException(
          'Stable Audio poll failed (${response.statusCode}): '
          '${_safe(response.body)}',
        );
      }

      final contentType =
          (response.headers['content-type'] ?? '').split(';').first.trim();
      if (contentType.startsWith('audio/') ||
          contentType == 'application/octet-stream') {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw const StableAudioException(
            'Stable Audio poll returned empty audio.',
          );
        }
        return StableAudioResult(
          audioBytes: bytes,
          contentType: contentType.isEmpty
              ? _contentTypeForFormat(outputFormat)
              : contentType,
          model: model,
          generationId: generationId,
          durationSeconds: requestedDurationSeconds,
        );
      }

      return _resultFromJsonBody(
        response.body,
        outputFormat: outputFormat,
        requestedDurationSeconds: requestedDurationSeconds,
        generationId: generationId,
      );
    }
  }

  StableAudioResult _resultFromJsonBody(
    String body, {
    required String outputFormat,
    required int requestedDurationSeconds,
    String? generationId,
  }) {
    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw StableAudioException('Malformed Stable Audio JSON response: $e');
    }

    if (json['id'] is String &&
        (json['status'] == 'in-progress' || json['audio'] == null)) {
      throw StableAudioException(
        'Stable Audio still in progress for "${json['id']}".',
      );
    }

    final audioB64 = (json['audio'] as String?)?.trim() ?? '';
    if (audioB64.isEmpty) {
      throw const StableAudioException(
        'Stable Audio JSON response missing audio.',
      );
    }
    late final List<int> bytes;
    try {
      bytes = base64Decode(audioB64);
    } catch (e) {
      throw StableAudioException(
        'Stable Audio returned invalid base64 audio: $e',
      );
    }
    if (bytes.isEmpty) {
      throw const StableAudioException(
        'Stable Audio JSON response contained empty audio.',
      );
    }

    return StableAudioResult(
      audioBytes: bytes,
      contentType: _contentTypeForFormat(outputFormat),
      model: model,
      generationId: generationId ?? (json['id'] as String?),
      durationSeconds: requestedDurationSeconds,
    );
  }

  static String _parseGenerationId(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final id = decoded['id'] ?? decoded['generation_id'];
        if (id is String && id.trim().isNotEmpty) {
          return id.trim();
        }
      }
    } catch (_) {
      // Fall through to generic error.
    }
    throw StableAudioException(
      'Stable Audio 202 response missing generation id: ${_safe(body)}',
    );
  }

  static String _contentTypeForFormat(String format) {
    switch (format.trim().toLowerCase()) {
      case 'wav':
        return 'audio/wav';
      case 'mp3':
      default:
        return 'audio/mpeg';
    }
  }

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String _safe(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 240) return trimmed;
    return '${trimmed.substring(0, 240)}…';
  }
}

final class StableAudioResult {
  const StableAudioResult({
    required this.audioBytes,
    required this.contentType,
    required this.model,
    this.generationId,
    this.durationSeconds,
  });

  final List<int> audioBytes;
  final String contentType;
  final String model;
  final String? generationId;
  final int? durationSeconds;
}

final class StableAudioException implements Exception {
  const StableAudioException(this.message);

  final String message;

  @override
  String toString() => 'StableAudioException: $message';
}
