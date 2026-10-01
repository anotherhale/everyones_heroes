import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

/// Domain recorded enrollment completion for a VoiceProfile (HS.12.9).
///
/// Does not imply cloning, story-use, or publication authorization.
final class VoiceProfileEnrolled extends EventBase {
  VoiceProfileEnrolled({
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
