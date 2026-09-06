# Everyone's Heroes — UI.3 Adaptive Experience Foundation

**Status:** Anchor Document  
**Phase:** UI.3 — Adaptive Experience Foundation  
**Version:** 1.0

## 1. Purpose

UI.3 follows UI.1 (UI Prototype) and UI.2 (Application Integration).

UI.1 established the intended experience, navigation, and presentation boundary. UI.2 connected that experience to the real application/domain workflow, including Reflection submission and behavioral understanding.

UI.3 establishes the next architectural capability:

> **What the platform learns about an individual can begin to influence what the individual experiences next.**

UI.3 is intentionally a foundation, not a complete Personalization Engine.

The central question is:

> **Can Everyone's Heroes use its current understanding of a person to provide a more relevant next experience?**

## 2. Product North Star

Everyone's Heroes is an adaptive human growth platform that continuously learns how to inspire each individual.

The long-term loop is:

```text
Experience
    ↓
Action
    ↓
Reflection
    ↓
Understanding
    ↓
Personalization
    ↓
Growth
    ↓
New Experience
```

UI.3 begins implementing the feedback relationship between understanding and the next experience.

The user should experience this as a natural continuation of their personal journey, not as a recommendation system.

## 3. Relationship to UI.1 and UI.2

### UI.1 — Prototype

UI.1 answered:

> **What does it feel like to use Everyone's Heroes as a companion for personal growth?**

It established Home, Journey, Discover, Reflect, Understanding, Today's Experience, navigation, user-facing terminology, and the UI/domain boundary.

### UI.2 — Application Integration

UI.2 answered:

> **Can the UI exercise the actual product architecture?**

It established the real flow:

```text
Reflection
    ↓
Application
    ↓
Behavioral Evidence
    ↓
Behavior Pattern Detection
    ↓
Journey / Understanding
    ↓
UI refresh
```

UI.2 explicitly deferred Growth Opportunity Detection, Discovery Profile synthesis, Personalization Engine, AI-generated experiences, adaptive coaching, recommendation algorithms, and production backend capabilities.

### UI.3 — Adaptive Experience Foundation

UI.3 answers:

> **Can current understanding influence the next experience without prematurely implementing the full Personalization Engine?**

## 4. Architectural Context

The long-term Adaptive Discovery & Evidence Engine is layered:

```text
Discovery Activities
        ↓
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

Each stage adds abstraction while preserving earlier outputs.

The architecture is evidence-first:

```text
Store
  ↓
Observe
  ↓
Understand
  ↓
Inspire
```

Behavior Pattern Detection produces understanding. Personalization eventually transforms understanding into experiences.

UI.3 establishes the seam between those concerns.

## 5. Architectural Objective

The dependency direction remains:

```text
Presentation / UI
       ↓
Application
       ↓
Domain
       ↓
Infrastructure
```

The intended interaction is:

```text
Home / Experience UI
        ↓
Application-facing Experience Selection
        ↓
Current Domain Understanding
        ↓
Experience Selection
        ↓
Presentation Model
        ↓
Adaptive Experience UI
```

The UI must not determine the experience, inspect evidence to invent recommendations, invoke detectors directly, or contain personalization business rules.

## 6. Fundamental UI Principle

> **The user experiences transformation; the architecture records understanding.**

User-facing concepts include Experience, Action, Reflection, Discovery, Journey, Encouragement, Growth, and What We're Learning.

Internal concepts include Behavioral Evidence, Behavior Patterns, Aggregates, Entities, Value Objects, Domain Events, Repositories, Application Use Cases, Reactors, and Providers.

For example, avoid exposing:

```text
BehaviorPattern
Strength: 0.82
ObservationCount: 7
```

as the primary experience.

Prefer:

```text
You've been showing a strong tendency
to follow through, even when things
become difficult.
```

## 7. User Experience Principles

### Personal

The experience should feel relevant without pretending the system knows more than it does.

### Encouraging

Avoid judgmental language, competitive scoring, shame, or language implying that a behavior defines the person's identity.

### Narrative

The UI should communicate:

- where the user has been
- where they are
- what they have learned
- what they are working toward
- what comes next

### Progressive

Do not expose the entire adaptive architecture.

### Human

| Internal Concept | User-Facing Concept |
|---|---|
| Behavioral Evidence | What happened / What you demonstrated |
| Behavior Pattern | Something we're noticing |
| Growth Opportunity | An opportunity / A next step |
| Discovery Profile | What we're learning about you |
| Personalization Engine | Not exposed |
| Adaptive Experience | Today's Experience / Your next experience |

### Explainable

When useful, the UI should communicate why an experience is relevant.

Example:

```text
We've noticed you've been building consistency.

Today's experience is a small step
toward strengthening that habit.
```

Explanations must remain grounded in available information.

## 8. Core UI.3 Experience Model

```text
Current Understanding
        ↓
Experience Selection
        ↓
Today's Experience
        ↓
Action
        ↓
Reflection
        ↓
Behavioral Evidence
        ↓
Behavior Pattern
        ↓
Updated Understanding
        ↓
Next Experience
```

UI.3 does not need AI, statistical optimization, or a production recommendation algorithm.

It needs to demonstrate that current understanding can affect the next experience through a clean application boundary.

## 9. Scope

UI.3 includes:

1. An application-facing concept for selecting an experience.
2. A deterministic initial experience-selection strategy.
3. A presentation model for Today's Experience.
4. Home integration.
5. A grounded explanation of relevance where appropriate.
6. A path from experience into an existing action/reflection flow.
7. Preservation of the existing Reflection → Evidence → Pattern pipeline.
8. Journey/Understanding refresh after reflection.
9. Riverpod integration.
10. Loading, success, empty, and failure states.
11. Tests for the adaptive experience flow.
12. Architecture validation.

## 10. Non-Goals

UI.3 does **not** implement:

- Production Personalization Engine
- Growth Opportunity Detection
- Complete Discovery Profile synthesis
- AI-generated experiences
- AI coaching
- AI-generated Hero Stories
- Personalized music generation
- Recommendation optimization
- Machine-learning ranking
- Production backend/network services
- Authentication
- Subscription/payment flows
- Marketplace
- Social/community features
- Push notification infrastructure
- Final branding
- Complete production design system
- Advanced animation
- Production accessibility certification

## 11. Experience Abstraction

UI.3 should establish an application-facing representation of an adaptive experience.

Conceptually:

```text
Adaptive Experience
├── identity
├── type
├── title
├── description
├── action
├── rationale
└── source/context
```

The UI should not know how the experience was selected.

Today:

```text
DeterministicExperienceSelector
```

Later:

```text
PersonalizationEngine
```

The presentation layer should not need to change merely because the selection strategy changes.

## 12. Experience Types

A minimal taxonomy should be established rather than designing the complete future catalog.

Potential types include:

```text
Mission
Reflection
Story
Coaching
Discovery
```

UI.3 does not require production implementations for all types.

The important property is:

> **New experience types should not require changes to the core behavioral-understanding model.**

The domain glossary defines Adaptive Experience broadly as any personalized experience generated for an individual, including missions, hero stories, motivational talks, personalized music, dynamic lyrics, coaching, and future experiences.

## 13. Deterministic Experience Selection

The initial selector should be deterministic to provide:

- explainability
- repeatability
- testability
- predictable behavior
- a stable seam for future personalization

Conceptually:

```text
Behavior Pattern
       ↓
Selection Rule
       ↓
Adaptive Experience
```

Possible examples:

```text
Consistency
    ↓
A slightly more challenging follow-through experience

Avoidance
    ↓
A small, manageable step toward a difficult task

Leadership
    ↓
An experience involving helping or mentoring someone

No meaningful pattern
    ↓
A discovery or reflection experience
```

These are examples, not mandatory product decisions.

Only information actually available in the current domain model may be used.

## 14. Understanding vs Recommendation

Behavior Pattern Detection remains responsible for understanding recurring behavior.

It must not become the recommendation engine.

```text
Behavior Pattern
    ↓
"What is consistently happening?"
```

versus:

```text
Experience Selection
    ↓
"What experience should we offer next?"
```

Growth Opportunity Detection is the future layer responsible for identifying meaningful development opportunities.

UI.3 must not hide Growth Opportunity logic inside Behavior Pattern Detection.

## 15. Application Boundary

The UI should depend on an application-facing abstraction.

Conceptually:

```text
Presentation
      ↓
Experience Provider
      ↓
Experience Selection Application Service
      ↓
Experience Selection Port
      ↓
Current Understanding
```

A conceptual contract may resemble:

```text
selectFor(context) → AdaptiveExperience
```

Exact names and APIs should follow repository conventions.

Requirements:

- Presentation does not know selection rules.
- Presentation does not inspect repositories.
- Presentation does not invoke detectors.
- Presentation does not construct domain events.
- The selector is independently testable.
- The selector is replaceable.
- A future Personalization Engine can fit behind the same boundary.

## 16. Presentation Models

Domain objects should not become the UI's primary state representation.

Conceptually:

```text
Domain
Journey
BehaviorPattern
Reflection
BehavioralEvidence

        ↓

Presentation
JourneyViewModel
PatternInsightViewModel
ReflectionState
TodayExperienceViewModel
```

Today's Experience should expose only what the screen needs, such as:

```text
title
description
callToAction
rationale
experienceType
state
```

The UI should not need `BehaviorPattern`, `Strength`, `EvidenceStatistics`, or `DomainEvent` to render the experience.

## 17. Home / Today

Home becomes the primary adaptive surface.

It should answer:

> **What should I do right now?**

Conceptual example:

```text
Good morning.

You don't have to change everything today.
Just take the next step.

────────────────────────────────

TODAY'S EXPERIENCE

Keep Showing Up

You've been building consistency
across your recent journey.

Take one small step today
to strengthen that habit.

[ Begin Experience ]

────────────────────────────────

YOUR JOURNEY

You're making progress.

[ Continue Journey ]

────────────────────────────────

WHAT WE'RE LEARNING

You're becoming someone
who follows through.

[ See What We're Learning ]
```

Content is illustrative; implementation should use actual application state where available.

## 18. Experience Detail

Selecting Today's Experience should lead to an experience-oriented screen or flow.

Conceptually:

```text
KEEP SHOWING UP

You've been building consistency.

Today's step:

Choose one thing you've been
putting off and spend 15 minutes
moving it forward.

[ Begin ]

────────────────────────────────

Why this?

You've demonstrated a tendency
to follow through when you commit
to a specific action.
```

The explanation is optional when insufficient information exists.

The system should prefer honest uncertainty over invented personalization.

## 19. Action Completion

UI.3 establishes:

```text
Experience
    ↓
Action
    ↓
Reflection
```

The first implementation may reuse the existing Journey/Mission model.

Application orchestration remains outside the UI.

## 20. Reflection Integration

UI.3 reuses the UI.2 Reflection integration.

```text
Today's Experience
        ↓
Action
        ↓
Reflect
        ↓
Submit Reflection
        ↓
Existing Application Workflow
        ↓
Behavioral Evidence
        ↓
Behavior Pattern Detection
        ↓
Journey / Understanding Updated
```

UI.3 must not duplicate the H.2 analysis pipeline.

## 21. Updated Experience

After reflection, the application should be able to request the next experience again.

```text
Before Reflection
        ↓
Experience A

Reflection
        ↓
New Evidence
        ↓
New Pattern State
        ↓
Experience Selection

        ↓

After Reflection
        ↓
Experience B
```

Experience B may remain the same if understanding has not materially changed.

The system must not manufacture adaptation merely to appear adaptive.

## 22. Journey Integration

Journey remains the user's narrative representation.

UI.3 may surface:

- current chapter
- current quest/mission
- completed experiences
- completed reflections
- detected behavior patterns
- progress
- next step

Prefer:

```text
You've kept showing up.

Three recent experiences
have reinforced that pattern.

Your next step is a little harder.
```

over raw metrics unless detailed metrics become an intentional product feature.

## 23. Understanding Integration

Understanding continues to answer:

> **What are we learning about you?**

UI.3 may connect understanding to the next step:

```text
WHAT WE'RE LEARNING

You're becoming more consistent.

That is why we're encouraging
you to take a slightly bigger step.
```

This connects:

```text
Understanding
      ↓
Next Step
```

without exposing the Personalization Engine.

## 24. Discovery Integration

UI.3 preserves the UI.1 Discovery experience.

A complete Discovery Profile remains outside scope.

Do not create a fake Discovery Profile merely to make adaptation appear more sophisticated.

## 25. State Management

Riverpod remains the presentation/application state mechanism.

Conceptually:

```text
Widget
  ↓
Riverpod Provider
  ↓
Application Service / Use Case
  ↓
Domain / Selection
```

Riverpod must not become:

- a repository
- a business-rule engine
- a detector
- a hidden personalization engine
- a second domain model

## 26. Experience State

At minimum:

```text
Loading
Success
Empty / No Experience
Failure
```

An empty state is distinct from an error.

Example:

```text
Nothing is ready for you yet.

Take a moment to reflect on your journey,
and we'll have something to build from.
```

Errors should not expose internal exception details.

## 27. Mock Data Policy

UI.3 should minimize mocks.

Where a real application capability exists, use it.

Where a capability does not exist, a mock must be:

- isolated
- explicitly named
- replaceable
- injected through an abstraction
- outside widgets
- covered by tests

Preferred:

```text
Widget
  ↓
Provider
  ↓
Application-facing abstraction
  ↓
Deterministic/mock adapter
```

Avoid hard-coded behavioral state and recommendations inside widgets.

## 28. Event-Driven Architecture

The H.2 pipeline remains authoritative:

```text
Reflection
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
BehaviorPatternsDetected
```

UI.3 consumes resulting application state.

The UI should not subscribe directly to infrastructure-specific EventBus implementations merely to make widgets reactive.

Riverpod providers may be invalidated or refreshed in response to application-level state changes where appropriate.

## 29. Future Event Flow

The long-term architecture is expected to evolve toward:

```text
BehaviorPatternsDetected
        ↓
GrowthOpportunitiesDetected
        ↓
DiscoveryProfileUpdated
        ↓
PersonalizationUpdated
        ↓
AdaptiveExperienceGenerated
```

UI.3 does not implement this chain.

It establishes the seam for a future Personalization Engine.

## 30. Future Personalization Boundary

The future Personalization Engine may consume:

```text
Discovery Profile
Behavior Patterns
Growth Opportunities
Narrative Themes
Influences
Current Journey
Historical Progress
```

and produce:

```text
Missions
Reflection Prompts
Hero Stories
Motivational Talks
Personalized Music
Coaching
```

UI.3 must not require Home to know which system produced the experience.

Desired evolution:

```text
Home
  ↓
Today's Experience
  ↓
Application-facing contract
  ↓
Current selector

Later:

Home
  ↓
Today's Experience
  ↓
Same application-facing contract
  ↓
Personalization Engine
```

## 31. Architecture Rules

UI.3 must not:

- manipulate aggregates from widgets
- access repositories directly from widgets
- invoke behavioral detectors from presentation
- construct domain events
- duplicate application orchestration
- embed selection rules in widgets
- use Riverpod as a domain service
- expose internal domain models as primary UI state
- create hidden Growth Opportunity logic inside Behavior Pattern Detection
- make unsupported claims about why an experience was selected

UI.3 must:

- use application abstractions
- keep domain ownership unchanged
- keep H.2 behavior stable
- preserve event-driven boundaries
- make experience selection deterministic and testable
- keep selection replaceable
- separate presentation models from domain objects
- preserve human-readable UX

## 32. Proposed Implementation Structure

Follow current repository conventions. Conceptually:

```text
features/
└── life_journey/
    ├── application/
    │   ├── services/
    │   │   └── experience_selection_service.dart
    │   └── use_cases/
    │       └── get_today_experience_use_case.dart
    │
    ├── domain/
    │   └── ...
    │
    └── presentation/
        ├── models/
        │   └── today_experience_view_model.dart
        ├── providers/
        │   └── today_experience_provider.dart
        └── screens/
            ├── home_screen.dart
            └── experience_screen.dart
```

This is conceptual, not a mandate to create every file.

Avoid abstractions that do not solve a real dependency problem.

## 33. Testing Strategy

### Experience Selection

Verify:

- no relevant understanding produces the default experience
- supported behavior patterns produce expected experiences
- unsupported/incomplete state does not fail
- rationale is grounded in available information
- identical inputs produce deterministic results

### Application

Verify:

```text
Application Request
        ↓
Experience Selection
        ↓
Application Response
```

without requiring Flutter widgets.

### Presentation

Verify:

- loading
- success
- empty
- failure
- CTA interaction
- navigation
- rationale rendering when available
- human-readable mapping

### Integration

Verify:

```text
Launch
  ↓
Home
  ↓
Today's Experience
  ↓
Begin
  ↓
Reflect
  ↓
Submit Reflection
  ↓
Existing H.2 Processing
  ↓
Journey / Understanding Updated
  ↓
Experience State Refresh
```

### Regression

All H.2, UI.1, and UI.2 tests must continue to pass.

## 34. Architecture Validation

Verify:

### Dependency Direction

```text
Presentation
     ↓
Application
     ↓
Domain
     ↓
Infrastructure
```

### No Presentation Leakage

Confirm:

- widgets do not manipulate aggregates
- widgets do not access repositories
- widgets do not invoke detectors
- widgets do not construct domain events
- widgets do not contain selection rules

### Application Boundary

Confirm:

- experience selection occurs outside presentation
- selection is independently testable
- selector is replaceable
- future Personalization Engine can fit behind the boundary

### Domain Stability

Confirm:

- H.2 behavioral evidence remains authoritative
- Behavior Pattern ownership remains unchanged
- Journey ownership remains unchanged
- existing domain events remain valid
- no UI concern leaks into the domain model

## 35. Product Judgment

A successful experience should make the user feel:

> **"This was chosen for me because of where I am in my journey."**

Not:

> **"An algorithm scored me and assigned me an activity."**

The platform should use understanding to inspire, not judge.

## 36. Definition of Done

### Product Experience

- [ ] Home presents an application-backed Today's Experience where available.
- [ ] User can open the selected experience.
- [ ] User can begin the experience.
- [ ] Experience can lead into the existing Reflection flow.
- [ ] Reflection submission uses the real application workflow.
- [ ] Behavioral understanding remains visible through Journey/Understanding.
- [ ] Experience state refreshes after relevant changes.
- [ ] Experience feels personal without unsupported claims.
- [ ] Experience feels encouraging rather than evaluative.
- [ ] UI remains human-readable.

### Architecture

- [ ] Experience selection occurs behind an application-facing abstraction.
- [ ] Presentation contains no experience-selection business rules.
- [ ] Presentation does not manipulate aggregates.
- [ ] Presentation does not access repositories directly.
- [ ] Presentation does not invoke detectors.
- [ ] Presentation does not construct domain events.
- [ ] Riverpod remains composition/state management.
- [ ] H.2 ownership and event rules remain unchanged.
- [ ] Deterministic selector is replaceable.
- [ ] Future Personalization Engine can be introduced without redesigning Home.

### State

- [ ] Loading state is represented.
- [ ] Success state is represented.
- [ ] Empty/unavailable state is represented.
- [ ] Failure state is represented.
- [ ] UI refreshes after relevant application state changes.

### Testing

- [ ] Experience selection unit tests pass.
- [ ] Application-layer tests pass.
- [ ] Presentation tests pass.
- [ ] UI interaction tests pass.
- [ ] Reflection-to-understanding integration remains covered.
- [ ] Existing H.2 tests pass.
- [ ] Existing UI.1 tests pass.
- [ ] Existing UI.2 tests pass.
- [ ] `dart analyze` passes.
- [ ] Full Flutter test suite passes.

### Architecture Review

- [ ] No new architecture drift is introduced.
- [ ] Remaining mocks are isolated and replaceable.
- [ ] New abstractions have clear responsibilities.
- [ ] No future capability has been prematurely pulled into UI.3.

### Product Review

- [ ] User understands what to do next.
- [ ] User can understand why an experience may be relevant when an explanation is available.
- [ ] Experience feels part of the user's journey.
- [ ] System feels adaptive without exposing implementation details.
- [ ] Experience does not feel like a generic recommendation feed.

## 37. Implementation Sequence

```text
1. Review UI.2 implementation
        ↓
2. Identify current Home / Today data flow
        ↓
3. Define Adaptive Experience presentation model
        ↓
4. Define application-facing experience selection boundary
        ↓
5. Implement deterministic selector
        ↓
6. Add selector unit tests
        ↓
7. Add application use case/service
        ↓
8. Add Riverpod provider
        ↓
9. Connect Home / Today
        ↓
10. Add experience detail/action flow
        ↓
11. Reuse existing Reflection workflow
        ↓
12. Verify H.2 processing remains intact
        ↓
13. Refresh Journey / Understanding
        ↓
14. Verify next experience selection
        ↓
15. Add presentation and integration tests
        ↓
16. Run full validation
        ↓
17. Architecture review
        ↓
18. Product review
```

Implementation should proceed in small vertical slices.

Do not build a generalized Personalization Engine before the first adaptive experience works end-to-end.

## 38. Incremental Vertical Slices

### Slice 1

```text
Existing Behavior Pattern
        ↓
Deterministic Selection Rule
        ↓
Today's Experience
        ↓
Home
```

### Slice 2

```text
Today's Experience
        ↓
Action
        ↓
Reflection
```

### Slice 3

```text
Reflection
        ↓
Behavioral Evidence
        ↓
Behavior Pattern
        ↓
Updated Understanding
```

### Slice 4

```text
Updated Understanding
        ↓
New Experience Selection
        ↓
Updated Today's Experience
```

Slice 4 is the critical proof of UI.3.

## 39. Explicitly Deferred Decisions

The following remain intentionally deferred:

- Growth Opportunity Detection
- full Discovery Profile synthesis
- LifeJourney expansion
- production Personalization Engine
- AI personalization
- recommendation algorithms
- machine-learning ranking
- AI-generated missions
- adaptive coaching
- generated Hero Stories
- personalized music
- dynamic lyrics
- production backend
- authentication
- subscriptions
- marketplace
- social/community features
- notification infrastructure
- final visual design system
- final branding
- advanced animation
- complete responsive design strategy
- production accessibility certification

UI.3 should create the architectural seam that allows these capabilities to arrive later without destabilizing the foundation.

## 40. Architectural Success Criteria

UI.3 succeeds when this statement is demonstrably true:

> **The system can use current understanding to select a meaningful next experience through the application layer, and the UI can present that experience without knowing how the selection was made.**

The proof should include:

```text
Behavior Pattern
      ↓
Experience Selection
      ↓
Today's Experience
      ↓
User Action
      ↓
Reflection
      ↓
Behavioral Evidence
      ↓
Updated Behavior Pattern
      ↓
Experience Selection
```

The implementation does not need to be intelligent.

It needs to be:

- architecturally correct
- deterministic
- testable
- explainable
- replaceable

## 41. Long-Term Evolution

UI.3 establishes the foundation for the eventual adaptive platform:

```text
UI.3
Deterministic Experience Selection
        ↓
Growth Opportunity Detection
        ↓
Discovery Profile
        ↓
Personalization Engine
        ↓
AI-Assisted Personalization
        ↓
Multiple Adaptive Experience Types
```

Each stage should consume the outputs of the previous stage rather than rewriting them.

The foundational progression remains:

```text
Facts
  ↓
Understanding
  ↓
Opportunity
  ↓
Identity
  ↓
Guidance
  ↓
Experience
  ↓
Growth
```

## 42. Anchor Statement

All UI.3 implementation decisions should be evaluated against this statement:

> **Everyone's Heroes should understand enough about a person to offer a meaningful next step, while remaining honest about what it actually knows.**

UI.3 is complete when that principle is demonstrated through a real, application-backed vertical slice.

**The UI should not merely look adaptive. The architecture must make adaptation possible without compromising the boundaries established by H.2, UI.1, and UI.2.**
