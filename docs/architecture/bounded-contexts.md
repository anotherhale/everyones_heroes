# Bounded Contexts

This document describes the bounded contexts that make up the Everyone's Heroes domain.

Bounded contexts define ownership boundaries, responsibilities, aggregate roots, and integration points.

Each context should own its own language, aggregates, repositories, and business rules.

Cross-context communication should occur through domain events.

---

# Context Map

Identity
     ↘
      Discovery
          ↘
       Life Journey
          ↘
      Contribution

Identity provides the person.

Discovery understands what inspires them.

Life Journey helps them grow.

Contribution helps them help others grow.

---

# Identity

Status: Planned

Responsibility:

Who is this person?

Identity owns:

* User
* Profile
* Preferences
* Settings

Potential Aggregates:

* User
* UserProfile

Potential Concepts:

* Profile
* Interests
* Preferences
* Notification Settings

Identity should not contain growth logic.

Identity should not contain recommendation logic.

Identity provides foundational person information to other contexts.

---

## Discovery Context

Status: Planned

### Responsibility

What inspires this person?

The Discovery Context is responsible for understanding the people, stories, ideas, characters, experiences, and themes that resonate with a user.

The purpose of Discovery is not personality classification.

The purpose is to identify sources of inspiration and map them to Narrative Themes that can be used throughout the platform.

Produces:

* Narrative Themes
* Influence Selections
* Discovery Insights

Consumes:

* UserId

---

### Core Concepts

#### DiscoveryProfile

Represents a user's evolving inspiration profile.

Contains:

* User Discoveries
* Selected Influences
* Narrative Themes
* Discovery History

DiscoveryProfile is the aggregate root of the Discovery Context.

---

#### UserDiscovery

Represents a single piece of information learned about a user.

Examples:

* Favorite Movie
* Favorite Athlete
* Favorite Book
* Favorite Character
* Favorite Team
* Mentor
* Life Lesson

Discoveries accumulate over time through progressive discovery experiences.

---

#### DiscoveryHistory

Tracks how a DiscoveryProfile evolved over time.

Examples:

* Discovery added
* Influence selected
* Theme resolved
* Theme strengthened

This history enables future personalization and recommendation explanations.

---

#### Influence

Represents anything that inspires a user.

Examples:

* Athlete
* Team
* Movie
* Book
* Song
* Artist
* Character
* Historical Figure
* Military Hero
* Entrepreneur
* Mentor

Each Influence is associated with one or more Narrative Themes.

Example:

Rocky

* Perseverance
* Discipline
* Growth

Aragorn

* Leadership
* Courage
* Service

---

#### InfluenceCatalog

The curated catalog of available influences.

The catalog is intentionally curated rather than AI-generated.

Benefits:

* Explainability
* Consistency
* Internationalization
* Lower operational cost
* Stable Narrative Theme mappings

The InfluenceCatalog is considered a strategic asset of the platform.

---

#### Narrative Theme

Narrative Themes represent universal human concepts.

Examples:

* Courage
* Discipline
* Perseverance
* Leadership
* Service
* Growth
* Sacrifice
* Purpose
* Friendship
* Redemption

Narrative Themes are the primary bridge between:

* Discovery
* Stories
* Music
* Missions
* Reflections
* Recommendations
* Future AI Guidance

Narrative Themes are owned by the Discovery Context but referenced throughout the platform.

---

### Context Boundaries

Discovery owns:

* DiscoveryProfile
* UserDiscovery
* DiscoveryHistory
* Influence
* InfluenceCatalog
* Narrative Theme definitions

Discovery does not own:

* Reflections
* Behavioral Evidence
* Patterns
* Growth Opportunities
* Narrative Guidance

Those belong to the Life Journey Context.

---

### Future Responsibilities

* Theme Resolution
* Recommendation Inputs
* Influence Discovery
* Story Matching
* Music Matching
* Narrative Personalization

Discovery determines what inspires a user.

Life Journey determines how a user is growing.

# Life Journey

Status: Active

Responsibility:

How is this person growing?

Life Journey is currently the primary bounded context.

This context manages:

* Journeys
* Quests
* Missions
* Reflections
* Insights
* Behavioral Evidence

---

## Aggregate Roots

### Journey

Represents a major area of growth.

Examples:

* Health
* Relationships
* Career
* Leadership

Responsibilities:

* Vision
* Chapters
* Quest enrollment

Published Events:

* JourneyCreated
* ChapterAdvanced

---

### Quest

Represents a meaningful challenge.

Contains:

* Mission entities

Responsibilities:

* Mission management
* Completion tracking

Published Events:

* QuestCreated
* MissionCreated
* MissionCompleted
* QuestCompleted

---

### Reflection

Represents structured self-reflection.

Responsibilities:

* Collect responses
* Submission lifecycle
* Insight ownership
* Behavioral Evidence ownership
* Narrative Theme references

Published Events:

* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded


### LifeJourney
Status: Planned

Future aggregate responsible for:

- Cross-journey pattern detection
- Person-level growth tracking
- Growth profile ownership
- Journey coordination

---

## Entities

### Mission

Represents the smallest actionable unit of progress.

Examples:

* Complete workout
* Read a chapter
* Practice gratitude

Owned by:

Quest

---

### ReflectionResponse

Represents a single response within a Reflection.

Current Types:

* JournalResponse
* PromptResponse
* EmojiResponse
* ScaleResponse
* ChoiceResponse
* VoiceResponse
* PhotoResponse

---

## Value Objects

### Insight

A meaningful interpretation derived from reflection.

---

### BehavioralEvidence

An observed indication of behavior.

Examples:

* Discipline
* Courage
* Avoidance
* Vulnerability

Behavioral Evidence is observational.

It is not inherently positive.

---

## Repository Interfaces

Current:

* JourneyRepository
* QuestRepository
* ReflectionRepository

Future:

* PatternRepository
* GrowthProfileRepository

---

## Domain Services

Current:

* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

These are domain ports.

Implementations belong in infrastructure.

---

## Published Events

Current:

* JourneyCreated
* ChapterAdvanced
* QuestCreated
* MissionCreated
* MissionCompleted
* QuestCompleted
* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded

Future:

* PatternDetected
* GrowthOpportunityDetected
* NarrativeGuidanceGenerated

---

## Consumed Events

Future:

* InfluenceAdded
* NarrativeThemeDiscovered

Life Journey may use discovery information to personalize recommendations.

---

# Contribution

Status: Planned

Responsibility:

How is this person helping others grow?

Contribution represents service and impact.

Examples:

* Mentorship
* Coaching
* Acts of service
* Community contribution

---

## Aggregate Roots

Potential:

* ContributionProfile
* ImpactRecord

---

## Published Events

Future:

* ContributionRecorded
* ImpactCreated

---

## Consumed Events

Future:

* GrowthOpportunityDetected
* NarrativeGuidanceGenerated

Contribution may become a natural next step in a person's growth journey.

---

# Cross-Context Integration

The preferred communication mechanism is:

Domain Event
↓
Application Service
↓
Use Case

Avoid:

Aggregate
↓
Direct Aggregate Dependency

---

# Ownership Rules

Identity owns:

* User
* Preferences

Discovery owns:

* Influence
* NarrativeTheme
* DiscoveryProfile

Life Journey owns:

* Journey
* Quest
* Mission
* Reflection
* Insight
* BehavioralEvidence

Contribution owns:

* Impact
* Service
* Mentorship

Ownership should be respected.

Concepts should not be duplicated across contexts.

Prefer identifiers when crossing context boundaries.

Example:

Reflection
↓
NarrativeThemeId

NOT

Reflection
↓
NarrativeTheme

---

# Current Implementation Status

Implemented:

✓ Journey Aggregate

✓ Quest Aggregate

✓ Mission Entity

✓ Reflection Aggregate

✓ Influence Entity

✓ NarrativeTheme Entity

✓ Reflection Responses

✓ Insight

✓ Behavioral Evidence

Partially Implemented:

⚠ Discovery Context

⚠ Narrative Theme Resolution

⚠ Event Pipeline Wiring

Planned:

○ Identity Context

○ Contribution Context

○ DiscoveryProfile Aggregate

○ LifeJourney Aggregate

○ Pattern Detection

○ Growth Opportunities

○ Narrative Guidance

---

# Architectural North Star

Identity
↓
Discovery
↓
Life Journey
↓
Contribution

Understand the Person
↓
Understand what Inspires Them
↓
Help Them Grow
↓
Help Them Help Others
