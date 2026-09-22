/// How a [StoryProposal] was produced (SB.9).
///
/// Foundation is deterministic only. Future AI shaping converges on the same
/// proposal model with [aiShaped] (or similar) without changing the contract.
enum StoryProposalDerivationKind {
  /// Built offline from session + SB.4 structure + deterministic Understanding.
  deterministic,
}
