import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/domain/services/story_experience_planner_port.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_experience_planner_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_experience_plan_config.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_transcription_config.dart';

/// Default: development [InMemoryStoryExperiencePlannerAdapter].
///
/// Production uses [ProxyStoryExperiencePlannerAdapter] when `EH_AI_PROXY_URL` /
/// `EH_TRANSCRIPTION_MODE=proxy` is configured (same defines as transcription).
final storyExperiencePlannerPortProvider =
    Provider<StoryExperiencePlannerPort>((ref) {
  final mode = StoryExperiencePlanConfig.resolveMode();
  if (mode == StoryTranscriptionMode.proxy) {
    final baseUrl = StoryExperiencePlanConfig.resolveProxyBaseUrl();
    if (baseUrl == null) {
      throw StateError(
        'EH_TRANSCRIPTION_MODE=proxy requires EH_AI_PROXY_URL.',
      );
    }
    final adapter = ProxyStoryExperiencePlannerAdapter(
      baseUrl: baseUrl,
      authToken: StoryExperiencePlanConfig.resolveAuthToken(),
    );
    ref.onDispose(adapter.dispose);
    return adapter;
  }
  return StoryExperiencePlanConfig.createDevelopmentAdapter();
});
