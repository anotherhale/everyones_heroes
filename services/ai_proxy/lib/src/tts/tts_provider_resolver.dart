import 'package:ai_proxy/src/openai_speech_client.dart';
import 'package:ai_proxy/src/proxy_config.dart';
import 'package:ai_proxy/src/tts/local_http_tts_provider.dart';
import 'package:ai_proxy/src/tts/openai_tts_provider.dart';
import 'package:ai_proxy/src/tts/tts_provider.dart';

/// Resolves the active [TtsProvider] from proxy configuration (HS.12.7).
///
/// Selection order:
/// 1. Opaque request `providerHint` when `EH_TTS_ALLOW_PROVIDER_HINTS=true`
/// 2. Else `EH_TTS_PROVIDER` (default `openai`)
///
/// Successfully verified adapters in HS.12.7: `openai`, `qwen3`.
/// `cosyvoice` is intentionally **not** wired — install/runtime was not
/// successfully verified on the spike host (see benchmark report).
///
/// Unknown / unverified providers fail closed with [TtsProviderException].
final class TtsProviderResolver {
  TtsProviderResolver({
    required ProxyConfig config,
    TtsProvider? openAiProvider,
    TtsProvider? qwen3Provider,
    OpenAiSpeechClient? openAiSpeechClient,
  })  : _config = config,
        _openAi = openAiProvider ??
            OpenAiTtsProvider(
              client: openAiSpeechClient ??
                  OpenAiSpeechClient(
                    apiKey: config.openAiApiKey,
                    baseUrl: config.openAiBaseUrl,
                    model: config.speechModel,
                    voice: config.speechVoice,
                  ),
            ),
        _qwen3 = qwen3Provider ??
            (config.localTtsBaseUrl != null
                ? LocalHttpTtsProvider(
                    providerKey: 'qwen3',
                    baseUrl: config.localTtsBaseUrl!,
                  )
                : null);

  final ProxyConfig _config;
  final TtsProvider _openAi;
  final TtsProvider? _qwen3;

  /// Providers with a verified complete-file synthetic path in HS.12.7.
  static const supportedProviders = {'openai', 'qwen3'};

  /// Resolve provider for one synthesis call.
  TtsProvider resolve({String? providerHint}) {
    final key = _selectKey(providerHint);
    return _providerFor(key);
  }

  String _selectKey(String? providerHint) {
    final hint = providerHint?.trim().toLowerCase();
    if (_config.allowTtsProviderHints &&
        hint != null &&
        hint.isNotEmpty) {
      return hint;
    }
    return _config.ttsProvider;
  }

  TtsProvider _providerFor(String key) {
    switch (key) {
      case 'openai':
        return _openAi;
      case 'qwen3':
        final provider = _qwen3;
        if (provider == null) {
          throw const TtsProviderException(
            'TTS provider "qwen3" is configured but EH_LOCAL_TTS_URL is unset '
            'or the local sidecar is not wired.',
          );
        }
        return provider;
      case 'cosyvoice':
        throw const TtsProviderException(
          'TTS provider "cosyvoice" was not successfully verified in HS.12.7 '
          '(install/runtime spike incomplete). Use openai or qwen3.',
        );
      default:
        throw TtsProviderException(
          'Unsupported TTS provider "$key". '
          'Supported: ${supportedProviders.join(', ')}.',
        );
    }
  }
}
