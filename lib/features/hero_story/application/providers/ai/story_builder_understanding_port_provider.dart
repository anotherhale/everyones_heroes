import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_understanding_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_builder_understanding_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_builder_understanding_config.dart';

/// Default: development [InMemoryStoryBuilderUnderstandingAdapter].
///
/// Production composition uses [ProxyStoryBuilderUnderstandingAdapter] when
/// `EH_AI_PROXY_URL` / `EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy` is configured.
final storyBuilderUnderstandingPortProvider =
    Provider<StoryBuilderUnderstandingPort>((ref) {
  final mode = StoryBuilderUnderstandingConfig.resolveMode();
  if (mode == StoryBuilderUnderstandingMode.proxy) {
    final baseUrl = StoryBuilderUnderstandingConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryBuilderUnderstandingAdapter(
      baseUrl: baseUrl,
      authToken: StoryBuilderUnderstandingConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return StoryBuilderUnderstandingConfig.createDevelopmentAdapter();
});
