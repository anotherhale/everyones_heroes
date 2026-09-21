import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/event_assertions.dart';

void main() {
  group('StoryBuilderSession', () {
    StoryBuilderSession createSession({
      StoryBuilderMode mode = StoryBuilderMode.guided,
      StoryBuilderIntent? intent,
    }) {
      return StoryBuilderSession.create(
        id: StoryBuilderSessionId.generate(),
        heroId: HeroId.generate(),
        mode: mode,
        intent: intent,
        createdAt: DateTime.utc(2026, 9, 21, 12),
      );
    }

    StoryBuilderPrompt promptAt(int ordinal, {String text = 'What happened?'}) {
      return StoryBuilderPrompt(
        id: StoryBuilderPromptId.generate(),
        text: text,
        ordinal: ordinal,
      );
    }

    test('create raises StoryBuilderSessionCreated and starts empty', () {
      final session = createSession();
      final events = session.pullDomainEvents();
      expectEventRaised<StoryBuilderSessionCreated>(events);
      expectEventCount(events, 1);

      expect(session.status, StoryBuilderSessionStatus.inProgress);
      expect(session.mode, StoryBuilderMode.guided);
      expect(session.responses, isEmpty);
      expect(session.prompts, isEmpty);
      expect(session.storyId, isNull);
      expect(session.intent.purpose, isNull);
      expect(session.intent.themes, isEmpty);
      expect(session.intent.purposeUnsure, isFalse);
      expect(session.intent.themesUnsure, isFalse);
      expect(session.progress.presentedPromptCount, 0);
      expect(session.progress.responseCount, 0);
    });

    test('can hold purpose and theme intent without catalog apply', () {
      final session = createSession(
        intent: StoryBuilderIntent(
          purpose: 'Encourage someone',
          themes: const ['perseverance', 'family'],
        ),
      );

      expect(session.intent.purpose, 'Encourage someone');
      expect(session.intent.themes, ['perseverance', 'family']);
      expect(session.intent.hasPurpose, isTrue);
      expect(session.intent.hasThemes, isTrue);

      session.pullDomainEvents();
      session.setIntent(
        StoryBuilderIntent(purposeUnsure: true, themesUnsure: true),
      );
      expect(session.intent.purposeUnsure, isTrue);
      expect(session.intent.themesUnsure, isTrue);
    });

    test('answer preserves exact user text and response identity on edit', () {
      final session = createSession();
      session.pullDomainEvents();
      final prompt = promptAt(0);
      session.presentPrompt(prompt);

      final responseId = StoryBuilderResponseId.generate();
      const original =
          '  I lost my job and did not know how to support my family.  ';
      session.answerPrompt(
        responseId: responseId,
        promptId: prompt.id,
        text: original,
        at: DateTime.utc(2026, 9, 21, 12, 1),
      );

      expect(session.responses, hasLength(1));
      expect(session.responses.single.text, original);
      expect(session.responses.single.id, responseId);
      expect(session.responses.single.promptId, prompt.id);
      expect(session.responses.single.ordinal, 0);
      expect(session.responses.single.isEdited, isFalse);

      session.editResponse(
        responseId: responseId,
        text: 'I lost my job.',
        at: DateTime.utc(2026, 9, 21, 12, 2),
      );

      expect(session.responses.single.id, responseId);
      expect(session.responses.single.text, 'I lost my job.');
      expect(session.responses.single.isEdited, isTrue);
      expect(session.progress.answeredCount, 1);
      expect(session.progress.skippedCount, 0);
    });

    test('skip records association without inventing text', () {
      final session = createSession();
      session.pullDomainEvents();
      final prompt = promptAt(0);
      session.presentPrompt(prompt);

      final responseId = StoryBuilderResponseId.generate();
      session.skipPrompt(responseId: responseId, promptId: prompt.id);

      expect(session.responses.single.skipped, isTrue);
      expect(session.responses.single.text, isNull);
      expect(session.progress.skippedCount, 1);
      expect(session.progress.answeredCount, 0);
    });

    test('preserves response ordering across multiple prompts', () {
      final session = createSession();
      session.pullDomainEvents();

      final first = promptAt(0, text: 'Beginning');
      final second = promptAt(1, text: 'Challenge');
      session.presentPrompt(first);
      session.answerPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: first.id,
        text: 'Life was stable.',
      );
      session.presentPrompt(second);
      session.skipPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: second.id,
      );

      expect(session.prompts.map((p) => p.ordinal), [0, 1]);
      expect(session.responses.map((r) => r.ordinal), [0, 1]);
      expect(session.progress.presentedPromptCount, 2);
      expect(session.progress.responseCount, 2);
      expect(session.progress.currentPromptOrdinal, 1);
    });

    test('pause and resume transitions', () {
      final session = createSession();
      session.pullDomainEvents();
      session.pause();
      expect(session.status, StoryBuilderSessionStatus.paused);

      session.resume();
      expect(session.status, StoryBuilderSessionStatus.inProgress);
    });

    test('complete raises StoryBuilderSessionCompleted and freezes mutations', () {
      final session = createSession();
      session.pullDomainEvents();
      session.complete();

      final events = session.pullDomainEvents();
      expectEventRaised<StoryBuilderSessionCompleted>(events);
      expect(session.status, StoryBuilderSessionStatus.completed);
      expect(session.isComplete, isTrue);

      expect(
        () => session.setIntent(StoryBuilderIntent(purpose: 'x')),
        throwsStateError,
      );
    });

    test('cannot modify abandoned session', () {
      final session = createSession();
      session.pullDomainEvents();
      session.abandon();
      expect(session.status, StoryBuilderSessionStatus.abandoned);
      expect(
        () => session.presentPrompt(promptAt(0)),
        throwsStateError,
      );
    });

    test('invalid transitions and duplicate answers throw', () {
      final session = createSession();
      session.pullDomainEvents();
      final prompt = promptAt(0);
      session.presentPrompt(prompt);
      session.answerPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: prompt.id,
        text: 'Answer',
      );

      expect(
        () => session.answerPrompt(
          responseId: StoryBuilderResponseId.generate(),
          promptId: prompt.id,
          text: 'Again',
        ),
        throwsStateError,
      );

      session.complete();
      expect(
        () => session.pause(),
        throwsStateError,
      );
    });

    test('mode can be set without AI dependency', () {
      final session = createSession();
      session.pullDomainEvents();
      session.setMode(StoryBuilderMode.ai);
      expect(session.mode, StoryBuilderMode.ai);
      session.setMode(StoryBuilderMode.guided);
      expect(session.mode, StoryBuilderMode.guided);
    });
  });
}
