import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_voice_rendering_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_voice_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_voice_rendering.dart';

class InMemoryStoryVoiceRenderingRepository
    implements StoryVoiceRenderingRepository {
  final Map<StoryVoiceRenderingId, StoryVoiceRendering> _byId = {};
  final Map<StoryId, StoryVoiceRenderingId> _latestByStory = {};

  @override
  Future<void> save(StoryVoiceRendering rendering) async {
    // Regeneration replaces the latest pointer with a new id — prior artifacts
    // are not blindly overwritten in place.
    _byId[rendering.id] = rendering;
    _latestByStory[rendering.storyId] = rendering.id;
  }

  @override
  Future<StoryVoiceRendering?> findById(StoryVoiceRenderingId id) async {
    return _byId[id];
  }

  @override
  Future<StoryVoiceRendering?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _byId[id];
  }

  @override
  Future<StoryVoiceRendering?> getByStoryId(StoryId storyId) =>
      findByStoryId(storyId);

  @override
  Future<void> delete(StoryVoiceRenderingId id) async {
    final existing = _byId.remove(id);
    if (existing != null && _latestByStory[existing.storyId] == id) {
      _latestByStory.remove(existing.storyId);
    }
  }

  @override
  Future<void> deleteByStoryId(StoryId storyId) async {
    final id = _latestByStory.remove(storyId);
    if (id != null) {
      _byId.remove(id);
    }
  }
}
