import 'package:everyonesheroes/features/hero_story/application/dto/story_candidate_eligibility_facts_payload.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story.dart';

/// Maps authoritative Flutter [Story] + [Hero] state into the platform
/// candidate projection ingest payload.
///
/// Contains only facts required by Slice 4 eligibility/projection.
/// Does not evaluate eligibility — platform
/// `AdaptiveStoryCandidateEligibilityPolicy` remains authoritative.
final class StoryCandidateEligibilityFactsMapper {
  const StoryCandidateEligibilityFactsMapper();

  StoryCandidateEligibilityFactsPayload fromStoryAndHero({
    required Story story,
    required Hero hero,
  }) {
    return StoryCandidateEligibilityFactsPayload(
      storyId: story.id.value,
      heroId: story.heroId.value,
      title: story.title.value,
      themeIds: story.classification.narrativeThemeIds
          .map((id) => id.value)
          .toList(growable: false),
      updatedAt: story.updatedAt.toUtc(),
      lifecycleStatus: story.lifecycleStatus.name,
      storyVisibility: story.visibility.name,
      hasProvisionalNarrative: story.hasProvisionalNarrative,
      hasAuthoritativeRepresentation:
          story.representations.any((r) => r.isAuthoritative),
      heroStatus: hero.status.name,
      heroVisibility: hero.visibility.name,
    );
  }
}
