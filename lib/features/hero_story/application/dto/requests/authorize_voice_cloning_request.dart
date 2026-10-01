import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

final class AuthorizeVoiceCloningRequest {
  const AuthorizeVoiceCloningRequest({
    required this.voiceProfileId,
    required this.ownerHeroId,
    this.at,
  });

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;
  final DateTime? at;
}
