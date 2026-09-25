import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/experience_render_manifest_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest.dart';
import 'package:everyonesheroes/features/hero_story/application/lab/experience_render_manifest_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/experience_render_manifest_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [ExperienceRenderManifestRepository] (Experiment A).
///
/// Files under `{root}/experience_render_manifests/{id}.json`.
/// Latest-per-story index under
/// `{root}/experience_render_manifests/_by_story.json`.
final class FileExperienceRenderManifestRepository
    implements ExperienceRenderManifestRepository {
  FileExperienceRenderManifestRepository({required Directory rootDirectory})
      : _manifestsDirectory = Directory(
          p.join(rootDirectory.path, 'experience_render_manifests'),
        );

  final Directory _manifestsDirectory;
  final Map<ExperienceRenderManifestId, ExperienceRenderManifest> _cache = {};
  final Map<StoryId, ExperienceRenderManifestId> _latestByStory = {};
  bool _loaded = false;

  File get _indexFile =>
      File(p.join(_manifestsDirectory.path, '_by_story.json'));

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _manifestsDirectory.exists()) {
      await _manifestsDirectory.create(recursive: true);
    }

    await for (final entity in _manifestsDirectory.list()) {
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
          'Corrupt ExperienceRenderManifest file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt ExperienceRenderManifest file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final manifest = ExperienceRenderManifestSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[manifest.id] = manifest;
    }

    if (await _indexFile.exists()) {
      final indexRaw = await _indexFile.readAsString();
      final decoded = jsonDecode(indexRaw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _latestByStory[StoryId(entry.key as String)] =
              ExperienceRenderManifestId(entry.value as String);
        }
      }
    } else {
      for (final manifest in _cache.values) {
        final existing = _latestByStory[manifest.storyId];
        if (existing == null) {
          _latestByStory[manifest.storyId] = manifest.id;
          continue;
        }
        final prior = _cache[existing];
        if (prior == null || manifest.createdAt.isAfter(prior.createdAt)) {
          _latestByStory[manifest.storyId] = manifest.id;
        }
      }
    }

    _loaded = true;
  }

  File _fileFor(ExperienceRenderManifestId id) =>
      File(p.join(_manifestsDirectory.path, '${id.value}.json'));

  Future<void> _persistIndex() async {
    final map = <String, String>{
      for (final entry in _latestByStory.entries)
        entry.key.value: entry.value.value,
    };
    await _indexFile.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  Future<void> save(ExperienceRenderManifest manifest) async {
    await _ensureLoaded();
    if (!await _manifestsDirectory.exists()) {
      await _manifestsDirectory.create(recursive: true);
    }

    // Regeneration replaces the latest-per-story pointer with a new id.
    final previousId = _latestByStory[manifest.storyId];
    if (previousId != null && previousId != manifest.id) {
      _cache.remove(previousId);
      final previousFile = _fileFor(previousId);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final file = _fileFor(manifest.id);
    await file.writeAsString(
      jsonEncode(ExperienceRenderManifestSnapshotMapper.toJson(manifest)),
      flush: true,
    );
    _cache[manifest.id] = manifest;
    _latestByStory[manifest.storyId] = manifest.id;
    await _persistIndex();
  }

  @override
  Future<ExperienceRenderManifest?> findById(
    ExperienceRenderManifestId id,
  ) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<ExperienceRenderManifest?> findByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _cache[id];
  }

  @override
  Future<void> delete(ExperienceRenderManifestId id) async {
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
