import 'dart:io';

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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_owned_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/archive_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/complete_story_capture_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/list_hero_owned_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/load_owned_story_media_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/capture/file_capture_completion_store.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/media/local_file_story_media_storage_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('hs10-owner-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test(
    'HS.10: capture → owner list → detail → media → restart → archive',
    () async {
      final eventBus = InMemoryEventBus(
        eventStore: InMemoryEventStore(),
        dispatcher: InMemoryEventDispatcher(),
      );

      final heroes1 = FileHeroRepository(rootDirectory: root);
      final stories1 = FileStoryRepository(rootDirectory: root);
      final media1 = LocalFileStoryMediaStorageAdapter(rootDirectory: root);
      final completion1 = FileCaptureCompletionStore(
        rootDirectory: root,
        storyRepository: stories1,
      );

      final createHero = CreateHeroUseCase(
        heroRepository: heroes1,
        eventBus: eventBus,
      );
      final heroId = HeroId.generate();
      final created = await createHero.execute(
        CreateHeroRequest(
          heroId: heroId,
          profile: HeroProfile(displayName: 'HS10 Hero'),
        ),
      );
      expect(created, isA<Success<Hero>>());

      final tempAudio = File('${root.path}/temp-recording.m4a');
      await tempAudio.writeAsBytes(List<int>.filled(128, 9));

      final storyId = StoryId.generate();
      final representationId = StoryRepresentationId.generate();
      final capture = await CompleteStoryCaptureUseCase(
        storyRepository: stories1,
        heroRepository: heroes1,
        mediaStorage: media1,
        eventBus: eventBus,
        completionStore: completion1,
      ).execute(
        CompleteStoryCaptureRequest(
          sessionId: 'hs10-${storyId.value}',
          heroId: heroId,
          storyId: storyId,
          representationId: representationId,
          originalLanguage: LanguageCode('en'),
          mediaFilePath: tempAudio.path,
          contentType: 'audio/mp4',
          duration: const Duration(seconds: 12),
          title: StoryTitle('Durable Owner Story'),
        ),
      );
      expect(capture, isA<Success>());

      // Process restart with fresh repositories on same root.
      final heroes2 = FileHeroRepository(rootDirectory: root);
      final stories2 = FileStoryRepository(rootDirectory: root);
      final media2 = LocalFileStoryMediaStorageAdapter(rootDirectory: root);

      final owned = await ListHeroOwnedStoriesUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
      ).execute(ListHeroOwnedStoriesRequest(heroId: heroId));
      expect(owned, isA<Success<List<OwnedStorySummary>>>());
      final summaries = (owned as Success<List<OwnedStorySummary>>).value;
      expect(summaries, hasLength(1));
      expect(summaries.first.storyId, storyId);
      expect(summaries.first.visibility, StoryVisibility.private);
      expect(summaries.first.lifecycleStatus, StoryLifecycleStatus.draft);

      final detail = await GetOwnedStoryDetailUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
      ).execute(
        GetOwnedStoryDetailRequest(storyId: storyId, ownerHeroId: heroId),
      );
      expect(detail, isA<Success<OwnedStoryDetail>>());
      expect(
        (detail as Success<OwnedStoryDetail>).value.primaryOriginalAudioId,
        representationId,
      );

      final mediaBytes = await LoadOwnedStoryMediaUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
        mediaStorage: media2,
      ).execute(
        LoadOwnedStoryMediaRequest(
          storyId: storyId,
          representationId: representationId,
          ownerHeroId: heroId,
        ),
      );
      expect(mediaBytes, isA<Success<StoryMediaBytes>>());
      expect(
        (mediaBytes as Success<StoryMediaBytes>).value.bytes,
        isNotEmpty,
      );

      final discovered = await DiscoverStoriesUseCase(
        storySearchPort: InMemoryStorySearchAdapter(stories2),
        storyRepository: stories2,
        heroRepository: heroes2,
      ).execute(const DiscoverStoriesRequest());
      expect(discovered, isA<Success>());
      expect((discovered as Success).value.items, isEmpty);

      final archived = await ArchiveStoryUseCase(
        storyRepository: stories2,
        eventBus: eventBus,
      ).execute(StoryIdRequest(storyId: storyId));
      expect(archived, isA<Success<Story>>());
      expect(
        (archived as Success<Story>).value.lifecycleStatus,
        StoryLifecycleStatus.archived,
      );

      final afterArchive = await ListHeroOwnedStoriesUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
      ).execute(ListHeroOwnedStoriesRequest(heroId: heroId));
      expect(
        (afterArchive as Success<List<OwnedStorySummary>>).value,
        isEmpty,
      );

      // Media remains after archive (non-destructive).
      final mediaAfterArchive = await LoadOwnedStoryMediaUseCase(
        storyRepository: stories2,
        heroRepository: heroes2,
        mediaStorage: media2,
      ).execute(
        LoadOwnedStoryMediaRequest(
          storyId: storyId,
          representationId: representationId,
          ownerHeroId: heroId,
        ),
      );
      expect(mediaAfterArchive, isA<Success<StoryMediaBytes>>());
      expect(mediaAfterArchive is Failure, isFalse);
    },
  );
}
