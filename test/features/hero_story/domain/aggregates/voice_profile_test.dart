import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_profile_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_created.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_deleted.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_enrolled.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_enrollment_authorized.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/voice_profile_revoked.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/voice_profile_authorization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final heroId = HeroId('hero-1');
  final language = LanguageCode('en');
  final at = DateTime.utc(2026, 10, 1, 12);

  VoiceProfile createDraft({
    VoiceProfileId? id,
    HeroId? owner,
    List<MediaReference> refs = const [],
  }) {
    return VoiceProfile.create(
      id: id ?? VoiceProfileId('vp-1'),
      ownerHeroId: owner ?? heroId,
      language: language,
      referenceAudio: refs,
      createdAt: at,
    );
  }

  group('Hero ownership', () {
    test('VoiceProfile belongs to exactly one HeroId', () {
      final profile = createDraft();
      expect(profile.ownerHeroId, heroId);
      expect(profile.ownerHeroId, isNot(HeroId('other-hero')));
    });

    test('ownerHeroId is immutable after creation', () {
      final profile = createDraft(owner: HeroId('owner-a'));
      expect(profile.ownerHeroId.value, 'owner-a');
      // No setter / transfer API exists on the aggregate.
      expect(profile.ownerHeroId, HeroId('owner-a'));
    });
  });

  group('Initial lifecycle', () {
    test('create starts in draft with no authorizations', () {
      final profile = createDraft();
      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.draft);
      expect(profile.authorization, VoiceProfileAuthorization.none);
      expect(
        profile.cloningAuthorizationScope,
        VoiceCloningAuthorizationScope.perStory,
      );
      expect(profile.isEnrollable, isFalse);
      expect(profile.providerEnrollmentExists, isFalse);
      expect(profile.pullDomainEvents().single, isA<VoiceProfileCreated>());
    });
  });

  group('Enrollment authorization', () {
    test('authorizeEnrollment transitions draft → authorized', () {
      final profile = createDraft()..pullDomainEvents();
      profile.authorizeEnrollment(at: at);

      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.authorized);
      expect(profile.authorization.isEnrollmentAuthorized, isTrue);
      expect(profile.isEnrollable, isTrue);
      expect(profile.providerEnrollmentExists, isFalse);
      expect(
        profile.pullDomainEvents().single,
        isA<VoiceProfileEnrollmentAuthorized>(),
      );
    });

    test('enrollment authorization does not imply cloning authorization', () {
      final profile = createDraft()..authorizeEnrollment(at: at);

      expect(profile.authorization.isEnrollmentAuthorized, isTrue);
      expect(profile.authorization.isCloningAuthorized, isFalse);
      expect(profile.authorization.isStoryUseAuthorized, isFalse);
      expect(profile.authorization.isPublicationAuthorized, isFalse);
    });
  });

  group('Enrollment without authorization fails', () {
    test('markEnrolled throws when enrollment is not authorized', () {
      final profile = createDraft();
      expect(
        () => profile.markEnrolled(at: at),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('enrollment is not authorized'),
          ),
        ),
      );
      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.draft);
    });
  });

  group('Independent authorization gates', () {
    test('cloning authorization is independently controlled', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..authorizeCloning(at: at);

      expect(profile.authorization.isEnrollmentAuthorized, isTrue);
      expect(profile.authorization.isCloningAuthorized, isTrue);
      expect(profile.authorization.isStoryUseAuthorized, isFalse);
      expect(profile.authorization.isPublicationAuthorized, isFalse);
    });

    test('story-use authorization is independent', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..authorizeStoryUse(at: at);

      expect(profile.authorization.isStoryUseAuthorized, isTrue);
      expect(profile.authorization.isCloningAuthorized, isFalse);
      expect(profile.authorization.isPublicationAuthorized, isFalse);
    });

    test('publication authorization is independent', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..authorizePublication(at: at);

      expect(profile.authorization.isPublicationAuthorized, isTrue);
      expect(profile.authorization.isCloningAuthorized, isFalse);
      expect(profile.authorization.isStoryUseAuthorized, isFalse);
    });

    test('enrollment alone does not authorize cloning or story use', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..markEnrolled(at: at);

      expect(profile.isEnrolled, isTrue);
      expect(profile.authorization.isCloningAuthorized, isFalse);
      expect(profile.maySynthesizeForStoryUse, isFalse);
    });
  });

  group('Enrollment lifecycle', () {
    test('authorized profile can markEnrolled', () {
      final profile = createDraft()
        ..pullDomainEvents()
        ..authorizeEnrollment(at: at)
        ..pullDomainEvents();

      profile.markEnrolled(at: at);

      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.enrolled);
      expect(profile.providerEnrollmentExists, isTrue);
      expect(profile.pullDomainEvents().single, isA<VoiceProfileEnrolled>());
    });
  });

  group('Revocation blocks future use', () {
    test('revoke blocks allowsFutureVoiceUse and maySynthesizeForStoryUse', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..authorizeStoryUse(at: at)
        ..markEnrolled(at: at)
        ..pullDomainEvents();

      expect(profile.maySynthesizeForStoryUse, isTrue);

      profile.revoke(at: at);

      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.revoked);
      expect(profile.allowsFutureVoiceUse, isFalse);
      expect(profile.maySynthesizeForStoryUse, isFalse);
      expect(profile.pullDomainEvents().single, isA<VoiceProfileRevoked>());
    });

    test('revoked profile cannot be modified', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..revoke(at: at);

      expect(
        () => profile.authorizeCloning(at: at),
        throwsA(isA<StateError>()),
      );
      expect(
        () => profile.markEnrolled(at: at),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Reference media', () {
    test('supports multiple MediaReference clips without embedding bytes', () {
      final profile = createDraft(
        refs: [MediaReference('media://ref-1')],
      )..pullDomainEvents();

      profile.addReferenceAudio(MediaReference('media://ref-2'), at: at);
      profile.addReferenceAudio(MediaReference('media://ref-3'), at: at);

      expect(profile.referenceAudio, hasLength(3));
      expect(
        profile.referenceAudio.map((r) => r.uri).toList(),
        ['media://ref-1', 'media://ref-2', 'media://ref-3'],
      );
    });

    test('duplicate reference URIs are ignored', () {
      final profile = createDraft()..pullDomainEvents();
      profile.addReferenceAudio(MediaReference('media://same'), at: at);
      profile.addReferenceAudio(MediaReference('media://same'), at: at);
      expect(profile.referenceAudio, hasLength(1));
    });
  });

  group('Provider identity isolation', () {
    test('VoiceProfileId is EH identity, not a provider voice id', () {
      final id = VoiceProfileId('eh-voice-profile-uuid');
      final profile = createDraft(id: id);
      expect(profile.id, id);
      expect(profile.id.value, isNot(contains('providerVoiceId')));
      // Aggregate exposes no providerVoiceId / openai / qwen fields.
      expect(profile.id.runtimeType.toString(), 'VoiceProfileId');
    });
  });

  group('Deletion', () {
    test('delete is terminal and emits VoiceProfileDeleted', () {
      final profile = createDraft()
        ..authorizeEnrollment(at: at)
        ..pullDomainEvents();

      profile.markDeleted(at: at);

      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.deleted);
      expect(profile.allowsFutureVoiceUse, isFalse);
      expect(profile.pullDomainEvents().single, isA<VoiceProfileDeleted>());
      expect(
        () => profile.authorizeEnrollment(at: at),
        throwsA(isA<StateError>()),
      );
    });
  });
}
