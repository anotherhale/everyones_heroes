import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/hero_catalog_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_entry_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_intent_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;
  late HeroId heroId;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    heroId = HeroId.generate();
    await heroes.save(
      hs.Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Local Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.private,
      ),
    );
  });

  List<Override> overrides() {
    final eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    return [
      heroRepositoryProvider.overrideWithValue(heroes),
      storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
      eventBusProvider.overrideWithValue(eventBus),
      activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
    ];
  }

  testWidgets('entry shows guided and disabled AI mode options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: StoryBuilderEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-builder-mode-guided')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-mode-ai')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-ai-coming-soon')), findsOneWidget);
    expect(find.text('Guided Story Builder'), findsOneWidget);
    expect(find.text('No AI required'), findsOneWidget);
    expect(find.textContaining('Works offline'), findsOneWidget);

    // AI option is not tappable — stays on entry.
    await tester.tap(find.byKey(const ValueKey('story-builder-mode-ai')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-builder-mode-title')), findsOneWidget);
  });

  testWidgets('guided path creates session with mode and intent then questions',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: StoryBuilderEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('story-builder-mode-guided')));
    await tester.pumpAndSettle();

    expect(find.byType(StoryBuilderIntentScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-purpose-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-themes-title')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-purpose-inspireSomeone')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-theme-courage')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-builder-intent-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(StoryBuilderScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-prompt')), findsOneWidget);
    expect(
      find.text('What was happening in your life when this story began?'),
      findsOneWidget,
    );

    final stored = await sessions.findByHeroId(heroId);
    expect(stored, hasLength(1));
    expect(stored.first.mode, StoryBuilderMode.guided);
    expect(stored.first.intent.purpose, StoryBuilderPurpose.inspireSomeone);
    expect(stored.first.intent.themes, [StoryBuilderTheme.courage]);
  });

  testWidgets('resume restores responses and next question', (tester) async {
    final sessionId = StoryBuilderSessionId.generate();
    final responseId = StoryBuilderResponseId.generate();
    final prompt = DeterministicStoryBuilderCatalog.prompts.first;
    final now = DateTime.utc(2026, 9, 21, 12);
    final session = StoryBuilderSession(
      id: sessionId,
      heroId: heroId,
      status: StoryBuilderSessionStatus.paused,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent(
        purpose: StoryBuilderPurpose.preserveAMemory,
        themes: const [StoryBuilderTheme.family],
      ),
      createdAt: now,
      updatedAt: now,
      prompts: [
        StoryBuilderPrompt(
          id: prompt.id,
          text: prompt.text,
          ordinal: prompt.ordinal,
          narrativeRole: prompt.narrativeRole,
          isOptional: prompt.isOptional,
        ),
      ],
      responses: [
        StoryBuilderResponse(
          id: responseId,
          promptId: prompt.id,
          ordinal: prompt.ordinal,
          text: 'We were packing boxes in the hallway.',
          skipped: false,
          createdAt: now,
        ),
      ],
    );
    await sessions.save(session);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: StoryBuilderEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('story-builder-resume-${sessionId.value}')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(ValueKey('story-builder-resume-${sessionId.value}')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StoryBuilderScreen), findsOneWidget);
    expect(find.text('What were you facing?'), findsOneWidget);
    expect(find.text('Question 2 of 11'), findsOneWidget);

    final reloaded = await sessions.findById(sessionId);
    expect(reloaded!.responses.single.id, responseId);
    expect(reloaded.intent.purpose, StoryBuilderPurpose.preserveAMemory);
    expect(reloaded.mode, StoryBuilderMode.guided);
  });

  testWidgets('heroes Build My Story opens mode selection entry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: HeroCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('build-my-story-button')));
    await tester.pumpAndSettle();

    expect(find.byType(StoryBuilderEntryScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-mode-title')), findsOneWidget);
  });

  testWidgets('pause leaves session resumable without completing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: StoryBuilderScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('story-builder-response-field')),
      'A beginning.',
    );
    await tester.tap(find.byKey(const ValueKey('story-builder-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('story-builder-pause')));
    await tester.pumpAndSettle();

    final stored = await sessions.findByHeroId(heroId);
    expect(stored, hasLength(1));
    expect(stored.first.status, StoryBuilderSessionStatus.paused);
    expect(stored.first.responses, isNotEmpty);
    expect(stored.first.mode, StoryBuilderMode.guided);
  });
}
