import 'package:everyonesheroes/features/hero_story/domain/services/story_transcription_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart';

/// Explicit development/test transcription mode (HS.11 / HS-ADR-067).
///
/// Never selected accidentally for production when a proxy URL is configured.
enum StoryTranscriptionMode {
  /// Deterministic [InMemoryStoryTranscriptionAdapter] — local tests / demos.
  development,

  /// [ProxyStoryTranscriptionAdapter] → EH AI backend → OpenAI.
  proxy,
}

/// Resolves transcription mode from compile-time configuration.
///
/// Production path requires `--dart-define=EH_AI_PROXY_URL=...`.
/// Optional: `--dart-define=EH_TRANSCRIPTION_MODE=proxy|development`.
abstract final class StoryTranscriptionConfig {
  static const String proxyUrlDefine = String.fromEnvironment(
    'EH_AI_PROXY_URL',
    defaultValue: '',
  );

  static const String modeDefine = String.fromEnvironment(
    'EH_TRANSCRIPTION_MODE',
    defaultValue: '',
  );

  static const String authTokenDefine = String.fromEnvironment(
    'EH_AI_PROXY_AUTH_TOKEN',
    defaultValue: '',
  );

  static StoryTranscriptionMode resolveMode() {
    final explicit = modeDefine.trim().toLowerCase();
    if (explicit == 'proxy') {
      return StoryTranscriptionMode.proxy;
    }
    if (explicit == 'development' || explicit == 'dev') {
      return StoryTranscriptionMode.development;
    }
    if (proxyUrlDefine.trim().isNotEmpty) {
      return StoryTranscriptionMode.proxy;
    }
    return StoryTranscriptionMode.development;
  }

  static Uri? resolveProxyBaseUrl() {
    final raw = proxyUrlDefine.trim();
    if (raw.isEmpty) {
      return null;
    }
    return Uri.parse(raw);
  }

  static String? resolveAuthToken() {
    final token = authTokenDefine.trim();
    return token.isEmpty ? null : token;
  }

  /// Default development adapter — deterministic, no network, no secrets.
  static StoryTranscriptionPort createDevelopmentAdapter() {
    return InMemoryStoryTranscriptionAdapter();
  }
}
