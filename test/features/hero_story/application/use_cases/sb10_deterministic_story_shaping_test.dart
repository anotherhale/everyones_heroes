import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_section_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/advance_story_builder_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/answer_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/build_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/set_story_builder_intent_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/shape_story_proposal_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/advance_story_builder_result.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/advance_story_builder_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/answer_story_builder_prompt_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/build_story_proposal_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/set_story_builder_intent_use_case.dart';
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
  late ShapeStoryProposalUseCase shapeProposal;
  late DeterministicStoryStructureBuilder structureBuilder;
  late DeterministicStoryBuilderUnderstandingBuilder understandingBuilder;
  late DeterministicStoryProposalBuilder proposalBuilder;
  late DeterministicStoryShaper shaper;

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
    shaper = const DeterministicStoryShaper();
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
    shapeProposal = ShapeStoryProposalUseCase(
      proposalRepository: proposalRepository,
      sessionRepository: sessionRepository,
      shaper: shaper,
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

  group('port / strategy', () {
    test('DeterministicStoryShaper implements StoryShaperPort', () {
      const StoryShaperPort port = DeterministicStoryShaper();
      expect(port, isA<DeterministicStoryShaper>());
    });

    test('shaper produces deterministic results', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'It began.',
          StoryBuilderNarrativeRole.challenge: 'The hard part.',
          StoryBuilderNarrativeRole.outcome: 'I grew.',
        },
        proposalId: StoryProposalId('det-1'),
      );
      final a = shaper.shapeSync(
        proposal,
        shapedAt: DateTime.utc(2026, 9, 22, 13),
      );
      final b = shaper.shapeSync(
        proposal,
        shapedAt: DateTime.utc(2026, 9, 22, 13),
      );
      expect(a.isContentEquivalentTo(b), isTrue);
      expect(a.narrative, b.narrative);
      expect(a.provenance.processingVersion, b.provenance.processingVersion);
    });
  });

  group('content preservation', () {
    test('hero-authored content remains byte-for-byte unchanged', () async {
      const heroText = 'I stood still. Then I moved — carefully.';
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: heroText,
          StoryBuilderNarrativeRole.challenge: 'Fear!',
        },
      );
      final shaped = shaper.shapeSync(proposal);
      final beginning = shaped.sectionForRole(
        StoryBuilderNarrativeRole.beginning,
      )!;
      expect(beginning.content, same(proposal.sections
          .firstWhere(
            (s) => s.narrativeRole == StoryBuilderNarrativeRole.beginning,
          )
          .content));
      expect(beginning.content, heroText);
      expect(
        beginning.contentOrigin,
        StoryProposalContentOrigin.heroAuthored,
      );
    });

    test('hero-authored punctuation and capitalization preserved', () async {
      const heroText = 'WHY?!  "Because," she said...';
      final (_, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: heroText},
      );
      final shaped = shaper.shapeSync(proposal);
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.beginning)!.content,
        heroText,
      );
    });

    test('hero-authored source response IDs remain attached', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Start',
          StoryBuilderNarrativeRole.challenge: 'Hard',
        },
      );
      final shaped = shaper.shapeSync(proposal);
      final beginningResponse = session.responses.firstWhere(
        (r) => session.prompts.any(
          (p) =>
              p.id == r.promptId &&
              p.narrativeRole == StoryBuilderNarrativeRole.beginning,
        ),
      );
      expect(
        shaped
            .sectionForRole(StoryBuilderNarrativeRole.beginning)!
            .sourceResponseIds,
        [beginningResponse.id],
      );
    });

    test('derived content remains marked derived', () {
      final section = StoryProposalSection(
        id: StoryProposalSectionId('sec-derived'),
        narrativeRole: StoryBuilderNarrativeRole.message,
        order: 0,
        contentOrigin: StoryProposalContentOrigin.derived,
        content: 'Structural note',
        sourceResponseIds: const [],
      );
      final proposal = StoryProposal(
        id: StoryProposalId('p-derived'),
        sessionId: StoryBuilderSessionId('s1'),
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: StoryBuilderSessionId('s1'),
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.deterministicProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
        sections: [section],
      );
      final shaped = shaper.shapeSync(proposal);
      expect(
        shaped.sections.single.contentOrigin,
        StoryProposalContentOrigin.derived,
      );
      expect(shaped.sections.single.content, 'Structural note');
    });

    test('shaping does not invent content for skipped or empty roles', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Start only',
          StoryBuilderNarrativeRole.challenge: null,
        },
      );
      final shaped = shaper.shapeSync(proposal);
      final stakes = shaped.sectionForRole(StoryBuilderNarrativeRole.stakes);
      final challenge =
          shaped.sectionForRole(StoryBuilderNarrativeRole.challenge)!;
      expect(challenge.wasSkipped, isTrue);
      expect(challenge.content, isNull);
      expect(stakes?.content, isNull);
      expect(shaped.narrative, 'Start only');
      expect(shaped.narrative, isNot(contains('stakes')));
      expect(shaped.narrative, isNot(contains('extremely high')));
    });
  });

  group('narrative ordering', () {
    test('sections follow canonical SB.4 narrative order', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          for (final role in StoryBuilderNarrativeRole.values)
            role: 'Text for ${role.name}',
        },
      );
      // Deliberately reverse before shaping to prove reorder.
      final reversed = StoryProposal(
        id: proposal.id,
        sessionId: proposal.sessionId,
        title: proposal.title,
        narrative: proposal.narrative,
        intent: proposal.intent,
        provenance: proposal.provenance,
        lifecycle: proposal.lifecycle,
        createdAt: proposal.createdAt,
        updatedAt: proposal.updatedAt,
        derivedSummary: proposal.derivedSummary,
        sections: [
          for (var i = 0; i < proposal.sections.length; i++)
            StoryProposalSection(
              id: proposal.sections[proposal.sections.length - 1 - i].id,
              narrativeRole: proposal
                  .sections[proposal.sections.length - 1 - i].narrativeRole,
              order: i,
              contentOrigin: proposal
                  .sections[proposal.sections.length - 1 - i].contentOrigin,
              content: proposal
                  .sections[proposal.sections.length - 1 - i].content,
              sourceResponseIds: proposal
                  .sections[proposal.sections.length - 1 - i]
                  .sourceResponseIds,
              wasSkipped: proposal
                  .sections[proposal.sections.length - 1 - i].wasSkipped,
            ),
        ],
      );
      final shaped = shaper.shapeSync(reversed);
      expect(
        shaped.sections.map((s) => s.narrativeRole).toList(),
        StoryBuilderNarrativeRole.values,
      );
      for (var i = 0; i < shaped.sections.length; i++) {
        expect(shaped.sections[i].order, i);
      }
    });

    test('populated sections are retained', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'A',
          StoryBuilderNarrativeRole.challenge: 'B',
          StoryBuilderNarrativeRole.importance: null,
          StoryBuilderNarrativeRole.struggle: null,
          StoryBuilderNarrativeRole.stakes: null,
          StoryBuilderNarrativeRole.turningPoint: null,
          StoryBuilderNarrativeRole.decision: null,
          StoryBuilderNarrativeRole.action: null,
          StoryBuilderNarrativeRole.outcome: 'C',
        },
      );
      final shaped = shaper.shapeSync(proposal);
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.beginning)!.content,
        'A',
      );
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.challenge)!.content,
        'B',
      );
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.outcome)!.content,
        'C',
      );
    });

    test('empty sections are omitted from narrative presentation', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Only start',
          StoryBuilderNarrativeRole.challenge: null,
        },
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.narrative, 'Only start');
      // Skipped/empty slots remain in the model for provenance.
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.challenge)!.wasSkipped,
        isTrue,
      );
      expect(
        shaped.sectionForRole(StoryBuilderNarrativeRole.stakes)!.isEmpty ||
            shaped.sectionForRole(StoryBuilderNarrativeRole.stakes)!.content ==
                null,
        isTrue,
      );
    });

    test('skipped sections are not converted into content', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Begin',
          StoryBuilderNarrativeRole.challenge: null,
          StoryBuilderNarrativeRole.importance: 'Matters',
        },
      );
      final shaped = shaper.shapeSync(proposal);
      final challenge =
          shaped.sectionForRole(StoryBuilderNarrativeRole.challenge)!;
      expect(challenge.wasSkipped, isTrue);
      expect(challenge.content, isNull);
      expect(shaped.narrative, isNot(contains('must have meant')));
    });
  });

  group('duplicate handling', () {
    test('exact duplicate content is omitted from narrative once', () {
      final idA = StoryBuilderResponseId('r-a');
      final idB = StoryBuilderResponseId('r-b');
      final proposal = StoryProposal(
        id: StoryProposalId('dup-1'),
        sessionId: StoryBuilderSessionId('s-dup'),
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: StoryBuilderSessionId('s-dup'),
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.deterministicProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
        sections: [
          StoryProposalSection(
            id: StoryProposalSectionId('s1'),
            narrativeRole: StoryBuilderNarrativeRole.beginning,
            order: 0,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'Same words exactly.',
            sourceResponseIds: [idA],
          ),
          StoryProposalSection(
            id: StoryProposalSectionId('s2'),
            narrativeRole: StoryBuilderNarrativeRole.challenge,
            order: 1,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'Same words exactly.',
            sourceResponseIds: [idB],
          ),
        ],
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.narrative, 'Same words exactly.');
      // Both sections retained with provenance.
      expect(shaped.sections.length, 2);
      expect(shaped.sections[0].sourceResponseIds, [idA]);
      expect(shaped.sections[1].sourceResponseIds, [idB]);
    });

    test('case and whitespace normalization detects duplicates', () {
      final proposal = StoryProposal(
        id: StoryProposalId('dup-2'),
        sessionId: StoryBuilderSessionId('s-dup2'),
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: StoryBuilderSessionId('s-dup2'),
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.deterministicProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
        sections: [
          StoryProposalSection(
            id: StoryProposalSectionId('s1'),
            narrativeRole: StoryBuilderNarrativeRole.beginning,
            order: 0,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: '  Hello   World  ',
            sourceResponseIds: [StoryBuilderResponseId('r1')],
          ),
          StoryProposalSection(
            id: StoryProposalSectionId('s2'),
            narrativeRole: StoryBuilderNarrativeRole.challenge,
            order: 1,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'hello world',
            sourceResponseIds: [StoryBuilderResponseId('r2')],
          ),
        ],
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.narrative, '  Hello   World  ');
      expect(
        DeterministicStoryShaper.normalizeForDuplicateDetection(
          '  Hello   World  ',
        ),
        'hello world',
      );
    });

    test('similar-but-not-identical text is not treated as duplicate', () {
      final proposal = StoryProposal(
        id: StoryProposalId('dup-3'),
        sessionId: StoryBuilderSessionId('s-dup3'),
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: StoryBuilderSessionId('s-dup3'),
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.deterministicProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.readyForReview,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
        sections: [
          StoryProposalSection(
            id: StoryProposalSectionId('s1'),
            narrativeRole: StoryBuilderNarrativeRole.beginning,
            order: 0,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'I was scared.',
            sourceResponseIds: [StoryBuilderResponseId('r1')],
          ),
          StoryProposalSection(
            id: StoryProposalSectionId('s2'),
            narrativeRole: StoryBuilderNarrativeRole.challenge,
            order: 1,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'I felt afraid.',
            sourceResponseIds: [StoryBuilderResponseId('r2')],
          ),
        ],
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.narrative, 'I was scared.\n\nI felt afraid.');
    });
  });

  group('provenance', () {
    test('session ID and understanding metadata survive shaping', () async {
      final intent = StoryBuilderIntent(
        purpose: StoryBuilderPurpose.inspireSomeone,
        themes: const [StoryBuilderTheme.perseverance],
      );
      final (session, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: 'Words'},
        intent: intent,
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.sessionId, session.id);
      expect(shaped.provenance.sessionId, session.id);
      expect(shaped.provenance.understandingKind, isNotNull);
      expect(shaped.provenance.understandingProcessingVersion, isNotNull);
      expect(shaped.intent.purpose, StoryBuilderPurpose.inspireSomeone);
      expect(
        shaped.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );
    });

    test('source response IDs and content origin remain correct', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Begin',
          StoryBuilderNarrativeRole.challenge: 'Challenge',
        },
      );
      final shaped = shaper.shapeSync(proposal);
      for (final role in [
        StoryBuilderNarrativeRole.beginning,
        StoryBuilderNarrativeRole.challenge,
      ]) {
        final before = proposal.sectionForRole(role)!;
        final after = shaped.sectionForRole(role)!;
        expect(after.sourceResponseIds, before.sourceResponseIds);
        expect(after.contentOrigin, StoryProposalContentOrigin.heroAuthored);
        expect(after.content, before.content);
      }
      expect(session.responses, isNotEmpty);
    });
  });

  group('immutability', () {
    test('source proposal is unchanged after shaping', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Original',
          StoryBuilderNarrativeRole.challenge: 'Also original',
        },
      );
      final narrativeBefore = proposal.narrative;
      final contentsBefore = [
        for (final s in proposal.sections) s.content,
      ];
      final versionBefore = proposal.provenance.processingVersion;
      final shaped = shaper.shapeSync(proposal);

      expect(proposal.narrative, narrativeBefore);
      expect(proposal.provenance.processingVersion, versionBefore);
      for (var i = 0; i < proposal.sections.length; i++) {
        expect(proposal.sections[i].content, contentsBefore[i]);
      }
      expect(identical(shaped, proposal), isFalse);
      expect(
        shaped.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );
    });
  });

  group('lifecycle', () {
    test('shaping does not result in accepted', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: 'Text'},
      );
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(shaped.lifecycle, isNot(StoryProposalLifecycleStatus.accepted));
    });

    test('accepted source returns to readyForReview', () {
      final accepted = StoryProposal(
        id: StoryProposalId('acc-1'),
        sessionId: StoryBuilderSessionId('s-acc'),
        intent: StoryBuilderIntent.empty(),
        provenance: StoryProposalProvenance(
          sessionId: StoryBuilderSessionId('s-acc'),
          derivationKind: StoryProposalDerivationKind.deterministic,
          processingVersion: StoryProposal.deterministicProcessingVersion,
        ),
        lifecycle: StoryProposalLifecycleStatus.accepted,
        createdAt: DateTime.utc(2026, 9, 22),
        updatedAt: DateTime.utc(2026, 9, 22),
        sections: [
          StoryProposalSection(
            id: StoryProposalSectionId('s1'),
            narrativeRole: StoryBuilderNarrativeRole.beginning,
            order: 0,
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
            content: 'Kept',
            sourceResponseIds: [StoryBuilderResponseId('r1')],
          ),
        ],
      );
      final shaped = shaper.shapeSync(accepted);
      expect(shaped.lifecycle, StoryProposalLifecycleStatus.readyForReview);
    });

    test('shaped content remains reviewable', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: 'Review me'},
      );
      final shaped = shaper.shapeSync(proposal);
      expect(
        shaped.lifecycle,
        StoryProposalLifecycleStatus.readyForReview,
      );
      expect(shaped.narrative, isNotNull);
    });
  });

  group('application use case', () {
    test('missing proposal returns typed failure', () async {
      final result = await shapeProposal.execute(
        ShapeStoryProposalRequest(
          proposalId: StoryProposalId('missing-proposal'),
        ),
      );
      expect(result, isA<Failure>());
      expect((result as Failure).error, contains('not found'));
    });

    test('valid proposal shapes successfully and persists', () async {
      final storiesBefore = await storyRepository.findAll();
      final id = await startSession();
      await answerCurrent(id, 'My beginning');
      final buildResult = await buildProposal.execute(
        BuildStoryProposalRequest(
          sessionId: id,
          createdAt: DateTime.utc(2026, 9, 22, 12),
        ),
      );
      final built = (buildResult as Success<StoryProposal>).value;
      final sessionBefore = (await sessionRepository.findById(id))!;

      final shapeResult = await shapeProposal.execute(
        ShapeStoryProposalRequest(
          proposalId: built.id,
          shapedAt: DateTime.utc(2026, 9, 22, 13),
        ),
      );
      expect(shapeResult, isA<Success<StoryProposal>>());
      final shaped = (shapeResult as Success<StoryProposal>).value;
      expect(shaped.id, built.id);
      expect(
        shaped.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );
      expect(shaped.lifecycle, StoryProposalLifecycleStatus.readyForReview);

      final reloaded = await proposalRepository.findById(built.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.narrative, shaped.narrative);
      expect(
        reloaded.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );

      final sessionAfter = (await sessionRepository.findById(id))!;
      expect(sessionAfter.responses.length, sessionBefore.responses.length);
      expect(sessionAfter.status, sessionBefore.status);
      expect(sessionAfter.storyId, sessionBefore.storyId);

      final storiesAfter = await storyRepository.findAll();
      expect(storiesAfter.length, storiesBefore.length);
    });

    test('repository persistence round-trip preserves shaped proposal',
        () async {
      final temp = await Directory.systemTemp.createTemp('sb10-proposal-');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final fileRepo = FileStoryProposalRepository(rootDirectory: temp);

      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Persist me',
          StoryBuilderNarrativeRole.challenge: 'And this',
        },
        proposalId: StoryProposalId('file-shape-1'),
      );
      final shaped = shaper.shapeSync(
        proposal,
        shapedAt: DateTime.utc(2026, 9, 22, 14),
      );
      await fileRepo.save(shaped);
      final loaded = await fileRepo.findById(shaped.id);
      expect(loaded, isNotNull);
      expect(loaded!.isContentEquivalentTo(shaped), isTrue);
      expect(
        loaded.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );

      final json = StoryProposalSnapshotMapper.toJson(shaped);
      final fromJson = StoryProposalSnapshotMapper.fromJson(json);
      expect(fromJson.isContentEquivalentTo(shaped), isTrue);
    });

    test('title is preserved and never invented', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {StoryBuilderNarrativeRole.beginning: 'Untitled material'},
      );
      expect(proposal.title, isNull);
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.title, isNull);
    });

    test('derivedSummary is preserved without regeneration', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'A long enough beginning '
              'to allow understanding summary metadata when present.',
          StoryBuilderNarrativeRole.challenge: 'A real challenge appeared.',
          StoryBuilderNarrativeRole.outcome: 'Things changed for me.',
        },
      );
      final summaryBefore = proposal.derivedSummary;
      final shaped = shaper.shapeSync(proposal);
      expect(shaped.derivedSummary, summaryBefore);
    });
  });
}
