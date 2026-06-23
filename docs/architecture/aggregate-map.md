# Aggregate Map
# Aggregate Map

This document describes the aggregate boundaries within Everyone's Heroes.

Aggregates are consistency boundaries.

Aggregates enforce invariants and publish domain events.

Repositories persist aggregates.

Other aggregates should communicate through events, identifiers, and use cases rather than direct mutation.

---

# Aggregate Hierarchy

Current Architecture

Journey
├── Quest
│   └── Mission
└── Reflection

Reflection is currently independent and may reference:

* Journey
* Quest
* Mission

through identifiers.

Future Architecture

LifeJourney
├── Journey
├── Quest
├── Reflection
└── Growth Profile

Current implementation has not yet introduced the LifeJourney aggregate.

---

# Life Journey Context

Status: Active

---

## Journey

Type:

Aggregate Root

Status:

Implemented

Responsibility:

Represents a major area of intentional growth.

Examples:

* Health
* Relationships
* Career
* Leadership

Journey provides context for growth.

Journey does not own growth itself.

---

### Responsibilities

* Vision ownership
* Chapter ownership
* Quest enrollment
* Journey progression

---

### Invariants

* A Journey must have a Vision.
* A Journey must have an active Chapter.
* Chapter progression must occur through domain behavior.

---

### Child Objects

Current:

* Chapter

Future:

* Milestones
* Journey Recommendations

---

### Published Events

* JourneyCreated
* ChapterAdvanced

---

### Repository

JourneyRepository

---

# Quest

Type:

Aggregate Root

Status:

Implemented

Responsibility:

Represents a meaningful challenge within a Journey.

Examples:

* Run a 5K
* Improve Communication
* Build a Meditation Habit

---

### Responsibilities

* Mission ownership
* Mission completion tracking
* Quest completion tracking

---

### Invariants

* A Quest must belong to a Journey.
* A Quest must contain at least one Mission.
* A Quest cannot be completed until all Missions are completed.

---

### Child Entities

Mission

---

### Published Events

* QuestCreated
* MissionCreated
* MissionCompleted
* QuestCompleted

---

### Repository

QuestRepository

---

# Mission

Type:

Entity

Status:

Implemented

Owner:

Quest

Mission is not an aggregate root.

Mission lifecycle is managed by Quest.

---

### Responsibilities

* Represent actionable work
* Track completion state
* Capture mission metadata

---

### Invariants

Defined and enforced by Quest.

---

# Reflection

Type:

Aggregate Root

Status:

Implemented

Responsibility:

Capture and analyze personal reflection.

Reflection is one of the most important aggregates in the platform.


---

### Responsibilities

* Response collection
* Submission lifecycle
* Insight ownership
* Behavioral Evidence ownership
* Narrative Theme references

---

### Lifecycle

Create
↓
Add Responses
↓
Submit
↓
Analyze

After submission:

Responses become immutable.

Insights, Behavioral Evidence, and Narrative Themes may be added.

---

### Invariants

* Reflection must contain at least one response before submission.
* Submitted reflections cannot accept additional responses.
* Insights require submission.
* Behavioral Evidence requires submission.
* Narrative Themes require submission.

---

### Child Objects

ReflectionResponse

Insight

BehavioralEvidence
├── BehavioralEvidenceType
├── EvidenceSource
│   ├── ReflectionEvidenceSource
│   └── MissionEvidenceSource
└── Strength

NarrativeThemeId

---

### Published Events

* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded

All four events are implemented.

---

### Repository

ReflectionRepository

---

# Discovery Context

Status: Foundation

---

## DiscoveryProfile

Type:

Aggregate Root

Status:

Planned

Responsibility:

Represent what inspires a person.

DiscoveryProfile will become the ownership boundary for:

* Influences
* Narrative Themes
* Discovery Preferences

---

### Responsibilities

* Influence ownership
* Theme ownership
* Recommendation inputs

---

### Child Entities

Influence

NarrativeTheme

---

### Planned Events

* InfluenceAdded
* InfluenceRemoved
* NarrativeThemeDiscovered
* DiscoveryProfileUpdated

---

### Planned Repository

DiscoveryProfileRepository

---

# Influence

Type:

Entity

Status:

Implemented

Owner:

Future DiscoveryProfile aggregate

---

### Responsibilities

Represent a source of inspiration.

Examples:

* Michael Jordan
* Rocky Balboa
* Aragorn
* Atomic Habits

---

### Invariants

* Must have a canonical name.
* Must contain at least one Narrative Theme.
* Aliases must be unique.

---

# NarrativeTheme

Type:

Entity

Status:

Implemented

Owner:

Future DiscoveryProfile aggregate

---

### Responsibilities

Represent recurring narrative patterns.

Examples:

* Courage
* Service
* Redemption
* Leadership
* Perseverance

---

### Invariants

* Must have a valid identifier.
* Must have a non-empty name.

---

# Future Aggregates

These concepts are intentionally deferred.

---

## LifeJourney

Status:

Planned

Potential Responsibilities:

* Cross-journey growth tracking
* Person-level pattern ownership
* Growth profile ownership
* Journey coordination

Rationale:

Current architecture focuses on Journey, Quest, and Reflection.

LifeJourney will emerge when person-level growth behavior becomes necessary.

---

## GrowthProfile

Status:

Planned

Potential Responsibilities:

* Pattern ownership
* Growth opportunities
* Behavioral trends

Potential Child Objects:

* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern
* GrowthOpportunityPattern

Rationale:

Patterns should emerge from evidence.

GrowthProfile may eventually become the consistency boundary for those patterns.

---

# Aggregate Relationships

Current

Journey
↓
Quest
↓
Mission

Reflection
↓
JourneyId

Reflection
↓
QuestId

Reflection
↓
MissionId

NarrativeTheme
↓
Referenced By
↓
Reflection

---

# Aggregate Communication

Preferred

Aggregate
↓
Domain Event
↓
Handler
↓
Use Case
↓
Aggregate

Avoid

Aggregate
↓
Direct Aggregate Mutation

Examples

Good:

MissionCompleted
↓
Create Reflection

Bad:

Quest
↓
Directly Modifies
↓
Reflection

---

# Aggregate Ownership Rules

Journey owns:

* Vision
* Chapters

Quest owns:

* Missions

Reflection owns:

* Responses
* Insights
* Behavioral Evidence

DiscoveryProfile owns:

* Influences
* Narrative Themes

Future GrowthProfile owns:

* Patterns
* Growth Opportunities

Ownership should be respected.

Do not duplicate concepts across aggregate boundaries.

---

# Architectural North Star

Store:

* Actions
* Reflections
* Evidence

Derive:

* Patterns
* Opportunities

Generate:

* Guidance

Aggregate boundaries should support:

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
Narrative Guidance
↓
Contribution

while maintaining clear ownership and consistency boundaries.
