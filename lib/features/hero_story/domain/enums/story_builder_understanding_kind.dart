/// How a [StoryBuilderUnderstanding] was produced (SB.8).
///
/// Guided Builder must remain usable with [deterministic] only.
enum StoryBuilderUnderstandingKind {
  /// Derived exclusively from SB.3/SB.4 session material — no AI.
  deterministic,

  /// AI-assisted interpretation of Hero-authored responses.
  aiEnhanced,
}
