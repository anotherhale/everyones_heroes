import 'dart:io';

/// Server-side configuration for the EH AI proxy (HS.11 / SB.7 / Experiment A).
///
/// Vendor credentials and model selection live here — never in Flutter.
final class ProxyConfig {
  const ProxyConfig({
    required this.openAiApiKey,
    this.openAiBaseUrl = 'https://api.openai.com/v1',
    this.transcriptionModel = 'gpt-4o-mini-transcribe',
    this.chatModel = 'gpt-4o-mini',
    this.speechModel = 'tts-1',
    this.speechVoice = 'alloy',
    this.ttsProvider = 'openai',
    this.allowTtsProviderHints = false,
    this.localTtsBaseUrl,
    this.stabilityApiKey = '',
    this.stabilityBaseUrl = 'https://api.stability.ai',
    this.stabilityAudioModel = 'stable-audio-3',
    this.host = '0.0.0.0',
    this.port = 8787,
    this.authToken,
  });

  /// Loads from process environment (server-side only).
  factory ProxyConfig.fromEnvironment({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final key = env['OPENAI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is required for the production AI proxy.',
      );
    }
    final ttsProvider =
        (env['EH_TTS_PROVIDER']?.trim().isNotEmpty == true
                ? env['EH_TTS_PROVIDER']!.trim()
                : 'openai')
            .toLowerCase();
    final localTtsUrl = env['EH_LOCAL_TTS_URL']?.trim();
    return ProxyConfig(
      openAiApiKey: key,
      openAiBaseUrl: env['OPENAI_BASE_URL']?.trim().isNotEmpty == true
          ? env['OPENAI_BASE_URL']!.trim()
          : 'https://api.openai.com/v1',
      transcriptionModel:
          env['OPENAI_TRANSCRIPTION_MODEL']?.trim().isNotEmpty == true
              ? env['OPENAI_TRANSCRIPTION_MODEL']!.trim()
              : 'gpt-4o-mini-transcribe',
      chatModel: env['OPENAI_CHAT_MODEL']?.trim().isNotEmpty == true
          ? env['OPENAI_CHAT_MODEL']!.trim()
          : 'gpt-4o-mini',
      speechModel: env['OPENAI_SPEECH_MODEL']?.trim().isNotEmpty == true
          ? env['OPENAI_SPEECH_MODEL']!.trim()
          : 'tts-1',
      speechVoice: env['OPENAI_SPEECH_VOICE']?.trim().isNotEmpty == true
          ? env['OPENAI_SPEECH_VOICE']!.trim()
          : 'alloy',
      ttsProvider: ttsProvider,
      allowTtsProviderHints: _truthy(env['EH_TTS_ALLOW_PROVIDER_HINTS']),
      localTtsBaseUrl: localTtsUrl != null && localTtsUrl.isNotEmpty
          ? Uri.parse(localTtsUrl)
          : null,
      stabilityApiKey: env['STABILITY_API_KEY']?.trim() ?? '',
      stabilityBaseUrl: env['STABILITY_BASE_URL']?.trim().isNotEmpty == true
          ? env['STABILITY_BASE_URL']!.trim()
          : 'https://api.stability.ai',
      stabilityAudioModel:
          env['STABILITY_AUDIO_MODEL']?.trim().isNotEmpty == true
              ? env['STABILITY_AUDIO_MODEL']!.trim()
              : 'stable-audio-3',
      host: env['EH_AI_PROXY_HOST']?.trim().isNotEmpty == true
          ? env['EH_AI_PROXY_HOST']!.trim()
          : '0.0.0.0',
      // Prefer EH_AI_PROXY_PORT; fall back to platform PORT (e.g. Render), then 8787.
      port: int.tryParse(env['EH_AI_PROXY_PORT'] ?? '') ??
          int.tryParse(env['PORT'] ?? '') ??
          8787,
      authToken: env['EH_AI_PROXY_AUTH_TOKEN']?.trim().isNotEmpty == true
          ? env['EH_AI_PROXY_AUTH_TOKEN']!.trim()
          : null,
    );
  }

  static bool _truthy(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on';
  }

  final String openAiApiKey;
  final String openAiBaseUrl;
  final String transcriptionModel;
  final String chatModel;
  final String speechModel;
  final String speechVoice;

  /// Default TTS backend: `openai` | `qwen3` (HS.12.7).
  /// `cosyvoice` remains a documented candidate but is not a verified adapter.
  final String ttsProvider;

  /// When true, opaque request `providerHint` may override [ttsProvider].
  final bool allowTtsProviderHints;

  /// Base URL for the local TTS Python sidecar (Qwen3 / CosyVoice).
  final Uri? localTtsBaseUrl;

  /// Optional; required only when [StoryMusicGenerationHandler] is used live.
  final String stabilityApiKey;
  final String stabilityBaseUrl;
  final String stabilityAudioModel;

  final String host;
  final int port;
  final String? authToken;

  bool get hasStabilityApiKey => stabilityApiKey.trim().isNotEmpty;
}
