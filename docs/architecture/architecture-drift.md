# Architecture Drift

This document tracks places where the implementation has drifted from the intended architecture.

Unlike Technical Debt, architecture drift represents inconsistencies between the documented architecture and the current implementation.

Drift items should eventually be resolved and removed.

---

# DRIFT-003 Domain Service Ports Located Under Infrastructure

Status: Open

Priority: High

Affected Context:

Life Journey

Expected:

Domain service interfaces should reside in the domain layer.

Examples:

* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

Current:

Interfaces live under:

infrastructure/services/

while implementations also live under infrastructure.

Impact:

* Blurs hexagonal boundaries
* Makes ports appear implementation-specific
* Weakens separation between domain and infrastructure

Expected Structure:

domain/
└── services/
├── insight_extraction_service.dart
├── behavioral_evidence_analyzer.dart
└── narrative_theme_resolver.dart

infrastructure/
└── services/
├── openai_insight_extraction_service.dart
├── anthropic_insight_extraction_service.dart
└── ...

Resolution:

Move interfaces into:

domain/services/

Keep implementations in:

infrastructure/services/

Done When:

All service ports reside in the domain layer.

---

# DRIFT-004 Use Cases Split Across Multiple Locations

Status: Open

Priority: High

Affected Context:

Life Journey

Expected:

All application use cases should reside in:

features/life_journey/application/use_cases/

Current:

Use cases exist in multiple locations.

Examples:

contexts/life_journey/application/

and

features/life_journey/application/

Historical Context:

Migration from the earlier context-based architecture was started but not completed.

Impact:

* Harder navigation
* Duplicate architectural patterns
* Confusing onboarding experience
* Increased maintenance cost

Resolution:

Consolidate all Life Journey use cases into:

features/life_journey/application/use_cases/

Remove legacy locations.

Done When:

A single application layer contains all Life Journey use cases.

---

# DRIFT-005 DiscoveryProfile Aggregate Missing

Status: Open

Priority: High

Affected Context:

Discovery

Expected:

Discovery bounded context should expose an aggregate root.

Expected Aggregate:

DiscoveryProfile

Current:

Implemented:

* Influence
* NarrativeTheme

Missing:

* DiscoveryProfile Aggregate
* DiscoveryProfileRepository
* Discovery Use Cases

Impact:

* No consistency boundary
* No aggregate ownership model
* Discovery concepts exist without a root aggregate

Architectural Consequence:

Influence and NarrativeTheme currently exist without an aggregate enforcing lifecycle and ownership rules.

Resolution:

Implement:

* DiscoveryProfile aggregate
* DiscoveryProfileRepository
* Discovery use cases

Done When:

All Discovery concepts are owned by a DiscoveryProfile aggregate.

---

# DRIFT-006 Service Locator Usage

Status: Open

Priority: Medium

Affected Context:

Cross-Cutting

Expected:

Dependencies should be injected through composition and provider wiring.

Current:

DependencyRegistration maintains mutable static state.

Examples:

* Static repository registration
* Static service registration
* Static event bus registration

Impact:

* Hidden dependencies
* Shared state across tests
* Reduced test isolation
* Harder runtime composition

Architectural Concern:

The project aims to follow Hexagonal Architecture and Dependency Injection.

Service Locator introduces implicit coupling.

Resolution Options:

Option A:

Riverpod-based dependency composition.

Option B:

Composition Root pattern.

Option C:

Dedicated dependency injection framework.

Preferred:

Riverpod composition.

Done When:

Static dependency registration is no longer required.

---

# DRIFT-007 Fake Adapters In Production Code

Status: Open

Priority: Medium

Affected Context:

Life Journey

Expected:

Production code should contain production adapters.

Test doubles should live under:

test/

Current:

Fake implementations exist under:

lib/features/life_journey/infrastructure/services/fake/

Examples:

* FakeInsightExtractionService
* FakeBehavioralEvidenceAnalyzer
* FakeNarrativeThemeResolver

Historical Context:

These were introduced to enable early development before AI integrations existed.

Impact:

* Production code contains testing infrastructure
* Blurs distinction between real adapters and test doubles
* Future contributors may accidentally use fakes in production

Resolution Options:

Option A:

Move fakes into:

test/fakes/

Option B:

Keep them temporarily and replace them with real adapters during AI integration.

Recommendation:

Defer until real AI adapters are introduced.

Done When:

Production code contains only production adapters.

---

# DRIFT-008 BehavioralSignalGenerated Event Is Orphaned

Status: Open

Priority: Medium

Affected Context:

Life Journey

Expected:

Per AD-005, GrowthSignal-era artifacts should be deprecated.

No aggregate should reference BehavioralSignalGenerated.

Current:

`behavioral_signal_generated.dart` defines `BehavioralSignalGenerated`.

No aggregate in lib/ raises this event.

`behavioral_signal.dart` defines a `BehavioralSignal` entity that is imported by nothing in lib/.

`BehavioralSignalType` enum is still referenced by `BehavioralEvidence`, creating naming confusion.

The test file `growth_signal_generated_test.dart` has a name that references the deprecated GrowthSignal concept.

Impact:

* Dead code increases cognitive overhead
* Naming creates confusion with the current BehavioralEvidence model
* Signals that the migration from GrowthSignal → BehavioralEvidence is incomplete

Resolution:

Remove:

* `behavioral_signal_generated.dart`
* `behavioral_signal.dart`
* `growth_signal_generated_test.dart`

Rename:

* `BehavioralSignalType` → `BehavioralEvidenceType` or `EvidenceType`

Update:

* `BehavioralEvidence` to reference the renamed type

Done When:

All GrowthSignal and BehavioralSignal artifacts are removed from production code.

---

# DRIFT-009 behavioral_evidencel_analyzer.dart Filename Typo

Status: Open

Priority: Low

Affected Context:

Life Journey

Expected:

`behavioral_evidence_analyzer.dart`

Current:

`behavioral_evidencel_analyzer.dart`

The filename has a stray 'l' between 'evidence' and '_analyzer'.

Impact:

* Confusing navigation
* Inconsistent naming

Resolution:

Rename:

`behavioral_evidencel_analyzer.dart`

to:

`behavioral_evidence_analyzer.dart`

Update imports accordingly.

Done When:

Filename matches the class it contains.

---

# Summary

High Priority

* DRIFT-003 Domain Service Ports Located Under Infrastructure
* DRIFT-004 Use Cases Split Across Multiple Locations
* DRIFT-005 DiscoveryProfile Aggregate Missing

Medium Priority

* DRIFT-006 Service Locator Usage
* DRIFT-007 Fake Adapters In Production Code
* DRIFT-008 BehavioralSignalGenerated Event Is Orphaned

Low Priority

* DRIFT-009 behavioral_evidencel_analyzer.dart Filename Typo

---

# Architectural Goal

The goal is not perfect architecture.

The goal is alignment between:

* Documentation
* Domain Model
* Implementation

Architecture drift should trend toward zero over time.
