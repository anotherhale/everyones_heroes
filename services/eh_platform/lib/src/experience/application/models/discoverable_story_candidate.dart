/// HS.8-compatible Story candidate for experience composition.
///
/// Platform J.1 does not own Hero & Story discovery. Candidates arrive through
/// [DiscoverableStoryCandidatePort] (empty by default — transitional adapter).
final class DiscoverableStoryCandidate {
  DiscoverableStoryCandidate({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.matchedThemeIds,
    required this.themeOverlapCount,
    required this.patternBoost,
    required this.updatedAt,
  });

  final String storyId;
  final String heroId;
  final String title;
  final List<String> matchedThemeIds;
  final int themeOverlapCount;
  final double patternBoost;
  final DateTime updatedAt;
}
