import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/discovery/application/use_cases/ensure_current_discovery_profile_use_case.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/narrative_theme_repository.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_discovery_summary.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/models/inspiration_story_exploration.dart';

/// D.7: Explore eligible Stories grounded in current Inspiration themes.
///
/// ```text
/// EnsureCurrentDiscoveryProfile
///      ↓
/// narrativeThemeIds (Influence → Theme union)
///      ↓
/// DiscoverStoriesUseCase (eligibility + catalog filter)
///      ↓
/// InspirationStoryExploration
/// ```
///
/// Does **not** use AdaptiveDiscoverySignals (avoids Reflection contamination).
/// Does **not** invent ranking beyond Discover* default ordering.
/// Does **not** record DiscoveryHistory or BehavioralEvidence.
abstract interface class ExploreStoriesByInspirationUseCase {
  Future<InspirationStoryExploration> execute({int limit = 20});
}

final class DefaultExploreStoriesByInspirationUseCase
    implements ExploreStoriesByInspirationUseCase {
  const DefaultExploreStoriesByInspirationUseCase({
    required this._ensureCurrentDiscoveryProfile,
    required this._discoverStories,
    required this._narrativeThemeRepository,
  });

  final EnsureCurrentDiscoveryProfileUseCase _ensureCurrentDiscoveryProfile;
  final DiscoverStoriesUseCase _discoverStories;
  final NarrativeThemeRepository _narrativeThemeRepository;

  @override
  Future<InspirationStoryExploration> execute({int limit = 20}) async {
    final profile = await _ensureCurrentDiscoveryProfile.execute();

    if (profile.influenceIds.isEmpty) {
      return InspirationStoryExploration.withoutInspirations();
    }

    final inspirationThemeIds =
        List<NarrativeThemeId>.unmodifiable(profile.narrativeThemeIds);

    if (inspirationThemeIds.isEmpty) {
      return InspirationStoryExploration(
        hasInspirations: true,
        inspirationThemeIds: inspirationThemeIds,
        stories: const [],
      );
    }

    final result = await _discoverStories.execute(
      DiscoverStoriesRequest(
        narrativeThemeIds: inspirationThemeIds,
        limit: limit,
        offset: 0,
      ),
    );

    if (result is Failure<DiscoverStoriesResponse>) {
      return InspirationStoryExploration(
        hasInspirations: true,
        inspirationThemeIds: inspirationThemeIds,
        stories: const [],
      );
    }

    final response = (result as Success<DiscoverStoriesResponse>).value;
    final themeNameById = await _themeNamesFor(inspirationThemeIds);

    final stories = response.items
        .map(
          (summary) => _toGroundedStory(
            summary: summary,
            inspirationThemeIds: inspirationThemeIds,
            themeNameById: themeNameById,
          ),
        )
        .toList(growable: false);

    return InspirationStoryExploration(
      hasInspirations: true,
      inspirationThemeIds: inspirationThemeIds,
      stories: stories,
    );
  }

  Future<Map<NarrativeThemeId, String>> _themeNamesFor(
    List<NarrativeThemeId> themeIds,
  ) async {
    final names = <NarrativeThemeId, String>{};
    for (final themeId in themeIds) {
      final theme = await _narrativeThemeRepository.findById(themeId);
      if (theme != null) {
        names[themeId] = theme.name;
      }
    }
    return names;
  }

  InspirationGroundedStory _toGroundedStory({
    required StoryDiscoverySummary summary,
    required List<NarrativeThemeId> inspirationThemeIds,
    required Map<NarrativeThemeId, String> themeNameById,
  }) {
    final inspirationSet = inspirationThemeIds.toSet();
    final matched = summary.narrativeThemeIds
        .where(inspirationSet.contains)
        .toList(growable: false);
    final matchedNames = matched
        .map((id) => themeNameById[id])
        .whereType<String>()
        .toList(growable: false);

    return InspirationGroundedStory(
      storyId: summary.storyId,
      heroId: summary.heroId,
      title: summary.title,
      heroDisplayName: summary.heroDisplayName,
      matchedThemeIds: matched,
      matchedThemeNames: matchedNames,
    );
  }
}
