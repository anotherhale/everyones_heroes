import 'package:everyonesheroes/features/hero_story/domain/services/story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Resolves Story Builder script generator mode from compile-time config.
///
/// Reuses [EH_AI_PROXY_URL] / [EH_AI_PROXY_AUTH_TOKEN] — no second auth.
/// Optional: `--dart-define=EH_STORY_SCRIPT_GENERATOR_MODE=proxy|development`.
enum StoryScriptGeneratorMode {
  development,
  proxy,
}

abstract final class StoryScriptGeneratorConfig {
  static const String modeDefine = String.fromEnvironment(
    'EH_STORY_SCRIPT_GENERATOR_MODE',
    defaultValue: '',
  );

  static StoryScriptGeneratorMode resolveMode() {
    final explicit = modeDefine.trim().toLowerCase();
    if (explicit == 'proxy') {
      return StoryScriptGeneratorMode.proxy;
    }
    if (explicit == 'development' || explicit == 'dev') {
      return StoryScriptGeneratorMode.development;
    }
    if (StoryTranscriptionConfig.proxyUrlDefine.trim().isNotEmpty) {
      return StoryScriptGeneratorMode.proxy;
    }
    return StoryScriptGeneratorMode.development;
  }

  static Uri? resolveProxyBaseUrl() =>
      StoryTranscriptionConfig.resolveProxyBaseUrl();

  static String? resolveAuthToken() =>
      StoryTranscriptionConfig.resolveAuthToken();

  static StoryScriptGenerator createDevelopmentAdapter() {
    return InMemoryStoryScriptGenerator();
  }
}
