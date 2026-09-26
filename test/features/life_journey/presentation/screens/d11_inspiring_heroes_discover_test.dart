import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/providers/current_local_user_id_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/search/story_search_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hero_story;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_profile_screen.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/discover_screen.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;
  final userId = UserId('dev-user');

  ProviderScope buildSubject() {
    return ProviderScope(
      overrides: [
        currentLocalUserIdProvider.overrideWithValue(userId),
        discoveryProfileRepositoryProvider.overrideWithValue(profileRepository),
        influenceRepositoryProvider.overrideWithValue(
          InMemoryInfluenceRepository.withReferenceCatalog(),
        ),
        heroRepositoryProvider.overrideWithValue(heroes),
        storyRepositoryProvider.overrideWithValue(stories),
        storySearchPortProvider.overrideWithValue(
          InMemoryStorySearchAdapter(stories),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: DiscoverScreen()),
      ),
    );
  }

  setUp(() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
  });

  testWidgets(
    'Heroes Who Inspire Me lists discoverable Heroes and supports remove',
    (tester) async {
      final publicHero = hero_story.Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Public Hero',
          biography: 'Lived courage.',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      );
      final privateHero = hero_story.Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Private Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      );
      await heroes.save(publicHero);
      await heroes.save(privateHero);

      final missingId = HeroId('unresolved-hero');
      await profileRepository.save(
        DiscoveryProfile(
          id: DiscoveryProfileId.generate(),
          userId: userId,
          inspiringHeroIds: [publicHero.id, privateHero.id, missingId],
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inspiring-heroes-heading')), findsOneWidget);
      expect(
        find.byKey(Key('inspiring-hero-tile-${publicHero.id.value}')),
        findsOneWidget,
      );
      expect(find.text('Public Hero'), findsOneWidget);
      expect(find.text('Private Hero'), findsNothing);

      // Profile still retains unresolved / undiscoverable IDs.
      final profile = await profileRepository.findByUserId(userId);
      expect(profile!.inspiringHeroIds, hasLength(3));

      await tester.tap(
        find.byKey(Key('remove-inspiring-hero-${publicHero.id.value}')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('inspiring-hero-tile-${publicHero.id.value}')),
        findsNothing,
      );
      final after = await profileRepository.findByUserId(userId);
      expect(after!.containsInspiringHero(publicHero.id), isFalse);
      expect(after.containsInspiringHero(privateHero.id), isTrue);
      expect(after.containsInspiringHero(missingId), isTrue);
    },
  );

  testWidgets('tapping inspiring Hero opens Hero profile', (tester) async {
    final publicHero = hero_story.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Navigate Hero',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.public,
    );
    await heroes.save(publicHero);
    await profileRepository.save(
      DiscoveryProfile(
        id: DiscoveryProfileId.generate(),
        userId: userId,
        inspiringHeroIds: [publicHero.id],
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(Key('inspiring-hero-tile-${publicHero.id.value}')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroProfileScreen), findsOneWidget);
    expect(find.byKey(const Key('inspires-me-selected')), findsOneWidget);
  });
}
