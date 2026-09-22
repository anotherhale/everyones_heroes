import 'dart:convert';
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
import 'package:everyonesheroes/features/hero_story/application/dto/requests/skip_story_builder_prompt_request.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_proposal_authoring_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_shaper_adapter.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/story_authoring_response_parser.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_proposal_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  late DeterministicStoryShaper deterministicShaper;

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
    deterministicShaper = const DeterministicStoryShaper();
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

    // Expand sparse answer maps so earlier catalog roles are filled before
    // the last provided role (catalog is sequential).
    final catalogRoles = [
      for (final prompt in DeterministicStoryBuilderCatalog.prompts)
        prompt.narrativeRole!,
    ];
    var lastIndex = -1;
    for (var i = 0; i < catalogRoles.length; i++) {
      if (answers.containsKey(catalogRoles[i])) {
        lastIndex = i;
      }
    }
    final expanded = <StoryBuilderNarrativeRole, String?>{};
    for (var i = 0; i <= lastIndex; i++) {
      final role = catalogRoles[i];
      expanded[role] = answers.containsKey(role)
          ? answers[role]
          : 'Filler for ${role.name}.';
    }

    for (final prompt in DeterministicStoryBuilderCatalog.prompts) {
      final role = prompt.narrativeRole!;
      if (!expanded.containsKey(role)) {
        break;
      }
      final text = expanded[role];
      if (text == null) {
        final step = await advanceOnce(id);
        await skip.execute(
          SkipStoryBuilderPromptRequest(
            sessionId: id,
            promptId: step.currentPrompt!.id,
            responseId: StoryBuilderResponseId.generate(),
          ),
        );
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

  Future<StoryProposal> persistShapedDeterministic(
    StoryProposal proposal,
  ) async {
    final shaped = deterministicShaper.shapeSync(
      proposal,
      shapedAt: DateTime.utc(2026, 9, 22, 13),
    );
    await proposalRepository.save(shaped);
    return shaped;
  }

  group('adapter', () {
    test('posts to /story-authoring with bearer auth', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'title': 'T',
            'summary': 'S',
            'sections': [
              {
                'role': 'struggle',
                'content': 'Derived struggle.',
                'sourceResponseIds': ['r1'],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final adapter = ProxyStoryShaperAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'secret-token',
      );
      final response = await adapter.author(
        StoryAuthoringRequest(
          sections: [
            StoryAuthoringSectionInput(
              role: StoryBuilderNarrativeRole.struggle,
              content: 'I kept going.',
              sourceResponseIds: [StoryBuilderResponseId('r1')],
              contentOrigin: StoryProposalContentOrigin.heroAuthored,
            ),
          ],
        ),
      );
      expect(captured!.url.path, '/story-authoring');
      expect(captured!.method, 'POST');
      expect(captured!.headers['authorization'], 'Bearer secret-token');
      expect(response.sections, hasLength(1));
      expect(response.sections.first.role, StoryBuilderNarrativeRole.struggle);
    });

    test('serializes minimal request payload', () {
      final json = ProxyStoryShaperAdapter.toEhRequestJson(
        StoryAuthoringRequest(
          purpose: StoryBuilderPurpose.inspireSomeone,
          themes: [StoryBuilderTheme.perseverance],
          title: 'Existing',
          summary: 'Narrative',
          understandingSummary: 'Derived note',
          sections: [
            StoryAuthoringSectionInput(
              role: StoryBuilderNarrativeRole.beginning,
              content: 'It began.',
              sourceResponseIds: [StoryBuilderResponseId('abc')],
              contentOrigin: StoryProposalContentOrigin.heroAuthored,
            ),
          ],
        ),
      );
      expect(json.keys, containsAll([
        'purpose',
        'themes',
        'themesUnsure',
        'title',
        'summary',
        'understandingSummary',
        'sections',
      ]));
      expect(json.containsKey('authToken'), isFalse);
      expect(json.containsKey('path'), isFalse);
      final section = (json['sections'] as List).first as Map;
      expect(section['contentOrigin'], 'heroAuthored');
      expect(section['sourceResponseIds'], ['abc']);
    });

    test('maps network failure to StoryShaperException', () async {
      final adapter = ProxyStoryShaperAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: MockClient((_) async {
          throw const SocketException('offline');
        }),
      );
      expect(
        () => adapter.author(
          StoryAuthoringRequest(
            sections: [
              StoryAuthoringSectionInput(
                role: StoryBuilderNarrativeRole.beginning,
                content: 'x',
                sourceResponseIds: [StoryBuilderResponseId('r1')],
                contentOrigin: StoryProposalContentOrigin.heroAuthored,
              ),
            ],
          ),
        ),
        throwsA(isA<StoryShaperException>()),
      );
    });

    test('maps 401 to authentication failure', () async {
      final adapter = ProxyStoryShaperAdapter(
        baseUrl: Uri.parse('http://proxy.test'),
        client: MockClient(
          (_) async => http.Response('{"error":"unauthorized"}', 401),
        ),
        authToken: 'bad',
      );
      expect(
        () => adapter.author(StoryAuthoringRequest(sections: [
          StoryAuthoringSectionInput(
            role: StoryBuilderNarrativeRole.beginning,
            content: 'x',
            sourceResponseIds: [StoryBuilderResponseId('r1')],
            contentOrigin: StoryProposalContentOrigin.heroAuthored,
          ),
        ])),
        throwsA(
          isA<StoryShaperException>().having(
            (e) => e.message,
            'message',
            contains('authentication'),
          ),
        ),
      );
    });

    test('rejects malformed response JSON', () {
      expect(
        () => StoryAuthoringResponseParser.parse('not-json'),
        throwsA(isA<StoryShaperException>()),
      );
    });

    test('rejects unknown narrative role', () {
      expect(
        () => StoryAuthoringResponseParser.parse(jsonEncode({
          'sections': [
            {
              'role': 'climaxScene',
              'content': 'Nope',
              'sourceResponseIds': ['r1'],
            },
          ],
        })),
        throwsA(
          isA<StoryShaperException>().having(
            (e) => e.message,
            'message',
            contains('unknown narrative role'),
          ),
        ),
      );
    });

    test('parser ignores AI lifecycle and contentOrigin fields', () {
      final parsed = StoryAuthoringResponseParser.parse(jsonEncode({
        'lifecycle': 'accepted',
        'contentOrigin': 'heroAuthored',
        'sections': [
          {
            'role': 'outcome',
            'content': 'I grew.',
            'sourceResponseIds': ['r1'],
          },
        ],
      }));
      expect(parsed.sections, hasLength(1));
      // Fields are simply not on the typed response.
      expect(parsed.sections.first.role, StoryBuilderNarrativeRole.outcome);
    });
  });

  group('domain / application', () {
    test('valid proposal produces AI-shaped proposal', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'It began quietly.',
          StoryBuilderNarrativeRole.challenge: 'Then hardship arrived.',
          StoryBuilderNarrativeRole.outcome: 'I kept growing.',
        },
        intent: StoryBuilderIntent(
          purpose: StoryBuilderPurpose.inspireSomeone,
          themes: [StoryBuilderTheme.perseverance],
        ),
      );
      final shaped = await persistShapedDeterministic(proposal);
      final transport = InMemoryStoryProposalAuthoringAdapter();
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        sessionRepository: sessionRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: transport),
        ),
      );
      final result = await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: shaped.id,
          mode: StoryShaperMode.ai,
          shapedAt: DateTime.utc(2026, 9, 22, 14),
        ),
      );
      expect(result, isA<Success<StoryProposal>>());
      final ai = (result as Success<StoryProposal>).value;
      expect(ai.provenance.derivationKind, StoryProposalDerivationKind.aiShaped);
      expect(
        ai.provenance.processingVersion,
        StoryProposal.aiShapedProcessingVersion,
      );
      expect(ai.lifecycle, StoryProposalLifecycleStatus.readyForReview);
      expect(ai.sessionId, session.id);
      for (final section in ai.sections) {
        expect(section.contentOrigin, StoryProposalContentOrigin.derived);
      }
      expect(await storyRepository.findAll(), isEmpty);
      expect(session.storyId, isNull);
    });

    test('AI-derived content is marked derived; source IDs preserved', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.struggle:
              'I kept going even when I wanted to quit.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final struggle = shaped.sectionForRole(StoryBuilderNarrativeRole.struggle)!;
      final sourceIds = struggle.sourceResponseIds;
      expect(sourceIds, isNotEmpty);

      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedResponse: StoryAuthoringResponse(
          title: 'Kept Going',
          sections: [
            StoryAuthoringSectionOutput(
              role: StoryBuilderNarrativeRole.struggle,
              content:
                  'Even when giving up felt tempting, the Hero chose to keep moving forward.',
              sourceResponseIds: sourceIds,
            ),
          ],
        ),
      );
      final shaper = AiStoryShaper(transport: transport);
      final ai = await shaper.shapeAt(
        shaped,
        shapedAt: DateTime.utc(2026, 9, 22, 15),
      );
      expect(ai.sections.first.contentOrigin, StoryProposalContentOrigin.derived);
      expect(ai.sections.first.sourceResponseIds, sourceIds);
      expect(ai.sections.first.content, isNot(struggle.content));
    });

    test('AI cannot invent source IDs', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Start.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedResponse: const StoryAuthoringResponse(
          sections: [
            StoryAuthoringSectionOutput(
              role: StoryBuilderNarrativeRole.beginning,
              content: 'Invented provenance.',
              sourceResponseIds: [StoryBuilderResponseId('unknown-id')],
            ),
          ],
        ),
      );
      await proposalRepository.save(shaped);
      final before = await proposalRepository.findById(shaped.id);
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        sessionRepository: sessionRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: transport),
        ),
      );
      final result = await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: shaped.id,
          mode: StoryShaperMode.ai,
        ),
      );
      expect(result, isA<Failure>());
      expect((result as Failure).error, contains('unknown sourceResponseId'));
      final after = await proposalRepository.findById(shaped.id);
      expect(after!.narrative, before!.narrative);
      expect(after.provenance.processingVersion, before.provenance.processingVersion);
    });

    test('unknown roles are rejected', () {
      expect(
        () => StoryAuthoringResponseParser.parse(jsonEncode({
          'sections': [
            {
              'role': 'epilogue',
              'content': 'x',
              'sourceResponseIds': ['r1'],
            },
          ],
        })),
        throwsA(isA<StoryShaperException>()),
      );
    });

    test('valid SB.4 roles are accepted', () {
      for (final role in StoryBuilderNarrativeRole.values) {
        final parsed = StoryAuthoringResponseParser.parse(jsonEncode({
          'sections': [
            {
              'role': role.name,
              'content': 'Grounded.',
              'sourceResponseIds': ['r1'],
            },
          ],
        }));
        expect(parsed.sections.first.role, role);
      }
    });

    test('accepted proposal becomes readyForReview after AI shaping', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.outcome: 'I finished.',
        },
      );
      final shaped = deterministicShaper.shapeSync(proposal);
      // Simulate an accepted proposal (future workflow) being re-shaped.
      final accepted = StoryProposal(
        id: shaped.id,
        sessionId: shaped.sessionId,
        title: shaped.title,
        narrative: shaped.narrative,
        sections: shaped.sections,
        intent: shaped.intent,
        provenance: shaped.provenance,
        lifecycle: StoryProposalLifecycleStatus.accepted,
        createdAt: shaped.createdAt,
        updatedAt: shaped.updatedAt,
        derivedSummary: shaped.derivedSummary,
      );
      await proposalRepository.save(accepted);
      final sourceIds = accepted.sections
          .expand((s) => s.sourceResponseIds)
          .toList();
      expect(sourceIds, isNotEmpty);
      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedResponse: StoryAuthoringResponse(
          sections: [
            StoryAuthoringSectionOutput(
              role: StoryBuilderNarrativeRole.outcome,
              content: 'Derived outcome.',
              sourceResponseIds: [sourceIds.first],
            ),
          ],
        ),
      );
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: transport),
        ),
      );
      final result = await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: accepted.id,
          mode: StoryShaperMode.ai,
        ),
      );
      expect(result, isA<Success<StoryProposal>>());
      final ai = (result as Success<StoryProposal>).value;
      expect(ai.lifecycle, StoryProposalLifecycleStatus.readyForReview);
    });

    test('AI failure preserves original proposal and session', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.challenge: 'Hard times.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final responsesBefore = session.responses.length;
      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedFailureMessage: 'provider unavailable',
      );
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        sessionRepository: sessionRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: transport),
        ),
      );
      final result = await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: shaped.id,
          mode: StoryShaperMode.ai,
        ),
      );
      expect(result, isA<Failure>());
      final afterProposal = await proposalRepository.findById(shaped.id);
      expect(afterProposal!.narrative, shaped.narrative);
      expect(
        afterProposal.provenance.processingVersion,
        StoryProposal.shapedProcessingVersion,
      );
      final afterSession = await sessionRepository.findById(session.id);
      expect(afterSession!.responses.length, responsesBefore);
      expect(afterSession.storyId, isNull);
      expect(await storyRepository.findAll(), isEmpty);
    });

    test('invalid provenance preserves original proposal', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.message: 'Keep going.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedResponse: const StoryAuthoringResponse(
          sections: [
            StoryAuthoringSectionOutput(
              role: StoryBuilderNarrativeRole.message,
              content: 'Fabricated.',
              sourceResponseIds: [StoryBuilderResponseId('not-real')],
            ),
          ],
        ),
      );
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: transport),
        ),
      );
      final result = await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: shaped.id,
          mode: StoryShaperMode.ai,
        ),
      );
      expect(result, isA<Failure>());
      final after = await proposalRepository.findById(shaped.id);
      expect(after!.provenance.derivationKind, StoryProposalDerivationKind.deterministic);
    });

    test('understanding metadata and session id remain intact', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.reflection: 'I learned patience.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final understandingKind = shaped.provenance.understandingKind;
      final understandingVersion =
          shaped.provenance.understandingProcessingVersion;
      final transport = InMemoryStoryProposalAuthoringAdapter();
      final ai = await AiStoryShaper(transport: transport).shapeAt(
        shaped,
        shapedAt: DateTime.utc(2026, 9, 22, 16),
      );
      expect(ai.sessionId, session.id);
      expect(ai.provenance.sessionId, session.id);
      expect(ai.provenance.understandingKind, understandingKind);
      expect(
        ai.provenance.understandingProcessingVersion,
        understandingVersion,
      );
    });

    test('persistence round-trip retains AI processing version', () async {
      final dir = await Directory.systemTemp.createTemp('sb11-proposal-');
      addTearDown(() => dir.delete(recursive: true));
      final fileRepo = FileStoryProposalRepository(rootDirectory: dir);
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.action: 'I took a step.',
        },
      );
      final shaped = deterministicShaper.shapeSync(proposal);
      final transport = InMemoryStoryProposalAuthoringAdapter();
      final ai = await AiStoryShaper(transport: transport).shapeAt(
        shaped,
        shapedAt: DateTime.utc(2026, 9, 22, 17),
      );
      await fileRepo.save(ai);
      final reloaded = await fileRepo.findById(ai.id);
      expect(reloaded, isNotNull);
      expect(
        reloaded!.provenance.processingVersion,
        StoryProposal.aiShapedProcessingVersion,
      );
      expect(
        reloaded.provenance.derivationKind,
        StoryProposalDerivationKind.aiShaped,
      );
      expect(
        reloaded.sections.every(
          (s) => s.contentOrigin == StoryProposalContentOrigin.derived,
        ),
        isTrue,
      );
      final json = StoryProposalSnapshotMapper.toJson(reloaded);
      expect(json['provenance']['processingVersion'], 'sb11.ai.v1');
      expect(json['provenance']['derivationKind'], 'aiShaped');
    });

    test('resolver selects deterministic vs AI independently of interview mode',
        () {
      final resolver = DefaultStoryShaperStrategyResolver(
        ai: AiStoryShaper(transport: InMemoryStoryProposalAuthoringAdapter()),
      );
      expect(
        resolver.resolve(StoryShaperMode.deterministic),
        isA<DeterministicStoryShaper>(),
      );
      expect(resolver.resolve(StoryShaperMode.ai), isA<AiStoryShaper>());
    });

    test('AI response cannot set contentOrigin to heroAuthored', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.stakes: 'Everything was on the line.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final ids = shaped.sections
          .firstWhere((s) => s.sourceResponseIds.isNotEmpty)
          .sourceResponseIds;
      final transport = InMemoryStoryProposalAuthoringAdapter(
        forcedResponse: StoryAuthoringResponse(
          sections: [
            StoryAuthoringSectionOutput(
              role: StoryBuilderNarrativeRole.stakes,
              content: 'AI rewrite.',
              sourceResponseIds: ids,
            ),
          ],
        ),
      );
      final ai = await AiStoryShaper(transport: transport).shapeAt(
        shaped,
        shapedAt: DateTime.utc(2026, 9, 22, 18),
      );
      expect(
        ai.sections.every(
          (s) => s.contentOrigin == StoryProposalContentOrigin.derived,
        ),
        isTrue,
      );
    });

    test('no Story is created by AI shaping', () async {
      final (session, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.decision: 'I chose to try.',
        },
      );
      final shaped = await persistShapedDeterministic(proposal);
      final useCase = ShapeStoryProposalUseCase(
        proposalRepository: proposalRepository,
        sessionRepository: sessionRepository,
        resolver: DefaultStoryShaperStrategyResolver(
          ai: AiStoryShaper(transport: InMemoryStoryProposalAuthoringAdapter()),
        ),
      );
      await useCase.execute(
        ShapeStoryProposalRequest(
          proposalId: shaped.id,
          mode: StoryShaperMode.ai,
        ),
      );
      expect(await storyRepository.findAll(), isEmpty);
      expect((await sessionRepository.findById(session.id))!.storyId, isNull);
    });
  });

  group('prompt safety contract (client-side mirrors)', () {
    test('authoring request distinguishes source vs understanding', () async {
      final (_, proposal) = await buildFromAnswers(
        answers: {
          StoryBuilderNarrativeRole.beginning: 'Hero words.',
        },
      );
      final request = AiStoryShaper.buildAuthoringRequest(proposal);
      expect(request.sections, isNotEmpty);
      expect(
        request.sections.any(
          (s) =>
              s.contentOrigin == StoryProposalContentOrigin.heroAuthored &&
              (s.content ?? '').contains('Hero words'),
        ),
        isTrue,
      );
      // understandingSummary is separate from section source material
      expect(
        identical(request.understandingSummary, request.summary),
        isFalse,
      );
    });
  });
}
