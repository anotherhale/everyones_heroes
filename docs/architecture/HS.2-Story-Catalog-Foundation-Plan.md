# HS.2 — Story Catalog Foundation

**Status:** Final architectural cleanup — implementation-ready plan  
**Phase:** HS.2 — Story Catalog Foundation  
**Base:** HS.1 merged on `main`; existing `lib/features/hero_story/` is authoritative for naming and structure  
**Governing sources:** `AGENTS.md`, HS-ADR-001…013, Discovery NarrativeTheme ownership, this plan  

**Document authority:** This document is the active HS.2 phase plan. The six decisions in §1 are final for HS.2 and are not open questions.

---

## 1. Executive Summary

HS.2 completes the **Story Catalog Foundation** on top of HS.1.

HS.1 already delivered:

- `Story` / `Hero` aggregates
- Multidimensional `StoryClassification`
- Independent `ContentSuitability` and `SpiritualityClassification`
- Closed taxonomy enums
- `NarrativeThemeId` references (Discovery-owned themes)
- Representations with language, format, origin, duration
- Replaceable `StorySearchPort` + in-memory adapter
- Authoritative `ClassifyStoryUseCase` and `StoryClassified`

HS.2 hardens and completes the catalog **without** becoming search infrastructure, AI understanding, personalization, or product UI.

### What HS.2 is

- Authoritative catalog state on Story
- Closed local taxonomies as enums
- Discovery themes by `NarrativeThemeId` only
- Expanded deterministic catalog query contract
- Application use cases for suitability/spirituality mutation
- Clear separation of Story / Search / Discovery / Personalization

### What HS.2 is not

- Production search, semantic/vector search
- AI classification or proposal/approval workflow (HS.4)
- Personalization, feed, ranking, recommendations
- Capture, transcription, media storage, translation pipelines
- Social, moderation platform, marketplace, Hero/Story UI
- Interaction → evidence integration

### Six final decisions (authoritative)

| ID | Decision |
|----|----------|
| **HS2-D1** | Local catalog dimensions are **closed enums**. No taxonomy repositories or extensible taxonomy IDs in HS.2. |
| **HS2-D2** | **Option B:** no AI classification proposal model in HS.2. `StoryClassified` marks authoritative classification only. AI proposal→approval is **HS.4**. |
| **HS2-D3** | Geography is free-form `StoryGeography`. No ISO/geography reference infrastructure. |
| **HS2-D4** | Duration lives on `StoryRepresentation`. `minDuration` / `maxDuration` match if **ANY** representation satisfies the constraint. |
| **HS2-D5** | Event model stays minimal: retain `StoryClassified`. No speculative suitability/spirituality/proposal events. |
| **HS2-D6** | Resilience is a Discovery `NarrativeTheme` referenced by `NarrativeThemeId`, not a `StoryChallenge`. |

---

## 2. Architectural Decisions

### 2.1 Reaffirmed HS.1 decisions (unchanged)

| ADR | Binding rule |
|-----|--------------|
| HS-ADR-002 | Story is canonical narrative; media/representations are derivatives |
| HS-ADR-003 | Narrative themes owned by Discovery; Story stores `NarrativeThemeId` only |
| HS-ADR-004 | Multilingual representation is fundamental |
| HS-ADR-005 | Provenance preserved through transformations |
| HS-ADR-006 | AI-generated **representations** are non-authoritative until approved |
| HS-ADR-007 | Cataloging is multidimensional (not tags) |
| HS-ADR-008 | Content suitability independent of classification |
| HS-ADR-009 | Spirituality/religion are Story content metadata, not Hero identity |
| HS-ADR-010 | Catalog ≠ Discovery ≠ Personalization |
| HS-ADR-011 | Story interaction ≠ automatic behavioral evidence |
| HS-ADR-012 | Search/capture implementations are replaceable ports |

> Note on HS-ADR-006 vs HS2-D2: HS.1 AI-authority rules apply to **StoryRepresentation** artifacts. HS.2 does **not** extend that into classification proposals. Classification AI workflow is deferred to HS.4.

### 2.2 Final HS.2 decisions

#### HS2-D1 — Closed taxonomies

For HS.2, local Story Catalog dimensions are **closed enums**:

- `StorySubject`
- `StoryChallenge`
- `StoryOutcome`
- `EmotionalCharacter`
- `StoryAudience`
- `StoryRepresentationFormat` (format; already enum on representation)

**Forbidden in HS.2:**

- `SubjectRepository`, `ChallengeRepository`, `OutcomeRepository`, etc.
- Taxonomy aggregate roots
- Extensible taxonomy ID types for these dimensions

Extensible taxonomies may be reconsidered in a **future** phase only if product requirements justify them. That reconsideration is not part of HS.2.

**Exception (different concept):** `NarrativeTheme` remains Discovery-owned reference data with `NarrativeThemeId`. Hero & Story must not duplicate theme definitions.

#### HS2-D2 — AI classification = Option B

HS.2 retains the **authoritative human/application** catalog mutation path only.

**Forbidden in HS.2:**

- `ClassificationProposal`
- Proposed-vs-authoritative classification state on Story
- AI classification approval workflow
- AI classification history / proposal persistence

`StoryClassified` means: authoritative classification was applied.

AI may eventually propose classifications in **HS.4 Story Understanding**. That workflow must be designed there, not prematurely introduced into the HS.2 domain model.

#### HS2-D3 — Free-form geography

Use existing free-form `StoryGeography` value object (`country`, `region`, `city`, `culturalContext`).

**Forbidden in HS.2:**

- Geography repositories
- ISO country/region hierarchy
- Geography aggregates
- Geographic taxonomy infrastructure

#### HS2-D4 — Duration = any matching representation

Duration is a property of `StoryRepresentation`, never duplicated as Story-level state.

For duration queries:

> A Story matches if **ANY** representation on that Story satisfies the duration constraint(s).

Example:

| Representation | Duration |
|----------------|----------|
| Original audio | 18 minutes |
| English | 9 minutes |
| Short | 6 minutes |

Query `maxDuration = 10 minutes` → **Story matches** (English and short qualify).

**Not used:**

- Shortest-only matching
- Longest-only matching
- Single canonical representation matching

A representation with `duration == null` does **not** satisfy `minDuration` or `maxDuration`. If no representation satisfies the constraint, the Story does not match.

#### HS2-D5 — Minimal events

Retain:

- `StoryClassified` (authoritative classification applied)

**Do not add in HS.2:**

- `StoryContentSuitabilityUpdated`
- `StorySpiritualityUpdated`
- `StoryClassificationProposed`

Principle: events represent meaningful domain facts needed by the architecture, not every mutation. Future phases may add events when real consumers exist. No current consumer requires suitability/spirituality events.

#### HS2-D6 — Resilience is a Narrative Theme

```text
StoryChallenge  = difficulty/problem in the story
                  (Failure, Loss, Fear, Injury, Uncertainty, …)

NarrativeTheme  = deeper meaning/theme (Discovery-owned)
                  (Resilience, Courage, Perseverance, Purpose, …)
```

Resilience is referenced as `NarrativeThemeId`.  
**Do not** add `StoryChallenge.resilience` to make search convenient.

### 2.3 Context separation (mandatory)

```text
Story
  → “What is this story?”
  → Owns authoritative catalog state
  → ZERO knowledge of search, ranking, recommendation, personalization

StorySearchPort
  → “Which stories match these explicit catalog criteria?”
  → Application/query capability
  → Replaceable; in-memory adapter for HS.2

Discovery
  → “What does this person find meaningful?”
  → Owns NarrativeTheme, Discovery Profile, influences, discovery preferences

Personalization (future)
  → “What should this person experience next?”
  → Not in HS.2
```

---

## 3. Domain Model

### 3.1 Story (authoritative catalog)

```text
Story
├── StoryId
├── HeroId
├── title / narrative
├── originalLanguage: LanguageCode
├── lifecycleStatus / visibility
├── classification: StoryClassification          // authoritative only
│     ├── subjects: List<StorySubject>           // closed enum
│     ├── challenges: List<StoryChallenge>       // closed enum; no Resilience
│     ├── narrativeThemeIds: List<NarrativeThemeId>
│     ├── outcomes: List<StoryOutcome>           // closed enum
│     ├── emotionalCharacters: List<EmotionalCharacter>
│     ├── audience: StoryAudience?
│     └── geography: StoryGeography?             // free-form
├── contentSuitability: ContentSuitability       // independent sibling
├── spirituality: SpiritualityClassification     // independent sibling
└── representations: StoryRepresentation[]
      ├── language
      ├── format                                 // closed enum
      ├── origin
      ├── duration?                              // duration query source
      ├── mediaReference / textContent
      ├── sourceRepresentationId?
      ├── isAiGenerated / isApproved             // representation authority (HS.1)
      └── …
```

### 3.2 Derived (not stored on Story)

| Derived concept | Source |
|-----------------|--------|
| Available languages | `originalLanguage` ∪ representation languages |
| Available formats | representation formats |
| Duration match | ANY representation whose `duration` satisfies query bounds |

Do **not** redundantly store available languages or Story-level duration on Story.

### 3.3 Dimension ownership

| Dimension | Owner | Form | Story state? |
|-----------|-------|------|--------------|
| Subject | Hero & Story | Closed enum | Yes (in classification) |
| Challenge | Hero & Story | Closed enum | Yes |
| Narrative Theme | Discovery defs; Story refs | `NarrativeThemeId[]` | Yes (IDs only) |
| Outcome | Hero & Story | Closed enum | Yes |
| Emotional Character | Hero & Story | Closed enum | Yes |
| Audience | Hero & Story | Closed enum | Yes |
| Geography | Hero & Story | Free-form VO | Yes |
| Content Suitability | Hero & Story | Independent VO | Yes (sibling field) |
| Spirituality / Religion | Hero & Story | Independent VO | Yes (sibling field) |
| Original Language | Hero & Story | `LanguageCode` | Yes |
| Available Language | Derived | From representations | No |
| Format | Hero & Story | Enum on representation | Representation |
| Origin | Hero & Story | Enum on representation | Representation |
| Duration | Hero & Story | `Duration?` on representation | Representation |

### 3.4 Challenge vs Narrative Theme

| Concept | Answers | Examples |
|---------|---------|----------|
| `StoryChallenge` | What difficulty/problem does the story involve? | Failure, Loss, Fear, Injury, Uncertainty |
| `NarrativeTheme` | What deeper meaning/theme does it carry? | Resilience, Courage, Perseverance, Purpose |

Search for “Resilience” uses `narrativeThemeIds`, never a Challenge enum value.

### 3.5 Content Suitability (independent)

Answers: **“What potentially sensitive content does this story contain?”**  
Does **not** answer: “What is this story about?”

Dimensions (existing):

- `profanity`
- `violence`
- `sexualContent`
- `substanceUse`
- `disturbingContent`

Each uses `SuitabilityLevel`.

Must remain separate from `StoryClassification`. Must not be merged into classification.

### 3.6 Spirituality and religion (independent)

`SpiritualityClassification` remains separate from both `StoryClassification` and `ContentSuitability`.

Critical rule (HS-ADR-009):

> Story content containing religious material does **not** establish that the Hero personally belongs to that religion.

No religion-identity inference from Story catalog state onto Hero.

### 3.7 Representations and languages

```text
Story                    → canonical lived narrative
StoryRepresentation      → one language/format presentation of that Story
```

Example provenance chain (one Story, many representations):

```text
Spanish Original
  → Spanish Transcript
  → English Translation
  → English Audio
```

Do **not** create separate Stories for each language/format.

Preserve:

- `originalLanguage` on Story
- per-representation `language`
- derived available languages
- transformation provenance (HS.1)

### 3.8 Emotional character

`EmotionalCharacter` describes story experience/tone (hopeful, reflective, …).  
It is **not** a psychological claim about the Hero’s personality.

---

## 4. Aggregate Boundaries

### 4.1 Story aggregate

**Owns** authoritative catalog + narrative lifecycle + representations needed for language/provenance/duration invariants.

**Does not own:**

- Search indexes or search knowledge
- Interaction history
- Recommendation / personalization scores
- Media blobs
- AI classification proposal history
- Taxonomy graphs
- Unbounded analytics

Rule: if a concept does not participate in Story invariants, it is not Story aggregate state. Prefer VO, representation entity, query model, or a future bounded context.

### 4.2 Comparison to removed Hero published-story IDs

Do not reintroduce query denormalizations as aggregate state.

| Candidate | Invariant? | HS.2 placement |
|-----------|------------|----------------|
| Classification VO | Yes | Story |
| Suitability VO | Yes | Story (sibling) |
| Spirituality VO | Yes | Story (sibling) |
| Duration | No at Story level | Representation + query |
| Available languages | No | Derived |
| Classification proposals | Deferred HS.4 | **Absent** |
| Taxonomy repositories | No | Enums in code |

### 4.3 Hero aggregate

Unchanged for HS.2 catalog work. Still does not store published story ID lists.

### 4.4 Discovery

Owns `NarrativeTheme` (including Resilience).  
Hero & Story only references `NarrativeThemeId`.

---

## 5. Value Objects

| VO | Role in HS.2 |
|----|--------------|
| `StoryClassification` | Authoritative multidimensional catalog fact |
| `ContentSuitability` | Independent suitability levels |
| `SpiritualityClassification` | Independent spirituality/religion content metadata |
| `StoryGeography` | Free-form geographic/cultural context |
| `LanguageCode` | Shared language code |
| `StoryTitle` / `StoryNarrative` | Canonical narrative fields |
| `MediaReference` | Opaque media pointer |
| `StoryProvenance` / steps | Transformation lineage |

No proposal VOs. No ISO geography VOs. No taxonomy-definition VOs inside Hero & Story.

---

## 6. StoryRepresentation

Entity within Story consistency boundary.

| Field | Catalog relevance |
|-------|-------------------|
| `language` | Available-language derivation and filters |
| `format` | Format filters (`StoryRepresentationFormat` enum) |
| `origin` | Provenance / transformation semantics |
| `duration` | **Sole** source for duration queries |
| `mediaReference` / `textContent` | Representation payload |
| `sourceRepresentationId` | Transformation chain |
| `isAiGenerated` / `isApproved` | Representation authority (HS.1); **not** classification authority |

HS.2 does not add Story-level copies of representation-derived catalog facts.

---

## 7. StorySearchQuery (final contract)

Expand existing `StorySearchQuery` on `StorySearchPort`.

### 7.1 Fields

| Field | Type / shape | Semantics |
|-------|--------------|-----------|
| `text?` | `String?` | Simple case-insensitive contains over title/narrative (in-memory) |
| `heroId?` | `HeroId?` | Exact |
| `subjects` | `List<StorySubject>` | OR within dimension |
| `challenges` | `List<StoryChallenge>` | OR within dimension |
| `narrativeThemeIds` | `List<NarrativeThemeId>` | OR within dimension (e.g. Resilience) |
| `outcomes` | `List<StoryOutcome>` | OR within dimension **(HS.2 add)** |
| `emotionalCharacters` | `List<EmotionalCharacter>` | OR within dimension **(HS.2 add)** |
| `audience?` | `StoryAudience?` | Exact |
| `geographyCountry?` | `String?` | Case-insensitive contains on `StoryGeography.country` **(HS.2 add)** |
| `geographyRegion?` | `String?` | Case-insensitive contains on region **(HS.2 add)** |
| `geographyCity?` | `String?` | Case-insensitive contains on city **(HS.2 add)** |
| `geographyCulturalContext?` | `String?` | Case-insensitive contains on culturalContext **(HS.2 add)** |
| `spiritualityCategory?` | `SpiritualityCategory?` | Exact **(HS.2 add)** |
| `religiousTradition?` | `ReligiousTradition?` | Exact **(HS.2 add)** |
| `maxProfanity?` | `SuitabilityLevel?` | Story level ≤ max (existing; retain) |
| `maxViolence?` | `SuitabilityLevel?` | Story level ≤ max **(HS.2 add)** |
| `maxSexualContent?` | `SuitabilityLevel?` | Story level ≤ max **(HS.2 add)** |
| `maxSubstanceUse?` | `SuitabilityLevel?` | Story level ≤ max **(HS.2 add)** |
| `maxDisturbingContent?` | `SuitabilityLevel?` | Story level ≤ max **(HS.2 add)** |
| `formats` | `List<StoryRepresentationFormat>` | OR: any representation format matches **(HS.2 add)** |
| `minDuration?` | `Duration?` | ANY representation with non-null duration ≥ min **(HS.2 add)** |
| `maxDuration?` | `Duration?` | ANY representation with non-null duration ≤ max **(HS.2 add)** |
| `originalLanguage?` | `LanguageCode?` | Exact vs `Story.originalLanguage` |
| `availableLanguage?` | `LanguageCode?` | Original **or** any representation language |
| `publishedOnly` | `bool` | Default **`true`** |

Exact Dart field names may follow existing file style; the semantics above are binding.

### 7.2 Combinatorics

- **Within** a multi-value dimension (subjects, challenges, themes, …): **OR** (any-match)
- **Across** dimensions: **AND** (all provided constraints must hold)
- Multiple geography fields: **AND** (each provided geography constraint must hold)
- `minDuration` and `maxDuration` together: a representation may satisfy both, or different representations may each satisfy one — Story matches if **there exists** a representation satisfying `minDuration` (when set) **and** **there exists** a representation satisfying `maxDuration` (when set). For HS.2 simplicity and predictability, require **the same representation** to satisfy both bounds when both are set (duration window on one representation).

### 7.3 Language distinction (mandatory)

| Filter | Meaning |
|--------|---------|
| `originalLanguage` | Language the story was originally told in |
| `availableLanguage` | Language the story can be experienced in (original or any representation) |

Example: Spanish original + English translation

- `originalLanguage = es` → matches
- `availableLanguage = en` → matches
- These concepts must not be collapsed

### 7.4 publishedOnly

Defaults to **`true`** for discovery-facing catalog queries.

### 7.5 Canonical query example

```text
subjects: [military]                         // StorySubject
narrativeThemeIds: [<Resilience theme id>] // NarrativeThemeId — NOT StoryChallenge
availableLanguage: en
maxProfanity: none
maxViolence: mild                            // example suitability cap
spiritualityCategory: nonSpiritual
maxDuration: 10 minutes                      // ANY representation ≤ 10m
publishedOnly: true
```

Duration example: 18m / 9m / 6m representations → `maxDuration = 10m` **matches**.

---

## 8. Search Semantics

### 8.1 Port boundary

```text
abstract interface class StorySearchPort {
  Future<List<StoryId>> search(StorySearchQuery query);
}
```

- Story aggregate imports **nothing** from search
- No `StorySearchRepository`
- Persistence remains `StoryRepository`
- Querying remains `StorySearchPort`

### 8.2 In-memory adapter (HS.2)

`InMemoryStorySearchAdapter`:

- Loads stories via `StoryRepository`
- Applies filters deterministically
- Implements any-match duration/format/language rules above
- Remains the only search implementation in HS.2

### 8.3 Explicit non-goals

- Elasticsearch / OpenSearch / vendor engines
- Semantic or vector search
- Ranking by engagement, relevance-to-user, or personalization
- Discovery meaning scoring inside Hero & Story

---

## 9. AI Boundary

### HS.2 (this phase)

```text
Human / application command
  → ClassifyStoryUseCase / suitability / spirituality use cases
  → Story authoritative mutators
  → StoryClassified (classification only)
```

No proposed classification state exists on Story.

### HS.1 still applies to representations only

AI-generated **representations** remain non-authoritative until `approveRepresentation` (HS-ADR-006).

### HS.4 (deferred)

```text
Evidence / content
  → Proposed classification
  → Human approval
  → Authoritative catalog state
```

Must be designed in HS.4. Do not prototype proposal types in HS.2 “for later.”

---

## 10. Events

| Event | HS.2 disposition |
|-------|------------------|
| `StoryClassified` | **Retain** — raised on authoritative `Story.classify` |
| Content suitability changed | **Do not add** |
| Spirituality changed | **Do not add** |
| Classification proposed | **Do not add** (HS.4) |
| Existing HS.1 lifecycle / representation events | Unchanged |

No events merely because a field changes.

---

## 11. Repository Strategy

| Port / repository | HS.2 |
|-------------------|------|
| `StoryRepository` | Retain — persistence of Story aggregate |
| `HeroRepository` | Retain — unchanged for catalog work |
| `StorySearchPort` | Retain & expand query contract — **not** a repository |
| Taxonomy repositories | **Do not create** |
| `StorySearchRepository` | **Do not create** |
| `NarrativeThemeRepository` | Remains in **Discovery** |

Persistence ≠ querying:

- `StoryRepository` saves/loads aggregates
- `StorySearchPort` answers catalog criteria queries

---

## 12. Cross-Context Integration

```text
Hero & Story          Discovery              Personalization (future)
─────────────         ─────────              ──────────────────────
What is this story?   What is meaningful?    What next?
StoryClassification   NarrativeTheme         Experience selection
ContentSuitability    Discovery Profile
Spirituality          Influences
StorySearchPort       Preferences
  (explicit filter)
```

Integration rules:

- Cross-context references use shared IDs (`NarrativeThemeId`, `HeroId`, `StoryId`)
- No importing Discovery aggregates into Hero & Story domain
- No Discovery/Personalization logic inside `StorySearchPort`
- `StoryClassified` may later be consumed elsewhere; HS.2 does not require new reactors

---

## 13. Application Use Cases

### Retain (HS.1)

- Hero create / update profile / search heroes
- Story create / submit / approve / publish / archive
- `ClassifyStoryUseCase` — sole authoritative classification write path
- `AddStoryRepresentationUseCase`
- `SearchStoriesUseCase` → `StorySearchPort`
- Capture port remains unsupported stub

### Add in HS.2

| Use case | Behavior |
|----------|----------|
| `UpdateStoryContentSuitabilityUseCase` | Load Story → `updateContentSuitability` → save → publish existing pulled events only (none new for this mutation) |
| `UpdateStorySpiritualityUseCase` | Load Story → `updateSpirituality` → save → same event rule |

### Out of HS.2

- AI propose / approve classification
- Personalized recommend
- Production capture / transcription
- Feed assembly
- Interaction → evidence

---

## 14. Testing Strategy

### Domain

1. Closed enums remain closed; no taxonomy ID/repo types introduced.
2. `StoryClassification` stores `NarrativeThemeId` only; no Resilience on `StoryChallenge`.
3. Suitability updates do not mutate classification.
4. Spirituality tradition guard; no Hero religious identity mutation.
5. Free-form `StoryGeography` retained; no ISO types.
6. Representation duration remains on representation; Story has no duration field.
7. `classify` raises `StoryClassified`; suitability/spirituality raise no new events.
8. Story domain does not import `StorySearchPort`.

### Search / adapter

9. Combinatorial AND across dimensions / OR within lists.
10. `originalLanguage` vs `availableLanguage` distinction (Spanish original + English rep).
11. Duration any-match: 18/9/6 → `maxDuration=10m` matches.
12. Duration null: representation without duration does not satisfy duration bounds.
13. When both `minDuration` and `maxDuration` set, same representation must fall in window.
14. Format any-match across representations.
15. All suitability max filters enforced independently of classification.
16. Spirituality category/tradition filters.
17. Geography case-insensitive contains per provided field.
18. `publishedOnly` defaults true.
19. Deterministic result ordering (document as repository iteration order).

### Application

20. Suitability/spirituality use cases persist changes without new events.
21. Classify remains authoritative-only path (no proposal API).

### Regression

22. Existing HS.1 hero_story tests remain green.
23. `dart analyze` clean on touched packages when implemented.

No UI, production search, or AI classification tests in HS.2.

---

## 15. Exact Proposed File Tree

Prefer extending existing files. No new bounded contexts.

```text
lib/features/hero_story/
├── domain/
│   ├── aggregates/story.dart                            # no search; no proposal state
│   ├── value_objects/
│   │   ├── story_classification.dart                    # enums + NarrativeThemeId + geography
│   │   ├── content_suitability.dart                     # independent
│   │   ├── spirituality_classification.dart             # independent
│   │   └── story_geography.dart                         # free-form
│   ├── enums/
│   │   ├── story_subject.dart                           # closed
│   │   ├── story_challenge.dart                         # closed; NO resilience
│   │   ├── story_outcome.dart                           # closed
│   │   ├── emotional_character.dart                     # closed
│   │   ├── story_audience.dart                          # closed
│   │   └── story_representation_format.dart             # closed (existing)
│   ├── entities/story_representation.dart               # duration lives here
│   ├── events/story_classified.dart                     # retain; no new catalog events
│   ├── services/story_search_port.dart                  # EXPAND StorySearchQuery
│   └── repositories/story_repository.dart               # persistence only
├── application/
│   ├── dto/requests/
│   │   ├── classify_story_request.dart
│   │   ├── update_story_content_suitability_request.dart    # ADD
│   │   └── update_story_spirituality_request.dart           # ADD
│   └── use_cases/
│       ├── classify_story_use_case.dart                     # authoritative only
│       ├── update_story_content_suitability_use_case.dart   # ADD
│       ├── update_story_spirituality_use_case.dart          # ADD
│       └── search_stories_use_case.dart
└── infrastructure/search/
    └── in_memory_story_search_adapter.dart                  # expanded + any-duration

test/features/hero_story/
├── domain/aggregates/story_test.dart
├── infrastructure/search/search_adapters_test.dart
└── application/use_cases/hero_story_use_cases_test.dart
```

**Do not add:**

```text
classification_proposal.dart
story_classification_proposed.dart
story_content_suitability_updated.dart
story_spirituality_updated.dart
subject_repository.dart / challenge_repository.dart / …
iso_country.dart / geography_repository.dart
story_search_repository.dart
```

**Discovery (reference only):** Resilience as `NarrativeTheme` / `NarrativeThemeId`.

---

## 16. Implementation Sequence

1. Record HS2-D1…D6 as ADRs in `docs/architecture/architecture-decisions.md` (implementation kickoff docs step).
2. Expand `StorySearchQuery` fields per §7.
3. Implement expanded filters in `InMemoryStorySearchAdapter` (including any-match duration window).
4. Add `UpdateStoryContentSuitabilityUseCase` + `UpdateStorySpiritualityUseCase` (+ request DTOs).
5. Keep `ClassifyStoryUseCase` as sole classification write path (Option B).
6. Add/adjust tests per §14 (especially duration any-match + Resilience-as-theme + language split).
7. Run analyzer + focused hero_story tests + full suite.
8. **Stop.** Do not start AI, production search, UI, personalization, or media work.

---

## 17. Deferred Work (explicit)

| Item | Deferred to |
|------|-------------|
| AI classification / proposal / approval workflow | **HS.4 Story Understanding** |
| Production search engine | Later (e.g. HS.6) |
| Semantic / vector search | Later |
| Personalized ranking / recommendation / feed algorithms | Personalization / later HS |
| Extensible ID-based Story taxonomies | Future ADR only if product requires |
| ISO geography hierarchy / geography repos | Later |
| Story capture / transcription | Later (e.g. HS.3) |
| Media processing / storage | Later |
| Translation pipeline productization | Later |
| Interaction → evidence integration | Life Journey |
| Moderation platform | Later |
| Suitability/spirituality domain events | Only when a real consumer exists |
| Hero UI / Story UI / marketplace / social / community | Out of HS.2 |
| Production backend platformization | Out of HS.2 |

HS.2 is the **Story Catalog foundation**, not the entire Hero & Story platform.

---

## 18. Remaining Questions

Only items that cannot be fully resolved from current architecture/product direction:

1. **Resilience fixture strategy** — For tests/demos, should Discovery seed a stable `NarrativeTheme` named “Resilience”, or may tests use an opaque generated `NarrativeThemeId` without requiring a persisted theme entity?
2. **Application provider wiring** — Should HS.2 add Riverpod providers for the new suitability/spirituality use cases, or keep constructor injection only (matching current classify/search wiring in HS.1)?

These do **not** block domain/search contract implementation. They affect test fixtures and DI wiring only.

All six formerly open architectural decisions (taxonomies, AI proposals, geography, duration, events, Resilience) are **closed** for HS.2.

---

## 19. Consistency Validation

| Check | Result |
|-------|--------|
| No contradiction with HS.1 ADRs | Pass — extends HS-ADR-003/007/008/009/010/012; does not weaken them |
| Discovery owns NarrativeTheme | Pass — IDs only in Story; Resilience is theme not challenge |
| No `StorySearchPort` leakage into Story aggregate | Pass — explicit boundary |
| No Personalization leakage | Pass — catalog filter only |
| No AI proposal model in HS.2 | Pass — Option B / HS.4 |
| No taxonomy repositories | Pass — closed enums |
| No religion-identity inference | Pass — HS-ADR-009 restated |
| No duplicated language/duration state on Story | Pass — derived / representation-owned |
| Duration = ANY matching representation | Pass — §2.2 HS2-D4, §7, §8, §14 |
| Event model minimal | Pass — `StoryClassified` only for catalog |
| Implementation-sized | Pass — search contract expansion + 2 use cases + tests; no platform sprawl |

---

## 20. Implementation Readiness

**HS.2 READY FOR IMPLEMENTATION**

Blockers: none for the catalog foundation scope defined here.  
Remaining questions (§18) are wiring/fixture choices and do not change the domain model, aggregate boundaries, search semantics, or event model.
