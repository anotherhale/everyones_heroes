/// AI orchestration module boundary (PF-ADR-010).
///
/// Application depends on [AiOrchestrationPort]; provider SDKs stay in adapters.
/// Near term: keep `services/ai_proxy` as a separate deployable.
/// Target (Phase 8): absorb proxy handlers behind this module.
final class AiModule {
  const AiModule();

  static const String name = 'ai';
}
