import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.FG.3 — private Hero blocks Discovery; explicit discoverability unblocks.
void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryEventBus eventBus;

  late ChangeHeroVisibilityUseCase changeVisibility;
  late CreateStoryUseCase createStory;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;
  late UpdateStoryConsentUseCase updateConsent;
  late DiscoverStoriesUseCase discoverStories;

  late HeroId heroId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    // Default local owner: private (matches ensureActiveLocalHeroProvider).
    heroId = HeroId.generate();
    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Local Private Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );

    changeVisibility = ChangeHeroVisibilityUseCase(
      heroRepository: heroRepository,
    );
    createStory = CreateStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    submitStory = SubmitStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    approveStory = ApproveStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    publishStory = PublishStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    updateConsent = UpdateStoryConsentUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    discoverStories = DiscoverStoriesUseCase(
      storySearchPort: InMemoryStorySearchAdapter(storyRepository),
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
  });

  Future<bool> isDiscoverable(StoryId storyId) async {
    final result = await discoverStories.execute(
      const DiscoverStoriesRequest(limit: 50),
    );
    expect(result, isA<Success<DiscoverStoriesResponse>>());
    final response = (result as Success<DiscoverStoriesResponse>).value;
    return response.items.any((item) => item.storyId == storyId);
  }

  Future<Story> publishEligibleStory() async {
    final storyId = StoryId.generate();
    final created = await createStory.execute(
      CreateStoryRequest(
        storyId: storyId,
        heroId: heroId,
        title: StoryTitle('FG.3 Eligible Story'),
        narrative: StoryNarrative('A complete eligible narrative for discovery.'),
        originalLanguage: LanguageCode('en'),
        visibility: StoryVisibility.draft,
      ),
    );
    expect(created, isA<Success<Story>>());

    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: true,
        grantPublication: true,
      ),
    );
    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final published = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(published, isA<Success<Story>>());
    final story = (published as Success<Story>).value;
    expect(story.lifecycleStatus, StoryLifecycleStatus.published);
    expect(story.visibility, StoryVisibility.public);
    expect(StoryDiscoverabilityPolicy.isDiscoverable(story), isTrue);
    return story;
  }

  test(
    'private Hero + published eligible Story excluded; discoverable includes; '
    'private again excludes',
    () async {
      expect(
        (await heroRepository.findById(heroId))!.visibility,
        HeroVisibility.private,
      );

      final story = await publishEligibleStory();

      // Story eligibility alone is not enough while Hero is private.
      expect(await isDiscoverable(story.id), isFalse);
      expect(
        HeroDiscoverabilityPolicy.isDiscoverable(
          (await heroRepository.findById(heroId))!,
        ),
        isFalse,
      );

      final madeDiscoverable = await changeVisibility.execute(
        ChangeHeroVisibilityRequest(
          heroId: heroId,
          ownerHeroId: heroId,
          visibility: HeroVisibility.public,
        ),
      );
      expect(madeDiscoverable, isA<Success<Hero>>());
      expect(
        HeroDiscoverabilityPolicy.isDiscoverable(
          (await heroRepository.findById(heroId))!,
        ),
        isTrue,
      );
      expect(await isDiscoverable(story.id), isTrue);

      final madePrivate = await changeVisibility.execute(
        ChangeHeroVisibilityRequest(
          heroId: heroId,
          ownerHeroId: heroId,
          visibility: HeroVisibility.private,
        ),
      );
      expect(madePrivate, isA<Success<Hero>>());
      expect(await isDiscoverable(story.id), isFalse);
    },
  );

  test('publishing a Story does not change Hero visibility', () async {
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );

    await publishEligibleStory();

    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });
}
