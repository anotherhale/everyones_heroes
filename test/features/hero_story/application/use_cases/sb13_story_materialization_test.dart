import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/mappers/story_materialization_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/materialize_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_proposal_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingSaveStoryRepository implements StoryRepository {
  _FailingSaveStoryRepository(this._inner);

  final InMemoryStoryRepository _inner;

  @override
  Future<void> save(Story story) async {
    throw StateError('simulated story persistence failure');
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
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late EventBus eventBus;
  late HeroId heroId;
  late StoryBuilderSessionId sessionId;
  late ApproveStoryProposalUseCase approveProposal;
  late MaterializeStoryProposalUseCase materialize;
  late CreateStoryUseCase createStory;

  Future<StoryProposal> seedReadyProposal({
    StoryProposalId? proposalId,
    StoryProposalLifecycleStatus lifecycle =
        StoryProposalLifecycleStatus.readyForReview,
    StoryProposalContentOrigin challengeOrigin =
        StoryProposalContentOrigin.derived,
    StoryProposalDerivationKind derivationKind =
        StoryProposalDerivationKind.aiShaped,
    String? narrative,
    String? title,
  }) async {
    final id = proposalId ?? StoryProposalId.generate();
    final responseId = StoryBuilderResponseId.generate();
    final proposal = StoryProposal(
      id: id,
      sessionId: sessionId,
      title: StoryTitle(title ?? 'Approved Title'),
      narrative: narrative ?? 'Hero beginning.\n\nAI challenge.',
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
          contentOrigin: challengeOrigin,
          content: 'AI challenge.',
          sourceResponseIds: [responseId],
          heroEdited: challengeOrigin == StoryProposalContentOrigin.derived,
          contentBeforeHeroEdit:
              challengeOrigin == StoryProposalContentOrigin.derived
                  ? 'AI challenge original'
                  : null,
        ),
      ],
      intent: StoryBuilderIntent.empty(),
      provenance: StoryProposalProvenance(
        sessionId: sessionId,
        derivationKind: derivationKind,
        processingVersion: derivationKind == StoryProposalDerivationKind.aiShaped
            ? StoryProposal.aiShapedProcessingVersion
            : StoryProposal.shapedProcessingVersion,
      ),
      lifecycle: lifecycle,
      createdAt: DateTime.utc(2026, 9, 22, 10),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
      derivedSummary: 'Derived summary',
    );
    await proposalRepository.save(proposal);
    return proposal;
  }

  Future<StoryProposal> approve(StoryProposalId id) async {
    final result = await approveProposal.execute(
      ApproveStoryProposalRequest(proposalId: id),
    );
    return (result as Success<StoryProposal>).value;
  }

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    heroId = HeroId.generate();
    final hero = Hero.create(
      id: heroId,
      profile: HeroProfile(
        displayName: 'Materialize Hero',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.private,
    );
    await heroRepository.save(hero);

    sessionId = StoryBuilderSessionId.generate();
    final session = StoryBuilderSession.create(
      id: sessionId,
      heroId: heroId,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.empty(),
    );
    session.complete(at: DateTime.utc(2026, 9, 22, 9));
    await sessionRepository.save(session);

    createStory = CreateStoryUseCase(
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
  });

  group('MaterializeStoryProposalUseCase', () {
    test('1. accepted proposal materializes successfully', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);

      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );

      expect(result, isA<Success<Story>>());
      final story = (result as Success<Story>).value;
      expect(story.heroId, heroId);
      expect(story.title.value, 'Approved Title');
      expect(story.narrative.value, 'Hero beginning.\n\nAI challenge.');
      expect(story.lifecycleStatus, StoryLifecycleStatus.draft);
      expect(story.visibility, StoryVisibility.draft);
      expect(story.isPublished, isFalse);
      expect(story.provenance.materializedFromProposalId, approved.id);
      expect(story.provenance.sourceSessionId, sessionId);
      expect(
        story.provenance.proposalDerivationKind,
        StoryProposalDerivationKind.aiShaped,
      );
      expect(story.provenance.proposalContainedDerivedContent, isTrue);

      final linked = await proposalRepository.findById(approved.id);
      expect(linked!.materializedStoryId, story.id);
      expect(linked.lifecycle, StoryProposalLifecycleStatus.accepted);
    });

    test('2. draft proposal is rejected', () async {
      final draft = await seedReadyProposal(
        lifecycle: StoryProposalLifecycleStatus.draft,
      );
      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: draft.id),
      );
      expect(result, isA<Failure<Story>>());
      expect(storyRepository.count, 0);
    });

    test('3. readyForReview proposal is rejected', () async {
      final ready = await seedReadyProposal();
      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: ready.id),
      );
      expect(result, isA<Failure<Story>>());
      expect(storyRepository.count, 0);
    });

    test('4. rejected proposal is rejected', () async {
      final ready = await seedReadyProposal();
      final rejected = ready.reject(at: DateTime.utc(2026, 9, 22, 12));
      await proposalRepository.save(rejected);

      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: rejected.id),
      );
      expect(result, isA<Failure<Story>>());
      expect(storyRepository.count, 0);
    });

    test('5. missing proposal fails', () async {
      final result = await materialize.execute(
        MaterializeStoryProposalRequest(
          proposalId: StoryProposalId.generate(),
        ),
      );
      expect(result, isA<Failure<Story>>());
    });

    test('6. invalid Hero ownership fails when session missing', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      await sessionRepository.delete(sessionId);

      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      expect(result, isA<Failure<Story>>());
      expect(storyRepository.count, 0);
      final still = await proposalRepository.findById(approved.id);
      expect(still!.lifecycle, StoryProposalLifecycleStatus.accepted);
    });

    test('7. Story persistence failure leaves proposal accepted', () async {
      final failingStories = _FailingSaveStoryRepository(storyRepository);
      final failingCreate = CreateStoryUseCase(
        storyRepository: failingStories,
        heroRepository: heroRepository,
        eventBus: eventBus,
      );
      final failingMaterialize = MaterializeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        sessionRepository: sessionRepository,
        storyRepository: failingStories,
        heroRepository: heroRepository,
        createStoryUseCase: failingCreate,
      );

      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);

      final result = await failingMaterialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      expect(result, isA<Failure<Story>>());
      expect(storyRepository.count, 0);

      final still = await proposalRepository.findById(approved.id);
      expect(still!.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(still.materializedStoryId, isNull);
    });

    test('8. successful materialization returns Story', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      final result = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      expect((result as Success<Story>).value, isA<Story>());
    });

    test('9. second materialization returns existing Story', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);

      final first = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );
      final second = await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );

      final story1 = (first as Success<Story>).value;
      final story2 = (second as Success<Story>).value;
      expect(story1.id, story2.id);
      expect(storyRepository.count, 1);
    });

    test('10. no publication occurs', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      final story = ((await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      expect(story.lifecycleStatus, isNot(StoryLifecycleStatus.published));
      expect(story.lifecycleStatus, isNot(StoryLifecycleStatus.approved));
      expect(await storyRepository.findPublished(), isEmpty);
    });

    test('11. provenance is preserved', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      final story = ((await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      expect(story.provenance.wasMaterializedFromProposal, isTrue);
      expect(story.provenance.materializedFromProposalId, approved.id);
      expect(story.provenance.sourceSessionId, sessionId);
      expect(
        story.provenance.originalSourceDescription,
        contains(approved.id.value),
      );
    });

    test('12. AI-derived content origin is preserved on proposal', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      );

      final linked = await proposalRepository.findById(approved.id);
      final challenge = linked!.sectionById(StoryProposalSectionId('sec-1'))!;
      expect(challenge.contentOrigin, StoryProposalContentOrigin.derived);
      expect(challenge.heroEdited, isTrue);
      expect(challenge.contentBeforeHeroEdit, 'AI challenge original');

      final story = await storyRepository.findByStoryProposalId(approved.id);
      expect(story!.provenance.proposalContainedDerivedContent, isTrue);
      expect(
        story.provenance.proposalDerivationKind,
        StoryProposalDerivationKind.aiShaped,
      );
    });
  });

  group('Idempotency', () {
    test('materialize twice sequentially yields one Story', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);

      final a = ((await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;
      final b = ((await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      expect(a.id, b.id);
      expect(storyRepository.count, 1);
    });

    test('materialize survives repository reload', () async {
      final temp = await Directory.systemTemp.createTemp('sb13-materialize-');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });

      final fileProposals = FileStoryProposalRepository(rootDirectory: temp);
      final fileStories = FileStoryRepository(rootDirectory: temp);
      final fileCreate = CreateStoryUseCase(
        storyRepository: fileStories,
        heroRepository: heroRepository,
        eventBus: eventBus,
      );
      final fileApprove = ApproveStoryProposalUseCase(
        proposalRepository: fileProposals,
      );
      final fileMaterialize = MaterializeStoryProposalUseCase(
        proposalRepository: fileProposals,
        sessionRepository: sessionRepository,
        storyRepository: fileStories,
        heroRepository: heroRepository,
        createStoryUseCase: fileCreate,
      );

      final ready = await seedReadyProposal();
      // Re-save into file repo
      await fileProposals.save(ready);
      final approved = ((await fileApprove.execute(
        ApproveStoryProposalRequest(proposalId: ready.id),
      )) as Success<StoryProposal>)
          .value;

      final first = ((await fileMaterialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      final restartedProposals =
          FileStoryProposalRepository(rootDirectory: temp);
      final restartedStories = FileStoryRepository(rootDirectory: temp);
      final restartedMaterialize = MaterializeStoryProposalUseCase(
        proposalRepository: restartedProposals,
        sessionRepository: sessionRepository,
        storyRepository: restartedStories,
        heroRepository: heroRepository,
        createStoryUseCase: CreateStoryUseCase(
          storyRepository: restartedStories,
          heroRepository: heroRepository,
          eventBus: eventBus,
        ),
      );

      final second = ((await restartedMaterialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      expect(second.id, first.id);
      expect(second.heroId, heroId);
      expect(second.title.value, first.title.value);
      expect(second.narrative.value, first.narrative.value);
      expect(second.lifecycleStatus, StoryLifecycleStatus.draft);
      expect(second.visibility, StoryVisibility.draft);
      expect(second.provenance.materializedFromProposalId, approved.id);
      expect(second.provenance.sourceSessionId, sessionId);
      expect(await restartedStories.findAll(), hasLength(1));

      final reloadedProposal =
          await restartedProposals.findById(approved.id);
      expect(reloadedProposal!.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(reloadedProposal.materializedStoryId, first.id);
    });
  });

  group('Snapshot round-trip', () {
    test('materialized Story provenance survives snapshot reload', () async {
      final draft = await seedReadyProposal();
      final approved = await approve(draft.id);
      final story = ((await materialize.execute(
        MaterializeStoryProposalRequest(proposalId: approved.id),
      )) as Success<Story>)
          .value;

      final json = StorySnapshotMapper.toJson(story);
      final restored = StorySnapshotMapper.fromJson(json);

      expect(restored.id, story.id);
      expect(restored.heroId, story.heroId);
      expect(restored.title, story.title);
      expect(restored.narrative, story.narrative);
      expect(restored.lifecycleStatus, story.lifecycleStatus);
      expect(restored.visibility, story.visibility);
      expect(
        restored.provenance.materializedFromProposalId,
        approved.id,
      );
      expect(restored.provenance.sourceSessionId, sessionId);
      expect(restored.provenance.proposalContainedDerivedContent, isTrue);

      final proposalJson = StoryProposalSnapshotMapper.toJson(
        (await proposalRepository.findById(approved.id))!,
      );
      final restoredProposal =
          StoryProposalSnapshotMapper.fromJson(proposalJson);
      expect(restoredProposal.materializedStoryId, story.id);
      expect(
        restoredProposal.sections[1].contentOrigin,
        StoryProposalContentOrigin.derived,
      );
    });
  });

  group('Mapper', () {
    test('maps title and narrative into CreateStoryRequest', () {
      final proposal = StoryProposal(
        id: StoryProposalId('prop-1'),
        sessionId: sessionId,
        title: StoryTitle('Mapped'),
        narrative: 'Body text',
        sections: [
          StoryProposalSection(
            id: StoryProposalSectionId('s0'),
            narrativeRole: StoryBuilderNarrativeRole.beginning,
            order: 0,
          contentOrigin: StoryProposalContentOrigin.heroAuthored,
          content: 'Body text',
          sourceResponseIds: [StoryBuilderResponseId('resp-1')],
        ),
        ],
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: sessionId,
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.shapedProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.accepted,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
      );

      final request = const StoryMaterializationMapper().toCreateStoryRequest(
        proposal: proposal,
        heroId: heroId,
        originalLanguage: LanguageCode('en'),
      );

      expect(request.title.value, 'Mapped');
      expect(request.narrative.value, 'Body text');
      expect(request.visibility, StoryVisibility.draft);
      expect(request.provenance!.materializedFromProposalId!.value, 'prop-1');
      expect(
        request.storyId,
        StoryMaterializationMapper.storyIdForProposal(proposal.id),
      );
    });
  });
}
