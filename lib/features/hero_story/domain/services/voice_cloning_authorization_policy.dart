import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/voice_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/effective_voice_cloning_authorization.dart';

/// Centralized effective voice-cloning authorization evaluation (HS.12.10).
///
/// Answers: can this [VoiceProfile] be used to clone voice for this [Story]?
///
/// Precedence (deterministic):
///
/// 1. Deleted / revoked VoiceProfile → denied
/// 2. Profile must be enrolled (technical readiness; independent of cloning
///    authorization stamps)
/// 3. Hero ownership: profile owner must match Story.heroId
/// 4. Explicit Story denial → always wins
/// 5. Story-use authorization (independent gate) must be present
/// 6. Scope-specific cloning authorization:
///    - [VoiceCloningAuthorizationScope.perStory] → Story cloning required
///    - [VoiceCloningAuthorizationScope.perProfile] → profile cloning required
///
/// Scope ≠ authorization. Changing scope does not mutate authorization stamps.
///
/// Does not call providers, UI, or persistence.
final class VoiceCloningAuthorizationPolicy {
  const VoiceCloningAuthorizationPolicy._();

  static EffectiveVoiceCloningAuthorization evaluate({
    required VoiceProfile profile,
    required Story story,
  }) {
    if (profile.isDeleted) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.profileDeleted,
      );
    }
    if (profile.isRevoked) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.profileRevoked,
      );
    }
    if (!profile.isEnrolled) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.profileNotEnrolled,
      );
    }
    if (profile.ownerHeroId != story.heroId) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.ownershipMismatch,
      );
    }

    // Explicit Story denial always wins — including under perProfile scope.
    if (story.consent.isVoiceCloningDenied) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.storyExplicitlyDenied,
      );
    }

    // Story-use remains an independent required gate for story-bound cloning.
    if (!profile.authorization.isStoryUseAuthorized) {
      return EffectiveVoiceCloningAuthorization.denied(
        VoiceCloningDenialReason.storyUseNotAuthorized,
      );
    }

    switch (profile.cloningAuthorizationScope) {
      case VoiceCloningAuthorizationScope.perStory:
        // Profile cloning authorization alone must not authorize the Story.
        if (!story.consent.isVoiceCloningAuthorized) {
          return EffectiveVoiceCloningAuthorization.denied(
            VoiceCloningDenialReason.storyCloningNotAuthorized,
          );
        }
      case VoiceCloningAuthorizationScope.perProfile:
        if (!profile.authorization.isCloningAuthorized) {
          return EffectiveVoiceCloningAuthorization.denied(
            VoiceCloningDenialReason.profileCloningNotAuthorized,
          );
        }
    }

    return EffectiveVoiceCloningAuthorization.allowed;
  }
}
