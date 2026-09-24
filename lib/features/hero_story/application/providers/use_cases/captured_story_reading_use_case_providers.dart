import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/providers/ai/captured_story_reading_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/captured_story_reading_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/transcription_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_captured_story_reading_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/understand_owned_hero_story_use_case.dart';

final generateCapturedStoryReadingUseCaseProvider =
    Provider<GenerateCapturedStoryReadingUseCase>((ref) {
  return GenerateCapturedStoryReadingUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    readingPort: ref.watch(capturedStoryReadingPortProvider),
    readingRepository: ref.watch(capturedStoryReadingRepositoryProvider),
  );
});

final understandOwnedHeroStoryUseCaseProvider =
    Provider<UnderstandOwnedHeroStoryUseCase>((ref) {
  return UnderstandOwnedHeroStoryUseCase(
    startTranscription: ref.watch(startOwnedStoryTranscriptionUseCaseProvider),
    generateReading: ref.watch(generateCapturedStoryReadingUseCaseProvider),
  );
});
