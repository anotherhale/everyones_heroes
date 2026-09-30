import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';

final class InMemoryStoryBuilderScriptRepository
    implements StoryBuilderScriptRepository {
  final Map<StoryBuilderScriptId, StoryBuilderScript> _byId = {};

  @override
  Future<void> save(StoryBuilderScript script) async {
    _byId[script.id] = script;
  }

  @override
  Future<StoryBuilderScript?> findById(StoryBuilderScriptId id) async {
    return _byId[id];
  }

  @override
  Future<bool> exists(StoryBuilderScriptId id) async {
    return _byId.containsKey(id);
  }

  @override
  Future<void> delete(StoryBuilderScriptId id) async {
    _byId.remove(id);
  }

  @override
  Future<List<StoryBuilderScript>> findBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    final matches = _byId.values
        .where((s) => s.sourceStoryBuilderSessionId == sessionId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matches);
  }

  @override
  Future<StoryBuilderScript?> findLatestBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    final matches = await findBySessionId(sessionId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<StoryBuilderScript?> findLatestApprovedBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    final matches = (await findBySessionId(sessionId))
        .where((s) => s.status == StoryBuilderScriptStatus.approved)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  void clear() => _byId.clear();
}
