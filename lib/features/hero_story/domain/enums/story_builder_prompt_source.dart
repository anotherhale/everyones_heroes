/// Who authored a [StoryBuilderPrompt] text.
///
/// Guided catalog prompts use [catalog]. Adaptive AI Story Coach prompts use
/// [aiCoach]. Both share the same prompt/response model on the session.
enum StoryBuilderPromptSource {
  catalog,
  aiCoach,
}
