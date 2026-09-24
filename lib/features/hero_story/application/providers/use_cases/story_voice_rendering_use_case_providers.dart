import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/ai/voice_rendering_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/render_story_voice_use_case.dart';

final renderStoryVoiceUseCaseProvider = Provider<RenderStoryVoiceUseCase>((
  ref,
) {
  return RenderStoryVoiceUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    planRepository: ref.watch(storyExperiencePlanRepositoryProvider),
    voiceRenderingPort: ref.watch(voiceRenderingPortProvider),
    renderingRepository: ref.watch(storyVoiceRenderingRepositoryProvider),
    mediaStorage: ref.watch(storyMediaStoragePortProvider),
  );
});
