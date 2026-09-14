import 'package:everyonesheroes/features/life_journey/application/models/adaptive_discovery_signals.dart';
import 'package:everyonesheroes/features/life_journey/application/models/discoverable_story_candidate.dart';

/// Port for HS.8 adaptive Story candidates.
///
/// Implementations must use HS.6 Discover* (not Search* / raw repos).
abstract interface class DiscoverableStoryCandidatePort {
  /// Returns ranked discoverable Story candidates for [signals].
  ///
  /// Empty when no thematic relevance can be established (cold start).
  Future<List<DiscoverableStoryCandidate>> findRelevant(
    AdaptiveDiscoverySignals signals, {
    int limit = 20,
  });
}

/// Test/default stub that never surfaces Story candidates.
final class EmptyDiscoverableStoryCandidatePort
    implements DiscoverableStoryCandidatePort {
  const EmptyDiscoverableStoryCandidatePort();

  @override
  Future<List<DiscoverableStoryCandidate>> findRelevant(
    AdaptiveDiscoverySignals signals, {
    int limit = 20,
  }) async {
    return const [];
  }
}
