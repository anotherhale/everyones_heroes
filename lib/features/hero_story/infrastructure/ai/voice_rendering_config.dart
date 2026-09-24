import 'package:everyonesheroes/features/hero_story/domain/services/voice_rendering_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_voice_rendering_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves voice-rendering mode from the same EH AI proxy defines.
///
/// Reuses `EH_AI_PROXY_URL`, `EH_TRANSCRIPTION_MODE`, and
/// `EH_AI_PROXY_AUTH_TOKEN` — no second auth scheme / gateway.
abstract final class VoiceRenderingConfig {
  static StoryTranscriptionMode resolveMode() =>
      StoryTranscriptionConfig.resolveMode();

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static VoiceRenderingPort createDevelopmentAdapter() {
    return InMemoryVoiceRenderingAdapter();
  }
}
