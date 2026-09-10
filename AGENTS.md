Everyone’s Heroes — AGENTS.md

1. Purpose

This file is the persistent implementation contract for AI coding agents working in the Everyone’s Heroes repository.

Everyone’s Heroes (EH) is an adaptive human growth platform that continuously learns how to inspire each individual.

Core product loop:

Experience → Action → Reflection → Understanding → Personalization → Growth → New Experience

Core architectural principle:

> The user experiences transformation; the architecture records understanding.

Agents must preserve the domain model, bounded-context boundaries, dependency direction, event-driven workflows, explainability, and incremental development discipline described here and in the project’s current architecture artifacts.

────────

2. Source-of-Truth Hierarchy

Architecture documentation is valuable, but some documents describe historical states.

When determining intended architecture, use this order:

1. Explicit current Architectural Decision Records (ADRs) or other current architectural decisions.
2. Current implementation when an architectural decision has clearly already been implemented.
3. Current active phase documentation.
4. Current architecture maps and inventories.
5. Completed-phase / historical documentation.
6. Legacy agent instructions such as obsolete CLAUDE.md guidance.

Conflict rule

When code and architecture documentation disagree:

> Determine whether the code represents an intentional completed architectural change or architectural drift. Do not assume either one is correct without evidence.

Do not:

• rewrite working code merely to match a stale map;
• rewrite architecture documentation merely to match accidental implementation drift;
• silently resolve an architectural conflict by choosing whichever representation is easiest.

If the conflict materially affects the requested work, stop and report it.

Stale documentation rule

If implementation reveals that an architecture document is stale:

• report the discrepancy;
• do not automatically rewrite unrelated architecture documents;
• update documentation only when it is in scope or necessary to make the requested implementation unambiguous.

────────

3. Current Project State

Completed foundations

The project has established:

• Shared Kernel and eventing foundations.
• Life Journey domain foundations.
• H.2 behavioral understanding pipeline.
• UI.1 prototype specification.
• UI.2 application-backed UI foundation.
• UI.3 Adaptive Experience Foundation.

UI.3 completion

UI.3 is complete and closed.

Validation at closure:

• dart analyze clean.
• 25/25 focused UI.3 tests passing.
• 522/522 full Flutter tests passing.
• Slice 4 demonstrated that updated understanding leads to a refreshed Today’s Experience.

UI.3 established deterministic experience selection as a foundation, not a complete personalization engine.

H.2 behavioral understanding

Current conceptual pipeline:

Reflection → Reflection Analysis → BehavioralEvidenceDetected → BehavioralEvidenceDetectedReactor → DetectPatternUseCase → PatternDetector → Journey.updateBehaviorPatterns() → BehaviorPatternsDetected

The behavioral model includes:

• BehavioralEvidence
• EvidenceStatistics
• BehaviorPattern
• PatternRule
• RuleBasedPatternDetector
• ConsistencyPatternRule
• Strength

Important:

• Behavioral evidence precedes interpretation.
• Patterns emerge from evidence.
• Journey owns behavior patterns.
• There is no BehaviorPatternRepository.
• Historical behavioral evidence is retrieved through its appropriate repository.
• Pattern detection is deterministic and replaceable.

────────

4. Architecture Conflict Protocol

Before changing code when a conflict is discovered:

1. Identify the conflicting artifacts.
2. Determine which artifact is current.
3. Determine whether implementation reflects an intentional architectural change.
4. Determine whether the discrepancy is relevant to the requested work.
5. If irrelevant, report it and leave it alone.
6. If it blocks safe implementation, stop for a decision.
7. Never perform broad cleanup simply because a discrepancy was discovered.

Classify discrepancies as:

A. Intentional implementation change

The code intentionally implements a newer architectural decision.

Action: Treat implementation as current and update documentation only when appropriate.

B. Architectural drift

Implementation violates an established current architectural decision.

Action: Report it. Fix only if in scope or blocking.

C. Documentation drift

Implementation is correct, but documentation describes an older state.

Action: Report it. Do not automatically rewrite unrelated documentation.

D. Ambiguous

There is insufficient evidence to determine intent.

Action: Do not guess. Ask for a decision if the ambiguity affects implementation.

────────

5. Current Development Authorization: HS.1

HS.1 — Hero & Story Platform Foundation

Status: Authorized next development phase.

HS.1 is no longer merely a future concept. It is the next architectural development phase.

HS.1 establishes the domain and architectural foundation required for later Hero & Story capabilities.

Authorization does not authorize premature implementation of:

• production AI;
• personalized AI coaching;
• production semantic search;
• social/community systems;
• marketplace;
• production backend infrastructure;
• engagement optimization;
• full personalization engine;
• unrestricted feed behavior.

────────

6. Bounded Contexts

Intended conceptual separation:

```text
Identity
     │
     ├──────────────┐
     │              │
     ▼              ▼
Discovery      Hero & Story
     │              │
     │              │
     └──────┬───────┘
            ▼
       Life Journey
            │
            ▼
       Contribution
```

Currently implemented:

• Life Journey.
• Discovery foundation.
• Shared Kernel.
• Eventing infrastructure.

Hero & Story is the context being established through HS.1.

Identity and Contribution boundaries are not yet fully implemented.

Do not invent additional bounded contexts without architectural justification.

────────

7. Dependency Direction

Intended direction:

```text
Presentation/UI
      ↓
Application
      ↓
Domain
      ↑
Infrastructure
```

• Presentation depends on application-facing contracts and presentation models.
• Application depends on domain and ports/contracts.
• Domain must remain independent of Flutter, Riverpod, infrastructure adapters, databases, REST clients, and AI SDKs.
• Infrastructure implements appropriate ports.
• AI providers and external services are implementation details.

Domain code must not import:

• Flutter;
• Riverpod;
• infrastructure implementations;
• AI SDKs;
• HTTP clients;
• database implementations;
• UI-specific types.

────────

8. DDD Rules

Aggregates

Aggregates define transactional consistency boundaries.

Do not create repositories merely because a noun exists.

Do not create giant aggregates simply because objects are conceptually related.

Aggregates should protect meaningful invariants.

Aggregates should not directly mutate other aggregates.

Cross-aggregate workflows should be coordinated by application use cases and/or domain events.

Value Objects

Prefer immutable value objects for domain concepts with validation or semantic meaning.

Domain Services

Use domain services for domain behavior that does not naturally belong to one aggregate/entity.

Do not use services as dumping grounds for application orchestration.

Repositories

Repositories represent persistence boundaries appropriate to aggregates or explicit domain persistence needs.

Do not introduce a repository solely because an entity, DTO, or value object exists.

────────

9. Event-Driven Architecture

Events represent facts that have already happened.

Prefer past-tense names:

• ReflectionSubmitted
• BehavioralEvidenceDetected
• BehaviorPatternsDetected
• StoryPublished

Current event flow:

```text
Aggregate.raise(...)
        ↓
UseCase.pullDomainEvents()
        ↓
EventBus.publish(...)
        ↓
EventStore.append(...)
        ↓
EventDispatcher.dispatch(...)
        ↓
DomainEventReactor
```

UI must not:

• construct domain events;
• publish domain events directly;
• invoke reactors;
• bypass application workflows.

Create an event only when the fact is meaningful and potentially useful to other components.

────────

10. H.2 Behavioral Understanding Boundary

```text
Reflection
   ↓
Reflection Analysis
   ↓
Behavioral Evidence
   ↓
Pattern Detection
   ↓
Behavior Pattern
   ↓
Experience Selection
```

Keep these concepts distinct:

• Evidence = observed/recorded fact.
• Signal = derived indication.
• Pattern = recurring meaningful structure.
• Guidance = response/opportunity.
• Experience = user-facing opportunity.

Never collapse them.

────────

11. UI.3 Adaptive Experience Boundary

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

Experience selection is behind an application-facing abstraction and currently uses deterministic selection.

UI must not:

• manipulate aggregates;
• access repositories directly when application abstractions exist;
• invoke pattern detectors;
• construct domain events;
• duplicate application orchestration;
• embed selection rules;
• use Riverpod as a domain service;
• unnecessarily expose internal domain models.

────────

12. Hero & Story Bounded Context

Hero & Story owns:

• Heroes.
• Hero profiles.
• Stories.
• Story representations.
• Story media references.
• Story classification.
• Story content suitability.
• Story provenance.
• Story catalog.
• Hero/Story relationships.

Hero & Story does not own:

• Behavioral Evidence.
• Behavior Patterns.
• Growth Opportunities.
• Discovery Profiles.
• Personalization decisions.
• Life Journey progression.

Cross-context relationships should use stable identifiers/contracts rather than importing another bounded context’s aggregate internals.

────────

13. Hero

A Hero represents a person whose lived experience may become meaningful to others.

Potential Hero concepts:

• HeroId
• profile;
• experience areas;
• professional/lived experience;
• achievements;
• service;
• languages;
• visibility;
• areas they are willing to discuss;
• profile media.

Prefer factual profile claims over psychological claims.

Do not infer sensitive personal identity from story content.

────────

14. Story Is the Canonical Narrative

A Story is a first-class domain concept.

A Story is not simply an audio file, video, transcript, or generated script.

Conceptual model:

```text
Story
├── StoryId
├── HeroId
├── Narrative
├── Classification
├── Content Suitability
├── Representations
├── Media References
├── Provenance
├── Visibility
└── Lifecycle
```

A story may have multiple representations:

• original audio;
• transcript;
• edited transcript;
• written narrative;
• script;
• video;
• translation;
• short form;
• long form;
• narrated audio.

The underlying Story remains singular.

────────

15. AI and Story Ownership

AI may assist with:

• transcription;
• organization;
• summarization;
• extraction;
• categorization;
• script generation;
• translation;
• editing;
• alternate formats.

AI must not silently manufacture:

• experiences;
• facts;
• achievements;
• lessons;
• beliefs;
• quotations;
• motivations.

Core rule:

> AI may help tell the story. It does not own the story.

Source-of-truth workflow:

```text
Original Recording
      ↓
Transcript
      ↓
Edited Transcript
      ↓
Story Draft
      ↓
Approved Story
      ↓
Translation / Other Representations
      ↓
Published Representation
```

AI-generated artifacts are non-authoritative until reviewed/approved according to lifecycle rules.

────────

16. Multilingual Support Is Foundational

Multiple languages are supported from the beginning.

The model should distinguish:

• original story language;
• representation language;
• available languages;
• translation provenance.

Example:

```text
Spanish Original
      ↓
Spanish Transcript
      ↓
English Translation
      ↓
English Audio
```

Preserve provenance through transformations.

Do not reduce a multilingual Story to a single language field.

────────

17. Multidimensional Story Catalog

Story classification is multidimensional.

Do not reduce the catalog to an unstructured tags[] collection.

Potential dimensions:

Subject

Military, First Responder, Parenting, Family, Career, Education, Leadership, Relationships, Entrepreneurship, Service, Sports, Arts, Aging, Starting Over.

Challenge

Fear, Failure, Loss, Grief, Change, Uncertainty, Conflict, Injury, Addiction, Isolation, Reintegration, Financial Hardship.

Narrative Theme

Courage, Discipline, Perseverance, Leadership, Service, Growth, Sacrifice, Purpose, Friendship, Redemption.

Narrative Themes are owned by Discovery.

Hero & Story may reference NarrativeThemeId, but must not duplicate ownership.

Outcome

Personal Transformation, Recovery, Career Change, Finding Purpose, Reconciliation, Helping Others, Leadership, New Beginning, Acceptance.

Emotional Character

Hopeful, Funny, Difficult, Reflective, Triumphant, Emotional, Serious, Inspiring.

Audience

General, Teen, Child, Adult.

Content Suitability

Profanity, Violence, Sexual Content, Substance Use, Disturbing Content.

Each suitability dimension should support meaningful levels where appropriate.

Spirituality / Religion

Keep separate:

• non-spiritual;
• spiritual;
• religious.

Optional tradition may include:

• Christianity;
• Judaism;
• Islam;
• Buddhism;
• Other.

Crucial rule:

> A story containing religious content does not establish that the Hero belongs to that religion.

Do not infer personal religious identity from content classification.

Other dimensions

• language;
• origin;
• format;
• duration;
• geography;
• cultural context.

────────

18. Catalog vs Discovery vs Personalization

Keep these questions separate:

Catalog

> What is this story?

Discovery

> What does this person find meaningful?

Personalization

> What should this person experience next?

Cataloging must not become personalization.

Discovery must not become behavioral pattern detection.

Personalization must not become a hidden catalog taxonomy.

────────

19. Discovery and Hero & Story

Discovery may use:

• User Understanding;
• Story Challenges;
• Narrative Themes;
• Hero Experience Areas;
• User Preferences;
• Language Preference;
• Content Preferences;
• Previous Story Interactions.

Conceptually:

```text
User Understanding
        +
Story Challenges
        +
Narrative Themes
        +
Hero Experience Areas
        +
User Preferences
        ↓
Discovery
```

Future discovery should support meaningful serendipity and explainability.

────────

20. Explainability

When EH answers:

> Why am I seeing this?

The explanation must be grounded in actual sources.

Potential sources:

• Narrative Theme;
• Current Journey;
• Behavior Pattern;
• User Discovery;
• Explicit Preference;
• Previous Story Interaction;
• Language Preference;
• Content Preference.

Never fabricate rationale.

────────

21. Story Interaction Is Not Automatically Evidence

Potential interactions:

• View.
• Listen.
• Complete.
• Save.
• Share.
• Reflect.
• Recommend.
• Dismiss.

Do not infer:

listened to story → inspired → growth

Prefer:

```text
Story
   ↓
Interaction
   ↓
Reflection / Action
   ↓
Behavioral Evidence
   ↓
Behavior Pattern
```

Evidence should arise from meaningful signals, not assumed emotional states.

────────

22. Story Lifecycle and Privacy

Potential lifecycle:

```text
Draft
  ↓
Processing
  ↓
Review
  ↓
Approved
  ↓
Published
  ↓
Archived
```

Possible additional states:

• Rejected.
• Suspended.
• Removed.

Visibility is separate from processing/lifecycle:

• Private.
• Draft.
• Unlisted.
• Community.
• Public.

AI transformation permissions are separate from visibility.

Potential consent stages:

• recorded;
• approved for processing;
• approved for publication;
• approved for AI transformation.

Raw recordings, transcripts, drafts, AI artifacts, and published content must not automatically inherit the same visibility.

────────

23. Candidate Hero & Story Events

Potential events:

• HeroCreated
• HeroProfileUpdated
• StoryCreated
• StorySubmitted
• StoryProcessingStarted
• StoryTranscribed
• StoryClassified
• StoryReviewed
• StoryApproved
• StoryPublished
• StoryArchived
• StoryRepresentationCreated
• StoryTranslated
• StoryMediaAdded

Do not implement all events automatically.

Create an event only when:

1. the fact is meaningful;
2. another component may need to react;
3. it belongs to the bounded context;
4. it does not merely expose an implementation detail.

────────

24. Application Layer

Application use cases orchestrate domain behavior.

They may depend on:

• domain aggregates;
• repository interfaces;
• domain services;
• ports;
• application-facing contracts.

They must not directly depend on:

• database implementations;
• REST clients;
• AI SDKs;
• concrete infrastructure adapters.

────────

25. Presentation Layer

Presentation should consume application-facing results and transform them into presentation models.

Widgets must not:

• manipulate aggregates;
• invoke repositories directly;
• invoke detectors;
• construct domain events;
• contain domain rules;
• duplicate application orchestration.

Riverpod manages composition and presentation state, not the business-rule engine.

────────

26. Infrastructure and Replaceable Ports

External capabilities must be replaceable behind ports/contracts.

Examples:

• AI;
• search;
• media storage;
• transcription;
• translation;
• persistence;
• external APIs.

Do not couple domain/application code to a vendor.

────────

27. Testing Rules

Every architectural change should be validated at the appropriate level.

Domain

Test invariants, state transitions, value objects, aggregate behavior, domain services, and deterministic rules.

Application

Test use-case orchestration, repository interactions, event publication, reactor behavior, and error handling.

Infrastructure

Test adapters, serialization, persistence, and external integration boundaries.

UI

Test presentation behavior, state transitions, user-visible outcomes, and application integration.

Prefer focused tests during implementation followed by the broader/full suite.

Never claim completion without running the relevant analyzer/tests.

────────

28. Determinism and Time

Avoid uncontrolled nondeterminism.

Be cautious with:

• DateTime.now();
• random identifiers;
• random ordering;
• external AI responses;
• network-dependent behavior.

If time or randomness is domain-relevant, make it controllable through appropriate abstractions.

Tests should not depend on wall-clock time unless intentionally testing time.

────────

29. Current Known Architecture / Hygiene Issues

The following were identified during repository inspection and are not automatically in scope for HS.1:

• naming mismatch between DetectPatternUseCase / DetectBehaviorPatternsUseCase;
• naming mismatch between PatternDetector / BehaviorPatternDetector;
• interface/provider placement inconsistency;
• orphan PatternsDetected versus BehaviorPatternsDetected;
• duplicate BasePatternRule;
• duplicate/unused BehavioralEvidence type;
• DateTime.now() usage;
• FakeNarrativeThemeResolver wired in production providers;
• incomplete RecoveryPatternRule;
• BehaviorPatternType values without rules;
• legacy duplicate test tree;
• stale architecture maps;
• stale completed-phase documentation;
• legacy CLAUDE.md.

These are findings, not an automatic cleanup mandate.

If one blocks the current task, address only the blocking issue or stop for a decision.

────────

30. Documentation Drift

Known documents may describe an earlier state, including:

• bounded-contexts.md
• aggregate-map.md
• use-case-map.md
• repository-map.md
• event-flow.md
• technical-debt.md
• completed-phase documentation
• legacy agent instructions

When these conflict with current implementation:

1. identify the discrepancy;
2. determine whether it is intentional;
3. report it;
4. avoid unrelated documentation churn.

Architecture documentation should eventually be reconciled, but that is separate work unless required by the current phase.

────────

31. HS.1 Implementation Scope

HS.1 should focus on the foundational model for Hero & Story.

Expected architectural work may include:

1. Architectural decisions.
2. Hero aggregate.
3. Story aggregate.
4. Story lifecycle.
5. Story representation.
6. Language model.
7. Catalog taxonomy.
8. Content suitability.
9. Spirituality/religion classification.
10. Appropriate repository interfaces.
11. Application use cases.
12. Capture contracts.
13. Discovery/search contracts.
14. Tests.

Do not jump directly to a social-media feed.

Catalog and language foundations should exist before feed/discovery UI depends on them.

────────

32. Recommended Development Workflow

Agents must follow:

```text
UNDERSTAND
    ↓
INSPECT
    ↓
PLAN
    ↓
IMPLEMENT
    ↓
ANALYZE
    ↓
TEST
    ↓
REVIEW
    ↓
REPORT
```

UNDERSTAND

Read:

• this AGENTS.md;
• relevant current architecture documentation;
• relevant phase specification;
• relevant existing code.

INSPECT

Before modifying code:

• locate existing types;
• locate related aggregates;
• locate repositories;
• locate events;
• locate providers;
• locate tests;
• identify existing conventions.

Do not invent parallel abstractions without checking for existing ones.

PLAN

For non-trivial changes, produce a concise implementation plan identifying:

• files/components affected;
• domain changes;
• application changes;
• infrastructure changes;
• presentation changes;
• events;
• tests;
• architectural risks.

If the plan reveals an unresolved architecture decision, stop before implementation.

IMPLEMENT

Implement the smallest coherent vertical slice.

Do not perform unrelated cleanup.

ANALYZE

Run the Dart analyzer after implementation.

TEST

Run focused tests, then the relevant broader/full suite.

REVIEW

Inspect:

• diff;
• dependency direction;
• aggregate boundaries;
• event flow;
• naming;
• tests;
• accidental scope expansion.

REPORT

Report:

• what changed;
• why;
• analyzer/tests run;
• known discrepancies;
• deferred work;
• architectural decisions still needed.

────────

33. Scope Discipline

Fix immediately if:

• it causes the requested feature to be incorrect;
• it violates a hard architecture boundary required by the feature;
• it prevents tests from passing;
• it creates unsafe coupling the feature inherently depends on.

Report and defer if:

• it is unrelated technical debt;
• it is stale documentation;
• it is a naming inconsistency with no functional impact;
• it is a legacy test organization issue;
• it is cleanup that can safely happen later.

Stop for a decision if:

• aggregate ownership is ambiguous;
• bounded-context ownership is ambiguous;
• a new cross-context dependency is required;
• an architectural decision is contradicted;
• multiple valid designs would materially affect future architecture.

────────

34. Terminology

Use these terms consistently:

• Evidence — recorded/observed information.
• Pattern — recurring meaningful structure derived from evidence.
• Understanding — accumulated interpretation of the user.
• Narrative Theme — Discovery-owned thematic concept.
• Discovery — determines what may be meaningful to a user.
• Personalization — determines what should be experienced next.
• Experience — a user-facing opportunity for action/reflection/growth.
• Hero — person whose lived experience can inspire others.
• Story — canonical narrative representing a Hero’s lived experience.
• Representation — a language/format form of a Story.
• Media Reference — pointer to media supporting a representation.
• Catalog — structured description of what a Story is.
• Provenance — lineage of a Story artifact or transformation.
• Suitability — content characteristics used for filtering/appropriateness.

Avoid using one term as a synonym for another.

────────

35. Stop Conditions

An agent must stop and ask for clarification when:

• an aggregate boundary is unclear;
• bounded-context ownership is unclear;
• a required dependency would violate the architecture;
• a new architectural decision is necessary;
• the requested behavior conflicts with an explicit current ADR;
• a safe implementation requires guessing about product semantics;
• tests reveal an unexpected architectural contract;
• the requested change would require broad unrelated refactoring.

Do not guess silently.

────────

36. Definition of Done

A feature is not complete merely because the code compiles.

Completion requires:

• architecture boundaries respected;
• domain invariants enforced;
• application orchestration explicit;
• infrastructure replaceable;
• tests added/updated;
• analyzer clean;
• relevant tests passing;
• no unnecessary scope expansion;
• documentation updated when the requested change materially alters current architecture;
• unresolved architectural questions reported.

────────

37. Prime Directive

> **Preserve the architecture while moving the product forward.**

And for Everyone’s Heroes specifically:

> **Build a system that helps one person’s lived experience become another person’s opportunity for growth — without confusing evidence with interpretation, cataloging with personalization, or AI assistance with ownership of the human story.**
