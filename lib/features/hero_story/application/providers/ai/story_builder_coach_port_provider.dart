import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_builder_coach_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_coach_config.dart';

/// Default: development [InMemoryStoryBuilderCoachAdapter].
///
/// Production composition uses [ProxyStoryBuilderCoachAdapter] when
/// `EH_AI_PROXY_URL` / `EH_STORY_BUILDER_COACH_MODE=proxy` is configured.
final storyBuilderCoachPortProvider = Provider<StoryBuilderCoachPort>((ref) {
  final mode = StoryBuilderCoachConfig.resolveMode();
  if (mode == StoryBuilderCoachMode.proxy) {
    final baseUrl = StoryBuilderCoachConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_STORY_BUILDER_COACH_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryBuilderCoachAdapter(
      baseUrl: baseUrl,
      authToken: StoryBuilderCoachConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return StoryBuilderCoachConfig.createDevelopmentAdapter();
});
