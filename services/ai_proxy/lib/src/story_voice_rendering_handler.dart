import 'dart:convert';

import 'package:ai_proxy/src/openai_speech_client.dart';
import 'package:ai_proxy/src/proxy_config.dart';
import 'package:ai_proxy/src/tts/tts_provider.dart';
import 'package:ai_proxy/src/tts/tts_provider_resolver.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// EH-owned HTTP contract for Story voice rendering (HS.12.6 / HS-ADR-077).
///
/// `POST /story-voice-renderings` accepts presentation source text and returns
/// complete-file base64 audio for ordinary synthetic narration. Does not
/// rewrite Story content, invent psychological claims, or perform voice cloning.
///
/// Provider selection is infrastructure-side (env / opaque hints). Domain never
/// depends on a specific TTS vendor. HS.12.7 adds an internal [TtsProvider]
/// resolver (`openai` / `qwen3` / `cosyvoice`) that stays inside this proxy.
final class StoryVoiceRenderingHandler {
  StoryVoiceRenderingHandler({
    required ProxyConfig config,
    TtsProviderResolver? ttsResolver,
    @Deprecated('Use ttsResolver / TtsProvider; retained for existing tests')
    OpenAiSpeechClient? client,
  })  : _config = config,
        _ttsResolver = ttsResolver ??
            TtsProviderResolver(
              config: config,
              openAiSpeechClient: client,
            );

  final ProxyConfig _config;
  final TtsProviderResolver _ttsResolver;

  static const supportedMode = 'syntheticNarration';
  static final RegExp _languagePattern =
      RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})?$');

  Router get router {
    final router = Router();
    router.post('/story-voice-renderings', handleRender);
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

  Future<Response> handleRender(Request request) async {
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

    final sourceText = (payload['sourceText'] as String?)?.trim() ?? '';
    if (sourceText.isEmpty) {
      return _error(400, 'sourceText is required.');
    }

    final storyId = payload['storyId'];
    final experiencePlanId = payload['experiencePlanId'];
    final sourceRepresentationId = payload['sourceRepresentationId'];
    final renderingMode = (payload['renderingMode'] as String?)?.trim() ?? '';
    final languageRaw = (payload['language'] as String?)?.trim().toLowerCase() ??
        '';

    if (storyId is! String || storyId.trim().isEmpty) {
      return _error(400, 'storyId is required.');
    }
    if (experiencePlanId is! String || experiencePlanId.trim().isEmpty) {
      return _error(400, 'experiencePlanId is required.');
    }
    if (sourceRepresentationId is! String ||
        sourceRepresentationId.trim().isEmpty) {
      return _error(400, 'sourceRepresentationId is required.');
    }
    if (languageRaw.isEmpty) {
      return _error(400, 'language is required.');
    }
    if (!_languagePattern.hasMatch(languageRaw)) {
      return _error(
        400,
        'language must be a valid BCP 47 primary tag '
        '(optionally with region), e.g. "en", "es", "en-us".',
      );
    }
    if (renderingMode.isEmpty) {
      return _error(400, 'renderingMode is required.');
    }
    if (renderingMode != supportedMode) {
      return _error(
        400,
        'Unsupported renderingMode "$renderingMode". '
        'Synthetic Story voice rendering supports only $supportedMode '
        '(ordinary synthetic narration — not voice cloning). '
        'Voice cloning is not authorized by narration consent.',
      );
    }

    // Opaque routing hints are accepted for infrastructure selection only.
    final providerHint = (payload['providerHint'] as String?)?.trim();
    final modelHint = (payload['modelHint'] as String?)?.trim();

    try {
      final provider = _ttsResolver.resolve(providerHint: providerHint);
      final result = await provider.synthesize(
        TtsSynthesisRequest(
          text: sourceText,
          language: languageRaw,
          modelHint: modelHint,
        ),
      );
      if (result.audioBytes.isEmpty) {
        return _error(502, 'Provider returned empty audio.');
      }

      final providerLabel = '${provider.providerKey}_tts_via_eh_proxy';
      final modelLabel = (modelHint != null && modelHint.isNotEmpty)
          ? modelHint
          : result.modelLabel;

      return Response.ok(
        jsonEncode({
          'storyId': storyId.trim(),
          'experiencePlanId': experiencePlanId.trim(),
          'experiencePlanProcessingVersion':
              (payload['experiencePlanProcessingVersion'] as String?)
                          ?.trim()
                          .isNotEmpty ==
                      true
                  ? (payload['experiencePlanProcessingVersion'] as String)
                      .trim()
                  : null,
          'sourceRepresentationId': sourceRepresentationId.trim(),
          'language': languageRaw,
          'renderingMode': supportedMode,
          'audioBase64': base64Encode(result.audioBytes),
          'contentType': result.contentType,
          'providerLabel': providerLabel,
          'modelLabel': modelLabel,
          'processingVersion':
              (payload['processingVersion'] as String?)?.trim().isNotEmpty ==
                      true
                  ? (payload['processingVersion'] as String).trim()
                  : 'hs12.6.v1',
        }),
        headers: {'content-type': 'application/json'},
      );
    } on TtsProviderException catch (e) {
      return _error(502, e.message);
    } on OpenAiSpeechException catch (e) {
      return _error(502, e.message);
    } catch (e) {
      return _error(500, 'Unexpected voice-rendering failure: $e');
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
