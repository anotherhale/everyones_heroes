import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_profile_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/voice_cloning_authorization_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/effective_voice_cloning_authorization.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/voice_profile_authorization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final heroId = HeroId('hero-1');
  final otherHeroId = HeroId('hero-other');
  final language = LanguageCode('en');
  final at = DateTime.utc(2026, 10, 1, 12);

  VoiceProfile createEnrolledProfile({
    HeroId? owner,
    VoiceCloningAuthorizationScope scope =
        VoiceCloningAuthorizationScope.perStory,
  }) {
    final profile = VoiceProfile.create(
      id: VoiceProfileId('vp-1'),
      ownerHeroId: owner ?? heroId,
      language: language,
      createdAt: at,
    )..pullDomainEvents();

    profile
      ..authorizeEnrollment(at: at)
      ..markEnrolled(at: at)
      ..authorizeStoryUse(at: at);

    if (scope != VoiceCloningAuthorizationScope.perStory) {
      profile.setCloningAuthorizationScope(scope, at: at);
    }
    return profile;
  }

  Story createStory({HeroId? owner}) {
    return Story.create(
      id: StoryId('story-1'),
      heroId: owner ?? heroId,
      title: StoryTitle('Test Story'),
      narrative: StoryNarrative('A meaningful narrative.'),
      originalLanguage: language,
      createdAt: at,
    )..pullDomainEvents();
  }

  group('Default scope', () {
    test('new VoiceProfile defaults to perStory', () {
      final profile = VoiceProfile.create(
        id: VoiceProfileId('vp-new'),
        ownerHeroId: heroId,
        language: language,
        createdAt: at,
      );

      expect(
        profile.cloningAuthorizationScope,
        VoiceCloningAuthorizationScope.perStory,
      );
      expect(profile.authorization, VoiceProfileAuthorization.none);
    });
  });

  group('perStory semantics', () {
    test('profile cloning alone does not authorize cloning', () {
      final profile = createEnrolledProfile()..authorizeCloning(at: at);
      final story = createStory();

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(
        result.denialReason,
        VoiceCloningDenialReason.storyCloningNotAuthorized,
      );
    });

    test('story cloning authorization allows cloning', () {
      final profile = createEnrolledProfile();
      final story = createStory();
      story.updateConsent(story.consent.grantVoiceCloning(at), at: at);

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isTrue);
      expect(result.denialReason, isNull);
    });
  });

  group('perProfile semantics', () {
    test('profile cloning authorization allows cloning', () {
      final profile = createEnrolledProfile(
        scope: VoiceCloningAuthorizationScope.perProfile,
      )..authorizeCloning(at: at);
      final story = createStory();

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isTrue);
    });

    test('perProfile without profile cloning authorization is denied', () {
      final profile = createEnrolledProfile(
        scope: VoiceCloningAuthorizationScope.perProfile,
      );
      final story = createStory();

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(
        result.denialReason,
        VoiceCloningDenialReason.profileCloningNotAuthorized,
      );
    });

    test('explicit Story denial always wins over profile authorization', () {
      final profile = createEnrolledProfile(
        scope: VoiceCloningAuthorizationScope.perProfile,
      )..authorizeCloning(at: at);
      final story = createStory();
      story.updateConsent(story.consent.denyVoiceCloning(at), at: at);

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(
        result.denialReason,
        VoiceCloningDenialReason.storyExplicitlyDenied,
      );
    });
  });

  group('Lifecycle restrictions', () {
    test('revoked VoiceProfile cannot be used for cloning', () {
      final profile = createEnrolledProfile()
        ..authorizeCloning(at: at);
      final story = createStory();
      story.updateConsent(story.consent.grantVoiceCloning(at), at: at);

      profile.revoke(at: at);

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(result.denialReason, VoiceCloningDenialReason.profileRevoked);
    });

    test('deleted VoiceProfile cannot be used for cloning', () {
      final profile = createEnrolledProfile()
        ..authorizeCloning(at: at);
      final story = createStory();
      story.updateConsent(story.consent.grantVoiceCloning(at), at: at);

      profile.markDeleted(at: at);

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(result.denialReason, VoiceCloningDenialReason.profileDeleted);
    });
  });

  group('Independence of authorization gates', () {
    test('cloning authorization does not imply enrollment', () {
      final profile = VoiceProfile.create(
        id: VoiceProfileId('vp-clone-only'),
        ownerHeroId: heroId,
        language: language,
        createdAt: at,
      )..authorizeCloning(at: at);

      expect(profile.authorization.isCloningAuthorized, isTrue);
      expect(profile.authorization.isEnrollmentAuthorized, isFalse);
      expect(profile.lifecycleStatus, VoiceProfileLifecycleStatus.draft);
      expect(profile.providerEnrollmentExists, isFalse);
    });

    test('cloning authorization does not imply story-use', () {
      final profile = createEnrolledProfile();
      // createEnrolledProfile already grants story-use; revoke it then grant
      // cloning to prove independence of the stamps on VoiceProfileAuthorization.
      final auth = profile.authorization;
      expect(auth.isStoryUseAuthorized, isTrue);

      final draft = VoiceProfile.create(
        id: VoiceProfileId('vp-indep'),
        ownerHeroId: heroId,
        language: language,
        createdAt: at,
      )
        ..authorizeEnrollment(at: at)
        ..authorizeCloning(at: at);

      expect(draft.authorization.isCloningAuthorized, isTrue);
      expect(draft.authorization.isStoryUseAuthorized, isFalse);
    });

    test('cloning authorization does not imply publication', () {
      final profile = createEnrolledProfile()..authorizeCloning(at: at);

      expect(profile.authorization.isCloningAuthorized, isTrue);
      expect(profile.authorization.isPublicationAuthorized, isFalse);
    });

    test('story-use remains independently required for effective cloning', () {
      final profile = VoiceProfile.create(
        id: VoiceProfileId('vp-no-story-use'),
        ownerHeroId: heroId,
        language: language,
        createdAt: at,
      )
        ..pullDomainEvents()
        ..authorizeEnrollment(at: at)
        ..markEnrolled(at: at)
        ..authorizeCloning(at: at)
        ..setCloningAuthorizationScope(
          VoiceCloningAuthorizationScope.perProfile,
          at: at,
        );

      final story = createStory();

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(
        result.denialReason,
        VoiceCloningDenialReason.storyUseNotAuthorized,
      );
    });
  });

  group('Ownership', () {
    test('Hero ownership mismatch denies cloning', () {
      final profile = createEnrolledProfile(owner: heroId)
        ..authorizeCloning(at: at)
        ..setCloningAuthorizationScope(
          VoiceCloningAuthorizationScope.perProfile,
          at: at,
        );
      final story = createStory(owner: otherHeroId);

      final result = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );

      expect(result.isAllowed, isFalse);
      expect(result.denialReason, VoiceCloningDenialReason.ownershipMismatch);
    });
  });

  group('Scope changes preserve authorization state', () {
    test('perStory → perProfile does not erase cloning authorization', () {
      final profile = createEnrolledProfile()..authorizeCloning(at: at);

      expect(
        profile.cloningAuthorizationScope,
        VoiceCloningAuthorizationScope.perStory,
      );
      expect(profile.authorization.isCloningAuthorized, isTrue);
      expect(profile.authorization.isStoryUseAuthorized, isTrue);
      expect(profile.authorization.isEnrollmentAuthorized, isTrue);

      profile.setCloningAuthorizationScope(
        VoiceCloningAuthorizationScope.perProfile,
        at: at,
      );

      expect(
        profile.cloningAuthorizationScope,
        VoiceCloningAuthorizationScope.perProfile,
      );
      expect(profile.authorization.isCloningAuthorized, isTrue);
      expect(profile.authorization.isStoryUseAuthorized, isTrue);
      expect(profile.authorization.isEnrollmentAuthorized, isTrue);
    });

    test('perProfile → perStory restores Story-level requirement', () {
      final profile = createEnrolledProfile(
        scope: VoiceCloningAuthorizationScope.perProfile,
      )..authorizeCloning(at: at);
      final story = createStory();

      expect(
        VoiceCloningAuthorizationPolicy.evaluate(
          profile: profile,
          story: story,
        ).isAllowed,
        isTrue,
      );

      profile.setCloningAuthorizationScope(
        VoiceCloningAuthorizationScope.perStory,
        at: at,
      );

      // Authorization stamps preserved…
      expect(profile.authorization.isCloningAuthorized, isTrue);
      // …but effective evaluation now requires Story-level grant.
      final after = VoiceCloningAuthorizationPolicy.evaluate(
        profile: profile,
        story: story,
      );
      expect(after.isAllowed, isFalse);
      expect(
        after.denialReason,
        VoiceCloningDenialReason.storyCloningNotAuthorized,
      );
    });
  });

  group('Story cloning consent vocabulary', () {
    test('distinguishes notGranted, authorized, and denied', () {
      final story = createStory();
      expect(story.consent.isVoiceCloningNotGranted, isTrue);
      expect(story.consent.isVoiceCloningAuthorized, isFalse);
      expect(story.consent.isVoiceCloningDenied, isFalse);

      story.updateConsent(story.consent.grantVoiceCloning(at), at: at);
      expect(story.consent.isVoiceCloningAuthorized, isTrue);
      expect(story.consent.isVoiceCloningDenied, isFalse);
      expect(story.consent.isVoiceCloningNotGranted, isFalse);

      story.updateConsent(story.consent.denyVoiceCloning(at), at: at);
      expect(story.consent.isVoiceCloningDenied, isTrue);
      expect(story.consent.isVoiceCloningAuthorized, isFalse);

      story.updateConsent(story.consent.revokeVoiceCloning(), at: at);
      expect(story.consent.isVoiceCloningNotGranted, isTrue);
    });

    test('voice rendering consent does not imply cloning consent', () {
      final story = createStory();
      story.updateConsent(story.consent.grantVoiceRendering(at), at: at);

      expect(story.consent.isVoiceRenderingApproved, isTrue);
      expect(story.consent.isVoiceCloningAuthorized, isFalse);
      expect(story.consent.isVoiceCloningDenied, isFalse);
    });
  });
}
