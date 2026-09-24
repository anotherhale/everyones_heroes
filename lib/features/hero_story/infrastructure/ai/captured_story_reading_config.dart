import 'package:everyonesheroes/features/hero_story/domain/services/captured_story_reading_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_captured_story_reading_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves captured-story reading mode from the same EH AI proxy defines.
///
/// Reuses `EH_AI_PROXY_URL`, `EH_TRANSCRIPTION_MODE`, and
/// `EH_AI_PROXY_AUTH_TOKEN` — no second auth scheme.
abstract final class CapturedStoryReadingConfig {
  static StoryTranscriptionMode resolveMode() =>
      StoryTranscriptionConfig.resolveMode();

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static CapturedStoryReadingPort createDevelopmentAdapter() {
    return InMemoryCapturedStoryReadingAdapter();
  }
}
