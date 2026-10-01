import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_cloning_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_enrollment_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_publication_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/authorize_voice_story_use_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/create_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/delete_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/enroll_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/revoke_voice_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_voice_cloning_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_voice_enrollment_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_voice_publication_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/authorize_voice_story_use_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_voice_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/delete_voice_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/enroll_voice_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/revoke_voice_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_profile_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_voice_profile_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_voice_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryVoiceProfileRepository voiceProfileRepository;
  late InMemoryVoiceProfileAdapter voiceProfilePort;
  late EventBus eventBus;
  late HeroId heroId;
  late VoiceProfileId voiceProfileId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    voiceProfileRepository = InMemoryVoiceProfileRepository();
    voiceProfilePort = InMemoryVoiceProfileAdapter();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    heroId = HeroId.generate();
    voiceProfileId = VoiceProfileId.generate();

    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Test Hero',
          biography: 'A test hero',
        ),
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
        referenceAudio: [MediaReference('media://enrollment-sample')],
        displayName: 'My Voice',
      ),
    );
    expect(result, isA<Success>());
  }

  test('CreateVoiceProfile creates Hero-scoped draft', () async {
    await createProfile();
    final profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(profile, isNotNull);
    expect(profile!.ownerHeroId, heroId);
    expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.draft);
    expect(profile.referenceAudio, hasLength(1));
  });

  test('enroll without authorization fails', () async {
    await createProfile();

    final result = await EnrollVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      voiceProfilePort: voiceProfilePort,
      eventBus: eventBus,
    ).execute(
      EnrollVoiceProfileRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    expect(result, isA<Failure>());
    expect(
      (result as Failure).error,
      contains('enrollment is not authorized'),
    );
    expect(voiceProfilePort.enrollCallCount, 0);
  });

  test('authorize enrollment then enroll via in-memory adapter', () async {
    await createProfile();

    final auth = await AuthorizeVoiceEnrollmentUseCase(
      voiceProfileRepository: voiceProfileRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeVoiceEnrollmentRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );
    expect(auth, isA<Success>());
    final authorized = (auth as Success).value;
    expect(
      authorized.lifecycleStatus,
      VoiceProfileLifecycleStatus.authorized,
    );
    expect(authorized.authorization.isCloningAuthorized, isFalse);

    final enrolled = await EnrollVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      voiceProfilePort: voiceProfilePort,
      eventBus: eventBus,
    ).execute(
      EnrollVoiceProfileRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    expect(enrolled, isA<Success>());
    final enrolledProfile = (enrolled as Success).value;
    expect(
      enrolledProfile.lifecycleStatus,
      VoiceProfileLifecycleStatus.enrolled,
    );
    expect(voiceProfilePort.enrollCallCount, 1);
    expect(voiceProfilePort.hasSyntheticEnrollment(voiceProfileId), isTrue);
    expect(enrolledProfile.authorization.isCloningAuthorized, isFalse);
  });

  test('authorization gates remain independent through use cases', () async {
    await createProfile();
    await AuthorizeVoiceEnrollmentUseCase(
      voiceProfileRepository: voiceProfileRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeVoiceEnrollmentRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
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
    await AuthorizeVoiceStoryUseUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      AuthorizeVoiceStoryUseRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );
    await AuthorizeVoicePublicationUseCase(
      voiceProfileRepository: voiceProfileRepository,
    ).execute(
      AuthorizeVoicePublicationRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    final profile = await voiceProfileRepository.findById(voiceProfileId);
    expect(profile!.authorization.isEnrollmentAuthorized, isTrue);
    expect(profile.authorization.isCloningAuthorized, isTrue);
    expect(profile.authorization.isStoryUseAuthorized, isTrue);
    expect(profile.authorization.isPublicationAuthorized, isTrue);
  });

  test('revoke blocks future use and calls port.revoke', () async {
    await createProfile();
    await AuthorizeVoiceEnrollmentUseCase(
      voiceProfileRepository: voiceProfileRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeVoiceEnrollmentRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );
    await EnrollVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      voiceProfilePort: voiceProfilePort,
      eventBus: eventBus,
    ).execute(
      EnrollVoiceProfileRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    final revoked = await RevokeVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      voiceProfilePort: voiceProfilePort,
      eventBus: eventBus,
    ).execute(
      RevokeVoiceProfileRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    expect(revoked, isA<Success>());
    final revokedProfile = (revoked as Success).value;
    expect(
      revokedProfile.lifecycleStatus,
      VoiceProfileLifecycleStatus.revoked,
    );
    expect(revokedProfile.allowsFutureVoiceUse, isFalse);
    expect(voiceProfilePort.revokeCallCount, 1);
  });

  test('delete marks deleted and calls port.delete', () async {
    await createProfile();

    final deleted = await DeleteVoiceProfileUseCase(
      voiceProfileRepository: voiceProfileRepository,
      voiceProfilePort: voiceProfilePort,
      eventBus: eventBus,
    ).execute(
      DeleteVoiceProfileRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: heroId,
      ),
    );

    expect(deleted, isA<Success>());
    expect(
      (deleted as Success).value.lifecycleStatus,
      VoiceProfileLifecycleStatus.deleted,
    );
    expect(voiceProfilePort.deleteCallCount, 1);
  });

  test('owner mismatch is rejected', () async {
    await createProfile();
    final other = HeroId.generate();

    final result = await AuthorizeVoiceEnrollmentUseCase(
      voiceProfileRepository: voiceProfileRepository,
      eventBus: eventBus,
    ).execute(
      AuthorizeVoiceEnrollmentRequest(
        voiceProfileId: voiceProfileId,
        ownerHeroId: other,
      ),
    );

    expect(result, isA<Failure>());
  });
}
