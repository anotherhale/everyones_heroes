/// Lifecycle status for a [StoryBuilderSession].
enum StoryBuilderSessionStatus {
  inProgress,
  paused,
  completed,
  abandoned;

  bool get isMutable =>
      this == StoryBuilderSessionStatus.inProgress ||
      this == StoryBuilderSessionStatus.paused;

  bool get isTerminal =>
      this == StoryBuilderSessionStatus.completed ||
      this == StoryBuilderSessionStatus.abandoned;

  bool canTransitionTo(StoryBuilderSessionStatus next) {
    if (this == next) {
      return true;
    }

    switch (this) {
      case StoryBuilderSessionStatus.inProgress:
        return next == StoryBuilderSessionStatus.paused ||
            next == StoryBuilderSessionStatus.completed ||
            next == StoryBuilderSessionStatus.abandoned;
      case StoryBuilderSessionStatus.paused:
        return next == StoryBuilderSessionStatus.inProgress ||
            next == StoryBuilderSessionStatus.completed ||
            next == StoryBuilderSessionStatus.abandoned;
      case StoryBuilderSessionStatus.completed:
      case StoryBuilderSessionStatus.abandoned:
        return false;
    }
  }
}
