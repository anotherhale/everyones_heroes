import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Non-AI strategy used only to prove the session is strategy-agnostic.
final class _FixedPromptStrategy implements StoryBuilderQuestionStrategy {
  _FixedPromptStrategy(this._prompts);

  final List<StoryBuilderPrompt> _prompts;

  @override
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session) async {
    if (session.prompts.length >= _prompts.length) {
      return null;
    }
    return _prompts[session.prompts.length];
  }

  @override
  bool isQuestioningComplete(StoryBuilderSession session) {
    return session.prompts.length >= _prompts.length &&
        session.responses.length >= _prompts.length;
  }
}

void main() {
  test('session works with a non-AI question strategy', () async {
    final prompts = [
      StoryBuilderPrompt(
        id: StoryBuilderPromptId.generate(),
        text: 'Beginning?',
        ordinal: 0,
      ),
      StoryBuilderPrompt(
        id: StoryBuilderPromptId.generate(),
        text: 'Challenge?',
        ordinal: 1,
      ),
    ];
    final strategy = _FixedPromptStrategy(prompts);
    final session = StoryBuilderSession.create(
      id: StoryBuilderSessionId.generate(),
      heroId: HeroId.generate(),
    );

    while (!strategy.isQuestioningComplete(session)) {
      final next = await strategy.nextPrompt(session);
      expect(next, isNotNull);
      session.presentPrompt(next!);
      // Caller records response; strategy does not mutate domain.
      session.skipPrompt(
        responseId: StoryBuilderResponseId.generate(),
        promptId: next.id,
      );
    }

    expect(session.prompts, hasLength(2));
    expect(session.responses, hasLength(2));
    expect(strategy.isQuestioningComplete(session), isTrue);
  });
}
