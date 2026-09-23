import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/media/story_media_storage_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_owned_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';

/// Owner Story application providers (HS.10 / HS.FG.1 / HS.FG.3).
///
/// Separated from discoverability-gated experience providers.
///
/// HS.FG.1 wires existing Submit / Approve / Publish / Consent use cases for
/// the owner publication path. Does not introduce a second lifecycle model.
///
/// HS.FG.3 wires [ChangeHeroVisibilityUseCase] for explicit Hero
/// discoverability consent. Story publication does not change Hero visibility.
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
  );
});
