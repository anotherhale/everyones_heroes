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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_intent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/skip_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/start_story_builder_session_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_proposal_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository sessionRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late EventBus eventBus;
  late StartStoryBuilderSessionUseCase start;
  late AdvanceStoryBuilderUseCase advance;
  late AnswerStoryBuilderPromptUseCase answer;
  late SkipStoryBuilderPromptUseCase skip;
  late SetStoryBuilderIntentUseCase setIntent;
  late BuildStoryProposalUseCase buildProposal;
  late DeterministicStoryStructureBuilder structureBuilder;
  late DeterministicStoryBuilderUnderstandingBuilder understandingBuilder;
  late DeterministicStoryProposalBuilder proposalBuilder;

  setUp(() {
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );
    structureBuilder = const DeterministicStoryStructureBuilder();
    understandingBuilder = const DeterministicStoryBuilderUnderstandingBuilder();
    proposalBuilder = const DeterministicStoryProposalBuilder();
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
    setIntent = SetStoryBuilderIntentUseCase(
      sessionRepository: sessionRepository,
      eventBus: eventBus,
    );
    buildProposal = BuildStoryProposalUseCase(
      sessionRepository: sessionRepository,
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

  Future<void> answerCurrent(
    StoryBuilderSessionId id,
    String text, {
    StoryBuilderResponseId? responseId,
  }) async {
    final step = await advanceOnce(id);
    await answer.execute(
      AnswerStoryBuilderPromptRequest(
        sessionId: id,
        promptId: step.currentPrompt!.id,
        responseId: responseId ?? StoryBuilderResponseId.generate(),
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

  Future<(StoryBuilderSession, StoryProposal)> buildFromAnswers({
    required Map<StoryBuilderNarrativeRole, String?> answers,
    StoryBuilderIntent? intent,
    DateTime? createdAt,
    StoryProposalId? proposalId,
  }) async {
    final id = await startSession();
    if (intent != null) {
      await setIntent.execute(
        SetStoryBuilderIntentRequest(sessionId: id, intent: intent),
      );
    }

    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final role = prompt.narrativeRole!;
      if (!answers.containsKey(role)) {
        break;
      }
      final text = answers[role];
      if (text == null) {
        await skipCurrent(id);
      } else {
        await answerCurrent(id, text);
      }
    }

    final session = (await sessionRepository.findById(id))!;
    final structure = structureBuilder.build(session);
    final understanding = understandingBuilder.build(
      session: session,
      structure: structure,
      analyzedAt: createdAt ?? DateTime.utc(2026, 9, 22, 12),
    );
    final proposal = proposalBuilder.build(
      session: session,
      structure: structure,
      understanding: understanding,
      proposalId: proposalId,
      createdAt: createdAt ?? DateTime.utc(2026, 9, 22, 12),
    );
    return (session, proposal);
  }

  group('domain StoryProposal', () {
    test('has its own id distinct from session id', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'It began quietly.',
        },
        proposalId: StoryProposalId('proposal-1'),
      );
      expect(proposal.id.value, 'proposal-1');
      expect(proposal.id.value, isNot(proposal.sessionId.value));
    });

    test('retains session provenance and intent', () async {
      final intent = StoryBuilderIntent(
        purpose: StoryBuilderPurpose.inspireSomeone,
        themes: const [StoryBuilderTheme.perseverance],
      );
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Start',
          StoryBuilderNarrativeRole.challenge: 'Hard challenge',
        },
        intent: intent,
      );
      expect(proposal.sessionId, session.id);
      expect(proposal.provenance.sessionId, session.id);
      expect(proposal.intent.purpose, StoryBuilderPurpose.inspireSomeone);
      expect(proposal.intent.themes, [StoryBuilderTheme.perseverance]);
    });

    test('contains ordered narrative sections with roles', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          for (final role in StoryBuilderNarrativeRole.values)
            role: 'Text for ${role.name}',
        },
      );
      expect(proposal.sectionCount, 11);
      for (var i = 0; i < 11; i++) {
        expect(proposal.sections[i].order, i);
      }
      expect(
        proposal.sections.map((s) => s.narrativeRole).toList(),
        StoryBuilderNarrativeRole.values,
      );
    });

    test('sections retain source response ids', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Beginning words',
          StoryBuilderNarrativeRole.challenge: 'Challenge words',
        },
      );
      final beginningResponse = session.responses.firstWhere(
        (r) =>
            session.prompts.any(
              (p) =>
                  p.id == r.promptId &&
                  p.narrativeRole == StoryBuilderNarrativeRole.beginning,
            ),
      );
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
        [beginningResponse.id],
      );
    });

    test('skipped responses remain skipped without invented content', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'I began.',
          StoryBuilderNarrativeRole.challenge: null,
          StoryBuilderNarrativeRole.importance: 'It mattered.',
        },
      );
      final challenge =
          proposal.sectionForRole(StoryBuilderNarrativeRole.challenge)!;
      expect(challenge.wasSkipped, isTrue);
      expect(challenge.content, isNull);
      expect(challenge.sourceResponseIds, isNotEmpty);
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.importance)!.content,
        'It mattered.',
      );
    });

    test('lifecycle defaults to readyForReview with controllable timestamps',
        () async {
      final at = DateTime.utc(2026, 9, 22, 15, 30);
      final (_, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: 'Once'},
        createdAt: at,
      );
      expect(proposal.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(proposal.createdAt, at);
      expect(proposal.updatedAt, at);
      expect(proposal.title, isNull);
    });
  });

  group('deterministic builder role mapping', () {
    test('maps each SB.4 role to proposal content from Hero responses',
        () async {
      final texts = {
        StoryBuilderNarrativeRole.beginning: 'Beginning text',
        StoryBuilderNarrativeRole.challenge: 'Challenge text',
        StoryBuilderNarrativeRole.importance: 'Importance text',
        StoryBuilderNarrativeRole.struggle: 'Struggle text',
        StoryBuilderNarrativeRole.stakes: 'Stakes text',
        StoryBuilderNarrativeRole.turningPoint: 'Turning point text',
        StoryBuilderNarrativeRole.decision: 'Decision text',
        StoryBuilderNarrativeRole.action: 'Action text',
        StoryBuilderNarrativeRole.outcome: 'Outcome text',
        StoryBuilderNarrativeRole.reflection: 'Reflection text',
        StoryBuilderNarrativeRole.message: 'Message text',
      };
      final (_, proposal) = await buildFromAnswers(answers: texts);
      for (final entry in texts.entries) {
        expect(proposal.sectionForRole(entry.key)!.content, entry.value);
        expect(
          proposal.sectionForRole(entry.key)!.contentOrigin,
          StoryProposalContentOrigin.heroAuthored,
        );
      }
    });

    test('same session produces equivalent proposal content', () async {
      final id = await startSession();
      await answerCurrent(id, 'Consistent beginning');
      await answerCurrent(id, 'Consistent challenge');
      final session = (await sessionRepository.findById(id))!;
      final structure = structureBuilder.build(session);
      final understanding = understandingBuilder.build(
        session: session,
        structure: structure,
        analyzedAt: DateTime.utc(2026, 9, 22),
      );
      final a = proposalBuilder.build(
        session: session,
        structure: structure,
        understanding: understanding,
        createdAt: DateTime.utc(2026, 9, 22),
      );
      final b = proposalBuilder.build(
        session: session,
        structure: structure,
        understanding: understanding,
        createdAt: DateTime.utc(2026, 9, 22),
      );
      expect(a.id, isNot(b.id));
      expect(a.isContentEquivalentTo(b), isTrue);
      expect(session.responses.length, 2);
    });

    test('missing responses do not invent content', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Only beginning',
        },
      );
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.beginning)!.content,
        'Only beginning',
      );
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.challenge)!.isEmpty,
        isTrue,
      );
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.challenge)!.content,
        isNull,
      );
    });

    test('does not mutate original session', () async {
      final (session, _) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Keep me',
        },
      );
      final before = List.of(session.responses.map((r) => r.text));
      final structure = structureBuilder.build(session);
      final understanding = understandingBuilder.build(
        session: session,
        structure: structure,
      );
      proposalBuilder.build(
        session: session,
        structure: structure,
        understanding: understanding,
      );
      expect(session.responses.map((r) => r.text).toList(), before);
      expect(session.storyId, isNull);
    });
  });

  group('understanding integration', () {
    test('understanding metadata does not replace Hero-authored material',
        () async {
      final id = await startSession();
      await answerCurrent(id, 'Hero wrote this beginning.');
      final session = (await sessionRepository.findById(id))!;
      final structure = structureBuilder.build(session);
      final understanding = StoryBuilderUnderstanding(
        sessionId: id,
        kind: StoryBuilderUnderstandingKind.deterministic,
        structure: structure,
        intentSnapshot: session.intent,
        processingVersion:
            StoryBuilderUnderstanding.deterministicProcessingVersion,
        analyzedAt: DateTime.utc(2026, 9, 22),
        derivedSummary: 'AI-sounding summary that is not Hero text.',
        providerLabel: 'deterministic',
      );
      final proposal = proposalBuilder.build(
        session: session,
        structure: structure,
        understanding: understanding,
      );
      expect(
        proposal.sectionForRole(StoryBuilderNarrativeRole.beginning)!.content,
        'Hero wrote this beginning.',
      );
      expect(
        proposal.derivedSummary,
        'AI-sounding summary that is not Hero text.',
      );
      expect(proposal.narrative, 'Hero wrote this beginning.');
      expect(proposal.narrative, isNot(contains('AI-sounding')));
    });

    test('works with deterministic understanding without AI proxy', () async {
      final result = await buildProposal.execute(
        BuildStoryProposalRequest(
          sessionId: await () async {
            final id = await startSession();
            await answerCurrent(id, 'Offline material');
            return id;
          }(),
        ),
      );
      expect(result, isA<Success<StoryProposal>>());
      final proposal = (result as Success<StoryProposal>).value;
      expect(
        proposal.provenance.derivationKind,
        StoryProposalDerivationKind.deterministic,
      );
      expect(
        proposal.provenance.understandingKind,
        StoryBuilderUnderstandingKind.deterministic,
      );
    });
  });

  group('application BuildStoryProposalUseCase', () {
    test('missing session returns typed failure', () async {
      final result = await buildProposal.execute(
        BuildStoryProposalRequest(
          sessionId: StoryBuilderSessionId('missing-session'),
        ),
      );
      expect(result, isA<Failure>());
      expect(
        (result as Failure).error,
        contains('not found'),
      );
    });

    test('valid session returns proposal without creating Story or mutating',
        () async {
      final id = await startSession();
      await setIntent.execute(
        SetStoryBuilderIntentRequest(
          sessionId: id,
          intent: StoryBuilderIntent(
            purpose: StoryBuilderPurpose.shareALesson,
            themes: const [StoryBuilderTheme.courage],
          ),
        ),
      );
      await answerCurrent(id, 'Lesson beginning');
      await answerCurrent(id, 'Lesson challenge');

      final before = await sessionRepository.findById(id);
      final storyCountBefore = (await storyRepository.findAll()).length;
      final responsesBefore = List.of(before!.responses);

      final result = await buildProposal.execute(
        BuildStoryProposalRequest(
          sessionId: id,
          createdAt: DateTime.utc(2026, 9, 22, 18),
        ),
      );

      expect(result, isA<Success<StoryProposal>>());
      final proposal = (result as Success<StoryProposal>).value;
      expect(proposal.sessionId, id);
      expect(proposal.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(await proposalRepository.findById(proposal.id), isNotNull);

      final after = await sessionRepository.findById(id);
      expect(after!.responses.length, responsesBefore.length);
      for (var i = 0; i < responsesBefore.length; i++) {
        expect(after.responses[i].text, responsesBefore[i].text);
      }
      expect(after.storyId, isNull);
      expect((await storyRepository.findAll()).length, storyCountBefore);
    });

    test('incomplete session with no answers fails', () async {
      final id = await startSession();
      final result = await buildProposal.execute(
        BuildStoryProposalRequest(sessionId: id),
      );
      expect(result, isA<Failure>());
      expect((result as Failure).error, contains('no answered material'));
    });
  });

  group('persistence', () {
    test('proposal survives reload with sections, provenance, lifecycle',
        () async {
      final dir = await Directory.systemTemp.createTemp('sb9-proposals-');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final fileRepo = FileStoryProposalRepository(rootDirectory: dir);
      final id = await startSession();
      await answerCurrent(id, 'Persisted beginning');
      await skipCurrent(id);
      await answerCurrent(id, 'Persisted importance');

      final useCase = BuildStoryProposalUseCase(
        sessionRepository: sessionRepository,
        proposalRepository: fileRepo,
      );
      final createdAt = DateTime.utc(2026, 9, 22, 20);
      final result = await useCase.execute(
        BuildStoryProposalRequest(sessionId: id, createdAt: createdAt),
      );
      final proposal = (result as Success<StoryProposal>).value;

      final reloadedRepo = FileStoryProposalRepository(rootDirectory: dir);
      final loaded = await reloadedRepo.findById(proposal.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, proposal.id);
      expect(loaded.sessionId, proposal.sessionId);
      expect(loaded.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(loaded.createdAt, createdAt);
      expect(loaded.updatedAt, createdAt);
      expect(loaded.sectionCount, 11);
      expect(
        loaded.sectionForRole(StoryBuilderNarrativeRole.beginning)!.content,
        'Persisted beginning',
      );
      expect(
        loaded.sectionForRole(StoryBuilderNarrativeRole.challenge)!.wasSkipped,
        isTrue,
      );
      expect(
        loaded
            .sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
        proposal
            .sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
      );
      expect(loaded.provenance.sessionId, id);
      expect(
        loaded.provenance.processingVersion,
        StoryProposal.deterministicProcessingVersion,
      );

      final roundTrip = StoryProposalSnapshotMapper.fromJson(
        StoryProposalSnapshotMapper.toJson(loaded),
      );
      expect(roundTrip.isContentEquivalentTo(loaded), isTrue);
    });
  });
}
