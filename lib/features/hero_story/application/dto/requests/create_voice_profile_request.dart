import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/voice_profile_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/media_reference.dart';

final class CreateVoiceProfileRequest {
  const CreateVoiceProfileRequest({
    required this.ownerHeroId,
    required this.language,
    this.voiceProfileId,
    this.referenceAudio = const [],
    this.displayName,
  });

  final HeroId ownerHeroId;
  final LanguageCode language;
  final VoiceProfileId? voiceProfileId;
  final List<MediaReference> referenceAudio;
  final String? displayName;
}
