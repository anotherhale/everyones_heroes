import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Result of advancing the deterministic Story Builder.
final class AdvanceStoryBuilderResult {
  const AdvanceStoryBuilderResult({
    required this.session,
    required this.questioningComplete,
    this.currentPrompt,
  });

  final StoryBuilderSession session;
  final StoryBuilderPrompt? currentPrompt;
  final bool questioningComplete;
}
