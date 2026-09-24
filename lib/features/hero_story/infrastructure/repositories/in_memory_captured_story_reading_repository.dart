import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';

class InMemoryCapturedStoryReadingRepository
    implements CapturedStoryReadingRepository {
  final Map<CapturedStoryReadingId, CapturedStoryReading> _byId = {};
  final Map<StoryId, CapturedStoryReadingId> _latestByStory = {};

  @override
  Future<void> save(CapturedStoryReading reading) async {
    _byId[reading.id] = reading;
    _latestByStory[reading.storyId] = reading.id;
  }

  @override
  Future<CapturedStoryReading?> findById(CapturedStoryReadingId id) async {
    return _byId[id];
  }

  @override
  Future<CapturedStoryReading?> findByStoryId(StoryId storyId) async {
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _byId[id];
  }

  @override
  Future<void> delete(CapturedStoryReadingId id) async {
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
