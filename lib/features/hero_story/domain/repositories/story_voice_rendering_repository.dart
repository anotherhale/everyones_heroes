import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

/// Persistence boundary for derived Story voice renderings (HS.12.6).
abstract interface class StoryVoiceRenderingRepository {
  Future<void> save(StoryVoiceRendering rendering);

  Future<StoryVoiceRendering?> findById(StoryVoiceRenderingId id);

  /// Latest rendering for [storyId], if any.
  Future<StoryVoiceRendering?> findByStoryId(StoryId storyId);

  Future<StoryVoiceRendering?> getByStoryId(StoryId storyId);

  Future<void> delete(StoryVoiceRenderingId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
