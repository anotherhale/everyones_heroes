import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/hero_snapshot_mapper.dart';
import 'package:path/path.dart' as p;

/// File-backed [HeroRepository] with lazy in-memory cache (HS.9).
final class FileHeroRepository implements HeroRepository {
  FileHeroRepository({required Directory rootDirectory})
    : _heroesDirectory = Directory(p.join(rootDirectory.path, 'heroes'));

  final Directory _heroesDirectory;
  final Map<HeroId, Hero> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    if (!await _heroesDirectory.exists()) {
      await _heroesDirectory.create(recursive: true);
    }

    await for (final entity in _heroesDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      final json =
          jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
      final hero = HeroSnapshotMapper.fromJson(json);
      _cache[hero.id] = hero;
    }

    _loaded = true;
  }

  File _fileFor(HeroId id) =>
      File(p.join(_heroesDirectory.path, '${id.value}.json'));

  @override
  Future<void> save(Hero hero) async {
    await _ensureLoaded();
    if (!await _heroesDirectory.exists()) {
      await _heroesDirectory.create(recursive: true);
    }
    final file = _fileFor(hero.id);
    await file.writeAsString(
      jsonEncode(HeroSnapshotMapper.toJson(hero)),
      flush: true,
    );
    _cache[hero.id] = hero;
  }

  @override
  Future<Hero?> findById(HeroId id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  @override
  Future<bool> exists(HeroId id) async {
    await _ensureLoaded();
    return _cache.containsKey(id);
  }

  @override
  Future<void> delete(HeroId id) async {
    await _ensureLoaded();
    final file = _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
    _cache.remove(id);
  }

  @override
  Future<List<Hero>> findAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache.values);
  }
}
