import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_owned_story_detail_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/owned_story_detail.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_owned_story_detail_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.FG.1 — Owner publish path application composition tests.
///
/// Reuses existing Submit / Approve / Publish / Consent use cases.
/// Does not reimplement SB.13 or invent a second lifecycle.
void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryEventBus eventBus;

  late CreateHeroUseCase createHero;
  late CreateStoryUseCase createStory;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;
  late UpdateStoryConsentUseCase updateConsent;
  late GetOwnedStoryDetailUseCase getOwnedDetail;

  final english = LanguageCode('en');

  setUp(() {
    heroRepository = InMemoryHeroRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
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
    updateConsent = UpdateStoryConsentUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    getOwnedDetail = GetOwnedStoryDetailUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
  });

  Future<HeroId> seedHero() async {
    final heroId = HeroId.generate();
    final result = await createHero.execute(
      CreateHeroRequest(
        heroId: heroId,
        profile: HeroProfile(displayName: 'Owner Hero'),
      ),
    );
    expect(result, isA<Success<Hero>>());
    return heroId;
  }

  Future<StoryId> seedDraftStory(HeroId heroId) async {
    final storyId = StoryId.generate();
    final result = await createStory.execute(
      CreateStoryRequest(
        storyId: storyId,
        heroId: heroId,
        title: StoryTitle('Draft Path Story'),
        narrative: StoryNarrative('A materialized draft narrative.'),
        originalLanguage: english,
        visibility: StoryVisibility.draft,
      ),
    );
    expect(result, isA<Success<Story>>());
    final story = (result as Success<Story>).value;
    expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
    return storyId;
  }

  test('owner can submit an eligible draft', () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(storyId: storyId, grantProcessing: true),
    );

    final result = await submitStory.execute(StoryIdRequest(storyId: storyId));
    expect(result, isA<Success<Story>>());
    expect(
      (result as Success<Story>).value.lifecycleStatus,
      StoryLifecycleStatus.processing,
    );

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.processing);
  });

  test('submit without processing consent is rejected and preserves draft',
      () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    final result = await submitStory.execute(StoryIdRequest(storyId: storyId));
    expect(result, isA<Failure<Story>>());

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.draft);
  });

  test('invalid lifecycle transition is rejected', () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    final approveFromDraft =
        await approveStory.execute(StoryIdRequest(storyId: storyId));
    expect(approveFromDraft, isA<Failure<Story>>());

    final publishFromDraft = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(publishFromDraft, isA<Failure<Story>>());

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.draft);
  });

  test('non-owner cannot read owned story detail', () async {
    final ownerId = await seedHero();
    final otherId = await seedHero();
    final storyId = await seedDraftStory(ownerId);

    final result = await getOwnedDetail.execute(
      GetOwnedStoryDetailRequest(storyId: storyId, ownerHeroId: otherId),
    );
    expect(result, isA<Failure<OwnedStoryDetail>>());
  });

  test('approval respects existing authorization (owner self-approve allowed)',
      () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(storyId: storyId, grantProcessing: true),
    );
    await submitStory.execute(StoryIdRequest(storyId: storyId));

    final result = await approveStory.execute(StoryIdRequest(storyId: storyId));
    expect(result, isA<Success<Story>>());
    expect(
      (result as Success<Story>).value.lifecycleStatus,
      StoryLifecycleStatus.approved,
    );

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.approved);
  });

  test('approved story can be published with discoverable visibility',
      () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: true,
        grantPublication: true,
      ),
    );
    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final result = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(result, isA<Success<Story>>());
    final published = (result as Success<Story>).value;
    expect(published.lifecycleStatus, StoryLifecycleStatus.published);
    expect(published.visibility, StoryVisibility.public);

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.published);
    expect(reloaded.visibility, StoryVisibility.public);
  });

  test('successful transitions persist across reload', () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: true,
        grantPublication: true,
      ),
    );

    await submitStory.execute(StoryIdRequest(storyId: storyId));
    expect(
      (await storyRepository.findById(storyId))!.lifecycleStatus,
      StoryLifecycleStatus.processing,
    );

    await approveStory.execute(StoryIdRequest(storyId: storyId));
    expect(
      (await storyRepository.findById(storyId))!.lifecycleStatus,
      StoryLifecycleStatus.approved,
    );

    await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.community,
      ),
    );
    expect(
      (await storyRepository.findById(storyId))!.lifecycleStatus,
      StoryLifecycleStatus.published,
    );
    expect(
      (await storyRepository.findById(storyId))!.visibility,
      StoryVisibility.community,
    );
  });

  test('failed publish preserves approved story', () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: true,
        // publication consent intentionally omitted
      ),
    );
    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final result = await publishStory.execute(
      PublishStoryRequest(
        storyId: storyId,
        visibility: StoryVisibility.public,
      ),
    );
    expect(result, isA<Failure<Story>>());

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.approved);
    expect(reloaded.visibility, StoryVisibility.draft);
  });

  test('publish without discoverable visibility is rejected', () async {
    final heroId = await seedHero();
    final storyId = await seedDraftStory(heroId);

    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: storyId,
        grantProcessing: true,
        grantPublication: true,
      ),
    );
    await submitStory.execute(StoryIdRequest(storyId: storyId));
    await approveStory.execute(StoryIdRequest(storyId: storyId));

    final result = await publishStory.execute(
      PublishStoryRequest(storyId: storyId),
    );
    expect(result, isA<Failure<Story>>());

    final reloaded = await storyRepository.findById(storyId);
    expect(reloaded!.lifecycleStatus, StoryLifecycleStatus.approved);
  });
}
