import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_experience_plan_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [StoryExperiencePlanRepository] (HS.12.4).
///
/// Files under `{root}/story_experience_plans/{id}.json`.
/// Latest-per-story index under `{root}/story_experience_plans/_by_story.json`.
final class FileStoryExperiencePlanRepository
    implements StoryExperiencePlanRepository {
  FileStoryExperiencePlanRepository({required Directory rootDirectory})
      : _plansDirectory = Directory(
          p.join(rootDirectory.path, 'story_experience_plans'),
        );

  final Directory _plansDirectory;
  final Map<StoryExperiencePlanId, StoryExperiencePlan> _cache = {};
  final Map<StoryId, StoryExperiencePlanId> _latestByStory = {};
  bool _loaded = false;

  File get _indexFile =>
      File(p.join(_plansDirectory.path, '_by_story.json'));

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _plansDirectory.exists()) {
      await _plansDirectory.create(recursive: true);
    }

    await for (final entity in _plansDirectory.list()) {
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
          'Corrupt StoryExperiencePlan file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt StoryExperiencePlan file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final plan = StoryExperiencePlanSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[plan.id] = plan;
    }

    if (await _indexFile.exists()) {
      final indexRaw = await _indexFile.readAsString();
      final decoded = jsonDecode(indexRaw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _latestByStory[StoryId(entry.key as String)] =
              StoryExperiencePlanId(entry.value as String);
        }
      }
    } else {
      for (final plan in _cache.values) {
        final existing = _latestByStory[plan.storyId];
        if (existing == null) {
          _latestByStory[plan.storyId] = plan.id;
          continue;
        }
        final prior = _cache[existing];
        if (prior == null || plan.createdAt.isAfter(prior.createdAt)) {
          _latestByStory[plan.storyId] = plan.id;
        }
      }
    }

    _loaded = true;
  }

  File _fileFor(StoryExperiencePlanId id) =>
      File(p.join(_plansDirectory.path, '${id.value}.json'));

  Future<void> _persistIndex() async {
    final map = <String, String>{
      for (final entry in _latestByStory.entries)
        entry.key.value: entry.value.value,
    };
    await _indexFile.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  Future<void> save(StoryExperiencePlan plan) async {
    await _ensureLoaded();
    if (!await _plansDirectory.exists()) {
      await _plansDirectory.create(recursive: true);
    }

    // Regeneration replaces the latest-per-story pointer without mutating
    // Story or CapturedStoryReading. Prior plan files may remain for audit
    // until explicitly deleted; the index always points at the newest.
    final previousId = _latestByStory[plan.storyId];
    if (previousId != null && previousId != plan.id) {
      _cache.remove(previousId);
      final previousFile = _fileFor(previousId);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    final file = _fileFor(plan.id);
    await file.writeAsString(
      jsonEncode(StoryExperiencePlanSnapshotMapper.toJson(plan)),
      flush: true,
    );
    _cache[plan.id] = plan;
    _latestByStory[plan.storyId] = plan.id;
    await _persistIndex();
  }

  @override
  Future<StoryExperiencePlan?> findById(StoryExperiencePlanId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<StoryExperiencePlan?> findByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _cache[id];
  }

  @override
  Future<StoryExperiencePlan?> getByStoryId(StoryId storyId) =>
      findByStoryId(storyId);

  @override
  Future<void> delete(StoryExperiencePlanId id) async {
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
