import 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
import 'package:eh_platform/src/shared_kernel/ids/narrative_theme_reference_ids.dart';

/// Adaptive Story candidate eligibility — HS.6 discoverability + Slice 4 gates.
///
/// Mirrors Flutter:
/// - [StoryDiscoverabilityPolicy]
/// - [HeroDiscoverabilityPolicy]
/// - Discover* `authoritativeRepresentationsOnly: true`
///
/// Plus adaptive requirement: ≥1 catalog-valid Discovery [NarrativeThemeReferenceIds].
///
/// Does **not** introduce a parallel `isDiscoverable` source of truth.
/// Eligibility is always derived from lifecycle, visibility, narrative,
/// representation, Hero state, and theme IDs.
final class AdaptiveStoryCandidateEligibilityPolicy {
  const AdaptiveStoryCandidateEligibilityPolicy._();

  /// Story visibility values allowed in catalog / adaptive discovery.
  static const Set<String> discoverableStoryVisibilities = {
    'public',
    'community',
  };

  /// Hero visibility values allowed in catalog / adaptive discovery.
  static const Set<String> discoverableHeroVisibilities = {
    'public',
    'community',
  };

  static const String publishedLifecycle = 'published';
  static const String activeHeroStatus = 'active';

  /// Whether [facts] may occupy the discoverable candidate projection.
  static bool isEligible(StoryCandidateEligibilityFacts facts) {
    return evaluate(facts).isEligible;
  }

  /// Detailed evaluation for tests / sync diagnostics.
  static AdaptiveStoryCandidateEligibilityResult evaluate(
    StoryCandidateEligibilityFacts facts,
  ) {
    if (facts.lifecycleStatus != publishedLifecycle) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'story_not_published',
      );
    }
    if (!discoverableStoryVisibilities.contains(facts.storyVisibility)) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'story_visibility_not_discoverable',
      );
    }
    if (facts.hasProvisionalNarrative) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'provisional_narrative',
      );
    }
    if (!facts.hasAuthoritativeRepresentation) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'missing_authoritative_representation',
      );
    }
    if (facts.heroStatus != activeHeroStatus) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'hero_not_active',
      );
    }
    if (!discoverableHeroVisibilities.contains(facts.heroVisibility)) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'hero_visibility_not_discoverable',
      );
    }

    final catalogThemes = facts.themeIds
        .where((id) => id.trim().isNotEmpty)
        .where(NarrativeThemeReferenceIds.containsValue)
        .toSet()
        .toList()
      ..sort();

    if (catalogThemes.isEmpty) {
      return AdaptiveStoryCandidateEligibilityResult.ineligible(
        'missing_catalog_theme',
      );
    }

    return AdaptiveStoryCandidateEligibilityResult.eligible(
      catalogThemeIds: catalogThemes,
    );
  }
}

/// Result of adaptive candidate eligibility evaluation.
final class AdaptiveStoryCandidateEligibilityResult {
  const AdaptiveStoryCandidateEligibilityResult._({
    required this.isEligible,
    this.reason,
    this.catalogThemeIds = const [],
  });

  factory AdaptiveStoryCandidateEligibilityResult.eligible({
    required List<String> catalogThemeIds,
  }) {
    return AdaptiveStoryCandidateEligibilityResult._(
      isEligible: true,
      catalogThemeIds: List.unmodifiable(catalogThemeIds),
    );
  }

  factory AdaptiveStoryCandidateEligibilityResult.ineligible(String reason) {
    return AdaptiveStoryCandidateEligibilityResult._(
      isEligible: false,
      reason: reason,
    );
  }

  final bool isEligible;
  final String? reason;

  /// Catalog-valid theme IDs to store on the projection when eligible.
  final List<String> catalogThemeIds;
}
