/// Distinguishes Hero-authored proposal content from derived metadata (SB.9).
///
/// Prefer this over a vague `isAiGenerated` flag. Deterministic SB.9 section
/// bodies use [heroAuthored] (verbatim response text). Optional proposal-level
/// notes from Understanding use [derived].
enum StoryProposalContentOrigin {
  /// Content is the Hero's Story Builder response text (canonical source).
  heroAuthored,

  /// Content or metadata was derived (e.g. Understanding summary) — not a
  /// claim that the Hero authored that wording.
  derived,
}
