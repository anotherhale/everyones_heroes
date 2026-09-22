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
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_proposal_section_edit.dart';
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

void main() {
  late InMemoryHeroRepository heroes;
  late InMemoryStoryBuilderSessionRepository sessions;
  late InMemoryStoryProposalRepository proposals;
  late InMemoryStoryRepository stories;
  late StoryBuilderSessionId sessionId;
  late StoryProposalId proposalId;
  late String heroSectionId;
  late String aiSectionId;

  setUp(() async {
    heroes = InMemoryHeroRepository();
    sessions = InMemoryStoryBuilderSessionRepository();
    proposals = InMemoryStoryProposalRepository();
    stories = InMemoryStoryRepository();

    final hero = hs.Hero.create(
      id: HeroId.generate(),
      profile: HeroProfile(
        displayName: 'Review Hero',
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
    heroSectionId = 'sec-hero';
    aiSectionId = 'sec-ai';
    final responseId = StoryBuilderResponseId.generate();

    final proposal = StoryProposal(
      id: proposalId,
      sessionId: sessionId,
      title: StoryTitle('Original Title'),
      narrative: 'Hero beginning.\n\nAI challenge.',
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId(heroSectionId),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Hero beginning.',
          sourceResponseIds: [responseId],
        ),
        StoryProposalSection(
          id: StoryProposalSectionId(aiSectionId),
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
      derivedSummary: 'Original summary',
    );
    await proposals.save(proposal);
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
        storyProposalRepositoryProvider.overrideWithValue(proposals),
        storyRepositoryProvider.overrideWithValue(stories),
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
    // Wait until review UI (or approved/rejected state) is visible.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      final phase = container.read(storyBuilderControllerProvider).phase;
      if (phase == StoryBuilderUiPhase.proposalPreview) {
        break;
      }
    }
    await tester.pump();
  }

  testWidgets('proposal opens in review mode with authorship labels', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    expect(find.text('Review Your Story'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-builder-review-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-builder-review-summary')),
      findsOneWidget,
    );
    expect(find.text('Hero-authored'), findsOneWidget);
    // Section label plus the "AI-assisted content" note title / disclosure.
    expect(find.textContaining('AI-assisted'), findsWidgets);
    expect(find.text('Approve Story'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('title, summary, and sections are editable and save', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.enterText(
      find.byKey(const ValueKey('story-builder-review-title')),
      'Edited Title',
    );
    await tester.enterText(
      find.byKey(const ValueKey('story-builder-review-summary')),
      'Edited summary',
    );
    await tester.enterText(
      find.byKey(ValueKey('story-builder-review-section-$aiSectionId')),
      'Edited AI section',
    );
    await tester.tap(find.byKey(const ValueKey('story-builder-review-save')));
    await tester.pumpAndSettle();

    final saved = await proposals.findById(proposalId);
    expect(saved!.title?.value, 'Edited Title');
    expect(saved.derivedSummary, 'Edited summary');
    expect(
      saved.sectionById(StoryProposalSectionId(aiSectionId))!.content,
      'Edited AI section',
    );
    expect(
      saved.sectionById(StoryProposalSectionId(aiSectionId))!.contentOrigin,
      StoryProposalContentOrigin.derived,
    );
    expect(
      saved.sectionById(StoryProposalSectionId(aiSectionId))!.heroEdited,
      isTrue,
    );
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('approve requires confirmation and shows approved state', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve Story?'), findsOneWidget);

    // Cancel does not approve.
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-cancel')),
    );
    await tester.pumpAndSettle();
    var stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.readyForReview);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-approve')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('story-builder-approve-confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Approved'), findsOneWidget);
    expect(
      find.textContaining('Story creation'),
      findsOneWidget,
    );
    stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.accepted);
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('reject persists rejection without creating a Story', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-review-reject')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Proposal Rejected'), findsOneWidget);
    final stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.rejected);
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('edit after approval returns to review', (tester) async {
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

    await tester.tap(
      find.byKey(const ValueKey('story-builder-proposal-edit-after-approve')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review Your Story'), findsOneWidget);
    expect(find.text('Approve Story'), findsOneWidget);
    final stored = await proposals.findById(proposalId);
    expect(stored!.lifecycle, StoryProposalLifecycleStatus.readyForReview);
    expect(stored.review.editedAfterDecision, isTrue);
  });

  testWidgets('resume restores accepted proposal without re-approval', (
    tester,
  ) async {
    final existing = await proposals.findById(proposalId);
    await proposals.save(
      existing!.approve(at: DateTime.utc(2026, 9, 22, 12)),
    );

    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    expect(find.text('Story Approved'), findsOneWidget);
    final state = container.read(storyBuilderControllerProvider);
    expect(
      state.proposal!.lifecycle,
      StoryProposalLifecycleStatus.accepted,
    );
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('resume after edit restores edited proposal for review', (
    tester,
  ) async {
    final existing = await proposals.findById(proposalId);
    final edited = existing!.editHeroContent(
      title: 'Saved Before Restart',
      updateTitle: true,
      summary: 'Edited summary survives restart',
      updateSummary: true,
      sectionEdits: [
        StoryProposalSectionEdit(
          sectionId: StoryProposalSectionId(aiSectionId),
          content: 'Edited AI section survives restart',
        ),
      ],
      editedAt: DateTime.utc(2026, 9, 22, 14),
    );
    await proposals.save(edited);

    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    expect(find.text('Review Your Story'), findsOneWidget);
    final titleField = tester.widget<TextField>(
      find.byKey(const ValueKey('story-builder-review-title')),
    );
    expect(titleField.controller!.text, 'Saved Before Restart');
    final summaryField = tester.widget<TextField>(
      find.byKey(const ValueKey('story-builder-review-summary')),
    );
    expect(summaryField.controller!.text, 'Edited summary survives restart');
    final sectionField = tester.widget<TextField>(
      find.byKey(ValueKey('story-builder-review-section-$aiSectionId')),
    );
    expect(sectionField.controller!.text, 'Edited AI section survives restart');

    final state = container.read(storyBuilderControllerProvider);
    expect(state.proposal!.lifecycle, StoryProposalLifecycleStatus.readyForReview);
    expect(
      state.proposal!.sectionById(StoryProposalSectionId(aiSectionId))!
          .contentOrigin,
      StoryProposalContentOrigin.derived,
    );
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('AI failure keeps proposal and returns to review', (
    tester,
  ) async {
    // Improve with AI is offered only for non-AI-shaped proposals.
    final existing = await proposals.findById(proposalId);
    await proposals.save(
      StoryProposal(
        id: existing!.id,
        sessionId: existing.sessionId,
        title: existing.title,
        narrative: existing.narrative,
        sections: existing.sections,
        intent: existing.intent,
        provenance: StoryProposalProvenance(
          sessionId: existing.sessionId,
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.shapedProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        derivedSummary: existing.derivedSummary,
        review: existing.review,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        heroRepositoryProvider.overrideWithValue(heroes),
        storyBuilderSessionRepositoryProvider.overrideWithValue(sessions),
        storyProposalRepositoryProvider.overrideWithValue(proposals),
        storyRepositoryProvider.overrideWithValue(stories),
        eventBusProvider.overrideWithValue(
          InMemoryEventBus(
            eventStore: InMemoryEventStore(),
            dispatcher: InMemoryEventDispatcher(),
          ),
        ),
        activeLocalHeroStoreProvider.overrideWithValue(ActiveLocalHeroStore()),
        storyAuthoringTransportProvider.overrideWithValue(
          InMemoryStoryProposalAuthoringAdapter(
            forcedFailureMessage: 'simulated AI authoring outage',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    expect(find.text('Improve with AI'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('story-builder-improve-with-ai')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('story-builder-authoring-unavailable')),
      findsOneWidget,
    );
    final mid = await proposals.findById(proposalId);
    expect(mid, isNotNull);
    expect(mid!.lifecycle, StoryProposalLifecycleStatus.readyForReview);

    await tester.tap(
      find.byKey(const ValueKey('story-builder-authoring-continue')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Review Your Story'), findsOneWidget);
    expect(find.text('Approve Story'), findsOneWidget);
    final restored = container.read(storyBuilderControllerProvider).proposal;
    expect(restored!.id, proposalId);
    expect(await stories.findAll(), isEmpty);
  });

  testWidgets('deterministic offline proposal opens review without AI', (
    tester,
  ) async {
    final existing = await proposals.findById(proposalId);
    await proposals.save(
      StoryProposal(
        id: existing!.id,
        sessionId: existing.sessionId,
        title: existing.title,
        narrative: existing.narrative,
        sections: [
          for (final section in existing.sections)
            StoryProposalSection(
              id: section.id,
              narrativeRole: section.narrativeRole,
              order: section.order,
              contentOrigin: StoryProposalContentOrigin.heroAuthored,
              content: section.content,
              sourceResponseIds: section.sourceResponseIds,
              wasSkipped: section.wasSkipped,
            ),
        ],
        intent: existing.intent,
        provenance: StoryProposalProvenance(
          sessionId: existing.sessionId,
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.shapedProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        derivedSummary: existing.derivedSummary,
      ),
    );

    final container = buildContainer();
    addTearDown(container.dispose);
    await pumpReview(tester, container);

    expect(find.text('Review Your Story'), findsOneWidget);
    expect(find.text('Hero-authored'), findsWidgets);
    expect(find.text('Improve with AI'), findsOneWidget);
    expect(find.text('Approve Story'), findsOneWidget);
    final state = container.read(storyBuilderControllerProvider);
    expect(
      state.proposal!.provenance.derivationKind,
      StoryProposalDerivationKind.deterministic,
    );
    expect(await stories.findAll(), isEmpty);
  });
}
