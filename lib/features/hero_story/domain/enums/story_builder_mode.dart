/// How questions are sourced for a Story Builder session.
///
/// Domain remains AI-agnostic: mode is metadata only. Question content comes
/// from an application [StoryBuilderQuestionStrategy] implementation.
enum StoryBuilderMode {
  /// Guided / deterministic static prompts. No AI required.
  guided,

  /// Adaptive questioning via an AI strategy. Optional enhancement.
  ai,
}
