enum JourneyChapter {
  awakening,
  commitment,
  resistance,
  momentum,
  transformation,
  contribution,
}

extension JourneyChapterProgression on JourneyChapter {
  JourneyChapter? get next {
    switch (this) {
      case JourneyChapter.awakening:
        return JourneyChapter.commitment;

      case JourneyChapter.commitment:
        return JourneyChapter.resistance;

      case JourneyChapter.resistance:
        return JourneyChapter.momentum;

      case JourneyChapter.momentum:
        return JourneyChapter.transformation;

      case JourneyChapter.transformation:
        return JourneyChapter.contribution;

      case JourneyChapter.contribution:
        return null;
    }
  }

  bool canAdvanceTo(JourneyChapter target) {
    return next == target;
  }

  bool get isFinalChapter {
    return this == JourneyChapter.contribution;
  }
}