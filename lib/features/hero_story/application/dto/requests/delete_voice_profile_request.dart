import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

final class DeleteVoiceProfileRequest {
  const DeleteVoiceProfileRequest({
    required this.voiceProfileId,
    required this.ownerHeroId,
  });

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;
}
