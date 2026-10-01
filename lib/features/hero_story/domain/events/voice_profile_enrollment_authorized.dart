import 'package:everyonesheroes/core/eventing/aggregate_type.dart';
import 'package:everyonesheroes/core/eventing/event_base.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';

/// Enrollment authorization was granted for a VoiceProfile (HS.12.9).
///
/// Does not imply provider enrollment exists or that cloning is authorized.
final class VoiceProfileEnrollmentAuthorized extends EventBase {
  VoiceProfileEnrollmentAuthorized({
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
