# CLAUDE.md

Current Implementation Status

When documentation and code disagree:

1. Trust the code.
2. Review ADRs.
3. Update architecture documents.
4. Do not blindly implement the original blueprint.

The architecture is intentionally evolving.
The codebase is the current source of truth.

## Everyone's Heroes Development Guide

### Current Status

The codebase is currently implementing the M1 Life Journey foundation using:

* Domain Driven Design (DDD)
* Hexagonal Architecture
* Event Driven Architecture
* Riverpod
* Domain-First Development

The project is intentionally built from the domain outward.

Flutter UI is considered a consumer of the domain, not the driver of the architecture.

---

# Core Philosophy

Everyone's Heroes exists to help people:

Challenge
↓
Action
↓
Reflection
↓
Growth
↓
Contribution

Because everyone is both:

* A Student
* A Hero

The platform is not a fitness application.

The platform is not an AI coaching application.

The platform is a Human Growth Platform.

---

# Architectural Principles

## Hexagonal Architecture

Every feature follows:

domain/
application/
infrastructure/
presentation/

Rules:

* Domain never depends on Flutter.
* Domain never depends on Riverpod.
* Domain never depends on AI providers.
* Infrastructure depends on domain.
* Application orchestrates domain behavior.
* Presentation consumes application services.

---

# Current Bounded Contexts

## Identity

Responsibility:

Who is this person?

Contains:

* User
* Profile
* Preferences

---

## Discovery

Responsibility:

What inspires this person?

Aggregate Root:

DiscoveryProfile

Entities:

* Influence
* NarrativeTheme
* UserDiscovery

Discovery is responsible for:

* Influence collection
* Narrative theme resolution
* Recommendation inputs
* Personal inspiration mapping

NarrativeTheme ownership belongs to Discovery.

Do not duplicate NarrativeTheme entities in other contexts.

Other contexts reference NarrativeThemeId only.

---

## Life Journey

Responsibility:

How is this person growing?

Aggregate Roots:

* LifeJourney
* Journey
* Quest
* Reflection

Entities:

* Mission

Current hierarchy:

LifeJourney
└── Journey
└── Quest
└── Mission

Reflection exists independently and may reference:

* Journey
* Quest
* Mission

or none of them.

Examples:

* Mission Reflection
* Daily Journal
* Gratitude Reflection
* Morning Check-In

---

## Contribution

Responsibility:

How is this person helping others grow?

Future Context.

Not currently implemented.

---

# Reflection Architecture

Reflection is one of the most important aggregates in the platform.

Reflections are not text fields.

Reflections are collections of responses.

Current model:

Reflection
├── ReflectionResponse[]
├── Insight[]
├── BehavioralEvidence[]
└── NarrativeThemeId[]

Reflection lifecycle:

Create Reflection
↓
Add Responses
↓
Submit Reflection
↓
Immutable Reflection

After submission:

Allowed:

* Add Insights
* Add Behavioral Evidence
* Add Narrative Themes

Not Allowed:

* Modify Responses

---

# Reflection Response Hierarchy

ReflectionResponse
├── JournalResponse
├── PromptResponse
├── EmojiResponse
├── ScaleResponse
├── ChoiceResponse
├── VoiceResponse
└── PhotoResponse

This allows adaptive reflection experiences.

The UI may dynamically select reflection types based on user preference.

The domain model remains unchanged.

---

# Discovery Model

Influence

Influence
├── CanonicalName
├── Category
├── Description
├── ImageReference
├── Aliases[]
└── NarrativeThemeIds[]

Examples:

* Rocky
* Michael Jordan
* Aragorn
* David Goggins
* Atomic Habits

Influences are recommendation primitives.

Narrative themes connect:

* Influences
* Stories
* Missions
* Reflections
* Music
* Coaching

---

# Behavioral Evidence Model

IMPORTANT:

The architecture has evolved away from Growth Signals.

Current direction:

Reflection
↓
InsightExtractionService
↓
Insight[]
↓
BehavioralEvidenceAnalyzer
↓
BehavioralEvidence[]

Behavioral Evidence may indicate:

* Strengths
* Weaknesses
* Avoidance
* Growth Opportunities
* Emerging Patterns

Behavioral Evidence is observational.

It is not inherently positive.

Examples:

* Discipline
* Courage
* Consistency
* Avoidance
* Fear
* Procrastination

Future pattern analysis will aggregate evidence into higher-order behavioral patterns.

---

# Growth Signal Deprecation

GrowthSignal and GrowthSignalGenerated are legacy concepts.

Do not introduce new usages.

Prefer:

* BehavioralEvidence
* BehavioralEvidenceDetected
* BehavioralSignal (future pattern layer)

Journey should not directly own behavioral evidence.

Evidence belongs to reflections.

Future pattern analysis may produce journey-level or person-level behavioral signals.

This remains an active architectural evolution.

---

# AI Integration Philosophy

AI is never part of the domain.

AI providers sit behind ports.

Domain Services:

* InsightExtractionService
* NarrativeThemeResolver
* BehavioralEvidenceAnalyzer

Infrastructure Adapters may use:

* OpenAI
* Anthropic
* Local Models

The domain remains provider-agnostic.

---

# Testing Philosophy

The domain is the product.

Prioritize tests for:

* Aggregate invariants
* Domain services
* Use cases
* Repository contracts
* Event publication
* Event pipelines

Do not prioritize UI tests during M1.

Current target:

300+ passing tests.

All new domain behavior should be accompanied by tests.

---

# Current Architectural Direction

The platform is evolving toward:

Discovery
↓
Action
↓
Reflection
↓
Behavioral Evidence
↓
Pattern Detection
↓
Narrative Guidance
↓
Contribution

The long-term moat is not AI.

The moat is:

* Discovery Engine
* Influence Catalog
* Narrative Themes
* Personal Hero Journey
* Adaptive Narrative Guidance

# Architectural Decisions Since M1 Blueprint

The implementation has evolved beyond the original M1.1 architecture blueprint.

When implementation and documentation disagree, this section reflects the current direction.

---

## AD-001 Reflections Are Multi-Modal

Original:

Reflection
├── ReflectionContent

Current:

Reflection
├── ReflectionResponse[]

Reflection is no longer assumed to be text-based.

Supported response types:

* JournalResponse
* PromptResponse
* EmojiResponse
* ScaleResponse
* ChoiceResponse
* VoiceResponse
* PhotoResponse

Future reflection types should inherit from ReflectionResponse.

Do not introduce new ReflectionContent-style objects.

---

## AD-002 Narrative Themes Belong To Discovery

NarrativeTheme ownership belongs to the Discovery context.

Do not duplicate NarrativeTheme entities in Life Journey.

Life Journey stores:

NarrativeThemeId[]

only.

Narrative Themes connect:

* Influences
* Stories
* Reflections
* Music
* Missions
* Recommendations

and therefore belong to Discovery.

---

## AD-003 Influence Is A First-Class Concept

Influences are not metadata.

Influences are recommendation primitives.

Examples:

* Rocky
* Michael Jordan
* Aragorn
* David Goggins
* Atomic Habits

Every Influence resolves into one or more Narrative Themes.

Future recommendation systems should primarily operate through:

Influence
↓
Narrative Theme
↓
Recommendation

rather than direct AI inference.

---

## AD-004 Reflections Generate Evidence

Reflections generate observations.

They do not directly generate growth.

Current flow:

Reflection
↓
Insight Extraction
↓
Behavioral Evidence

Behavioral Evidence may represent:

* Strength
* Weakness
* Avoidance
* Fear
* Courage
* Discipline
* Consistency
* Growth Opportunity

Evidence is observational and neutral.

Avoid designing systems that assume all evidence is positive.

---

## AD-005 Growth Signals Are Being Deprecated

The original architecture used:

GrowthSignal
GrowthSignalEvidence
GrowthSignalGenerated

The architecture is evolving toward:

BehavioralEvidence
BehavioralEvidenceDetected
BehavioralSignal (future)

Do not create new GrowthSignal-based concepts.

If introducing new behavior analysis functionality:

Prefer:

BehavioralEvidence

over:

GrowthSignal

---

## AD-006 Growth Does Not Automatically Transfer Between Journeys

The system should not assume:

Discipline(Health)
↓
Discipline(Relationships)

Growth is contextual.

Examples:

A user may demonstrate:

* Strong discipline in fitness
* Weak discipline in relationships

simultaneously.

Do not automatically increase behavioral measurements across journeys.

---

## AD-007 Theme Overlap Is More Important Than Trait Transfer

The platform should detect:

Theme Overlap

rather than:

Trait Transfer

Example:

Health Journey:

Showing Up
Persistence
Commitment

Relationship Journey:

Showing Up
Commitment

This overlap may create:

* Encouragement
* Coaching opportunities
* Reflection prompts
* Mission recommendations

without assuming skill transfer.

---

## AD-008 Pattern Detection Is A Future Layer

Future architecture should evolve toward:

BehavioralEvidence
↓
Pattern Detection
↓
Guidance

Potential patterns:

* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern
* GrowthOpportunityPattern

These patterns may eventually become part of a Growth Profile.

---

## AD-009 AI Is An Implementation Detail

AI is not domain logic.

AI belongs behind ports.

Never place:

OpenAI
Anthropic
Claude
Gemini

inside aggregates, entities, value objects, or use cases.

The domain should be unaware of AI providers.

---

## AD-010 Domain First

The domain model is the product.

Before creating:

* Screens
* Riverpod providers
* Widgets
* APIs

ensure the domain model exists.

Prefer:

Aggregate
↓
Tests
↓
Use Case
↓
Infrastructure
↓
UI

over:

UI
↓
Business Logic

---

## AD-011 Event Driven By Default

Cross-context communication should occur through domain events.

Avoid direct dependencies between bounded contexts.

Preferred:

ReflectionSubmitted
↓
BehavioralEvidenceDetected
↓
PatternDetected

Avoid:

ReflectionUseCase
↓
Directly calling
↓
JourneyUseCase

unless a strong reason exists.

---

## AD-012 The Long-Term Moat

The long-term value of Everyone's Heroes is not AI.

The moat is:

* Discovery Engine
* Influence Catalog
* Narrative Themes
* Personal Hero Journey
* Adaptive Narrative Guidance

AI providers must remain replaceable.

# Architecture Heuristics

These heuristics should guide future architectural decisions.

When uncertain, prefer these principles over introducing new abstractions.

---

## Prefer Evidence Over Conclusions

Store:

* Observations
* Evidence
* User Actions
* User Responses

Derive:

* Signals
* Patterns
* Insights
* Guidance

Generate:

* Recommendations
* Encouragement
* Coaching

Bad:

Reflection
↓
GrowthScore

Better:

Reflection
↓
BehavioralEvidence
↓
Pattern Detection
↓
Guidance

---

## Prefer Patterns Over Scores

Everyone's Heroes is not a gamification platform.

Avoid introducing:

* XP
* Character Stats
* Arbitrary Scoring Systems

Prefer:

* Patterns
* Narrative Themes
* Growth Opportunities
* Emerging Behaviors

The platform should feel like a guide rather than a game.

---

## Prefer Discovery Over Assumption

Do not assume:

* User motivations
* User personality
* User growth style

Discover them through:

* Influences
* Reflections
* Narrative Themes
* Behavioral Evidence

The platform learns over time.

---

## Prefer Theme Connections Over Trait Transfer

Avoid:

Discipline(Health)
↓
Discipline(Relationships)

Prefer:

Theme Overlap
↓
Guidance Opportunity

Growth should not automatically transfer across life domains.

Narrative connections should create coaching opportunities.

---

## Prefer Person Growth Over Journey Growth

Journeys provide context.

Growth belongs to the person.

When introducing new concepts ask:

"Does this belong to the Journey?"

or

"Does this belong to the Person?"

Future Growth Profile concepts should likely be person-centric rather than journey-centric.

---

## Prefer Derived Data Over Stored Data

Before creating a repository or field ask:

Can this be derived?

Examples:

Store:

* Reflections
* Evidence
* Themes

Derive:

* Patterns
* Opportunities
* Recommendations

Avoid storing projections that can be recomputed.

---

## Prefer Events Over Direct Dependencies

When crossing aggregate boundaries:

Prefer:

Domain Event
↓
Handler
↓
Use Case

Avoid:

Aggregate
↓
Directly Mutating
↓
Another Aggregate

Cross-context communication should remain event-driven.

---

## Prefer Narrative Guidance Over Optimization

The platform exists to help users become better versions of themselves.

It does not exist to maximize:

* Streaks
* Scores
* Points
* Engagement Metrics

The primary outcome is:

Meaningful Growth

not

Maximum Activity

---

## Before Adding A New Concept

Ask:

1. Is this evidence?
2. Is this a signal?
3. Is this a pattern?
4. Is this guidance?
5. Is this a Narrative Theme?
6. Is this journey-specific?
7. Is this person-wide?
8. Can it be derived instead of stored?
9. Does it belong in an existing bounded context?
10. Would a domain event be a better solution?

Only introduce a new aggregate when existing concepts cannot model the behavior cleanly.

---

## Future Architectural Direction

Current:

Reflection
↓
BehavioralEvidence

Future:

BehavioralEvidence
↓
Pattern Detection
↓
Growth Opportunities
↓
Narrative Guidance

Potential future concepts:

* GrowthProfile
* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern
* GrowthOpportunityPattern

These should be introduced only when supported by real evidence from the domain model.

---

## Architectural North Star

Everyone's Heroes should help people:

Face Challenges
↓
Take Action
↓
Reflect
↓
Recognize Patterns
↓
Grow
↓
Contribute

Every architectural decision should support this flow.
