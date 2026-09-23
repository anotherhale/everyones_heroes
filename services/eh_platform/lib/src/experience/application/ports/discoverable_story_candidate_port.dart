import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';

/// Replaceable HS.8 Story candidate seam for Experience composition.
///
/// Default for unwired tests: [EmptyDiscoverableStoryCandidatePort]
/// (fail-closed to UI.3 reflection).
///
/// Platform composition (J.2 Slice 3) injects
/// [SeededDiscoverableStoryCandidateAdapter] backed by a transitional
/// Hero & Story seed catalog — replaceable by real HS persistence later.
abstract interface class DiscoverableStoryCandidatePort {
  Future<List<DiscoverableStoryCandidate>> findRelevant(
    AdaptiveDiscoverySignals signals, {
    int limit = 20,
  });
}

/// Transitional default — no platform Discovery/HS catalog yet.
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
