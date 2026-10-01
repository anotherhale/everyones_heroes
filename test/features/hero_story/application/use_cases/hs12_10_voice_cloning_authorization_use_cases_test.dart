import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_story_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/deny_story_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/revoke_story_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/revoke_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_voice_cloning_authorization_scope_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_story_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_voice_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/deny_story_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/revoke_story_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/revoke_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_voice_cloning_authorization_scope_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_voice_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryVoiceProfileRepository voiceProfileRepository;
  late InMemoryStoryRepository storyRepository;
  late EventBus eventBus;
  late HeroId heroId;
  late VoiceProfileId voiceProfileId;
  late StoryId storyId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    voiceProfileRepository = InMemoryVoiceProfileRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    heroId = HeroId.generate();
    voiceProfileId = VoiceProfileId.generate();
    storyId = StoryId.generate();

    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Test Hero',
          biography: 'A test hero',
        ),
      ),
    );

    await storyRepository.save(
      Story.create(
        id: storyId,
        heroId: heroId,
        title: StoryTitle('Cloning Scope Story'),
        narrative: StoryNarrative('Narrative body.'),
        originalLanguage: LanguageCode('en'),
      ),
    );
  });

  Future<void> createProfile() async {
    final result = await CreateVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    ).execute(
      CreateVoiceProfileRequest(
        ownerHeroId: heroId,
        voiceProfileId: voiceProfileId,
        language: LanguageCode('en'),
      ),
    );
    expect(result, isA<Success>());
  }

  test('create defaults cloningAuthorizationScope to perStory', () async {
    await createProfile();
    final profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(
      profile!.cloningAuthorizationScope,
      VoiceCloningAuthorizationScope.perStory,
    );
  });

  test('SetVoiceCloningAuthorizationScope switches to perProfile', () async {
    await createProfile();

    final result = await SetVoiceCloningAuthorizationScopeUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      SetVoiceCloningAuthorizationScopeRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
        scope: VoiceCloningAuthorizationScope.perProfile,
      ),
    );

    expect(result, isA<Success>());
    final profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(
      profile!.cloningAuthorizationScope,
      VoiceCloningAuthorizationScope.perProfile,
    );
  });

  test('scope change rejects non-owner', () async {
    await createProfile();

    final result = await SetVoiceCloningAuthorizationScopeUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      SetVoiceCloningAuthorizationScopeRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: HeroId.generate(),
        scope: VoiceCloningAuthorizationScope.perProfile,
      ),
    );

    expect(result, isA<Failure>());
  });

  test('Authorize then Revoke profile cloning preserves scope', () async {
    await createProfile();
    await SetVoiceCloningAuthorizationScopeUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      SetVoiceCloningAuthorizationScopeRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
        scope: VoiceCloningAuthorizationScope.perProfile,
      ),
    );

    await AuthorizeVoiceCloningUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      AuthorizeVoiceCloningRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    var profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(profile!.authorization.isCloningAuthorized, isTrue);

    await RevokeVoiceCloningUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      RevokeVoiceCloningRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(profile!.authorization.isCloningAuthorized, isFalse);
    expect(
      profile.cloningAuthorizationScope,
      VoiceCloningAuthorizationScope.perProfile,
    );
  });

  test('AuthorizeStoryVoiceCloning sets Story consent', () async {
    final result = await AuthorizeStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );

    expect(result, isA<Success>());
    final story = await storyRepository.findById(storyId);
    expect(story!.consent.isVoiceCloningAuthorized, isTrue);
    expect(story.consent.isVoiceRenderingApproved, isFalse);
  });

  test('DenyStoryVoiceCloning sets explicit denial', () async {
    await AuthorizeStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );

    final result = await DenyStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      DenyStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );

    expect(result, isA<Success>());
    final story = await storyRepository.findById(storyId);
    expect(story!.consent.isVoiceCloningDenied, isTrue);
    expect(story.consent.isVoiceCloningAuthorized, isFalse);
  });

  test('RevokeStoryVoiceCloning returns to notGranted', () async {
    await DenyStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      DenyStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );

    final result = await RevokeStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      RevokeStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: heroId,
      ),
    );

    expect(result, isA<Success>());
    final story = await storyRepository.findById(storyId);
    expect(story!.consent.isVoiceCloningNotGranted, isTrue);
  });

  test('story cloning authorize rejects non-owner', () async {
    final result = await AuthorizeStoryVoiceCloningUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeStoryVoiceCloningRequest(
        storyId: storyId,
        ownerHeroId: HeroId.generate(),
      ),
    );

    expect(result, isA<Failure>());
  });
}
