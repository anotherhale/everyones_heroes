import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/change_hero_visibility_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/change_hero_visibility_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late ChangeHeroVisibilityUseCase useCase;
  late HeroId heroId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    useCase = ChangeHeroVisibilityUseCase(heroRepository: heroRepository);
    heroId = HeroId.generate();
    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Owner Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  test('owner can change visibility to public', () async {
    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );

    expect(result, isA<Success<Hero>>());
    expect((result as Success<Hero>).value.visibility, HeroVisibility.public);
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.public,
    );
  });

  test('owner can change visibility back to private', () async {
    await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );

    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.private,
      ),
    );

    expect(result, isA<Success<Hero>>());
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });

  test('non-owner cannot change another hero visibility', () async {
    final otherOwner = HeroId.generate();

    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: otherOwner,
        visibility: HeroVisibility.public,
      ),
    );

    expect(result, isA<Failure<Hero>>());
    expect((result as Failure<Hero>).error, contains('Not authorized'));
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });

  test('same visibility is a no-op success', () async {
    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.private,
      ),
    );

    expect(result, isA<Success<Hero>>());
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });

  test('missing hero returns failure', () async {
    final missing = HeroId.generate();
    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: missing,
        ownerHeroId: missing,
        visibility: HeroVisibility.public,
      ),
    );

    expect(result, isA<Failure<Hero>>());
    expect((result as Failure<Hero>).error, contains('Hero not found'));
  });

  test('archived hero change fails and preserves visibility', () async {
    final hero = (await heroRepository.findById(heroId))!;
    hero.archive();
    await heroRepository.save(hero);

    final result = await useCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );

    expect(result, isA<Failure<Hero>>());
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });

  test('persistence failure restores prior visibility', () async {
    final failing = _FailingSaveHeroRepository(delegate: heroRepository);
    final failingUseCase = ChangeHeroVisibilityUseCase(
      heroRepository: failing,
    );

    final result = await failingUseCase.execute(
      ChangeHeroVisibilityRequest(
        heroId: heroId,
        ownerHeroId: heroId,
        visibility: HeroVisibility.public,
      ),
    );

    expect(result, isA<Failure<Hero>>());
    expect(
      (await heroRepository.findById(heroId))!.visibility,
      HeroVisibility.private,
    );
  });
}

final class _FailingSaveHeroRepository implements HeroRepository {
  _FailingSaveHeroRepository({required this.delegate});

  final HeroRepository delegate;

  @override
  Future<void> save(Hero hero) async {
    throw StateError('simulated save failure');
  }

  @override
  Future<Hero?> findById(HeroId id) => delegate.findById(id);

  @override
  Future<bool> exists(HeroId id) => delegate.exists(id);

  @override
  Future<void> delete(HeroId id) => delegate.delete(id);

  @override
  Future<List<Hero>> findAll() => delegate.findAll();
}
