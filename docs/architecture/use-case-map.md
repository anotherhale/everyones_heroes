# Use Case Map

This document describes the application use cases within Everyone's Heroes.

Use cases orchestrate domain behavior.

Use cases coordinate:

* Aggregates
* Repositories
* Domain Services
* Domain Events

Use cases should not contain business rules that belong inside aggregates.
| Use Case                           | Status      | Context        | Tested |
| ---------------------------------- | ----------- | -------------- | ------ |
| CreateJourneyUseCase              | Implemented | Life Journey   | ✅     |
| CreateQuestUseCase                | Implemented | Life Journey   | ✅     |
| CreateMissionUseCase              | Implemented | Life Journey   | ✅     |
| CompleteMissionUseCase            | Implemented | Life Journey   | ✅     |
| CreateReflectionUseCase           | Implemented | Life Journey   | ✅     |
| SubmitReflectionUseCase           | Implemented | Life Journey   | ✅     |
| AnalyzeReflectionUseCase          | Implemented | Life Journey   | ✅     |
| AdvanceChapterUseCase             | Planned     | Life Journey   | ❌     |
| DetectPatternsUseCase             | Planned     | Life Journey   | ❌     |
| DetectGrowthOpportunitiesUseCase  | Planned     | Life Journey   | ❌     |
| GenerateNarrativeGuidanceUseCase  | Planned     | Life Journey   | ❌     |
| CreateDiscoveryProfileUseCase     | Planned     | Discovery      | ❌     |
| AddDiscoveryUseCase               | Planned     | Discovery      | ❌     |
| SelectInfluenceUseCase            | Planned     | Discovery      | ❌     |
| ResolveNarrativeThemesUseCase     | Planned     | Discovery      | ❌     |
| CreateContributionUseCase         | Planned     | Contribution   | ❌     |
| PublishContributionUseCase        | Planned     | Contribution   | ❌     |
| StartMentorshipUseCase            | Planned     | Contribution   | ❌     |
---

# Use Case Principles

Use cases are responsible for:

* Loading aggregates
* Coordinating behavior
* Persisting changes
* Publishing events

Use cases are not responsible for:

* Owning business rules
* Performing persistence directly
* Containing UI logic

---

# Current Contexts

Implemented:

* Life Journey

Planned:

* Discovery
* Identity
* Contribution

---

# Life Journey Context

Status: Active

---

# Journey Use Cases

## CreateJourneyUseCase

Status:

Implemented

Purpose:

Create a new Journey.

Flow:

Create Journey
↓
Persist Journey
↓
Publish JourneyCreated

Dependencies:

* JourneyRepository

Events:

* JourneyCreated

---

## AdvanceChapterUseCase

Status:

Future

Purpose:

Advance a Journey to the next Chapter.

Potential Flow:

Load Journey
↓
Advance Chapter
↓
Persist Journey
↓
Publish ChapterAdvanced

Dependencies:

* JourneyRepository

Events:

* ChapterAdvanced

---

# Quest Use Cases

## CreateQuestUseCase

Status:

Implemented

Purpose:

Create a new Quest within a Journey.

Flow:

Load Journey
↓
Create Quest
↓
Persist Quest
↓
Update Journey
↓
Publish QuestCreated

Dependencies:

* JourneyRepository
* QuestRepository

Events:

* QuestCreated

Notes:

Current implementation should be reviewed to ensure Journey persistence is properly tested.

---

## CreateMissionUseCase

Status:

Implemented

Purpose:

Create a Mission within a Quest.

Flow:

Load Quest
↓
Create Mission
↓
Persist Quest
↓
Publish MissionCreated

Dependencies:

* QuestRepository

Events:

* MissionCreated

---

## CompleteMissionUseCase

Status:

Implemented

Purpose:

Complete a Mission.

Flow:

Load Quest
↓
Complete Mission
↓
Persist Quest
↓
Publish MissionCompleted

Possible Outcome:

MissionCompleted
↓
QuestCompleted

Dependencies:

* QuestRepository

Events:

* MissionCompleted
* QuestCompleted

---

# Reflection Use Cases

Reflection is one of the primary workflows in the platform.

---

## CreateReflectionUseCase

Status:

Implemented

Purpose:

Create a Reflection.

Flow:

Create Reflection
↓
Persist Reflection

Dependencies:

* ReflectionRepository

Events:

None

---

## SubmitReflectionUseCase

Status:

Implemented

Purpose:

Submit a Reflection.

Flow:

Load Reflection
↓
Submit Reflection
↓
Persist Reflection
↓
Publish ReflectionSubmitted

Dependencies:

* ReflectionRepository

Events:

* ReflectionSubmitted

---

## AnalyzeReflectionUseCase

Status:

Implemented

Purpose:

Generate analysis from a submitted Reflection.

Current Flow:

Load Reflection
↓
Extract Insights
↓
Analyze Behavioral Evidence
↓
Resolve Narrative Themes
↓
Update Reflection
↓
Persist Reflection

Dependencies:

* ReflectionRepository
* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

Events:

* InsightsGenerated
* BehavioralEvidenceDetected
* NarrativeThemesAdded

Notes:

Current implementation represents the first stage of the reflection intelligence pipeline.

---

# Reflection Analysis Pipeline

Current

ReflectionSubmitted
↓
AnalyzeReflectionUseCase
↓
InsightsGenerated
↓
BehavioralEvidenceDetected
↓
NarrativeThemesAdded

Future

ReflectionSubmitted
↓
AnalyzeReflectionUseCase
↓
PatternDetectionUseCase
↓
GrowthOpportunityDetectionUseCase
↓
NarrativeGuidanceUseCase

---

# Discovery Use Cases

Status:

Planned

---

## CreateDiscoveryProfileUseCase

Status:

Future

Purpose:

Create a Discovery Profile for a user.

Dependencies:

* DiscoveryProfileRepository

---

## AddInfluenceUseCase

Status:

Future

Purpose:

Add an Influence to a Discovery Profile.

Dependencies:

* DiscoveryProfileRepository

Events:

* InfluenceAdded

---

## RemoveInfluenceUseCase

Status:

Future

Purpose:

Remove an Influence from a Discovery Profile.

Dependencies:

* DiscoveryProfileRepository

Events:

* InfluenceRemoved

---

## DiscoverNarrativeThemesUseCase

Status:

Future

Purpose:

Identify Narrative Themes from selected Influences.

Dependencies:

* NarrativeThemeResolver

Events:

* NarrativeThemeDiscovered

---

# Pattern Detection Use Cases

Status:

Future

These use cases are intentionally deferred.

See ADR-008 and ADR-013.

---

## DetectPatternsUseCase

Status:

Future

Purpose:

Detect recurring behavioral patterns.

Flow:

Behavioral Evidence
↓
Pattern Detection
↓
Pattern Creation

Potential Outputs:

* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern

Dependencies:

* PatternRepository

---

## DetectGrowthOpportunitiesUseCase

Status:

Future

Purpose:

Identify growth opportunities from patterns.

Flow:

Patterns
↓
Opportunity Detection
↓
Growth Opportunities

Dependencies:

* PatternRepository

---

# Narrative Guidance Use Cases

Status:

Future

See ADR-013 Evidence Before Guidance.

---

## GenerateNarrativeGuidanceUseCase

Status:

Future

Purpose:

Generate personalized guidance.

Flow:

Behavioral Evidence
↓
Patterns
↓
Growth Opportunities
↓
Narrative Guidance

Dependencies:

* GrowthProfileRepository
* NarrativeThemeRepository

Outputs:

* Recommendations
* Encouragement
* Reflection Prompts
* Suggested Missions

---

# Contribution Use Cases

Status:

Future

---

## RecordContributionUseCase

Status:

Future

Purpose:

Record acts of contribution and service.

Dependencies:

* ContributionRepository

Events:

* ContributionRecorded

---

# Event Driven Use Cases

Future architecture will increasingly trigger use cases through events.

Example:

ReflectionSubmitted
↓
AnalyzeReflectionUseCase

BehavioralEvidenceDetected
↓
DetectPatternsUseCase

PatternDetected
↓
DetectGrowthOpportunitiesUseCase

GrowthOpportunityDetected
↓
GenerateNarrativeGuidanceUseCase

NarrativeGuidanceGenerated
↓
RecommendationUseCase

---

# Current Refactoring Notes

Known architectural drift:

* Use cases currently exist in multiple locations.
* Some use cases implement a UseCase interface.
* Others are simple classes.
* Consolidation is planned.

Desired Future Structure:

lib/features/life_journey/
└── application/
└── use_cases/

All Life Journey use cases should eventually reside within a single application layer.

---

# Use Case Dependency Rules

Use Cases May Depend On:

* Aggregates
* Repositories
* Domain Services

Use Cases Must Not Depend On:

* Widgets
* Screens
* Riverpod UI State
* Infrastructure SDKs

---

# Architectural North Star

Challenge
↓
Action
↓
Reflection
↓
Behavioral Evidence
↓
Patterns
↓
Growth Opportunities
↓
Narrative Guidance
↓
Contribution

Use cases are the orchestration layer that moves the user through this journey while keeping business rules inside the domain model.

# Discovery Use Cases

Status: Planned

The Discovery Context is responsible for understanding what inspires a user.

Discovery should produce:

* Influences
* Narrative Themes
* Discovery Insights

that can be used throughout the platform.

---

## CreateDiscoveryProfileUseCase

Status:

Future

Purpose:

Create a Discovery Profile for a user.

Flow:

Create DiscoveryProfile
↓
Persist DiscoveryProfile

Dependencies:

* DiscoveryProfileRepository

Events:

* DiscoveryProfileCreated

---

## AddDiscoveryUseCase

Status:

Future

Purpose:

Add a new discovery to a user's Discovery Profile.

Examples:

* Favorite Book
* Favorite Movie
* Favorite Character
* Personal Hero
* Inspirational Quote

Flow:

Load DiscoveryProfile
↓
Add Discovery
↓
Persist DiscoveryProfile
↓
Publish DiscoveryAdded

Dependencies:

* DiscoveryProfileRepository

Events:

* DiscoveryAdded

---

## SelectInfluenceUseCase

Status:

Future

Purpose:

Associate an Influence with a user's Discovery Profile.

Examples:

* Michael Jordan
* Rocky Balboa
* Aragorn
* David Goggins

Flow:

Load DiscoveryProfile
↓
Select Influence
↓
Resolve Narrative Themes
↓
Persist DiscoveryProfile
↓
Publish InfluenceSelected

Dependencies:

* DiscoveryProfileRepository
* InfluenceRepository

Events:

* InfluenceSelected

---

## ResolveThemesUseCase

Status:

Future

Purpose:

Resolve Narrative Themes from a user's selected influences and discoveries.

Flow:

Load DiscoveryProfile
↓
Resolve Themes
↓
Update DiscoveryProfile
↓
Publish NarrativeThemesDiscovered

Dependencies:

* NarrativeThemeResolver
* DiscoveryProfileRepository

Events:

* NarrativeThemesDiscovered

---

# Contribution Use Cases

Status: Planned

The Contribution Context focuses on helping others grow.

Contribution represents the outward expression of personal growth.

---

## CreateContributionUseCase

Status:

Future

Purpose:

Create a contribution opportunity or contribution record.

Examples:

* Mentorship
* Service Project
* Coaching Session
* Community Support

Flow:

Create Contribution
↓
Persist Contribution
↓
Publish ContributionCreated

Dependencies:

* ContributionRepository

Events:

* ContributionCreated

---

## PublishContributionUseCase

Status:

Future

Purpose:

Make a contribution visible to the community.

Flow:

Load Contribution
↓
Publish Contribution
↓
Persist Contribution
↓
Publish ContributionPublished

Dependencies:

* ContributionRepository

Events:

* ContributionPublished

---

## StartMentorshipUseCase

Status:

Future

Purpose:

Create a mentorship relationship between users.

Flow:

Create Mentorship
↓
Persist Relationship
↓
Publish MentorshipStarted

Dependencies:

* ContributionRepository
* UserRepository

Events:

* MentorshipStarted

---

# Future Narrative Intelligence Pipeline

Status: Planned

The platform is evolving toward an evidence-driven growth architecture.

Preferred Flow:

ReflectionSubmitted
↓
AnalyzeReflectionUseCase
↓
BehavioralEvidenceDetected
↓
DetectPatternsUseCase
↓
PatternDetected
↓
DetectGrowthOpportunitiesUseCase
↓
GrowthOpportunityDetected
↓
GenerateNarrativeGuidanceUseCase
↓
NarrativeGuidanceGenerated
↓
RecommendationUseCase

---

## DetectPatternsUseCase

Status:

Future

Purpose:

Identify recurring behavioral patterns across reflections.

Inputs:

* Behavioral Evidence
* Reflection History

Outputs:

* Strength Patterns
* Avoidance Patterns
* Emerging Growth Patterns

Dependencies:

* PatternRepository

Events:

* PatternDetected

---

## DetectGrowthOpportunitiesUseCase

Status:

Future

Purpose:

Identify growth opportunities from observed patterns.

Inputs:

* Behavioral Patterns

Outputs:

* Growth Opportunities

Dependencies:

* PatternRepository

Events:

* GrowthOpportunityDetected

---

## GenerateNarrativeGuidanceUseCase

Status:

Future

Purpose:

Generate personalized guidance grounded in:

* Behavioral Evidence
* Narrative Themes
* Behavioral Patterns
* Growth Opportunities

Outputs:

* Encouragement
* Recommendations
* Reflection Prompts
* Mission Suggestions
* Story Recommendations

Dependencies:

* NarrativeThemeRepository
* PatternRepository
* GrowthProfileRepository

Events:

* NarrativeGuidanceGenerated

---

## Architectural Principle

See:

AD-013 Evidence Before Guidance

Preferred:

Behavioral Evidence
↓
Patterns
↓
Growth Opportunities
↓
Narrative Guidance

Avoid:

Behavioral Evidence
↓
Narrative Guidance

Guidance should remain explainable and traceable to observable evidence.
