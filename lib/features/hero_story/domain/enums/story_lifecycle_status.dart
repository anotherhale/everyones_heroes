enum StoryLifecycleStatus {
  draft,
  processing,
  review,
  approved,
  published,
  archived,
  rejected,
  suspended,
  removed,
}

extension StoryLifecycleTransitions on StoryLifecycleStatus {
  bool canTransitionTo(StoryLifecycleStatus next) {
    switch (this) {
      case StoryLifecycleStatus.draft:
        return next == StoryLifecycleStatus.processing ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.processing:
        return next == StoryLifecycleStatus.review ||
            next == StoryLifecycleStatus.draft ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.review:
        return next == StoryLifecycleStatus.approved ||
            next == StoryLifecycleStatus.rejected ||
            next == StoryLifecycleStatus.processing;
      case StoryLifecycleStatus.approved:
        return next == StoryLifecycleStatus.published ||
            next == StoryLifecycleStatus.review ||
            next == StoryLifecycleStatus.archived;
      case StoryLifecycleStatus.published:
        return next == StoryLifecycleStatus.archived ||
            next == StoryLifecycleStatus.suspended ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.archived:
        return next == StoryLifecycleStatus.published ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.rejected:
        return next == StoryLifecycleStatus.draft ||
            next == StoryLifecycleStatus.review ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.suspended:
        return next == StoryLifecycleStatus.published ||
            next == StoryLifecycleStatus.removed;
      case StoryLifecycleStatus.removed:
        return false;
    }
  }
}
