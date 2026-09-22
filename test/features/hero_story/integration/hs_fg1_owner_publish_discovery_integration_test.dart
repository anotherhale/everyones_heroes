import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/publish_story_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/story_id_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/update_story_consent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_use_case.dart';
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

/// HS.FG.1 integration: materialize → submit → approve → publish → Discover.
void main() {
  late InMemoryHeroRepository heroRepository;
  late InMemoryStoryBuilderSessionRepository sessionRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryEventBus eventBus;

  late MaterializeStoryProposalUseCase materialize;
  late SubmitStoryUseCase submitStory;
  late ApproveStoryUseCase approveStory;
  late PublishStoryUseCase publishStory;
  late UpdateStoryConsentUseCase updateConsent;
  late DiscoverStoriesUseCase discoverStories;
  late ApproveStoryProposalUseCase approveProposal;

  late HeroId heroId;
  late StoryBuilderSessionId sessionId;

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    // Discoverable Hero (separate from Story publish path).
    heroId = HeroId.generate();
    await heroRepository.save(
      Hero.create(
        id: heroId,
        profile: HeroProfile(
          displayName: 'Discoverable Owner',
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
      intent: StoryBuilderIntent.empty(),
    );
    session.complete(at: DateTime.utc(2026, 9, 22, 9));
    await sessionRepository.save(session);

    final createStory = CreateStoryUseCase(
      storyRepository: storyRepository,
      heroRepository: heroRepository,
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
  });

  Future<StoryProposal> seedAcceptedProposal() async {
    final proposalId = StoryProposalId.generate();
    final responseId = StoryBuilderResponseId.generate();
    final proposal = StoryProposal(
      id: proposalId,
      sessionId: sessionId,
      title: StoryTitle('FG.1 Integration Story'),
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
    await proposalRepository.save(proposal);

    final approved = await approveProposal.execute(
      ApproveStoryProposalRequest(proposalId: proposalId),
    );
    return (approved as Success<StoryProposal>).value;
  }

  Future<bool> isDiscoverable(StoryId storyId) async {
    final result = await discoverStories.execute(
      const DiscoverStoriesRequest(limit: 50),
    );
    expect(result, isA<Success<DiscoverStoriesResponse>>());
    final response = (result as Success<DiscoverStoriesResponse>).value;
    return response.items.any((item) => item.storyId == storyId);
  }

  test(
    'materialize → draft → submit → approve → publish → discovery',
    () async {
      final proposal = await seedAcceptedProposal();

      final materialized = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: proposal.id),
      );
      expect(materialized, isA<Success<Story>>());
      final story = (materialized as Success<Story>).value;
      expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
      expect(story.visibility, StoryVisibility.draft);
      expect(await isDiscoverable(story.id), isFalse);

      await updateConsent.execute(
        UpdateStoryConsentRequest(
          storyId: story.id,
          grantProcessing: true,
          grantPublication: true,
        ),
      );

      await submitStory.execute(StoryIdRequest(storyId: story.id));
      expect(
        (await storyRepository.findById(story.id))!.lifecycleStatus,
        StoryLifecycleStatus.processing,
      );
      expect(await isDiscoverable(story.id), isFalse);

      await approveStory.execute(StoryIdRequest(storyId: story.id));
      expect(
        (await storyRepository.findById(story.id))!.lifecycleStatus,
        StoryLifecycleStatus.approved,
      );
      expect(await isDiscoverable(story.id), isFalse);

      final published = await publishStory.execute(
        PublishStoryRequest(
          storyId: story.id,
          visibility: StoryVisibility.public,
        ),
      );
      expect(published, isA<Success<Story>>());
      final publishedStory = (published as Success<Story>).value;
      expect(publishedStory.lifecycleStatus, StoryLifecycleStatus.published);
      expect(publishedStory.visibility, StoryVisibility.public);

      // Provenance preserved — publication is not a content transformation.
      expect(
        publishedStory.provenance.materializedFromProposalId,
        proposal.id,
      );

      expect(await isDiscoverable(story.id), isTrue);
    },
  );
}
