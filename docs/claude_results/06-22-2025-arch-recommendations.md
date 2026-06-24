❯ Review architecture-drift.md.

  For each drift item:

  1. Evaluate whether it is true architectural drift or technical debt.
  2. Recommend priority order.
  3. Produce a step-by-step migration plan.
  4. Identify any risks or breaking changes.
  5. Do not modify code.

  Read 1 file

Let me read the key files that each drift item affects before forming re

  Searched for 5 patterns, read 7 files

Let me check one more thing before writing the review — the duplicate ev

  Searched for 2 patterns, read 2 files

I have everything I need. Here is the full review.

---
Architecture Drift Review

Classification: Drift vs. Debt

The document treats all items as "drift" but the distinction matters for scheduling and ownership.

True architectural drift — implementation contradicts an explicit, documented architecture decision:

- DRIFT-003: Ports in the wrong layer (violates the hexagonal dependency rule)
- DRIFT-004: Split use case locations (violates single application layer
- DRIFT-008: Dead GrowthSignal artifacts (explicitly violates AD-005)

Technical debt — intentional shortcuts or unfinished work, not a contradiction of the architecture:

- DRIFT-005: DiscoveryProfile not implemented (planned feature, not a violation)
- DRIFT-006: Service locator (documented as a deliberate bootstrap short
- DRIFT-007: Fakes in lib/ (intentional during the pre-AI phase; the architecture allows fakes, just not in that folder)
- DRIFT-009: Filename typo (naming cleanup, not an architecture issue)

This matters because the three true drift items should be resolved beforop of them. The debt items can be scheduled independently.

---
Priority Order

┌───────┬────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Order │        Item        │                                          ale                                                                  │
├───────┼────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1     │ DRIFT-008          │ Isolated dead-code removal. No aggregate confusion from BehavioralEvidenceType before it compounds.             │
├───────┼────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2     │ DRIFT-003 +        │ Foundational hexagonal fix. Move ports to consolidation (DRIFT-004) immediately imports from the correct      │
│       │ DRIFT-009          │ location. Subsumes the typo fix.                                                                                                           │
├───────┼────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3     │ DRIFT-004          │ Consolidate use cases. Safe to do after DRIFT-003 so consolidated files reference correct domain/services paths from the start.            │
├───────┼────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4     │ DRIFT-007          │ Move fakes to test/. Unblocked once use case consolidation is complete and import graph is stable.                                         │
├───────┼────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5     │ DRIFT-006          │ Service locator removal. Depends on Riverpod integration decisions and the presentation layer existing to justify the change.              │
├───────┼────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6     │ DRIFT-005          │ Full bounded context implementation. Independent of Life Journey stability. Begin when Discovery work starts.                              │
└───────┴────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

---
DRIFT-008 — BehavioralSignalGenerated Is Orphaned

Classification: True drift. AD-005 explicitly states GrowthSignal-era concepts must not be introduced. The migration to BehavioralEvidence completed in production but left
artifacts behind.

What is actually dead:
- behavioral_signal.dart — entity, imported by nothing in lib/
- behavioral_signal_generated.dart — event, raised by no aggregate
- growth_signal_generated_test.dart — tests a deprecated concept
- behaviorial_signal_test.dart — tests the entity being deleted

What is still live and must be handled carefully:
- BehavioralEvidenceType enum — actively used by BehavioralEvidence.signalType and by FakeBehavioralSignalAnalyzer. This is the only risky rename.

Step-by-step plan:

1. Rename behavioral_signal_type.dart: BehavioralEvidenceType → BehavioralEvidenceType. The values themselves (discipline, courage, resilience, etc.) are valid domain language
— only the enum container name changes.
2. In behavioral_evidence.dart: rename the signalType field to evidenceType and update the type reference.
3. In fake_behavioral_signal_analyzer.dart: update the enum reference.
4. In all test files that construct BehavioralEvidence directly (behaviorial_evidence_test.dart, reflection_test.dart, analyze_reflection_use_case_test.dart,
fake_behaviorial_signal_analyzer_test.dart): update field name and enum
5. Delete behavioral_signal_generated.dart.
6. Delete behavioral_signal.dart.
7. Delete growth_signal_generated_test.dart.
8. Delete behaviorial_signal_test.dart (entity is gone; tests are meanin
9. Run flutter analyze && flutter test.

Risks:
- The signalType → evidenceType rename on BehavioralEvidence is the only~4 test files. There is no production code path that readsbehavioralEvidence.signalType outside tests yet, so this is contained.
- If the BehavioralEvidenceType values are ever serialized to a database onum container name is safe (the values are what gets stored), butrenaming values would not be. Only the container name changes here.

---
DRIFT-003 — Domain Service Ports Located Under Infrastructure (+ DRIFT-0

Classification: True drift. The hexagonal dependency rule is: domain ← aWhen AnalyzeReflectionUseCase imports InsightExtractionService frominfrastructure/services/, the application layer now depends on infrastructure by path, even though the interface has no infrastructure implementation. That inverts the
dependency arrow.

Current state:
lib/features/life_journey/
  infrastructure/services/
    insight_extraction_service.dart         ← port (interface), wrong location
    behavioral_evidencel_analyzer.dart      ← port (interface), wrong lo
    narrative_theme_resolver.dart           ← port (interface), wrong location
    fake/
      fake_insight_extraction_service.dart  ← adapter, correct layer, wrong folder
      fake_behavioral_signal_analyzer.dart  ← adapter, correct layer, wr
      fake_narrative_theme_resolver.dart    ← adapter, correct layer, wrong folder

Step-by-step plan:

1. Create lib/features/life_journey/domain/services/ directory.
2. Move insight_extraction_service.dart → domain/services/insight_extrac changes needed; the interface references Reflection and Insight whichare both domain objects.
3. Move behavioral_evidencel_analyzer.dart → domain/services/behavioral_ct the filename typo in the move. No content changes needed.
4. Move narrative_theme_resolver.dart → domain/services/narrative_theme_resolver.dart. No content changes needed.
5. Update analyze_reflection_use_case.dart imports: replace three infrashs with three domain/services/ import paths.
6. Update the three fake adapters to import their interface from the new domain/services/ path.
7. Update all test files that import these interfaces (primarily analyzet and the three fake service tests).
8. Run flutter analyze && flutter test.

Risks:
- Low. This is file moves only. No API surface changes.
- The BehavioralEvidenceAnalyzer interface imports Reflection from the domain — that import is already correct, it's just the interface file's location that is wrong. No
circular dependency is introduced.
- One subtlety: if DRIFT-007 (moving fakes to test/) is done after this step, the fakes will already import their ports from domain/services/. The second move will be
import-path-only changes with no risk of confusion.

---
DRIFT-004 — Use Cases Split Across Multiple Locations

Classification: True drift. This is an incomplete refactoring. The contexts/ directory was the original home; features/ is the intended destination. The migration was started
(two newer use cases landed in features/) but the five older ones were n

Additional finding not in the drift document: lib/contexts/life_journey/itted.dart is a second, orphaned copy of ReflectionSubmitted. It has noexternal references — the contexts/ domain layer is entirely inert. It should be deleted as part of this cleanup.

Current split:
lib/contexts/life_journey/application/       ← old location (5 use cases
  create_journey_use_case.dart              ← only one implementing UseCase<>
  create_quest_use_case.dart
  create_mission_use_case.dart
  complete_mission_use_case.dart
  submit_reflection_use_case.dart
  use_case.dart                             ← UseCase<Request, Response>

lib/features/life_journey/application/      ← new location (2 use cases)
  analyze_reflection_use_case.dart          ← no UseCase<> interface
  use_cases/
    create_reflection_use_case.dart         ← no UseCase<> interface

Test files importing from the old path (all need import updates):
test/life_journey/create_journey_use_case_test.dart
test/life_journey/create_quest_use_case_test.dart
test/life_journey/create_mission_use_case_test.dart
test/life_journey/complete_mission_use_case_test.dart
test/life_journey/submit_reflection_use_case_test.dart
test/life_journey/mission_lifecycle_integration_test.dart

Step-by-step plan:

1. Decide the fate of UseCase<Request, Response>. Two options:
  - A (recommended): Promote to shared kernel (lib/core/shared_kernel/uscan implement it uniformly.
  - B: Keep it in features/life_journey/application/use_cases/use_case.dart and apply it to all seven use cases.
Apply the interface to CreateQuestUseCase, CreateMissionUseCase, ComplettionUseCase, CreateReflectionUseCase, and AnalyzeReflectionUseCase.
2. Move each of the five use cases (and their request objects) from contexts/life_journey/application/ to features/life_journey/application/use_cases/:
  - create_journey_use_case.dart + create_journey_request.dart
  - create_quest_use_case.dart + create_quest_request.dart
  - create_mission_use_case.dart + create_mission_request.dart
  - complete_mission_use_case.dart + complete_mission_request.dart
  - submit_reflection_use_case.dart + submit_reflection_request.dart
3. Move analyze_reflection_use_case.dart and analyze_reflection_request.dart from features/life_journey/application/ into features/life_journey/application/use_cases/ (it
currently sits one level above the use_cases/ folder).
4. Update imports in all moved use cases to reference domain/services/ ports (already fixed if DRIFT-003 was done first).
5. Update the six test files listed above: change import paths from cont
6. Delete lib/contexts/life_journey/domain/events/reflection_submitted.dart (orphaned duplicate).
7. Delete the lib/contexts/ directory entirely once empty.
8. Run flutter analyze && flutter test.

Risks:
- The UseCase<> interface decision is the only design choice. If it stay Contribution use cases will need to import across contexts — a futureboundary issue. Promoting it to core/shared_kernel/ is clean.
- All five moved use cases already use proper constructor injection — nohs only.
- The orphaned contexts/life_journey/domain/events/reflection_submitted.dart deletion: verify no reference exists before deleting. The grep returned empty, but confirm with
dart pub get && flutter analyze after the move.
- If any bootstrap or runner code (e.g., a future Riverpod provider file) imports from contexts/, that would break and need updating. Currently none do.

---
DRIFT-007 — Fake Adapters In Production Code

Classification: Technical debt. The fakes are not used by AppCompositionr DemoRunner — only by tests. They are safe to move.

Step-by-step plan:

1. Create test/fakes/life_journey/ directory.
2. Move the three fake adapters:
  - lib/features/.../fake/fake_insight_extraction_service.dart → test/fa
  - lib/features/.../fake/fake_behavioral_signal_analyzer.dart → test/fakes/life_journey/
  - lib/features/.../fake/fake_narrative_theme_resolver.dart → test/fake
3. Update import paths in all three fake-service test files and in analyze_reflection_use_case_test.dart.
4. Delete lib/features/life_journey/infrastructure/services/fake/ direct
5. Run flutter test.

Risks:
- Low. The only consumers are test files.
- Defer this item. If real AI adapters are introduced before this is done, the fakes will likely be deleted rather than moved. Doing this move prematurely just creates an
extra migration step. The document's current recommendation to defer is

---
DRIFT-006 — Service Locator Usage

Classification: Technical debt. The locator only manages three event infrastructure objects (EventStore, EventDispatcher, EventBus). All use cases receive dependencies
through constructors — that's already correct DI. The locator is a bootsn coupling.

Step-by-step plan (Riverpod path — preferred):

1. Add flutter_riverpod as a dependency.
2. Create provider file: lib/bootstrap/providers/event_infrastructure_providers.dart with Riverpod providers for EventStore, EventDispatcher, EventBus.
3. Create providers for repositories and use cases.
4. Update AppCompositionRoot to use ProviderScope.
5. Remove DependencyRegistration and ApplicationBootstrap static registr
6. Update all test files that currently call DependencyRegistration.register() to use ProviderContainer instead.

Risks:
- This is the most cross-cutting change. Every test that touches the boo
- The decision to use Riverpod should be made when the presentation layer is being built, not before. Building Riverpod providers without any UI consumers means building
infrastructure with no validation that the provider graph is correct.
- Defer until the first screen is being wired. Doing it earlier introduces Riverpod overhead without the feedback loop that confirms the provider structure is right.

---
DRIFT-005 — DiscoveryProfile Aggregate Missing

Classification: Technical debt (with a drift element). The drift is realme exist without an aggregate enforcing ownership. But the resolution isimplementing a planned-but-not-yet-built bounded context, which is feature work.

Step-by-step plan:

1. Define DiscoveryProfile aggregate invariants before writing code:
  - A DiscoveryProfile must belong to a UserId.
  - An Influence can only be added if it is not already present.
  - NarrativeThemeId references are derived from selected Influences, no
2. Implement DiscoveryProfile aggregate in lib/features/discovery/domain/aggregates/discovery_profile.dart.
3. Define DiscoveryProfileRepository interface in lib/features/discovery
4. Define NarrativeThemeRepository interface (currently 0 bytes) in lib/features/discovery/domain/repositories/.
5. Implement InMemoryDiscoveryProfileRepository in lib/features/discover/.
6. Implement use cases in lib/features/discovery/application/use_cases/:
  - CreateDiscoveryProfileUseCase
  - AddInfluenceUseCase
  - SelectInfluenceUseCase
7. Define and raise events: InfluenceAdded, DiscoveryProfileCreated.
8. Write aggregate invariant tests, repository contract tests, and use c
9. Register in bootstrap.

Risks:
- This is new domain design, not refactoring. The hardest part is the in whether DiscoveryProfile stores Influence directly or by reference, andhow Narrative Theme resolution works at the aggregate boundary.
- Do not attempt this while DRIFT-003 and DRIFT-004 are unresolved — thefollow the same structural conventions as the corrected Life Journey usecases, or they immediately create new drift.
- InfluenceRepository is entirely missing. Decide whether influences arefile (aggregate-owned) or via a standalone repository beforeimplementing.

---
Summary Table

┌───────────────────────────────┬───────────┬──────────────┬───────────────────────────────┬───────────────────────────────────────────────┐
│             Item              │   True    │  Technical   │            Order             │          Blocking?          │                     Risk                      │
│                               │   Drift   │     Debt     │                               │                                               │
├───────────────────────────────┼───────────┼──────────────┼──────────────────────────────┼─────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-008 BehavioralSignal    │ ✓         │              │ 1          locked by it       │ Low — BehavioralEvidenceType rename touches ~4  │
│ cleanup                       │           │              │                              │                             │ test files                                    │
├───────────────────────────────┼───────────┼──────────────┼───────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-009 Filename typo       │           │ ✓            │ Bundled with DRIFT-003       │ Nothing                     │ Trivial                                       │
├───────────────────────────────┼───────────┼──────────────┼───────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-003 Ports to domain     │ ✓         │              │ 2                            │ DRIFT-004 import            │ Low — file moves only                         │
│ layer                         │           │              │            ss                 │                                               │
├───────────────────────────────┼───────────┼──────────────┼──────────────────────────────┼─────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-004 Use case            │ ✓         │              │ 3          but grows worse    │ Medium — 6 test files, UseCase<> interface    │
│ consolidation                 │           │              │                              │ over time                   │ decision                                      │
├───────────────────────────────┼───────────┼──────────────┼───────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-007 Fakes in lib/       │           │ ✓            │ 4, defer until AI adapters   │ Nothing                     │ Low                                           │
├───────────────────────────────┼───────────┼──────────────┼───────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-006 Service locator     │           │ ✓            │ 5, defer until Riverpod      │ Nothing                     │ High — cross-cutting                          │
│                               │           │              │ integration                   │                                               │
├───────────────────────────────┼───────────┼──────────────┼──────────────────────────────┼─────────────────────────────┼───────────────────────────────────────────────┤
│ DRIFT-005 DiscoveryProfile    │ Partial   │ ✓            │ 6, independ work              │ High — new domain design                      │
└───────────────────────────────┴───────────┴──────────────┴──────────────────────────────┴─────────────────────────────┴───────────────────────────────────────────────┘

The recommended sequence for the next working session is DRIFT-008 → DRIFT-003 (absorbing DRIFT-009) → DRIFT-004. These three can be done consecutively without touching any
UI code, without making design decisions, and without risk of breaking tecoverable import-path updates.