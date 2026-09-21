import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_builder_coach_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves Story Builder coach mode from compile-time configuration.
///
/// Reuses [EH_AI_PROXY_URL] / [EH_AI_PROXY_AUTH_TOKEN] — no second proxy URL.
/// Optional: `--dart-define=EH_STORY_BUILDER_COACH_MODE=proxy|development`.
enum StoryBuilderCoachMode {
  development,
  proxy,
}

abstract final class StoryBuilderCoachConfig {
  static const String modeDefine = String.fromEnvironment(
    'EH_STORY_BUILDER_COACH_MODE',
    defaultValue: '',
  );

  static StoryBuilderCoachMode resolveMode() {
    final explicit = modeDefine.trim().toLowerCase();
    if (explicit == 'proxy') {
      return StoryBuilderCoachMode.proxy;
    }
    if (explicit == 'development' || explicit == 'dev') {
      return StoryBuilderCoachMode.development;
    }
    if (StoryTranscriptionConfig.proxyUrlDefine.trim().isNotEmpty) {
      return StoryBuilderCoachMode.proxy;
    }
    return StoryBuilderCoachMode.development;
  }

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static StoryBuilderCoachPort createDevelopmentAdapter() {
    return InMemoryStoryBuilderCoachAdapter();
  }
}
