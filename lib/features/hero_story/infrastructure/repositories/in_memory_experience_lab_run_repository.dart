import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/experience_lab_run_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';

class InMemoryExperienceLabRunRepository implements ExperienceLabRunRepository {
  final Map<ExperienceLabRunId, ExperienceLabRun> _byId = {};
  final Map<StoryId, ExperienceLabRunId> _latestByStory = {};

  @override
  Future<void> save(ExperienceLabRun run) async {
    _byId[run.id] = run;
    _latestByStory[run.storyId] = run.id;
  }

  @override
  Future<ExperienceLabRun?> findById(ExperienceLabRunId id) async => _byId[id];

  @override
  Future<ExperienceLabRun?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) return null;
    return _byId[id];
  }

  @override
  Future<void> delete(ExperienceLabRunId id) async {
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
