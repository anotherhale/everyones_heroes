import 'package:everyonesheroes/core/eventing/event_providers.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/ai/story_authoring_port_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/hero_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_builder_session_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_proposal_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/repositories/story_repository_provider.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart'
    as hs;
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_content_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_derivation_kind.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_proposal_authoring_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/story_builder_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts saves to prove Continue rehydration does not persist a new proposal.
final class _CountingStoryProposalRepository
    implements StoryProposalRepository {
  _CountingStoryProposalRepository(this._inner);

  final InMemoryStoryProposalRepository _inner;
  var saveCount = 0;

  @override
  Future<void> save(StoryProposal proposal) async {
    saveCount++;
    await _inner.save(proposal);
  }

  @override
  Future<StoryProposal?> findById(StoryProposalId id) => _inner.findById(id);

  @override
  Future<bool> exists(StoryProposalId id) => _inner.exists(id);

  @override
  Future<void> delete(StoryProposalId id) => _inner.delete(id);

  @override
  Future<List<StoryProposal>> findBySessionId(
    StoryBuilderSessionId sessionId,
  ) =>
      _inner.findBySessionId(sessionId);
}

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;
  late InMemoryStoryProposalRepository proposals;
  late InMemoryStoryRepository stories;
  late StoryBuilderSessionId sessionId;
  late StoryProposalId proposalId;
  late StoryProposal canonical;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    proposals = InMemoryStoryProposalRepository();
    stories = InMemoryStoryRepository();

    final hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Continue Hero',
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
    canonical = StoryProposal(
      id: proposalId,
      sessionId: sessionId,
      title: StoryTitle('Canonical Title'),
      narrative: 'Canonical beginning.\n\nCanonical challenge.',
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId('sec-begin'),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Canonical beginning.',
          sourceResponseIds: [responseId],
        ),
        StoryProposalSection(
          id: StoryProposalSectionId('sec-challenge'),
          narrativeRole: StoryBuilderNarrativeRole.challenge,
          order: 1,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Canonical challenge.',
          sourceResponseIds: [responseId],
        ),
      ],
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.deterministic,
        processingVersion: StoryProposal.shapedProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22, 10),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
      derivedSummary: 'Canonical summary',
    );
    await proposals.save(canonical);
  });

  ProviderContainer buildContainer({
    StoryProposalRepository? proposalRepo,
    String? forcedFailureMessage = 'simulated AI authoring outage',
  }) {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
        storyProposalRepositoryProvider.overrideWithValue(
          proposalRepo ?? proposals,
        ),
        storyRepositoryProvider.overrideWithValue(stories),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
        if (forcedFailureMessage != null)
          storyAuthoringTransportProvider.overrideWithValue(
            InMemoryStoryProposalAuthoringAdapter(
              forcedFailureMessage: forcedFailureMessage,
            ),
          ),
      ],
    );
  }

  Future<void> pumpToReview(
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
      if (phase == StoryBuilderUiPhase.proposalPreview) {
        break;
      }
    }
    await tester.pump();
  }

  Future<void> failAiAuthoring(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.tap(
      find.byKey(const ValueKey('story-builder-improve-with-ai')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      container.read(storyBuilderControllerProvider).phase,
      StoryBuilderUiPhase.authoringUnavailable,
    );
  }

  testWidgets(
    'Continue rehydrates when transient proposal state is null',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await pumpToReview(tester, container);
      await failAiAuthoring(tester, container);

      final controller = container.read(storyBuilderControllerProvider.notifier);
      controller.clearTransientProposalsForTest();
      final cleared = container.read(storyBuilderControllerProvider);
      expect(cleared.proposal, isNull);
      expect(cleared.originalProposal, isNull);
      expect(cleared.canonicalProposalId, proposalId);

      await controller.continueWithCurrentProposal();
      await tester.pump();

      final restored = container.read(storyBuilderControllerProvider);
      expect(restored.phase, StoryBuilderUiPhase.proposalPreview);
      expect(restored.proposal, isNotNull);
      expect(restored.proposal!.id, proposalId);
      expect(restored.proposal!.narrative, canonical.narrative);
      expect(restored.proposal!.sections.length, 2);
      expect(restored.proposal!.sections[0].content, 'Canonical beginning.');
      expect(restored.proposal!.sections[1].content, 'Canonical challenge.');
      expect(restored.proposal!.isContentEquivalentTo(canonical), isTrue);
    },
  );

  testWidgets(
    'Continue does not save or allocate a new proposal identity',
    (tester) async {
      final counting = _CountingStoryProposalRepository(proposals);
      // Seed already saved once via setUp; reset counter after overrides load.
      final container = buildContainer(proposalRepo: counting);
      addTearDown(container.dispose);
      await pumpToReview(tester, container);
      await failAiAuthoring(tester, container);

      final savesBeforeContinue = counting.saveCount;
      final idsBefore = {
        for (final p in await proposals.findBySessionId(sessionId)) p.id.value,
      };

      final controller = container.read(storyBuilderControllerProvider.notifier);
      controller.clearTransientProposalsForTest();
      await controller.continueWithCurrentProposal();
      await tester.pump();

      expect(counting.saveCount, savesBeforeContinue);
      final idsAfter = {
        for (final p in await proposals.findBySessionId(sessionId)) p.id.value,
      };
      expect(idsAfter, idsBefore);
      expect(idsAfter, {proposalId.value});

      final restored = container.read(storyBuilderControllerProvider).proposal;
      expect(restored!.id, proposalId);
      expect(restored.isContentEquivalentTo(canonical), isTrue);
    },
  );

  testWidgets(
    'Continue stays out of proposalPreview when repository lookup fails',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await pumpToReview(tester, container);
      await failAiAuthoring(tester, container);

      await proposals.delete(proposalId);

      final controller = container.read(storyBuilderControllerProvider.notifier);
      controller.clearTransientProposalsForTest();
      await controller.continueWithCurrentProposal();
      await tester.pump();

      final state = container.read(storyBuilderControllerProvider);
      expect(state.phase, isNot(StoryBuilderUiPhase.proposalPreview));
      expect(state.phase, StoryBuilderUiPhase.authoringUnavailable);
      expect(state.proposal, isNull);
      expect(state.originalProposal, isNull);
      expect(state.errorMessage, contains('could not be restored'));
      expect(find.text('Review Your Story'), findsNothing);
      expect(
        find.byKey(const ValueKey('story-builder-authoring-unavailable')),
        findsOneWidget,
      );
    },
  );
}
