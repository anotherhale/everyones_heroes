import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeterministicStoryBuilderCatalog', () {
    test('has 11 stable prompts with narrative roles and order', () {
      expect(DeterministicStoryBuilderCatalog.length, 11);
      expect(
        DeterministicStoryBuilderCatalog.prompts.map((p) => p.id.value),
        [
          'sb.q.beginning',
          'sb.q.challenge',
          'sb.q.importance',
          'sb.q.struggle',
          'sb.q.stakes',
          'sb.q.turningPoint',
          'sb.q.decision',
          'sb.q.action',
          'sb.q.outcome',
          'sb.q.reflection',
          'sb.q.message',
        ],
      );
      expect(
        DeterministicStoryBuilderCatalog.prompts.map((p) => p.narrativeRole),
        [
          StoryBuilderNarrativeRole.beginning,
          StoryBuilderNarrativeRole.challenge,
          StoryBuilderNarrativeRole.importance,
          StoryBuilderNarrativeRole.struggle,
          StoryBuilderNarrativeRole.stakes,
          StoryBuilderNarrativeRole.turningPoint,
          StoryBuilderNarrativeRole.decision,
          StoryBuilderNarrativeRole.action,
          StoryBuilderNarrativeRole.outcome,
          StoryBuilderNarrativeRole.reflection,
          StoryBuilderNarrativeRole.message,
        ],
      );
      expect(
        DeterministicStoryBuilderCatalog.prompts.map((p) => p.ordinal),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      );
      expect(
        DeterministicStoryBuilderCatalog.prompts.first.text,
        'What was happening in your life when this story began?',
      );
      expect(
        DeterministicStoryBuilderCatalog.prompts.every((p) => p.isOptional),
        isTrue,
      );
    });
  });

  group('DeterministicStoryBuilderQuestionStrategy', () {
    const strategy = DeterministicStoryBuilderQuestionStrategy();

    StoryBuilderSession session() {
      return StoryBuilderSession.create(
        id: StoryBuilderSessionId.generate(),
        heroId: HeroId.generate(),
        mode: StoryBuilderMode.guided,
      );
    }

    test('progresses Q1 through Q11 then completes questioning', () async {
      final s = session()..pullDomainEvents();
      for (var i = 0; i < 11; i++) {
        expect(strategy.isQuestioningComplete(s), isFalse);
        final next = await strategy.nextPrompt(s);
        expect(next, isNotNull);
        expect(next!.ordinal, i);
        s.presentPrompt(next);
        s.answerPrompt(
          responseId: StoryBuilderResponseId.generate(),
          promptId: next.id,
          text: 'Answer $i — raw hero voice.',
        );
      }
      expect(strategy.isQuestioningComplete(s), isTrue);
      expect(await strategy.nextPrompt(s), isNull);
      expect(s.responses.every((r) => r.text!.contains('raw hero voice')), isTrue);
    });

    test('skip does not invent text and still advances', () async {
      final s = session()..pullDomainEvents();
      final first = await strategy.nextPrompt(s);
      s.presentPrompt(first!);
      s.skipPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: first.id,
      );
      expect(s.responses.single.skipped, isTrue);
      expect(s.responses.single.text, isNull);

      final second = await strategy.nextPrompt(s);
      expect(second!.ordinal, 1);
    });

    test('does not depend on intent / AI — same catalog regardless of purpose', () async {
      final withIntent = session()..pullDomainEvents();
      withIntent.setPurpose(StoryBuilderPurpose.inspireSomeone);
      withIntent.setThemes(
        themes: const [StoryBuilderTheme.overcomingAdversity],
      );
      final without = session()..pullDomainEvents();

      expect(
        (await strategy.nextPrompt(withIntent))!.id,
        (await strategy.nextPrompt(without))!.id,
      );
    });
  });
}
