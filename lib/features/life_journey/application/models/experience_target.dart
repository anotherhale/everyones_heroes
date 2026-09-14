import 'package:everyonesheroes/core/ids/story_id.dart';

/// Presentation-safe target reference for an [AdaptiveExperience].
///
/// HS.8 introduces only the Story target required for Today’s Experience
/// routing. Do not expand into a speculative multi-type hierarchy.
sealed class ExperienceTarget {
  const ExperienceTarget();
}

/// Targets a discoverable Story for HS.7 experience / consume.
final class StoryExperienceTarget extends ExperienceTarget {
  const StoryExperienceTarget({required this.storyId});

  final StoryId storyId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryExperienceTarget && storyId == other.storyId;

  @override
  int get hashCode => storyId.hashCode;
}
