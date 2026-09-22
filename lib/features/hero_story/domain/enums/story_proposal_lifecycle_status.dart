/// Lifecycle of a reviewable [StoryProposal] (SB.9).
///
/// Distinct from [StoryLifecycleStatus]. SB.9 establishes the boundary;
/// full Hero review/approval workflow is deferred.
enum StoryProposalLifecycleStatus {
  /// Constructed but not yet presented for review.
  draft,

  /// Ready for the Hero to review (default after deterministic build).
  readyForReview,

  /// Hero accepted the proposal (future review workflow).
  accepted,

  /// Hero rejected the proposal (future review workflow).
  rejected,
}
