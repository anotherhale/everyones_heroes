import 'package:everyonesheroes/features/hero_story/application/lab/creative_direction_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_creative_direction_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves creative-direction mode from the same EH AI proxy defines.
abstract final class CreativeDirectionConfig {
  static StoryTranscriptionMode resolveMode() =>
      StoryTranscriptionConfig.resolveMode();

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static CreativeDirectionPort createDevelopmentAdapter() {
    return InMemoryCreativeDirectionAdapter();
  }
}
