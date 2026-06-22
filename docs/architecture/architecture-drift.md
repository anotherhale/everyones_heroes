# Architecture Drift

This document tracks places where the implementation has drifted from the intended architecture.

Unlike Technical Debt, architecture drift represents inconsistencies between the documented architecture and the current implementation.

Drift items should eventually be resolved and removed.

---

# DRIFT-001 NarrativeThemesAdded Event Missing

Status: Open

Priority: Medium

Affected Context:

Life Journey

Expected:

Reflection should publish a domain event whenever Narrative Themes are added.

Current:

Reflection.addNarrativeThemes()

updates aggregate state but does not publish an event.

Current Flow:

Reflection
↓
addNarrativeThemes()
↓
State Updated

Expected Flow:

Reflection
↓
addNarrativeThemes()
↓
NarrativeThemesAdded
↓
State Updated

Impact:

* Missing audit trail
* Missing event-driven integration point
* Inconsistent behavior compared to:

  * InsightsGenerated
  * BehavioralEvidenceDetected

Resolution:

Create:

* NarrativeThemesAdded event

Update:

* Reflection.addNarrativeThemes()

to publish the event.

Done When:

NarrativeThemesAdded is raised whenever themes are added to a Reflection.

---

# DRIFT-002 behavioral_signals_observed.dart Filename Mismatch

Status: Open

Priority: Low

Affected Context:

Life Journey

Expected:

File names should reflect contained concepts.

Current:

File:

behavioral_signals_observed.dart

Contains:

BehavioralEvidenceDetected

Historical Context:

The architecture evolved from:

GrowthSignal
↓
BehavioralSignal
↓
BehavioralEvidence

The filename was not updated during the migration.

Impact:

* Naming confusion
* Harder navigation
* Misleading architectural terminology

Resolution:

Rename:

behavioral_signals_observed.dart

to:

behavioral_evidence_detected.dart

Update imports accordingly.

Done When:

File names align with event names and current domain language.

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

# Summary

High Priority

* DRIFT-003 Domain Service Ports Located Under Infrastructure
* DRIFT-004 Use Cases Split Across Multiple Locations
* DRIFT-005 DiscoveryProfile Aggregate Missing

Medium Priority

* DRIFT-001 NarrativeThemesAdded Event Missing
* DRIFT-006 Service Locator Usage
* DRIFT-007 Fake Adapters In Production Code

Low Priority

* DRIFT-002 behavioral_signals_observed.dart Filename Mismatch

---

# Architectural Goal

The goal is not perfect architecture.

The goal is alignment between:

* Documentation
* Domain Model
* Implementation

Architecture drift should trend toward zero over time.
