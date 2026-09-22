/// How a [StoryProposal] was produced (SB.9 / SB.10 / SB.11).
///
/// Deterministic and AI shaping converge on the same [StoryProposal] model.
enum StoryProposalDerivationKind {
  /// Built offline from session + SB.4 structure + deterministic Understanding,
  /// or deterministically shaped (SB.9 / SB.10).
  deterministic,

  /// AI-assisted shaping of an existing proposal (SB.11). Not Hero-authored.
  aiShaped,
}
