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

  /// JSON transport shape for HTTP ingest (J.2 Slice 5).
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

  /// Parse HTTP / test JSON into facts. Throws [FormatException] when required
  /// fields are missing or mistyped.
  factory StoryCandidateEligibilityFacts.fromJson(Map<String, Object?> json) {
    String requireString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('$key is required');
      }
      return value;
    }

    bool requireBool(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('$key must be a boolean');
      }
      return value;
    }

    final themeRaw = json['themeIds'];
    if (themeRaw is! List) {
      throw const FormatException('themeIds must be an array');
    }
    final themeIds = themeRaw.map((e) => e.toString()).toList();

    final updatedRaw = json['updatedAt'];
    if (updatedRaw is! String || updatedRaw.trim().isEmpty) {
      throw const FormatException('updatedAt is required');
    }
    final updatedAt = DateTime.tryParse(updatedRaw);
    if (updatedAt == null) {
      throw const FormatException('updatedAt must be an ISO-8601 timestamp');
    }

    return StoryCandidateEligibilityFacts(
      storyId: requireString('storyId'),
      heroId: requireString('heroId'),
      title: requireString('title'),
      themeIds: themeIds,
      updatedAt: updatedAt.toUtc(),
      lifecycleStatus: requireString('lifecycleStatus'),
      storyVisibility: requireString('storyVisibility'),
      hasProvisionalNarrative: requireBool('hasProvisionalNarrative'),
      hasAuthoritativeRepresentation:
          requireBool('hasAuthoritativeRepresentation'),
      heroStatus: requireString('heroStatus'),
      heroVisibility: requireString('heroVisibility'),
    );
  }
}
