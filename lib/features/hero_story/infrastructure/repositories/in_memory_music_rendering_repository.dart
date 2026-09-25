import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/music_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';

class InMemoryMusicRenderingRepository implements MusicRenderingRepository {
  final Map<MusicRenderingId, MusicRendering> _byId = {};
  final Map<StoryId, MusicRenderingId> _latestByStory = {};

  @override
  Future<void> save(MusicRendering rendering) async {
    _byId[rendering.id] = rendering;
    _latestByStory[rendering.storyId] = rendering.id;
  }

  @override
  Future<MusicRendering?> findById(MusicRenderingId id) async => _byId[id];

  @override
  Future<MusicRendering?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) return null;
    return _byId[id];
  }

  @override
  Future<void> delete(MusicRenderingId id) async {
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
