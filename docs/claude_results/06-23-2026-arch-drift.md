
---
Architecture Drift Review

Classification: Drift vs. Technical Debt

┌───────────┬───────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│   Item    │      Classification       │                                                               Rationale                                                               │
├───────────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-003 │ True Architectural Drift  │ Interfaces are pure domain contracts with zero infrastructure imports; their location contradicts hexagonal architecture at the       │
│           │                           │ structural level                                                                                         │
├───────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-004 │ Resolved (in progress)    │ Git status shows all contexts/lifstaged for deletion; use cases already consolidated under               │
│           │                           │ features/life_journey/application/use_cases/                                                                                          │
├───────────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-005 │ True Architectural Drift  │ discovery_profile.dart exists but is an empty 1-line file; no DiscoveryProfileRepository or use cases; Influence and NarrativeTheme   │
│           │                           │ float without an aggregate root e                                                                        │
├───────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-006 │ Technical Debt, narrower  │ DependencyRegistration only managventStore, EventDispatcher, EventBus) — not repositories or services.   │
│           │ than documented           │ The document overstates scope. Still a valid concern for test isolation.                                                              │
├───────────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-007 │ Technical Debt            │ Fakes are in the right layer (infrastructure), wrong folder. No hexagonal boundary is violated — this is a code organization issue    │
├───────────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-008 │ Largely Resolved          │ BehavioralSignalType → BehavioralEvidenceType rename is done. behavioral_signal.dart and behavioral_signal_generated.dart are gone.   │
│           │                           │ Remaining artifacts: fake_behavionaming) and growth_signal_fixture.dart in test fixtures                 │
├───────────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-009 │ Technical Debt            │ Pure filename typo (behavioral_ev                                                                        │
└───────────┴───────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

---
Recommended Priority Order

1. DRIFT-004 — Commit the staged deletions (now)
The work is done; the tree is inconsistent until those deletions are committed. Every test run until then risks confusion about which use case location is authoritative.

2. DRIFT-008 — Remove remaining signal artifacts (next)
Small, bounded, zero-risk. Leaving fake_behavioral_signal_analyzer.dart namtradicts the "Evidence" rename and will confuse anyone reading the fakesalongside the interfaces. Bundle with DRIFT-009.

3. DRIFT-009 — Fix filename typo (bundle with DRIFT-008)
One rename + import update. Zero risk. Costs nothing to fix now, costs comp

4. DRIFT-003 — Move service ports to domain/services/ (before first AI adap
This must happen before any real AI adapter is written. Once a real adapter exists and imports the interface from infrastructure/, moving it requires updating two files instead of
one. The window to fix this cheaply closes at AI integration time.

5. DRIFT-005 — Flesh out DiscoveryProfile (before Discovery use cases are n
The aggregate file exists but is empty. This needs real implementation before any recommendation or narrative guidance work begins. The Influence and NarrativeTheme entities are
orphaned without it.

6. DRIFT-006 — Replace service locator with Riverpod composition (before UI
Low urgency today (only eventing infrastructure is affected), but must be resolved before Riverpod providers wire up application services, or you'll have two competing composition
roots.

7. DRIFT-007 — Move fakes to test/ (defer to AI integration)
The document's own recommendation is correct. When a real InsightExtractionService adapter is introduced, the fake should move to test/fakes/. Doing it now produces churn without
benefit.

---
Step-by-Step Migration Plans

---
DRIFT-004 — Commit staged deletions

1. Verify test/life_journey/ tests still pass after the context deletions (ons).
2. Commit the staged deletions as a single focused commit: "remove legacy contexts/life_journey/application layer".
3. Update DRIFT-004 status to Resolved.

Risk: If any test file still imports from contexts/life_journey/applicationrep -r "contexts/life_journey/application" test/ before committing.

---
DRIFT-008 + DRIFT-009 — Signal cleanup + typo fix

1. Rename fake_behavioral_signal_analyzer.dart → fake_behavioral_evidence_analyzer.dart. Update the class name inside from FakeBehavioralSignalAnalyzer →
FakeBehavioralEvidenceAnalyzer.
2. Update all imports of the old filename.
3. Rename behavioral_evidencel_analyzer.dart → behavioral_evidence_analyzere all imports.
4. Delete test/features/life_journey/domain/fixtures/growth_signal_fixture.dart if it is unreferenced; if referenced, rename it to behavioral_evidence_fixture.dart and update its
contents.
5. Search for any remaining GrowthSignal, BehavioralSignal (non-BehavioralSignalType since that's already renamed), or growth_signal strings in lib/ — there should be none after
steps 1–4.
6. Run full test suite. Commit.

Risk: Low. Pure renames. The only breakage risk is an import that was missed.

---
DRIFT-003 — Move service ports to domain/services/

1. Create lib/features/life_journey/domain/services/ directory.
2. Move these three files into it:
  - infrastructure/services/insight_extraction_service.dart → domain/servic.dart
  - infrastructure/services/narrative_theme_resolver.dart → domain/services/narrative_theme_resolver.dart
  - infrastructure/services/behavioral_evidence_analyzer.dart (post-DRIFT-0behavioral_evidence_analyzer.dart
3. Update imports in all fake adapters under infrastructure/services/fake/ to reference new domain paths.
4. Update imports in use cases (analyze_reflection_use_case.dart etc.) thatastructure path.
5. Update imports in DependencyRegistration if it wires these (currently it doesn't appear to, but verify).
6. Run flutter analyze to catch any remaining stale imports.
7. Run full test suite. Commit.

Risk: Medium. This is a file-move with cascading import updates. flutter analyze will surface every missed import. No behavioral change — only structural.

---
DRIFT-005 — Implement DiscoveryProfile aggregate

The file at lib/features/discovery/domain/aggregates/discovery_profile.dartuilt from scratch. Suggested steps:

1. Define DiscoveryProfile as the aggregate root for Discovery. It should o
  - DiscoveryProfileId
  - List<InfluenceId> (references, not embedded entities)
  - List<NarrativeThemeId> (resolved from influences)
  - Lifecycle invariants (e.g., cannot add duplicate influences)
2. Create lib/features/discovery/domain/repositories/discovery_profile_repository.dart as an abstract interface (port).
3. Create a DiscoveryProfileRepository in-memory implementation under infra
4. Create Discovery use cases under features/discovery/application/use_cases/:
  - AddInfluenceUseCase
  - ResolveNarrativeThemesUseCase (can be deferred)
5. Write aggregate tests first (domain-first per AD-010).
6. Run full test suite. Commit.

Risk: Medium-high. This is new code. The main design risk is whether DiscoveryProfile owns Influence entities directly or only InfluenceId references. Given the size and richness
of Influence, references are safer — avoids loading the full catalog into eore writing the aggregate.

---
DRIFT-006 — Replace service locator with Riverpod composition

Current scope is narrower than documented: only InMemoryEventStore, InMemoryEventDispatcher, and InMemoryEventBus are registered statically.

1. Create a Riverpod Provider for each:
  - eventStoreProvider
  - eventDispatcherProvider
  - eventBusProvider
2. Wire these in the app's ProviderScope overrides at startup (in application_bootstrap.dart).
3. Update use cases and handlers that currently call DependencyRegistrationt bus via constructor injection.
4. Remove DependencyRegistration class entirely.
5. In tests, override providers via ProviderContainer — this replaces the c problem.
6. Run full test suite. Commit.

Risk: Medium. The primary risk is test isolation — tests that currently rely on DependencyRegistration.register() being called once must be updated to create fresh
ProviderContainer instances. This is the entire motivation for the fix, so

---
DRIFT-007 — Move fakes to test/ (deferred)

When a real AI adapter is introduced:

1. Move lib/features/life_journey/infrastructure/services/fake/ → test/fakes/life_journey/.
2. Update all test imports.
3. Delete the fake/ directory from lib/.

Risk: Low. Pure structural move at the time of AI integration.

---
Breaking Change Summary

┌───────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│     Item      │                                                               Breaking Changes                                                               │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-003     │ Import paths change in fakes and use cases — compile-time, caught by flutter analyze                                                         │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-004     │ Any test still importing from contexts/ will fail — verify before committing deletions                                                       │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-005     │ No breaking changes — additive only                                                                                                          │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-006     │ Tests that depend on DependencyRegistration.register() shared state will need to move to ProviderContainer — behavioral change in test setup │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-007     │ Test imports change — compile-time only                                                                                                      │
├───────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DRIFT-008/009 │ Import paths for fake and analyzer change — compile-time only                                                                                │
└───────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
