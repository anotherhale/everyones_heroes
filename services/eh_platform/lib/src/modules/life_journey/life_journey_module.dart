/// Life Journey module boundary (PF-ADR-002).
///
/// Owns: Journey, Quest, Mission, Reflection, and Behavioral Understanding
/// (evidence → pattern detection) until a documented split is required.
///
/// Domain aggregates are **not** migrated in PF.3 — this module establishes
/// ownership and dependency direction only.
final class LifeJourneyModule {
  const LifeJourneyModule();

  static const String name = 'life_journey';

  /// Behavioral Understanding remains a subdomain of Life Journey (PF-ADR-002).
  static const String behavioralUnderstandingSubdomain =
      'behavioral_understanding';
}
