/// Experience module boundary (PF-ADR-002 / PF-ADR-013).
///
/// Owns: Today's experience composition and explainability payloads.
/// Depends on Life Journey / Discovery / Hero & Story **read ports** only.
///
/// Personalization starts as a colocated submodule (PF-ADR-002).
/// Selection migration deferred to Phase 5.
final class ExperienceModule {
  const ExperienceModule();

  static const String name = 'experience';
  static const String personalizationSubmodule = 'personalization';
}
