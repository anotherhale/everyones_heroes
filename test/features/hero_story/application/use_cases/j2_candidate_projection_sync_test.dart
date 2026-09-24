import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/classify_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/story_candidate_eligibility_facts_payload.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_candidate_eligibility_facts_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/ports/sync_discoverable_story_candidate_port.dart';
import 'package:everyonesheroes/features/hero_story/application/services/discoverable_story_candidate_sync.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recording fake — captures sync payloads without HTTP.
final class _RecordingSyncPort implements SyncDiscoverableStoryCandidatePort {
  final List<StoryCandidateEligibilityFactsPayload> calls = [];
  Object? throwOnSync;
  bool wasUpserted = true;

  @override
  Future<SyncDiscoverableStoryCandidateResult> sync(
    StoryCandidateEligibilityFactsPayload facts,
  ) async {
    if (throwOnSync != null) {
      throw throwOnSync!;
    }
    calls.add(facts);
    return SyncDiscoverableStoryCandidateResult(
      storyId: facts.storyId,
      wasUpserted: wasUpserted,
      reason: wasUpserted ? null : 'ineligible',
    );
  }
}

void main() {
  final english = LanguageCode('en');
  const mapper = StoryCandidateEligibilityFactsMapper();

  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryEventBus eventBus;
  late _RecordingSyncPort syncPort;
  late DiscoverableStoryCandidateSync candidateSync;

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    syncPort = _RecordingSyncPort();
    candidateSync = DiscoverableStoryCandidateSync(port: syncPort);
  });

  Future<Hero> seedHero({
    HeroVisibility visibility = HeroVisibility.public,
  }) async {
    final hero = Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Owner',
        languages: [english],
      ),
      visibility: visibility,
    );
    await heroRepository.save(hero);
    return hero;
  }

  Future<Story> seedApprovedStory(Hero hero) async {
    final story = Story.create(
      id: StoryId.generate(),
      heroId: hero.id,
      title: StoryTitle('Finding Direction'),
      narrative: StoryNarrative('A lived experience about finding purpose.'),
      originalLanguage: english,
    );
    story.classify(
      StoryClassification(
        narrativeThemeIds: [
          NarrativeThemeId('discovery'),
          NarrativeThemeId('purpose'),
        ],
      ),
    );
    story.addRepresentation(
      StoryRepresentation(
        id: StoryRepresentationId.generate(),
        language: english,
        format: StoryRepresentationFormat.written,
        origin: RepresentationOrigin.original,
        textContent: 'Authored narrative body.',
        isAiGenerated: false,
      ),
    );
    story.updateConsent(
      story.consent
          .grantProcessing(DateTime.utc(2026, 1, 1))
          .grantPublication(DateTime.utc(2026, 1, 1)),
    );
    story
      ..submit()
      ..markReadyForReview()
      ..approve()
      ..changeVisibility(StoryVisibility.public);
    await storyRepository.save(story);
    return story;
  }

  group('StoryCandidateEligibilityFactsMapper', () {
    test('maps Story + Hero into projection facts', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      story.publish();

      final facts = mapper.fromStoryAndHero(story: story, hero: hero);
      expect(facts.storyId, story.id.value);
      expect(facts.heroId, hero.id.value);
      expect(facts.title, 'Finding Direction');
      expect(facts.themeIds, ['discovery', 'purpose']);
      expect(facts.lifecycleStatus, 'published');
      expect(facts.storyVisibility, 'public');
      expect(facts.hasProvisionalNarrative, isFalse);
      expect(facts.hasAuthoritativeRepresentation, isTrue);
      expect(facts.heroStatus, 'active');
      expect(facts.heroVisibility, 'public');
    });
  });

  group('PublishStoryUseCase candidate projection sync', () {
    test('publish invokes sync with published eligibility facts', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      final publish = PublishStoryUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        eventBus: eventBus,
        candidateSync: candidateSync,
      );

      final result = await publish.execute(
        PublishStoryRequest(storyId: story.id),
      );
      expect(result, isA<Success<Story>>());
      expect(syncPort.calls, hasLength(1));
      expect(syncPort.calls.single.lifecycleStatus, 'published');
      expect(syncPort.calls.single.storyId, story.id.value);
      expect(
        (result as Success<Story>).value.lifecycleStatus,
        StoryLifecycleStatus.published,
      );
    });

    test('publish succeeds when sync fails (soft-fail)', () async {
      syncPort.throwOnSync = StateError('platform unreachable');
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      final publish = PublishStoryUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        eventBus: eventBus,
        candidateSync: candidateSync,
      );

      final result = await publish.execute(
        PublishStoryRequest(storyId: story.id),
      );
      expect(result, isA<Success<Story>>());
      final reloaded = await storyRepository.findById(story.id);
      expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.published);
    });

    test('publish without candidateSync does not require platform', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      final publish = PublishStoryUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        eventBus: eventBus,
      );

      final result = await publish.execute(
        PublishStoryRequest(storyId: story.id),
      );
      expect(result, isA<Success<Story>>());
      expect(syncPort.calls, isEmpty);
    });
  });

  group('ArchiveStoryUseCase candidate projection sync', () {
    test('archive invokes sync with archived lifecycle', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      story.publish();
      await storyRepository.save(story);

      final archive = ArchiveStoryUseCase(
        storyRepository: storyRepository,
        eventBus: eventBus,
        heroRepository: heroRepository,
        candidateSync: candidateSync,
      );

      final result = await archive.execute(StoryIdRequest(storyId: story.id));
      expect(result, isA<Success<Story>>());
      expect(syncPort.calls, hasLength(1));
      expect(syncPort.calls.single.lifecycleStatus, 'archived');
    });
  });

  group('ChangeHeroVisibilityUseCase candidate projection sync', () {
    test('syncs published owned stories when hero visibility changes', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      story.publish();
      await storyRepository.save(story);

      final change = ChangeHeroVisibilityUseCase(
        heroRepository: heroRepository,
        storyRepository: storyRepository,
        candidateSync: candidateSync,
      );

      final result = await change.execute(
        ChangeHeroVisibilityRequest(
          ownerHeroId: hero.id,
          heroId: hero.id,
          visibility: HeroVisibility.private,
        ),
      );
      expect(result, isA<Success<Hero>>());
      expect(syncPort.calls, hasLength(1));
      expect(syncPort.calls.single.heroVisibility, 'private');
      expect(syncPort.calls.single.lifecycleStatus, 'published');
    });
  });

  group('ClassifyStoryUseCase candidate projection sync', () {
    test('syncs when classifying an already published story', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);
      story.publish();
      await storyRepository.save(story);

      final classify = ClassifyStoryUseCase(
        storyRepository: storyRepository,
        eventBus: eventBus,
        heroRepository: heroRepository,
        candidateSync: candidateSync,
      );

      final result = await classify.execute(
        ClassifyStoryRequest(
          storyId: story.id,
          classification: StoryClassification(
            narrativeThemeIds: [NarrativeThemeId('courage')],
          ),
        ),
      );
      expect(result, isA<Success<Story>>());
      expect(syncPort.calls, hasLength(1));
      expect(syncPort.calls.single.themeIds, ['courage']);
    });

    test('does not sync when classifying unpublished story', () async {
      final hero = await seedHero();
      final story = await seedApprovedStory(hero);

      final classify = ClassifyStoryUseCase(
        storyRepository: storyRepository,
        eventBus: eventBus,
        heroRepository: heroRepository,
        candidateSync: candidateSync,
      );

      await classify.execute(
        ClassifyStoryRequest(
          storyId: story.id,
          classification: StoryClassification(
            narrativeThemeIds: [NarrativeThemeId('courage')],
          ),
        ),
      );
      expect(syncPort.calls, isEmpty);
    });
  });
}
