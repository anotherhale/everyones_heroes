/// Hero & Story module boundary (PF-ADR-002).
///
/// Owns: Hero, Story, representations, builder, catalog.
/// Does not own: BehavioralEvidence, BehaviorPatterns, DiscoveryProfile.
///
/// Authority migration deferred to Phase 7. `services/ai_proxy` remains
/// the interim AI credential boundary until Phase 8.
final class HeroStoryModule {
  const HeroStoryModule();

  static const String name = 'hero_story';
}
