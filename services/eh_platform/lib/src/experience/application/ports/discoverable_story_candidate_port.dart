import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/experience/application/models/discoverable_story_candidate.dart';

/// Replaceable HS.8 Story candidate seam for Experience composition.
///
/// J.1 default is [EmptyDiscoverableStoryCandidatePort] (fail-closed to UI.3
/// reflection). Injected implementations enable Story selection without
/// migrating Hero & Story authority into this module.
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
