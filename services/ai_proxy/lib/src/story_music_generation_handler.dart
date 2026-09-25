import 'dart:convert';

import 'package:ai_proxy/src/proxy_config.dart';
import 'package:ai_proxy/src/stable_audio_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// EH-owned HTTP contract for Experiment A story music generation.
///
/// `POST /story-music-generations` accepts plan-derived prompt inputs and
/// returns base64 instrumental audio. Does not mutate Story content.
final class StoryMusicGenerationHandler {
  StoryMusicGenerationHandler({
    required ProxyConfig config,
    StableAudioClient? client,
  })  : _config = config,
        _client = client ??
            StableAudioClient(
              apiKey: config.stabilityApiKey,
              baseUrl: config.stabilityBaseUrl,
              model: config.stabilityAudioModel,
            );

  final ProxyConfig _config;
  final StableAudioClient _client;

  static const defaultProcessingVersion = 'exp-a.music.v1';
  static const providerLabel = 'stable_audio_via_eh_proxy';

  Router get router {
    final router = Router();
    router.post('/story-music-generations', handleGenerate);
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

  Future<Response> handleGenerate(Request request) async {
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

    final storyId = payload['storyId'];
    final experiencePlanId = payload['experiencePlanId'];
    final planVersion = payload['experiencePlanProcessingVersion'];
    final prompt = (payload['prompt'] as String?)?.trim() ?? '';
    final durationRaw = payload['targetDurationSeconds'];

    if (storyId is! String || storyId.trim().isEmpty) {
      return _error(400, 'storyId is required.');
    }
    if (experiencePlanId is! String || experiencePlanId.trim().isEmpty) {
      return _error(400, 'experiencePlanId is required.');
    }
    if (planVersion is! String || planVersion.trim().isEmpty) {
      return _error(400, 'experiencePlanProcessingVersion is required.');
    }
    if (prompt.isEmpty) {
      return _error(400, 'prompt is required.');
    }
    if (durationRaw is! int && durationRaw is! num) {
      return _error(400, 'targetDurationSeconds is required.');
    }
    final durationSeconds = durationRaw is int
        ? durationRaw
        : (durationRaw as num).round();
    if (durationSeconds < 1 || durationSeconds > 380) {
      return _error(
        400,
        'targetDurationSeconds must be between 1 and 380.',
      );
    }

    final instrumentalPreferred = payload['instrumentalPreferred'] is bool
        ? payload['instrumentalPreferred'] as bool
        : true;
    if (instrumentalPreferred) {
      final lower = prompt.toLowerCase();
      if (!lower.contains('instrumental') &&
          !lower.contains('no vocals') &&
          !lower.contains('no lyrics')) {
        return _error(
          400,
          'When instrumentalPreferred is true, prompt must contain '
          '"instrumental", "no vocals", or "no lyrics".',
        );
      }
    }

    final modelHint = (payload['model'] as String?)?.trim();
    final modelLabel = (modelHint != null && modelHint.isNotEmpty)
        ? modelHint
        : _config.stabilityAudioModel;

    try {
      final result = await _client.generate(
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
      if (result.audioBytes.isEmpty) {
        return _error(502, 'Provider returned empty audio.');
      }

      return Response.ok(
        jsonEncode({
          'storyId': storyId.trim(),
          'experiencePlanId': experiencePlanId.trim(),
          'experiencePlanProcessingVersion': planVersion.trim(),
          'audioBase64': base64Encode(result.audioBytes),
          'contentType': result.contentType,
          'durationSeconds':
              result.durationSeconds ?? durationSeconds,
          'providerLabel': providerLabel,
          'modelLabel': modelLabel,
          if (result.generationId != null &&
              result.generationId!.trim().isNotEmpty)
            'generationId': result.generationId!.trim(),
          'promptUsed': prompt,
          'processingVersion':
              (payload['processingVersion'] as String?)?.trim().isNotEmpty ==
                      true
                  ? (payload['processingVersion'] as String).trim()
                  : defaultProcessingVersion,
          'instrumental': true,
          if ((payload['experimentId'] as String?)?.trim().isNotEmpty == true)
            'experimentId': (payload['experimentId'] as String).trim(),
          if ((payload['requestId'] as String?)?.trim().isNotEmpty == true)
            'requestId': (payload['requestId'] as String).trim(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } on StableAudioException catch (e) {
      return _error(502, e.message);
    } catch (e) {
      return _error(500, 'Unexpected story-music generation failure: $e');
    }
  }

  Response _error(int status, String message) {
    return Response(
      status,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
