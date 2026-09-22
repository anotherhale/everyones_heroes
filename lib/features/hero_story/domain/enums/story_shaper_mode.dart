/// How a [StoryProposal] should be shaped (SB.10 / SB.11).
///
/// Independent of [StoryBuilderMode] interview strategy — a Hero may use
/// guided/AI interviewing and still choose deterministic or AI shaping.
enum StoryShaperMode {
  /// Offline deterministic organization (SB.10).
  deterministic,

  /// AI-assisted narrative authoring of the proposal (SB.11).
  ai,
}
