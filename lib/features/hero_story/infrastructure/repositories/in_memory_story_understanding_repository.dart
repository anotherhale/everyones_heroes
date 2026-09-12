import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_understanding_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_understanding.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_understanding_repository.dart';

class InMemoryStoryUnderstandingRepository
    implements StoryUnderstandingRepository {
  final Map<StoryUnderstandingId, StoryUnderstanding> _store = {};

  @override
  Future<void> save(StoryUnderstanding understanding) async {
    _store[understanding.id] = understanding;
  }

  @override
  Future<StoryUnderstanding?> findById(StoryUnderstandingId id) async {
    return _store[id];
  }

  @override
  Future<List<StoryUnderstanding>> findByStoryId(StoryId storyId) async {
    final matches = _store.values
        .where((u) => u.storyId == storyId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(matches);
  }

  @override
  Future<StoryUnderstanding?> findLatestByStoryId(StoryId storyId) async {
    final matches = await findByStoryId(storyId);
    if (matches.isEmpty) {
      return null;
    }
    return matches.last;
  }
}
