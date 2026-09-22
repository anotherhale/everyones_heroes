import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_proposal_review_decision.dart';

/// Durable Hero review metadata for a [StoryProposal] (SB.12).
///
/// Captures the explicit review decision and whether content was edited after
/// a prior decision. Does not overwrite [StoryProposalContentOrigin] provenance.
///
/// Not a general audit framework — scoped to Story Proposal review only.
final class StoryProposalReview extends ValueObject {
  StoryProposalReview({
    this.decision,
    this.reviewedAt,
    this.revision = 0,
    this.editedAfterDecision = false,
    this.lastEditedAt,
    this.titleHeroEdited = false,
    this.summaryHeroEdited = false,
    this.titleBeforeHeroEdit,
    this.summaryBeforeHeroEdit,
  }) {
    if (revision < 0) {
      throw ArgumentError('revision cannot be negative.');
    }
    if (decision != null && reviewedAt == null) {
      throw ArgumentError('reviewedAt is required when a decision is recorded.');
    }
    final titleBaseline = titleBeforeHeroEdit?.trim();
    if (titleBeforeHeroEdit != null &&
        (titleBaseline == null || titleBaseline.isEmpty)) {
      throw ArgumentError(
        'titleBeforeHeroEdit cannot be blank when provided.',
      );
    }
    final summaryBaseline = summaryBeforeHeroEdit?.trim();
    if (summaryBeforeHeroEdit != null &&
        (summaryBaseline == null || summaryBaseline.isEmpty)) {
      throw ArgumentError(
        'summaryBeforeHeroEdit cannot be blank when provided.',
      );
    }
  }

  /// Empty review metadata (no Hero decision yet).
  factory StoryProposalReview.empty() => StoryProposalReview();

  /// Explicit Hero decision, or null when none has been recorded / was cleared.
  final StoryProposalReviewDecision? decision;

  /// When the current [decision] was recorded.
  final DateTime? reviewedAt;

  /// Monotonic content revision; increments on each Hero content edit.
  final int revision;

  /// True when content changed after a prior approve/reject decision.
  final bool editedAfterDecision;

  /// When the Hero last edited title, summary, or section content.
  final DateTime? lastEditedAt;

  final bool titleHeroEdited;
  final bool summaryHeroEdited;

  /// Title text as it existed before the Hero's first title edit.
  final String? titleBeforeHeroEdit;

  /// Summary text as it existed before the Hero's first summary edit.
  final String? summaryBeforeHeroEdit;

  bool get hasExplicitDecision => decision != null;

  /// Approval was recorded but content changed afterward (lifecycle should be
  /// readyForReview until the Hero approves again).
  bool get isApprovalStale =>
      decision == StoryProposalReviewDecision.approved && editedAfterDecision;

  StoryProposalReview copyWith({
    StoryProposalReviewDecision? decision,
    bool clearDecision = false,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
    int? revision,
    bool? editedAfterDecision,
    DateTime? lastEditedAt,
    bool clearLastEditedAt = false,
    bool? titleHeroEdited,
    bool? summaryHeroEdited,
    String? titleBeforeHeroEdit,
    bool clearTitleBeforeHeroEdit = false,
    String? summaryBeforeHeroEdit,
    bool clearSummaryBeforeHeroEdit = false,
  }) {
    return StoryProposalReview(
      decision: clearDecision ? null : (decision ?? this.decision),
      reviewedAt:
          clearReviewedAt ? null : (reviewedAt ?? this.reviewedAt),
      revision: revision ?? this.revision,
      editedAfterDecision: editedAfterDecision ?? this.editedAfterDecision,
      lastEditedAt:
          clearLastEditedAt ? null : (lastEditedAt ?? this.lastEditedAt),
      titleHeroEdited: titleHeroEdited ?? this.titleHeroEdited,
      summaryHeroEdited: summaryHeroEdited ?? this.summaryHeroEdited,
      titleBeforeHeroEdit: clearTitleBeforeHeroEdit
          ? null
          : (titleBeforeHeroEdit ?? this.titleBeforeHeroEdit),
      summaryBeforeHeroEdit: clearSummaryBeforeHeroEdit
          ? null
          : (summaryBeforeHeroEdit ?? this.summaryBeforeHeroEdit),
    );
  }

  @override
  List<Object?> get equalityProps => [
    decision,
    reviewedAt,
    revision,
    editedAfterDecision,
    lastEditedAt,
    titleHeroEdited,
    summaryHeroEdited,
    titleBeforeHeroEdit,
    summaryBeforeHeroEdit,
  ];
}
