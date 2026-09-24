import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

/// Persistence boundary for derived [CapturedStoryReading] artifacts (HS.12.3).
///
/// Readings are keyed by [StoryId]. They are not stored on the Story aggregate.
abstract interface class CapturedStoryReadingRepository {
  Future<void> save(CapturedStoryReading reading);

  Future<CapturedStoryReading?> findById(CapturedStoryReadingId id);

  /// Latest reading for [storyId], if any.
  Future<CapturedStoryReading?> findByStoryId(StoryId storyId);

  Future<void> delete(CapturedStoryReadingId id);

  Future<void> deleteByStoryId(StoryId storyId);
}
