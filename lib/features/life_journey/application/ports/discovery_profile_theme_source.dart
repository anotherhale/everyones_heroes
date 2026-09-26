import 'package:everyonesheroes/core/ids/narrative_theme_id.dart';

/// Cross-context read port: DiscoveryProfile narrative themes for adaptive
/// experience selection.
///
/// Life Journey / Experience consumes Discovery-owned theme IDs without
/// importing Discovery aggregates. Implementations live in Discovery
/// application/infrastructure and are wired at composition.
///
/// Returns an empty list when no profile exists or themes are unresolved.
abstract interface class DiscoveryProfileThemeSource {
  Future<List<NarrativeThemeId>> currentUserNarrativeThemeIds();
}

/// Default: no DiscoveryProfile contribution (cold start / tests).
final class EmptyDiscoveryProfileThemeSource
    implements DiscoveryProfileThemeSource {
  const EmptyDiscoveryProfileThemeSource();

  @override
  Future<List<NarrativeThemeId>> currentUserNarrativeThemeIds() async {
    return const [];
  }
}
