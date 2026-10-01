import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

/// A VoiceProfile was revoked; future authorized voice use is blocked (HS.12.9).
final class VoiceProfileRevoked extends EventBase {
  VoiceProfileRevoked({
    required this.voiceProfileId,
    required this.ownerHeroId,
    super.correlationId,
    super.causationId,
  }) : super(
          aggregateId: voiceProfileId,
          aggregateType: AggregateType.voiceProfile,
        );

  final VoiceProfileId voiceProfileId;
  final HeroId ownerHeroId;
}
