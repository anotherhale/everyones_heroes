import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';
import 'package:eh_platform/src/experience/application/ports/discoverable_story_candidate_port.dart';
import 'package:eh_platform/src/hero_story/application/ports/story_candidate_source.dart';
import 'package:eh_platform/src/hero_story/application/services/deterministic_story_relevance_ranker.dart';

/// Hero & Story adapter: [StoryCandidateSource] → Experience port (J.2 Slice 4).
///
/// ```text
/// Experience
///     ↓
/// DiscoverableStoryCandidatePort  (this adapter)
///     ↓
/// StoryCandidateSource            (live Postgres projection / test double)
///     ↓
/// DeterministicStoryRelevanceRanker
/// ```
///
/// Source-agnostic: production wires [PostgresStoryCandidateSource]; tests may
/// inject [SeededStoryCandidateCatalog] or an in-memory projection.
///
/// Does not move theme classification into Experience.
/// Does not invent Stories when signals lack themes or overlap.
final class DiscoverableStoryCandidateAdapter
    implements DiscoverableStoryCandidatePort {
  const DiscoverableStoryCandidateAdapter({
    required StoryCandidateSource candidateSource,
    DeterministicStoryRelevanceRanker ranker =
        const DeterministicStoryRelevanceRanker(),
  })  : _candidateSource = candidateSource,
        _ranker = ranker;

  final StoryCandidateSource _candidateSource;
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

    final records = await _candidateSource.listCandidates();
    final ranked = _ranker.rank(records: records, signals: signals);

    if (ranked.length <= limit) {
      return ranked;
    }
    return List.unmodifiable(ranked.take(limit));
  }
}

/// @Deprecated('Use DiscoverableStoryCandidateAdapter')
/// Kept as a typedef so Slice 3 test imports keep compiling during rename.
typedef SeededDiscoverableStoryCandidateAdapter
    = DiscoverableStoryCandidateAdapter;
