import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';
import 'package:everyonesheroes/core/ids/influence_reference_ids.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/ids/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/discovery_profile_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/application/providers/repositories/influence_repository_provider.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_discovery_profile_repository.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_influence_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/search/story_search_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hero_story;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/discover_screen.dart';

void main() {
  late InMemoryDiscoveryProfileRepository profileRepository;
  late InMemoryHeroRepository heroes;
  late InMemoryStoryRepository stories;

  ProviderScope buildSubject() {
    profileRepository = InMemoryDiscoveryProfileRepository();
    heroes = InMemoryHeroRepository();
    stories = InMemoryStoryRepository();
    return ProviderScope(
      overrides: [
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

  Future<void> saveInfluence(WidgetTester tester, InfluenceId id) async {
    final tileKey = Key('influence-tile-${id.value}');
    await tester.scrollUntilVisible(
      find.byKey(tileKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(tileKey));
    await tester.pump();

    final saveButton = find.byKey(const Key('save-influences-button'));
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<Story> seedPublishedStory({
    required String title,
    required List<NarrativeThemeId> themes,
  }) async {
    final hero = hero_story.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Explore Hero',
        biography: 'Lived experience.',
        experienceAreas: const ['Service'],
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.public,
    );
    await heroes.save(hero);

    final story = Story.create(
      id: StoryId.generate(),
      heroId: hero.id,
      title: StoryTitle(title),
      narrative: StoryNarrative('Narrative for $title.'),
      originalLanguage: LanguageCode('en'),
    );
    story.classify(StoryClassification(narrativeThemeIds: themes));
    story.updateConsent(
      story.consent
          .grantProcessing(DateTime.utc(2026, 1, 1))
          .grantPublication(DateTime.utc(2026, 1, 1)),
    );
    story
      ..submit()
      ..markReadyForReview()
      ..approve()
      ..changeVisibility(StoryVisibility.public)
      ..publish();
    await stories.save(story);
    return story;
  }

  group('DiscoverScreen D.7 inspiration-grounded Story exploration', () {
    testWidgets(
      'empty Inspirations shows choose-inspirations empty state',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('Discover'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(const Key('explore-stories-heading')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Explore Stories'), findsOneWidget);
        expect(
          find.text('Stories connected to your inspirations'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('explore-stories-empty-no-inspirations')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Choose a few inspirations to discover related Stories.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'selecting an Inspiration surfaces matching Stories with provenance',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final story = await seedPublishedStory(
          title: 'Keep Climbing',
          themes: [NarrativeThemeReferenceIds.perseverance],
        );

        await saveInfluence(tester, InfluenceReferenceIds.rockyBalboa);

        expect(
          find.byKey(Key('inspiration-story-tile-${story.id.value}')),
          findsOneWidget,
        );
        expect(find.text('Keep Climbing'), findsOneWidget);

        final provenance = tester.widget<Text>(
          find.byKey(
            Key('inspiration-story-provenance-${story.id.value}'),
          ),
        );
        expect(provenance.data!.toLowerCase(), contains('perseverance'));
        expect(provenance.data!.toLowerCase(), isNot(contains('reflect')));
      },
    );

    testWidgets(
      'removing exclusive Inspiration clears matching Stories',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final story = await seedPublishedStory(
          title: 'Courage Path',
          themes: [NarrativeThemeReferenceIds.courage],
        );

        await saveInfluence(tester, InfluenceReferenceIds.rockyBalboa);
        expect(find.text('Courage Path'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
        final chipKey = Key(
          'selected-influence-chip-${InfluenceReferenceIds.rockyBalboa.value}',
        );
        await tester.ensureVisible(find.byKey(chipKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Remove inspiration'));
        await tester.pump();

        final saveButton = find.byKey(const Key('save-influences-button'));
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(Key('inspiration-story-tile-${story.id.value}')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('explore-stories-empty-no-inspirations')),
          findsOneWidget,
        );
      },
    );
  });
}
