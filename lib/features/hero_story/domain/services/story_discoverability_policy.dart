import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';

/// Pure eligibility rules for catalog Story discovery (HS.6 / HS-ADR-043).
///
/// Discoverable visibility is exactly `{public, community}`.
/// Private and unlisted Stories are never discoverable.
final class StoryDiscoverabilityPolicy {
  const StoryDiscoverabilityPolicy._();

  /// Visibility values allowed in catalog discovery / browse.
  static const Set<StoryVisibility> discoverableVisibilities = {
    StoryVisibility.public,
    StoryVisibility.community,
  };

  static List<StoryVisibility> get discoverableVisibilityList =>
      List.unmodifiable(discoverableVisibilities.toList());

  /// Whether [story] may appear in seeker-facing discovery results.
  static bool isDiscoverable(Story story) {
    if (story.lifecycleStatus != StoryLifecycleStatus.published) {
      return false;
    }
    if (!discoverableVisibilities.contains(story.visibility)) {
      return false;
    }
    if (story.hasProvisionalNarrative) {
      return false;
    }
    return true;
  }
}
