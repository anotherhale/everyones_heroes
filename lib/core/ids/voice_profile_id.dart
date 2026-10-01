import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Provider-independent identity for a Hero voice profile (HS.12.8 / HS.12.9).
///
/// Distinct from [StoryVoiceRenderingId]: a VoiceProfile is a reusable voice
/// identity; a StoryVoiceRendering is a derived audio artifact.
///
/// Must never be confused with a provider-specific voice id, OpenAI voice
/// name, Qwen speaker label, or embedding handle (HS-ADR-078).
final class VoiceProfileId extends StronglyTypedId implements AggregateId {
  const VoiceProfileId(super.value);

  factory VoiceProfileId.generate() {
    return VoiceProfileId(StronglyTypedId.uuid.v4());
  }
}
