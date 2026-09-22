/// Explicit Hero decision recorded during Story Proposal review (SB.12).
///
/// Distinct from [StoryProposalLifecycleStatus]: lifecycle is the proposal
/// workflow state; this enum is the Hero's recorded decision. Only an explicit
/// approve/reject domain operation may set a decision.
enum StoryProposalReviewDecision {
  /// Hero explicitly approved the current proposal contents.
  approved,

  /// Hero explicitly rejected the proposal (proposal remains persisted).
  rejected,
}
