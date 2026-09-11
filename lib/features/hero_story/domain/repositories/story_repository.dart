import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';

abstract interface class StoryRepository {
  Future<void> save(Story story);

  Future<Story?> findById(StoryId id);

  Future<bool> exists(StoryId id);

  Future<void> delete(StoryId id);

  Future<List<Story>> findByHeroId(HeroId heroId);

  Future<List<Story>> findAll();

  Future<List<Story>> findPublished();
}
