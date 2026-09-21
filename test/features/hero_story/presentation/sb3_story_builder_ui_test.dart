import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    await heroes.save(
      hs.Hero.create(
        id: HeroId.generate(),
        profile: HeroProfile(
          displayName: 'Local Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  testWidgets('guided builder shows first prompt and accepts a response', (
    tester,
  ) async {
    final eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heroRepositoryProvider.overrideWithValue(heroes),
          storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
          eventBusProvider.overrideWithValue(eventBus),
          activeLocalHeroStoreProvider.overrideWithValue(
            ActiveLocalHeroStore(),
          ),
        ],
        child: const MaterialApp(home: StoryBuilderScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-builder-prompt')), findsOneWidget);
    expect(
      find.text('What was happening in your life when this story began?'),
      findsOneWidget,
    );
    expect(find.text('Question 1 of 11'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('story-builder-response-field')),
      'I was scared as hell and did not know what to do.',
    );
    await tester.tap(find.byKey(const ValueKey('story-builder-continue')));
    await tester.pumpAndSettle();

    expect(find.text('What were you facing?'), findsOneWidget);
    expect(find.text('Question 2 of 11'), findsOneWidget);
  });
}
