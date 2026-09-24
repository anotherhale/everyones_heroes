import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Response for [RenderStoryVoiceUseCase].
final class RenderStoryVoiceResponse {
  const RenderStoryVoiceResponse({
    required this.rendering,
    this.idempotentReplay = false,
  });

  final StoryVoiceRendering rendering;
  final bool idempotentReplay;
}
