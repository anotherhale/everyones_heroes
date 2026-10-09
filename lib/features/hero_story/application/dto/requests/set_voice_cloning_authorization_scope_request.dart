import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/voice_cloning_authorization_scope.dart';

final class SetVoiceCloningAuthorizationScopeRequest {
  const SetVoiceCloningAuthorizationScopeRequest({
    required this.voiceProfileId,
    required this.ownerHeroId,
    required this.scope,
    this.at,
  });

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;
  final VoiceCloningAuthorizationScope scope;
  final DateTime? at;
}
