import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/get_my_hero_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_hero_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/get_my_hero_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_hero_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/hero_profile_updated.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryEventStore eventStore;
  late GetMyHeroUseCase getMyHero;
  late UpdateHeroProfileUseCase updateProfile;
  late HeroId heroId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    eventStore = InMemoryEventStore();
    final eventBus = InMemoryEventBus(
      eventStore: eventStore,
      dispatcher: InMemoryEventDispatcher(),
    );
    getMyHero = GetMyHeroUseCase(heroRepository: heroRepository);
    updateProfile = UpdateHeroProfileUseCase(
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    heroId = HeroId.generate();
    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Local Owner',
          biography: 'Starting biography',
          experienceAreas: const ['Military'],
          languages: [LanguageCode('en')],
          geographicContext: 'Midwest',
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  group('GetMyHeroUseCase', () {
    test('active owner can retrieve their Hero without discoverability',
        () async {
      final result = await getMyHero.execute(GetMyHeroRequest(heroId: heroId));

      expect(result, isA<Success<Hero>>());
      final hero = (result as Success<Hero>).value;
      expect(hero.id, heroId);
      expect(hero.profile.displayName, 'Local Owner');
      expect(hero.visibility, HeroVisibility.private);
    });

    test('missing hero returns failure', () async {
      final result = await getMyHero.execute(
        GetMyHeroRequest(heroId: HeroId.generate()),
      );

      expect(result, isA<Failure<Hero>>());
      expect((result as Failure<Hero>).error, contains('Hero not found'));
    });
  });

  group('UpdateHeroProfileUseCase', () {
    test('owner can update HeroProfile and persist', () async {
      final updated = HeroProfile(
        displayName: 'Updated Name',
        biography: 'New biography',
        experienceAreas: const ['Parenting', 'Leadership'],
        languages: [LanguageCode('en'), LanguageCode('es')],
        geographicContext: 'Pacific Northwest',
      );

      final result = await updateProfile.execute(
        UpdateHeroProfileRequest(heroId: heroId, profile: updated),
      );

      expect(result, isA<Success<Hero>>());
      final hero = (result as Success<Hero>).value;
      expect(hero.profile.displayName, 'Updated Name');
      expect(hero.profile.biography, 'New biography');
      expect(hero.profile.experienceAreas, ['Parenting', 'Leadership']);
      expect(
        hero.profile.languages.map((l) => l.value),
        ['en', 'es'],
      );
      expect(hero.profile.geographicContext, 'Pacific Northwest');

      final reloaded = await heroRepository.findById(heroId);
      expect(reloaded!.profile.displayName, 'Updated Name');
      expect(reloaded.profile.geographicContext, 'Pacific Northwest');
    });

    test('owner can update a private Hero', () async {
      final result = await updateProfile.execute(
        UpdateHeroProfileRequest(
          heroId: heroId,
          profile: HeroProfile(
            displayName: 'Still Private',
            languages: [LanguageCode('en')],
          ),
        ),
      );

      expect(result, isA<Success<Hero>>());
      final stored = await heroRepository.findById(heroId);
      expect(stored!.visibility, HeroVisibility.private);
      expect(stored.profile.displayName, 'Still Private');
    });

    test('publishes HeroProfileUpdated', () async {
      await updateProfile.execute(
        UpdateHeroProfileRequest(
          heroId: heroId,
          profile: HeroProfile(
            displayName: 'Event Name',
            languages: [LanguageCode('en')],
          ),
        ),
      );

      final events = await eventStore.allEvents();
      expect(events.any((e) => e.event is HeroProfileUpdated), isTrue);
    });

    test('invalid profile values are rejected by HeroProfile rules', () {
      expect(
        () => HeroProfile(displayName: '   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => HeroProfile(displayName: 'a' * 201),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => HeroProfile(
          displayName: 'Valid',
          biography: 'b' * 5001,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('missing hero returns failure', () async {
      final result = await updateProfile.execute(
        UpdateHeroProfileRequest(
          heroId: HeroId.generate(),
          profile: HeroProfile(
            displayName: 'Ghost',
            languages: [LanguageCode('en')],
          ),
        ),
      );

      expect(result, isA<Failure<Hero>>());
      expect((result as Failure<Hero>).error, contains('Hero not found'));
    });
  });
}
