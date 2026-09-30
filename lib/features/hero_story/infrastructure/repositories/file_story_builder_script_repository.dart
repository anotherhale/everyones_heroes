import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_script_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_script.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_builder_script_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [StoryBuilderScriptRepository] (SB.8).
///
/// Files under `{root}/story_builder_scripts/{id}.json`.
final class FileStoryBuilderScriptRepository
    implements StoryBuilderScriptRepository {
  FileStoryBuilderScriptRepository({required Directory rootDirectory})
      : _scriptsDirectory = Directory(
          p.join(rootDirectory.path, 'story_builder_scripts'),
        );

  final Directory _scriptsDirectory;
  final Map<StoryBuilderScriptId, StoryBuilderScript> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    if (!await _scriptsDirectory.exists()) {
      await _scriptsDirectory.create(recursive: true);
    }

    await for (final entity in _scriptsDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;

      final raw = await entity.readAsString();
      late final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException catch (e) {
        throw FormatException(
          'Corrupt Story Builder script file ${entity.path}: $e',
        );
      }

      if (decoded is! Map) {
        throw FormatException(
          'Corrupt Story Builder script file ${entity.path}: '
          'expected JSON object.',
        );
      }

      final script = StoryBuilderScriptSnapshotMapper.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      _cache[script.id] = script;
    }

    _loaded = true;
  }

  File _fileFor(StoryBuilderScriptId id) =>
      File(p.join(_scriptsDirectory.path, '${id.value}.json'));

  @override
  Future<void> save(StoryBuilderScript script) async {
    await _ensureLoaded();
    if (!await _scriptsDirectory.exists()) {
      await _scriptsDirectory.create(recursive: true);
    }
    final file = _fileFor(script.id);
    await file.writeAsString(
      jsonEncode(StoryBuilderScriptSnapshotMapper.toJson(script)),
      flush: true,
    );
    _cache[script.id] = script;
  }

  @override
  Future<StoryBuilderScript?> findById(StoryBuilderScriptId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<bool> exists(StoryBuilderScriptId id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  @override
  Future<void> delete(StoryBuilderScriptId id) async {
    await _ensureLoaded();
    _cache.remove(id);
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<StoryBuilderScript>> findBySessionId(
    StoryBuilderSessionId sessionId,
  ) async {
    await _ensureLoaded();
    final matches = _cache.values
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
}
