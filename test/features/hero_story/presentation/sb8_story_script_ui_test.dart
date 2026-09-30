import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_script_generator_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_script_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/deterministic_story_builder_catalog.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingSaveStoryRepository implements StoryRepository {
  _FailingSaveStoryRepository(this._inner);

  final InMemoryStoryRepository _inner;
  var failSaves = true;

  @override
  Future<void> save(Story story) async {
    if (failSaves) {
      throw StateError('simulated story persistence failure');
    }
    await _inner.save(story);
  }

  @override
  Future<Story?> findById(StoryId id) => _inner.findById(id);

  @override
  Future<bool> exists(StoryId id) => _inner.exists(id);

  @override
  Future<void> delete(StoryId id) => _inner.delete(id);

  @override
  Future<List<Story>> findByHeroId(HeroId heroId) =>
      _inner.findByHeroId(heroId);

  @override
  Future<List<Story>> findAll() => _inner.findAll();

  @override
  Future<List<Story>> findPublished() => _inner.findPublished();

  @override
  Future<Story?> findByStoryProposalId(StoryProposalId proposalId) =>
      _inner.findByStoryProposalId(proposalId);
}

void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryBuilderSessionRepository sessionRepository;
  late InMemoryStoryBuilderScriptRepository scriptRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryScriptGenerator generator;
  late StoryBuilderSessionId sessionId;
  late HeroId heroId;
  late ActiveLocalHeroStore heroStore;

  Future<void> seedCompletedSession() async {
    final session = StoryBuilderSession.create(
      id: sessionId,
      heroId: heroId,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.purposeOnly(
        StoryBuilderPurpose.inspireSomeone,
      ),
    );
    session.setThemes(themes: const [StoryBuilderTheme.perseverance]);
    final prompts = DeterministicStoryBuilderCatalog.prompts.take(3).toList();
    final answers = [
      'When I first joined the military, everything changed overnight.',
      'I faced challenges that tested my courage every day.',
      'Looking back now, what I learned was perseverance.',
    ];
    for (var i = 0; i < prompts.length; i++) {
      session.presentPrompt(prompts[i]);
      session.answerPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: prompts[i].id,
        text: answers[i],
      );
    }
    session.complete();
    await sessionRepository.save(session);
  }

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    scriptRepository = InMemoryStoryBuilderScriptRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    generator = InMemoryStoryScriptGenerator(
      fixedContent:
          'When I first joined the military, everything changed overnight.\n\n'
          'I faced challenges that tested my courage every day.\n\n'
          'Looking back now, what I learned from that experience was '
          'perseverance.',
    );
    heroId = HeroId.generate();
    sessionId = StoryBuilderSessionId.generate();
    final hero = hs.Hero.create(
      id: heroId,
      profile: HeroProfile(
        displayName: 'UI Script Hero',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.private,
    );
    await heroRepository.save(hero);
    heroStore = ActiveLocalHeroStore();
    await heroStore.setActive(heroId);
    await seedCompletedSession();
  });

  Widget buildApp({StoryRepository? stories}) {
    return ProviderScope(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroRepository),
        storyBuilderSessionRepositoryProvider.overrideWithValue(
          sessionRepository,
        ),
        storyBuilderScriptRepositoryProvider.overrideWithValue(
          scriptRepository,
        ),
        storyProposalRepositoryProvider.overrideWithValue(proposalRepository),
        storyRepositoryProvider.overrideWithValue(stories ?? storyRepository),
        storyScriptGeneratorProvider.overrideWithValue(generator),
        activeLocalHeroStoreProvider.overrideWithValue(heroStore),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
      ],
      child: MaterialApp(
        home: StoryBuilderScreen(resumeSessionId: sessionId.value),
      ),
    );
  }

  testWidgets(
    'Create My Story → review → edit → approve → Story created',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-builder-completed')), findsOneWidget);
      expect(find.text('Create My Story'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('story-builder-create-my-story')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-builder-script-review')), findsOneWidget);
      expect(find.textContaining('When I first joined'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('story-builder-script-edit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-builder-script-editor')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('story-builder-script-editor')),
        'When I first joined the military, everything changed.\n\n'
        'I edited this carefully.\n\n'
        'Looking back now, perseverance remains the lesson.',
      );
      await tester.tap(find.byKey(const ValueKey('story-builder-script-save')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('story-builder-script-approve')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-builder-story-created')), findsOneWidget);
      final scripts = await scriptRepository.findBySessionId(sessionId);
      expect(scripts.first.isApproved, isTrue);
      expect(scripts.first.materializedStoryId, isNotNull);
    },
  );

  testWidgets(
    'Approve → Create fails → approved script remains → Retry succeeds',
    (tester) async {
      final failing = _FailingSaveStoryRepository(storyRepository);
      await tester.pumpWidget(buildApp(stories: failing));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('story-builder-create-my-story')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('story-builder-script-approve')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('story-builder-script-approved')),
        findsOneWidget,
      );
      expect(find.textContaining('Script Approved — Create Failed'), findsOneWidget);

      final approved = await scriptRepository.findLatestBySessionId(sessionId);
      expect(approved!.isApproved, isTrue);
      expect(approved.materializedStoryId, isNull);

      failing.failSaves = false;
      await tester.tap(
        find.byKey(const ValueKey('story-builder-script-retry-create')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('story-builder-story-created')), findsOneWidget);
      final linked = await scriptRepository.findById(approved.id);
      expect(linked!.materializedStoryId, isNotNull);
    },
  );
}
