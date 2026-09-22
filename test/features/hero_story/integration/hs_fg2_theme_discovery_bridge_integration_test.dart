import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/discovery/domain/catalog/narrative_theme_reference_ids.dart';
import 'package:everyonesheroes/features/discovery/infrastructure/repositories/in_memory_narrative_theme_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/bridges/story_builder_theme_narrative_theme_bridge.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/browse_stories_by_catalog_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/browse_stories_by_catalog_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/classify_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/materialize_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/publish_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/submit_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/update_story_consent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// HS.FG.2: Builder themes → NarrativeThemeId → Story → Discovery recognition.
void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryBuilderSessionRepository sessionRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryNarrativeThemeRepository narrativeThemeRepository;
  late InMemoryEventBus eventBus;

  late MaterializeStoryProposalUseCase materialize;
  late ApproveStoryProposalUseCase approveProposal;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;
  late UpdateStoryConsentUseCase updateConsent;
  late DiscoverStoriesUseCase discoverStories;
  late BrowseStoriesByCatalogUseCase browseByCatalog;

  late HeroId heroId;
  late StoryBuilderSessionId sessionId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    narrativeThemeRepository =
        InMemoryNarrativeThemeRepository.withReferenceCatalog();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    heroId = HeroId.generate();
    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Theme Bridge Hero',
          languages: [LanguageCode('en')],
        ),
        visibility: HeroVisibility.public,
      ),
    );

    sessionId = StoryBuilderSessionId.generate();
    final session = StoryBuilderSession.create(
      id: sessionId,
      heroId: heroId,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent(
        themes: [
          StoryBuilderTheme.courage,
          StoryBuilderTheme.perseverance,
        ],
      ),
    );
    session.complete(at: DateTime.utc(2026, 9, 22, 9));
    await sessionRepository.save(session);

    final createStory = CreateStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    final classifyStory = ClassifyStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    approveProposal = ApproveStoryProposalUseCase(
      proposalRepository: proposalRepository,
    );
    materialize = MaterializeStoryProposalUseCase(
      proposalRepository: proposalRepository,
      sessionRepository: sessionRepository,
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      createStoryUseCase: createStory,
      classifyStoryUseCase: classifyStory,
      themeBridge: const StoryBuilderThemeNarrativeThemeBridge(),
    );
    submitStory = SubmitStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    approveStory = ApproveStoryUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    publishStory = PublishStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      eventBus: eventBus,
    );
    updateConsent = UpdateStoryConsentUseCase(
      storyRepository: storyRepository,
      eventBus: eventBus,
    );
    discoverStories = DiscoverStoriesUseCase(
      storySearchPort: InMemoryStorySearchAdapter(storyRepository),
      storyRepository: storyRepository,
      heroRepository: heroRepository,
    );
    browseByCatalog = BrowseStoriesByCatalogUseCase(
      discoverStoriesUseCase: discoverStories,
    );
  });

  Future<StoryProposal> seedAcceptedProposal({
    List<StoryBuilderTheme> themes = const [
      StoryBuilderTheme.courage,
      StoryBuilderTheme.perseverance,
    ],
  }) async {
    final proposalId = StoryProposalId.generate();
    final responseId = StoryBuilderResponseId.generate();
    final proposal = StoryProposal(
      id: proposalId,
      sessionId: sessionId,
      title: StoryTitle('FG.2 Theme Bridge Story'),
      narrative: 'Hero beginning.\n\nChallenge.\n\nGrowth.',
      sections: [
        StoryProposalSection(
          id: StoryProposalSectionId('sec-0'),
          narrativeRole: StoryBuilderNarrativeRole.beginning,
          order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Hero beginning.',
          sourceResponseIds: [responseId],
        ),
        StoryProposalSection(
          id: StoryProposalSectionId('sec-1'),
          narrativeRole: StoryBuilderNarrativeRole.challenge,
          order: 1,
          contentOrigin: StoryProposalContentOrigin.derived,
          content: 'Challenge.',
          sourceResponseIds: [responseId],
          heroEdited: true,
          contentBeforeHeroEdit: 'Challenge original',
        ),
      ],
      intent: StoryBuilderIntent(themes: themes),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: StoryProposalDerivationKind.aiShaped,
        processingVersion: StoryProposal.aiShapedProcessingVersion,
      ),
      lifecycle: StoryProposalLifecycleStatus.readyForReview,
      createdAt: DateTime.utc(2026, 9, 22, 10),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
    );
    await proposalRepository.save(proposal);

    final approved = await approveProposal.execute(
      ApproveStoryProposalRequest(proposalId: proposalId),
    );
    return (approved as Success<StoryProposal>).value;
  }

  Future<Story> publish(Story story) async {
    await updateConsent.execute(
      UpdateStoryConsentRequest(
        storyId: story.id,
        grantProcessing: true,
        grantPublication: true,
      ),
    );
    await submitStory.execute(StoryIdRequest(storyId: story.id));
    await approveStory.execute(StoryIdRequest(storyId: story.id));
    final result = await publishStory.execute(
      PublishStoryRequest(
        storyId: story.id,
        visibility: StoryVisibility.public,
      ),
    );
    return (result as Success<Story>).value;
  }

  group('HS.FG.2 materialization theme bridge', () {
    test('session → proposal → Story carries Discovery NarrativeThemeIds',
        () async {
      final approved = await seedAcceptedProposal();
      expect(approved.intent.themes, [
        StoryBuilderTheme.courage,
        StoryBuilderTheme.perseverance,
      ]);

      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      expect(result, isA<Success<Story>>());
      final story = (result as Success<Story>).value;

      expect(story.classification.narrativeThemeIds, [
        NarrativeThemeReferenceIds.courage,
        NarrativeThemeReferenceIds.perseverance,
      ]);

      // Provenance unchanged by theme bridge.
      expect(story.provenance.materializedFromProposalId, approved.id);
      expect(story.provenance.proposalContainedDerivedContent, isTrue);
      expect(
        story.provenance.proposalDerivationKind,
        StoryProposalDerivationKind.aiShaped,
      );
    });

    test('empty Builder themes leave Story narrativeThemeIds empty', () async {
      final approved = await seedAcceptedProposal(themes: const []);
      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      final story = (result as Success<Story>).value;
      expect(story.classification.narrativeThemeIds, isEmpty);
    });

    test('Discovery catalog resolves Story theme references', () async {
      final approved = await seedAcceptedProposal(
        themes: [StoryBuilderTheme.service, StoryBuilderTheme.leadership],
      );
      final story = (await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      ) as Success<Story>)
          .value;

      for (final id in story.classification.narrativeThemeIds) {
        final theme = await narrativeThemeRepository.findById(id);
        expect(theme, isNotNull, reason: 'Discovery missing $id');
        expect(theme!.id, id);
      }
    });

    test('DiscoverStories filters by mapped NarrativeThemeId', () async {
      final approved = await seedAcceptedProposal(
        themes: [StoryBuilderTheme.courage],
      );
      final drafted = (await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      ) as Success<Story>)
          .value;
      final published = await publish(drafted);

      final byTheme = await discoverStories.execute(
        DiscoverStoriesRequest(
          narrativeThemeIds: [NarrativeThemeReferenceIds.courage],
        ),
      );
      expect(byTheme, isA<Success<DiscoverStoriesResponse>>());
      final items = (byTheme as Success<DiscoverStoriesResponse>).value.items;
      expect(items.any((i) => i.storyId == published.id), isTrue);
      expect(
        items
            .firstWhere((i) => i.storyId == published.id)
            .narrativeThemeIds,
        contains(NarrativeThemeReferenceIds.courage),
      );

      final wrongTheme = await discoverStories.execute(
        DiscoverStoriesRequest(
          narrativeThemeIds: [NarrativeThemeReferenceIds.love],
        ),
      );
      final wrongItems =
          (wrongTheme as Success<DiscoverStoriesResponse>).value.items;
      expect(wrongItems.any((i) => i.storyId == published.id), isFalse);
    });

    test('BrowseStoriesByCatalog recognizes mapped narrativeTheme', () async {
      final approved = await seedAcceptedProposal(
        themes: [StoryBuilderTheme.sacrifice],
      );
      final drafted = (await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      ) as Success<Story>)
          .value;
      await publish(drafted);

      final browse = await browseByCatalog.execute(
        BrowseStoriesByCatalogRequest(
          dimension: CatalogBrowseDimension.narrativeTheme,
          narrativeThemeId: NarrativeThemeReferenceIds.sacrifice,
        ),
      );
      expect(browse, isA<Success<DiscoverStoriesResponse>>());
      final items = (browse as Success<DiscoverStoriesResponse>).value.items;
      expect(items.any((i) => i.storyId == drafted.id), isTrue);
    });
  });
}
