import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late FileHeroRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-file-hero-repo-');
    repository = FileHeroRepository(rootDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Hero buildHero(String id, {String name = 'Hero'}) {
    return Hero(
      id: HeroId(id),
      profile: HeroProfile(
        displayName: name,
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.public,
      createdAt: DateTime.utc(2024, 1, 1),
    );
  }

  test('save writes json file and findById returns hero', () async {
    final hero = buildHero('hero-a', name: 'Alpha');
    await repository.save(hero);

    final file = File(p.join(tempDir.path, 'heroes', 'hero-a.json'));
    expect(file.existsSync(), isTrue);

    final loaded = await repository.findById(const HeroId('hero-a'));
    expect(loaded, isNotNull);
    expect(loaded!.profile.displayName, 'Alpha');
    expect(await repository.exists(const HeroId('hero-a')), isTrue);
  });

  test('findAll returns saved heroes and survives process restart', () async {
    await repository.save(buildHero('h1', name: 'One'));
    await repository.save(buildHero('h2', name: 'Two'));

    final first = await repository.findAll();
    expect(first.map((h) => h.id.value), unorderedEquals(['h1', 'h2']));

    final restarted = FileHeroRepository(rootDirectory: tempDir);
    final second = await restarted.findAll();
    expect(second.map((h) => h.profile.displayName), unorderedEquals(['One', 'Two']));
  });

  test('delete removes file and cache entry', () async {
    await repository.save(buildHero('hero-del'));
    await repository.delete(const HeroId('hero-del'));

    expect(await repository.findById(const HeroId('hero-del')), isNull);
    expect(
      File(p.join(tempDir.path, 'heroes', 'hero-del.json')).existsSync(),
      isFalse,
    );
  });
}
