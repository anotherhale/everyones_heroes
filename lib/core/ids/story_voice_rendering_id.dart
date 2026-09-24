import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

/// Identity for a derived [StoryVoiceRendering] artifact (HS.12.6).
final class StoryVoiceRenderingId extends StronglyTypedId {
  const StoryVoiceRenderingId(super.value);

  factory StoryVoiceRenderingId.generate() {
    return StoryVoiceRenderingId(StronglyTypedId.uuid.v4());
  }
}
