import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_builder_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStoryBuilderSessionRepository repository;

  setUp(() {
    repository = InMemoryStoryBuilderSessionRepository();
  });

  StoryBuilderSession newSession(HeroId heroId) {
    return StoryBuilderSession.create(
      id: StoryBuilderSessionId.generate(),
      heroId: heroId,
      createdAt: DateTime.utc(2026, 9, 21, 10),
    );
  }

  test('save and findById round-trip', () async {
    final session = newSession(HeroId.generate());
    await repository.save(session);

    final loaded = await repository.findById(session.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, session.id);
    expect(loaded.heroId, session.heroId);
    expect(loaded.status, StoryBuilderSessionStatus.inProgress);
  });

  test('update after answer persists new responses', () async {
    final session = newSession(HeroId.generate());
    await repository.save(session);

    final prompt = StoryBuilderPrompt(
      id: StoryBuilderPromptId.generate(),
      text: 'What were you facing?',
      ordinal: 0,
    );
    session.presentPrompt(prompt);
    session.answerPrompt(
      responseId: StoryBuilderResponseId.generate(),
      promptId: prompt.id,
      text: 'Uncertainty.',
    );
    await repository.save(session);

    final loaded = await repository.findById(session.id);
    expect(loaded!.responses, hasLength(1));
    expect(loaded.responses.single.text, 'Uncertainty.');
    expect(loaded.prompts.single.text, 'What were you facing?');
  });

  test('findResumableByHeroId returns inProgress and paused only', () async {
    final heroId = HeroId.generate();
    final active = newSession(heroId);
    final paused = newSession(heroId)..pause();
    final done = newSession(heroId)..complete();
    final otherHero = newSession(HeroId.generate());

    await repository.save(active);
    await repository.save(paused);
    await repository.save(done);
    await repository.save(otherHero);

    final resumable = await repository.findResumableByHeroId(heroId);
    expect(resumable.map((s) => s.id), containsAll([active.id, paused.id]));
    expect(resumable.map((s) => s.id), isNot(contains(done.id)));
    expect(resumable.map((s) => s.id), isNot(contains(otherHero.id)));
  });

  test('exists and delete', () async {
    final session = newSession(HeroId.generate());
    expect(await repository.exists(session.id), isFalse);
    await repository.save(session);
    expect(await repository.exists(session.id), isTrue);
    await repository.delete(session.id);
    expect(await repository.exists(session.id), isFalse);
    expect(await repository.findById(session.id), isNull);
  });
}
