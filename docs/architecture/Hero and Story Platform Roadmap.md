# Everyone's Heroes

## Hero & Story Platform Roadmap

**Status:** Proposed Roadmap
**Scope:** Hero & Story Platform
**Current Story Builder:** SB.0–SB.13
**Companion (execution):** `docs/architecture/Hero and Story Platform Implementation Master Plan.md`
**Latest checkpoint:** `docs/analysis/HS-architecture-checkpoint.md`
**Architectural North Star:** Stories become a trustworthy source of human experience that can eventually participate in discovery and personalized growth experiences.

---

# 1. Purpose

The Hero & Story platform expands Everyone's Heroes from understanding an individual's own journey into a platform through which people can discover the experiences, struggles, lessons, perspectives, and stories of other human beings.

The product direction is:

```text
Heroes
   ↓
Stories
   ↓
Themes
   ↓
Challenges
   ↓
Lessons
   ↓
Discovery
   ↓
Personalized Experience
```

This eventually converges with the existing personal-growth loop:

```text
Experience
   ↓
Action
   ↓
Reflection
   ↓
Understanding
   ↓
Personalization
   ↓
Growth
   ↓
New Experience
```

The long-term architecture therefore becomes:

```text
                         USER
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
      Personal Journey          Hero & Story
       Understanding             Ecosystem
             │                         │
             │                  Stories / Themes
             │                         │
             └────────────┬────────────┘
                          ▼
                     Discovery
                          ▼
                  Personalization
                          ▼
                    Experience
                          ▼
                       Action
                          ▼
                     Reflection
                          ▼
                    Understanding
```

The user's experience is transformation.

The platform's responsibility is to preserve trustworthy evidence and understanding that can support increasingly meaningful experiences.

---

# 2. Architectural Principles

The Hero & Story platform must preserve the following principles established in the foundation.

### Story is canonical

A Story is the human experience artifact.

Media is not the Story.

Representations may include:

- Original audio
- Transcript
- Written narrative
- Script
- Video
- Localized representations

A Story may have multiple representations.

### AI is not authoritative

AI may help:

- understand a Story
- transform a Story
- create alternate representations
- assist discovery
- create experiences

AI does not become the source of truth about the Hero or their lived experience.

### Provenance survives transformation

The platform must always be able to answer:

```text
Where did this content come from?
Who authored it?
What was derived?
What was transformed?
What did AI produce?
What did the Hero approve?
```

### Hero approval matters

AI-generated or transformed material does not become Hero-authored merely because the Hero reviews it.

Origin remains origin.

Hero intervention and approval are separate pieces of provenance.

### Classification is not personalization

Story classification describes the Story.

Personalization describes its potential relevance to another person.

Those concerns remain separate.

### Story interaction is not automatically behavioral evidence

Viewing, listening to, liking, or interacting with a Story does not automatically establish that the user demonstrated a behavior or experienced growth.

Behavioral Evidence remains grounded in actual observations.

### Discovery owns Narrative Themes

Hero & Story may reference themes but must not create a competing definition of Narrative Theme.

### Replaceable infrastructure

The domain must not become coupled to:

- a particular search engine
- AI provider
- media provider
- storage provider
- recommendation engine

---

# 3. Where We Are Now

The Story Builder has established a substantial authoring pipeline:

```text
StoryBuilderSession
        ↓
Story Understanding
        ↓
Story Proposal
        ↓
Deterministic / AI Shaping
        ↓
Hero Review
        ↓
Explicit Approval
        ↓
SB.13
Story Materialization
        ↓
CANONICAL STORY
```

SB.13 is therefore the transition point between:

**creating and approving a Story proposal**

and

**owning a canonical Story in the Hero & Story domain.**

After SB.13, we should stop extending the Story Builder simply for the sake of extending it.

The work becomes Hero & Story Platform work.

---

# 4. Roadmap at a Glance

```text
STORY CREATION
────────────────────────────────────────────

SB.0–SB.13
Story Builder
    │
    ▼
Canonical Story
    │
    ├───────────────────┐
    │                   │
    ▼                   ▼
Representations      Story Lifecycle
    │                   │
    └─────────┬─────────┘
              ▼
         Story Catalog
              │
              ▼
       Story Discovery
              │
              ▼
        Hero Experience
              │
              ▼
    Adaptive Hero Discovery
              │
              ▼
      Personalized Experience
```

The major Hero & Story roadmap is:

| Phase    | Capability          | Outcome                                       |
| -------- | ------------------- | --------------------------------------------- |
| **HS.1** | Foundation          | Canonical Hero/Story domain                   |
| **HS.2** | Catalog Foundation  | Structured, multilingual Story classification |
| **HS.3** | Story Capture       | Production Story representations              |
| **HS.4** | Story Understanding | Structured understanding contracts            |
| **HS.5** | Story Authoring     | Hero-approved transformations                 |
| **HS.6** | Discovery           | Search, filtering, catalog browsing           |
| **HS.7** | Hero Experience     | Hero profiles, Stories, playback, collections |
| **HS.8** | Adaptive Discovery  | Personalized Hero/Story discovery             |

However, several HS capabilities have already been implemented or partially implemented through later work. Therefore the roadmap should now be treated as a **capability roadmap**, not as a strict historical implementation sequence.

---

# 5. HS.1 — Hero & Story Foundation

### Objective

Establish the canonical Hero & Story bounded context.

### Core capabilities

- Hero aggregate
- Story aggregate
- Story identity
- Hero ownership
- Story lifecycle
- Story provenance
- visibility
- classification foundations
- language foundations
- repository contracts
- application contracts
- domain events where justified

### Architectural boundary

```text
Hero
  │
  └── owns
        │
        ▼
      Story
```

The Story domain must not depend on:

- Story Builder UI
- AI proxy
- Riverpod
- search infrastructure
- personalization
- media infrastructure

### Exit condition

A canonical Story can exist independently of how it was created.

---

# 6. HS.2 — Story Catalog Foundation

### Objective

Make Stories structurally discoverable without prematurely building a recommendation engine.

### Catalog dimensions

The foundation identifies dimensions including:

- Narrative Theme
- content suitability
- spirituality
- religion
- language
- audience
- format
- geography
- other explicit catalog metadata

### Important distinction

```text
Classification
      ≠
Personalization
```

Classification describes what a Story is.

Personalization determines whether it may be relevant to someone.

### Exit condition

A Story can be represented consistently in a catalog without embedding recommendation logic into the Story domain.

---

# 7. HS.3 — Story Representation & Capture

### Objective

Establish production-grade representations of canonical Stories.

The architecture treats:

```text
Story
 ├── Original Audio
 ├── Transcript
 ├── Written Narrative
 ├── Script
 ├── Video
 └── Localized Representations
```

as representations of the same underlying Story.

### Capabilities

- recording
- audio persistence
- transcript persistence
- representation provenance
- representation lifecycle
- language association
- review
- representation replacement/versioning where required

### Existing work to reuse

The existing HS.9 recording/capture infrastructure should be treated as the implementation foundation rather than recreated.

### Exit condition

A canonical Story can have one or more durable, provenance-aware representations.

---

# 8. HS.4 — Story Understanding

### Objective

Turn Story representations into structured understanding without changing the canonical Story.

### Understanding may include

- transcription
- narrative structure
- themes
- classification
- structured story elements
- summaries
- other derived analysis

### Critical boundary

```text
Canonical Story
      │
      ▼
Understanding
      │
      ▼
Derived analysis
```

Understanding is derived.

It does not become a second Story.

### Existing work

The existing HS.4/SB.8 work provides important precedent:

- deterministic fallback
- replaceable AI implementation
- no AI ownership of the canonical Story
- derived understanding
- no unnecessary persistence of transient analysis

### Exit condition

The platform can understand a Story without modifying its source of truth.

---

# 9. HS.5 — Story Authoring & Approval

### Objective

Allow the Hero to transform, refine, and approve Story representations while preserving provenance.

The completed Story Builder work provides the foundation for this capability.

```text
Hero-authored material
        │
        ▼
Story Proposal
        │
   ┌────┴────┐
   │         │
   ▼         ▼
Guided      AI-assisted
   │         │
   └────┬────┘
        ▼
Hero Review
        ▼
Explicit Approval
        ▼
Story Materialization
```

### Rules

- AI output remains derived.
- Hero edits do not erase origin.
- Approval is explicit.
- Rejection is explicit.
- Accepted proposals remain retryable until materialization succeeds.
- Story creation is separate from publication.

### SB.13 relationship

SB.13 is the final Story Builder slice required to cross this boundary.

---

# 10. SB.13 — Story Materialization Checkpoint

Although SB.13 is a Story Builder slice, it is also the bridge into the Hero & Story platform.

### Objective

Convert:

```text
Accepted StoryProposal
        ↓
Canonical Story
```

### Requirements

Only:

```text
StoryProposal.lifecycle == accepted
```

may be materialized.

Materialization must:

- resolve authoritative Hero ownership
- create the existing Story aggregate
- preserve title/narrative
- preserve provenance
- preserve Hero-authored vs AI-derived origin
- enter an existing non-published Story state
- remain non-public
- be idempotent
- avoid duplicate Stories
- leave the accepted proposal intact on failure

### Critical distinction

```text
Materialization
      ≠
Publication
```

This is the architectural checkpoint between Story creation and Story distribution.

---

# 11. HS.6 — Hero & Story Discovery

### Objective

Make canonical Stories and Heroes discoverable.

### Capabilities

- Story search
- Hero search
- structured filtering
- catalog browsing
- language filtering
- suitability filtering
- theme filtering
- geography filtering
- format filtering
- discovery contracts

### Architecture

```text
Hero & Story Domain
        │
        ▼
Application Discovery Contracts
        │
        ▼
Search / Catalog Adapter
```

The domain must not know which search engine implements discovery.

### Product principle

Discovery should favor:

```text
Meaning
Connection
Depth
Serendipity
```

rather than simply:

```text
Popularity
Engagement
Infinite scrolling
```

### Exit condition

A user can intentionally explore Heroes and Stories using explicit catalog dimensions.

---

# 12. HS.7 — Hero Experience

### Objective

Turn the catalog into a meaningful human experience.

### Capabilities

### Hero profiles

A Hero profile should present grounded information about the person and their Stories.

It should avoid unsupported psychological or behavioral claims.

### Story browsing

Users can:

- browse Stories
- open a Story
- inspect available representations
- select language
- understand Story context

### Story playback

Users can consume:

- audio
- video
- written narrative
- other available representations

### Hero journeys

A Hero may eventually have multiple Stories that reveal a broader journey.

### Collections

Stories can eventually participate in meaningful collections without turning the platform into a generic social feed.

### Exit condition

A user can move naturally from:

```text
Hero
  ↓
Story
  ↓
Experience
```

---

# 13. HS.8 — Adaptive Hero Discovery

### Objective

Connect the Hero & Story ecosystem to the existing understanding and personalization architecture.

The foundation specifies:

```text
User Understanding
        +
Discovery Profile
        +
Hero & Story Catalog
        ↓
Personalized Hero Discovery
```

### Important boundary

Adaptive discovery belongs outside the Story domain.

The Story domain provides grounded catalog information.

The personalization system determines relevance.

### Inputs may eventually include

- user interests
- Narrative Themes
- current context
- Journey understanding
- Discovery Profile
- preferences
- previous experiences
- Story catalog metadata

### Output

Not merely:

> "You may also like..."

but potentially:

> "This experience may be meaningful for you because..."

with an explanation grounded in known information.

### Exit condition

Hero & Story becomes an input to the adaptive experience engine without taking ownership of personalization.

---

# 14. Beyond HS.8 — The Experience Layer

HS.8 should not be treated as the end of the product.

It establishes the connection between Hero & Story and the larger Everyone's Heroes experience architecture.

The longer-term architecture becomes:

```text
                 HERO & STORY
                      │
              Stories / Themes
                      │
                      ▼
                 Discovery
                      │
                      ▼
              Personalization
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
     Mission      Reflection     Hero Story
        │             │             │
        └─────────────┼─────────────┘
                      ▼
                   Action
                      │
                      ▼
                 Reflection
                      │
                      ▼
              Behavioral Evidence
                      │
                      ▼
               Behavior Patterns
                      │
                      ▼
             Discovery Profile
                      │
                      ▼
               Personalization
                      │
                      └──────────► next experience
```

The Hero & Story platform therefore becomes one of the major experience sources in the adaptive human-growth system.

---

# 15. Future Representation Ecosystem

Once the canonical Story foundation is stable, additional representations can evolve independently.

Potential representation families include:

```text
Canonical Story
      │
      ├── Written Narrative
      ├── Original Audio
      ├── Transcript
      ├── Script
      ├── Video
      ├── Translation
      ├── Short Form
      ├── Long Form
      ├── Motivational Adaptation
      └── Future Experiences
```

The critical rule remains:

**These are representations or experiences derived from the Story; they do not replace the canonical Story.**

This allows future forms of storytelling to evolve without destabilizing the core domain.

---

# 16. Publication

Publication should remain a distinct capability.

The conceptual flow is:

```text
Created
   ↓
Reviewed
   ↓
Approved
   ↓
Eligible for Publication
   ↓
Published
```

Materialization must not automatically publish.

Publication should eventually establish:

- explicit publication consent
- visibility
- publication lifecycle
- audience
- suitability requirements
- withdrawal/unpublish behavior
- representation eligibility

The existing foundation explicitly distinguishes Story creation, approval, and publication.

---

# 17. Catalog

Once Stories exist and have sufficient classification, catalog infrastructure can become a durable platform capability.

```text
Canonical Story
      ↓
Classification
      ↓
Catalog Entry
      ↓
Search / Browse
      ↓
Discovery
```

The catalog should remain multidimensional rather than reducing Stories to a single category or ranking.

---

# 18. Discovery

Discovery eventually becomes the bridge between:

```text
What exists
```

and:

```text
What may matter to this person
```

That means discovery should consume:

- Story catalog
- Hero catalog
- Themes
- challenges
- lessons
- user understanding
- Discovery Profile
- current experience context

while preserving separation between content truth and personalization.

---

# 19. Adaptive Experience

The long-term Hero & Story relationship is:

```text
                    Hero & Story
                         │
                         ▼
                    Discovery
                         │
                         ▼
                  Candidate Stories
                         │
                         ▼
                 Personalization
                         │
                         ▼
              Adaptive Experience
                         │
                         ▼
                      Action
                         │
                         ▼
                    Reflection
                         │
                         ▼
              Behavioral Evidence
                         │
                         ▼
                 New Understanding
                         │
                         ▼
                  Better Discovery
```

This is where the Hero & Story platform becomes part of the larger Everyone's Heroes transformation loop.

---

# 20. Architectural Decision Roadmap

The following decisions should remain explicit ADRs:

### HS-ADR-001

Hero & Story is a dedicated bounded context.

### HS-ADR-002

Story is the canonical narrative; media and representations are derivatives.

### HS-ADR-003

Narrative Themes remain owned by Discovery.

### HS-ADR-004

Multilingual representation is fundamental to Story.

### HS-ADR-005

Story provenance survives transformation.

### HS-ADR-006

AI-generated Story artifacts are non-authoritative until approved.

### HS-ADR-007

Story Cataloging is multidimensional.

### HS-ADR-008

Content suitability is independent from Story classification.

### HS-ADR-009

Spirituality and religion remain separate classifications.

### HS-ADR-010

Content classification does not determine personalization.

### HS-ADR-011

Story interaction does not automatically constitute Behavioral Evidence.

### HS-ADR-012

Search and discovery implementations are replaceable.

These decisions form the architectural guardrails for the roadmap.

---

# 21. Cross-Context Boundaries

The Hero & Story platform should eventually interact with other contexts approximately as follows:

```text
                 LIFE JOURNEY
                      │
              Behavioral Evidence
                      │
              Behavior Patterns
                      │
                      ▼
              Discovery Profile
                      │
                      │
                      ▼
                 DISCOVERY
                      │
                Themes / Relevance
                      │
                      ▼
              HERO & STORY
                      │
              Heroes / Stories
                      │
                      ▼
                EXPERIENCE
```

Ownership remains explicit.

### Hero & Story owns

- Heroes
- Stories
- Story representations
- Story provenance
- Story classification
- Story suitability
- Story catalog data

### Discovery owns

- Narrative Themes
- discovery relationships
- personalization relevance
- discovery orchestration

### Life Journey owns

- Journey
- Behavioral Evidence
- Behavior Patterns
- personal growth state

### Experience/UI owns

- presentation
- interaction
- experience composition

No context should absorb another context simply because the concepts are related.

---

# 22. Testing Strategy

The platform should be tested at four levels.

## Domain

Test:

- Hero invariants
- Story invariants
- lifecycle
- provenance
- ownership
- representations
- classification
- suitability
- visibility

## Application

Test:

- creation
- materialization
- submission
- approval
- publication
- cataloging
- search contracts
- discovery contracts

## Integration

Validate:

```text
Create Story
    ↓
Process Story
    ↓
Classify Story
    ↓
Approve
    ↓
Publish
    ↓
Discover
```

## Cross-context

Eventually validate:

```text
Published Story
      ↓
Discovery
      ↓
Candidate Inspiration
```

and:

```text
Story
  ↓
Reflection
  ↓
Behavioral Evidence
  ↓
Behavior Pattern
```

---

# 23. Definition of Platform Completion

The Hero & Story platform should be considered mature when:

- [ ] Heroes have a stable canonical representation.
- [ ] Stories have a stable canonical representation.
- [ ] Story lifecycle is explicit.
- [ ] Story representations are distinct from Stories.
- [ ] Language is foundational.
- [ ] Provenance survives transformation.
- [ ] Hero approval is explicit.
- [ ] AI remains non-authoritative.
- [ ] Story materialization is idempotent.
- [ ] Publication is separate from materialization.
- [ ] Stories can be cataloged.
- [ ] Stories can be searched.
- [ ] Stories can be filtered.
- [ ] Heroes can be discovered.
- [ ] Stories can be discovered.
- [ ] Stories can be consumed through appropriate representations.
- [ ] Discovery can consume Hero & Story data.
- [ ] Personalization remains outside the Story domain.
- [ ] Behavioral Evidence remains outside the Story domain.
- [ ] Adaptive discovery can use the Story ecosystem.
- [ ] The platform can feed personalized experiences.

---

# 24. The Architectural End State

The most important thing about this roadmap is that it does **not** end with a social feed.

The intended architecture is:

```text
                         EVERYONE'S HEROES

                              USER
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
         PERSONAL JOURNEY              HERO & STORY
         UNDERSTANDING                  ECOSYSTEM
                │                             │
                │                       Heroes / Stories
                │                       Themes / Lessons
                │                             │
                └──────────────┬──────────────┘
                               ▼
                           DISCOVERY
                               │
                               ▼
                        PERSONALIZATION
                               │
                               ▼
                     ADAPTIVE EXPERIENCE
                               │
                  ┌────────────┼────────────┐
                  ▼            ▼            ▼
               Mission     Reflection    Hero Story
                  │            │            │
                  └────────────┼────────────┘
                               ▼
                             ACTION
                               │
                               ▼
                          REFLECTION
                               │
                               ▼
                    BEHAVIORAL EVIDENCE
                               │
                               ▼
                       BEHAVIOR PATTERNS
                               │
                               ▼
                      DISCOVERY PROFILE
                               │
                               └──────────────►
                                  next experience
```

The Hero & Story platform is therefore not an isolated content system.

It becomes the **human experience ecosystem** that gives the personalization engine something profoundly different to work with:

**the lived experiences of other people.**

The long-term progression is:

> **One person's experience becomes another person's opportunity for growth.**

---

# 25. Recommended Implementation Strategy

After SB.13, do **not** immediately start HS.6.

The recommended sequence is:

```text
SB.13
Story Materialization
        ↓
══════════════════════════════════
HERO & STORY PLATFORM CHECKPOINT
══════════════════════════════════
        ↓
Validate canonical Story
        ↓
Validate lifecycle
        ↓
Validate representations
        ↓
Validate provenance
        ↓
Validate publication boundary
        ↓
Validate catalog boundary
        ↓
        ├───────────────┐
        ▼               ▼
 Representation     Publication
 Foundation         Foundation
        │               │
        └───────┬───────┘
                ▼
             Catalog
                ↓
          Discovery/Search
                ↓
          Hero Experience
                ↓
      Adaptive Hero Discovery
                ↓
      Personalized Experience
```

This checkpoint is important because SB.13 will be the first time the Story Builder's output becomes an actual canonical Story.

At that point, we should inspect the real implementation rather than assume the remaining HS phases still map exactly to the original 2026 design.

---

# 26. Roadmap Philosophy

The roadmap should follow one rule above all others:

> **Build the smallest vertical slice that creates a real architectural capability, then validate the boundary before expanding it.**

That is the pattern that has worked through SB.0–SB.12:

```text
Define boundary
      ↓
Implement smallest useful capability
      ↓
Persist what must be durable
      ↓
Test the boundary
      ↓
Validate architecture
      ↓
Move to next capability
```

The same discipline should govern the rest of Hero & Story.

The goal is not to build a giant content platform.

The goal is to build a trustworthy foundation through which:

**people can share what they have lived, other people can discover what may matter to them, and Everyone's Heroes can eventually turn those human experiences into meaningful personalized experiences.**
