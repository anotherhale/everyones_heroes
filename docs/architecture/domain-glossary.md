# Domain Glossary

This document defines the ubiquitous language of Everyone's Heroes.

When introducing new concepts, terminology should align with this glossary whenever possible.

---

# Core Philosophy

Everyone's Heroes helps people:

Challenge
↓
Action
↓
Reflection
↓
Growth
↓
Contribution

The platform is designed around personal growth through intentional action and reflection.

---

# Person

The human using the platform.

A person may participate in multiple journeys simultaneously.

Growth belongs to the person, not to a single journey.

---

# Life Journey

A collection of journeys representing a person's broader growth experience.

Future aggregate root.

Potential responsibilities:

* Journey ownership
* Cross-journey pattern detection
* Person-level growth profile
* Long-term narrative guidance

Current Status:
Not yet implemented.

---

# Journey

A significant area of intentional growth.

Examples:

* Health Journey
* Relationship Journey
* Career Journey
* Spiritual Journey
* Leadership Journey

A Journey provides context for growth.

A Journey does not own growth itself.

---

# Chapter

A stage within a Journey.

Examples:

* Getting Started
* Building Consistency
* Expanding Capacity
* Leadership

Chapters represent progression within a Journey.

---

# Quest

A meaningful challenge within a Journey.

Examples:

* Run a 5K
* Improve Communication
* Build a Meditation Habit

A Quest contains one or more Missions.

---

# Mission

The smallest actionable unit of progress.

Examples:

* Complete today's workout
* Read one chapter
* Practice gratitude

Missions are completed through action.

---

# Reflection

A structured act of self-reflection.

Reflections capture experiences, thoughts, emotions, and observations.

Reflections are one of the most important aggregates in the platform.

Lifecycle:

Create
↓
Add Responses
↓
Submit
↓
Analyze

Once submitted, responses become immutable.

---

# Reflection Response

A single piece of information collected during a Reflection.

Supported types:

* JournalResponse
* PromptResponse
* EmojiResponse
* ScaleResponse
* ChoiceResponse
* VoiceResponse
* PhotoResponse

Reflection Responses allow adaptive reflection experiences.

Different users may reflect in different ways.

---

# Insight

A meaningful interpretation generated from a Reflection.

Examples:

* "You seem more confident when discussing leadership."
* "You consistently frame challenges as learning opportunities."

Insights are interpretations.

Insights are not facts.

Insights should always be traceable to reflection data.

---

# Behavioral Evidence

An observed indication of behavior found within a Reflection.

Behavioral Evidence is observational.

Behavioral Evidence is not inherently positive or negative.

BehavioralEvidence
├── BehavioralEvidenceType
├── EvidenceSource
│   ├── ReflectionEvidenceSource
│   └── MissionEvidenceSource
└── Strength

BehavioralEvidenceType:

### Positive Behaviors

* Discipline
* Confidence
* Resilience
* Consistency
* Courage
* Leadership
* Service
* Responsibility
* Self-Awareness
* Purpose
* Connection
* Vulnerability

### Growth Opportunities

* Avoidance
* Fear
* Procrastination
* Indecision
* Self-Sabotage
* Perfectionism
* Impulsivity
* Defensiveness
* Blame
* Dishonesty
* Entitlement

Behavioral Evidence is the foundation for future pattern detection.

# Evidence Source
The origin of Behavioral Evidence.

Examples:
- Reflection
- Mission
Pattern
A recurring trend derived from Behavioral Evidence.

---

# Behavioral Signal Type (deprecated)

A classification describing the type of behavior represented by Behavioral Evidence.

Examples:

* Discipline
* Resilience
* Courage
* Curiosity
* Vulnerability
* Consistency
* Avoidance

Current Status:

BehavioralSignalType currently removed from code.

Future naming may evolve as the behavioral model matures.

---

# Pattern

A repeated behavioral trend observed across multiple reflections.

Examples:

* Strength Pattern
* Avoidance Pattern
* Emerging Growth Pattern
* Growth Opportunity Pattern

Patterns are derived from Behavioral Evidence.

Patterns should not be manually created.

Current Status:
Future concept.

---

# Growth Opportunity

A potential area where growth may occur.

Growth Opportunities emerge from patterns.

Examples:

* Avoiding difficult conversations
* Inconsistent follow-through
* Underutilized strengths

Growth Opportunities should guide reflection and action.

Current Status:
Future concept.

---

# Narrative Guidance

Personalized coaching generated from a person's reflections, patterns, influences, and themes.

Narrative Guidance helps users:

* Recognize strengths
* Overcome obstacles
* See opportunities
* Maintain momentum

Current Status:
Future concept.

---

# Influence

A person, character, team, book, song, movie, or other source of inspiration.

Examples:

* Michael Jordan
* Rocky Balboa
* Aragorn
* Atomic Habits
* Navy SEALs

Influences are recommendation primitives.

They help the system understand what inspires a user.

---

# Influence Category

The classification of an Influence.

Current examples:

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
* Creator
* Coach

---

# Narrative Theme

A recurring story pattern represented across influences, reflections, stories, and recommendations.

Examples:

* Perseverance
* Redemption
* Courage
* Service
* Sacrifice
* Growth
* Leadership

Narrative Themes are one of the central organizing concepts of the platform.

Ownership belongs to the Discovery bounded context.

Other contexts reference NarrativeThemeId.

---

# Discovery

The process of understanding what inspires a person.

Discovery helps identify:

* Influences
* Narrative Themes
* Motivators
* Aspirations

Discovery drives personalization.

---

# Discovery Profile

A future aggregate responsible for storing a person's discovery information.

Potential responsibilities:

* Selected influences
* Narrative themes
* Recommendation preferences

Current Status:
Not yet implemented.

---

# Behavioral Evidence Analyzer

A domain service responsible for identifying Behavioral Evidence from Reflection data.

The analyzer produces observations.

It does not produce guidance.

---

# Insight Extraction Service

A domain service responsible for generating Insights from Reflection data.

The service extracts interpretations.

It does not make coaching decisions.

---

# Narrative Theme Resolver

A domain service responsible for associating Reflection content with Narrative Themes.

The resolver connects experiences to story patterns.

---

# Recommendation

A suggested action, influence, mission, story, or reflection.

Recommendations should be grounded in:

* Behavioral Evidence
* Narrative Themes
* Influences
* Patterns

Recommendations should not be arbitrary.

---

# Event

A record of something meaningful that happened in the domain.

Examples:

* JourneyCreated
* QuestCompleted
* ReflectionSubmitted
* InsightsGenerated
* BehavioralEvidenceDetected

Events are used to communicate across bounded contexts.

---

# Guiding Principle

Prefer:

Evidence
↓
Patterns
↓
Guidance

Over:

Assumptions
↓
Scores
↓
Conclusions

Store observations.
Derive patterns.
Generate guidance.

Evidence
    ↓
Patterns
    ↓
Guidance