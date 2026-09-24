import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

class InMemoryStoryExperiencePlanRepository
    implements StoryExperiencePlanRepository {
  final Map<StoryExperiencePlanId, StoryExperiencePlan> _byId = {};
  final Map<StoryId, StoryExperiencePlanId> _latestByStory = {};

  @override
  Future<void> save(StoryExperiencePlan plan) async {
    _byId[plan.id] = plan;
    _latestByStory[plan.storyId] = plan.id;
  }

  @override
  Future<StoryExperiencePlan?> findById(StoryExperiencePlanId id) async {
    return _byId[id];
  }

  @override
  Future<StoryExperiencePlan?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _byId[id];
  }

  @override
  Future<StoryExperiencePlan?> getByStoryId(StoryId storyId) =>
      findByStoryId(storyId);

  @override
  Future<void> delete(StoryExperiencePlanId id) async {
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
