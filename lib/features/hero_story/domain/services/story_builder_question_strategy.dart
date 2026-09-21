import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';

/// Application-facing boundary for sourcing the next Story Builder prompt.
///
/// Implementations may be deterministic (static catalog) or AI-backed.
/// Domain [StoryBuilderSession] remains unaware of which strategy is used.
///
/// SB.1 provides the port only — no guided catalog and no AI adapter.
abstract interface class StoryBuilderQuestionStrategy {
  /// Returns the next prompt to present, or null when the strategy is done.
  Future<StoryBuilderPrompt?> nextPrompt(StoryBuilderSession session);

  /// Whether the strategy considers the session complete for questioning.
  bool isQuestioningComplete(StoryBuilderSession session);
}
