import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/ports/sync_discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/hero_story/application/services/discoverable_story_candidate_sync.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_owned_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/platform/platform_sync_discoverable_story_candidate_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/submit_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_config.dart';

/// Owner Story application providers (HS.10 / HS.FG.1 / HS.FG.3 / J.2 Slice 5).
///
/// Separated from discoverability-gated experience providers.
///
/// HS.FG.1 wires existing Submit / Approve / Publish / Consent use cases for
/// the owner publication path. Does not introduce a second lifecycle model.
///
/// HS.FG.3 wires [ChangeHeroVisibilityUseCase] for explicit Hero
/// discoverability consent. Story publication does not change Hero visibility.
///
/// J.2 Slice 5 wires optional platform candidate projection sync after
/// publish / archive / hero-visibility (soft-fail; Story remains authoritative).

/// Port for EH Platform discoverable-candidate projection ingest.
///
/// No-op when platform authority is not configured (local/offline Today).
final syncDiscoverableStoryCandidatePortProvider =
    Provider<SyncDiscoverableStoryCandidatePort>((ref) {
  if (!EhPlatformConfig.usePlatformAuthority) {
    return const NoOpSyncDiscoverableStoryCandidatePort();
  }
  final client = ref.watch(ehPlatformClientProvider);
  if (client == null) {
    return const NoOpSyncDiscoverableStoryCandidatePort();
  }
  return PlatformSyncDiscoverableStoryCandidateAdapter(client: client);
});

final discoverableStoryCandidateSyncProvider =
    Provider<DiscoverableStoryCandidateSync>((ref) {
  return DiscoverableStoryCandidateSync(
    port: ref.watch(syncDiscoverableStoryCandidatePortProvider),
  );
});

final listHeroOwnedStoriesUseCaseProvider =
    Provider<ListHeroOwnedStoriesUseCase>((ref) {
      return ListHeroOwnedStoriesUseCase(
        storyRepository: ref.watch(storyRepositoryProvider),
        heroRepository: ref.watch(heroRepositoryProvider),
      );
    });

final getOwnedStoryDetailUseCaseProvider = Provider<GetOwnedStoryDetailUseCase>(
  (ref) {
    return GetOwnedStoryDetailUseCase(
      storyRepository: ref.watch(storyRepositoryProvider),
      heroRepository: ref.watch(heroRepositoryProvider),
    );
  },
);

final loadOwnedStoryMediaUseCaseProvider = Provider<LoadOwnedStoryMediaUseCase>(
  (ref) {
    return LoadOwnedStoryMediaUseCase(
      storyRepository: ref.watch(storyRepositoryProvider),
      heroRepository: ref.watch(heroRepositoryProvider),
      mediaStorage: ref.watch(storyMediaStoragePortProvider),
    );
  },
);

final archiveStoryUseCaseProvider = Provider<ArchiveStoryUseCase>((ref) {
  return ArchiveStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    candidateSync: ref.watch(discoverableStoryCandidateSyncProvider),
  );
});

/// Re-exported ownership composition of [SubmitStoryUseCase] (also available
/// from capture providers). Prefer this provider from owned Story UI.
final ownedSubmitStoryUseCaseProvider = Provider<SubmitStoryUseCase>((ref) {
  return SubmitStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final approveStoryUseCaseProvider = Provider<ApproveStoryUseCase>((ref) {
  return ApproveStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final publishStoryUseCaseProvider = Provider<PublishStoryUseCase>((ref) {
  return PublishStoryUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    heroRepository: ref.watch(heroRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
    candidateSync: ref.watch(discoverableStoryCandidateSyncProvider),
  );
});

/// Consent updates for owner publication composition (HS.FG.1).
///
/// Same use case as capture wiring; exposed here so owned UI does not depend
/// on capture provider modules.
final ownedUpdateStoryConsentUseCaseProvider =
    Provider<UpdateStoryConsentUseCase>((ref) {
  return UpdateStoryConsentUseCase(
    storyRepository: ref.watch(storyRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

/// Owner Hero discoverability composition (HS.FG.3).
///
/// Reuses [Hero.changeVisibility]; does not alter Story lifecycle or
/// Discovery policy.
final changeHeroVisibilityUseCaseProvider =
    Provider<ChangeHeroVisibilityUseCase>((ref) {
  return ChangeHeroVisibilityUseCase(
    heroRepository: ref.watch(heroRepositoryProvider),
    storyRepository: ref.watch(storyRepositoryProvider),
    candidateSync: ref.watch(discoverableStoryCandidateSyncProvider),
  );
});
