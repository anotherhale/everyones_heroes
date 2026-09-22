import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_builder_understanding_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves Story Builder understanding mode from compile-time configuration.
///
/// Reuses [EH_AI_PROXY_URL] / [EH_AI_PROXY_AUTH_TOKEN] — no second proxy URL.
/// Optional: `--dart-define=EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy|development`.
enum StoryBuilderUnderstandingMode {
  development,
  proxy,
}

abstract final class StoryBuilderUnderstandingConfig {
  static const String modeDefine = String.fromEnvironment(
    'EH_STORY_BUILDER_UNDERSTANDING_MODE',
    defaultValue: '',
  );

  static StoryBuilderUnderstandingMode resolveMode() {
    final explicit = modeDefine.trim().toLowerCase();
    if (explicit == 'proxy') {
      return StoryBuilderUnderstandingMode.proxy;
    }
    if (explicit == 'development' || explicit == 'dev') {
      return StoryBuilderUnderstandingMode.development;
    }
    if (StoryTranscriptionConfig.proxyUrlDefine.trim().isNotEmpty) {
      return StoryBuilderUnderstandingMode.proxy;
    }
    return StoryBuilderUnderstandingMode.development;
  }

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static StoryBuilderUnderstandingPort createDevelopmentAdapter() {
    return InMemoryStoryBuilderUnderstandingAdapter();
  }
}
