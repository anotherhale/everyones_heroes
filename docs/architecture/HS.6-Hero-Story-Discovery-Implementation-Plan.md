# HS.6 — Hero & Story Discovery Implementation Plan

**Phase:** HS.6 — Hero & Story Discovery  
**Status:** Planning complete — **D1–D4 and D7 CONFIRMED**; ready for implementation  
**Date:** 2026-09-12 (decisions locked 2026-09-12)  
**Constraint:** This document is the authoritative plan. Production implementation is a separate phase.  
**Predecessor:** HS.5 Story Authoring — **COMPLETE** (merged PR #12)  
**Successor (out of scope):** HS.7 Hero Experience; HS.8 Adaptive Hero Discovery  

**Document path note:** Repository convention for phase plans is `docs/architecture/HS.N-*-Plan.md` (see HS.2–HS.5). This file follows that convention.

---

## 1. Executive Summary

HS.6 establishes **application-facing Hero & Story Discovery** on top of the completed HS.1–HS.5 foundation:

```text
Canonical published Story (+ approved catalog + consent-gated publish)
        ↓
Catalog search / structured filtering (existing StorySearchPort)
        ↓
Discoverability eligibility policy (lifecycle + visibility + hero + representation rules)
        ↓
Discovery / browse use cases → summary read models (IDs + safe public fields)
        ↓
Riverpod providers (composition only)
```

Foundation §72 defines HS.6 as:

> Establish: search · structured filtering · Hero discovery · Story discovery · catalog browsing

That is **not** HS.8 Adaptive Hero Discovery (personalized “what next”), and **not** HS.7 Hero Experience UI (profiles, playback, collections).

### Core recommendation

Treat HS.6 as a **query / read / orchestration** milestone that:

1. **Reuses** existing `StorySearchPort` / `HeroSearchPort` and `SearchStoriesUseCase` / `SearchHeroesUseCase` as the catalog-filter substrate (HS-ADR-010 / HS-ADR-012).
2. **Adds** discoverability eligibility rules so private / unpublished / non-consent-publishable content cannot leak into discovery results.
3. **Adds** `DiscoverStories` / `DiscoverHeroes` / catalog-browse application use cases and **safe summary DTOs** (Foundation §56 already lists Discover\* separately from Search\*).
4. **Does not** introduce personalization, ranking engines, semantic/vector search, production AI, feed UX, or a second Story source of truth.
5. **Does not** move Discovery Profile ownership into Hero & Story (HS-ADR-001 / HS-ADR-003 / HS-ADR-010).

### Planning readiness

**READY FOR IMPLEMENTATION.** Hard gates **D1–D4 and D7** are human-confirmed (see §17). Soft gates **D5/D6/D8/D9/D10** may use plan recommendations unless overridden.

### Locked decisions (summary)

| Gate | Confirmed decision |
|------|--------------------|
| **D1** | Reuse existing search ports; add application-level Discover/Browse use cases |
| **D2** | One authoritative discoverability eligibility rule; **no private/unlisted leakage** (discoverable visibilities = `{public, community}` only) |
| **D3** | Only authoritative/approved representations participate in representation-dependent discovery/filtering |
| **D4** | MVP remains deterministic/in-memory; production search remains an adapter concern |
| **D7** | HS.6 is UI-agnostic; UI belongs to HS.7 |

---

## 2. Current Architecture Baseline (HS.1–HS.5)

### 2.1 Source-of-truth hierarchy applied

1. **Accepted HS-ADRs through HS-ADR-040** — binding.
2. **Merged HS.1–HS.5 implementation** (`lib/features/hero_story/**`) — authoritative for current behavior.
3. **HS.5 Implementation Report** — accepted complete; explicitly defers “UI / discovery / personalization” and names HS.6 as successor.
4. **Foundation roadmap §72** — authoritative for intended HS.6 / HS.7 / HS.8 split.
5. **HS.2–HS.4 plans/reports** — binding for catalog, capture, understanding boundaries.
6. **Architecture maps / AGENTS.md “HS.1 next” wording** — documentation drift; reported, not rewritten here.

### 2.2 Completed Hero & Story architecture (verified in code)

| Concern | Actual state |
|---------|--------------|
| Bounded context | `lib/features/hero_story` — Hero, Story, StoryUnderstanding |
| Canonical Story | `Story` aggregate: narrative, title, lifecycle, visibility, consent, classification, suitability, spirituality, representations, provenance |
| Hero | `Hero` aggregate: profile, status, visibility; published stories derived via `Story.heroId` |
| StoryUnderstanding | Separate HS.4 aggregate; proposals only; never silent catalog mutation |
| Story Authoring (HS.5) | `StoryAuthoringPort` + in-memory adapter; scripts/shortForm; human narrative update; representation edit/approve; `StoryRepresentationApproved` |
| Translation (HS.5 Slice B) | `StoryTranslationPort` → unapproved translated representation |
| Catalog classification | Multidimensional closed enums + `NarrativeThemeId[]` (Discovery-owned themes) |
| Consent | `StoryConsent`: recorded / processing / publication / AI — independent gates (HS-ADR-021) |
| Publish gate | Requires non-private/non-draft visibility + publication consent + non-provisional narrative + lifecycle transition into `published` |
| Search contracts | `StorySearchPort` / `HeroSearchPort` + in-memory adapters + thin Search\* use cases |
| Persistence | In-memory repositories only (`HeroRepository`, `StoryRepository`, `StoryUnderstandingRepository`) |
| Providers | Repository providers only; **no** search/discovery providers |
| Presentation | No `presentation/` layer under `hero_story` |
| Production AI | None (deterministic in-memory adapters only) |

### 2.3 Canonical Story vs derived material (must preserve)

```text
Canonical (source of truth)
├── Story.narrative / Story.title
├── Story.classification / suitability / spirituality (authoritative after human apply)
├── Story.lifecycleStatus / visibility / consent
└── StoryRepresentation (human original OR approved AI)

Derived / non-canonical until approved
├── StoryUnderstanding proposals
├── AI transcripts / scripts / shortForm / translations (isAiGenerated && !isApproved)
└── AI-assisted provenance steps
```

**Human approval principle (HS-ADR-006 / 023 / 034 / 035):** generated/derived material must not silently become canonical Story state. HS.6 must **consume** approved/published facts for discovery; it must **not** invent a path that promotes AI drafts into discoverable catalog content.

### 2.4 Story Understanding boundary (HS.4)

Understanding answers “what can we understand?” It is optional authoring context and optional future catalog-apply input. HS.6 must **not**:

- index or expose unreviewed understanding payloads in discovery results;
- treat understanding confidence as ranking;
- couple discovery adapters to `StoryUnderstandingPort`.

### 2.5 Story Authoring boundary (HS.5) — verified

| Item | Status |
|------|--------|
| `StoryAuthoringPort` | Present; deterministic in-memory adapter |
| Script / shortForm generation | Unapproved representations |
| Human-only narrative updates | `UpdateStoryNarrativeUseCase` |
| Representation editing | Unapproved in-place edit |
| Representation approval | `ApproveStoryRepresentationUseCase` → `StoryRepresentationApproved` |
| Translation Slice B | Unapproved translated representations |
| Deferred by HS.5 report | UI / discovery / personalization → **HS.6 / later** |

### 2.6 Existing search / filter substrate (already HS.1/HS.2)

**`StorySearchQuery`** supports: text, heroId, subjects, challenges, narrativeThemeIds, outcomes, emotionalCharacters, audience, geography\*, spirituality/religion, suitability maxes, formats, duration window (ANY representation / same-rep when both bounds — HS-ADR-016), originalLanguage vs availableLanguage, `publishedOnly` (default `true`).

Semantics: OR within dimension, AND across dimensions. Explicit port comment: **catalog filtering only — does not personalize, rank, or score relevance.**

**`HeroSearchQuery`** supports: text, experienceArea, language, `activeOnly` (default `true`).

**Gaps vs discoverability (verified):**

| Concern | Current search behavior | Risk |
|---------|-------------------------|------|
| Story visibility | **Not filtered** | Published `unlisted` stories still match |
| Hero visibility | **Not filtered** | Private heroes may appear in Hero search |
| Representation approval | Format/language/duration match **any** representation | Unapproved AI script/transcript can qualify a Story |
| Publication consent | Implied only via lifecycle=`published` | OK if publish invariant holds; do not duplicate consent on read models |
| Pagination / sort | None (repo iteration order) | Browse UX incomplete |
| Result shape | `List<StoryId>` / `List<HeroId>` only | No safe summary DTO; callers may over-fetch aggregates |
| Providers | None | Not wired for application/UI composition |
| Discover\* use cases | **Missing** | Foundation §56 lists them separately from Search\* |
| Catalog browse API | **Missing** | Empty search is only implicit browse |

### 2.7 Discovery bounded context (separate)

`lib/features/discovery` owns:

- `DiscoveryProfile`, `Influence`, `NarrativeTheme`, preferences
- `AddInfluenceUseCase`, `ResolveNarrativeThemesUseCase`

It does **not** own Story/Hero catalog discovery. Shared bridge today: `NarrativeThemeId` on `StoryClassification`.

**Adaptive-Discovery-and-Evidence-Engine.md** describes person-understanding → personalization experiences. That is **not** HS.6 Hero & Story Discovery. HS.8 consumes that seam.

### 2.8 Documentation drift (report only; do not rewrite maps in HS.6 unless in scope)

| Artifact | Drift |
|----------|-------|
| `bounded-contexts.md`, `aggregate-map.md`, `repository-map.md`, `use-case-map.md`, `event-flow.md` | Lag HS.1–HS.5 implementation |
| `AGENTS.md` | Still frames HS.1 as next authorized phase |
| HS.5 deferred line | Sometimes lumps “discovery (HS.6/HS.8)” — Foundation cleanly splits them |

Classification: **documentation drift (C)**. Reconcile only if an implementing slice explicitly includes map updates; otherwise leave for separate hygiene work.

---

## 3. HS.6 Objective

**Objective:** Make published, consent-eligible Heroes and Stories **findable and browsable** through replaceable catalog/discovery application contracts — with structured filtering, deterministic ordering, safe result payloads, and privacy-preserving eligibility — without personalization or AI ranking.

Success means another agent can implement:

- catalog search (hardened + wired),
- structured filtering (existing dimensions + eligibility),
- Story discovery,
- Hero discovery,
- catalog browsing,

…as vertical slices with tests, while preserving Catalog ≠ Discovery ≠ Personalization.

---

## 4. Scope

### 4.1 In scope (HS.6)

| Capability | Intent |
|------------|--------|
| **Search** | Keep/extend `StorySearchPort` / `HeroSearchPort` as replaceable catalog filters; wire providers; return usable application results |
| **Structured filtering** | Preserve multidimensional Story filters; strengthen Hero filters if needed for visibility; document OR/AND semantics |
| **Story discovery** | Application `DiscoverStories` orchestration producing safe story summaries for eligible published content |
| **Hero discovery** | Application `DiscoverHeroes` orchestration producing safe hero summaries for eligible heroes |
| **Catalog browsing** | Deterministic browse-by-dimension (subject/challenge/theme/language/format/etc.) without requiring free-text |
| **Eligibility policy** | Explicit discoverability rules (lifecycle, visibility, hero status/visibility, representation authority — **D2/D3 confirmed**) |
| **Read models / DTOs** | Application summary DTOs (not a second canonical store) |
| **Deterministic ordering** | Explicit stable sort + optional pagination (pending D6) |
| **Explainability (catalog-level)** | Optional non-personalized “matched because filter X” reasons (pending D8) |
| **Tests + ADRs** | Domain policy / application / adapter tests; HS-ADR-041+ |

### 4.2 Out of scope (explicit)

| Item | Belongs to |
|------|------------|
| Personalized ranking / “what next” | **HS.8** Adaptive Hero Discovery |
| Discovery Profile → relevance scoring / serendipity engine | **HS.8** (and Discovery BC evolution) |
| “Someone who has been there” full capability | Future / **HS.8** (needs User Understanding + Discovery Profile) |
| Hero Experience UI (profiles, playback, collections screens) | **HS.7** |
| Social feed / infinite scroll engagement optimization | Never as HS.6 goal; feed only as later presentation over discovery |
| Production AI / LLM recommendations / semantic vector search | Later (not required by Foundation §72) |
| Story interaction → behavioral evidence | Life Journey / HS-ADR-011 |
| TTS / narration synthesis | Deferred from HS.5 |
| Promote representation → narrative | Deferred from HS.5 |
| Explicit representation reject lifecycle | Deferred from HS.5 |
| Production backend / real search engine cluster | Optional only if D4 chooses it; **not recommended** for HS.6 MVP |
| Mutating Story/Hero aggregates as part of discovery queries | Forbidden |
| Rewriting stale architecture maps broadly | Separate hygiene unless slice requires |

### 4.3 What “discovery” means in HS.6 (terminology)

Keep terms distinct (AGENTS.md §34 + HS-ADR-010):

| Term | HS.6 meaning |
|------|----------------|
| **Catalog** | What a Story/Hero *is* (classification, suitability, languages, formats) |
| **Search / filter** | Catalog query returning matching IDs |
| **Discovery (HS.6)** | Application capability to find/browse **eligible** cataloged Heroes/Stories for a seeker |
| **Discovery BC** | Separate context: what inspires a *person* (influences/themes/profile) |
| **Personalization** | What this person should experience *next* — **HS.8**, not HS.6 |

HS.6 may *optionally accept* caller-supplied `NarrativeThemeId` filters (including values that originated from a DiscoveryProfile) **as ordinary catalog filters**. That is not personalization scoring.

---

## 5. Non-Goals

Confirmed non-goals for HS.6 (supported by Foundation §72 / HS-ADR-010 / HS.2–HS.5 deferrals):

1. **Production AI** / vendor SDKs for discovery
2. **AI-generated discovery** results or fabricated explanations
3. **Semantic / vector search** / embeddings
4. **LLM-based recommendations**
5. **Social networking** / follows / comments / messaging
6. **Automated personalization** / adaptive experience selection
7. **Complex recommendation engines** / engagement ranking
8. **Gamification** / streaks / XP
9. **TTS / narration**
10. **Story narrative promotion** from approved representations
11. **Story rejection lifecycle** for representations
12. **Marketplace**
13. **Direct mutation of canonical Story via discovery**
14. **Bypassing StoryConsent** or inventing a parallel consent model
15. **Collapsing Catalog into Discovery BC** or vice versa

If product later wants any of the above inside HS.6, that is a **scope change requiring a new decision**, not a silent expansion.

---

## 6. Discovery Model

### 6.1 What is being discovered?

**Primary discoverable units (recommended):**

1. **Published Stories** (Story aggregate as catalog entry)
2. **Discoverable Heroes** (Hero aggregate as catalog entry)

**Not primary units:**

- Raw `StoryRepresentation` rows as independent catalog products (representations support language/format/duration matching, but the discoverable *thing* remains the Story)
- `StoryUnderstanding` records
- Unapproved AI artifacts
- Capture media / private drafts

**Hero/Story combination:** Discovery results may *include* `heroId` + safe hero display fields on a Story summary for presentation, but the consistency boundary remains the Story (and separately the Hero). Do not create a `HeroStoryPair` aggregate.

### 6.2 Eligibility rules — **authoritative (D2/D3 confirmed)**

#### Story discoverable when all hold:

| Rule | Rationale |
|------|-----------|
| `lifecycleStatus == published` | Foundation + existing `publishedOnly` default |
| `visibility ∈ {public, community}` | **D2:** no private/unlisted leakage; publish ≠ catalog-discoverable |
| Publication consent already enforced at publish time | Reuse `StoryConsent`; do not duplicate on read model |
| Narrative not provisional | Already required to publish/approve |
| Hero exists and is discoverability-eligible | Avoid orphaned / private-hero leakage |
| Format/language/duration filters match only **authoritative** representations | **D3:** `isAuthoritative == true` (`!isAiGenerated \|\| isApproved`) |

**D2 locked:** Discovery-visible Story visibilities = `{public, community}` only.  
- `unlisted` = reachable by direct link / known id (HS.7+), **not** catalog discoverable  
- `private` / `draft` = never discoverable (also not publishable)

**D3 locked:** For representation-sensitive predicates (format, availableLanguage, duration), match only representations where `isAuthoritative == true`. Classification/suitability/spirituality remain Story-level authoritative fields.

#### Hero discoverable when all hold:

| Rule | Rationale |
|------|-----------|
| `status == active` (default) | Existing `activeOnly` |
| `visibility ∈ {public, community}` | **D2:** `unlisted`/`private` excluded from discovery/browse |

### 6.3 Consent / privacy interaction

```text
StoryConsent.publicationApproved  → required to publish (already domain-enforced)
Story.publish                     → requires visibility ∉ {private, draft}
HS.6 discovery                    → reads published + visibility-eligible only
```

Do **not**:

- add `StoryDiscoverabilityConsent`;
- copy consent timestamps into discovery DTOs;
- expose raw recordings, unapproved transcripts/scripts, understanding payloads, or private narrative drafts in discovery summaries;
- infer religion/identity of Hero from Story spirituality classification (HS-ADR-009).

**AI consent** is irrelevant to discovery *reads*. It remains a write-path gate for AI ports.

### 6.4 Information allowed in discovery results

Safe Story summary fields (application DTO):

- `storyId`, `heroId`
- `title` (published narrative title)
- `originalLanguage`, `availableLanguages` (**from authoritative representations + original**)
- classification dimensions needed for display/filter chips (subjects, challenges, theme ids, outcomes, emotional characters, audience, geography)
- content suitability summary (for client filtering UI)
- spirituality category/tradition as **content labels**, not Hero identity
- visibility (only if already discovery-eligible)
- published/updated timestamps if already on aggregate
- optional matched-filter explanation codes (D8)
- optional **authoritative** representation descriptors (format/language/duration) — never unapproved AI text bodies by default

Safe Hero summary fields:

- `heroId`, displayName, short biography (if visibility allows), experienceAreas, languages, visibility

**Exclude by default:** full narrative body (or gate behind explicit “get story detail” later in HS.7), media URLs to raw recordings, provenance internals, understanding payloads, unapproved representation text, identity user ids unless product requires.

> **D9 (soft):** Whether Story discovery summaries include narrative excerpt. **Recommendation:** title + classification only in HS.6; full narrative retrieval is HS.7 detail/playback.

---

## 7. Query vs Aggregate Boundaries

### 7.1 Decision

HS.6 is primarily a **query/read concern**.

| Approach | Use in HS.6? |
|----------|--------------|
| Load/mutate aggregates inside discovery | **No** mutation; load only to project summaries after ID query |
| Repository as sole browse API | Insufficient — need filter semantics already on search ports |
| Dedicated persistent read-model store / projection DB | **Not for MVP** (D4/D5 persistence) — premature with in-memory repos |
| Search ports returning IDs + application hydration | **Yes — recommended** |
| Indexes / Elastic / vector DB | Out of scope unless D4 expands |

### 7.2 Recommended flow

```text
DiscoverStoriesUseCase / BrowseStoriesUseCase
        ↓
StoryDiscoverabilityPolicy (pure rules)
        ↓
StorySearchPort.search(query with publishedOnly + visibility constraints)
        ↓
StoryRepository.findById (hydrate summaries for page of IDs)
        ↓
StoryDiscoverySummaryDto[]  (application read model)
```

**Why not a second source of truth?**  
Summaries are **derived projections** computed at query time from canonical `Story` / `Hero`. No `StoryDiscovery` aggregate. No write-side duplication of classification. If persistence projections are added later, they must be rebuildable from aggregates/events and never authoritative over Story.

### 7.3 Where policy lives

| Component | Layer | Role |
|-----------|-------|------|
| `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy` | Domain (pure) **or** application policy object | Eligibility predicates; no I/O |
| `StorySearchPort` | Domain port | Catalog filter substrate |
| Discover/Browse use cases | Application | Orchestrate port + policy + hydration |
| Summary DTOs | Application | Safe outward shape |
| In-memory adapters | Infrastructure | Deterministic filter implementation |
| Providers | Application (Riverpod) | Composition only |

Prefer keeping eligibility policy **outside** the search adapter if possible so adapters remain pure catalog matchers — **or** extend query fields (`visibilities`, `authoritativeRepresentationsOnly`) so replaceable engines can enforce the same contract. **Recommendation:** extend query fields + shared policy helper used by adapter and tests (single semantics). Confirm via **D2/D3**.

---

## 8. Ranking / Ordering / Filtering / Pagination

### 8.1 Ranking

**HS.6 does not require personalized ranking.**

Do **not** introduce relevance scores, ML rankers, engagement sorts, or DiscoveryProfile-weighted ordering in HS.6.

### 8.2 Deterministic ordering (required for browse)

Recommended stable sort for discovery/browse results:

1. `updatedAt` descending (or `createdAt` if preferred — **D10 soft**)
2. Tie-break: `storyId.value` ascending (lexicographic)

Hero browse:

1. `createdAt` descending  
2. Tie-break: `heroId.value` ascending

Ordering should be applied **after** filtering, **before** pagination, in the application layer (or inside the port if the contract documents it). Document the contract so replaceable adapters remain deterministic.

### 8.3 Filtering

Reuse existing multidimensional filters. Add:

- `visibilities: List<StoryVisibility>` (or fixed policy default)
- `authoritativeRepresentationsOnly: bool` (default true for discovery queries)
- Hero: `visibilities: List<HeroVisibility>`

### 8.4 Pagination

**Recommended (D6):** cursor- or offset-based page (`limit` + `offset`) on Discover/Browse use cases only. Search\* may remain unpaged for compatibility, or gain optional page args.

Empty pages and “no matches” are success with empty lists — not failures.

---

## 9. Domain Model Impact

### 9.1 New aggregates?

**None recommended.**

### 9.2 New entities?

**None recommended.**

### 9.3 New value objects / policies?

| Component | Why | Canonical/derived | Deterministic? |
|-----------|-----|-------------------|----------------|
| `StoryDiscoverabilityPolicy` | Centralize eligibility | Derived rules over canonical state | Yes |
| `HeroDiscoverabilityPolicy` | Same for heroes | Derived | Yes |
| Optional `DiscoveryMatchReason` (enum/VO) | Catalog-level explanation | Derived | Yes |

### 9.4 Port changes

| Port | Change |
|------|--------|
| `StorySearchPort` / `StorySearchQuery` | Add visibility + authoritative-representation flags; optionally document sort contract |
| `HeroSearchPort` / `HeroSearchQuery` | Add visibility filter |
| New `StoryDiscoveryPort`? | **Not recommended** for MVP — Discover\* is application orchestration over search + repos |
| Production search port impl | Only if D4 expands; otherwise keep in-memory |

### 9.5 Events

**No new domain events required for ordinary discovery queries.**

| Candidate | Needed? |
|-----------|---------|
| `StoriesDiscovered` | **No** — query, not a fact |
| `StoryBecameDiscoverable` | **Optional later** if projections need incremental indexing; not MVP |
| Existing `StoryPublished` / `StoryArchived` / `StoryRepresentationApproved` | Sufficient facts if future projections appear |

Prefer minimum event surface (HS-ADR-039 spirit).

---

## 10. Application-Layer Impact

### 10.1 New use cases (recommended)

| Use case | Responsibility |
|----------|----------------|
| `DiscoverStoriesUseCase` | Apply discovery defaults + eligibility + search + hydrate summaries + order + paginate |
| `DiscoverHeroesUseCase` | Same for heroes |
| `BrowseStoriesByCatalogUseCase` | Browse by one primary dimension (subject/challenge/theme/…) with discovery defaults |
| `GetStoryDiscoverySummaryUseCase` (optional) | Fetch one summary by id **only if discoverable** (prevents unlisted leakage via known-id browse APIs) |
| Keep `SearchStoriesUseCase` / `SearchHeroesUseCase` | Lower-level catalog filter returning IDs (may be used by Discover\* or admin tooling) |

Foundation §56 already separates Search\* from Discover\*. **D1 recommendation:** Discover\* = seeker-facing discovery defaults + summaries; Search\* = raw catalog filter.

### 10.2 DTOs / read models

| DTO | Contents |
|-----|----------|
| `DiscoverStoriesRequest` | filters + page + optional theme ids + language prefs |
| `DiscoverStoriesResponse` | `items: List<StoryDiscoverySummary>`, `totalCount?` / `nextOffset?` |
| `StoryDiscoverySummary` | safe fields (§6.4) |
| `DiscoverHeroesRequest` / `HeroDiscoverySummary` | analogous |
| `BrowseStoriesRequest` | dimension key + value + page |

These are **application** types, not domain aggregates.

### 10.3 Providers

Add Riverpod providers for:

- `storySearchPortProvider` / `heroSearchPortProvider` → in-memory adapters
- Discover/Browse/Search use cases

Follow existing repository provider patterns. Providers must not embed ranking rules.

---

## 11. Port / Adapter Impact

| Adapter | Change |
|---------|--------|
| `InMemoryStorySearchAdapter` | Honor new query fields; optionally share policy helper; keep deterministic |
| `InMemoryHeroSearchAdapter` | Honor visibility |
| Production search adapter | Out of MVP unless D4 |

No AI adapters. No network dependencies.

---

## 12. Persistence Impact

**MVP recommendation: no new persistence, tables, migrations, or projection stores.**

Reasons:

- Current stack is in-memory repositories.
- Discovery summaries are derivable from aggregates.
- HS-ADR-012 already anticipates replaceable search without requiring a new repository type.
- HS.2 explicitly rejected `StorySearchRepository`.

**If D4 chooses production search later:** introduce an infrastructure index adapter behind `StorySearchPort` that is rebuildable from `StoryRepository.findAll()` / future events — still not a second canonical store.

In-memory test doubles remain the default for unit/application tests.

---

## 13. Event Impact

| Event | Producer | Consumer | Necessary in HS.6? |
|-------|----------|----------|--------------------|
| `StoryPublished` | Story.publish | Future indexers | Already exists; no HS.6 requirement to consume |
| `StoryArchived` | Story.archive | Future indexers | Same |
| `StoryRepresentationApproved` | Story.approveRepresentation | Future authoritative filters | Exists; adapters read current state |
| New discovery events | — | — | **No** for MVP |

---

## 14. Consent / Privacy Rules (normative for implementation)

1. Discovery never grants access that publication + visibility would deny.
2. `publishedOnly=true` is the discovery default.
3. Visibility eligibility is mandatory (after D2 confirmation).
4. Do not return unapproved AI representation text in summaries.
5. Do not expose `StoryUnderstanding` via discovery APIs.
6. Do not expose capture media references meant for private processing.
7. Do not invent consent fields on discovery DTOs.
8. Revoked publication consent cannot un-publish by itself today; if product later allows unpublish-on-revoke, discovery must follow lifecycle/visibility truth — still no duplicated consent store.
9. Spirituality on Story ≠ Hero religious identity.

---

## 15. Testing Strategy

### 15.1 Domain / policy tests

- Story discoverable when published + allowed visibility + eligible hero
- Not discoverable when draft/processing/review/approved/archived/rejected/suspended/removed
- Not discoverable when visibility private/draft/(unlisted if D2 excludes)
- Hero not discoverable when private/archived
- Authoritative representation matching (D3): unapproved script format does not satisfy format filter; approved does
- Duration ANY-match still obeys HS-ADR-016 under authoritative constraint

### 15.2 Application tests

For each Discover/Browse use case:

- eligible Story appears
- ineligible Story does not
- unpublished / private does not appear
- unapproved representation does not leak into summaries or format filters
- consent is not re-implemented incorrectly (publish path still gate of record)
- deterministic ordering + tie-break
- empty results
- no duplicate IDs
- pagination windows (if D6 accepted)
- filter AND/OR semantics preserved
- Discover\* does not mutate aggregates / publish events

### 15.3 Adapter / repository tests

- Extend `search_adapters_test.dart` for visibility + authoritative flags
- Hero visibility cases
- Determinism across repeated calls

### 15.4 Architecture boundary tests

- Extend AI-boundary style tests if needed: discovery code must not import AI SDKs
- Discovery use cases must not write StoryUnderstanding / authoring ports

### 15.5 Explicitly not required

- UI widget tests (HS.7)
- Personalization A/B tests
- Vector recall metrics

---

## 16. ADR Requirements

Last accepted ADR: **HS-ADR-040**. New ADRs start at **HS-ADR-041**.

Create ADR files/entries during **implementation** (append to `docs/architecture/architecture-decisions.md`), not during this planning task.

### Proposed ADRs

#### HS-ADR-041 — HS.6 Discovery Is Catalog Findability, Not Personalization

- **Decision:** HS.6 delivers search, structured filtering, Hero/Story discovery, and catalog browsing as seeker-facing findability over eligible catalog content. Personalized “what next” remains HS.8.
- **Context:** Foundation §72 splits HS.6 vs HS.8; HS-ADR-010 already separates Catalog / Discovery / Personalization.
- **Alternatives:** Fold personalization into HS.6; rename HS.6 to Adaptive Discovery.
- **Consequences:** Clear non-goals; Discover\* must not score by user understanding.

#### HS-ADR-042 — Discover\* Use Cases Compose Search Ports; No StoryDiscovery Aggregate

- **Decision:** Add application Discover/Browse use cases + summary DTOs. Do not create a Discovery aggregate or StorySearchRepository.
- **Context:** Foundation §56 lists Discover\* separately; search ports already exist.
- **Alternatives:** Only expose Search\* IDs; create dedicated discovery port/aggregate; introduce projection DB now.
- **Consequences:** Hydration lives in application; adapters stay replaceable.

#### HS-ADR-043 — Discoverability Requires Lifecycle + Visibility Eligibility

- **Decision:** (Pending D2) Published lifecycle is necessary but not sufficient; visibility must be in an explicit allowed set for catalog discovery.
- **Context:** Current adapter ignores visibility; `unlisted` is publishable.
- **Alternatives:** Treat all published as discoverable; encode visibility inside lifecycle.
- **Consequences:** Privacy-preserving browse; unlisted direct-link semantics preserved for later HS.7.

#### HS-ADR-044 — Representation-Sensitive Discovery Filters Use Authoritative Representations Only

- **Decision:** (Pending D3) Format/language/duration discovery filters match only `isAuthoritative` representations.
- **Context:** HS-ADR-006/034; unapproved AI reps currently can satisfy filters.
- **Alternatives:** Keep ANY-representation matching; separate “draft catalog” API.
- **Consequences:** Prevents AI draft leakage into discoverability predicates.

#### HS-ADR-045 — HS.6 Ordering Is Deterministic Non-Personalized Sort

- **Decision:** Stable sort + tie-break; no relevance ranking in HS.6.
- **Context:** Avoid nondeterministic browse and premature ML.
- **Alternatives:** Random serendipity; engagement rank; leave unsorted.
- **Consequences:** Testable browse; serendipity deferred to HS.8 with explainability.

#### HS-ADR-046 — HS.6 Ships In-Memory Search Only (Unless D4 Overrides)

- **Decision:** Keep `InMemory*SearchAdapter` as the only implementation in HS.6 MVP; production engines remain future replaceable adapters under HS-ADR-012.
- **Context:** HS.2 deferred “production search engine e.g. HS.6” — “e.g.” is not a mandate.
- **Alternatives:** Build Elastic/meilisearch now.
- **Consequences:** Faster delivery; no migrations; port contract remains the extension point.

#### HS-ADR-047 — Discovery Summaries Are Derived Application Read Models

- **Decision:** Summary DTOs are non-authoritative projections; Story/Hero remain sources of truth.
- **Context:** Prefer derived data; avoid dual writes.
- **Alternatives:** Persist denormalized discovery documents as canonical.
- **Consequences:** Simpler consistency; possible later projection optimization.

---

## 17. Human Decision Gates

### Confirmed hard gates (implementation-binding)

#### D1 — Relationship between Search\* and Discover\* — **CONFIRMED**

- **Decision:** Reuse existing search ports; add application-level Discover/Browse use cases.
- **Binding interpretation:**
  - Keep `StorySearchPort` / `HeroSearchPort` (+ Search\* use cases) as the catalog-filter substrate.
  - Add `DiscoverStories` / `DiscoverHeroes` / catalog-browse application use cases with seeker defaults, eligibility, hydration to summary DTOs, ordering, and (per D6 recommendation) pagination.
  - Do **not** replace Search\* with Discover\*; Discover\* composes Search\*.

#### D2 — Visibility eligibility set — **CONFIRMED**

- **Decision:** Define one authoritative discoverability eligibility rule; **no private/unlisted leakage**.
- **Binding interpretation (authoritative eligibility rule):**
  - Story catalog-discoverable only when: `lifecycleStatus == published` **and** `visibility ∈ {public, community}` **and** owning Hero is discoverability-eligible.
  - Hero catalog-discoverable only when: `status == active` (default) **and** `visibility ∈ {public, community}`.
  - **Excluded from discovery/browse:** `private`, `draft` (Story), `unlisted`.
  - `unlisted` remains valid for direct-link / known-id access in later HS.7 detail flows; it must **not** appear in Discover/Browse/catalog search defaults used by discovery.
  - Eligibility is a single shared policy used by Discover/Browse (and by discovery-default search queries); do not scatter ad-hoc visibility checks.

#### D3 — Authoritative representation matching — **CONFIRMED**

- **Decision:** Only authoritative/approved representations participate in representation-dependent discovery/filtering.
- **Binding interpretation:**
  - Representation-dependent predicates (format, available language, duration, and any future rep-level filters) match only representations where `isAuthoritative == true` (`!isAiGenerated || isApproved`).
  - Discover/Browse defaults: `authoritativeRepresentationsOnly: true`.
  - Unapproved AI scripts/transcripts/translations must not make a Story appear under format/language/duration filters and must not appear as discoverable representation descriptors in summaries.

#### D4 — Production search engine in HS.6? — **CONFIRMED**

- **Decision:** Keep the MVP deterministic/in-memory; production search remains an adapter concern.
- **Binding interpretation:**
  - HS.6 ships / extends `InMemoryStorySearchAdapter` / `InMemoryHeroSearchAdapter` only.
  - Do **not** add Elastic/Meilisearch/vector engines, migrations, or persistent search indexes in HS.6.
  - Preserve replaceable `*SearchPort` contracts (HS-ADR-012) so a future production adapter can replace in-memory without changing Discover\* use cases.

#### D7 — UI in HS.6 vs HS.7 — **CONFIRMED**

- **Decision:** Keep HS.6 UI-agnostic; UI belongs to HS.7.
- **Binding interpretation:**
  - HS.6 delivers domain policy, ports/adapters, application use cases, DTOs, tests, Riverpod providers, and ADRs.
  - **No** Flutter discovery screens, widgets, or presentation models beyond application DTOs.
  - HS.7 owns Hero Experience UI (profiles, browsing screens, playback, collections).

### Soft gates (recommendations remain defaults unless overridden)

#### D5 — May Discover\* accept DiscoveryProfile theme IDs as filter input?

- **Status:** Open — use recommendation unless overridden.
- **Recommended:** Yes as **plain catalog filters**; Discover\* must not load DiscoveryProfile inside Hero & Story domain. Optional application façade may read profile in a cross-context app service later — not required for HS.6 MVP.
- **Alternatives:** Hard-wire DiscoveryProfile into Discover\*; forbid theme filters.
- **Consequence:** Boundary purity vs convenience.

#### D6 — Pagination required?

- **Status:** Open — use recommendation unless overridden.
- **Recommended:** Yes, minimal offset/limit.
- **Alternatives:** Return full lists until HS.7.
- **Consequence:** Test matrix and DTO shape.

#### D8 — Catalog match explanations

- **Status:** Open — use recommendation unless overridden.
- **Recommended:** Optional lightweight match reason codes in summaries; full “Why this story?” personalized explanations wait for HS.8.
- **Alternatives:** None in HS.6; full explanation engine now.
- **Consequence:** DTO fields + tests.

#### D9 — Narrative body in summaries

- **Status:** Open — use recommendation unless overridden.
- **Recommended:** Title + catalog metadata only; full narrative in HS.7 detail.
- **Alternatives:** Short excerpt; full narrative.
- **Consequence:** Privacy + payload size.

#### D10 — Default sort field

- **Status:** Open — use recommendation unless overridden.
- **Recommended:** `updatedAt` desc + id asc.
- **Alternatives:** createdAt; title.
- **Consequence:** Deterministic ordering tests.

---

## 18. Hard-Stop Conditions

Stop implementation planning/execution and escalate if:

1. Product demands **personalized ranking** inside HS.6 (conflicts with Foundation HS.8).
2. Product demands discovery of **unpublished** or **private** stories.
3. Product demands indexing **unapproved AI representations** as discoverable catalog entries.
4. A design requires a **second canonical Story store** for discovery.
5. Discoverability ownership is forced into Discovery BC aggregates (violates HS-ADR-001/010) without a new ADR.
6. An implementing agent attempts to reopen **confirmed** D1–D4/D7 without a new human decision (e.g. adding UI, production search, unlisted discovery, or ANY-rep filtering).

**Previously open hard unknowns — now locked:**

| Topic | Locked decision |
|-------|-----------------|
| Unlisted discoverability | **Not discoverable** (D2) |
| Production search mandate | **In-memory MVP**; adapter later (D4) |
| UI inclusion | **App-only**; UI → HS.7 (D7) |

---

## 19. Implementation Slices

Prefer vertical, independently testable slices. No single mega-PR.

### Slice 0 — Decision lock

- **Purpose:** Encode confirmed D1–D4/D7 into implementation kickoff ADRs; adopt D5/D6/D8/D9/D10 recommendations unless overridden.
- **Files:** `architecture-decisions.md` (HS-ADR-041+), this plan reference.
- **Deps:** Human architect — **satisfied for hard gates** (this revision).
- **Tests:** None.
- **AC:** ADRs cite confirmed D1–D4/D7; soft-gate defaults recorded.

### Slice 1 — Discoverability policy + search query extensions

- **Purpose:** Encode eligibility; extend `StorySearchQuery` / `HeroSearchQuery`; update in-memory adapters.
- **Files:**  
  - `domain/services/story_search_port.dart`  
  - `domain/services/hero_search_port.dart`  
  - new policy files under `domain/services/` or `domain/policies/`  
  - `infrastructure/search/in_memory_*_search_adapter.dart`  
  - `test/.../search_adapters_test.dart`
- **Deps:** Slice 0 (D2/D3).
- **Tests:** visibility, authoritative rep, publishedOnly, hero visibility, determinism.
- **AC:** Ineligible content never returned by discovery-default queries; existing multidimensional tests still pass.

### Slice 2 — Story discovery use case + summary DTOs

- **Purpose:** `DiscoverStoriesUseCase` + request/response DTOs + hydration + sort + pagination.
- **Files:** application use case + dto + tests; optionally keep Search\* unchanged.
- **Deps:** Slice 1.
- **Tests:** eligible/ineligible/empty/duplicates/pagination/ordering; no aggregate mutation.
- **AC:** Returns only safe summaries for eligible published stories.

### Slice 3 — Hero discovery use case + summary DTOs

- **Purpose:** `DiscoverHeroesUseCase` parallel to Slice 2.
- **Files:** application + tests; hero adapter visibility.
- **Deps:** Slice 1.
- **Tests:** active/visibility filters; empty; ordering.
- **AC:** Private/archived heroes excluded under discovery defaults.

### Slice 4 — Catalog browsing

- **Purpose:** `BrowseStoriesByCatalogUseCase` (by subject/challenge/theme/language/format).
- **Files:** application + tests.
- **Deps:** Slice 2.
- **Tests:** each primary dimension; combined with suitability caps; empty dimension values rejected or return empty.
- **AC:** Browse uses discovery eligibility defaults; no free-text required.

### Slice 5 — Riverpod providers + wiring

- **Purpose:** Wire search ports and Discover/Browse/Search use cases for composition.
- **Files:** `application/providers/...`
- **Deps:** Slices 2–4.
- **Tests:** provider construction / simple resolve test if pattern exists; otherwise use-case integration via providers in tests.
- **AC:** No UI required; providers do not embed personalization.

### Slice 6 — ADRs + focused validation + report

- **Purpose:** Accept HS-ADR-041…047 (as applicable), run analyzer + focused/full tests, write HS.6 implementation report.
- **Files:** `architecture-decisions.md`, `HS.6-*-Implementation-Report.md`
- **Deps:** Slices 1–5.
- **Tests:** full relevant suite green.
- **AC:** Analyzer clean on touched packages; report lists decisions, files, deferred HS.7/HS.8 work.

**Optional slices deferred by confirmed decisions:**

- **Slice 7 (production search):** deferred — D4 locks in-memory MVP.
- **Slice 8 (Flutter UI):** deferred — D7 locks UI to HS.7.

---

## 20. Acceptance Criteria (HS.6 implementation phase)

HS.6 implementation is complete when:

1. [x] D1–D4 and D7 confirmed (this plan revision); [ ] reflected in implementation ADRs
2. [ ] Discoverability eligibility enforced for Stories and Heroes (`{public, community}` only; no private/unlisted)
3. [ ] Structured catalog filtering remains multidimensional and documented
4. [ ] `DiscoverStories` / `DiscoverHeroes` exist with summary DTOs (D1)
5. [ ] Catalog browsing works without personalization
6. [ ] Unapproved representations do not leak (D3)
7. [ ] Private/unpublished/unlisted content does not appear in discovery/browse (D2)
8. [ ] Ordering is deterministic and tested
9. [ ] Pagination behaves correctly if D6 accepted
10. [ ] No production AI / vector / personalization code introduced
11. [ ] No new canonical dual store for discovery
12. [ ] Riverpod providers wire ports/use cases (if Slice 5 kept)
13. [ ] Focused tests pass; broader suite pass
14. [ ] `dart analyze` clean on changed code
15. [ ] Implementation report published under `docs/architecture/`
16. [ ] HS.7/HS.8 boundaries explicitly preserved

---

## 21. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Leaking private Story information | Visibility eligibility (D2); summary field allowlist; no understanding/raw media |
| Bypassing StoryConsent | Do not re-model consent; rely on publish invariants + lifecycle |
| Duplicating canonical state | Derived DTOs only; no discovery aggregate persistence |
| Coupling discovery to authoring | No authoring ports in Discover\*; ignore unapproved reps |
| Coupling discovery to AI providers | No AI ports; in-memory search only |
| Premature personalization | HS-ADR-041; reject ranking by DiscoveryProfile |
| Aggregate over-fetching | Search returns IDs; hydrate page only |
| Persistence/read-model divergence | No persistent projection in MVP |
| Nondeterministic ranking | Explicit sort + id tie-break |
| Unnecessary domain complexity | No new aggregates; policy + application orchestration |
| Treating Discovery BC as Story search | Keep NarrativeThemeId as reference only |
| Unlisted treated as public | D2 default excludes unlisted from browse |
| Format filter satisfied by unapproved AI script | D3 authoritative matching |

---

## 22. Alignment With Existing Patterns

Follow existing Everyone’s Heroes architecture:

- DDD + hexagonal ports/adapters
- Domain free of Flutter/Riverpod/AI SDKs
- Application orchestration + Result types
- Riverpod for composition only
- Typed past-tense domain events (no query events)
- Repository abstractions without noun-driven repository sprawl
- Deterministic in-memory adapters for tests
- Naming consistent with `SearchStoriesUseCase`, `InMemoryStorySearchAdapter`, HS-ADR style

Do not introduce CQRS frameworks, GraphQL, or competing DI systems.

---

## 23. Files Likely Touched (implementation phase; not this planning task)

```text
docs/architecture/architecture-decisions.md
docs/architecture/HS.6-Hero-Story-Discovery-Implementation-Report.md

lib/features/hero_story/domain/services/story_search_port.dart
lib/features/hero_story/domain/services/hero_search_port.dart
lib/features/hero_story/domain/services|policies/*discoverability*
lib/features/hero_story/application/use_cases/discover_stories_use_case.dart
lib/features/hero_story/application/use_cases/discover_heroes_use_case.dart
lib/features/hero_story/application/use_cases/browse_stories_by_catalog_use_case.dart
lib/features/hero_story/application/dto/requests|responses/*discovery*
lib/features/hero_story/application/providers/**/*
lib/features/hero_story/infrastructure/search/in_memory_story_search_adapter.dart
lib/features/hero_story/infrastructure/search/in_memory_hero_search_adapter.dart

test/features/hero_story/**/hs6_*_test.dart
test/features/hero_story/infrastructure/search/search_adapters_test.dart
```

**Do not touch for HS.6 MVP (unless decision expands):** production AI adapters, StoryUnderstanding write paths, authoring ports, Life Journey experience selection, DiscoveryProfile aggregate internals, Flutter screens.

---

## 24. Planning Artifact Completeness Checklist

- [x] Current architecture baseline
- [x] HS.6 objective
- [x] Scope / non-goals
- [x] Domain / application / port / persistence / event impacts
- [x] Consent/privacy rules
- [x] Discovery/query model
- [x] Ranking/filtering/pagination decisions
- [x] Testing strategy
- [x] ADR requirements (041+)
- [x] Implementation slices
- [x] Acceptance criteria
- [x] Risks
- [x] Human decision gates
- [x] Hard-stop conditions

---

## 25. Final Planning Verdict

| Item | Verdict |
|------|---------|
| HS.6 meaning | Catalog findability: search, filter, discover Heroes/Stories, browse |
| Personalization | **Out** → HS.8 |
| UI screens | **Out (D7 confirmed)** → HS.7 |
| New aggregates | **None** |
| Reuse search ports | **Yes (D1 confirmed)** + Discover/Browse application use cases |
| Critical fixes | Visibility eligibility **{public, community}** (D2) + authoritative representation matching (D3) |
| Production search | **Not in HS.6** — in-memory MVP; adapter later (D4) |
| Ready to implement? | **Yes** — hard gates D1–D4 and D7 confirmed |

**Hard gates are locked. Soft gates D5/D6/D8/D9/D10 use plan recommendations unless overridden.**

**This revision records decisions only. No HS.6 production implementation was performed.**

---

*End of HS.6 — Hero & Story Discovery Implementation Plan.*
