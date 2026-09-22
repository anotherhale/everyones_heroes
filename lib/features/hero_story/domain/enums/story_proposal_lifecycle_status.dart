/// Lifecycle of a reviewable [StoryProposal] (SB.9 / SB.12).
///
/// Distinct from [StoryLifecycleStatus]. Transitions to [accepted] or
/// [rejected] require an explicit Hero domain operation (SB.12) — never
/// shaping, generation, or UI navigation alone.
enum StoryProposalLifecycleStatus {
  /// Constructed but not yet presented for review.
  draft,

  /// Ready for the Hero to review (default after deterministic build/shape).
  readyForReview,

  /// Hero explicitly accepted the current proposal contents.
  accepted,

  /// Hero explicitly rejected the proposal (proposal remains persisted).
  rejected,
}
