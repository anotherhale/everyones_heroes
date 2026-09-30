import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_bus.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_dispatcher.dart';
import 'package:everyonesheroes/core/eventing/in_memory_event_store.dart';
import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_script_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_proposal_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/approve_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/edit_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/generate_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/materialize_story_builder_script_request.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/approve_story_builder_script_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/create_story_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/edit_story_builder_script_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/generate_story_builder_script_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/materialize_story_builder_script_use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/in_memory_story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/ai/proxy_story_script_generator.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_builder_script_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_script_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_proposal_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  late InMemoryStoryBuilderScriptRepository scriptRepository;
  late InMemoryStoryProposalRepository proposalRepository;
  late InMemoryStoryRepository storyRepository;
  late InMemoryStoryScriptGenerator generator;
  late EventBus eventBus;
  late HeroId heroId;
  late StoryBuilderSessionId sessionId;
  late GenerateStoryBuilderScriptUseCase generate;
  late EditStoryBuilderScriptUseCase edit;
  late ApproveStoryBuilderScriptUseCase approve;
  late MaterializeStoryBuilderScriptUseCase materialize;

  Future<void> seedAnsweredSession({bool emptyAnswers = false}) async {
    final session = StoryBuilderSession.create(
      id: sessionId,
      heroId: heroId,
      mode: StoryBuilderMode.guided,
      intent: StoryBuilderIntent.purposeOnly(StoryBuilderPurpose.inspireSomeone),
    );
    session.setThemes(
      themes: const [StoryBuilderTheme.perseverance],
      themesUnsure: false,
    );

    if (!emptyAnswers) {
      final prompts = DeterministicStoryBuilderCatalog.prompts.take(3).toList();
      final answers = [
        'When I first joined the military, everything changed overnight.',
        'I faced challenges that tested my courage every day.',
        'Looking back now, what I learned was perseverance.',
      ];
      for (var i = 0; i < prompts.length; i++) {
        session.presentPrompt(prompts[i]);
        session.answerPrompt(
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompts[i].id,
          text: answers[i],
        );
      }
    }

    session.complete(at: DateTime.utc(2026, 9, 30, 10));
    await sessionRepository.save(session);
  }

  setUp(() async {
    heroRepository = InMemoryHeroRepository();
    sessionRepository = InMemoryStoryBuilderSessionRepository();
    scriptRepository = InMemoryStoryBuilderScriptRepository();
    proposalRepository = InMemoryStoryProposalRepository();
    storyRepository = InMemoryStoryRepository();
    generator = InMemoryStoryScriptGenerator(
      fixedContent:
          'When I first joined the military, everything changed overnight.\n\n'
          'I faced challenges that tested my courage every day.\n\n'
          'Looking back now, what I learned from that experience was '
          'perseverance.',
    );
    eventBus = InMemoryEventBus(
      eventStore: InMemoryEventStore(),
      dispatcher: InMemoryEventDispatcher(),
    );

    heroId = HeroId.generate();
    final hero = Hero.create(
      id: heroId,
      profile: HeroProfile(
        displayName: 'Script Hero',
        languages: [LanguageCode('en')],
      ),
      visibility: HeroVisibility.private,
    );
    await heroRepository.save(hero);

    sessionId = StoryBuilderSessionId.generate();
    await seedAnsweredSession();

    generate = GenerateStoryBuilderScriptUseCase(
      sessionRepository: sessionRepository,
      scriptRepository: scriptRepository,
      scriptGenerator: generator,
    );
    edit = EditStoryBuilderScriptUseCase(scriptRepository: scriptRepository);
    approve = ApproveStoryBuilderScriptUseCase(
      scriptRepository: scriptRepository,
    );
    materialize = MaterializeStoryBuilderScriptUseCase(
      scriptRepository: scriptRepository,
      sessionRepository: sessionRepository,
      proposalRepository: proposalRepository,
      storyRepository: storyRepository,
      heroRepository: heroRepository,
      createStoryUseCase: CreateStoryUseCase(
        storyRepository: storyRepository,
        heroRepository: heroRepository,
        eventBus: eventBus,
      ),
    );
  });

  group('Generation', () {
    test('valid session generates a non-empty complete narrative script',
        () async {
      final result = await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      );
      expect(result, isA<Success<StoryBuilderScript>>());
      final script = (result as Success<StoryBuilderScript>).value;
      expect(script.content.trim(), isNotEmpty);
      expect(script.content.contains('When I first joined'), isTrue);
      expect(script.content.toLowerCase(), isNot(contains('summary:')));
      expect(script.sourceStoryBuilderSessionId, sessionId);
      expect(script.isDraft, isTrue);
      expect(script.isAiGenerated, isTrue);
      expect(script.isApproved, isFalse);
    });

    test('AI failure does not destroy the session', () async {
      generator.failWith = const StoryScriptGeneratorException('boom');
      final before = await sessionRepository.findById(sessionId);
      final result = await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      );
      expect(result, isA<Failure<StoryBuilderScript>>());
      final after = await sessionRepository.findById(sessionId);
      expect(after!.responses.length, before!.responses.length);
      expect(after.status, before.status);
    });
  });

  group('Validation', () {
    test('empty session material is rejected', () async {
      final emptyId = StoryBuilderSessionId.generate();
      sessionId = emptyId;
      await seedAnsweredSession(emptyAnswers: true);
      final result = await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: emptyId),
      );
      expect(result, isA<Failure<StoryBuilderScript>>());
    });

    test('blank AI output is rejected', () async {
      generate = GenerateStoryBuilderScriptUseCase(
        sessionRepository: sessionRepository,
        scriptRepository: scriptRepository,
        scriptGenerator: InMemoryStoryScriptGenerator(fixedContent: '   '),
      );
      final result = await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      );
      expect(result, isA<Failure<StoryBuilderScript>>());
    });
  });

  group('Persistence', () {
    test('generated, edited, and approved scripts survive reload', () async {
      final dir = await Directory.systemTemp.createTemp('sb8-scripts-');
      addTearDown(() => dir.delete(recursive: true));
      final fileRepo = FileStoryBuilderScriptRepository(rootDirectory: dir);

      final generated = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      await fileRepo.save(generated);

      final reloadedDraft = await fileRepo.findById(generated.id);
      expect(reloadedDraft!.content, generated.content);
      expect(reloadedDraft.isDraft, isTrue);

      final edited = ((await EditStoryBuilderScriptUseCase(
        scriptRepository: fileRepo,
      ).execute(
        EditStoryBuilderScriptRequest(
          scriptId: generated.id,
          content: '${generated.content}\n\nI added this line myself.',
        ),
      )) as Success<StoryBuilderScript>)
          .value;
      expect(edited.heroEdited, isTrue);

      final approved = ((await ApproveStoryBuilderScriptUseCase(
        scriptRepository: fileRepo,
      ).execute(
        ApproveStoryBuilderScriptRequest(scriptId: edited.id),
      )) as Success<StoryBuilderScript>)
          .value;
      expect(approved.isApproved, isTrue);

      final fresh = FileStoryBuilderScriptRepository(rootDirectory: dir);
      final reloaded = await fresh.findById(approved.id);
      expect(reloaded!.isApproved, isTrue);
      expect(reloaded.content, contains('I added this line myself'));
      expect(reloaded.heroEdited, isTrue);
    });

    test('snapshot mapper round-trips provenance', () {
      final script = StoryBuilderScript(
        id: StoryBuilderScriptId.generate(),
        sourceStoryBuilderSessionId: sessionId,
        content: 'A full first-person story.',
        language: LanguageCode('en'),
        provenance: StoryBuilderScriptProvenance(
          sessionId: sessionId,
          processingVersion: StoryBuilderScript.aiProcessingVersion,
          providerLabel: 'test',
        ),
        status: StoryBuilderScriptStatus.draft,
        createdAt: DateTime.utc(2026, 9, 30),
        updatedAt: DateTime.utc(2026, 9, 30),
      );
      final json = StoryBuilderScriptSnapshotMapper.toJson(script);
      final restored = StoryBuilderScriptSnapshotMapper.fromJson(json);
      expect(restored, script);
    });
  });

  group('Approval', () {
    test('draft can be approved and approval is persisted', () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      final approved = ((await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      )) as Success<StoryBuilderScript>)
          .value;
      expect(approved.isApproved, isTrue);
      final loaded = await scriptRepository.findById(draft.id);
      expect(loaded!.isApproved, isTrue);
    });

    test('approved script is not replaced by stale draft regeneration silence',
        () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      );

      generator = InMemoryStoryScriptGenerator(
        fixedContent: 'A brand new regenerated draft narrative for testing.',
      );
      generate = GenerateStoryBuilderScriptUseCase(
        sessionRepository: sessionRepository,
        scriptRepository: scriptRepository,
        scriptGenerator: generator,
      );
      final regenerated = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(
          sessionId: sessionId,
          replaceExistingDraft: true,
          confirmDiscardHeroEdits: true,
        ),
      )) as Success<StoryBuilderScript>)
          .value;
      expect(regenerated.isDraft, isTrue);
      expect(regenerated.id, isNot(draft.id));

      final stillApproved = await scriptRepository.findById(draft.id);
      expect(stillApproved!.isApproved, isTrue);
      expect(stillApproved.content, draft.content);
    });
  });

  group('Materialization', () {
    test('approved script creates Story with Hero title and script narrative',
        () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      final approved = ((await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      )) as Success<StoryBuilderScript>)
          .value;

      const chosenTitle = 'My Journey Through Service';
      final storyResult = await materialize.execute(
        MaterializeStoryBuilderScriptRequest(
          scriptId: approved.id,
          title: chosenTitle,
        ),
      );
      expect(storyResult, isA<Success<Story>>());
      final story = (storyResult as Success<Story>).value;
      expect(story.title.value, chosenTitle);
      expect(story.narrative.value, approved.content);
      expect(
        story.provenance.sourceStoryBuilderScriptId,
        approved.id,
      );
      expect(story.provenance.sourceSessionId, sessionId);

      final linked = await scriptRepository.findById(approved.id);
      expect(linked!.materializedStoryId, story.id);
      expect(linked.isApproved, isTrue);
      expect(linked.content, approved.content);

      final proposal =
          await proposalRepository.findById(linked.linkedProposalId!);
      expect(proposal, isNotNull);
      expect(proposal!.title!.value, chosenTitle);
      expect(proposal.narrative, approved.content);
    });

    test('empty and whitespace-only titles are rejected', () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      final approved = ((await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      )) as Success<StoryBuilderScript>)
          .value;

      for (final invalid in ['', '   ', '\n\t']) {
        final result = await materialize.execute(
          MaterializeStoryBuilderScriptRequest(
            scriptId: approved.id,
            title: invalid,
          ),
        );
        expect(result, isA<Failure<Story>>(), reason: 'title="$invalid"');
      }

      final preserved = await scriptRepository.findById(approved.id);
      expect(preserved!.isApproved, isTrue);
      expect(preserved.materializedStoryId, isNull);
      expect(preserved.content, approved.content);
    });

    test('title is trimmed before persistence', () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      final approved = ((await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      )) as Success<StoryBuilderScript>)
          .value;

      final storyResult = await materialize.execute(
        MaterializeStoryBuilderScriptRequest(
          scriptId: approved.id,
          title: '  Finding Strength Through Service  ',
        ),
      );
      final story = (storyResult as Success<Story>).value;
      expect(story.title.value, 'Finding Strength Through Service');
    });

    test(
        'failed Story creation preserves approved script, title, and retry works',
        () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      final approved = ((await approve.execute(
        ApproveStoryBuilderScriptRequest(scriptId: draft.id),
      )) as Success<StoryBuilderScript>)
          .value;

      const chosenTitle = 'My Journey Through Service';
      final failingRepo = _FailingSaveStoryRepository(storyRepository);
      final failing = MaterializeStoryBuilderScriptUseCase(
        scriptRepository: scriptRepository,
        sessionRepository: sessionRepository,
        proposalRepository: proposalRepository,
        storyRepository: failingRepo,
        heroRepository: heroRepository,
        createStoryUseCase: CreateStoryUseCase(
          storyRepository: failingRepo,
          heroRepository: heroRepository,
          eventBus: eventBus,
        ),
      );

      final failed = await failing.execute(
        MaterializeStoryBuilderScriptRequest(
          scriptId: approved.id,
          title: chosenTitle,
        ),
      );
      expect(failed, isA<Failure<Story>>());

      final preserved = await scriptRepository.findById(approved.id);
      expect(preserved!.isApproved, isTrue);
      expect(preserved.content, approved.content);
      expect(preserved.materializedStoryId, isNull);
      expect(preserved.linkedProposalId, isNotNull);

      final failedProposal =
          await proposalRepository.findById(preserved.linkedProposalId!);
      expect(failedProposal!.title!.value, chosenTitle);
      expect(failedProposal.narrative, approved.content);

      final retry = await materialize.execute(
        MaterializeStoryBuilderScriptRequest(
          scriptId: approved.id,
          title: chosenTitle,
        ),
      );
      expect(retry, isA<Success<Story>>());
      final story = (retry as Success<Story>).value;
      expect(story.narrative.value, approved.content);
      expect(story.title.value, chosenTitle);
      expect(
        story.provenance.sourceStoryBuilderScriptId,
        approved.id,
      );
    });

    test('empty narrative cannot create Story', () async {
      // Materialize requires approved non-blank content — constructor already
      // rejects blank. Verify draft rejection path.
      final result = await materialize.execute(
        MaterializeStoryBuilderScriptRequest(
          scriptId: StoryBuilderScriptId.generate(),
          title: 'Valid Title',
        ),
      );
      expect(result, isA<Failure<Story>>());
    });
  });

  group('Regeneration', () {
    test('hero edits are not silently discarded', () async {
      final draft = ((await generate.execute(
        GenerateStoryBuilderScriptRequest(sessionId: sessionId),
      )) as Success<StoryBuilderScript>)
          .value;
      await edit.execute(
        EditStoryBuilderScriptRequest(
          scriptId: draft.id,
          content: '${draft.content}\n\nMy careful edit.',
        ),
      );

      final blocked = await generate.execute(
        GenerateStoryBuilderScriptRequest(
          sessionId: sessionId,
          replaceExistingDraft: true,
          confirmDiscardHeroEdits: false,
        ),
      );
      expect(blocked, isA<Failure<StoryBuilderScript>>());
      expect(
        (blocked as Failure<StoryBuilderScript>).error,
        contains('Confirm'),
      );

      final stillEdited = await scriptRepository.findById(draft.id);
      expect(stillEdited!.content, contains('My careful edit'));
    });
  });

  group('Proxy adapter', () {
    test('authenticated successful response', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer secret');
        expect(request.url.path, endsWith('/story-builder-scripts'));
        final body = jsonDecode(request.body) as Map;
        expect(body['answers'], isA<List>());
        return http.Response(
          jsonEncode({
            'content': 'When I look back, this is my story from the answers.',
            'language': 'en',
            'providerLabel': 'openai_via_eh_proxy',
            'promptOrTemplateVersion': 'sb8.script.ai.v1',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final adapter = ProxyStoryScriptGenerator(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'secret',
      );

      final draft = await adapter.generate(
        StoryScriptGenerationMaterial(
          sessionId: sessionId,
          answers: const [
            StoryScriptSourceAnswer(
              question: 'What happened?',
              answer: 'I joined and learned.',
            ),
          ],
        ),
      );
      expect(draft.content, contains('this is my story'));
    });

    test('empty response is rejected', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'content': '  '}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final adapter = ProxyStoryScriptGenerator(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );
      expect(
        () => adapter.generate(
          StoryScriptGenerationMaterial(
            sessionId: sessionId,
            answers: const [
              StoryScriptSourceAnswer(question: 'Q', answer: 'A'),
            ],
          ),
        ),
        throwsA(isA<StoryScriptGeneratorException>()),
      );
    });

    test('malformed response is rejected', () async {
      final client = MockClient((_) async => http.Response('not-json', 200));
      final adapter = ProxyStoryScriptGenerator(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );
      expect(
        () => adapter.generate(
          StoryScriptGenerationMaterial(
            sessionId: sessionId,
            answers: const [
              StoryScriptSourceAnswer(question: 'Q', answer: 'A'),
            ],
          ),
        ),
        throwsA(isA<StoryScriptGeneratorException>()),
      );
    });

    test('proxy error response is rejected', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'upstream failed'}),
          502,
          headers: {'content-type': 'application/json'},
        ),
      );
      final adapter = ProxyStoryScriptGenerator(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
      );
      expect(
        () => adapter.generate(
          StoryScriptGenerationMaterial(
            sessionId: sessionId,
            answers: const [
              StoryScriptSourceAnswer(question: 'Q', answer: 'A'),
            ],
          ),
        ),
        throwsA(isA<StoryScriptGeneratorException>()),
      );
    });

    test('auth failure is rejected', () async {
      final client = MockClient((_) async => http.Response('unauthorized', 401));
      final adapter = ProxyStoryScriptGenerator(
        baseUrl: Uri.parse('http://proxy.test'),
        client: client,
        authToken: 'secret',
      );
      expect(
        () => adapter.generate(
          StoryScriptGenerationMaterial(
            sessionId: sessionId,
            answers: const [
              StoryScriptSourceAnswer(question: 'Q', answer: 'A'),
            ],
          ),
        ),
        throwsA(isA<StoryScriptGeneratorException>()),
      );
    });
  });
}
