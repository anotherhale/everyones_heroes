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

# Behavior Pattern

A recurring behavioral trend that emerges from accumulated Behavioral Evidence.

Examples:

* Consistency
* Leadership
* Avoidance
* Resilience

Patterns represent long-term behavior rather than isolated observations.

---

# Behavioral Evidence

A deterministic observation derived from structured user interactions.

Behavioral Evidence represents facts.

It never represents conclusions.

Behavioral Evidence is intentionally explainable and traceable.

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

A meaningful opportunity for future development identified from one or more Behavior Patterns.

Growth Opportunities are deterministic recommendations for where growth could occur next.

They do not determine how growth should be communicated.

Examples:

* Avoiding difficult conversations
* Inconsistent follow-through
* Underutilized strengths

Growth Opportunities should guide reflection and action.

Current Status:
Future concept.

---

# Personalization Engine

The central orchestration engine of Everyone's Heroes.

Its purpose is to determine the most inspiring experience for a particular individual at a particular moment.

Inputs include:

* Discovery Profile
* Behavioral Evidence
* Behavior Patterns
* Growth Opportunities
* Narrative Themes
* Current Journey
* Historical Progress
* Subscription Tier
* Purchased AI Capabilities

Outputs may include:

* Missions
* Reflection prompts
* Hero stories
* Motivational talks
* Personalized music
* Song lyrics
* Coaching
* Push notifications
* Future adaptive experiences

The Personalization Engine is the heart of the platform.

Current Status:
Future concept / not currently an implemented bounded context or engine.
Existing adaptive Story selection uses Life Journey application
`AdaptiveDiscoverySignals`, not a Personalization Engine.
`DiscoveryProfile.inspiringHeroIds` is **not** currently an input (D.13 —
Not Yet).

---

# Deterministic Personalization

Personalization driven entirely by deterministic business rules and structured evidence.

This is the default implementation for the free and basic subscription tiers.

Deterministic personalization emphasizes explainability, repeatability, and predictable behavior.

---

# AI Personalization

Personalization that uses AI to creatively generate experiences while remaining grounded in deterministic understanding.

AI does not determine behavioral truth.

AI transforms deterministic understanding into emotionally engaging experiences such as stories, coaching, music, narration, voice performance, and personalized motivational talks.

Creative direction may eventually propose how an experience is heard (pace, emotion, voice, music). That proposal is not behavioral truth. See `Voice-Cloning-and-Story-Performance-Architecture.md`.

---

# Inspiration

The desired outcome of personalization.

The platform does not optimize for engagement alone.

It optimizes for helping an individual take meaningful action by presenting the right experience at the right time.

---

# Personal Hero Journey

The lifelong process through which an individual grows, discovers purpose, overcomes challenges, and ultimately helps others grow.

This is the unifying concept behind the entire platform.

---

# Adaptive Experience

Any personalized experience generated specifically for an individual.

Examples include:

* A mission
* A hero story
* An AI-generated motivational speech
* Personalized music
* Dynamic lyrics
* Coaching conversations
* Personalized audio journeys
* Future immersive experiences

The platform is intentionally designed so new Adaptive Experience types can be introduced without changing the core domain model.
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

# Inspiring Hero

A Hero that a seeker has explicitly marked as inspiring through the Discovery
experience (“Inspires Me”).

Stored as `DiscoveryProfile.inspiringHeroIds` (D.11).

An Inspiring Hero is:

* explicit
* user-selected
* private
* current-state
* unordered / set-like

An Inspiring Hero is **not** currently:

* a recommendation instruction
* a Story affinity
* a Narrative Theme
* Behavioral Evidence
* a Behavior Pattern
* a Followed Hero
* a social relationship

Its future role in Personalization is intentionally unresolved (**D.13 —
Not Yet**). Do not infer Today, ranking, theme, behavioral, or personalization
behavior from the existence of the field.

Distinct from Influence: Influences are curated recommendation primitives that
may resolve into Narrative Themes; Inspiring Heroes are EH Hero aggregates the
seeker has privately marked as inspiring.

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

# Discovery Activity

A small intentional interaction designed to improve the platform's understanding of an individual.

Examples:

* Favorite hero
* Inspirational quote
* Music preference
* Reflection prompt
* Story selection
* Mission preference

Discovery Activities gradually build the Discovery Profile over time.

---

# Discovery Profile

The platform's continuously evolving understanding of an individual.

The Discovery Profile combines:

* Discoveries
* Influences
* Narrative Themes
* Motivational Preferences
* Storytelling Preferences
* Music Preferences
* Behavioral Patterns
* Growth Opportunities

Current Flutter-local DiscoveryProfile also stores `inspiringHeroIds` (D.11) —
an explicit private Inspiring Hero preference whose downstream meaning is
**Not Yet** defined (D.13 / D-ADR-001). That field is not currently a
personalization or ranking input.

The Discovery Profile is intended as a primary input into **future**
personalization. A Personalization Engine / bounded context is not currently
implemented.

Current Status:
Partial — local DiscoveryProfile foundation exists; full profile synthesis and
personalization consumption remain incomplete / future.

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

# Voice Identity

The identity of the speaker represented by a voice-generation system.

In the current EH model this concept is the `VoiceProfile` aggregate (HS-ADR-078, HS.12.9): a Hero-scoped, provider-independent identity. It is not a Qwen speaker label, an OpenAI voice name, or a generated audio file.

A Voice Identity may later be used for many performances. Creating or changing a performance does not create a new identity.

Current Status:
`VoiceProfile` foundation implemented. Production voice cloning is not implemented.

---

# Voice Reference

Audio and associated metadata used to reproduce a Voice Identity.

Includes the reference recording and, as architectural direction, a reviewed reference transcript stored with the enrollment. Reference bytes stay behind a media storage port. They are not embedded in the aggregate and they are not Story canonical media.

Current Status:
`VoiceProfile` may hold `MediaReference` entries. Durable reference-transcript metadata and production enrollment are not implemented. The local Qwen Base/ICL enrollment flow is a prototype outside this repository.

---

# Voice Performance

The manner in which a voice delivers content.

Voice Performance is not Voice Identity and not Audio Production.

HS-ADR-079: the first domain vocabulary, when implemented, is experience-level **delivery** (with a grounded rationale) on `StoryExperiencePlan`. Emotion, energy, pace, emphasis, and pause are not separate domain fields. Energy stays on music direction. Emphasis stays on key moments. Pauses stay in playback or audio production.

Current Status:
Not an implemented domain type.

---

# Performance Intent

Provider-neutral instructions describing desired spoken delivery.

HS-ADR-079: this is the name of the future delivery guidance on `StoryExperiencePlan`. It is not a separate value object beside that guidance, and it is not `temperature`, `top_p`, `speed`, or `instruct`.

Provider adapters translate the delivery string into whatever a given TTS system actually supports.

Current Status:
Architectural term. Not implemented. See `Story-Performance-Representation-Spike.md`.

---

# Story Performance

The application of performance intent to a Story experience.

The canonical pre-render representation is experience-level delivery guidance on `StoryExperiencePlan` (HS-ADR-079). Story Performance is not an aggregate, not a field on `Story` or `VoiceProfile`, and not the generated audio. `StoryVoiceRendering` stores the audio artifact. The canonical Story remains the narrative.

Current Status:
Boundary decided. Not implemented. The Story Performance Editor does not exist.

---

# Voice Generation

The process of transforming textual story content and a Voice Identity into audio.

Today, synthetic narration uses `VoiceRenderingPort` and does not require a VoiceProfile. Future profile-backed or performance-aware generation stays behind a provider-neutral port. Domain and application code do not call a TTS vendor.

Current Status:
Synthetic narration implemented (HS.12.6 / HS.12.7). Cloning and performance-aware generation are not implemented.

---

# Audio Production

The assembly and processing of generated voice segments, silence, music, and other audio elements into a final audio experience.

Audio Production is not voice identity and not the wording of the Story. Intermediate segment assets remain distinct from the final mix.

Current Status:
Local sentence-assembly experiment is prototype / under validation. Not an EH product pipeline.

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