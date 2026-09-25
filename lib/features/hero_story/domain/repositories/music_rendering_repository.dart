import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';

/// Persistence boundary for derived music renderings (Experiment A).
abstract interface class MusicRenderingRepository {
  Future<void> save(MusicRendering rendering);

  Future<MusicRendering?> findById(MusicRenderingId id);

  Future<MusicRendering?> findByStoryId(StoryId storyId);

  Future<void> delete(MusicRenderingId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
