import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';

/// Persistence boundary for laboratory experiment runs (Experiment A).
abstract interface class ExperienceLabRunRepository {
  Future<void> save(ExperienceLabRun run);

  Future<ExperienceLabRun?> findById(ExperienceLabRunId id);

  Future<ExperienceLabRun?> findByStoryId(StoryId storyId);

  Future<void> delete(ExperienceLabRunId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
