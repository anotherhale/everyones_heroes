import 'package:eh_platform/src/experience/application/models/adaptive_discovery_signals.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';

/// Experience-facing port: Discovery resolves catalog-aligned signals.
///
/// Experience Selection consumes [AdaptiveDiscoverySignals] and must not
/// interpret raw Reflection theme observations itself (J.2).
abstract interface class AdaptiveDiscoverySignalPort {
  Future<AdaptiveDiscoverySignals> resolve(Journey journey);
}

/// J.1 transitional fallback: patterns only, empty themes.
///
/// Retained for unit tests that intentionally isolate Experience Selection
/// without Discovery wiring. Production composition uses
/// CatalogAlignedAdaptiveDiscoverySignalResolver.
final class PatternsOnlyAdaptiveDiscoverySignalPort
    implements AdaptiveDiscoverySignalPort {
  const PatternsOnlyAdaptiveDiscoverySignalPort();

  @override
  Future<AdaptiveDiscoverySignals> resolve(Journey journey) async {
    return AdaptiveDiscoverySignals(
      behaviorPatterns: journey.behaviorPatterns,
    );
  }
}
