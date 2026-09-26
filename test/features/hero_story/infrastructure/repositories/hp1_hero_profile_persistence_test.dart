import 'dart:io';

import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_hero_profile_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_hero_profile_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_hero_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FileHeroRepository repository;
  late UpdateHeroProfileUseCase updateProfile;
  late HeroId heroId;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('eh-hp1-hero-profile-');
    repository = FileHeroRepository(rootDirectory: tempDir);
    updateProfile = UpdateHeroProfileUseCase(
      heroRepository: repository,
      eventBus: InMemoryEventBus(
        eventStore: InMemoryEventStore(),
        dispatcher: InMemoryEventDispatcher(),
      ),
    );
    heroId = HeroId('owner-hero');
    await repository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Before',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('update → persist → reload → same HeroProfile', () async {
    final result = await updateProfile.execute(
      UpdateHeroProfileRequest(
        heroId: heroId,
        profile: HeroProfile(
          displayName: 'After Save',
          biography: 'Persisted biography',
          experienceAreas: const ['Service', 'Family'],
          languages: [LanguageCode('en'), LanguageCode('es')],
          geographicContext: 'Austin, TX',
        ),
      ),
    );

    expect(result, isA<Success<Hero>>());

    final restarted = FileHeroRepository(rootDirectory: tempDir);
    final loaded = await restarted.findById(heroId);
    expect(loaded, isNotNull);
    expect(loaded!.profile.displayName, 'After Save');
    expect(loaded.profile.biography, 'Persisted biography');
    expect(loaded.profile.experienceAreas, ['Service', 'Family']);
    expect(loaded.profile.languages.map((l) => l.value), ['en', 'es']);
    expect(loaded.profile.geographicContext, 'Austin, TX');
    expect(loaded.visibility, HeroVisibility.private);
  });
}
