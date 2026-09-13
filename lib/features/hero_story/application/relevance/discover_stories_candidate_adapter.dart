import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/relevance/deterministic_story_relevance_ranker.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';
import 'package:everyonesheroes/features/life_journey/application/ports/discoverable_story_candidate_port.dart';

/// HS.8 candidate adapter: Discover* eligibility + deterministic relevance.
///
/// Never uses Search* or raw repositories for seeker-facing candidates.
final class DiscoverStoriesCandidateAdapter
    implements DiscoverableStoryCandidatePort {
  const DiscoverStoriesCandidateAdapter({
    required DiscoverStoriesUseCase discoverStoriesUseCase,
    DeterministicStoryRelevanceRanker ranker =
        const DeterministicStoryRelevanceRanker(),
  }) : _discoverStoriesUseCase = discoverStoriesUseCase,
       _ranker = ranker;

  final DiscoverStoriesUseCase _discoverStoriesUseCase;
  final DeterministicStoryRelevanceRanker _ranker;

  @override
  Future<List<DiscoverableStoryCandidate>> findRelevant(
    AdaptiveDiscoverySignals signals, {
    int limit = 20,
  }) async {
    // Themes are required for adaptive Story relevance (cold-start safe).
    // Patterns alone do not invent thematic matches.
    if (!signals.hasThemes) {
      return const [];
    }

    final result = await _discoverStoriesUseCase.execute(
      DiscoverStoriesRequest(
        narrativeThemeIds: signals.narrativeThemeIds,
        limit: limit,
        offset: 0,
      ),
    );

    return result.fold(
      onSuccess: (DiscoverStoriesResponse response) {
        return _ranker.rank(
          summaries: response.items,
          signals: signals,
        );
      },
      onFailure: (_) => const <DiscoverableStoryCandidate>[],
    );
  }
}
