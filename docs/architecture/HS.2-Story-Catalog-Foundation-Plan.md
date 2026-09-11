# HS.2 — Story Catalog Foundation (Revised & Approved Plan)

**Status:** Planning only — no implementation in this document’s originating task  
**Base:** HS.1 on `main`; existing `lib/features/hero_story/` conventions are authoritative  
**Binding inputs:** eight approved decisions below

---

## Binding Decisions

| # | Decision | HS.2 outcome |
|---|----------|--------------|
| 1 | Closed taxonomies | Keep `StorySubject`, `StoryChallenge`, `StoryOutcome`, `EmotionalCharacter`, `StoryAudience` as **closed enums**. No ID-based extensible taxonomies. |
| 2 | AI classification | **Option B.** No `ClassificationProposal`, no proposed-vs-authoritative state, no AI approval workflow. Authoritative human/application mutation only. Defer AI classification to **HS.4**. |
| 3 | Geography | Keep free-form `StoryGeography`. No ISO reference data. |
| 4 | Duration | `maxDuration` matches if **any** representation satisfies the constraint. Duration stays on representation; never Story-level state. |
| 5 | Events | Minimal. Retain `StoryClassified`. No suitability/spirituality/proposal events unless a real consumer exists (none today). |
| 6 | Resilience | Discovery-owned narrative theme via `NarrativeThemeId`. Do **not** add `StoryChallenge.resilience`. |
| 7 | Search boundary | `StorySearchPort` is replaceable query capability. Story aggregate has **no** search knowledge. |
| 8 | Scope | No production AI, AI classification/approval, production/semantic search, feed UI, personalization, social, media storage, interaction→evidence. |

**Code naming (authoritative):** `EmotionalCharacter`, `StoryGeography`, `StoryClassification`, `ContentSuitability`, `SpiritualityClassification`, `NarrativeThemeId`, `StorySearchPort` / `StorySearchQuery`, `StoryClassified`, `ClassifyStoryUseCase`.

---

## Final Architecture Decisions

### Reaffirmed from HS.1 (no new choice)

- Narrative themes owned by Discovery; Story stores `NarrativeThemeId[]` only.
- Multidimensional catalog (not free-form tags).
- `ContentSuitability` independent of classification.
- Spirituality/religion are Story content metadata, not Hero identity.
- Catalog ≠ Discovery ≠ Personalization.
- Search/capture implementations are replaceable ports.
- Do not store query/relationship denormalizations as aggregate state (same principle as removing Hero published-story ID lists).

### Locked by this approval

| ID | Decision |
|----|----------|
| **HS2-A1** | Closed enums for subject/challenge/outcome/emotional character/audience for all of HS.2. |
| **HS2-A2** | AI classification / proposal workflow deferred to HS.4 (Option B). |
| **HS2-A3** | Free-form `StoryGeography` retained. |
| **HS2-A4** | Duration query = **any matching representation**; no Story-level duration. |
| **HS2-A5** | Catalog-related events stay minimal: retain `StoryClassified` only. |
| **HS2-A6** | Resilience = Discovery `NarrativeThemeId`, not a `StoryChallenge`. |
| **HS2-A7** | Story = authoritative catalog state; `StorySearchPort` = query; Discovery = meaning; Personalization (future) = what next. |

### Explicitly not decided here

No additional architectural decisions are made in this revision. Open items appear only under **Remaining Architectural Questions**.

---

## Final Aggregate Boundaries

### Story owns

- `StoryId`, `HeroId`
- Title / narrative
- `originalLanguage`
- Lifecycle + visibility
- Authoritative `StoryClassification`
- Authoritative `ContentSuitability` (sibling VO)
- Authoritative `SpiritualityClassification` (sibling VO)
- Representations (language, format, origin, duration, media/text, HS.1 AI representation authority)
- Representation transformation provenance

### Story does not own

- Search logic or knowledge of `StorySearchPort`
- `NarrativeTheme` definitions
- Proposed/AI classification state
- Personalization scores / ranking
- Interactions, likes, evidence, behavior patterns
- Taxonomy definition repositories
- ISO geography reference data
- Story-level duration / format / available-language denormalized fields

### Hero owns

- Profile, visibility, status
- **Not** published story ID lists (query via `Story.heroId` + lifecycle)

### Discovery owns

- `NarrativeTheme` definitions (including Resilience)
- What is meaningful to a person

### Personalization (future) owns

- What the person should experience next — **not HS.2**

### Aggregate invariant test

| Candidate | Protects an invariant? | Placement |
|-----------|------------------------|-----------|
| `StoryClassification` | Yes — authoritative multi-dimension catalog fact | Story |
| `ContentSuitability` | Yes — coherent levels; independent of themes | Story (separate) |
| `SpiritualityClassification` | Yes — tradition only when religious; content-only | Story (separate) |
| Duration | Representation fact only | Representation; query-derived |
| Available languages / formats | Derived | Derived |
| Classification proposals | Deferred HS.4 | **Not in Story** |
| Taxonomy repos for closed enums | No | Enums in domain code |

---

## Final Domain Model

```text
Story
├── StoryId, HeroId
├── title / narrative
├── originalLanguage: LanguageCode
├── lifecycleStatus / visibility
├── classification: StoryClassification          // authoritative
│     ├── subjects: List<StorySubject>           // closed enum
│     ├── challenges: List<StoryChallenge>       // closed enum; no resilience
│     ├── narrativeThemeIds: List<NarrativeThemeId>
│     ├── outcomes: List<StoryOutcome>           // closed enum
│     ├── emotionalCharacters: List<EmotionalCharacter>
│     ├── audience: StoryAudience?
│     └── geography: StoryGeography?             // free-form
├── contentSuitability: ContentSuitability
├── spirituality: SpiritualityClassification
└── representations: StoryRepresentation[]
      ├── language / format / origin
      ├── duration?                              // maxDuration source
      └── …

Derived (not stored on Story):
├── availableLanguages
├── formats
└── duration match ← ANY representation.duration satisfying query

Discovery:
└── NarrativeTheme (e.g. Resilience) ← NarrativeThemeId on Story only
```

### Dimension matrix

| Dimension | Story state? | Form |
|-----------|--------------|------|
| Subject | Yes | Closed enum |
| Challenge | Yes | Closed enum |
| Narrative Theme | Yes (IDs) | `NarrativeThemeId[]` |
| Outcome | Yes | Closed enum |
| Emotional Character | Yes | Closed enum |
| Audience | Yes | Closed enum |
| Geography | Yes | Free-form VO |
| Content Suitability | Yes (sibling) | VO |
| Spirituality / Religion | Yes (sibling) | VO |
| Original Language | Yes | `LanguageCode` |
| Available Languages | No | Derived |
| Format / Origin | No (on Story) | Representation |
| Duration | No (on Story) | Representation; any-match query |

**Taxonomy repositories for Story enums: none.**  
`NarrativeTheme` persistence remains Discovery-only.

---

## Final Search Contract

### Boundary

```text
Story                 → authoritative catalog state (no search imports)
StorySearchPort       → replaceable catalog query capability
InMemoryStorySearchAdapter → deterministic HS.2 implementation
Discovery             → relevance/meaning (not catalog filtering)
Personalization       → what next (future; not HS.2)
```

### `StorySearchQuery` — target HS.2 shape

Current fields retained; expansions marked **add**:

| Field | Semantics |
|-------|-----------|
| `text?` | Simple contains (in-memory) |
| `heroId?` | Exact |
| `subjects` | Any-match (OR within dimension) |
| `challenges` | Any-match |
| `narrativeThemeIds` | Any-match (e.g. Resilience) |
| `outcomes` | Any-match **(add)** |
| `emotionalCharacters` | Any-match **(add)** |
| `audience?` | Exact |
| Geography constraints | On free-form fields **(add)** |
| `originalLanguage?` | Exact vs Story.originalLanguage |
| `availableLanguage?` | Original **or** any representation language |
| `formats` | Any representation format **(add)** |
| `maxDuration?` | **Any** representation with duration ≤ max **(add)** |
| Suitability maxes | Expand beyond `maxProfanity` **(add)** |
| Spirituality filters | Category / tradition **(add)** |
| `publishedOnly` | Default `true` |

### Canonical example

```text
subjects: [military]                         // or equivalent StorySubject
narrativeThemeIds: [Resilience]              // NarrativeThemeId — NOT StoryChallenge
availableLanguage: en
maxProfanity: none                           // + other suitability caps as included
spiritualityCategory: nonSpiritual
maxDuration: 10 minutes                      // any representation ≤ 10m
publishedOnly: true
```

### Duration binding example

- Original = 18m, English = 9m, short = 6m
- `maxDuration = 10m` → **matches** (English and short qualify)

### Non-goals

Ranking, personalization, vector/semantic search, search-engine coupling inside domain.

---

## Final Application Use Cases

### Retain (HS.1)

- Hero: create / update profile / search heroes
- Story lifecycle: create / submit / approve / publish / archive
- `ClassifyStoryUseCase` — authoritative classification write
- `AddStoryRepresentationUseCase`
- `SearchStoriesUseCase` → `StorySearchPort`
- Capture port remains stubbed

### HS.2 additions (application only; domain mutators already exist)

| Use case | Notes |
|----------|-------|
| `ClassifyStoryUseCase` | Keep as sole authoritative classification path (Option B) |
| `UpdateStoryContentSuitabilityUseCase` | **Add** — wraps `Story.updateContentSuitability`; no new event |
| `UpdateStorySpiritualityUseCase` | **Add** — wraps `Story.updateSpirituality`; no new event |
| `SearchStoriesUseCase` | Keep; consume expanded `StorySearchQuery` |

### Out of HS.2

AI propose/approve classification, personalized recommend, production capture, feed assembly, interaction→evidence.

---

## Final Events

| Event | HS.2 |
|-------|------|
| `StoryClassified` | **Retain** on authoritative `classify` |
| Suitability-changed | **Do not add** |
| Spirituality-changed | **Do not add** |
| Classification-proposed | **Do not add** (HS.4) |
| HS.1 lifecycle/representation events | Unchanged |

**Rule:** No events merely because a field changes.

---

## Exact Proposed File Tree

Prefer extending existing files. Paths match current layout.

```text
lib/features/hero_story/
├── domain/
│   ├── aggregates/story.dart                         # no search; no proposal state
│   ├── value_objects/
│   │   ├── story_classification.dart                 # keep enum + theme-id shape
│   │   ├── content_suitability.dart
│   │   ├── spirituality_classification.dart
│   │   └── story_geography.dart                      # free-form retained
│   ├── enums/                                        # closed taxonomies retained
│   │   ├── story_subject.dart
│   │   ├── story_challenge.dart                      # NO resilience
│   │   ├── story_outcome.dart
│   │   ├── emotional_character.dart
│   │   └── story_audience.dart
│   ├── entities/story_representation.dart            # duration stays here
│   ├── events/story_classified.dart                  # retain only catalog event
│   ├── services/story_search_port.dart               # EXPAND StorySearchQuery
│   └── repositories/story_repository.dart
├── application/
│   ├── dto/requests/
│   │   ├── classify_story_request.dart
│   │   ├── update_story_content_suitability_request.dart   # ADD
│   │   └── update_story_spirituality_request.dart          # ADD
│   └── use_cases/
│       ├── classify_story_use_case.dart
│       ├── update_story_content_suitability_use_case.dart  # ADD
│       ├── update_story_spirituality_use_case.dart         # ADD
│       └── search_stories_use_case.dart
└── infrastructure/search/
    └── in_memory_story_search_adapter.dart           # expanded filters + any-duration

test/features/hero_story/
├── domain/aggregates/story_test.dart
├── infrastructure/search/search_adapters_test.dart
└── application/use_cases/hero_story_use_cases_test.dart
```

**Do not add:** proposal types, suitability/spirituality/proposal events, taxonomy repositories, ISO geography types.

**Discovery (reference only):** Resilience as `NarrativeTheme` / `NarrativeThemeId` — ownership does not move.

---

## Testing Plan

1. Closed enums remain compile-time closed; no ID-taxonomy types.
2. Story stores `NarrativeThemeId` only; Resilience queries use theme id; no `StoryChallenge.resilience`.
3. Suitability updates do not alter `StoryClassification`.
4. Spirituality tradition guard; no Hero identity mutation.
5. Free-form geography retained; no ISO types.
6. Combinatorial search: subject + Resilience theme + available language + suitability + spirituality + `maxDuration`.
7. Duration any-match: 18/9/6 → `maxDuration=10m` matches.
8. `originalLanguage` vs `availableLanguage` distinct.
9. Format any-match when formats filter is added.
10. `classify` raises `StoryClassified`; suitability/spirituality raise no new events.
11. Story domain does not reference `StorySearchPort`.
12. HS.1 regression + analyzer clean on touched code when implemented.

No UI / production search / AI tests.

---

## Implementation Sequence

1. Record HS2-A1…A7 as ADRs when doc writes are authorized.
2. Expand `StorySearchQuery` + `InMemoryStorySearchAdapter` (outcomes, emotional character, geography, spirituality, suitability dimensions, formats, **any-match maxDuration**).
3. Add suitability/spirituality application use cases + request DTOs.
4. Keep `ClassifyStoryUseCase` as sole authoritative classification write path.
5. Tests: combinatorial catalog, duration any-match, Resilience-as-theme.
6. Analyzer + focused suite + full suite.
7. Stop — no AI, production search, UI, or personalization.

---

## Deferred Work

| Item | When |
|------|------|
| AI classification + proposed→approval→authoritative | **HS.4** |
| Production / semantic / vector search | HS.6 |
| Personalized discovery / feed | HS.8 / personalization |
| Extensible ID-based Story taxonomies | Post-HS.2 ADR only if needed |
| ISO geography reference data | Later |
| Capture / transcription / media storage | HS.3+ |
| Interaction → evidence | Life Journey |
| Suitability/spirituality domain events | Only if a real consumer appears |
| Feed UI, social, marketplace | Out of HS.2 |

---

## Remaining Architectural Questions

*Not decided. Do not resolve silently during implementation.*

1. **Null duration** — If no representation has duration, does `maxDuration` exclude the story, ignore the filter, or apply only when durations exist?
2. **`minDuration`** — In scope for HS.2 with the same any-match rule?
3. **Suitability filter breadth** — All suitability dimensions in HS.2, or staged beyond `maxProfanity`?
4. **Geography operators** — Exact vs case-insensitive contains on country/region/city/culturalContext?
5. **Cross-dimension combinatorics** — Confirm OR within a dimension, AND across dimensions as the HS.2 contract.
6. **Duration-eligible representations** — All representations, or only approved/authoritative ones when filtering published stories?
7. **Resilience seeding** — Seed a Discovery `NarrativeTheme` named Resilience for fixtures, or allow tests to use a generated `NarrativeThemeId` without a defined entity?
8. **Provider wiring** — Add Riverpod providers for new suitability/spirituality use cases, or keep constructors-only like current classify/search?
9. **Docs authorization** — Update in-repo ADRs/plan markdown as part of HS.2 implementation, or separate docs PR?

---

## Delta From Pre-Decision Draft

- Closed enums **locked**
- AI/proposal path **removed** from HS.2 (Option B → HS.4)
- Free-form geography **locked**
- Duration **locked** to any-matching representation
- Events **locked** to minimal (`StoryClassified`)
- Resilience **locked** as Discovery theme id
- Search/Story/Discovery/Personalization separation **reaffirmed**
- Scope exclusions **reaffirmed**
- No further decisions made beyond the eight approvals
