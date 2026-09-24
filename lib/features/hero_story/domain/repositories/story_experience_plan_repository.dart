import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';

/// Persistence boundary for derived [StoryExperiencePlan] artifacts (HS.12.4).
///
/// Plans are keyed by [StoryId]. They are not stored on the Story aggregate
/// and regenerating a plan must not modify Story or CapturedStoryReading.
abstract interface class StoryExperiencePlanRepository {
  Future<void> save(StoryExperiencePlan plan);

  Future<StoryExperiencePlan?> findById(StoryExperiencePlanId id);

  /// Latest plan for [storyId], if any.
  Future<StoryExperiencePlan?> findByStoryId(StoryId storyId);

  /// Alias for [findByStoryId] (HS.12.4 wording).
  Future<StoryExperiencePlan?> getByStoryId(StoryId storyId);

  Future<void> delete(StoryExperiencePlanId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
