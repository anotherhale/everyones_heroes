import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [StoryRepository] with lazy in-memory cache (HS.9).
final class FileStoryRepository implements StoryRepository {
  FileStoryRepository({required Directory rootDirectory})
    : _storiesDirectory = Directory(p.join(rootDirectory.path, 'stories'));

  final Directory _storiesDirectory;
  final Map<StoryId, Story> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _storiesDirectory.exists()) {
      await _storiesDirectory.create(recursive: true);
    }

    await for (final entity in _storiesDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      final json =
          jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
      final story = StorySnapshotMapper.fromJson(json);
      _cache[story.id] = story;
    }

    _loaded = true;
  }

  File _fileFor(StoryId id) =>
      File(p.join(_storiesDirectory.path, '${id.value}.json'));

  @override
  Future<void> save(Story story) async {
    await _ensureLoaded();
    if (!await _storiesDirectory.exists()) {
      await _storiesDirectory.create(recursive: true);
    }
    final file = _fileFor(story.id);
    await file.writeAsString(
      jsonEncode(StorySnapshotMapper.toJson(story)),
      flush: true,
    );
    _cache[story.id] = story;
  }

  @override
  Future<Story?> findById(StoryId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<bool> exists(StoryId id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  @override
  Future<void> delete(StoryId id) async {
    await _ensureLoaded();
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
    _cache.remove(id);
  }

  @override
  Future<List<Story>> findByHeroId(HeroId heroId) async {
    await _ensureLoaded();
    return _cache.values.where((story) => story.heroId == heroId).toList();
  }

  @override
  Future<List<Story>> findAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache.values);
  }

  @override
  Future<List<Story>> findPublished() async {
    await _ensureLoaded();
    return _cache.values
        .where(
          (story) => story.lifecycleStatus == StoryLifecycleStatus.published,
        )
        .toList();
  }
}
