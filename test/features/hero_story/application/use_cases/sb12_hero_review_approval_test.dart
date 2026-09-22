import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/reject_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/shape_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/reject_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/shape_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_proposal_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingSaveStoryProposalRepository
    implements StoryProposalRepository {
  _FailingSaveStoryProposalRepository(this._inner);

  final InMemoryStoryProposalRepository _inner;

  @override
  Future<void> save(StoryProposal proposal) async {
    throw StateError('simulated save failure');
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
  late InMemoryStoryBuilderSessionRepository sessionRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late BuildStoryProposalUseCase buildProposal;
  late ShapeStoryProposalUseCase shapeProposal;
  late EditStoryProposalUseCase editProposal;
  late ApproveStoryProposalUseCase approveProposal;
  late RejectStoryProposalUseCase rejectProposal;

  setUp(() {
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    start = StartStoryBuilderSessionUseCase(
      sessionRepository: sessionRepository,
      eventBus: eventBus,
    );
    advance = AdvanceStoryBuilderUseCase(
      sessionRepository: sessionRepository,
      strategyResolver: const DefaultStoryBuilderQuestionStrategyResolver(),
      eventBus: eventBus,
    );
    answer = AnswerStoryBuilderPromptUseCase(
      sessionRepository: sessionRepository,
      eventBus: eventBus,
    );
    skip = SkipStoryBuilderPromptUseCase(
      sessionRepository: sessionRepository,
      eventBus: eventBus,
    );
    buildProposal = BuildStoryProposalUseCase(
      sessionRepository: sessionRepository,
      proposalRepository: proposalRepository,
    );
    shapeProposal = ShapeStoryProposalUseCase(
      proposalRepository: proposalRepository,
      sessionRepository: sessionRepository,
      shaper: const DeterministicStoryShaper(),
    );
    editProposal = EditStoryProposalUseCase(
      proposalRepository: proposalRepository,
      sessionRepository: sessionRepository,
    );
    approveProposal = ApproveStoryProposalUseCase(
      proposalRepository: proposalRepository,
    );
    rejectProposal = RejectStoryProposalUseCase(
      proposalRepository: proposalRepository,
    );
  });

  Future<StoryBuilderSessionId> startSession() async {
    final id = StoryBuilderSessionId.generate();
    await start.execute(
      StartStoryBuilderSessionRequest(
        sessionId: id,
        heroId: HeroId.generate(),
        mode: StoryBuilderMode.guided,
      ),
    );
    return id;
  }

  Future<AdvanceStoryBuilderResult> advanceOnce(
    StoryBuilderSessionId id,
  ) async {
    final result = await advance.execute(
      AdvanceStoryBuilderRequest(sessionId: id),
    );
    return (result as Success<AdvanceStoryBuilderResult>).value;
  }

  Future<void> answerCurrent(StoryBuilderSessionId id, String text) async {
    final step = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        promptId: step.currentPrompt!.id,
        responseId: StoryBuilderResponseId.generate(),
        text: text,
      ),
    );
  }

  Future<void> skipCurrent(StoryBuilderSessionId id) async {
    final step = await advanceOnce(id);
    await skip.execute(
      SkipStoryBuilderPromptRequest(
        sessionId: id,
        promptId: step.currentPrompt!.id,
        responseId: StoryBuilderResponseId.generate(),
      ),
    );
  }

  Future<StoryProposal> buildAndShapeReadyProposal() async {
    final id = await startSession();
    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final role = prompt.narrativeRole!;
      if (role == StoryBuilderNarrativeRole.beginning ||
          role == StoryBuilderNarrativeRole.challenge ||
          role == StoryBuilderNarrativeRole.turningPoint) {
        await answerCurrent(id, 'Answer for ${role.name}');
      } else {
        await skipCurrent(id);
      }
    }
    // Drain completion
    await advanceOnce(id);

    final built = await buildProposal.execute(
      BuildStoryProposalRequest(sessionId: id),
    );
    final proposal = (built as Success<StoryProposal>).value;
    final shaped = await shapeProposal.execute(
      ShapeStoryProposalRequest(proposalId: proposal.id),
    );
    return (shaped as Success<StoryProposal>).value;
  }

  group('EditStoryProposalUseCase', () {
    test('load → edit → save preserves provenance and session', () async {
      final proposal = await buildAndShapeReadyProposal();
      final sessionBefore =
          (await sessionRepository.findById(proposal.sessionId))!;
      final section = proposal.sections.firstWhere((s) => s.hasContent);

      final result = await editProposal.execute(
        EditStoryProposalRequest(
          proposalId: proposal.id,
          title: 'Edited Title',
          updateTitle: true,
          summary: 'Edited summary',
          updateSummary: true,
          sectionEdits: [
            StoryProposalSectionEdit(
              sectionId: section.id,
              content: 'Hero edited this section.',
            ),
          ],
          editedAt: DateTime.utc(2026, 9, 22, 15),
        ),
      );

      expect(result, isA<Success<StoryProposal>>());
      final edited = (result as Success<StoryProposal>).value;
      expect(edited.title?.value, 'Edited Title');
      expect(edited.derivedSummary, 'Edited summary');
      expect(
        edited.sectionById(section.id)!.content,
        'Hero edited this section.',
      );
      expect(
        edited.sectionById(section.id)!.contentOrigin,
        section.contentOrigin,
      );
      expect(
        edited.sectionById(section.id)!.sourceResponseIds,
        section.sourceResponseIds,
      );

      final sessionAfter =
          (await sessionRepository.findById(proposal.sessionId))!;
      expect(sessionAfter.responses.length, sessionBefore.responses.length);
      expect(sessionAfter.storyId, sessionBefore.storyId);
      expect(storyRepository, isNotNull);
      expect(await storyRepository.findAll(), isEmpty);
    });

    test('loading failure yields Failure with no mutation', () async {
      final result = await editProposal.execute(
        EditStoryProposalRequest(
          proposalId: StoryProposalId('missing'),
          title: 'x',
          updateTitle: true,
        ),
      );
      expect(result, isA<Failure>());
    });
  });

  group('ApproveStoryProposalUseCase', () {
    test('explicit approve persists accepted lifecycle', () async {
      final proposal = await buildAndShapeReadyProposal();
      final result = await approveProposal.execute(
        ApproveStoryProposalRequest(
          proposalId: proposal.id,
          approvedAt: DateTime.utc(2026, 9, 22, 16),
        ),
      );
      expect(result, isA<Success<StoryProposal>>());
      final approved = (result as Success<StoryProposal>).value;
      expect(approved.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(
        approved.review.decision,
        StoryProposalReviewDecision.approved,
      );

      final reloaded = await proposalRepository.findById(proposal.id);
      expect(reloaded!.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(await storyRepository.findAll(), isEmpty);
    });

    test('save failure does not claim approval success', () async {
      final proposal = await buildAndShapeReadyProposal();
      final failing = ApproveStoryProposalUseCase(
        proposalRepository: _FailingSaveStoryProposalRepository(
          proposalRepository,
        ),
      );
      final result = await failing.execute(
        ApproveStoryProposalRequest(proposalId: proposal.id),
      );
      expect(result, isA<Failure>());
      final stored = await proposalRepository.findById(proposal.id);
      expect(stored!.lifecycle, StoryProposalLifecycleStatus.readyForReview);
    });

    test('build/shape alone never leaves proposal accepted', () async {
      final proposal = await buildAndShapeReadyProposal();
      expect(proposal.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(proposal.review.decision, isNull);
    });
  });

  group('RejectStoryProposalUseCase', () {
    test('explicit reject persists rejected lifecycle', () async {
      final proposal = await buildAndShapeReadyProposal();
      final result = await rejectProposal.execute(
        RejectStoryProposalRequest(
          proposalId: proposal.id,
          rejectedAt: DateTime.utc(2026, 9, 22, 17),
        ),
      );
      expect(result, isA<Success<StoryProposal>>());
      final rejected = (result as Success<StoryProposal>).value;
      expect(rejected.lifecycle, StoryProposalLifecycleStatus.rejected);

      final reloaded = await proposalRepository.findById(proposal.id);
      expect(reloaded!.lifecycle, StoryProposalLifecycleStatus.rejected);
      expect(await storyRepository.findAll(), isEmpty);
    });
  });

  group('approval invalidation', () {
    test('edit after approve returns readyForReview', () async {
      final proposal = await buildAndShapeReadyProposal();
      await approveProposal.execute(
        ApproveStoryProposalRequest(proposalId: proposal.id),
      );
      final edited = await editProposal.execute(
        EditStoryProposalRequest(
          proposalId: proposal.id,
          title: 'Post-approval edit',
          updateTitle: true,
        ),
      );
      final value = (edited as Success<StoryProposal>).value;
      expect(value.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(value.review.isApprovalStale, isTrue);
    });
  });

  group('persistence round-trip', () {
    test('accepted / rejected / edited review state round-trips', () async {
      final root = await Directory.systemTemp.createTemp('sb12-proposal-');
      addTearDown(() => root.delete(recursive: true));
      final fileRepo = FileStoryProposalRepository(rootDirectory: root);

      final proposal = await buildAndShapeReadyProposal();
      await proposalRepository.delete(proposal.id);

      // Seed file repo from shaped proposal via mapper path.
      await fileRepo.save(proposal);

      final editedUseCase = EditStoryProposalUseCase(
        proposalRepository: fileRepo,
      );
      final approveUseCase = ApproveStoryProposalUseCase(
        proposalRepository: fileRepo,
      );
      final rejectUseCase = RejectStoryProposalUseCase(
        proposalRepository: fileRepo,
      );

      final edited = (await editedUseCase.execute(
        EditStoryProposalRequest(
          proposalId: proposal.id,
          title: 'Durable Title',
          updateTitle: true,
          sectionEdits: [
            StoryProposalSectionEdit(
              sectionId: proposal.sections.firstWhere((s) => s.hasContent).id,
              content: 'Durable section edit',
            ),
          ],
        ),
      ) as Success<StoryProposal>)
          .value;

      final json = StoryProposalSnapshotMapper.toJson(edited);
      final fromJson = StoryProposalSnapshotMapper.fromJson(json);
      expect(fromJson.title?.value, 'Durable Title');
      expect(fromJson.review.revision, 1);
      expect(fromJson.sections.any((s) => s.heroEdited), isTrue);

      final approved = (await approveUseCase.execute(
        ApproveStoryProposalRequest(proposalId: proposal.id),
      ) as Success<StoryProposal>)
          .value;
      final approvedReload = await fileRepo.findById(proposal.id);
      expect(approvedReload!.lifecycle, StoryProposalLifecycleStatus.accepted);
      expect(approvedReload.review.decision, StoryProposalReviewDecision.approved);
      expect(approved.lifecycle, StoryProposalLifecycleStatus.accepted);

      // Reject after begin-style reopen via edit invalidation path:
      final reopened = (await editedUseCase.execute(
        EditStoryProposalRequest(
          proposalId: proposal.id,
          title: 'After accept',
          updateTitle: true,
        ),
      ) as Success<StoryProposal>)
          .value;
      expect(reopened.lifecycle, StoryProposalLifecycleStatus.readyForReview);

      final rejected = (await rejectUseCase.execute(
        RejectStoryProposalRequest(proposalId: proposal.id),
      ) as Success<StoryProposal>)
          .value;
      final rejectedReload = await fileRepo.findById(proposal.id);
      expect(rejectedReload!.lifecycle, StoryProposalLifecycleStatus.rejected);
      expect(rejected.review.decision, StoryProposalReviewDecision.rejected);

      // Legacy snapshot without review keys still loads.
      final legacy = Map<String, dynamic>.from(
        StoryProposalSnapshotMapper.toJson(proposal),
      )..remove('review');
      for (final section in (legacy['sections'] as List).cast<Map>()) {
        section.remove('heroEdited');
        section.remove('heroEditedAt');
        section.remove('contentBeforeHeroEdit');
      }
      final legacyLoaded = StoryProposalSnapshotMapper.fromJson(legacy);
      expect(legacyLoaded.review.revision, 0);
      expect(legacyLoaded.sections.every((s) => !s.heroEdited), isTrue);
    });
  });
}
