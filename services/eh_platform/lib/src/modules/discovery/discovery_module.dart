/// Discovery module boundary (PF-ADR-002).
///
/// Owns: Influences, NarrativeTheme entities, DiscoveryProfile.
/// Other modules reference NarrativeThemeId only.
///
/// Product wiring deferred to Phase 6.
final class DiscoveryModule {
  const DiscoveryModule();

  static const String name = 'discovery';
}
