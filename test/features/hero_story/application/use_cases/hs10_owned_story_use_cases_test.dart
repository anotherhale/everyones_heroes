import 'dart:typed_data';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/complete_story_capture_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_story_experience_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_owned_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryMediaStorageAdapter mediaStorage;
  late InMemoryEventBus eventBus;
  late CreateHeroUseCase createHero;
  late CompleteStoryCaptureUseCase completeCapture;
  late ListHeroOwnedStoriesUseCase listOwned;
  late GetOwnedStoryDetailUseCase getOwnedDetail;
  late LoadOwnedStoryMediaUseCase loadOwnedMedia;
  late ArchiveStoryUseCase archiveStory;
  late GetStoryExperienceUseCase getExperience;
  late LoadStoryMediaUseCase loadDiscoverableMedia;
  late DiscoverStoriesUseCase discoverStories;

  final english = LanguageCode('en');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    mediaStorage = InMemoryStoryMediaStorageAdapter();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    createHero = CreateHeroUseCase(
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    completeCapture = CompleteStoryCaptureUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: mediaStorage,
      eventBus: eventBus,
    );
    listOwned = ListHeroOwnedStoriesUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
    getOwnedDetail = GetOwnedStoryDetailUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
    loadOwnedMedia = LoadOwnedStoryMediaUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: mediaStorage,
    );
    archiveStory = ArchiveStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    getExperience = GetStoryExperienceUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
    loadDiscoverableMedia = LoadStoryMediaUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      mediaStorage: mediaStorage,
    );
    discoverStories = DiscoverStoriesUseCase(
      storySearchPort: InMemoryStorySearchAdapter(storyRepository),
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
  });

  Future<HeroId> seedHero({String name = 'Owner'}) async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: name),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  Future<({StoryId storyId, StoryRepresentationId representationId})>
  capturePrivateDraft({
    required HeroId heroId,
    String? title,
    Duration duration = const Duration(seconds: 8),
    DateTime? at,
  }) async {
    final storyId = StoryId.generate();
    final representationId = StoryRepresentationId.generate();
    final result = await completeCapture.execute(
      CompleteStoryCaptureRequest(
        sessionId: 'session-${storyId.value}',
        heroId: heroId,
        storyId: storyId,
        representationId: representationId,
        originalLanguage: english,
        mediaBytes: Uint8List.fromList(List<int>.filled(64, 7)),
        contentType: 'audio/wav',
        duration: duration,
        title: title == null ? null : StoryTitle(title),
        occurredAt: at,
      ),
    );
    expect(result, isA<Success>());
    final response = (result as Success).value;
    return (
      storyId: response.storyId as StoryId,
      representationId: response.representationId as StoryRepresentationId,
    );
  }

  group('ListHeroOwnedStoriesUseCase', () {
    test('returns current owner private draft', () async {
      final heroId = await seedHero();
      final captured = await capturePrivateDraft(heroId: heroId);

      final result = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: heroId),
      );
      expect(result, isA<Success<List<OwnedStorySummary>>>());
      final stories = (result as Success<List<OwnedStorySummary>>).value;
      expect(stories, hasLength(1));
      expect(stories.first.storyId, captured.storyId);
      expect(stories.first.visibility, StoryVisibility.private);
      expect(stories.first.lifecycleStatus, StoryLifecycleStatus.draft);
      expect(stories.first.isRecorded, isTrue);
      expect(stories.first.hasMedia, isTrue);
    });

    test('returns multiple owner stories newest-updated first', () async {
      final heroId = await seedHero();
      final older = await capturePrivateDraft(
        heroId: heroId,
        title: 'Older',
        at: DateTime.utc(2026, 9, 1),
      );
      final newer = await capturePrivateDraft(
        heroId: heroId,
        title: 'Newer',
        at: DateTime.utc(2026, 9, 15),
      );

      final result = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: heroId),
      );
      final stories = (result as Success<List<OwnedStorySummary>>).value;
      expect(stories.map((s) => s.storyId), [newer.storyId, older.storyId]);
    });

    test('excludes another owner story', () async {
      final owner = await seedHero(name: 'Owner');
      final other = await seedHero(name: 'Other');
      await capturePrivateDraft(heroId: owner, title: 'Mine');
      await capturePrivateDraft(heroId: other, title: 'Theirs');

      final result = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: owner),
      );
      final stories = (result as Success<List<OwnedStorySummary>>).value;
      expect(stories, hasLength(1));
      expect(stories.first.title, 'Mine');
    });

    test('returns empty list when owner has no stories', () async {
      final heroId = await seedHero();
      final result = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: heroId),
      );
      expect((result as Success<List<OwnedStorySummary>>).value, isEmpty);
    });

    test('excludes archived stories by default', () async {
      final heroId = await seedHero();
      final captured = await capturePrivateDraft(heroId: heroId);
      final archived = await archiveStory.execute(
        StoryIdRequest(storyId: captured.storyId),
      );
      expect(archived, isA<Success<Story>>());
      expect(
        (archived as Success<Story>).value.lifecycleStatus,
        StoryLifecycleStatus.archived,
      );

      final active = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: heroId),
      );
      expect((active as Success<List<OwnedStorySummary>>).value, isEmpty);

      final withArchived = await listOwned.execute(
        ListHeroOwnedStoriesRequest(heroId: heroId, includeArchived: true),
      );
      expect(
        (withArchived as Success<List<OwnedStorySummary>>).value,
        hasLength(1),
      );
    });
  });

  group('GetOwnedStoryDetailUseCase / LoadOwnedStoryMediaUseCase', () {
    test('owner can load private draft detail and media', () async {
      final heroId = await seedHero();
      final captured = await capturePrivateDraft(heroId: heroId);

      final detailResult = await getOwnedDetail.execute(
        GetOwnedStoryDetailRequest(
          storyId: captured.storyId,
          ownerHeroId: heroId,
        ),
      );
      expect(detailResult, isA<Success<OwnedStoryDetail>>());
      final detail = (detailResult as Success<OwnedStoryDetail>).value;
      expect(detail.lifecycleStatus, StoryLifecycleStatus.draft);
      expect(detail.visibility, StoryVisibility.private);
      expect(detail.primaryOriginalAudioId, captured.representationId);

      final mediaResult = await loadOwnedMedia.execute(
        LoadOwnedStoryMediaRequest(
          storyId: captured.storyId,
          representationId: captured.representationId,
          ownerHeroId: heroId,
        ),
      );
      expect(mediaResult, isA<Success<StoryMediaBytes>>());
      expect(
        (mediaResult as Success<StoryMediaBytes>).value.bytes,
        isNotEmpty,
      );
    });

    test('non-owner cannot load detail or media', () async {
      final owner = await seedHero(name: 'Owner');
      final other = await seedHero(name: 'Other');
      final captured = await capturePrivateDraft(heroId: owner);

      final detail = await getOwnedDetail.execute(
        GetOwnedStoryDetailRequest(
          storyId: captured.storyId,
          ownerHeroId: other,
        ),
      );
      expect(detail, isA<Failure<OwnedStoryDetail>>());
      expect((detail as Failure).error, contains('not owned'));

      final media = await loadOwnedMedia.execute(
        LoadOwnedStoryMediaRequest(
          storyId: captured.storyId,
          representationId: captured.representationId,
          ownerHeroId: other,
        ),
      );
      expect(media, isA<Failure<StoryMediaBytes>>());
    });

    test('private draft remains undiscoverable and seeker media fails', () async {
      final heroId = await seedHero();
      final captured = await capturePrivateDraft(heroId: heroId);

      final experience = await getExperience.execute(
        GetStoryExperienceRequest(storyId: captured.storyId),
      );
      expect(experience, isA<Failure>());
      expect((experience as Failure).error, contains('not discoverable'));

      final seekerMedia = await loadDiscoverableMedia.execute(
        LoadStoryMediaRequest(
          storyId: captured.storyId,
          representationId: captured.representationId,
        ),
      );
      expect(seekerMedia, isA<Failure>());
      expect((seekerMedia as Failure).error, contains('not discoverable'));

      final discovered = await discoverStories.execute(
        const DiscoverStoriesRequest(),
      );
      expect(discovered, isA<Success>());
      expect((discovered as Success).value.items, isEmpty);
    });
  });

  group('ArchiveStoryUseCase for drafts', () {
    test('draft can archive and media remains retrievable', () async {
      final heroId = await seedHero();
      final captured = await capturePrivateDraft(heroId: heroId);

      final archived = await archiveStory.execute(
        StoryIdRequest(storyId: captured.storyId),
      );
      expect(archived, isA<Success<Story>>());
      expect(
        (archived as Success<Story>).value.lifecycleStatus,
        StoryLifecycleStatus.archived,
      );

      final media = await loadOwnedMedia.execute(
        LoadOwnedStoryMediaRequest(
          storyId: captured.storyId,
          representationId: captured.representationId,
          ownerHeroId: heroId,
        ),
      );
      expect(media, isA<Success<StoryMediaBytes>>());
    });
  });
}
