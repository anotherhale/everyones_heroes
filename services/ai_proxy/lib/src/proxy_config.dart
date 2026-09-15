import 'dart:io';

/// Server-side configuration for the EH AI proxy (HS.11 / HS-ADR-067).
///
/// OpenAI credentials and model selection live here — never in Flutter.
final class ProxyConfig {
  const ProxyConfig({
    required this.openAiApiKey,
    this.openAiBaseUrl = 'https://api.openai.com/v1',
    this.transcriptionModel = 'gpt-4o-mini-transcribe',
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
    return ProxyConfig(
      openAiApiKey: key,
      openAiBaseUrl: env['OPENAI_BASE_URL']?.trim().isNotEmpty == true
          ? env['OPENAI_BASE_URL']!.trim()
          : 'https://api.openai.com/v1',
      transcriptionModel:
          env['OPENAI_TRANSCRIPTION_MODEL']?.trim().isNotEmpty == true
              ? env['OPENAI_TRANSCRIPTION_MODEL']!.trim()
              : 'gpt-4o-mini-transcribe',
      host: env['EH_AI_PROXY_HOST']?.trim().isNotEmpty == true
          ? env['EH_AI_PROXY_HOST']!.trim()
          : '0.0.0.0',
      port: int.tryParse(env['EH_AI_PROXY_PORT'] ?? '') ?? 8787,
      authToken: env['EH_AI_PROXY_AUTH_TOKEN']?.trim().isNotEmpty == true
          ? env['EH_AI_PROXY_AUTH_TOKEN']!.trim()
          : null,
    );
  }

  final String openAiApiKey;
  final String openAiBaseUrl;
  final String transcriptionModel;
  final String host;
  final int port;
  final String? authToken;
}
