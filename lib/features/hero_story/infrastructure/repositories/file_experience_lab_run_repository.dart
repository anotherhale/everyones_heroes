import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/experience_lab_run_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/experience_lab_run_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/experience_lab_run.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/experience_lab_run_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [ExperienceLabRunRepository] (Experiment A).
///
/// Files under `{root}/experience_lab_runs/{id}.json`.
/// Latest-per-story index under `{root}/experience_lab_runs/_by_story.json`.
final class FileExperienceLabRunRepository
    implements ExperienceLabRunRepository {
  FileExperienceLabRunRepository({required Directory rootDirectory})
      : _runsDirectory = Directory(
          p.join(rootDirectory.path, 'experience_lab_runs'),
        );

  final Directory _runsDirectory;
  final Map<ExperienceLabRunId, ExperienceLabRun> _cache = {};
  final Map<StoryId, ExperienceLabRunId> _latestByStory = {};
  bool _loaded = false;

  File get _indexFile => File(p.join(_runsDirectory.path, '_by_story.json'));

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _runsDirectory.exists()) {
      await _runsDirectory.create(recursive: true);
    }

    await for (final entity in _runsDirectory.list()) {
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
          'Corrupt ExperienceLabRun file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt ExperienceLabRun file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final run = ExperienceLabRunSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[run.id] = run;
    }

    if (await _indexFile.exists()) {
      final indexRaw = await _indexFile.readAsString();
      final decoded = jsonDecode(indexRaw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _latestByStory[StoryId(entry.key as String)] =
              ExperienceLabRunId(entry.value as String);
        }
      }
    } else {
      for (final run in _cache.values) {
        final existing = _latestByStory[run.storyId];
        if (existing == null) {
          _latestByStory[run.storyId] = run.id;
          continue;
        }
        final prior = _cache[existing];
        if (prior == null || run.createdAt.isAfter(prior.createdAt)) {
          _latestByStory[run.storyId] = run.id;
        }
      }
    }

    _loaded = true;
  }

  File _fileFor(ExperienceLabRunId id) =>
      File(p.join(_runsDirectory.path, '${id.value}.json'));

  Future<void> _persistIndex() async {
    final map = <String, String>{
      for (final entry in _latestByStory.entries)
        entry.key.value: entry.value.value,
    };
    await _indexFile.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  Future<void> save(ExperienceLabRun run) async {
    await _ensureLoaded();
    if (!await _runsDirectory.exists()) {
      await _runsDirectory.create(recursive: true);
    }

    // Regeneration replaces the latest-per-story pointer with a new id.
    final previousId = _latestByStory[run.storyId];
    if (previousId != null && previousId != run.id) {
      _cache.remove(previousId);
      final previousFile = _fileFor(previousId);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final file = _fileFor(run.id);
    await file.writeAsString(
      jsonEncode(ExperienceLabRunSnapshotMapper.toJson(run)),
      flush: true,
    );
    _cache[run.id] = run;
    _latestByStory[run.storyId] = run.id;
    await _persistIndex();
  }

  @override
  Future<ExperienceLabRun?> findById(ExperienceLabRunId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<ExperienceLabRun?> findByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _cache[id];
  }

  @override
  Future<void> delete(ExperienceLabRunId id) async {
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
