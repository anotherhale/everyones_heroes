import 'package:everyonesheroes/features/hero_story/domain/services/music_generation_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_music_generation_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves music-generation mode from the same EH AI proxy defines.
abstract final class MusicGenerationConfig {
  static StoryTranscriptionMode resolveMode() =>
      StoryTranscriptionConfig.resolveMode();

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static MusicGenerationPort createDevelopmentAdapter() {
    return InMemoryMusicGenerationAdapter();
  }
}
