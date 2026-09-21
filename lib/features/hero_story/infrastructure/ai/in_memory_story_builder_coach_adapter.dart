import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/story_builder_coach_port.dart';

/// Deterministic development/test [StoryBuilderCoachPort] (no network).
///
/// Walks SB.3 narrative roles with adaptive follow-ups when the latest answer
/// mentions quitting/fear/decision keywords. Never invents a polished story.
final class InMemoryStoryBuilderCoachAdapter
    implements StoryBuilderCoachPort {
  InMemoryStoryBuilderCoachAdapter({
    this.forcedFailureMessage,
    this.forcedSuggestion,
    this.suggestions,
  });

  final String? forcedFailureMessage;
  final StoryBuilderCoachSuggestion? forcedSuggestion;
  final List<StoryBuilderCoachSuggestion>? suggestions;

  var _suggestionIndex = 0;

  static const List<_RoleQuestion> _roleSequence = [
    _RoleQuestion(
      StoryBuilderNarrativeRole.beginning,
      'What was happening in your life when this story began?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.challenge,
      'What challenge were you facing?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.importance,
      'Why did that moment matter to you?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.struggle,
      'What made it hard to keep going?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.stakes,
      'What was at stake if things did not change?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.turningPoint,
      'What was the turning point?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.decision,
      'What decision did you make?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.action,
      'What did you do next?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.outcome,
      'How did things turn out?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.reflection,
      'Looking back, what do you understand now that you did not then?',
    ),
    _RoleQuestion(
      StoryBuilderNarrativeRole.message,
      'If someone facing something similar heard your story, what would you want them to take from it?',
    ),
  ];

  @override
  Future<StoryBuilderCoachSuggestion> suggestNextQuestion(
    StoryBuilderCoachRequest request,
  ) async {
    final failure = forcedFailureMessage;
    if (failure != null) {
      throw StoryBuilderCoachException(failure);
    }

    if (forcedSuggestion != null) {
      return forcedSuggestion!;
    }

    final scripted = suggestions;
    if (scripted != null) {
      if (_suggestionIndex >= scripted.length) {
        return const StoryBuilderCoachSuggestion(readyToComplete: true);
      }
      return scripted[_suggestionIndex++];
    }

    final answeredTurns = request.turns
        .where((t) => !t.skipped && (t.responseText ?? '').isNotEmpty)
        .toList();
    final lastAnswer = answeredTurns.isEmpty
        ? null
        : answeredTurns.last.responseText!.toLowerCase();
    final lastPromptText =
        request.turns.isEmpty ? '' : request.turns.last.promptText;

    if (lastAnswer != null) {
      final alreadyFollowedUp = lastPromptText.contains('quitting') ||
          lastPromptText.contains('frightening') ||
          lastPromptText.contains('keep going');
      if (!alreadyFollowedUp) {
        if (lastAnswer.contains('quit') || lastAnswer.contains('give up')) {
          return const StoryBuilderCoachSuggestion(
            question: 'What made you feel like quitting?',
            narrativeRole: StoryBuilderNarrativeRole.struggle,
            reason: 'follow_up_quit',
          );
        }
        if (lastAnswer.contains('scared') || lastAnswer.contains('afraid')) {
          return const StoryBuilderCoachSuggestion(
            question: 'What made that moment so frightening?',
            narrativeRole: StoryBuilderNarrativeRole.stakes,
            reason: 'follow_up_fear',
          );
        }
      } else if (lastPromptText.contains('quitting') &&
          (lastAnswer.isNotEmpty)) {
        return const StoryBuilderCoachSuggestion(
          question: 'What made you decide to keep going?',
          narrativeRole: StoryBuilderNarrativeRole.decision,
          reason: 'follow_up_persist',
        );
      }
    }

    final covered = request.presentedNarrativeRoles.toSet();
    for (final item in _roleSequence) {
      if (!covered.contains(item.role)) {
        return StoryBuilderCoachSuggestion(
          question: item.question,
          narrativeRole: item.role,
          reason: 'cover_${item.role.name}',
        );
      }
    }

    if (request.turns.length >= 8) {
      return const StoryBuilderCoachSuggestion(readyToComplete: true);
    }

    return const StoryBuilderCoachSuggestion(
      question: 'Is there anything else about this experience you want to share?',
      narrativeRole: StoryBuilderNarrativeRole.reflection,
      reason: 'closing_open',
    );
  }
}

final class _RoleQuestion {
  const _RoleQuestion(this.role, this.question);

  final StoryBuilderNarrativeRole role;
  final String question;
}
