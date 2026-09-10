import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/add_story_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/add_story_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/search_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryEventStore eventStore;
  late InMemoryEventBus eventBus;

  late CreateHeroUseCase createHero;
  late CreateStoryUseCase createStory;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;
  late ArchiveStoryUseCase archiveStory;
  late AddStoryRepresentationUseCase addRepresentation;
  late ClassifyStoryUseCase classifyStory;
  late SearchStoriesUseCase searchStories;

  final english = LanguageCode('en');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    eventStore = InMemoryEventStore();
    eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: InMemoryEventDispatcher(),
    );

    createHero = CreateHeroUseCase(
      heroRepository: heroRepository,
      eventBus: eventBus,
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
    archiveStory = ArchiveStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    addRepresentation = AddStoryRepresentationUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    classifyStory = ClassifyStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    searchStories = SearchStoriesUseCase(
      storySearchPort: InMemoryStorySearchAdapter(storyRepository),
    );
  });

  Future<HeroId> seedHero() async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Alex Rivera'),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  Future<StoryId> seedStory(HeroId heroId) async {
    final storyId = StoryId.generate();
    final result = await createStory.execute(
      CreateStoryRequest(
        storyId: storyId,
        heroId: heroId,
        title: StoryTitle('Finding Purpose'),
        narrative: StoryNarrative('A story about rebuilding purpose.'),
        originalLanguage: english,
      ),
    );
    expect(result, isA<Success<Story>>());
    return storyId;
  }

  test('create hero publishes HeroCreated', () async {
    await seedHero();
    final events = await eventStore.allEvents();
    expect(events.any((e) => e.event is HeroCreated), isTrue);
  });

  test('create story requires existing hero', () async {
    final result = await createStory.execute(
      CreateStoryRequest(
        storyId: StoryId.generate(),
        heroId: HeroId.generate(),
        title: StoryTitle('Orphan'),
        narrative: StoryNarrative('Should fail without hero.'),
        originalLanguage: english,
      ),
    );
    expect(result.isFailure, isTrue);
  });

  test('full lifecycle create -> publish -> archive', () async {
    final heroId = await seedHero();
    final storyId = await seedStory(heroId);

    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final publishResult = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(publishResult, isA<Success<Story>>());

    final hero = await heroRepository.findById(heroId);
    expect(hero!.publishedStoryIds, contains(storyId));

    await archiveStory.execute(StoryIdRequest(storyId: storyId));
    final archived = await storyRepository.findById(storyId);
    expect(archived!.lifecycleStatus, StoryLifecycleStatus.archived);
    expect(
      (await heroRepository.findById(heroId))!.publishedStoryIds,
      isNot(contains(storyId)),
    );
  });

  test('classify and search by catalog dimensions', () async {
    final heroId = await seedHero();
    final storyId = await seedStory(heroId);
    final themeId = NarrativeThemeId.generate();

    await classifyStory.execute(
      ClassifyStoryRequest(
        storyId: storyId,
        classification: StoryClassification(
          subjects: const [StorySubject.career],
          challenges: const [StoryChallenge.change],
          narrativeThemeIds: [themeId],
        ),
      ),
    );

    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));
    await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.community,
      ),
    );

    final search = await searchStories.execute(
      StorySearchQuery(
        subjects: const [StorySubject.career],
        narrativeThemeIds: [themeId],
      ),
    );

    expect(search, isA<Success<List<StoryId>>>());
    search.fold(
      onSuccess: (ids) => expect(ids, contains(storyId)),
      onFailure: fail,
    );
  });

  test('add representation through use case', () async {
    final heroId = await seedHero();
    final storyId = await seedStory(heroId);
    final representationId = StoryRepresentationId.generate();

    final result = await addRepresentation.execute(
      AddStoryRepresentationRequest(
        storyId: storyId,
        representation: StoryRepresentation(
          id: representationId,
          language: english,
          format: StoryRepresentationFormat.written,
          origin: RepresentationOrigin.original,
          textContent: storyNarrativeText,
        ),
        transformationType: StoryTransformationType.editing,
      ),
    );

    expect(result, isA<Success<Story>>());
    final story = await storyRepository.findById(storyId);
    expect(story!.findRepresentation(representationId), isNotNull);
  });
}

const storyNarrativeText = 'Edited written narrative of the story.';
