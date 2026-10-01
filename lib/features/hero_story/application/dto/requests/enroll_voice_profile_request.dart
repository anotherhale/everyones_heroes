import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

final class EnrollVoiceProfileRequest {
  const EnrollVoiceProfileRequest({
    required this.voiceProfileId,
    required this.ownerHeroId,
    this.referenceAudio,
    this.processingVersion,
    this.providerHint,
    this.modelHint,
  });

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;

  /// Optional override; defaults to the first reference on the profile.
  final MediaReference? referenceAudio;
  final String? processingVersion;

  /// Opaque infrastructure routing hints only — never domain identity.
  final String? providerHint;
  final String? modelHint;
}
