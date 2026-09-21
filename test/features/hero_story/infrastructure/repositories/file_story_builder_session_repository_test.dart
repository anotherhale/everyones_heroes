import 'dart:convert';
import 'dart:io';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late FileStoryBuilderSessionRepository repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('eh-file-sb-session-');
    repository = FileStoryBuilderSessionRepository(rootDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  StoryBuilderSession buildSession({
    required String id,
    required String heroId,
    StoryBuilderSessionStatus status = StoryBuilderSessionStatus.inProgress,
    StoryBuilderIntent? intent,
    List<StoryBuilderPrompt>? prompts,
    List<StoryBuilderResponse>? responses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime.utc(2026, 9, 21, 10);
    return StoryBuilderSession(
      id: StoryBuilderSessionId(id),
      heroId: HeroId(heroId),
      status: status,
      mode: StoryBuilderMode.guided,
      intent: intent ?? StoryBuilderIntent.empty(),
      createdAt: created,
      updatedAt: updatedAt ?? created,
      prompts: prompts,
      responses: responses,
    );
  }

  test('save writes json and findById returns session', () async {
    final session = buildSession(id: 'sb-a', heroId: 'hero-1');
    await repository.save(session);

    expect(
      File(
        p.join(tempDir.path, 'story_builder_sessions', 'sb-a.json'),
      ).existsSync(),
      isTrue,
    );

    final loaded = await repository.findById(
      const StoryBuilderSessionId('sb-a'),
    );
    expect(loaded, isNotNull);
    expect(loaded!.heroId.value, 'hero-1');
    expect(await repository.exists(const StoryBuilderSessionId('sb-a')), isTrue);
  });

  test('missing session returns null and exists is false', () async {
    expect(
      await repository.findById(const StoryBuilderSessionId('missing')),
      isNull,
    );
    expect(
      await repository.exists(const StoryBuilderSessionId('missing')),
      isFalse,
    );
  });

  test('overwrite updates disk and cache', () async {
    final session = buildSession(id: 'sb-u', heroId: 'hero-1');
    await repository.save(session);

    final prompt = StoryBuilderPrompt(
      id: const StoryBuilderPromptId('sb.q.beginning'),
      text: 'Beginning?',
      ordinal: 0,
      narrativeRole: StoryBuilderNarrativeRole.beginning,
    );
    session.presentPrompt(prompt, at: DateTime.utc(2026, 9, 21, 11));
    session.answerPrompt(
      responseId: const StoryBuilderResponseId('resp-1'),
      promptId: prompt.id,
      text: 'Updated answer',
      at: DateTime.utc(2026, 9, 21, 11),
    );
    await repository.save(session);

    final loaded = await repository.findById(
      const StoryBuilderSessionId('sb-u'),
    );
    expect(loaded!.responses.single.text, 'Updated answer');
    expect(loaded.responses.single.id.value, 'resp-1');
  });

  test('survives process restart via disk', () async {
    final session = buildSession(
      id: 'persist',
      heroId: 'hero-1',
      intent: StoryBuilderIntent(
        purpose: StoryBuilderPurpose.preserveAMemory,
        themes: const [StoryBuilderTheme.family, StoryBuilderTheme.love],
      ),
      prompts: [
        StoryBuilderPrompt(
          id: const StoryBuilderPromptId('sb.q.beginning'),
          text: 'What was happening?',
          ordinal: 0,
          narrativeRole: StoryBuilderNarrativeRole.beginning,
        ),
      ],
      responses: [
        StoryBuilderResponse(
          id: const StoryBuilderResponseId('resp-persist'),
          promptId: const StoryBuilderPromptId('sb.q.beginning'),
          ordinal: 0,
          text: 'A beginning.',
          createdAt: DateTime.utc(2026, 9, 21, 10, 5),
        ),
      ],
    );
    await repository.save(session);

    final restarted = FileStoryBuilderSessionRepository(
      rootDirectory: tempDir,
    );
    final loaded = await restarted.findById(
      const StoryBuilderSessionId('persist'),
    );

    expect(loaded, isNotNull);
    expect(loaded!.intent.purpose, StoryBuilderPurpose.preserveAMemory);
    expect(loaded.intent.themes, [
      StoryBuilderTheme.family,
      StoryBuilderTheme.love,
    ]);
    expect(loaded.responses.single.id.value, 'resp-persist');
    expect(loaded.responses.single.text, 'A beginning.');
    expect(loaded.createdAt, DateTime.utc(2026, 9, 21, 10));
  });

  test('findByHeroId and findResumableByHeroId', () async {
    await repository.save(
      buildSession(id: 'a1', heroId: 'hero-a'),
    );
    await repository.save(
      buildSession(
        id: 'a2',
        heroId: 'hero-a',
        status: StoryBuilderSessionStatus.paused,
        updatedAt: DateTime.utc(2026, 9, 22),
      ),
    );
    await repository.save(
      buildSession(
        id: 'a3',
        heroId: 'hero-a',
        status: StoryBuilderSessionStatus.completed,
      ),
    );
    await repository.save(buildSession(id: 'b1', heroId: 'hero-b'));

    final forHero = await repository.findByHeroId(const HeroId('hero-a'));
    expect(forHero.map((s) => s.id.value), unorderedEquals(['a1', 'a2', 'a3']));

    final resumable = await repository.findResumableByHeroId(
      const HeroId('hero-a'),
    );
    expect(resumable.map((s) => s.id.value), ['a2', 'a1']);
  });

  test('delete removes file and cache entry', () async {
    await repository.save(buildSession(id: 'to-delete', heroId: 'hero-1'));
    await repository.delete(const StoryBuilderSessionId('to-delete'));

    expect(
      await repository.findById(const StoryBuilderSessionId('to-delete')),
      isNull,
    );
    expect(
      File(
        p.join(tempDir.path, 'story_builder_sessions', 'to-delete.json'),
      ).existsSync(),
      isFalse,
    );
  });

  test('malformed session file fails safely without partial load', () async {
    final dir = Directory(p.join(tempDir.path, 'story_builder_sessions'));
    await dir.create(recursive: true);
    await File(p.join(dir.path, 'corrupt.json')).writeAsString('{not-json');

    final fresh = FileStoryBuilderSessionRepository(rootDirectory: tempDir);
    await expectLater(
      fresh.findById(const StoryBuilderSessionId('corrupt')),
      throwsA(isA<FormatException>()),
    );
  });

  test('malformed object body fails safely', () async {
    final dir = Directory(p.join(tempDir.path, 'story_builder_sessions'));
    await dir.create(recursive: true);
    await File(p.join(dir.path, 'bad.json')).writeAsString(
      jsonEncode({'id': 'bad'}),
    );

    final fresh = FileStoryBuilderSessionRepository(rootDirectory: tempDir);
    await expectLater(
      fresh.findById(const StoryBuilderSessionId('bad')),
      throwsA(isA<FormatException>()),
    );
  });

  test('lifecycle states survive disk round trip', () async {
    for (final status in [
      StoryBuilderSessionStatus.inProgress,
      StoryBuilderSessionStatus.paused,
      StoryBuilderSessionStatus.completed,
      StoryBuilderSessionStatus.abandoned,
    ]) {
      final id = 'life-${status.name}';
      await repository.save(
        buildSession(id: id, heroId: 'hero-1', status: status),
      );
      final restarted = FileStoryBuilderSessionRepository(
        rootDirectory: tempDir,
      );
      final loaded = await restarted.findById(StoryBuilderSessionId(id));
      expect(loaded!.status, status);
    }
  });
}
