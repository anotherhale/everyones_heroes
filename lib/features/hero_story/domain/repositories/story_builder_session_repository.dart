import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';

abstract interface class StoryBuilderSessionRepository {
  Future<void> save(StoryBuilderSession session);

  Future<StoryBuilderSession?> findById(StoryBuilderSessionId id);

  Future<bool> exists(StoryBuilderSessionId id);

  Future<void> delete(StoryBuilderSessionId id);

  Future<List<StoryBuilderSession>> findByHeroId(HeroId heroId);

  /// In-progress or paused sessions for a Hero (resume candidates).
  Future<List<StoryBuilderSession>> findResumableByHeroId(HeroId heroId);

  Future<List<StoryBuilderSession>> findByHeroIdAndStatus(
    HeroId heroId,
    StoryBuilderSessionStatus status,
  );
}
