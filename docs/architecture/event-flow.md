# Event Flow

This document describes how domain events move through the system.

The platform follows an event-driven architecture.

Aggregates publish events.

Application services and orchestrators react to events.

Cross-context communication should occur through events rather than direct aggregate dependencies.

---

# Principles

## Aggregates Publish Events

Aggregates may raise domain events when meaningful business actions occur.

Example:

Quest
↓
Mission Completed
↓
MissionCompleted Event

---

## Events Represent Facts

Events should represent something that happened.

Good:

* ReflectionSubmitted
* MissionCompleted
* QuestCompleted
* BehavioralEvidenceDetected

Avoid:

* AnalyzeReflectionRequested
* GenerateInsightsRequested

Commands request work.

Events record facts.

---

## Events Cross Boundaries

Events are the preferred mechanism for communication between:

* Aggregates
* Bounded Contexts
* Application Services

Prefer:

ReflectionSubmitted
↓
AnalyzeReflectionUseCase

Over:

Reflection
↓
Directly Calling
↓
AnalyzeReflectionUseCase

---

# Current Event Flow

## Journey Lifecycle

Journey Created
↓
JourneyCreated

Future:

JourneyCreated
↓
Recommendation Engine
↓
Suggested Quests

---

## Quest Lifecycle

Create Quest
↓
QuestCreated

Complete All Missions
↓
QuestCompleted

---

## Mission Lifecycle

Create Mission
↓
MissionCreated

Complete Mission
↓
MissionCompleted

Future:

MissionCompleted
↓
Create Reflection Recommendation

---

## Reflection Lifecycle

Create Reflection
↓
Add Responses
↓
Submit Reflection
↓
ReflectionSubmitted

At this point the Reflection becomes immutable.

Responses may no longer be modified.

---

# Reflection Analysis Pipeline

Current Architecture

ReflectionSubmitted
↓
AnalyzeReflectionUseCase
↓
InsightsGenerated
↓
BehavioralEvidenceDetected

Optional:

BehavioralEvidenceDetected
↓
Narrative Theme Resolution
↓
NarrativeThemesAdded

Current Status:

The event infrastructure exists.

Automatic orchestration is not yet wired.

Analysis currently occurs through direct use case execution.

---

# Current Domain Events

## Journey Events

JourneyCreated

Raised when a Journey is created.

---

ChapterAdvanced

Raised when a Journey advances to a new chapter.

---

## Quest Events

QuestCreated

Raised when a Quest is created.

---

MissionCreated

Raised when a Mission is created.

---

MissionCompleted

Raised when a Mission is completed.

---

QuestCompleted

Raised when all Quest missions are completed.

---

## Reflection Events

ReflectionSubmitted

Raised when a Reflection is submitted.

---

InsightsGenerated

Raised when Insights are added to a Reflection.

---

BehavioralEvidenceDetected

Raised when Behavioral Evidence is added to a Reflection.

---

## Planned Events

NarrativeThemesAdded

Raised when Narrative Themes are attached to a Reflection.

Current Status:
Not yet implemented.

---

PatternDetected

Raised when a behavioral pattern is identified.

Current Status:
Future.

---

GrowthOpportunityDetected

Raised when a growth opportunity is identified.

Current Status:
Future.

---

NarrativeGuidanceGenerated

Raised when personalized guidance is created.

Current Status:
Future.

---

# Future Architecture

The long-term architecture is expected to evolve toward:

MissionCompleted
↓
Reflection Recommendation
↓
Reflection Submitted
↓
Behavioral Evidence Detection
↓
Pattern Detection
↓
Growth Opportunity Detection
↓
Narrative Guidance
↓
Recommendations

---

# Behavioral Evidence Pipeline

Current

Reflection
↓
BehavioralEvidence

Future

BehavioralEvidence
↓
Pattern Detection
↓
Behavioral Patterns
↓
Growth Opportunities
↓
Narrative Guidance

Examples:

BehavioralEvidence
↓
Avoidance Pattern
↓
Growth Opportunity
↓
Reflection Prompt

BehavioralEvidence
↓
Consistency Pattern
↓
Encouragement
↓
Mission Recommendation

---

# Discovery Integration

Future Discovery flow:

Influence Selected
↓
Narrative Theme Identified
↓
Discovery Profile Updated

Narrative Theme
↓
Mission Recommendation

Narrative Theme
↓
Story Recommendation

Narrative Theme
↓
Guidance Personalization

---

# Event Ownership

Journey Aggregate

Publishes:

* JourneyCreated
* ChapterAdvanced

---

Quest Aggregate

Publishes:

* QuestCreated
* MissionCreated
* MissionCompleted
* QuestCompleted

---

Reflection Aggregate

Publishes:

* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded (future)

---

Discovery Aggregate

Planned

Publishes:

* InfluenceAdded
* NarrativeThemeDiscovered
* DiscoveryProfileUpdated

---

# Architectural Gaps

The following event infrastructure exists but is not fully wired:

ReflectionSubmitted
↓
No automatic subscribers

BehavioralEvidenceDetected
↓
No automatic subscribers

MissionCompleted
↓
No automatic subscribers

This is expected during M1.

Future work should focus on connecting the event pipeline through orchestrators and application services.

---

# Event Design Guidelines

When adding a new event:

1. The event must represent a business fact.
2. The event should be named in past tense.
3. The event should be published by an aggregate.
4. The event should not contain behavior.
5. The event should not contain service references.
6. Prefer small immutable payloads.
7. Prefer identifiers over aggregate objects.

Good:

ReflectionSubmitted

Bad:

SubmitReflectionRequested

Good:

BehavioralEvidenceDetected

Bad:

AnalyzeReflectionRequested

---

# Architectural North Star

The platform is evolving toward:

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

Events are the mechanism that allows each stage to evolve independently.
