import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_builder_session_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [StoryBuilderSessionRepository] with lazy in-memory cache (SB.5).
///
/// Mirrors [FileStoryRepository] / [FileHeroRepository] conventions:
/// - Files under `{root}/story_builder_sessions/{id}.json`
/// - `writeAsString(..., flush: true)` (best-effort durability; no temp+rename)
/// - Missing [findById] returns `null`
/// - Malformed JSON throws [FormatException] during load (no partial session)
final class FileStoryBuilderSessionRepository
    implements StoryBuilderSessionRepository {
  FileStoryBuilderSessionRepository({required Directory rootDirectory})
    : _sessionsDirectory = Directory(
        p.join(rootDirectory.path, 'story_builder_sessions'),
      );

  final Directory _sessionsDirectory;
  final Map<StoryBuilderSessionId, StoryBuilderSession> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _sessionsDirectory.exists()) {
      await _sessionsDirectory.create(recursive: true);
    }

    await for (final entity in _sessionsDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      final raw = await entity.readAsString();
      late final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException catch (e) {
        throw FormatException(
          'Corrupt Story Builder session file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt Story Builder session file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final session = StoryBuilderSessionSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[session.id] = session;
    }

    _loaded = true;
  }

  File _fileFor(StoryBuilderSessionId id) =>
      File(p.join(_sessionsDirectory.path, '${id.value}.json'));

  @override
  Future<void> save(StoryBuilderSession session) async {
    await _ensureLoaded();
    if (!await _sessionsDirectory.exists()) {
      await _sessionsDirectory.create(recursive: true);
    }
    final file = _fileFor(session.id);
    await file.writeAsString(
      jsonEncode(StoryBuilderSessionSnapshotMapper.toJson(session)),
      flush: true,
    );
    _cache[session.id] = session;
  }

  @override
  Future<StoryBuilderSession?> findById(StoryBuilderSessionId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<bool> exists(StoryBuilderSessionId id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  @override
  Future<void> delete(StoryBuilderSessionId id) async {
    await _ensureLoaded();
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
    _cache.remove(id);
  }

  @override
  Future<List<StoryBuilderSession>> findByHeroId(HeroId heroId) async {
    await _ensureLoaded();
    final matches = _cache.values.where((s) => s.heroId == heroId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(matches);
  }

  @override
  Future<List<StoryBuilderSession>> findResumableByHeroId(HeroId heroId) async {
    await _ensureLoaded();
    final matches = _cache.values
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
    await _ensureLoaded();
    final matches = _cache.values
        .where((s) => s.heroId == heroId && s.status == status)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(matches);
  }
}
