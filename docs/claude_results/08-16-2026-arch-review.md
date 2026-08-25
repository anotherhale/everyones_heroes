
I'll start by surveying the repository structure and documentation before diving into the source code.

  Searched for 4 patterns

Now let me read the core files systematically. I'll fan out reads in parallel.

  Searched for 4 patterns, read 58 files

Now let me read the key tests and integration tests.

  Searched for 11 patterns, read 25 files

Now I have enough information for a comprehensive review. Let me compile the full findings.

---

Everyone's Heroes — Adversarial Architecture Review

---

A. Architecture Violations

AV-1 — CRITICAL: Core Shared Kernel Depends on a Feature Domain Type

Location: lib/core/eventing/domain_event.dart:3, lib/core/eventing/event_base.dart:4

// domain_event.dart — shared kernel
import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

abstract base class DomainEvent {
  AggregateType get aggregateType;  // pulls life_journey enum into core

Principle: Shared kernel / core must not depend on feature domains. Dependency direction is features → core, not the reverse.

Why it's a problem: AggregateType is defined inside features/life_journey/domain/enums/. Every bounded context — Discovery, future Contribution — must import a Life Journey type to implement DomainEvent. The Discovery context's events already import this enum across the context boundary (discovery/domain/events/influence_added.dart:4). Any new bounded context inherits this unintentional coupling from day one.

Recommended change (mandatory): Move AggregateType to lib/core/eventing/aggregate_type.dart or, better, replace the typed enum with a plain String aggregateType getter (more extensible across contexts without enum growth).

---

AV-2 — CRITICAL: Domain Model Imports Flutter SDK

Location: lib/features/life_journey/domain/patterns/behavior_pattern.dart:1

import 'package:flutter/foundation.dart';   // Flutter in the domain!

final class BehaviorPattern {
  ...
  bool operator ==(...) {
    ...
    listEquals(supportingEvidence, other.supportingEvidence);

Principle: CLAUDE.md and AD-009/AD-010 both state "Domain never depends on Flutter." The domain is supposed to be a plain Dart library.

Why it's a problem: Domain tests cannot be run as pure Dart tests — they pull in the Flutter SDK. Flutter upgrades can break domain compilation. The package:meta/meta.dart already present in the project provides @immutable. A simple two-line list equality helper removes the Flutter dependency entirely.

Recommended change (mandatory): Replace package:flutter/foundation.dart with package:meta/meta.dart for @immutable and inline a list equality comparison.

---

AV-3 — HIGH: Production Providers Wire to Fake/Stub Implementations

Location: lib/features/life_journey/application/providers/services/

// behavioral_evidence_analyzer_provider.dart
final behavioralEvidenceAnalyzerProvider = Provider<BehavioralEvidenceAnalyzer>((ref) {
  return FakeBehavioralEvidenceAnalyzer();   // hardcoded test double
});

// insight_extraction_service_provider.dart
final insightExtractionServiceProvider = Provider<InsightExtractionService>((ref) {
  return FakeInsightExtractionService();    // always returns one hardcoded insight
});

Principle: Production code should not depend on test doubles. DRIFT-007 was supposed to close this (marked "Closed 2026-06-23") but the fakes were merely relocated from infrastructure/services/fake/ to application/providers/fake/. The criterion stated in DRIFT-007 — "production code contains only production adapters" — is NOT met.

Why it's a problem: The entire analysis pipeline (Reflection → Insights → BehavioralEvidence → Themes) runs on stubbed data. Real implementations exist (RuleBasedInsightExtractionService in infrastructure) but are not wired up. All behavioral evidence from reflections will always be a single hardcoded selfAwareness at strength 0.8.

Recommended change (mandatory): Wire the production providers to real infrastructure implementations. Move the fake implementations exclusively to test/fakes/.

---

AV-4 — HIGH: Application Layer Has Riverpod Dependency

Location: All files under lib/features/life_journey/application/providers/

// journey_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return InMemoryJourneyRepository();
});

Principle: Hexagonal architecture requires the application layer to be framework-free. The Riverpod Provider DSL belongs in the composition root / bootstrap layer, not in application/.

Why it's a problem: Every application-layer file carries a Riverpod import. This means unit testing a use case requires a Riverpod container. It forces future developers to wire DI via Riverpod even if the team later chooses a different DI strategy. It also blurs the boundary between application orchestration and framework-level wiring.

Recommended change (mandatory): Move all *_provider.dart files from application/providers/ into a dedicated bootstrap/providers/ or app/di/ layer. Application use cases and domain services should remain pure Dart, assembled by the composition root.

---

AV-5 — HIGH: Ephemeral ProviderContainer in AppCompositionRoot

Location: lib/app/app_composition_root.dart:5-12

static Future<void> initialize() async {
  final container = ProviderContainer();   // created locally
  final bootstrap = ApplicationBootstrap(container: container);
  await bootstrap.initialize();
  // container is never stored — goes out of scope here
}

Principle: Composition root must control object lifetime.

Why it's a problem: The container holding all repositories, services, and use cases is a local variable. When initialize() returns, the container is eligible for GC. The ReactorRegistration registers reactors that hold references to use cases, which in turn hold repository instances that are now orphaned. Real runtime state cannot persist between operations. The main.dart demonstrates the full picture: DemoRunner.run() initializes and discards the container, then renders a Placeholder widget — there is currently no persistent application state.

Recommended change (mandatory): Store the ProviderContainer for the application lifetime, pass it to the widget tree via ProviderScope, or store it as a singleton accessible to the composition root.

---

AV-6 — HIGH: Cross-Bounded-Context Import (Discovery → Life Journey Enum)

Location: lib/features/discovery/domain/events/influence_added.dart:4, influence_removed.dart:4, narrative_themes_resolved.dart:4

import 'package:everyonesheroes/features/life_journey/domain/enums/aggregate_type.dart';

Principle: Bounded contexts communicate via shared kernel types or domain events, never via direct domain model imports from other contexts.

Why it's a problem: The Discovery context now has a compile-time dependency on the Life Journey context. Moving or renaming AggregateType in Life Journey would silently break Discovery. This is the same root cause as AV-1 but a separate manifestation.

Recommended change: Resolved entirely by fixing AV-1 (relocating AggregateType to core).

---

AV-7 — HIGH: Duplicate and Conflicting BasePatternRule Classes

Locations:
- lib/features/life_journey/domain/patterns/base_pattern_rule.dart — exported by domain.dart, uses normalizedStrength()
- lib/features/life_journey/domain/patterns/rules/base_pattern_rule.dart — NOT exported, uses plain division, is dead code

The actual pattern rules (ConsistencyPatternRule, etc.) extend BasePatternRule through the domain.dart barrel (which exports the version at patterns/base_pattern_rule.dart). The file at patterns/rules/base_pattern_rule.dart is an orphaned duplicate that serves no purpose. The two implementations compute averageStrength differently.

Recommended change: Delete patterns/rules/base_pattern_rule.dart.

---

B. Architectural Risks

AR-1 — HIGH: Silent Failure in Reactor Chain

Location: lib/features/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart:17-27

Future<void> react(ReflectionSubmitted event) async {
  final result = await _useCase.execute(...);
  result.fold(
    onSuccess: (value) {/* Handle success case */},
    onFailure: (error) {/* Handle failure case */},  // swallowed
  );
}

Both branches are empty. If reflection analysis fails (e.g., service throws, reflection not found), the failure is silently discarded with no log, no compensation, no retry. The event-driven pipeline gives no observable signal that processing failed.

Recommended change (mandatory): At minimum, log failures. Longer term, consider a dead-letter mechanism.

---

AR-2 — HIGH: Pattern Detection is O(n) on All Journey Reflections

Location: lib/features/life_journey/application/use_cases/detect_pattern_use_case.dart:32-38

final reflections = await _reflectionRepository.findByJourneyId(journeyId);
final evidence = reflections
    .expand((reflection) => reflection.behavioralEvidence)
    .toList(growable: false);
final patterns = _detector.detect(evidence: evidence);

Every BehavioralEvidenceDetected event triggers a full reload of all reflections for the journey and re-runs all pattern rules across the entire evidence corpus. As a user accrues hundreds of reflections, this grows unbounded. There is no incremental or windowed detection.

Recommended change: Design pattern detection to be incremental — either use a snapshot aggregate that caches accumulated evidence, or implement windowed rule evaluation.

---

AR-3 — MEDIUM: BehaviorPattern Ownership Conflict with Architecture Principles

Location: lib/features/life_journey/domain/aggregates/journey.dart:31, 92-113

final List<BehaviorPattern> _behaviorPatterns;

void updateBehaviorPatterns(List<BehaviorPattern> detectedPatterns) {
  _behaviorPatterns..clear()..addAll(detectedPatterns);

CLAUDE.md AD-006 states "Journey should not directly own behavioral evidence." BehaviorPattern is a pattern derived from evidence — storing it in Journey makes the Journey aggregate grow with user behavior. The documented "Future Architecture" in aggregate-map.md anticipates a GrowthProfile as the correct owner.

Risk: Every re-run of pattern detection fully replaces the pattern list with no history. Temporal evolution of patterns is lost.

---

AR-4 — MEDIUM: No Optimistic Concurrency Control

Location: lib/features/life_journey/infrastructure/repositories/in_memory_journey_repository.dart:8-26

@override
Future<void> save(Journey journey) async {
  _store[journey.id] = journey;  // blind overwrite, no version check
}

Concurrent saves silently overwrite each other. While the current in-memory implementation runs synchronously, there is no version field on aggregates to retrofit when a real persistence layer is introduced.

---

AR-5 — MEDIUM: Orphaned PatternsDetected Event

Location: lib/features/life_journey/domain/events/patterns_detected.dart

PatternsDetected (aggregateType: behavioralEvidence) and BehaviorPatternsDetected (aggregateType: journey) both exist as separate events with identical payloads. Only BehaviorPatternsDetected is raised (by Journey.updateBehaviorPatterns()). PatternsDetected is never raised by any aggregate and has no registered reactor.

---

C. Code/Documentation Inconsistencies

CD-1 — HIGH: DRIFT-007 Marked Closed but Criterion Not Met

The DRIFT-007 resolution criterion is: "Production code contains only production adapters." This is false. The fakes moved from infrastructure/services/fake/ to application/providers/fake/ and are still imported by production providers.

CD-2 — MEDIUM: aggregate-map.md Shows DiscoveryProfile as "Planned"

DiscoveryProfile aggregate, DiscoveryProfileRepository, and two use cases all exist and are tested. The aggregate map document says "Status: Planned."

CD-3 — MEDIUM: TD-001 Describes Pattern Detection as Missing Despite Full Implementation

TD-001 says "there is no Pattern Detection layer." In reality, PatternDetector, RuleBasedPatternDetector, six PatternRule implementations, BehaviorPattern, and DefaultDetectPatternUseCase are all fully implemented and tested.

CD-4 — LOW: Dead behavioral_evidence_type.dart Value Object

lib/features/life_journey/domain/value_objects/behavioral_evidence_type.dart contains a second, incompatible BehavioralEvidence class (using field name evidenceType and missing observedAt). It is not imported anywhere and not exported from domain.dart. It is dead code that creates naming confusion.

CD-5 — LOW: Old and New Test Directory Structures Coexist

Use case tests exist at both test/life_journey/ and test/features/life_journey/application/use_cases/. New tests should have a canonical home.

---

D. Unnecessary Complexity

UC-1 — MEDIUM: EvidenceStatistics Is Unconnected Speculation

Location: lib/features/life_journey/domain/value_objects/evidence_statistics.dart

This class implements slope, linear regression, momentum, plateau detection, standard deviation, and variance — all for BehavioralEvidence. Nothing in the domain, application, or infrastructure layer uses it. This is premature abstraction anticipating analytics that doesn't exist. When the system is ready for this, the implementation should be guided by actual use cases, not pre-speculated.

UC-2 — LOW: Empty Scaffolding Directories

- lib/features/life_journey/application/ports/ — empty
- lib/features/life_journey/domain/behavior_patterns/ — entire directory is empty (including events/, models/, rules/, services/ subdirectories)

These directories add cognitive overhead and signal incomplete work without context.

UC-3 — LOW: Insight Does Not Extend ValueObject

Insight manually implements equality without extending the ValueObject base class used by all other value objects, creating inconsistency. EvidenceStatistics has the same issue.

---

E. Missing Architectural Protections

MP-1 — HIGH: No Real Persistence Adapter and No Adapter Contract Test

All repositories use in-memory Map storage. There are no abstract contract tests (e.g., a JourneyRepositoryContract mixin) that any future SQL/Firestore implementation must pass. When a real persistence layer is introduced, there is nothing to verify the contract.

MP-2 — MEDIUM: No Error Propagation or Dead-Letter Pattern in Event Pipeline

When the ReflectionSubmittedReactor or BehavioralEvidenceDetectedReactor encounters a failure, the pipeline silently terminates. There is no retry mechanism, no dead-letter store, no alerting. This is particularly important given that the entire analysis pipeline runs asynchronously post-submission.

MP-3 — MEDIUM: DateTime.now() Bypasses Clock Abstraction in Three Places

The Clock interface and FixedClock implementation exist in the shared kernel but are not used by:
- Reflection.create() — sets _createdAt
- Reflection.submit() — sets _submittedAt
- Mission.complete() — sets _completedAt
- EventBase constructor — sets _occurredAt

This makes reflection timeline tests non-deterministic. TD-007 acknowledges this but marks it Low priority. The correct fix is to accept Clock in Reflection.create() and Mission.complete() since they are factory-constructed. For EventBase, an optional DateTime? occurredAt parameter already exists but DateTime.now() is the fallback — this is adequate for now.

---

F. Things the Architecture Does Particularly Well

1. Aggregate invariant design is excellent. Reflection enforces its lifecycle precisely: cannot submit empty, cannot respond after submission, cannot add insights before submission. All invariants throw clear StateErrors. Quest auto-completes when all missions complete. These are real DDD invariants, not just CRUD.
2. Strong separation of domain events from persistence. The pattern of aggregate.pullDomainEvents() then publishing in use cases is correct and consistent across the codebase. Events are never published directly from infrastructure.
3. Value object quality is high. Strength, JourneyVision, BehavioralEvidence, EvidenceSource are all correctly immutable with structural equality. The sealed EvidenceSource hierarchy cleanly models multiple evidence origins.
4. Domain service ports are cleanly defined. InsightExtractionService, BehavioralEvidenceAnalyzer, NarrativeThemeResolver, and PatternDetector are all abstract interfaces in the domain layer, properly separating contract from implementation.
5. Pattern rule architecture is well-structured. The PatternRule / RuleBasedPatternDetector composition is an excellent application of the Strategy pattern. Adding a new behavior pattern is a one-class operation.
6. Integration test pipeline tests are genuinely valuable. behavior_pattern_detection_pipeline_test.dart tests the full event-driven chain: Evidence → Reactor → PatternDetection → Journey update → BehaviorPatternsDetected event. These tests enforce correct wiring, not just unit behavior.
7. NarrativeThemeId cross-context reference is handled correctly. The Reflection aggregate stores only NarrativeThemeId references rather than duplicating the entity. AD-002 compliance is proper.
8. ID type safety is thorough. Every aggregate and entity has a strongly-typed ID wrapper (JourneyId, QuestId, ReflectionId, etc.) that extends StronglyTypedId. This prevents accidental cross-type ID confusion at compile time.

---

G. Recommended Changes, Prioritized by Impact

┌──────────┬──────────────────────────────────────────────────────────────────────────────────────────┬───────────┬─────────┐
│ Priority │                                          Change                                          │ Category  │ Effort  │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 1        │ Move AggregateType from life_journey domain to lib/core/eventing/                        │ AV-1 /    │ Small   │
│          │                                                                                          │ AV-6      │         │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 2        │ Remove flutter/foundation.dart from BehaviorPattern                                      │ AV-2      │ Trivial │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 3        │ Store ProviderContainer for application lifetime (or use ProviderScope)                  │ AV-5      │ Medium  │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 4        │ Wire real infrastructure implementations (not fakes) in production providers             │ AV-3      │ Small   │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 5        │ Move application/providers/ to bootstrap/ or app/di/ layer                               │ AV-4      │ Medium  │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 6        │ Add failure logging/handling to ReflectionSubmittedReactor                               │ AR-1      │ Trivial │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 7        │ Delete orphaned files: patterns/rules/base_pattern_rule.dart,                            │ CD-4 /    │ Trivial │
│          │ value_objects/behavioral_evidence_type.dart, PatternsDetected event                      │ AV-7      │         │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 8        │ Define repository contract tests for future persistence swap                             │ MP-1      │ Small   │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 9        │ Introduce aggregate version field for future optimistic concurrency                      │ AR-4      │ Small   │
├──────────┼──────────────────────────────────────────────────────────────────────────────────────────┼───────────┼─────────┤
│ 10       │ Update DRIFT-007 status and close CD-1/CD-2/CD-3 documentation                           │ CD-1–3    │ Trivial │
└──────────┴──────────────────────────────────────────────────────────────────────────────────────────┴───────────┴─────────┘

---

Overall Architecture Assessment: 6.5 / 10

What earns the score up: The domain model is genuinely DDD — real aggregates, real invariants, real domain events, proper ports. The integration tests verify end-to-end pipeline behavior. The bounded context thinking is directionally sound.

What holds it back: Two structural violations are severe enough to block scaling: the core depending on a feature domain (AggregateType in domain_event.dart) corrupts the entire layering model, and the domain depending on Flutter (BehaviorPattern) violates the stated non-negotiable principle. The ephemeral container means there is currently no runtime state persistence at the application level. And the production providers routing to fakes means the system under test is not the system users will run.

---

Top 5 Changes Before Continuing Development

1. Fix AggregateType location — move to lib/core/eventing/. Every new event in every new bounded context currently imports a Life Journey type.
2. Remove Flutter dependency from BehaviorPattern — this is a one-minute fix with large symbolic importance. A domain model that imports Flutter is a credibility problem for every future contributor.
3. Store the ProviderContainer properly — without this, the application has no persistent runtime state and every test that uses AppCompositionRoot.initialize() is testing infrastructure that is immediately thrown away.
4. Wire real infrastructure to production providers — RuleBasedInsightExtractionService exists but isn't used. FakeBehavioralEvidenceAnalyzer always returns the same hardcoded evidence. Ship a real rule-based analyzer even if it's simple; it will be used in all production data paths.
5. Add failure handling to ReflectionSubmittedReactor — the entire reflection analysis pipeline is event-driven; a silent failure here means a user submits a reflection and nothing happens, with no signal that anything went wrong. Even a print() or debugPrint() is better than the current empty catch.
