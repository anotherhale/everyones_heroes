import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/ai_story_shaper.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_shaper.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_authoring_transport.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_shaper_strategy_resolver.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_shaper_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_authoring_config.dart';

/// Default: development in-memory authoring transport.
///
/// Production uses [ProxyStoryShaperAdapter] when `EH_AI_PROXY_URL` /
/// `EH_STORY_AUTHORING_MODE=proxy` is configured.
final storyAuthoringTransportProvider = Provider<StoryAuthoringTransport>((ref) {
  final mode = StoryAuthoringConfig.resolveMode();
  if (mode == StoryAuthoringMode.proxy) {
    final baseUrl = StoryAuthoringConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_STORY_AUTHORING_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryShaperAdapter(
      baseUrl: baseUrl,
      authToken: StoryAuthoringConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return StoryAuthoringConfig.createDevelopmentAdapter();
});

/// SB.11 AI shaper — depends on [storyAuthoringTransportProvider].
final aiStoryShaperProvider = Provider<StoryShaperPort>((ref) {
  return AiStoryShaper(transport: ref.watch(storyAuthoringTransportProvider));
});

/// Resolves deterministic (SB.10) vs AI (SB.11) shaping.
final storyShaperStrategyResolverProvider =
    Provider<StoryShaperStrategyResolver>((ref) {
  return DefaultStoryShaperStrategyResolver(
    deterministic: const DeterministicStoryShaper(),
    ai: ref.watch(aiStoryShaperProvider),
  );
});
