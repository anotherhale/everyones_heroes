# Technical Debt

This document tracks known technical debt, deferred architectural work, and intentional shortcuts.

Technical debt is not necessarily bad.

Many items are intentionally deferred to keep development focused on the current milestone.

Each item should include:

* Description
* Impact
* Priority
* Related ADRs
* Suggested Resolution

---

# TD-001 Pattern Detection Layer

Status: Open

Priority: High

Depends On:
- BehavioralEvidence
- Reflection Analysis Pipeline

Blocks:
- TD-002 Growth Opportunity Detection
- TD-003 Narrative Guidance Engine

Related ADRs:

* AD-008 Pattern Detection Is A Future Layer
* AD-013 Evidence Before Guidance
* AD-014 Store Observations, Derive Interpretations

Description:

The architecture currently captures:

* Reflections
* Insights
* Behavioral Evidence
* Narrative Themes

However, there is no Pattern Detection layer.

Desired Flow:

Behavioral Evidence
↓
Pattern Detection
↓
Pattern

Examples:
- Consistent Discipline
- Emerging Leadership
- Avoidance Trend
- Service Orientation

Impact:

The platform can collect observations but cannot yet identify recurring behavioral trends.

Suggested Resolution:

Introduce:

* Pattern aggregate or domain model
* Pattern detection services
* Pattern detection use cases

---

# TD-002 Growth Opportunity Detection

Status: Open

Priority: High

Blocks:
- TD-003 Narrative Guidance Engine

Related ADRs:

* AD-008 Pattern Detection Is A Future Layer
* AD-013 Evidence Before Guidance

Description:

Growth opportunities should emerge from detected patterns.

Desired Flow:

Behavioral Evidence
↓
Pattern
↓
Growth Opportunity

Examples:

* Communication Opportunity
* Courage Opportunity
* Consistency Opportunity

Impact:

The platform cannot yet transform observed patterns into actionable opportunities.

Suggested Resolution:

Create:

* GrowthOpportunity domain model
* DetectGrowthOpportunitiesUseCase

---

# TD-003 Narrative Guidance Engine

Status: Open

Priority: High

Related ADRs:

* AD-013 Evidence Before Guidance
* AD-014 Store Observations, Derive Interpretations

Description:

The final personalization layer has not been implemented.

Desired Flow:

Behavioral Evidence
↓
Patterns
↓
Growth Opportunities
↓
Narrative Guidance

Potential Outputs:

* Encouragement
* Reflection Prompts
* Story Recommendations
* Mission Recommendations
* Hero Recommendations

Impact:

The platform can gather information but cannot yet generate personalized guidance.

Suggested Resolution:

Create:

* Narrative Guidance domain model
* GenerateNarrativeGuidanceUseCase
* Guidance recommendation services

---

# TD-005 Contribution Context

Status: Open

Priority: Medium

Description:

Contribution bounded context is planned but not implemented.

Potential Concepts:

* Contribution
* Mentorship
* Service
* Coaching
* Hero Impact

Impact:

The current architecture supports growth but not outward contribution.

Suggested Resolution:

Create:

* Contribution bounded context
* Contribution aggregates
* Contribution repositories
* Contribution use cases

---

# TD-006 Event Pipeline Wiring

Status: Open

Priority: Medium

Related ADRs:

* AD-011 Event Driven By Default

Description:

Domain events are generated but event orchestration remains incomplete.

Examples:

ReflectionSubmitted
↓
AnalyzeReflectionUseCase

BehavioralEvidenceDetected
↓
DetectPatternsUseCase

PatternDetected
↓
DetectGrowthOpportunitiesUseCase

Most future event-driven workflows remain unwired.

Impact:

The architecture supports event-driven workflows but many event handlers do not yet exist.

Suggested Resolution:

Introduce:

* Event registration layer
* Event handler infrastructure
* Integration tests for event pipelines

---

# TD-007 Clock Injection

Status: Open

Priority: Low

Description:

Some domain objects currently call:

DateTime.now()

directly.

Examples:

Reflection.create()
Reflection.submit()

The shared kernel already contains:

* Clock
* FixedClock
* SystemClock

but they are not consistently used.

Impact:

Makes certain tests less deterministic.

Suggested Resolution:

Inject clock abstractions into creation and lifecycle workflows.

Potential Future:

Reflection.create(
clock: clock,
)

instead of:

DateTime.now()

# TD-008 Reflection Query Support

Status: Open

Priority: Medium

Description:

ReflectionRepository currently supports:

- save()
- findById()

but does not support common query operations such as:

findByJourneyId()

Impact:

Future Journey dashboards, growth summaries, and pattern detection will likely require efficient reflection retrieval by Journey.

Suggested Resolution:

Extend ReflectionRepository with:

- findByJourneyId()
- findByQuestId() (optional)
- findByMissionId() (optional)

Future reporting and pattern detection workflows should avoid loading reflections individually.

Technical Debt items should eventually be resolved and closed and moved to the CLOSED section.

---

# Technical Debt Prioritization

Current Focus:

High Priority

Medium Priority

Low Priority

---

# Architectural North Star

Store:

* Reflections
* Behavioral Evidence
* Narrative Themes

Derive:

* Patterns
* Growth Opportunities

Generate:

* Narrative Guidance

Technical debt should be evaluated based on whether it moves the architecture closer to this vision.

---
# CLOSED TD Issues
---

# TD-004 DiscoveryProfile Aggregate

Status: CLOSED

Closed: 2026-06-23

Priority: High

Related ADRs:

* AD-002 Narrative Themes Belong To Discovery
* AD-003 Influence Is A First-Class Concept
* AD-015 Narrative Themes Are A Cross-Cutting Concept
* AD-016 Curated Discovery Before AI Discovery

Description:

Discovery entities exist:

* Influence
* NarrativeTheme

However, DiscoveryProfile aggregate ownership has not been implemented.

Missing:

* DiscoveryProfile aggregate
* DiscoveryProfileRepository
* Discovery use cases

Impact:

Discovery currently lacks a consistency boundary.

Suggested Resolution:

Implement:

* DiscoveryProfile aggregate
* DiscoveryProfileRepository
* Discovery use cases

---
