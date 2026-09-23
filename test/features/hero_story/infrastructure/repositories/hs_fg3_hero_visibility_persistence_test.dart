import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FileHeroRepository repository;
  late ChangeHeroVisibilityUseCase useCase;
  late HeroId heroId;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('eh-fg3-hero-visibility-');
    repository = FileHeroRepository(rootDirectory: tempDir);
    useCase = ChangeHeroVisibilityUseCase(heroRepository: repository);
    heroId = HeroId('fg3-hero');
    await repository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Persist Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
        createdAt: DateTime.utc(2026, 9, 22),
      ),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('private → discoverable → reload → discoverable', () async {
    final changed = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );
    expect(changed, isA<Success<Hero>>());

    final reloaded = FileHeroRepository(rootDirectory: tempDir);
    final hero = await reloaded.findById(heroId);
    expect(hero, isNotNull);
    expect(hero!.visibility, HeroVisibility.public);
  });

  test('discoverable → private → reload → private', () async {
    await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );

    final changed = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.private,
      ),
    );
    expect(changed, isA<Success<Hero>>());

    final reloaded = FileHeroRepository(rootDirectory: tempDir);
    final hero = await reloaded.findById(heroId);
    expect(hero, isNotNull);
    expect(hero!.visibility, HeroVisibility.private);
  });
}
