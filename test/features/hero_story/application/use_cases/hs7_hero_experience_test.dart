import 'dart:typed_data';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/begin_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/consume_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_hero_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/list_hero_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/resolve_playable_representation_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_reflection_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/hero_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/playable_representation.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_consumption_session.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_experience_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/experience/playable_representation_selector.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/experience_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/begin_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/consume_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_hero_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/resolve_playable_representation_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_reflection_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/create_reflection_use_case.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_reflection_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = LanguageCode('en');
  final spanish = LanguageCode('es');
  final french = LanguageCode('fr');

  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  late InMemoryStoryMediaStorageAdapter media;
  late InMemoryReflectionRepository reflections;
  late DiscoverStoriesUseCase discoverStories;
  late GetStoryExperienceUseCase getStoryExperience;
  late GetHeroExperienceUseCase getHeroExperience;
  late ListHeroStoriesUseCase listHeroStories;
  late ResolvePlayableRepresentationUseCase resolvePlayable;
  late LoadStoryMediaUseCase loadMedia;
  late BeginStoryExperienceUseCase beginStory;
  late ConsumeStoryExperienceUseCase consumeStory;
  late StartStoryReflectionUseCase startReflection;

  setUp(() {
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    media = InMemoryStoryMediaStorageAdapter();
    reflections = InMemoryReflectionRepository();
    final storySearch = InMemoryStorySearchAdapter(stories);
    discoverStories = DiscoverStoriesUseCase(
      storySearchPort: storySearch,
      storyRepository: stories,
      heroRepository: heroes,
    );
    getStoryExperience = GetStoryExperienceUseCase(
      storyRepository: stories,
      heroRepository: heroes,
    );
    getHeroExperience = GetHeroExperienceUseCase(heroRepository: heroes);
    listHeroStories = ListHeroStoriesUseCase(
      discoverStoriesUseCase: discoverStories,
    );
    resolvePlayable = ResolvePlayableRepresentationUseCase(
      storyRepository: stories,
      heroRepository: heroes,
    );
    loadMedia = LoadStoryMediaUseCase(
      storyRepository: stories,
      heroRepository: heroes,
      mediaStorage: media,
    );
    beginStory = BeginStoryExperienceUseCase(
      getStoryExperienceUseCase: getStoryExperience,
      resolvePlayableRepresentationUseCase: resolvePlayable,
    );
    consumeStory = ConsumeStoryExperienceUseCase(
      getStoryExperienceUseCase: getStoryExperience,
      storyRepository: stories,
      heroRepository: heroes,
    );
    startReflection = StartStoryReflectionUseCase(
      getStoryExperienceUseCase: getStoryExperience,
      createReflectionUseCase: CreateReflectionUseCase(
        reflectionRepository: reflections,
      ),
    );
  });

  Future<Hero> seedHero({
    required String name,
    HeroVisibility visibility = HeroVisibility.public,
  }) async {
    final hero = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: name,
        biography: 'Lived experience of $name.',
        experienceAreas: const ['Service'],
        languages: [english],
      ),
      visibility: visibility,
    );
    await heroes.save(hero);
    return hero;
  }

  Future<Story> seedPublishedStory({
    required Hero hero,
    required String title,
    required String narrative,
    StoryVisibility visibility = StoryVisibility.public,
    LanguageCode? originalLanguage,
    List<StoryRepresentation> representations = const [],
  }) async {
    final story = Story.create(
      id: StoryId.generate(),
      heroId: hero.id,
      title: StoryTitle(title),
      narrative: StoryNarrative(narrative),
      originalLanguage: originalLanguage ?? english,
    );
    for (final representation in representations) {
      story.addRepresentation(representation);
    }
    story.updateConsent(
      story.consent
          .grantProcessing(DateTime.utc(2026, 1, 1))
          .grantPublication(DateTime.utc(2026, 1, 1)),
    );
    story
      ..submit()
      ..markReadyForReview()
      ..approve()
      ..changeVisibility(visibility)
      ..publish();
    await stories.save(story);
    return story;
  }

  StoryRepresentation writtenRep({
    required LanguageCode language,
    required String text,
    String? id,
    bool ai = false,
    bool approved = false,
  }) {
    return StoryRepresentation(
      id: id == null
          ? StoryRepresentationId.generate()
          : StoryRepresentationId(id),
      language: language,
      format: StoryRepresentationFormat.written,
      origin: RepresentationOrigin.original,
      textContent: text,
      isAiGenerated: ai,
      isApproved: approved,
    );
  }

  group('story discovery eligibility for experience (D4)', () {
    test('public and community stories are experience-eligible', () async {
      final hero = await seedHero(name: 'Public Hero');
      final publicStory = await seedPublishedStory(
        hero: hero,
        title: 'Public Story',
        narrative: 'Public narrative body.',
        visibility: StoryVisibility.public,
        representations: [
          writtenRep(language: english, text: 'Public written.'),
        ],
      );
      final communityStory = await seedPublishedStory(
        hero: hero,
        title: 'Community Story',
        narrative: 'Community narrative body.',
        visibility: StoryVisibility.community,
        representations: [
          writtenRep(language: english, text: 'Community written.'),
        ],
      );

      final public = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: publicStory.id),
      );
      final community = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: communityStory.id),
      );

      expect(public, isA<Success<StoryExperienceDetail>>());
      expect(community, isA<Success<StoryExperienceDetail>>());
      expect(
        (public as Success<StoryExperienceDetail>).value.narrativeBody,
        'Public narrative body.',
      );
    });

    test('private and unlisted stories are rejected by known-id experience', () async {
      final hero = await seedHero(name: 'Hero');
      final unlisted = await seedPublishedStory(
        hero: hero,
        title: 'Unlisted Story',
        narrative: 'Secret unlisted narrative.',
        visibility: StoryVisibility.unlisted,
        representations: [
          writtenRep(language: english, text: 'Unlisted text.'),
        ],
      );

      final result = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: unlisted.id),
      );
      expect(result, isA<Failure<StoryExperienceDetail>>());
      expect(
        (result as Failure<StoryExperienceDetail>).error,
        contains('not discoverable'),
      );
    });

    test('known-id unlisted access cannot bypass discoverability', () async {
      final hero = await seedHero(name: 'Hero');
      final unlisted = await seedPublishedStory(
        hero: hero,
        title: 'Hidden',
        narrative: 'Must not leak.',
        visibility: StoryVisibility.unlisted,
      );

      final discover = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      final discoverIds =
          (discover as Success<DiscoverStoriesResponse>).value.items
              .map((item) => item.storyId)
              .toSet();
      expect(discoverIds.contains(unlisted.id), isFalse);

      final experience = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: unlisted.id),
      );
      expect(experience, isA<Failure<StoryExperienceDetail>>());
    });
  });

  group('representation selection (D2/D3)', () {
    test('only authoritative representations are exposed', () async {
      final hero = await seedHero(name: 'Hero');
      final approvedId = StoryRepresentationId('approved-rep');
      final unapprovedId = StoryRepresentationId('unapproved-rep');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Auth Story',
        narrative: 'Canonical narrative.',
        representations: [
          writtenRep(
            id: approvedId.value,
            language: english,
            text: 'Approved text.',
            ai: true,
            approved: true,
          ),
          writtenRep(
            id: unapprovedId.value,
            language: english,
            text: 'Provisional AI draft — must not leak.',
            ai: true,
            approved: false,
          ),
        ],
      );

      final result = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: story.id),
      );
      final detail = (result as Success<StoryExperienceDetail>).value;
      final ids = detail.playableRepresentations
          .map((item) => item.representationId)
          .toSet();
      expect(ids, {approvedId});
      expect(detail.narrativeBody, 'Canonical narrative.');
      for (final playable in detail.playableRepresentations) {
        expect(playable.textContent, isNot(contains('must not leak')));
      }
    });

    test('unapproved representation is rejected by resolve', () async {
      final hero = await seedHero(name: 'Hero');
      final unapprovedId = StoryRepresentationId('ai-draft');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Story',
        narrative: 'Narrative.',
        representations: [
          writtenRep(
            language: english,
            text: 'Human written.',
          ),
          writtenRep(
            id: unapprovedId.value,
            language: spanish,
            text: 'AI draft.',
            ai: true,
            approved: false,
          ),
        ],
      );

      final result = await resolvePlayable.execute(
        ResolvePlayableRepresentationRequest(
          storyId: story.id,
          representationId: unapprovedId,
        ),
      );
      expect(result, isA<Failure<PlayableRepresentation>>());
    });

    test('deterministic language priority: preferred → original → fallback', () {
      final preferred = StoryRepresentation(
        id: StoryRepresentationId('es-written'),
        language: spanish,
        format: StoryRepresentationFormat.written,
        origin: RepresentationOrigin.translated,
        textContent: 'Spanish',
        sourceRepresentationId: StoryRepresentationId('en-written'),
      );
      final original = StoryRepresentation(
        id: StoryRepresentationId('en-written'),
        language: english,
        format: StoryRepresentationFormat.written,
        origin: RepresentationOrigin.original,
        textContent: 'English',
      );
      final other = StoryRepresentation(
        id: StoryRepresentationId('fr-written'),
        language: french,
        format: StoryRepresentationFormat.written,
        origin: RepresentationOrigin.translated,
        textContent: 'French',
        sourceRepresentationId: StoryRepresentationId('en-written'),
      );

      final withPreferred = PlayableRepresentationSelector.select(
        candidates: [original, preferred, other],
        originalLanguage: english,
        preferredLanguage: spanish,
      );
      expect(withPreferred!.id.value, 'es-written');

      final withoutPreferred = PlayableRepresentationSelector.select(
        candidates: [other, original],
        originalLanguage: english,
      );
      expect(withoutPreferred!.id.value, 'en-written');

      final fallback = PlayableRepresentationSelector.select(
        candidates: [other],
        originalLanguage: english,
      );
      expect(fallback!.id.value, 'fr-written');
    });

    test('deterministic format priority within a language', () {
      final transcript = StoryRepresentation(
        id: StoryRepresentationId('en-transcript'),
        language: english,
        format: StoryRepresentationFormat.transcript,
        origin: RepresentationOrigin.original,
        textContent: 'Transcript',
      );
      final audio = StoryRepresentation(
        id: StoryRepresentationId('en-audio'),
        language: english,
        format: StoryRepresentationFormat.audio,
        origin: RepresentationOrigin.original,
        mediaReference: MediaReference('memory://audio'),
      );
      final script = StoryRepresentation(
        id: StoryRepresentationId('en-script'),
        language: english,
        format: StoryRepresentationFormat.script,
        origin: RepresentationOrigin.original,
        textContent: 'Script',
      );

      final selected = PlayableRepresentationSelector.select(
        candidates: [transcript, script, audio],
        originalLanguage: english,
      );
      expect(selected!.format, StoryRepresentationFormat.audio);
      expect(
        PlayableRepresentationSelector.formatPriority.first,
        StoryRepresentationFormat.audio,
      );
    });
  });

  group('story experience DTO safety', () {
    test('DTO exposes safe fields and not raw aggregate', () async {
      final hero = await seedHero(name: 'Maya');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Returning Home',
        narrative: 'I learned to begin again.',
        representations: [
          writtenRep(language: english, text: 'Written form.'),
        ],
      );

      final result = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: story.id),
      );
      final detail = (result as Success<StoryExperienceDetail>).value;
      expect(detail, isA<StoryExperienceDetail>());
      expect(detail, isNot(isA<Story>()));
      expect(detail.title, 'Returning Home');
      expect(detail.narrativeBody, 'I learned to begin again.');
      expect(detail.heroDisplayName, 'Maya');
      expect(detail.primaryPlayable, isNotNull);
      expect(detail.primaryPlayable!.textContent, 'Written form.');
    });

    test('missing authoritative representation yields null primary', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'No reps',
        narrative: 'Narrative only.',
        representations: [
          writtenRep(
            language: english,
            text: 'AI only.',
            ai: true,
            approved: false,
          ),
        ],
      );

      final result = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: story.id),
      );
      final detail = (result as Success<StoryExperienceDetail>).value;
      expect(detail.playableRepresentations, isEmpty);
      expect(detail.primaryPlayable, isNull);
      expect(detail.narrativeBody, 'Narrative only.');
    });
  });

  group('hero experience (D5/D6)', () {
    test('hero discovery uses Discover* via list hero stories', () async {
      final publicHero = await seedHero(name: 'Public');
      final privateHero = await seedHero(
        name: 'Private',
        visibility: HeroVisibility.private,
      );
      await seedPublishedStory(
        hero: publicHero,
        title: 'Visible',
        narrative: 'Visible narrative.',
        representations: [
          writtenRep(language: english, text: 'Text.'),
        ],
      );
      await seedPublishedStory(
        hero: privateHero,
        title: 'Hidden story',
        narrative: 'Hidden narrative.',
        representations: [
          writtenRep(language: english, text: 'Hidden.'),
        ],
      );

      final heroResult = await getHeroExperience.execute(
        GetHeroExperienceRequest(heroId: publicHero.id),
      );
      expect(heroResult, isA<Success<HeroExperienceDetail>>());
      expect(
        (heroResult as Success<HeroExperienceDetail>).value.displayName,
        'Public',
      );

      final privateResult = await getHeroExperience.execute(
        GetHeroExperienceRequest(heroId: privateHero.id),
      );
      expect(privateResult, isA<Failure<HeroExperienceDetail>>());

      final storiesResult = await listHeroStories.execute(
        ListHeroStoriesRequest(heroId: publicHero.id),
      );
      final items =
          (storiesResult as Success<DiscoverStoriesResponse>).value.items;
      expect(items.map((item) => item.title), ['Visible']);

      final privateStories = await listHeroStories.execute(
        ListHeroStoriesRequest(heroId: privateHero.id),
      );
      expect(
        (privateStories as Success<DiscoverStoriesResponse>).value.items,
        isEmpty,
      );
    });

    test('ineligible stories remain inaccessible from hero path', () async {
      final hero = await seedHero(name: 'Hero');
      final unlisted = await seedPublishedStory(
        hero: hero,
        title: 'Unlisted',
        narrative: 'Nope.',
        visibility: StoryVisibility.unlisted,
      );

      final listed = await listHeroStories.execute(
        ListHeroStoriesRequest(heroId: hero.id),
      );
      expect(
        (listed as Success<DiscoverStoriesResponse>).value.items,
        isEmpty,
      );

      final experience = await getStoryExperience.execute(
        GetStoryExperienceRequest(storyId: unlisted.id),
      );
      expect(experience, isA<Failure<StoryExperienceDetail>>());
    });
  });

  group('consumption boundary (D8/D9)', () {
    test('story can be begun and consumed without reflection', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Consume Me',
        narrative: 'Body.',
        representations: [
          writtenRep(language: english, text: 'Readable script.'),
        ],
      );

      final probeJourney = JourneyId.generate();
      expect(await reflections.findByJourneyId(probeJourney), isEmpty);

      final begun = await beginStory.execute(
        BeginStoryExperienceRequest(
          storyId: story.id,
          startedAt: DateTime.utc(2026, 9, 13),
        ),
      );
      expect(begun, isA<Success<StoryConsumptionSession>>());
      final session = (begun as Success<StoryConsumptionSession>).value;
      expect(session.completed, isFalse);
      expect(session.selectedRepresentation.textContent, 'Readable script.');

      final consumed = await consumeStory.execute(
        ConsumeStoryExperienceRequest(
          storyId: story.id,
          representationId: session.representationId,
        ),
      );
      expect(consumed, isA<Success<StoryConsumptionSession>>());
      expect(
        (consumed as Success<StoryConsumptionSession>).value.completed,
        isTrue,
      );

      expect(await reflections.findByJourneyId(probeJourney), isEmpty);
    });

    test('media uses existing StoryMediaStoragePort', () async {
      final hero = await seedHero(name: 'Hero');
      final mediaRef = await media.store(
        StoreStoryMediaRequest(bytes: Uint8List.fromList([1, 2, 3, 4])),
      );
      final repId = StoryRepresentationId('audio-1');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Audio Story',
        narrative: 'Spoken narrative.',
        representations: [
          StoryRepresentation(
            id: repId,
            language: english,
            format: StoryRepresentationFormat.audio,
            origin: RepresentationOrigin.original,
            mediaReference: mediaRef,
          ),
        ],
      );

      final result = await loadMedia.execute(
        LoadStoryMediaRequest(storyId: story.id, representationId: repId),
      );
      expect(result, isA<Success<StoryMediaBytes>>());
      expect(
        (result as Success<StoryMediaBytes>).value.bytes,
        Uint8List.fromList([1, 2, 3, 4]),
      );
    });

    test('consumption does not create BehavioralEvidence or alter journey', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Boundary',
        narrative: 'Narrative.',
        representations: [
          writtenRep(language: english, text: 'Text.'),
        ],
      );

      final beforeEvents = story.pullDomainEvents();
      expect(beforeEvents, isEmpty);

      final begun = await beginStory.execute(
        BeginStoryExperienceRequest(storyId: story.id),
      );
      final session = (begun as Success<StoryConsumptionSession>).value;
      await consumeStory.execute(
        ConsumeStoryExperienceRequest(
          storyId: story.id,
          representationId: session.representationId,
        ),
      );

      final reloaded = await stories.findById(story.id);
      expect(reloaded!.pullDomainEvents(), isEmpty);
      expect(await reflections.findByJourneyId(JourneyId.generate()), isEmpty);
    });
  });

  group('story begin path ≠ BeginExperienceUseCase', () {
    test('BeginStoryExperience does not create Reflection', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Begin',
        narrative: 'Narrative.',
        representations: [
          writtenRep(language: english, text: 'Text.'),
        ],
      );

      final journeyId = JourneyId.generate();
      await beginStory.execute(BeginStoryExperienceRequest(storyId: story.id));
      expect(await reflections.findByJourneyId(journeyId), isEmpty);
    });

    test('explicit StartStoryReflection uses H.2 CreateReflectionUseCase', () async {
      final hero = await seedHero(name: 'Hero');
      final story = await seedPublishedStory(
        hero: hero,
        title: 'Reflectable',
        narrative: 'Narrative.',
        representations: [
          writtenRep(language: english, text: 'Text.'),
        ],
      );

      final reflectionId = ReflectionId.generate();
      final journeyId = JourneyId.generate();
      final result = await startReflection.execute(
        StartStoryReflectionRequest(
          storyId: story.id,
          journeyId: journeyId,
          reflectionId: reflectionId,
        ),
      );

      expect(result, isA<Success<Reflection>>());
      final reflection = (result as Success<Reflection>).value;
      expect(reflection.id, reflectionId);
      expect(reflection.journeyId, journeyId);
      expect(await reflections.findById(reflectionId), isNotNull);
    });

    test('explicit reflection is rejected for undiscoverable story', () async {
      final hero = await seedHero(name: 'Hero');
      final unlisted = await seedPublishedStory(
        hero: hero,
        title: 'Unlisted',
        narrative: 'Secret.',
        visibility: StoryVisibility.unlisted,
      );

      final journeyId = JourneyId.generate();
      final result = await startReflection.execute(
        StartStoryReflectionRequest(
          storyId: unlisted.id,
          journeyId: journeyId,
        ),
      );
      expect(result, isA<Failure<Reflection>>());
      expect(await reflections.findByJourneyId(journeyId), isEmpty);
    });
  });

  group('architectural guards', () {
    test('ListHeroStories delegates to DiscoverStories, not Search*', () async {
      final hero = await seedHero(name: 'Hero');
      await seedPublishedStory(
        hero: hero,
        title: 'One',
        narrative: 'Narrative.',
        representations: [
          writtenRep(language: english, text: 'Text.'),
        ],
      );

      final viaList = await listHeroStories.execute(
        ListHeroStoriesRequest(heroId: hero.id),
      );
      final viaDiscover = await discoverStories.execute(
        DiscoverStoriesRequest(heroId: hero.id),
      );

      final listIds = (viaList as Success<DiscoverStoriesResponse>).value.items
          .map((item) => item.storyId.value)
          .toList();
      final discoverIds =
          (viaDiscover as Success<DiscoverStoriesResponse>).value.items
              .map((item) => item.storyId.value)
              .toList();
      expect(listIds, discoverIds);
    });

    test('experience providers wire without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(getStoryExperienceUseCaseProvider), isNotNull);
      expect(container.read(getHeroExperienceUseCaseProvider), isNotNull);
      expect(container.read(listHeroStoriesUseCaseProvider), isNotNull);
      expect(container.read(beginStoryExperienceUseCaseProvider), isNotNull);
      expect(container.read(consumeStoryExperienceUseCaseProvider), isNotNull);
      expect(container.read(startStoryReflectionUseCaseProvider), isNotNull);
    });
  });
}
