import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';

/// Persistence boundary for laboratory render manifests (Experiment A).
abstract interface class ExperienceRenderManifestRepository {
  Future<void> save(ExperienceRenderManifest manifest);

  Future<ExperienceRenderManifest?> findById(ExperienceRenderManifestId id);

  Future<ExperienceRenderManifest?> findByStoryId(StoryId storyId);

  Future<void> delete(ExperienceRenderManifestId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
