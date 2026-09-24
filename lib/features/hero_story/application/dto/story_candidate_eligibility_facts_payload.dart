/// Flutter-side eligibility facts payload for platform candidate projection
/// ingest (J.2 Slice 5).
///
/// Mirrors `StoryCandidateEligibilityFacts` on EH Platform. Not a Candidate
/// aggregate — transport facts only. Domain ownership stays on [Story]/[Hero].
final class StoryCandidateEligibilityFactsPayload {
  const StoryCandidateEligibilityFactsPayload({
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
  final String lifecycleStatus;
  final String storyVisibility;
  final bool hasProvisionalNarrative;
  final bool hasAuthoritativeRepresentation;
  final String heroStatus;
  final String heroVisibility;

  Map<String, Object?> toJson() => {
        'storyId': storyId,
        'heroId': heroId,
        'title': title,
        'themeIds': themeIds,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'lifecycleStatus': lifecycleStatus,
        'storyVisibility': storyVisibility,
        'hasProvisionalNarrative': hasProvisionalNarrative,
        'hasAuthoritativeRepresentation': hasAuthoritativeRepresentation,
        'heroStatus': heroStatus,
        'heroVisibility': heroVisibility,
      };
}
