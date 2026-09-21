import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Stable deterministic question catalog for Guided Story Builder (SB.3).
///
/// Common narrative sequence for all sessions. Purpose/theme branching is
/// deferred — [StoryBuilderIntent] is stored on the session but does not
/// alter this catalog in SB.3.
///
/// Prompt IDs are stable string keys (not UUIDs) so responses survive catalog
/// reordering and resume.
final class DeterministicStoryBuilderCatalog {
  const DeterministicStoryBuilderCatalog._();

  static const StoryBuilderPromptId beginningId = StoryBuilderPromptId(
    'sb.q.beginning',
  );
  static const StoryBuilderPromptId challengeId = StoryBuilderPromptId(
    'sb.q.challenge',
  );
  static const StoryBuilderPromptId importanceId = StoryBuilderPromptId(
    'sb.q.importance',
  );
  static const StoryBuilderPromptId struggleId = StoryBuilderPromptId(
    'sb.q.struggle',
  );
  static const StoryBuilderPromptId stakesId = StoryBuilderPromptId(
    'sb.q.stakes',
  );
  static const StoryBuilderPromptId turningPointId = StoryBuilderPromptId(
    'sb.q.turningPoint',
  );
  static const StoryBuilderPromptId decisionId = StoryBuilderPromptId(
    'sb.q.decision',
  );
  static const StoryBuilderPromptId actionId = StoryBuilderPromptId(
    'sb.q.action',
  );
  static const StoryBuilderPromptId outcomeId = StoryBuilderPromptId(
    'sb.q.outcome',
  );
  static const StoryBuilderPromptId reflectionId = StoryBuilderPromptId(
    'sb.q.reflection',
  );
  static const StoryBuilderPromptId messageId = StoryBuilderPromptId(
    'sb.q.message',
  );

  static final List<StoryBuilderPrompt> prompts = List.unmodifiable([
    StoryBuilderPrompt(
      id: beginningId,
      text: 'What was happening in your life when this story began?',
      ordinal: 0,
      narrativeRole: StoryBuilderNarrativeRole.beginning,
    ),
    StoryBuilderPrompt(
      id: challengeId,
      text: 'What were you facing?',
      ordinal: 1,
      narrativeRole: StoryBuilderNarrativeRole.challenge,
    ),
    StoryBuilderPrompt(
      id: importanceId,
      text: 'Why was this difficult or important to you?',
      ordinal: 2,
      narrativeRole: StoryBuilderNarrativeRole.importance,
    ),
    StoryBuilderPrompt(
      id: struggleId,
      text: 'What was the hardest part?',
      ordinal: 3,
      narrativeRole: StoryBuilderNarrativeRole.struggle,
    ),
    StoryBuilderPrompt(
      id: stakesId,
      text: 'What might you have lost, or what was at stake?',
      ordinal: 4,
      narrativeRole: StoryBuilderNarrativeRole.stakes,
    ),
    StoryBuilderPrompt(
      id: turningPointId,
      text: 'Was there a moment when something changed?',
      ordinal: 5,
      narrativeRole: StoryBuilderNarrativeRole.turningPoint,
    ),
    StoryBuilderPrompt(
      id: decisionId,
      text: 'What did you decide to do?',
      ordinal: 6,
      narrativeRole: StoryBuilderNarrativeRole.decision,
    ),
    StoryBuilderPrompt(
      id: actionId,
      text: 'What happened next?',
      ordinal: 7,
      narrativeRole: StoryBuilderNarrativeRole.action,
    ),
    StoryBuilderPrompt(
      id: outcomeId,
      text: 'How did things turn out?',
      ordinal: 8,
      narrativeRole: StoryBuilderNarrativeRole.outcome,
    ),
    StoryBuilderPrompt(
      id: reflectionId,
      text: 'What did this experience teach you?',
      ordinal: 9,
      narrativeRole: StoryBuilderNarrativeRole.reflection,
    ),
    StoryBuilderPrompt(
      id: messageId,
      text:
          'If someone else were going through something similar, '
          'what would you want them to hear?',
      ordinal: 10,
      narrativeRole: StoryBuilderNarrativeRole.message,
    ),
  ]);

  static int get length => prompts.length;

  static StoryBuilderPrompt? byId(StoryBuilderPromptId id) {
    for (final prompt in prompts) {
      if (prompt.id == id) {
        return prompt;
      }
    }
    return null;
  }

  static int? indexOf(StoryBuilderPromptId id) {
    for (var i = 0; i < prompts.length; i++) {
      if (prompts[i].id == id) {
        return i;
      }
    }
    return null;
  }
}
