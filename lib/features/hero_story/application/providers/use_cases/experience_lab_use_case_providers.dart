import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/ai/creative_direction_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/music_generation_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/voice_rendering_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_lab_run_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/experience_render_manifest_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/music_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_experience_plan_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_voice_rendering_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/run_experience_lab_use_case.dart';

final runExperienceLabUseCaseProvider = Provider<RunExperienceLabUseCase>((ref) {
  return RunExperienceLabUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    planRepository: ref.watch(storyExperiencePlanRepositoryProvider),
    creativeDirectionPort: ref.watch(creativeDirectionPortProvider),
    voiceRenderingPort: ref.watch(voiceRenderingPortProvider),
    musicGenerationPort: ref.watch(musicGenerationPortProvider),
    voiceRenderingRepository: ref.watch(storyVoiceRenderingRepositoryProvider),
    musicRenderingRepository: ref.watch(musicRenderingRepositoryProvider),
    labRunRepository: ref.watch(experienceLabRunRepositoryProvider),
    manifestRepository: ref.watch(experienceRenderManifestRepositoryProvider),
    mediaStorage: ref.watch(storyMediaStoragePortProvider),
  );
});
