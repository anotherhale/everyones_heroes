import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/captured_story_reading_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/captured_story_reading_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/captured_story_reading.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/captured_story_reading_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [CapturedStoryReadingRepository] (HS.12.3).
///
/// Files under `{root}/captured_story_readings/{id}.json`.
/// Latest-per-story index under `{root}/captured_story_readings/_by_story.json`.
final class FileCapturedStoryReadingRepository
    implements CapturedStoryReadingRepository {
  FileCapturedStoryReadingRepository({required Directory rootDirectory})
      : _readingsDirectory = Directory(
          p.join(rootDirectory.path, 'captured_story_readings'),
        );

  final Directory _readingsDirectory;
  final Map<CapturedStoryReadingId, CapturedStoryReading> _cache = {};
  final Map<StoryId, CapturedStoryReadingId> _latestByStory = {};
  bool _loaded = false;

  File get _indexFile =>
      File(p.join(_readingsDirectory.path, '_by_story.json'));

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _readingsDirectory.exists()) {
      await _readingsDirectory.create(recursive: true);
    }

    await for (final entity in _readingsDirectory.list()) {
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
          'Corrupt CapturedStoryReading file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt CapturedStoryReading file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final reading = CapturedStoryReadingSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[reading.id] = reading;
    }

    if (await _indexFile.exists()) {
      final indexRaw = await _indexFile.readAsString();
      final decoded = jsonDecode(indexRaw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          _latestByStory[StoryId(entry.key as String)] =
              CapturedStoryReadingId(entry.value as String);
        }
      }
    } else {
      for (final reading in _cache.values) {
        final existing = _latestByStory[reading.storyId];
        if (existing == null) {
          _latestByStory[reading.storyId] = reading.id;
          continue;
        }
        final prior = _cache[existing];
        if (prior == null || reading.createdAt.isAfter(prior.createdAt)) {
          _latestByStory[reading.storyId] = reading.id;
        }
      }
    }

    _loaded = true;
  }

  File _fileFor(CapturedStoryReadingId id) =>
      File(p.join(_readingsDirectory.path, '${id.value}.json'));

  Future<void> _persistIndex() async {
    final map = <String, String>{
      for (final entry in _latestByStory.entries)
        entry.key.value: entry.value.value,
    };
    await _indexFile.writeAsString(jsonEncode(map), flush: true);
  }

  @override
  Future<void> save(CapturedStoryReading reading) async {
    await _ensureLoaded();
    if (!await _readingsDirectory.exists()) {
      await _readingsDirectory.create(recursive: true);
    }
    final file = _fileFor(reading.id);
    await file.writeAsString(
      jsonEncode(CapturedStoryReadingSnapshotMapper.toJson(reading)),
      flush: true,
    );
    _cache[reading.id] = reading;
    _latestByStory[reading.storyId] = reading.id;
    await _persistIndex();
  }

  @override
  Future<CapturedStoryReading?> findById(CapturedStoryReadingId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<CapturedStoryReading?> findByStoryId(StoryId storyId) async {
    await _ensureLoaded();
    final id = _latestByStory[storyId];
    if (id == null) {
      return null;
    }
    return _cache[id];
  }

  @override
  Future<void> delete(CapturedStoryReadingId id) async {
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
