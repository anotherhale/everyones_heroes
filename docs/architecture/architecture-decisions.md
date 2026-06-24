# Architecture Decisions

This document records significant architectural decisions for Everyone's Heroes.

Architecture Decision Records (ADRs) describe intentional choices that guide future development.

When implementation and documentation disagree:

1. Review the ADRs.
2. Determine whether implementation or documentation should change.
3. Update the ADR if the architecture direction has evolved.

ADRs should change rarely.

---

# AD-001 Reflections Are Multi-Modal

Status: Accepted

Date: 2026

Original Design:

Reflection
├── ReflectionContent

Current Design:

Reflection
├── ReflectionResponse[]

Supported Response Types:

* JournalResponse
* PromptResponse
* EmojiResponse
* ScaleResponse
* ChoiceResponse
* VoiceResponse
* PhotoResponse

Rationale:

Different people process growth differently.

Some users prefer journaling.

Some users prefer structured prompts.

Some users prefer lightweight emotional check-ins.

The domain should support multiple reflection styles without changing the Reflection aggregate.

---

# AD-002 Narrative Themes Belong To Discovery

Status: Accepted

Date: 2026

Decision:

NarrativeTheme ownership belongs to the Discovery bounded context.

Life Journey should reference:

NarrativeThemeId

instead of:

NarrativeTheme

Rationale:

Narrative Themes connect:

* Influences
* Reflections
* Stories
* Music
* Missions
* Recommendations

Because Narrative Themes span multiple contexts, Discovery owns them.

---

# AD-003 Influence Is A First-Class Concept

Status: Accepted

Date: 2026

Decision:

Influences are not metadata.

Influences are recommendation primitives.

Examples:

* Michael Jordan
* Rocky Balboa
* Aragorn
* Atomic Habits

Influences should resolve into one or more Narrative Themes.

Recommendation flow:

Influence
↓
Narrative Theme
↓
Recommendation

Rationale:

The long-term personalization engine should be grounded in explicit inspiration sources rather than opaque AI inference.

---

# AD-004 Reflections Generate Evidence

Status: Accepted

Date: 2026

Decision:

Reflections generate observations.

They do not directly generate growth.

Current Flow:

Reflection
↓
Insights
↓
Behavioral Evidence

Behavioral Evidence may represent:

* Strengths
* Weaknesses
* Avoidance
* Fear
* Courage
* Discipline
* Consistency

Rationale:

Growth should be inferred from observations over time.

The system should avoid making immediate conclusions from a single reflection.

---

# AD-005 Growth Signals Are Being Deprecated

Status: Accepted

Date: 2026

Decision:

The architecture is evolving away from:

* GrowthSignal
* GrowthSignalEvidence
* GrowthSignalGenerated

Toward:

* BehavioralEvidence
* BehavioralEvidenceDetected
* Evidence Source

BehavioralSignal entity removed.

Rationale:

GrowthSignal implied positive progress.

Behavioral Evidence is observational and neutral.

Observations may represent:

* Strengths
* Weaknesses
* Avoidance
* Opportunities

Future implementations should prefer Behavioral Evidence terminology.

---

# AD-006 Growth Does Not Automatically Transfer Between Journeys

Status: Accepted

Date: 2026

Decision:

Growth demonstrated in one journey should not automatically improve measurements in another journey.

Example:

Strong discipline in Health
≠
Strong discipline in Relationships

Rationale:

Behavior is contextual.

People often demonstrate strengths in one area while struggling in another.

The system should not assume direct trait transfer.

---

# AD-007 Theme Overlap Is More Important Than Trait Transfer

Status: Accepted

Date: 2026

Decision:

The platform should detect:

Theme Overlap

rather than:

Trait Transfer

Example:

Health Journey
↓
Commitment
↓
Persistence

Relationship Journey
↓
Commitment

This overlap may create:

* Encouragement
* Reflection Prompts
* Recommendations
* Coaching Opportunities

Rationale:

Narrative connections create insight without requiring artificial score transfers.

---

# AD-008 Pattern Detection Is A Future Layer

Status: Accepted

Date: 2026

Decision:

Future architecture should evolve toward:

BehavioralEvidence
↓
Pattern Detection
↓
Guidance

Potential Pattern Types:

* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern
* GrowthOpportunityPattern

Rationale:

Patterns emerge from multiple observations.

Patterns should not be manually stored.

Patterns should be derived.

---

# AD-009 AI Is An Implementation Detail

Status: Accepted

Date: 2026

Decision:

AI providers must remain outside the domain.

Allowed:

Domain Service Interfaces

Examples:

* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

Not Allowed:

* OpenAI references in aggregates
* Anthropic references in entities
* AI SDK dependencies in value objects

Rationale:

The domain should remain independent from AI vendors.

Providers should be replaceable.

---

# AD-010 Domain First

Status: Accepted

Date: 2026

Decision:

The domain model is the product.

Preferred Development Order:

Aggregate
↓
Tests
↓
Use Cases
↓
Infrastructure
↓
UI

Rationale:

Business rules should exist before implementation details.

This supports long-term architectural stability.

---

# AD-011 Event Driven By Default

Status: Accepted

Date: 2026

Decision:

Cross-context communication should occur through domain events.

Preferred:

ReflectionSubmitted
↓
Handler
↓
Use Case

Avoid:

ReflectionUseCase
↓
Directly Calling
↓
JourneyUseCase

Rationale:

Events reduce coupling between bounded contexts.

Events support future extensibility.

---

# AD-012 The Long-Term Moat

Status: Accepted

Date: 2026

Decision:

The long-term value of Everyone's Heroes is not AI.

The moat is:

* Discovery Engine
* Influence Catalog
* Narrative Themes
* Personal Hero Journey
* Adaptive Narrative Guidance

Rationale:

AI models will continue to evolve and commoditize.

The unique value comes from the domain model and accumulated user understanding.

---

# AD-013 Evidence Before Guidance

Status: Accepted

Date: 2026

Decision:

The platform should preserve observations before generating conclusions.

Preferred Flow:

BehavioralEvidence
↓
Pattern Detection
↓
Growth Opportunity
↓
Narrative Guidance

Avoid:

BehavioralEvidence
↓
Narrative Guidance

Rationale:

Guidance should be explainable.

Recommendations should be traceable.

The system should be able to answer:

"Why did I receive this recommendation?"

using observable evidence.

Benefits:

* Explainability
* Transparency
* Better coaching quality
* Reduced AI hallucination risk
* Stronger domain model

Implications:

Behavioral Evidence should be stored.

Patterns should be derived.

Guidance should be generated.

Avoid skipping intermediate layers simply because AI makes it possible.

---

# AD-014 Store Observations, Derive Interpretations

Status: Accepted

Date: 2026

Decision:

Prefer storing raw observations over storing conclusions.

Store:

* Reflection Responses
* Behavioral Evidence
* Narrative Themes
* Influences

Derive:

* Patterns
* Opportunities
* Recommendations
* Guidance

Avoid:

* Arbitrary scores
* Opaque growth ratings
* AI-generated conclusions without evidence

Rationale:

Stored observations retain long-term value.

Interpretations may evolve as the platform becomes more sophisticated.

The platform should preserve the facts and allow future systems to derive better insights from them.

---

# ADR-15 — Behavioral Evidence Is Atomic

Status: Accepted

Date: 2026-06

## Context

The original Life Journey design introduced the concept of a Growth Signal. As the domain evolved, it became clear that growth-oriented signals represented only one subset of observable human behavior.

Reflections may reveal strengths, growth, weaknesses, avoidance patterns, fears, blind spots, emerging capabilities, or other behavioral characteristics. A model focused solely on growth signals imposed an unintended positive bias and limited future analysis capabilities.

The architecture requires a neutral, evidence-based representation of observed behavior that can support future pattern detection, growth opportunity identification, and narrative guidance.

## Decision

Behavioral Evidence is the atomic behavioral observation within the domain.

A BehavioralEvidence instance represents a classified observation derived from a source of evidence.

BehavioralEvidence consists of:

* BehavioralEvidenceType
* EvidenceSource
* Strength

BehavioralEvidence does not represent interpretation across time, behavioral trends, or growth opportunities.

BehavioralEvidence is intentionally small and context-independent.

Example:

```text
BehavioralEvidence
    Type: Discipline
    Source: Reflection #123
    Strength: 0.85
```

## Evidence Sources

BehavioralEvidence must reference an EvidenceSource.

Current EvidenceSource implementations:

* ReflectionEvidenceSource
* MissionEvidenceSource

Future sources may include:

* ContributionEvidenceSource
* MentorshipEvidenceSource
* DiscoveryEvidenceSource
* ExternalAssessmentEvidenceSource

## Event Model

Reflections publish:

```text
BehavioralEvidenceDetected
```

when behavioral evidence is identified.

BehavioralEvidenceDetected contains one or more BehavioralEvidence instances.

The event represents newly detected evidence, not long-term conclusions.

## Consequences

### Positive

* Supports both strengths and weaknesses.
* Eliminates positive bias inherent in Growth Signal terminology.
* Enables future pattern detection across multiple observations.
* Provides a stable foundation for AI-assisted analysis.
* Supports multiple evidence sources.
* Aligns with event sourcing and event-driven architecture.

### Negative

* Additional layers are required to derive meaning from evidence.
* BehavioralEvidence alone cannot determine growth opportunities.
* Future pattern detection infrastructure is required.

## Future Architecture

BehavioralEvidence is the foundation for future adaptive narrative systems.

Expected progression:

```text
BehavioralEvidence
        ↓
Pattern Detection
        ↓
DetectedPattern
        ↓
Growth Opportunity Detection
        ↓
GrowthOpportunity
        ↓
Narrative Guidance Engine
        ↓
Narrative Guidance
```

BehavioralEvidence remains the atomic observation throughout this pipeline.

## Deprecated Concepts

The following concepts are deprecated and should not be used in new development:

* GrowthSignal
* GrowthSignalGenerated
* GrowthSignalObserved

Existing references should be migrated to:

* BehavioralEvidence
* BehavioralEvidenceDetected

## Related ADRs

* AD-001 Hexagonal Architecture
* AD-010 Domain First
* AD-011 Behavioral Signals Become Behavioral Evidence

---

# Architectural North Star

Everyone's Heroes exists to help people:

Challenge
↓
Action
↓
Reflection
↓
Behavioral Evidence
↓
Pattern Detection
↓
Growth Opportunities
↓
Narrative Guidance
↓
Contribution

Every major architectural decision should support this progression.
