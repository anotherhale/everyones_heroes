import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';

class InMemoryStoryRepository implements StoryRepository {
  final Map<StoryId, Story> _store = {};

  @override
  Future<void> save(Story story) async {
    _store[story.id] = story;
  }

  @override
  Future<Story?> findById(StoryId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(StoryId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(StoryId id) async {
    _store.remove(id);
  }

  @override
  Future<List<Story>> findByHeroId(HeroId heroId) async {
    return _store.values.where((story) => story.heroId == heroId).toList();
  }

  @override
  Future<List<Story>> findAll() async {
    return List.unmodifiable(_store.values);
  }

  @override
  Future<List<Story>> findPublished() async {
    return _store.values
        .where(
          (story) => story.lifecycleStatus == StoryLifecycleStatus.published,
        )
        .toList();
  }
}
