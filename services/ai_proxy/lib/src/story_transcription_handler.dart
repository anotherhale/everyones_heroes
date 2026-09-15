import 'dart:convert';

import 'package:ai_proxy/src/openai_transcription_client.dart';
import 'package:ai_proxy/src/proxy_config.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// EH-owned HTTP contract for story transcription (HS.11).
///
/// `POST /story-transcriptions` accepts a JSON body with base64 media and
/// returns EH-owned fields — never OpenAI-specific request shapes to clients.
final class StoryTranscriptionHandler {
  StoryTranscriptionHandler({
    required ProxyConfig config,
    OpenAiTranscriptionClient? client,
  })  : _config = config,
        _client = client ??
            OpenAiTranscriptionClient(
              apiKey: config.openAiApiKey,
              baseUrl: config.openAiBaseUrl,
              model: config.transcriptionModel,
            );

  final ProxyConfig _config;
  final OpenAiTranscriptionClient _client;

  Router get router {
    final router = Router();
    router.post('/story-transcriptions', handleTranscribe);
    router.get('/health', (_) => Response.ok('ok'));
    return router;
  }

  Middleware get authMiddleware {
    return (Handler inner) {
      return (Request request) async {
        final requiredToken = _config.authToken;
        if (requiredToken == null || requiredToken.isEmpty) {
          return inner(request);
        }
        if (request.url.path == 'health') {
          return inner(request);
        }
        final header = request.headers['authorization'] ?? '';
        final token = header.startsWith('Bearer ')
            ? header.substring('Bearer '.length).trim()
            : '';
        if (token != requiredToken) {
          return Response(
            401,
            body: jsonEncode({'error': 'unauthorized'}),
            headers: {'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  Future<Response> handleTranscribe(Request request) async {
    late final Map<String, dynamic> payload;
    try {
      final raw = await request.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return _error(400, 'Request body must be a JSON object.');
      }
      payload = Map<String, dynamic>.from(decoded);
    } catch (e) {
      return _error(400, 'Malformed JSON body: $e');
    }

    final mediaBase64 = payload['mediaBase64'] as String?;
    if (mediaBase64 == null || mediaBase64.isEmpty) {
      return _error(400, 'mediaBase64 is required.');
    }

    late final List<int> bytes;
    try {
      bytes = base64Decode(mediaBase64);
    } catch (e) {
      return _error(400, 'mediaBase64 is not valid base64: $e');
    }
    if (bytes.isEmpty) {
      return _error(400, 'mediaBase64 decoded to empty audio.');
    }

    final contentType =
        (payload['contentType'] as String?)?.trim().isNotEmpty == true
            ? (payload['contentType'] as String).trim()
            : 'audio/mp4';
    final language = payload['language'] as String?;
    final filename = _filenameFor(contentType);

    try {
      final result = await _client.transcribe(
        audioBytes: bytes,
        contentType: contentType,
        filename: filename,
        language: language,
      );

      return Response.ok(
        jsonEncode({
          'text': result.text,
          'language': result.language ?? language ?? 'en',
          'providerLabel': 'openai_via_eh_proxy',
          'supportLevel': 'moderate',
          'storyId': payload['storyId'],
          'sourceRepresentationId': payload['sourceRepresentationId'],
          'requestId': payload['requestId'],
          'processingVersion': payload['processingVersion'],
        }),
        headers: {'content-type': 'application/json'},
      );
    } on OpenAiTranscriptionException catch (e) {
      return _error(502, e.message);
    } catch (e) {
      return _error(500, 'Proxy transcription failed: $e');
    }
  }

  static String _filenameFor(String contentType) {
    if (contentType.contains('wav')) return 'recording.wav';
    if (contentType.contains('mpeg') || contentType.contains('mp3')) {
      return 'recording.mp3';
    }
    if (contentType.contains('webm')) return 'recording.webm';
    if (contentType.contains('ogg')) return 'recording.ogg';
    return 'recording.m4a';
  }

  static Response _error(int status, String message) {
    return Response(
      status,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
