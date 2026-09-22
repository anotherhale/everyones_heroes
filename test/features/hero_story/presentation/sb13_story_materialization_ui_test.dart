import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
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
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;
  late InMemoryStoryProposalRepository proposals;
  late InMemoryStoryRepository stories;
  late StoryBuilderSessionId sessionId;
  late StoryProposalId proposalId;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    proposals = InMemoryStoryProposalRepository();
    stories = InMemoryStoryRepository();

    final hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'SB13 Hero',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.private,
    );
    await heroes.save(hero);

    sessionId = StoryBuilderSessionId.generate();
    final session = StoryBuilderSession.create(
      id: sessionId,
      heroId: hero.id,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.empty(),
    );
    session.complete(at: DateTime.utc(2026, 9, 22, 10));
    await sessions.save(session);

    proposalId = StoryProposalId.generate();
    final responseId = StoryBuilderResponseId.generate();
    final proposal = StoryProposal(
      id: proposalId,
      sessionId: sessionId,
      title: StoryTitle('UI Story Title'),
      narrative: 'Hero beginning.\n\nAI challenge.',
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId('sec-hero'),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Hero beginning.',
          sourceResponseIds: [responseId],
        ),
        StoryProposalSection(
          id: StoryProposalSectionId('sec-ai'),
          narrativeRole: StoryBuilderNarrativeRole.challenge,
          order: 1,
          contentOrigin: StoryProposalContentOrigin.derived,
          content: 'AI challenge.',
          sourceResponseIds: [responseId],
        ),
      ],
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.aiShaped,
        processingVersion: StoryProposal.aiShapedProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22, 10),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
    );
    await proposals.save(proposal);
  });

  ProviderContainer buildContainer({StoryRepository? storyRepo}) {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
        storyProposalRepositoryProvider.overrideWithValue(proposals),
        storyRepositoryProvider.overrideWithValue(storyRepo ?? stories),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
      ],
    );
  }

  Future<void> pumpReview(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StoryBuilderScreen(resumeSessionId: sessionId.value),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      final phase = container.read(storyBuilderControllerProvider).phase;
      if (phase == StoryBuilderUiPhase.proposalPreview ||
          phase == StoryBuilderUiPhase.storyCreated) {
        break;
      }
    }
    await tester.pump();
  }

  testWidgets('approve causes materialization and shows story created', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('story-builder-story-created')),
      findsOneWidget,
    );
    expect(find.text('Your story has been created.'), findsOneWidget);
    expect(find.text('UI Story Title'), findsOneWidget);
    expect(find.textContaining('Not yet published'), findsOneWidget);
    expect(find.textContaining('published'), findsWidgets);

    final stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.accepted);
    expect(await stories.findAll(), hasLength(1));
    final story = (await stories.findAll()).single;
    expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
    expect(story.visibility, StoryVisibility.draft);
    expect(story.isPublished, isFalse);
  });

  testWidgets('materialization failure preserves approval and offers retry', (
    tester,
  ) async {
    final failing = _FailingSaveStoryRepository(stories);
    final container = buildContainer(storyRepo: failing);
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('story-builder-proposal-approved')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('story-builder-materialize-retry')),
      findsOneWidget,
    );
    final stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.accepted);
    expect(stored.materializedStoryId, isNull);
    expect(await stories.findAll(), isEmpty);

    failing.failSaves = false;
    await tester.tap(
      find.byKey(const ValueKey('story-builder-materialize-retry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('story-builder-story-created')),
      findsOneWidget,
    );
    expect(await stories.findAll(), hasLength(1));
  });

  testWidgets('duplicate approve/materialize does not create duplicate Stories', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-confirm')),
    );
    await tester.pumpAndSettle();

    expect(await stories.findAll(), hasLength(1));
    final firstId = (await stories.findAll()).single.id;

    // Retry materialize from controller — still one Story.
    final ok = await container
        .read(storyBuilderControllerProvider.notifier)
        .materializeApprovedProposal();
    expect(ok, isTrue);
    expect(await stories.findAll(), hasLength(1));
    expect((await stories.findAll()).single.id, firstId);
  });

  testWidgets('UI does not imply publication', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Not yet published'), findsOneWidget);
    expect(find.text('Published'), findsNothing);
    expect(find.textContaining('is now live'), findsNothing);
  });
}
