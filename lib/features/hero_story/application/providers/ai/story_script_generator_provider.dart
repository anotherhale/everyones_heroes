import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_script_generator_config.dart';

/// Default: development [InMemoryStoryScriptGenerator].
///
/// Production composition uses [ProxyStoryScriptGenerator] when
/// `EH_AI_PROXY_URL` / `EH_STORY_SCRIPT_GENERATOR_MODE=proxy` is configured.
final storyScriptGeneratorProvider = Provider<StoryScriptGenerator>((ref) {
  final mode = StoryScriptGeneratorConfig.resolveMode();
  if (mode == StoryScriptGeneratorMode.proxy) {
    final baseUrl = StoryScriptGeneratorConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_STORY_SCRIPT_GENERATOR_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryScriptGenerator(
      baseUrl: baseUrl,
      authToken: StoryScriptGeneratorConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return StoryScriptGeneratorConfig.createDevelopmentAdapter();
});
