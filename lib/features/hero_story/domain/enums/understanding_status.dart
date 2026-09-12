/// Lifecycle status for a [StoryUnderstanding] proposal.
enum UnderstandingStatus {
  proposed,
  partiallyReviewed,
  approved,
  rejected,
  superseded;

  bool canTransitionTo(UnderstandingStatus next) {
    if (this == next) {
      return true;
    }

    switch (this) {
      case UnderstandingStatus.proposed:
        return next == UnderstandingStatus.partiallyReviewed ||
            next == UnderstandingStatus.approved ||
            next == UnderstandingStatus.rejected ||
            next == UnderstandingStatus.superseded;
      case UnderstandingStatus.partiallyReviewed:
        return next == UnderstandingStatus.approved ||
            next == UnderstandingStatus.rejected ||
            next == UnderstandingStatus.superseded ||
            next == UnderstandingStatus.partiallyReviewed;
      case UnderstandingStatus.approved:
        return next == UnderstandingStatus.superseded;
      case UnderstandingStatus.rejected:
        return next == UnderstandingStatus.superseded;
      case UnderstandingStatus.superseded:
        return false;
    }
  }

  bool get isReviewable =>
      this == UnderstandingStatus.proposed ||
      this == UnderstandingStatus.partiallyReviewed;

  bool get isApplicable =>
      this == UnderstandingStatus.approved ||
      this == UnderstandingStatus.partiallyReviewed;
}
