import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';

class InMemoryStoryBuilderSessionRepository
    implements StoryBuilderSessionRepository {
  final Map<StoryBuilderSessionId, StoryBuilderSession> _store = {};

  @override
  Future<void> save(StoryBuilderSession session) async {
    _store[session.id] = session;
  }

  @override
  Future<StoryBuilderSession?> findById(StoryBuilderSessionId id) async {
    return _store[id];
  }

  @override
  Future<bool> exists(StoryBuilderSessionId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<void> delete(StoryBuilderSessionId id) async {
    _store.remove(id);
  }

  @override
  Future<List<StoryBuilderSession>> findByHeroId(HeroId heroId) async {
    final matches = _store.values.where((s) => s.heroId == heroId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(matches);
  }

  @override
  Future<List<StoryBuilderSession>> findResumableByHeroId(HeroId heroId) async {
    final matches = _store.values
        .where(
          (s) =>
              s.heroId == heroId &&
              (s.status == StoryBuilderSessionStatus.inProgress ||
                  s.status == StoryBuilderSessionStatus.paused),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(matches);
  }

  @override
  Future<List<StoryBuilderSession>> findByHeroIdAndStatus(
    HeroId heroId,
    StoryBuilderSessionStatus status,
  ) async {
    final matches = _store.values
        .where((s) => s.heroId == heroId && s.status == status)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(matches);
  }
}
