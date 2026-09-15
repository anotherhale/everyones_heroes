import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_transcription_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/transcription/transcription_store_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_unapproved_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_transcription_status_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_owned_story_transcription_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart';

/// HS.4 transcription use case wired for app composition (HS.11).
final transcribeStoryRepresentationUseCaseProvider =
    Provider<TranscribeStoryRepresentationUseCase>((ref) {
  return TranscribeStoryRepresentationUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    mediaStorage: ref.watch(storyMediaStoragePortProvider),
    transcriptionPort: ref.watch(storyTranscriptionPortProvider),
    eventBus: ref.watch(eventBusProvider),
    completionStore: ref.watch(transcriptionCompletionStoreProvider),
  );
});

final startOwnedStoryTranscriptionUseCaseProvider =
    Provider<StartOwnedStoryTranscriptionUseCase>((ref) {
  return StartOwnedStoryTranscriptionUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    transcribeStory: ref.watch(transcribeStoryRepresentationUseCaseProvider),
    jobStore: ref.watch(storyTranscriptionJobStoreProvider),
  );
});

final getOwnedStoryTranscriptionStatusUseCaseProvider =
    Provider<GetOwnedStoryTranscriptionStatusUseCase>((ref) {
  return GetOwnedStoryTranscriptionStatusUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    jobStore: ref.watch(storyTranscriptionJobStoreProvider),
  );
});

final editUnapprovedStoryRepresentationUseCaseProvider =
    Provider<EditUnapprovedStoryRepresentationUseCase>((ref) {
  return EditUnapprovedStoryRepresentationUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final approveStoryRepresentationUseCaseProvider =
    Provider<ApproveStoryRepresentationUseCase>((ref) {
  return ApproveStoryRepresentationUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});
