import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_understanding.dart';

abstract interface class StoryUnderstandingRepository {
  Future<void> save(StoryUnderstanding understanding);

  Future<StoryUnderstanding?> findById(StoryUnderstandingId id);

  Future<List<StoryUnderstanding>> findByStoryId(StoryId storyId);

  Future<StoryUnderstanding?> findLatestByStoryId(StoryId storyId);
}
