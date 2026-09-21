import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_prompt_source.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_question_strategy.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

/// Adaptive AI Story Coach strategy (SB.7).
///
/// Asks the [StoryBuilderCoachPort] for the next question. Assigns prompt IDs
/// locally — the LLM never invents domain identifiers. Does not rewrite Hero
/// responses or author a polished story.
final class AiStoryBuilderQuestionStrategy
    implements StoryBuilderQuestionStrategy {
  AiStoryBuilderQuestionStrategy({
    required StoryBuilderCoachPort coach,
    this.softMaxPresentedPrompts = 20,
    StoryBuilderPromptId Function()? promptIdGenerator,
  })  : _coach = coach,
        _promptIdGenerator =
            promptIdGenerator ?? StoryBuilderPromptId.generate;

  final StoryBuilderCoachPort _coach;
  final StoryBuilderPromptId Function() _promptIdGenerator;

  /// Safety bound so questioning cannot run forever if the coach never stops.
  final int softMaxPresentedPrompts;

  @override
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session) async {
    final unanswered = _firstUnansweredPrompt(session);
    if (unanswered != null) {
      return unanswered;
    }

    if (isQuestioningComplete(session)) {
      return null;
    }

    final suggestion = await _coach.suggestNextQuestion(
      buildCoachRequest(session),
    );

    final question = suggestion.question?.trim() ?? '';
    if (suggestion.readyToComplete && question.isEmpty) {
      return null;
    }
    if (question.isEmpty) {
      throw const StoryBuilderCoachException(
        'AI Story Coach returned no question.',
      );
    }

    return StoryBuilderPrompt(
      id: _promptIdGenerator(),
      text: question,
      ordinal: session.prompts.length,
      narrativeRole: suggestion.narrativeRole,
      isOptional: true,
      source: StoryBuilderPromptSource.aiCoach,
    );
  }

  @override
  bool isQuestioningComplete(StoryBuilderSession session) {
    return session.prompts.length >= softMaxPresentedPrompts &&
        _firstUnansweredPrompt(session) == null;
  }

  /// Reconstructs minimized coach context from the durable session.
  static StoryBuilderCoachRequest buildCoachRequest(
    StoryBuilderSession session,
  ) {
    final responsesByPrompt = <String, StoryBuilderResponse>{
      for (final response in session.responses)
        response.promptId.value: response,
    };

    final turns = <StoryBuilderCoachTurn>[
      for (final prompt in session.prompts)
        StoryBuilderCoachTurn(
          promptText: prompt.text,
          ordinal: prompt.ordinal,
          narrativeRole: prompt.narrativeRole,
          responseText: responsesByPrompt[prompt.id.value]?.text,
          skipped: responsesByPrompt[prompt.id.value]?.skipped ?? false,
        ),
    ];

    return StoryBuilderCoachRequest(
      purpose: session.intent.purpose,
      themes: List.of(session.intent.themes),
      themesUnsure: session.intent.themesUnsure,
      turns: turns,
      presentedNarrativeRoles: [
        for (final prompt in session.prompts)
          if (prompt.narrativeRole != null) prompt.narrativeRole!,
      ],
    );
  }

  static StoryBuilderPrompt? _firstUnansweredPrompt(
    StoryBuilderSession session,
  ) {
    for (final prompt in session.prompts) {
      final hasResponse =
          session.responses.any((r) => r.promptId == prompt.id);
      if (!hasResponse) {
        return prompt;
      }
    }
    return null;
  }
}
