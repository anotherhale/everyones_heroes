# HS.2 — Story Catalog Foundation: Architecture Plan

**Status:** Planning only (no implementation in this document’s originating task)  
**Base:** `main` @ `3c38f65` (HS.1 merged)  
**Governing sources:** `AGENTS.md`, HS.1 foundation doc, HS-ADR-001…013, current `lib/features/hero_story/` + Discovery implementation

---

## A. Executive Summary

HS.1 already delivered most of the Story Catalog *domain skeleton*: multidimensional `StoryClassification`, independent `ContentSuitability` and `SpiritualityClassification`, closed taxonomy enums, `NarrativeThemeId` references, language/representation separation, and a replaceable `StorySearchPort` with an in-memory catalog filter.

**HS.2 is not a greenfield catalog.** It should harden and complete the catalog foundation:

1. Clarify which dimensions are **aggregate state** vs **derived/queryable**.
2. Close gaps in the **catalog query contract** (combinatorial filters).
3. Establish **authoritative vs proposed** classification (AI boundary) without production AI.
4. Decide **enum vs extensible taxonomy** where HS.1 conceptual docs and code diverge.
5. Keep **Discovery / Personalization** out of Story classification.
6. Avoid bloating Story or inventing taxonomy repositories for closed vocabularies.

**Primary rule:** Aggregate state exists to protect invariants — not because a noun describes a Story (same principle that removed `Hero.publishedStoryIds`).

---

## B. Current HS.1 State

### Implemented (authoritative)

| Area | Location / shape |
|------|------------------|
| Bounded context | `lib/features/hero_story/` (domain + application + infrastructure; **no presentation**) |
| Aggregates | `Hero`, `Story` |
| Classification VO | `StoryClassification`: subjects, challenges, narrativeThemeIds, outcomes, emotionalCharacters, audience?, geography? |
| Suitability VO | `ContentSuitability` (5 dimensions × `SuitabilityLevel`) — separate from classification |
| Spirituality VO | `SpiritualityClassification` (category + optional tradition) — separate from Hero identity |
| Language | `Story.originalLanguage`; `StoryRepresentation.language`; derived `availableLanguages` |
| Format / origin / duration | On `StoryRepresentation`, not on `StoryClassification` |
| Search | `StorySearchPort` + `InMemoryStorySearchAdapter` (catalog filter only) |
| Use cases | `ClassifyStoryUseCase` (+ lifecycle/search/capture stubs) |
| Events | `StoryClassified` (classification only) |
| ADRs | HS-ADR-001…013 accepted in `architecture-decisions.md` |
| Hero story list | **Not stored** — query via `StoryRepository.findByHeroId` |

### Intentionally missing / deferred from HS.1

- Proposed/AI classification workflow
- Use cases for suitability/spirituality updates
- Full multidimensional query surface
- Taxonomy reference-data entities for Subject/Challenge/Outcome
- Production search, AI, media, feed UI

### Documentation drift (report only)

- Conceptual HS.1 §35 sketches `SubjectId` / `ChallengeId` / `OutcomeId`; code uses **closed enums**.
- Conceptual aggregate sketch still mentions “Published Story References” on Hero; code correctly removed them.
- `repository-map.md` / some Discovery docs lag implementation.

Treat **code + accepted HS-ADRs** as current truth for HS.2 planning.

---

## C. Existing Catalog/Taxonomy Findings

### Dimension inventory vs current ownership

| Dimension | HS.1 model | Where it lives | Queryable today? |
|-----------|------------|----------------|------------------|
| Subject | `StorySubject` enum | Story aggregate (`StoryClassification`) | Yes (any-match) |
| Challenge | `StoryChallenge` enum | Story aggregate | Yes |
| Narrative Theme | `NarrativeThemeId[]` | Story aggregate; **definitions in Discovery** | Yes |
| Outcome | `StoryOutcome` enum | Story aggregate | **No** |
| Emotional Character | `EmotionalCharacter` enum | Story aggregate | **No** |
| Audience | `StoryAudience` enum | Story aggregate | Yes |
| Content Suitability | `ContentSuitability` VO | Story aggregate (separate field) | Partial (`maxProfanity` only) |
| Spirituality | `SpiritualityClassification` VO | Story aggregate (separate field) | **No** |
| Religion (tradition) | `ReligiousTradition?` | Inside spirituality VO | **No** |
| Language (original) | `LanguageCode` | Story | Yes |
| Language (available) | derived from representations | Derived | Yes |
| Origin | `RepresentationOrigin` | Representation | **No** |
| Format | `StoryRepresentationFormat` | Representation | **No** |
| Duration | `Duration?` on representation | Representation (precise); buckets would be derived | **No** |
| Geography / cultural context | `StoryGeography` free-form strings | Story classification | **No** |

### Discovery ownership confirmed

- `NarrativeTheme` entity + `NarrativeThemeRepository` (read-oriented) live in Discovery.
- Cross-context references use shared-kernel `NarrativeThemeId` only (`lib/core/ids/`).
- HS-ADR-003 + AD-002 remain binding.

### Influence catalog pattern (transferable)

Discovery uses curated entities + closed category enums + theme IDs. Story catalog already mirrors the **ID reference** pattern for themes and **enums** for local dimensions. Do **not** create a parallel Story-owned theme catalog.

---

## D. Architecture Decisions Required

Decisions that need **human approval before implementation** are marked ★.

| ID | Decision | Recommendation | Needs approval? |
|----|----------|----------------|-----------------|
| HS2-D1 | Keep Subject/Challenge/Outcome/Emotional/Audience as **closed enums** for HS.2 | Yes — match HS.1 code; defer extensible taxonomy | ★ if product wants SubjectId now |
| HS2-D2 | Keep Suitability + Spirituality **outside** `StoryClassification` | Yes — HS-ADR-008/009 already accepted | No (reaffirm) |
| HS2-D3 | Format/Origin/Duration remain **representation-derived**, not Story classification fields | Yes | No |
| HS2-D4 | Expand `StorySearchQuery` to full combinatorial catalog contract | Yes for HS.2 foundation; production search deferred to HS.6 | No |
| HS2-D5 | Introduce **proposed vs authoritative** classification state | Model contracts in HS.2; keep AI adapter stubbed | ★ (lifecycle/approval actor) |
| HS2-D6 | Which dimensions require Hero approval before authoritative | Propose: classification themes/subjects/outcomes/emotional + spirituality/suitability when AI-proposed; Hero/editor-authored apply immediately | ★ |
| HS2-D7 | Geography: free strings vs controlled codes | Keep free-form VO for HS.2; optionally normalize later | ★ if ISO/country codes required now |
| HS2-D8 | Emotional character naming (“tone” vs “character”) | Keep `EmotionalCharacter`; document as story-experience descriptor, not psychology | No |
| HS2-D9 | Taxonomy repositories for enums | **Do not create** | No |
| HS2-D10 | Catalog definitions ownership | Hero & Story owns local taxonomy enums/VOs; Discovery owns NarrativeTheme | No |
| HS2-D11 | Events for suitability/spirituality/classification proposal | Add only when other components need to react | ★ (event minimalism) |

---

## E. Catalog Domain Model

### Conceptual boundaries

```text
Hero & Story owns:     What the Story is.
Discovery owns:        What is meaningful to a particular person.
Personalization owns:  What this person should experience next.  (future)
```

### Story-facing catalog surface (target HS.2)

```text
Story
├── originalLanguage                    // aggregate fact
├── classification : StoryClassification
│     ├── subjects[]
│     ├── challenges[]
│     ├── narrativeThemeIds[]           // Discovery IDs only
│     ├── outcomes[]
│     ├── emotionalCharacters[]
│     ├── audience?
│     └── geography?
├── contentSuitability                  // independent VO
├── spirituality                        // independent VO; not Hero identity
└── representations[]
      ├── language / format / origin / duration / media
      └── → derive availableLanguages, formats, durations
```

### Not Story classification

- Popularity, engagement, “for you” ranking
- User preference matching
- Behavior patterns / evidence
- Hero religious identity
- Feed ordering

---

## F. Taxonomy Ownership

| Concept | Owner | Form in HS.2 | Repository? |
|---------|-------|--------------|-------------|
| NarrativeTheme | **Discovery** | Entity + `NarrativeThemeId` | Yes (`NarrativeThemeRepository`, already) |
| Subject / Challenge / Outcome / Emotional / Audience | **Hero & Story** | Closed enums | **No** |
| Suitability levels | Hero & Story | Enum | **No** |
| Spirituality category / Religious tradition | Hero & Story | Enums inside VO | **No** |
| LanguageCode | Shared kernel | Value object | **No** |
| Geography | Hero & Story | Value object (strings) | **No** |
| Format / Origin | Hero & Story | Enums on Representation | **No** |
| Duration buckets | Application/query projection | Derived | **No** |

**Rule:** Taxonomy nouns do not get repositories. Repositories persist aggregates (and Discovery’s curated theme/influence reference data). Closed vocabularies live as enums in domain code until product proves need for runtime-extensible reference data (post-HS.2 ADR).

**Where catalog definitions live:** Hero & Story **domain** (enums/VOs), not application configuration and not a new bounded context — unless/until extensible taxonomy requires curated seed data similar to Influences (future).

---

## G. Aggregate Boundary Analysis

### Do catalog fields on Story create new invariants?

| State | Invariant / reason to store on Story | Verdict |
|-------|--------------------------------------|---------|
| `classification` | Authoritative “what is this story?”; consistency of multi-dimension set applied atomically via `classify` | **Keep on Story** |
| `contentSuitability` | Must remain coherent per-dimension levels; independent of subject/theme; used for appropriateness filters | **Keep on Story** (separate field) |
| `spirituality` | Tradition only allowed when religious; must not leak to Hero | **Keep on Story** (separate field) |
| `originalLanguage` | Original reps must match; canonical language of narrative | **Keep on Story** |
| Available languages | Derived from representations | **Do not store** |
| Format / origin | Belong to each representation; Story may have many | **Do not duplicate onto Story** |
| Duration | Belongs to representation; “under 10 minutes” is query projection | **Do not store Story-level duration** |
| Hero.publishedStoryIds | Query/relationship, not invariant | **Already correctly removed** — do not reintroduce analogous denormalizations (e.g. StorySubject index tables inside aggregate) |

### Avoiding a giant Story aggregate

HS.2 should **not** add:

- Interaction history
- Search indexes
- AI proposal history as unbounded child collections (if proposal state is needed, keep a small VO or pending snapshot — ★ decide)
- Taxonomy definition graphs
- Personalization scores
- Media blobs

Representations already live on Story for lifecycle/provenance invariants (language match, source chain, AI approval). That is justified. Catalog dimensions that are already VOs should stay as **replaceable value objects**, not expanding entity trees.

### Compare to `publishedStoryIds` removal

Adding “every catalog facet as queryable denormalized child entities” would repeat the same mistake. Prefer:

- Authoritative VOs on Story for invariant-bearing classification
- Query via `StorySearchPort` (replaceable) for combinations
- Derive format/language/duration from representations

---

## H. Value Objects / Entities / Enums

### Keep as value objects

- `StoryClassification`
- `ContentSuitability`
- `SpiritualityClassification`
- `StoryGeography`
- `LanguageCode` (shared)
- `MediaReference`
- `StoryProvenance` / `ProvenanceStep` (classification provenance interaction — see N)

### Keep as entities (not new for HS.2)

- `StoryRepresentation` (format/origin/duration/language)

### Keep as closed enums (HS.2 default)

- `StorySubject`, `StoryChallenge`, `StoryOutcome`, `EmotionalCharacter`, `StoryAudience`
- `SuitabilityLevel`, `SpiritualityCategory`, `ReligiousTradition`
- `StoryRepresentationFormat`, `RepresentationOrigin`

### Eventually extensible taxonomy (deferred)

Subject (and possibly Challenge/Outcome) were described as extensible in conceptual docs. **Do not migrate to entity+repo in HS.2** without ★ approval. If approved later:

- Prefer Discovery-like curated reference entities **owned by Hero & Story**
- Story stores IDs only
- Still no personalization ownership

### Do **not** create entities for

Emotional tone, audience, suitability levels, religious tradition (as standalone aggregates), geography countries.

---

## I. Story Classification Model

### Authoritative model (current → retain)

```text
StoryClassification
├── subjects: List<StorySubject>           // set semantics
├── challenges: List<StoryChallenge>
├── narrativeThemeIds: List<NarrativeThemeId>
├── outcomes: List<StoryOutcome>
├── emotionalCharacters: List<EmotionalCharacter>
├── audience: StoryAudience?
└── geography: StoryGeography?
```

### Evolution without aggregate bloat

1. Treat classification as **one VO replacement** (`classify(newClassification)`), not per-dimension child entities.
2. Keep suitability/spirituality as **sibling VOs** with their own update methods (already exist).
3. Do not merge everything into one mega-VO if update frequency/invariants diverge (they already diverge: spirituality has tradition guard; suitability has independent levels).
4. Optional HS.2 refinement: a single application use case that can update classification + suitability + spirituality in one orchestration **without** forcing one domain VO.

### Emotional character without psychological claims

Document and test that `EmotionalCharacter` describes **story experience / tone**, not Hero personality or clinical affect. Prefer catalog language like “hopeful story” over “hero is hopeful.” No trait transfer to Identity or Life Journey.

### Geography / cultural context

Retain `StoryGeography` as story setting/context, distinct from Hero location (Hero profile has no current-location field today — keep it that way). Free-form strings are acceptable for foundation; avoid inferring identity from geography.

---

## J. Content Suitability Model

**Retain HS-ADR-008.**

```text
ContentSuitability
├── profanity
├── violence
├── sexualContent
├── substanceUse
└── disturbingContent
    each: SuitabilityLevel { none | mild | moderate | strong }
```

Independence rules:

- Suitability ≠ subject/theme classification
- Suitability ≠ moderation/publishability (catalog vs moderation; HS.1 §60)
- Suitability ≠ personalization (user prefs consume suitability later; Story only declares content)

HS.2 work: expose **all** suitability dimensions on the search query (max level per dimension or “no stronger than”), not only profanity.

---

## K. Spirituality / Religion Model

**Retain HS-ADR-009.**

```text
SpiritualityClassification
├── category: nonSpiritual | spiritual | religious
└── tradition?: ReligiousTradition   // only when religious
```

Hard rules:

1. Story content classification only — **never** write to Hero profile as religious identity.
2. Tradition null unless `religious`.
3. Queryable as content filters (e.g. non-religious), not as “find heroes of faith X.”
4. Do not collapse spirituality into `StoryClassification` subjects/themes.

---

## L. Language / Representation Integration

| Concept | Model | Query |
|---------|-------|-------|
| Original language | `Story.originalLanguage` | `StorySearchQuery.originalLanguage` |
| Available languages | Derived from representation languages (+ original) | `availableLanguage` |
| Format | Per representation | Add to query (any representation matches) |
| Origin | Per representation | Optional filter; not primary catalog facet |
| Duration | Per representation (`Duration?`) | Query `maxDuration` / bucket against **shortest or canonical published representation** — ★ pick rule |

Invariant to preserve: original representation language must match `originalLanguage`.

HS.2 must **not** add a single Story-level language field that replaces representation languages.

---

## M. Query / Catalog Contract

### Purpose

Establish domain/application contracts for combinatorial catalog queries. **No** Elasticsearch/vector DB/vendor coupling (HS-ADR-012).

### Target example (must be expressible)

```text
subjects: Military
challenges/themes: Resilience  → NarrativeThemeId (Discovery), not a StoryChallenge enum value named resilience
availableLanguage: English
maxProfanity: none
spirituality: nonSpiritual
maxDuration: 10 minutes
publishedOnly: true
```

Note: “Resilience” is a **Narrative Theme** (Discovery), not currently a `StoryChallenge`. Query uses `narrativeThemeIds`, not a free tag.

### Proposed `StorySearchQuery` expansion (HS.2)

Add (beyond today’s fields):

- `outcomes`, `emotionalCharacters`
- `geography` constraints (country/region/culturalContext contains or equals)
- `spiritualityCategory`, `religiousTradition`
- full suitability maxes: violence, sexualContent, substanceUse, disturbingContent
- `formats`, `maxDuration` / `minDuration`
- keep `originalLanguage` vs `availableLanguage` distinct
- keep `publishedOnly` default true
- keep text as simple contains for in-memory adapter only

### Adapter

Extend `InMemoryStorySearchAdapter` deterministically. Production search remains HS.6.

### Explicit non-goals for this contract

- Ranking by engagement
- Personalized ordering
- Semantic/vector similarity
- “Because you liked…” explanations from behavioral patterns

---

## N. AI Classification Boundary

Preserve:

```text
Evidence / content
    → Proposed Classification
    → Human (Hero/editor) Approval
    → Authoritative Catalog State
```

HS.1 already applies this to **representations** (`isAiGenerated` / `approveRepresentation`). HS.2 should extend the **same philosophy** to classification without shipping production AI.

### Recommended model (requires ★ approval on exact shape)

**Option A (minimal — preferred for HS.2):**

- Authoritative fields remain as today.
- Add optional `ClassificationProposal` VO (or pending fields) holding proposed classification/suitability/spirituality + provenance note (`isAiAssisted`, source, timestamp).
- `applyClassificationProposal` / `approveClassification` methods promote proposal → authoritative and raise `StoryClassified`.
- Capture/AI port may later fill proposals; HS.2 ships stub/port only.

**Option B (defer proposal state):**

- HS.2 only documents the boundary and keeps `ClassifyStoryUseCase` as human-authoritative write path.
- AI classification waits for HS.4 (Story Understanding).

**Recommendation:** Prefer **Option A lite** if HS.2 must make the boundary enforceable in domain; otherwise Option B with explicit ADR “AI classification deferred to HS.4” — ★ choose.

### Provenance interaction

When AI proposes classifications:

- Record assistance in provenance or proposal metadata (`isAiAssisted: true`).
- Do **not** treat proposal as authoritative catalog state.
- Do **not** silently invent themes/facts/outcomes.

### What requires Hero approval before authoritative

| Source | Classification / suitability / spirituality | Recommendation |
|--------|-----------------------------------------------|----------------|
| Hero/editor direct input | Apply immediately as authoritative | Default |
| AI proposal | Requires explicit approval | ★ confirm |
| Staff moderator | Policy-dependent; may be authoritative for suitability | ★ confirm |
| System defaults (`unmarked` / empty) | Allowed until classified | Keep |

---

## O. Domain Events

### Existing

- `StoryClassified` — raised on authoritative `classify`

### Proposed HS.2 (only if reactors/consumers need them)

| Event | When | Notes |
|-------|------|-------|
| `StoryClassified` | Authoritative classification applied/replaced | Keep; optionally enrich payload with dimension summaries later |
| `StoryContentSuitabilityUpdated` | Suitability changes | Optional ★ |
| `StorySpiritualityUpdated` | Spirituality changes | Optional ★ |
| `StoryClassificationProposed` | AI/system proposal recorded | Only if Option A |

Do **not** emit personalization or evidence events from catalog changes.

No reactors required in HS.2 unless Discovery explicitly needs `StoryClassified` (not currently wired).

---

## P. Repository Requirements

| Repository | HS.2 action |
|------------|-------------|
| `StoryRepository` | Keep; no taxonomy methods |
| `HeroRepository` | Unchanged |
| `NarrativeThemeRepository` | Remains in Discovery; Hero & Story must not duplicate |
| `SubjectRepository` / etc. | **Do not create** |
| Search indexes as repos | **Do not create**; use `StorySearchPort` |

Optional: application-level taxonomy listing helpers (enum values / display maps) — not repositories.

---

## Q. Proposed File Changes

*Planning only — do not implement until HS.2 is authorized.*

### Likely touch points

```text
lib/features/hero_story/domain/services/story_search_port.dart     # expand StorySearchQuery
lib/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart
lib/features/hero_story/application/use_cases/…                   # update suitability/spirituality use cases
lib/features/hero_story/application/dto/requests/…
lib/features/hero_story/domain/aggregates/story.dart              # proposal/approval methods if Option A
lib/features/hero_story/domain/value_objects/…                    # ClassificationProposal if Option A
lib/features/hero_story/domain/events/…                           # only if approved
docs/architecture/architecture-decisions.md                      # HS2-ADRs
docs/architecture/… HS.2 phase doc (when authorized to write)
```

### Tests

```text
test/features/hero_story/domain/aggregates/story_test.dart
test/features/hero_story/infrastructure/search/search_adapters_test.dart
test/features/hero_story/application/use_cases/hero_story_use_cases_test.dart
```

### Explicitly out of scope files

- Presentation / feed UI
- Production AI adapters
- Elasticsearch/vector infra
- Discovery NarrativeTheme ownership moves
- Life Journey evidence bridges

---

## R. Testing Strategy

1. **Domain invariants**
   - Spirituality tradition guard
   - Suitability independence from classification
   - Theme IDs only (no NarrativeTheme entity import in hero_story)
   - Classification set dedupe
   - Proposal non-authoritative until approved (if Option A)
2. **Aggregate boundary**
   - No Hero denormalized story/catalog indexes
   - Duration/format not duplicated onto Story
3. **Search contract**
   - Combinatorial query: subject + theme + language + suitability + spirituality + duration
   - `originalLanguage` ≠ `availableLanguage`
   - `publishedOnly` default
   - Deterministic ordering (document current order = repository iteration)
4. **Application**
   - Classify / update suitability / update spirituality use cases publish expected events
5. **Analyzer**
   - `dart analyze` clean on touched packages
6. **Regression**
   - Existing HS.1 hero_story suites remain green

No UI tests for HS.2.

---

## S. Implementation Sequence

1. Write HS2 ADRs (reaffirm HS-ADR-007…010; decide ★ items D1/D5/D6/D7/D11).
2. Document dimension ownership matrix in phase doc.
3. Expand `StorySearchQuery` + in-memory adapter (combinatorial catalog).
4. Add application use cases for suitability/spirituality if missing from public API.
5. (If Option A) Add proposal VO + approve path + tests.
6. Tighten tests for language/duration/format derived filters.
7. Analyzer + focused tests + full suite.
8. Stop before capture AI, feed UI, or production search.

---

## T. Deferred Work

| Item | Deferred to |
|------|-------------|
| Production search engine | HS.6 |
| Personalized discovery / feed | HS.8 / personalization |
| Production AI classification | HS.4 |
| Story capture/transcription | HS.3 |
| Extensible Subject/Challenge taxonomies as entities | Post-HS.2 ADR |
| ISO geography codes | Later |
| Story interaction → evidence | Life Journey (HS-ADR-011) |
| Moderation workflow beyond lifecycle | Later |
| Hero discovery UI / marketplace / social | Explicitly out of scope |
| Duration bucket UX | Presentation later; domain keeps precise Duration |

---

## U. Architecture Risks

1. **Enum vs SubjectId tension** — conceptual docs imply extensibility; migrating mid-flight breaks catalogs. Resolve via ★ D1 before coding extensibility.
2. **Story aggregate creep** — stuffing proposal history, interactions, or indexes into Story repeats the giant-aggregate failure mode.
3. **Catalog becoming personalization** — search scoring by “match to user” inside Hero & Story violates HS-ADR-010.
4. **Theme vocabulary drift** — inventing Story-local theme enums instead of `NarrativeThemeId`.
5. **Religion identity leakage** — copying spirituality onto Hero or Identity.
6. **Treating AI output as truth** — skipping approval.
7. **Denormalizing query fields onto Hero** — same class of error as `publishedStoryIds`.
8. **Over-eventing** — events for every suitability tweak without consumers.
9. **Duration ambiguity** — which representation’s duration filters the story (shortest? preferred format? any?).
10. **Documentation drift** — updating stale maps broadly is out of scope; update only HS.2-relevant ADRs/phase docs when implementation starts.

---

## V. Definition of Done (for future HS.2 implementation)

HS.2 is complete when:

- Catalog dimensions are explicitly owned and documented (aggregate vs derived).
- Narrative themes remain Discovery-owned; Story stores IDs only.
- Suitability and spirituality remain independent of subject/theme classification and of Hero identity.
- Original vs available languages are queryable distinctly.
- Format/origin/duration are representation-derived for catalog queries.
- `StorySearchPort` expresses multidimensional combinations (including the Military + theme + English + no profanity + non-religious + under 10 min class of query) via in-memory adapter.
- AI classification is non-authoritative until approved (modeled or explicitly deferred by ADR).
- No taxonomy repositories for closed enums.
- No production search/AI/feed/personalization/social features.
- Domain/application tests cover invariants and combinatorial catalog queries.
- `dart analyze` clean; relevant test suites pass.
- ★ human decisions below are resolved before merging implementation.

---

## Decisions Requiring Human Approval Before Implementation

1. **★ HS2-D1** — Keep closed enums for Subject/Challenge/Outcome/Emotional/Audience in HS.2, or begin migrating to extensible ID-based taxonomies now?
2. **★ HS2-D5/D6** — Implement proposed-vs-authoritative classification in HS.2 (Option A), or defer AI classification state to HS.4 (Option B)? Who may approve (Hero only vs editor/moderator)?
3. **★ HS2-D7** — Is free-form `StoryGeography` acceptable for HS.2, or are controlled country/region codes required now?
4. **★ Duration filter rule** — When a story has multiple representations, which duration applies for “under 10 minutes” (any match, all match, preferred format, shortest)?
5. **★ Event set** — Emit dedicated suitability/spirituality/proposal events in HS.2, or keep `StoryClassified` only until consumers exist?
6. **★ “Resilience” vocabulary** — Confirm resilience (and similar) are Discovery `NarrativeTheme`s to seed/reference — not new `StoryChallenge` enum values.

---

## Out of Scope (reaffirmed)

Do not implement in HS.2:

- social networking
- followers
- likes/comments
- popularity ranking
- production recommendations
- personalization
- production AI classification
- production transcription
- media storage
- feed UI
- Hero discovery UI
- marketplace
- subscriptions
- monetization
