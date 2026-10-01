import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

/// Provider-neutral VoiceProfile enrollment / lifecycle boundary
/// (HS.12.8 / HS.12.9).
///
/// Enrollment and revocation are **not** story narration. Story audio
/// synthesis remains on [VoiceRenderingPort]. Provider-specific voice ids,
/// SDKs, and credentials must never appear on this contract (HS-ADR-078).
///
/// HS.12.9 wires this port to the VoiceProfile aggregate via application use
/// cases and an in-memory adapter. No production cloning adapter, durable
/// persistence, or consent UI is implemented in this milestone.
abstract interface class VoiceProfilePort {
  /// Create or refresh a provider enrollment for a Hero-owned voice identity.
  Future<VoiceProfileEnrollmentDraft> enroll(
    VoiceProfileEnrollmentRequest request,
  );

  /// Revoke authorization for future synthesis with this profile.
  Future<void> revoke(VoiceProfileId voiceProfileId);

  /// Delete enrollment resources for this profile (best-effort at adapters).
  Future<void> delete(VoiceProfileId voiceProfileId);
}

/// Minimum EH-owned inputs for voice enrollment.
///
/// [referenceAudio] points at consented reference media. Bytes remain behind
/// a media storage port — never embedded in domain aggregates.
final class VoiceProfileEnrollmentRequest {
  const VoiceProfileEnrollmentRequest({
    required this.ownerHeroId,
    required this.referenceAudio,
    required this.language,
    this.voiceProfileId,
    this.displayName,
    this.processingVersion,
    this.providerHint,
    this.modelHint,
  });

  /// Hero whose voice identity is being enrolled.
  final HeroId ownerHeroId;

  /// Existing profile to refresh; null creates a new EH identity at use-case
  /// orchestration time (adapters must not mint provider ids as EH identity).
  final VoiceProfileId? voiceProfileId;

  final MediaReference referenceAudio;
  final LanguageCode language;
  final String? displayName;
  final String? processingVersion;

  /// Opaque infrastructure routing hints only — never domain identity.
  final String? providerHint;
  final String? modelHint;
}

/// EH-owned enrollment result. Provider handles stay opaque labels/refs.
final class VoiceProfileEnrollmentDraft {
  const VoiceProfileEnrollmentDraft({
    required this.voiceProfileId,
    required this.ownerHeroId,
    required this.language,
    this.displayName,
    this.providerLabel,
    this.modelLabel,
    this.processingVersion,
  });

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;
  final LanguageCode language;
  final String? displayName;
  final String? providerLabel;
  final String? modelLabel;
  final String? processingVersion;
}

final class VoiceProfileException implements Exception {
  const VoiceProfileException(this.message);

  final String message;

  @override
  String toString() => 'VoiceProfileException: $message';
}
