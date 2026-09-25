import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/music_rendering_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/music_rendering_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/music_rendering.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/music_rendering_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [MusicRenderingRepository] (Experiment A).
///
/// Files under `{root}/music_renderings/{id}.json`.
/// Latest-per-story index under `{root}/music_renderings/_by_story.json`.
final class FileMusicRenderingRepository implements MusicRenderingRepository {
  FileMusicRenderingRepository({required Directory rootDirectory})
      : _renderingsDirectory = Directory(
          p.join(rootDirectory.path, 'music_renderings'),
        );

  final Directory _renderingsDirectory;
  final Map<MusicRenderingId, MusicRendering> _cache = {};
  final Map<StoryId, MusicRenderingId> _latestByStory = {};
  bool _loaded = false;

  File get _indexFile =>
      File(p.join(_renderingsDirectory.path, '_by_story.json'));

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _renderingsDirectory.exists()) {
      await _renderingsDirectory.create(recursive: true);
    }

    await for (final entity in _renderingsDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      if (p.basename(entity.path) == '_by_story.json') {
        continue;
      }

      final raw = await entity.readAsString();
      late final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException catch (e) {
        throw FormatException(
          'Corrupt MusicRendering file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt MusicRendering file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final rendering = MusicRenderingSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[rendering.id] = rendering;
    }

    if (await _indexFile.exists()) {
      final indexRaw = await _indexFile.readAsString();
      final decoded = jsonDecode(indexRaw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _latestByStory[StoryId(entry.key as String)] =
              MusicRenderingId(entry.value as String);
        }
      }
    } else {
      for (final rendering in _cache.values) {
        final existing = _latestByStory[rendering.storyId];
        if (existing == null) {
          _latestByStory[rendering.storyId] = rendering.id;
          continue;
        }
        final prior = _cache[existing];
        if (prior == null || rendering.createdAt.isAfter(prior.createdAt)) {
          _latestByStory[rendering.storyId] = rendering.id;
        }
      }
    }

    _loaded = true;
  }

  File _fileFor(MusicRenderingId id) =>
      File(p.join(_renderingsDirectory.path, '${id.value}.json'));

  Future<void> _persistIndex() async {
    final map = <String, String>{
      for (final entry in _latestByStory.entries)
        entry.key.value: entry.value.value,
    };
    await _indexFile.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  Future<void> save(MusicRendering rendering) async {
    await _ensureLoaded();
    if (!await _renderingsDirectory.exists()) {
      await _renderingsDirectory.create(recursive: true);
    }

    // Regeneration replaces the latest-per-story pointer with a new id.
    // Prior artifact files are removed so invalid/stale audio is not exposed.
    final previousId = _latestByStory[rendering.storyId];
    if (previousId != null && previousId != rendering.id) {
      _cache.remove(previousId);
      final previousFile = _fileFor(previousId);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final file = _fileFor(rendering.id);
    await file.writeAsString(
      jsonEncode(MusicRenderingSnapshotMapper.toJson(rendering)),
      flush: true,
    );
    _cache[rendering.id] = rendering;
    _latestByStory[rendering.storyId] = rendering.id;
    await _persistIndex();
  }

  @override
  Future<MusicRendering?> findById(MusicRenderingId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<MusicRendering?> findByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _cache[id];
  }

  @override
  Future<void> delete(MusicRenderingId id) async {
    await _ensureLoaded();
    final existing = _cache.remove(id);
    if (existing != null && _latestByStory[existing.storyId] == id) {
      _latestByStory.remove(existing.storyId);
      await _persistIndex();
    }
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory.remove(storyId);
    if (id != null) {
      _cache.remove(id);
      final file = _fileFor(id);
      if (await file.exists()) {
        await file.delete();
      }
      await _persistIndex();
    }
  }
}
