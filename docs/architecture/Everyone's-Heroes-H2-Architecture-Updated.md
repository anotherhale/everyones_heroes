# Everyone's Heroes — Phase H.2 Architecture
## Behavior Pattern Detection — Current Authoritative Architecture

**Status:** Accepted / Implemented  
**Phase:** H.2  
**Scope:** Behavioral Evidence → Behavior Patterns → Journey behavioral understanding  
**Last Updated:** 2026-08-18

---

# 1. Purpose

Phase H.2 establishes deterministic Behavior Pattern Detection as the next stage of the Adaptive Discovery & Evidence Engine.

The purpose of H.2 is to transform accumulated **Behavioral Evidence** into **Behavior Patterns** that become part of the Journey's long-term behavioral understanding.

The architecture is intentionally narrow:

```text
Reflection
    ↓
Behavioral Evidence
    ↓
Behavior Pattern Detection
    ↓
Journey Behavioral Understanding
```

H.2 does **not** attempt to implement Growth Opportunities, Discovery Profile synthesis, personalization, AI-based detection, or adaptive experiences.

Those capabilities consume the knowledge produced by H.2 in later phases.

---

# 2. Architectural North Star

Everyone's Heroes is being designed as an adaptive human-growth platform that learns how to inspire each individual.

The long-term conceptual loop is:

```text
Discovery / Experience
        ↓
Action
        ↓
Reflection
        ↓
Behavioral Evidence
        ↓
Behavior Patterns
        ↓
Deeper Personal Understanding
        ↓
Personalized Experience
        ↓
Growth
        ↓
New Experience
```

H.2 implements one specific layer of that loop:

```text
Behavioral Evidence
        ↓
Behavior Pattern Detection
        ↓
Behavioral Understanding
```

The H.2 implementation must remain useful independently of any particular future output such as missions, coaching, stories, music, or AI-generated experiences.

---

# 3. Architectural Principles

H.2 follows these principles:

1. **Evidence is stored; patterns are derived.**
2. **Behavioral Evidence is historical and immutable.**
3. **BehaviorPattern is a Value Object.**
4. **Journey owns BehaviorPatterns.**
5. **BehaviorPatternDetector is deterministic and side-effect free.**
6. **Detection rules do not modify aggregates.**
7. **Application services orchestrate; domain objects enforce domain rules.**
8. **Domain events are owned and raised by the aggregate whose state changed.**
9. **There is no BehaviorPatternRepository.**
10. **BehaviorPatterns are persisted through JourneyRepository.**
11. **H.2 does not make AI the source of behavioral truth.**
12. **Future capabilities consume H.2 output rather than changing H.2's core responsibilities.**

---

# 4. Current Domain Ownership

## 4.1 Journey

`Journey` is the aggregate root for Life Journey behavioral understanding in H.2.

The aggregate owns:

```text
Journey
├── Chapters
├── Quests
├── BehaviorPatterns
└── Domain Events
```

Behavior Patterns are therefore part of the Journey's consistency and persistence boundary.

A future `DiscoveryProfile` may synthesize or project behavioral understanding, but it does not replace Journey as the H.2 owner of BehaviorPatterns.

This is the authoritative H.2 decision.

---

# 5. Evidence vs. Understanding

The architecture deliberately distinguishes historical facts from derived interpretation.

```text
Behavioral Evidence
        ↓
      facts
        ↓
Behavior Pattern
        ↓
derived understanding
```

## Behavioral Evidence

Behavioral Evidence represents an observed behavioral fact.

Examples:

```text
Discipline
Consistency
Courage
Leadership
Recovery
Service
```

Evidence references its source and represents what was observed, not what the person "is."

Evidence is retained as the historical record.

## Behavior Pattern

A Behavior Pattern represents a recurring behavioral interpretation derived from evidence.

For example:

```text
Evidence #1  ─┐
Evidence #2  ─┼──> Consistency Pattern
Evidence #3  ─┘
```

Patterns may change as new evidence accumulates.

The evidence remains the underlying historical record.

---

# 6. Domain Model

The conceptual relationships are:

```text
Reflection
    │
    ▼
BehavioralEvidence
    │
    ▼
BehaviorPatternDetector
    │
    ├── PatternRule*
    │
    ▼
BehaviorPattern
    │
    ▼
Journey
```

## 6.1 BehaviorPattern

`BehaviorPattern` is an immutable Value Object.

It represents the current derived behavioral understanding of a specific pattern.

Value-object semantics include:

- value equality,
- immutability,
- deterministic representation,
- replacement rather than in-place mutation.

The aggregate changes behavioral understanding by replacing the relevant value object rather than mutating it.

---

## 6.2 BehaviorPatternType

`BehaviorPatternType` provides the canonical classification of patterns.

Examples may include:

- Leadership
- Consistency
- Recovery
- Service
- Resilience

The set of supported types is intentionally extensible through new rules.

---

## 6.3 Strength

`Strength` represents the normalized strength of a pattern.

Strength is deterministic and value based.

The domain owns the normalization and comparison semantics.

---

## 6.4 Supporting Evidence

Behavior Patterns retain references to the evidence supporting them, preferably through stable evidence identifiers.

This provides traceability:

```text
BehaviorPattern
    ↓
Supporting Evidence IDs
    ↓
BehavioralEvidence
    ↓
Original Evidence Source
```

This is fundamental to explainability.

---

# 7. Pattern Detection

## 7.1 Detector

`BehaviorPatternDetector` is a domain service/port that performs deterministic pattern detection.

Conceptually:

```text
List<BehavioralEvidence>
        ↓
BehaviorPatternDetector
        ↓
List<BehaviorPattern>
```

The detector:

- reads evidence,
- evaluates pattern rules,
- returns candidate patterns,
- performs no persistence,
- does not modify Journey,
- does not publish domain events.

---

# 8. Pattern Rules

Detection is decomposed into small composable rules.

```text
BehaviorPatternDetector
        │
        ├── ConsistencyPatternRule
        ├── LeadershipPatternRule
        ├── RecoveryPatternRule
        ├── ServicePatternRule
        └── ...
```

Each rule answers a focused domain question:

> Does this body of evidence support this particular behavioral pattern?

Rules must be:

- deterministic,
- side-effect free,
- independently testable,
- independent of persistence,
- independent of Flutter/UI concerns.

Adding a new pattern should normally require adding a rule rather than modifying unrelated rules.

---

# 9. Aggregate Integration

The detector proposes patterns.

The Journey decides whether its state actually changes.

```text
BehaviorPatternDetector
        ↓
Detected Patterns
        ↓
Journey.updateBehaviorPatterns()
        ↓
Compare Existing vs Detected
        ↓
State Changed?
    ├── No → no event
    └── Yes → update state + raise event
```

This distinction is critical.

The detector does not own aggregate state.

The Journey does.

---

# 10. Domain Event Ownership

Every domain event has one authoritative owner.

## BehavioralEvidenceDetected

Represents newly detected Behavioral Evidence.

The event originates from the Reflection analysis pipeline.

```text
Reflection Analysis
        ↓
BehavioralEvidenceDetected
```

## BehaviorPatternsDetected

Represents a change in the Journey's behavioral understanding.

It is raised exclusively by Journey after its BehaviorPatterns have changed.

```text
Journey.updateBehaviorPatterns()
        ↓
BehaviorPatternsDetected
```

Application services and reactors do not construct or publish this event manually.

---

# 11. Event-Driven Application Flow

The completed H.2 flow is:

```text
Reflection
    ↓
Reflection Analysis
    ↓
BehavioralEvidenceDetected
    ↓
BehavioralEvidenceDetectedReactor
    ↓
DetectBehaviorPatternsUseCase
    ↓
BehaviorPatternDetector
    ↓
Journey.updateBehaviorPatterns()
    ↓
JourneyRepository.save()
    ↓
BehaviorPatternsDetected
    ↓
Future Subscribers
```

The reactor is the application entry point for event-driven execution.

The UI does not invoke the pattern detector directly.

---

# 12. Application Layer

## DetectBehaviorPatternsUseCase

The use case coordinates the workflow:

1. Receive the relevant Journey identity.
2. Load the Journey.
3. Load the relevant Behavioral Evidence.
4. Invoke `BehaviorPatternDetector`.
5. Pass the detected patterns to `Journey.updateBehaviorPatterns()`.
6. Save the Journey through `JourneyRepository`.
7. Allow aggregate events to be published through the established eventing infrastructure.

Conceptually:

```text
DetectBehaviorPatternsUseCase
        │
        ├── JourneyRepository
        ├── BehavioralEvidenceRepository
        └── BehaviorPatternDetector
```

The use case contains orchestration, not behavioral rules.

---

# 13. Reactors

`BehavioralEvidenceDetectedReactor` translates the domain event into an application workflow.

Its responsibility is intentionally narrow:

```text
Event
  ↓
Reactor
  ↓
Use Case
```

The reactor:

- receives the event,
- extracts the necessary identifiers,
- invokes the use case.

The reactor does not:

- detect patterns,
- modify Journey directly,
- publish `BehaviorPatternsDetected`,
- own behavioral state.

---

# 14. Repository Architecture

There is no `BehaviorPatternRepository`.

Repositories exist around aggregate roots.

The authoritative persistence relationship is:

```text
JourneyRepository
        ↓
Journey
        ↓
BehaviorPatterns
```

Behavioral Evidence remains separately accessible through its established repository/port:

```text
BehavioralEvidenceRepository
        ↓
BehavioralEvidence
```

This preserves aggregate encapsulation and avoids creating a competing consistency boundary around BehaviorPattern.

---

# 15. Persistence Boundary

Behavior Patterns are persisted as part of the Journey aggregate.

Conceptually:

```text
Load Journey
     ↓
Analyze Evidence
     ↓
Update Journey
     ↓
Save Journey
```

The persistence boundary is the Journey aggregate.

A standalone pattern persistence operation is not part of the H.2 architecture.

---

# 16. Idempotency

The detection workflow should be idempotent.

Processing equivalent evidence repeatedly should not create repeated state changes or duplicate `BehaviorPatternsDetected` events.

Conceptually:

```text
Same Evidence
     ↓
Same Detected Patterns
     ↓
Journey state unchanged
     ↓
No new BehaviorPatternsDetected event
```

This supports reliable retries and future asynchronous infrastructure.

---

# 17. Determinism

Given the same input evidence, the deterministic detector should produce the same pattern results.

```text
Evidence A + B + C
        ↓
Detector
        ↓
Pattern X
```

Running the detector again with the same evidence should produce the same result.

Determinism provides:

- reproducibility,
- testability,
- explainability,
- safe retries,
- future recomputation.

---

# 18. Explainability

Every Behavior Pattern must be traceable to evidence.

```text
BehaviorPatternsDetected
        ↓
BehaviorPattern
        ↓
Supporting Evidence IDs
        ↓
Behavioral Evidence
        ↓
Evidence Source
```

This makes the behavioral understanding auditable.

The system should be able to answer:

> "Why does the platform believe this pattern exists?"

with evidence rather than an opaque model assertion.

---

# 19. AI Boundary

AI is deliberately outside the authoritative H.2 behavioral state model.

H.2 does not require AI to determine behavioral truth.

The core relationship is:

```text
Historical Evidence
        ↓
Deterministic Detection
        ↓
Behavior Patterns
```

Future AI systems may:

- augment detection,
- generate explanations,
- discover candidate rules,
- create personalized experiences,
- compose motivational content.

However, AI-generated interpretation should not silently replace the evidence-first domain model.

The architectural principle is:

> **Store observations. Derive understanding. Generate experiences.**

---

# 20. Dependency Rules

The dependency direction is:

```text
Presentation
     ↓
Application
     ↓
Domain

Infrastructure
     ↓
Application / Domain abstractions
```

The domain must not depend on:

- Flutter,
- UI frameworks,
- repositories' concrete implementations,
- database implementations,
- event bus implementations.

Framework-specific composition belongs at the appropriate outer boundary.

The application layer should depend on abstractions for repositories, detectors, and other ports.

---

# 21. Framework Boundary

Riverpod may be used by the project's dependency-composition mechanism, but the domain model must remain framework independent.

In particular:

```text
Domain
  ✗ Flutter
  ✗ Riverpod
  ✗ UI concerns
  ✗ persistence implementations
```

Provider definitions and framework-specific dependency wiring should remain outside the domain model.

The architectural intent is dependency inversion, not prohibition of a particular composition framework.

---

# 22. Package Organization

The implementation should remain aligned with the broader Life Journey feature structure.

Conceptually:

```text
lib/features/life_journey/

├── application/
│   ├── use_cases/
│   │   └── detect_behavior_patterns_use_case.dart
│   └── reactors/
│       └── behavioral_evidence_detected_reactor.dart
│
├── domain/
│   ├── aggregates/
│   │   └── journey.dart
│   ├── behavior_patterns/
│   │   ├── behavior_pattern.dart
│   │   ├── behavior_pattern_type.dart
│   │   ├── strength.dart
│   │   ├── behavior_pattern_detector.dart
│   │   ├── behavior_pattern_rule.dart
│   │   └── rules/
│   └── events/
│       └── behavior_patterns_detected.dart
│
└── infrastructure/
    ├── persistence/
    └── ...
```

The exact physical location may evolve with the repository, but the architectural boundaries above are authoritative.

---

# 23. Testing Architecture

Testing follows the same dependency direction as production code.

## Domain

Test:

- BehaviorPattern equality,
- immutability,
- Strength semantics,
- rule behavior,
- detector behavior,
- Journey state transitions,
- event generation.

## Application

Test:

- reactor invocation,
- use-case orchestration,
- repository interactions,
- detector invocation,
- aggregate persistence.

## Integration

Test:

```text
Reflection
    ↓
Behavioral Evidence
    ↓
BehavioralEvidenceDetected
    ↓
Reactor
    ↓
Use Case
    ↓
Detector
    ↓
Journey
    ↓
Repository
    ↓
BehaviorPatternsDetected
```

Important integration scenarios include:

- single reflection,
- multiple reflections,
- repeated evidence,
- no pattern change,
- new pattern,
- pattern strengthening,
- repeated event processing,
- event registration,
- persistence.

---

# 24. Architectural Decisions

## ADR-H2-001 — BehaviorPattern is a Value Object

**Status:** Accepted

BehaviorPattern is immutable and compared by value.

Behavioral understanding changes by replacing patterns rather than mutating individual instances.

---

## ADR-H2-002 — Journey Owns BehaviorPatterns

**Status:** Accepted

Journey owns BehaviorPatterns because they represent part of the Journey's accumulated behavioral understanding.

A future Discovery Profile may consume or synthesize this information but does not become the authoritative H.2 owner.

---

## ADR-H2-003 — BehaviorPatternDetector is Pure

**Status:** Accepted

The detector is deterministic, side-effect free, persistence independent, and aggregate independent.

It returns proposed patterns.

---

## ADR-H2-004 — No BehaviorPatternRepository

**Status:** Accepted

BehaviorPatterns are persisted through JourneyRepository because BehaviorPattern is not an aggregate root and has no independent lifecycle.

---

## ADR-H2-005 — Evidence is Stored; Patterns are Derived

**Status:** Accepted

Behavioral Evidence is the historical record.

Behavior Patterns are derived interpretations of that evidence.

This permits future recomputation as detection rules evolve while preserving historical fidelity.

---

# 25. Current Architecture vs. Future Architecture

H.2 should not be confused with the full future adaptive platform.

## Current H.2

```text
Reflection
    ↓
Behavioral Evidence
    ↓
Behavior Pattern Detection
    ↓
Journey Behavioral Understanding
```

## Future

```text
Behavioral Evidence
    ↓
Behavior Patterns
    ↓
Growth Opportunities
    ↓
Discovery Profile
    ↓
Personalization Engine
    ↓
Adaptive Experiences
```

Future experience types may include:

- missions,
- reflections,
- coaching,
- hero stories,
- music,
- motivational talks,
- educational experiences,
- other adaptive experiences.

These are future consumers of the behavioral understanding established by H.2.

---

# 26. Architectural Constraints for Future Work

Future changes should not:

- introduce a BehaviorPatternRepository without superseding the H.2 ADR,
- move BehaviorPattern ownership outside Journey without an explicit architectural decision,
- place Flutter dependencies in domain code,
- make detector rules mutate aggregates,
- allow application services to manufacture aggregate-owned domain events,
- replace historical Behavioral Evidence with derived patterns,
- make AI the authoritative source of behavioral truth,
- couple H.2 to a particular future experience type.

Future changes may:

- add pattern types,
- add deterministic rules,
- improve detection algorithms,
- add AI-assisted candidate detection,
- add Growth Opportunity detection,
- synthesize Discovery Profiles,
- consume `BehaviorPatternsDetected`,
- add new personalized experience generators.

---

# 27. Architecture Drift Remediation

The architecture review identified several categories of drift that should be treated separately from the H.2 domain design.

## Confirmed H.2 architectural constraints

These are authoritative:

- Journey owns BehaviorPatterns.
- No BehaviorPatternRepository.
- BehaviorPatternDetector is pure.
- Evidence is stored; patterns are derived.
- BehaviorPatternsDetected is owned by Journey.
- The application workflow is reactor-driven.

## Implementation drift to verify and correct

The following should be verified against the current source:

1. Shared Kernel code must not depend on Life Journey-specific types.
2. Domain code must not import Flutter.
3. Production dependency providers must not silently substitute fake implementations.
4. Duplicate or obsolete event types should be removed where their semantics overlap.
5. Dead or superseded types should be removed.
6. Documentation must identify H.2 as implemented rather than planned.
7. Test organization should reflect the current repository structure.

These are implementation/documentation alignment concerns, not reasons to redesign the H.2 domain model.

---

# 28. Architectural Review Position

The H.2 architecture is considered structurally sound when:

```text
Evidence
   ↓
Pure Detection
   ↓
Journey-Owned Understanding
   ↓
Aggregate-Owned Event
```

is preserved.

The primary architectural risk is **drift between this model and implementation**, not the model itself.

When implementation and documentation disagree:

1. Check the latest accepted ADR.
2. Determine whether the implementation or documentation is stale.
3. If the architectural direction has genuinely changed, create or update an ADR.
4. Synchronize the implementation and documentation.
5. Do not silently introduce a new architectural rule through implementation.

---

# 29. Definition of Done

H.2 is architecturally complete when:

### Domain

- [x] BehaviorPattern implemented.
- [x] BehaviorPatternType implemented.
- [x] Strength implemented.
- [x] Pattern rules implemented.
- [x] Detector implemented.
- [x] Journey owns BehaviorPatterns.
- [x] Journey determines whether behavioral understanding changed.

### Application

- [x] DetectBehaviorPatternsUseCase implemented.
- [x] BehavioralEvidenceDetectedReactor implemented.
- [x] Repository orchestration implemented.
- [x] Detector invoked through the application workflow.

### Events

- [x] BehavioralEvidenceDetected drives the workflow.
- [x] BehaviorPatternsDetected is owned by Journey.
- [x] No application service manually publishes the aggregate-owned event.

### Persistence

- [x] BehaviorPatterns persist through JourneyRepository.
- [x] No BehaviorPatternRepository exists.

### Testing

- [x] Domain behavior tested.
- [x] Pattern rules tested.
- [x] Detector tested.
- [x] Journey behavior tested.
- [x] Application orchestration tested.
- [x] Event-driven integration tested.

### Architecture

- [x] Evidence remains the historical record.
- [x] Patterns remain derived understanding.
- [x] Detector remains deterministic and side-effect free.
- [x] Aggregate ownership remains explicit.
- [x] Dependency direction remains inward.
- [ ] Known implementation/documentation drift is remediated.

---

# 30. Final H.2 Model

The authoritative H.2 architecture can be summarized as:

```text
                    REFLECTION
                        │
                        ▼
              BEHAVIORAL EVIDENCE
                        │
                        │ BehavioralEvidenceDetected
                        ▼
       BehavioralEvidenceDetectedReactor
                        │
                        ▼
        DetectBehaviorPatternsUseCase
                        │
                        ▼
          BehaviorPatternDetector
                        │
                        ▼
                BehaviorPatterns
                        │
                        ▼
                     JOURNEY
                        │
              owns behavioral
                 understanding
                        │
                        │ state changed
                        ▼
          BehaviorPatternsDetected
                        │
                        ▼
              FUTURE CAPABILITIES
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
      Growth        Discovery    Personalization
   Opportunities     Profile         Engine
```

The enduring architectural separation is:

```text
FACTS
  ↓
Behavioral Evidence

UNDERSTANDING
  ↓
Behavior Patterns

FUTURE GUIDANCE
  ↓
Growth Opportunities / Discovery / Personalization

EXPERIENCE
  ↓
Missions / Coaching / Stories / Music / Other Experiences
```

H.2 owns the first two layers of behavioral understanding and establishes the event boundary through which future capabilities can evolve without coupling themselves to the implementation of pattern detection.
