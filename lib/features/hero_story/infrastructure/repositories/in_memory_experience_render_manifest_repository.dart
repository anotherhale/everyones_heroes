import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_repository.dart';

class InMemoryExperienceRenderManifestRepository
    implements ExperienceRenderManifestRepository {
  final Map<ExperienceRenderManifestId, ExperienceRenderManifest> _byId = {};
  final Map<StoryId, ExperienceRenderManifestId> _latestByStory = {};

  @override
  Future<void> save(ExperienceRenderManifest manifest) async {
    _byId[manifest.id] = manifest;
    _latestByStory[manifest.storyId] = manifest.id;
  }

  @override
  Future<ExperienceRenderManifest?> findById(
    ExperienceRenderManifestId id,
  ) async =>
      _byId[id];

  @override
  Future<ExperienceRenderManifest?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) return null;
    return _byId[id];
  }

  @override
  Future<void> delete(ExperienceRenderManifestId id) async {
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
