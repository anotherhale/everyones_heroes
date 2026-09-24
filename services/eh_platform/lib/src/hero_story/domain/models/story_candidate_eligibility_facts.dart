/// Authoritative Story + Hero facts needed to evaluate adaptive candidate
/// eligibility **without** importing the Flutter Story/Hero aggregates.
///
/// This is a transitional projection input (J.2 Slice 4), not a second Story
/// model. Phase 7 replaces this with platform Story/Hero authority + events.
///
/// String values mirror Flutter enum `.name` values:
/// - lifecycle: draft, processing, review, approved, published, archived, …
/// - storyVisibility / heroVisibility: private, draft, unlisted, community, public
/// - heroStatus: active, archived
final class StoryCandidateEligibilityFacts {
  const StoryCandidateEligibilityFacts({
    required this.storyId,
    required this.heroId,
    required this.title,
    required this.themeIds,
    required this.updatedAt,
    required this.lifecycleStatus,
    required this.storyVisibility,
    required this.hasProvisionalNarrative,
    required this.hasAuthoritativeRepresentation,
    required this.heroStatus,
    required this.heroVisibility,
  });

  final String storyId;
  final String heroId;
  final String title;
  final List<String> themeIds;
  final DateTime updatedAt;

  /// Flutter [StoryLifecycleStatus.name].
  final String lifecycleStatus;

  /// Flutter [StoryVisibility.name].
  final String storyVisibility;

  /// Flutter `Story.hasProvisionalNarrative`.
  final bool hasProvisionalNarrative;

  /// Parity with Discover* `authoritativeRepresentationsOnly: true`.
  final bool hasAuthoritativeRepresentation;

  /// Flutter [HeroStatus.name].
  final String heroStatus;

  /// Flutter [HeroVisibility.name].
  final String heroVisibility;
}
