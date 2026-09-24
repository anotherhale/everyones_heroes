import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves Story Experience Plan mode from the same EH AI proxy defines.
///
/// Reuses `EH_AI_PROXY_URL`, `EH_TRANSCRIPTION_MODE`, and
/// `EH_AI_PROXY_AUTH_TOKEN` — no second auth scheme.
abstract final class StoryExperiencePlanConfig {
  static StoryTranscriptionMode resolveMode() =>
      StoryTranscriptionConfig.resolveMode();

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static StoryExperiencePlannerPort createDevelopmentAdapter() {
    return InMemoryStoryExperiencePlannerAdapter();
  }
}
