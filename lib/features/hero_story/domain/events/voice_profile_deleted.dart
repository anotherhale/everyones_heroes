import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

/// A VoiceProfile entered the terminal deleted lifecycle state (HS.12.9).
final class VoiceProfileDeleted extends EventBase {
  VoiceProfileDeleted({
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
