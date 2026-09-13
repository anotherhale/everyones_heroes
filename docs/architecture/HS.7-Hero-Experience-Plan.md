# HS.7 — Hero Experience Plan

**Phase:** HS.7 — Hero Experience  
**Status:** Planning complete (no production implementation in this deliverable)  
**Date:** 2026-09-12  
**Constraint:** Planning only. Do not implement HS.7 production code, screens, adapters, migrations, SDKs, or speculative personalization in this planning task.  
**Predecessor:** HS.6 Hero & Story Discovery — **COMPLETE / MERGED / CLOSED**  
**Related foundation:** UI.3 Adaptive Experience Foundation — **COMPLETE** (reflection-only selector today)  
**Successor (out of scope):** HS.8 Adaptive Hero Discovery  

**Document path note:** Repository convention for phase plans is `docs/architecture/HS.N-*-Plan.md` (see HS.2–HS.6). This file follows that convention. The brief’s suggested `HS.7-Hero-Experience-Plan.md` name is satisfied.

---

## 1. Executive Summary

HS.7 establishes the **smallest architecturally correct Hero Experience** that turns HS.6 discoverable Heroes/Stories into meaningful user-facing experiences—without becoming social media, without absorbing HS.8 personalization, and without collapsing Hero & Story into Life Journey or UI.3 selection logic.

### Recommended architecture (one sentence)

Reuse HS.6 Discover\* as the only catalog entry; add **discoverability-gated detail/experience application use cases + safe experience DTOs**; add a **deterministic Story consumption seam** (text/script first; media via existing `StoryMediaStoragePort`); add a **Story → `AdaptiveExperience` composer** that plugs into the existing UI.3 `ExperienceSelectionService` boundary; keep reflection **optional and evidence-first**; defer Hero Journey aggregate, collections, saves/likes, and personalized ranking.

### Central answer

```text
HS.6 Discovery
      ↓
Discoverable Hero / Story (public|community + published/active)
      ↓
HS.7 Experience application (detail + consume + optional AdaptiveExperience mapping)
      ↓
Presentation (Hero/Story screens)  —  and/or  —  UI.3 Today’s Experience (type=story)
      ↓
Optional Reflection (existing H.2 pipeline)
      ↓
Behavioral Evidence (only if reflection/action produces it)
```

**Story interaction ≠ Behavioral Evidence** (existing **HS-ADR-011**). HS.7 must preserve that boundary.

### Planning readiness

**CONDITIONALLY READY FOR IMPLEMENTATION** after human confirmation of the approval-gate table in §39 (especially Hero Journey, unlisted known-id access, collections, story-begin vs reflection-begin, and whether Today’s Experience may return `ExperienceType.story` in HS.7).

---

## 2. Current Architecture Baseline

### 2.1 Source-of-truth hierarchy applied

1. **Accepted HS-ADRs through HS-ADR-047** — binding.
2. **Merged HS.1–HS.6 implementation** (`lib/features/hero_story/**`) — authoritative for current behavior.
3. **UI.3 implementation** (`lib/features/life_journey/**` Adaptive Experience seam) — authoritative for experience selection/presentation.
4. **HS.6 Implementation Report** — accepted complete; explicitly defers HS.7 UI / playback / collections and HS.8 personalization.
5. **Foundation roadmap HS.7** — Hero profiles, Story browsing, story playback, Hero journeys, collections (product intent; not a mandate to implement all in Slice 1).
6. **Architecture maps / AGENTS.md** — documentation drift possible; reported, not rewritten here.

### 2.2 Verified EXISTS (merged code)

| Capability | Exact symbols / paths |
|------------|------------------------|
| Story discovery | `DiscoverStoriesUseCase`, `DiscoverStoriesRequest/Response`, `StoryDiscoverySummary` |
| Hero discovery | `DiscoverHeroesUseCase`, `DiscoverHeroesRequest/Response`, `HeroDiscoverySummary` |
| Catalog browse | `BrowseStoriesByCatalogUseCase`, `BrowseStoriesByCatalogRequest`, `CatalogBrowseDimension` |
| Known-id discovery summary | `GetStoryDiscoverySummaryUseCase` (fails closed if not discoverable) |
| Discoverability | `StoryDiscoverabilityPolicy`, `HeroDiscoverabilityPolicy` — `{public, community}` |
| Search substrate | `StorySearchPort` / `HeroSearchPort` + in-memory adapters; `authoritativeRepresentationsOnly`, `visibilities` |
| Hero stories query substrate | `StoryRepository.findByHeroId(HeroId)` **EXISTS**; DiscoverStories also accepts `heroId` filter |
| Representation authority | `StoryRepresentation.isAuthoritative => !isAiGenerated \|\| isApproved` |
| Media storage | `StoryMediaStoragePort` (`store` / `exists` / `retrieve` / `delete`) + in-memory adapter |
| Media pointer | `MediaReference` (URI string) on representation |
| Adaptive Experience model | `AdaptiveExperience`, `ExperienceType` **includes `story`**, `ExperienceAction.begin` |
| Selection seam | `ExperienceSelectionService.selectFor(Journey)` → `DeterministicExperienceSelectionService` (**reflection only today**) |
| Today’s Experience | `GetTodayExperienceUseCase`, `todayExperienceProvider`, `TodayExperienceViewModel`, `HomeScreen` |
| Begin experience | `BeginExperienceUseCase` — **always creates a Reflection** then UI navigates to `ReflectScreen` |
| Evidence pipeline | Reflection submit → analysis → `BehavioralEvidenceDetected` → pattern detection (**EXISTS**) |
| Discover screen | `DiscoverScreen` — **life-meaning prompts**, not Hero/Story catalog UI |
| hero_story presentation | **DOES NOT EXIST** (no `presentation/` under `hero_story`) |
| Last ADR | **HS-ADR-047** |

### 2.3 Explicit GAPS (not present; candidates for HS.7 or deferral)

| Gap | Notes |
|-----|-------|
| `GetHeroDiscoverySummaryUseCase` | Not present; Hero detail needed for experience |
| Story/Hero **experience detail** DTOs (narrative body, playable representation payload) | Discovery summaries intentionally exclude narrative/media bodies (HS.6 D9) |
| Playback port / session model | Storage exists; playback orchestration does not |
| `ExperienceType.story` selection path | Enum exists; selector never returns it; begin always opens reflection |
| Hero Journey aggregate / chronology VO | Conceptual only in Foundation §36 |
| Collections / saved stories / likes / follows | Not present in hero_story |
| Production media streaming | Not present; in-memory bytes only |
| hero_story Riverpod providers beyond discovery/search/repos | Create/update/publish use cases not provider-wired |

### 2.4 Terminology (preserve)

| Term | Meaning in HS.7 |
|------|-----------------|
| **Catalog** | What a Story/Hero *is* (HS.2 classification) |
| **Discovery (HS.6)** | Findable eligible catalog entries |
| **Hero Experience (HS.7)** | Meaningful consume/browse/detail surfaces over discoverable content |
| **Adaptive Experience (UI.3)** | Application-facing “what to do now” card/seam |
| **Personalization (HS.8)** | Which Hero/Story should *this person* see next |
| **Behavioral Evidence (H.2)** | Observed growth-relevant facts from reflection/action — not mere playback |

---

## 3. HS.7 Product Objective

### Objective

Make a **real discoverable Story (and Hero)** usable as a **meaningful experience**: open → understand context → consume an **approved/authoritative representation** → optionally continue into reflection—while preserving HS.6 safety and UI.3 seams.

Foundation §72 HS.7 intent:

- Hero profiles  
- Story browsing  
- Story playback  
- Hero journeys  
- collections  

HS.7 Slice strategy below **does not** implement all five as first-class domain systems. It proves the experience path first; journeys/collections are evaluated and mostly deferred.

### Product philosophy guardrail

```text
Discovery → Meaning → Connection → Reflection → Action → Growth
```

Not:

```text
Attention → Engagement → Retention
```

Therefore HS.7 excludes social graph mechanics and engagement optimization.

---

## 4. Bounded-Context Boundaries

| Context | Owns in HS.7 | Must not own |
|---------|--------------|--------------|
| **Hero & Story** | Hero/Story canonical state, representations, media refs, lifecycle, catalog fields, discoverability metadata, experience **content** DTOs, playback **content retrieval** orchestration | Personalization ranking; behavioral evidence interpretation; UI.3 selection policy |
| **Discovery (person inspiration BC)** | Narrative themes (ids only referenced) | Story search; Hero Experience screens |
| **HS.6 Discovery APIs (within Hero & Story app layer)** | Findability queries already shipped | Experience detail narrative bodies (by design left to HS.7) |
| **Life Journey / H.2** | Reflection, Behavioral Evidence, Behavior Patterns | Story playback state; Hero profile |
| **UI.3 / Application Experience** | `AdaptiveExperience` contract, Today’s Experience presentation, selection port | Direct repository access to Story/Hero; catalog rules; ranking |
| **HS.8** | Future personalized Hero/Story selection | Anything required for HS.7 MVP |

Cross-context rule: compose via application DTOs/ports/events — never leak aggregates into presentation.

---

## 5. Existing Capabilities Reused

**Reuse (do not duplicate):**

1. `DiscoverStoriesUseCase` / `DiscoverHeroesUseCase` / `BrowseStoriesByCatalogUseCase`  
2. `GetStoryDiscoverySummaryUseCase` for safe card/summary refresh by id  
3. `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy`  
4. `StorySearchPort` eligibility flags (`visibilities`, `authoritativeRepresentationsOnly`)  
5. `StoryRepository.findByHeroId` + DiscoverStories `heroId` filter for “Hero’s Stories”  
6. `StoryRepresentation.isAuthoritative`  
7. `StoryMediaStoragePort.retrieve` for media bytes  
8. `AdaptiveExperience` + `ExperienceType.story` + `ExperienceSelectionService`  
9. Existing reflection create/submit/analysis pipeline for **optional** post-story reflection  
10. Riverpod patterns from `life_journey` presentation + HS.6 discovery providers  

**Do not create:** second search port, second discoverability policy, StoryDiscovery aggregate, HeroExperience aggregate, Playback aggregate (unless approval gate overturns).

---

## 6. Proposed HS.7 Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│ Presentation (NEW under hero_story/presentation + UI.3 hooks)   │
│  HeroCatalogScreen / HeroProfileScreen / StoryDetailScreen /    │
│  StoryConsumeScreen / optional Today’s Experience story path    │
└───────────────────────────────┬─────────────────────────────────┘
                                │ view models only
┌───────────────────────────────▼─────────────────────────────────┐
│ Application (HS.7)                                              │
│  GetHeroExperienceUseCase                                       │
│  GetStoryExperienceUseCase                                      │
│  ListHeroStoriesUseCase (thin compose over DiscoverStories)     │
│  ResolvePlayableRepresentationUseCase                           │
│  LoadStoryMediaUseCase (via StoryMediaStoragePort)              │
│  ComposeStoryAdaptiveExperienceUseCase (mapper)                │
│  Optional: CompleteStoryExperienceUseCase (no evidence emit)    │
│  Optional: BeginStoryReflectionUseCase → existing reflection    │
└───────────────┬─────────────────────────┬───────────────────────┘
                │                         │
┌───────────────▼──────────┐   ┌──────────▼───────────────────────┐
│ Hero & Story domain      │   │ UI.3 / Life Journey              │
│ policies, repos, media   │   │ ExperienceSelectionService       │
│ HS.6 Discover*           │   │ GetTodayExperience / Begin*      │
└──────────────────────────┘   └──────────────────────────────────┘
```

### Hard rules

1. Every experience entry path re-applies discoverability (never trust a prior list alone).  
2. Representation-sensitive resolution uses authoritative reps only.  
3. Presentation never imports repositories/policies/detectors.  
4. Playback/completion does not publish Behavioral Evidence events.  
5. No HS.8 ranking inside selectors beyond an optional **deterministic demo candidate** behind the existing port.

---

## 7. Hero Experience Model

### EXISTS inputs

`Hero` aggregate + `HeroProfile` (`displayName`, `biography?`, `experienceAreas`, `languages`, `geographicContext?`) + `HeroVisibility` + `HeroStatus` + `HeroDiscoverySummary`.

### PROPOSED application read model

`HeroExperienceDetail` (application DTO, not a new aggregate):

| Field | Source | Notes |
|-------|--------|-------|
| `heroId` | Hero | required |
| `displayName` | profile | safe |
| `biography` | profile | only if hero discoverable |
| `experienceAreas` | profile | safe |
| `languages` | profile | safe |
| `geographicContext` | profile | **include** (missing from `HeroDiscoverySummary` today) |
| `visibility` | Hero | only discoverable values reach DTO |
| `storyCount` | derived | count of **discoverable** stories for hero |
| `createdAt` | Hero | optional |

**Exclude:** `identityUserId`, private/unlisted heroes, archived heroes, internal events.

### Decision

Prefer **application DTO + use case** over a `HeroProfile` aggregate. Existing Hero aggregate already holds canonical profile facts.

---

## 8. Story Experience Model

### EXISTS inputs

`StoryDiscoverySummary` (no narrative body) + full `Story` aggregate (narrative, representations, classification, suitability, spirituality, visibility, lifecycle).

### PROPOSED application read model

`StoryExperienceDetail`:

| Field | Rule |
|-------|------|
| Identity | `storyId`, `heroId`, `heroDisplayName` |
| Title | published title |
| Narrative body | **included for experience detail** (HS.6 deferred this to HS.7) — only if story+hero discoverable |
| Catalog chips | subjects/challenges/themes/outcomes/etc. |
| Suitability / spirituality | content labels only (not Hero identity) |
| `playableRepresentations` | authoritative only; include format, language, duration, representationId, hasText, hasMedia |
| Primary playable | resolved by language/format policy (§23) |
| Visibility | discoverable only |

**Exclude by default:** unapproved representation text, understanding payloads, provenance internals, raw private capture URIs unless representation is authoritative and discoverability passed.

`StoryExperienceDetail` ≠ canonical Story store. Derived at query time (same spirit as HS-ADR-047).

---

## 9. Story Playback Architecture

### Distinctions (normative)

| Concept | Meaning | Layer |
|---------|---------|-------|
| **Story** | Canonical narrative aggregate | Domain |
| **StoryRepresentation** | Language/format form of the Story | Domain entity |
| **MediaReference** | Pointer to bytes | Domain VO |
| **StoryMediaStoragePort** | Byte persistence/retrieval | Domain port / infra adapter |
| **Playback / Consume session** | Ephemeral UX progression (position, started/completed) | Application or presentation state — **not an aggregate** |

### EXISTS

- Formats: `audio`, `video`, `written`, `transcript`, `script`, `shortForm`, `longForm` (`StoryRepresentationFormat`)  
- `StoryMediaStoragePort.retrieve(MediaReference) → Uint8List?`  
- In-memory media adapter  

### PROPOSED HS.7 playback meaning (MVP)

1. **Text-like formats** (`written`, `transcript`, `script`, `shortForm`, `longForm`): render authoritative `textContent` in UI.  
2. **Audio/video**: retrieve bytes via `StoryMediaStoragePort` and play through Flutter widgets / simple in-app players.  
3. No CDN, HLS, DRM, or vendor streaming platform in HS.7.  
4. No `PlaybackAggregate`. Optional `StoryConsumeProgress` in-memory map keyed by `(user/device, storyId, representationId)` only if Slice UX needs resume — default **defer persistence**.

### PROPOSED ports

| Port | Status | Role |
|------|--------|------|
| `StoryMediaStoragePort` | EXISTS | bytes |
| `StoryPlaybackPort` | **NOT recommended for MVP** | Would wrap player SDKs; keep player in presentation + storage port until a second consumer appears |

---

## 10. Hero Profile

### Recommendation

Implement **Hero Profile as an experience screen** backed by `GetHeroExperienceUseCase` → `HeroExperienceDetail`.

Flow:

```text
DiscoverHeroesUseCase
      ↓
Hero list (HeroDiscoverySummary)
      ↓
GetHeroExperienceUseCase(heroId)  // re-check HeroDiscoverabilityPolicy
      ↓
HeroProfileScreen
      ↓
ListHeroStoriesUseCase(heroId) → DiscoverStories(heroId: …)
      ↓
StoryExperienceDetail
```

No separate `HeroProfile` aggregate.

---

## 11. Hero Journey Decision

### Foundation warning (EXISTS in docs)

Hero chronological narrative ≠ user’s Life Journey aggregate.

### Options evaluated

| Option | Verdict |
|--------|---------|
| 1. Hero-owned chronological Story ordering (by `createdAt`/`updatedAt`) | **Recommended for HS.7** as presentation/application listing only |
| 2. Presentation-level timeline UI over discoverable stories | Same as (1); preferred |
| 3. Dedicated Hero narrative structure (Childhood/Challenge/…) | **STOP** — requires new domain model / taxonomy decision |
| 4. Defer entirely | Acceptable if Slice 2 ships Hero Stories list without calling it “Journey” |

### Recommendation

**Do not create a `HeroJourney` aggregate in HS.7.**

Ship “Hero’s Stories” ordered deterministically (`createdAt` asc for chronological biography feel, or `updatedAt` desc for recency — **open decision**, see §34/§39). Label UI as “Stories” unless product explicitly approves “Journey” naming without structured acts.

If product requires Childhood/Challenge/Turning Point/Transformation/Contribution as first-class structure: **escalate** — that is a new ADR beyond current code.

---

## 12. Story Browsing

### Recommendation

HS.7 browsing **is** HS.6 discovery + presentation.

```text
DiscoverStories / BrowseStoriesByCatalog / DiscoverHeroes
        ↓
HS.7 presentation list screens + view models
```

- No HS.7 search port.  
- No widget-local discoverability rules.  
- Presentation maps `StoryDiscoverySummary` / `HeroDiscoverySummary` → list cards.  
- Pull-to-refresh re-invokes Discover\* (eligibility re-applied server-side/app-side).

---

## 13. Story Detail

### Recommendation

Add **`GetStoryExperienceUseCase`** (PROPOSED):

1. Load Story + Hero by id.  
2. Require `StoryDiscoverabilityPolicy.isDiscoverable(story)` and `HeroDiscoverabilityPolicy.isDiscoverable(hero)`.  
3. Project `StoryExperienceDetail` including narrative + authoritative playable descriptors.  
4. Fail closed otherwise (same spirit as `GetStoryDiscoverySummaryUseCase`).

**Unlisted known-id access:** Foundation allows unlisted as share-link semantics. HS.6 discovery excludes unlisted.  

**HS.7 recommendation:** Slice 1 keeps **discoverability == experience eligibility** (public|community only). Unlisted direct-link experience is an **open decision** (§34) and requires human approval before implementation.

---

## 14. Story → Adaptive Experience Integration

### EXISTS

- `ExperienceType.story`  
- `ExperienceSelectionService`  
- `DeterministicExperienceSelectionService` returns only `ExperienceType.reflection`  
- `BeginExperienceUseCase` assumes reflection  

### PROPOSED mapping

Composer (application, Hero & Story or thin cross-context app service):

```text
StoryExperienceDetail (or summary + title)
        ↓
AdaptiveExperience(
  id: 'story:<storyId>',
  type: ExperienceType.story,
  title: story.title,
  description: short safe blurb (not necessarily full narrative),
  action: ExperienceAction.begin,
  rationale: optional catalog match reason / “From Hero stories”,
)
```

### How selection should work in HS.7

**Preferred (boundary-clean):**

1. HS.7 provides `StoryAdaptiveExperienceComposer` + a **candidate provider port** (e.g. `StoryExperienceCandidateSource`) returning 0..N deterministic candidates from DiscoverStories (e.g. newest discoverable story).  
2. Extend `DeterministicExperienceSelectionService` **only via explicit approved rule** (e.g. “if no consistency pattern and a candidate exists, return story once”) — **or** keep selector reflection-only and let Hero Experience UI be the primary entry (Today’s Experience integration in Slice 3).  

**Recommendation:**  

- Slice 1–2: Hero Experience UI entry (browse → detail → consume).  
- Slice 3: Wire a **deterministic optional story candidate** into `ExperienceSelectionService` behind a feature flag / clear rule, proving UI.3 seam reuse without HS.8 ranking.  
- Do **not** put StoryRepository calls in widgets.

### Begin path for `ExperienceType.story`

**EXISTS problem:** `BeginExperienceUseCase` always creates Reflection.

**PROPOSED:** Branch by experience type (approval required):

| Type | Begin behavior |
|------|----------------|
| `reflection` | Keep current (create Reflection → ReflectScreen) |
| `story` | Navigate/open Story Experience consume flow for `storyId` encoded in experience id; **do not** auto-create Reflection |
| other types | unchanged / unsupported |

Optional post-consume CTA: “Reflect on this story” → existing reflection pipeline.

---

## 15. Reflection Integration

```text
Story consumed
      ↓
Optional user chooses Reflect
      ↓
CreateReflectionUseCase (existing)
      ↓
ReflectScreen (existing)
      ↓
SubmitReflection → H.2 evidence pipeline (existing)
```

### Normative

- Playback start/complete **MUST NOT** emit `BehavioralEvidence*`.  
- No silent “inspired” evidence.  
- Aligns with **HS-ADR-011**.

### PROPOSED thin use case (optional)

`StartStoryReflectionUseCase(storyId)` → creates reflection with optional metadata linking `storyId` as **context reference** (string/id on reflection request if supported; if Reflection aggregate cannot store foreign StoryId today, keep link in application/presentation only until a Life Journey ADR allows it).

**Open decision:** whether Reflection gains an optional `sourceStoryId` field (cross-context reference). Default HS.7: **do not modify Reflection aggregate**; pass story title as prompt text only.

---

## 16. Collections Decision

### Evaluation

| Meaning | Needed for Slice 1? | Aggregate justified? |
|---------|---------------------|----------------------|
| Saved Stories | No | Not yet |
| Curated editorial collections | No | Would need ownership/lifecycle |
| Hero Collections | No | Premature |
| Thematic Collections | Overlaps catalog browse | Use `BrowseStoriesByCatalog` |
| Personal Collections | No | Privacy + persistence |

### Recommendation

**Defer collections entirely from HS.7 MVP.** Foundation lists them as HS.7 intent, but current architecture lacks invariants, owners, or consumers. Revisit after Story Experience is proven.

If product insists on one: prefer **personal Saved Stories** as a tiny application preference list (in-memory first) — still not a domain aggregate — and require approval.

---

## 17. Persistence Decision

| Data | HS.7 MVP |
|------|----------|
| Hero/Story canonical | Existing in-memory repos |
| Discovery | Derived |
| Experience detail | Derived |
| Media bytes | Existing in-memory media adapter |
| Playback progress | **Defer** (or ephemeral presentation state) |
| Collections / saves | **Defer** |
| New DB/migrations | **None** |

Deterministic in-memory remains the phase default (consistent with HS.3–HS.6).

---

## 18. Application Use Cases

| Use case | Status | Responsibility | In HS.7? |
|----------|--------|----------------|----------|
| `DiscoverStoriesUseCase` | EXISTS | Findable stories | Reuse |
| `DiscoverHeroesUseCase` | EXISTS | Findable heroes | Reuse |
| `BrowseStoriesByCatalogUseCase` | EXISTS | Dimension browse | Reuse |
| `GetStoryDiscoverySummaryUseCase` | EXISTS | Safe summary by id | Reuse |
| `GetHeroExperienceUseCase` | **PROPOSED** | Discoverability-gated hero detail DTO | Yes |
| `GetStoryExperienceUseCase` | **PROPOSED** | Discoverability-gated story detail + narrative + playable reps | Yes |
| `ListHeroStoriesUseCase` | **PROPOSED** (optional thin) | Compose DiscoverStories(`heroId`) | Yes (or call Discover directly from provider) |
| `ResolvePlayableRepresentationUseCase` | **PROPOSED** | Pick authoritative rep by language/format prefs | Yes |
| `LoadStoryMediaUseCase` | **PROPOSED** | `StoryMediaStoragePort.retrieve` | Yes |
| `ComposeStoryAdaptiveExperienceUseCase` | **PROPOSED** | Story → `AdaptiveExperience` | Yes (Slice 3) |
| `CompleteStoryExperienceUseCase` | **PROPOSED optional** | Mark consume complete locally; **no evidence event** | Maybe |
| `GetHeroJourneyUseCase` | **NOT PROPOSED** | Would imply fake aggregate | No |
| `GetCollectionUseCase` | **NOT PROPOSED** | Deferred | No |
| `PlayStoryUseCase` as domain mutation | **NOT PROPOSED** | Playback is not Story mutation | No |

Avoid use cases that only forward a single repository call **unless** they enforce discoverability + DTO projection (detail use cases qualify).

---

## 19. Ports and Adapters

| Port | Status | HS.7 action |
|------|--------|-------------|
| `StorySearchPort` / `HeroSearchPort` | EXISTS | Reuse |
| `StoryMediaStoragePort` | EXISTS | Reuse for consume |
| `StoryCapturePort` / AI ports | EXISTS | Out of HS.7 experience path |
| New `StoryPlaybackPort` | — | **Defer** |
| New `StoryExperienceCandidateSource` | PROPOSED | Optional for UI.3 selector integration |
| Production search / streaming | — | Out of scope |

Adapters remain in-memory/replaceable. No vendor SDKs.

---

## 20. Presentation Architecture

### NEW (PROPOSED) under `lib/features/hero_story/presentation/`

Minimum Slice 1–2 screens:

1. **StoryCatalogScreen** — DiscoverStories list  
2. **StoryDetailScreen** — experience detail + CTA Consume  
3. **StoryConsumeScreen** — text render and/or audio player  
4. **HeroCatalogScreen** — DiscoverHeroes list  
5. **HeroProfileScreen** — hero detail + stories list  

### Integration with existing shell

- Do **not** overload `DiscoverScreen` (life-meaning) without product approval; prefer a new nav entry (“Heroes” / “Stories”) or a clearly separated tab section.  
- Reuse UI.1/UI.3 patterns: `ConsumerWidget`, view models, providers, loading/error/empty states.  
- `HomeScreen` / `ExperienceScreen` gain story-type handling only in Slice 3.

### View models (PROPOSED)

- `HeroExperienceViewModel`  
- `StoryExperienceViewModel`  
- `StoryConsumeViewModel`  
- Map from application DTOs only.

---

## 21. Riverpod Architecture

### EXISTS to reuse

- `discoverStoriesUseCaseProvider`, `discoverHeroesUseCaseProvider`, `browseStoriesByCatalogUseCaseProvider`, `getStoryDiscoverySummaryUseCaseProvider`  
- `storyRepositoryProvider`, `heroRepositoryProvider`, search port providers  
- `todayExperienceProvider`, `getTodayExperienceUseCaseProvider`, `beginExperienceUseCaseProvider`  

### PROPOSED providers

- `getHeroExperienceUseCaseProvider`  
- `getStoryExperienceUseCaseProvider`  
- `resolvePlayableRepresentationUseCaseProvider`  
- `loadStoryMediaUseCaseProvider`  
- `heroExperienceProvider(heroId)` / `storyExperienceProvider(storyId)` as `FutureProvider.autoDispose`  
- `storyConsumeProvider(...)` for consume session UI state  

Follow life_journey conventions: application providers under `application/providers`, presentation providers under `presentation/providers`.

No selection/ranking rules inside providers.

---

## 22. Event Strategy

### Recommendation: **event-minimal (no new domain events required for MVP)**

| Candidate | Needed in HS.7 MVP? | Why |
|-----------|---------------------|-----|
| `StoryExperienceStarted` | No | UX state; no other BC consumer |
| `StoryExperienceCompleted` | No | Must not become evidence; avoid temptation |
| `StoryPlaybackStarted/Completed` | No | Same |
| `StorySaved` | No | Collections deferred |
| Existing `StoryPublished` / `StoryRepresentationApproved` | Already enough for future indexers | |

If product later needs analytics, use an application telemetry port — not Life Journey evidence events.

---

## 23. Language Strategy

### EXISTS

- Story `originalLanguage`  
- Representation languages  
- Discovery availableLanguage filter (authoritative-only on Discover\*)  
- Hero profile languages  

### PROPOSED HS.7 resolution order for playable representation

1. Caller-supplied preferred `LanguageCode` (explicit UI control)  
2. Else device/app locale if an authoritative rep exists in that language  
3. Else original language authoritative rep  
4. Else any authoritative rep (deterministic: stable sort by language code + format priority)

**Format priority (deterministic MVP suggestion):**  
`audio` → `video` → `written` → `script` → `shortForm` → `longForm` → `transcript`  
(adjust only with approval)

No ML language detection. No silent mutation of `Story.originalLanguage`.

---

## 24. Discoverability / Safety Strategy

Reuse policies; never reimplement in widgets.

| Path | Gate |
|------|------|
| Lists | Discover\* defaults |
| Detail by id | Re-check policies in Get\*Experience |
| Playable content | Authoritative representations only |
| Media retrieve | Only after detail gate + authoritative rep media ref |
| Suitability | Surface labels; optional client-side max filters already on Discover\* |
| Spirituality | Content label only; not Hero religion |

Private / draft / unlisted / unpublished / unapproved AI must not appear on default experience paths.

---

## 25. Aggregate Boundaries

| Concept | Aggregate? | HS.7 verdict |
|---------|------------|--------------|
| Hero | Yes (EXISTS) | Reuse |
| Story | Yes (EXISTS) | Reuse |
| StoryRepresentation | Entity on Story | Reuse |
| Collection | No | Defer |
| StoryExperience | No | Application DTO + UX |
| Playback | No | Ephemeral state |
| HeroJourney | No | Defer structured form |
| AdaptiveExperience | Application model (EXISTS) | Reuse |

---

## 26. HS.8 Boundary

HS.7 must explicitly **not** implement:

- semantic / vector search  
- personalized Hero/Story ranking  
- DiscoveryProfile-weighted scoring  
- AI recommendations  
- engagement optimization  
- collaborative filtering  

Conceptual split:

| Phase | Question |
|-------|----------|
| HS.6 | What exists and is discoverable? |
| HS.7 | Can I meaningfully experience it? |
| HS.8 | Which Hero/Story should this person experience next? |

Any Story candidate source used by UI.3 in HS.7 must remain **deterministic and non-personalized**.

---

## 27. Vertical Slices

### Slice 1 — Story Experience (prove the path)

```text
DiscoverStories → StoryDetail (GetStoryExperience) → Consume authoritative representation
```

**Includes:** DTOs, use cases, providers, StoryCatalog/Detail/Consume screens, discoverability tests, authoritative representation tests, analyzer + focused tests.  
**Excludes:** Hero profile, Today’s Experience story selection, reflection bridge, collections.

### Slice 2 — Hero Experience

```text
DiscoverHeroes → HeroProfile → Hero’s Stories → Slice 1 Story Experience
```

**Includes:** `GetHeroExperienceUseCase`, Hero screens, list-by-hero.  
**Excludes:** structured Hero Journey acts; collections.

### Slice 3 — UI.3 Adaptive Experience Integration

```text
Story candidate (deterministic) → AdaptiveExperience(type=story) → Home/Experience begin → StoryConsume
```

**Includes:** composer; selector extension **or** documented opt-in rule; begin-path branch for story vs reflection.  
**Requires approval** of selector behavior + begin branching.

### Slice 4 — Reflection Bridge

```text
After consume → optional Reflect → existing H.2 pipeline
```

**Includes:** CTA + navigation; proof that consume alone creates **no** Behavioral Evidence.  
**Excludes:** modifying Reflection aggregate unless approved.

### Slice 5 — Collections (optional / likely defer)

Only if §16 approval overturns deferral.

---

## 28. Testing Strategy

### Domain / policy

- Existing discoverability + authoritative representation tests remain green.  
- No new aggregates ⇒ limited new domain tests unless representation resolution helpers are domain-pure.

### Application

- GetStoryExperience: public/community allowed; private/unlisted/unpublished denied; unapproved reps excluded from playable list; narrative present only when allowed.  
- GetHeroExperience: parallel.  
- List hero stories: only discoverable stories.  
- Resolve playable representation: language/format priority deterministic.  
- Compose AdaptiveExperience: type=story; stable id.  
- Complete/consume: no domain events / no evidence.  
- Reflection bridge: evidence only after submit reflection.

### Presentation

- Loading/error/empty for catalog/detail/consume.  
- Story consume renders text; audio path uses retrieved bytes (fake player ok).  
- ExperienceScreen begin branches for story vs reflection (Slice 3).

### Cross-context

- Discoverable Story → Experience → optional Reflection → evidence pipeline.  
- Negative: playback complete ⇏ BehavioralEvidence.

### Non-goals

- Personalization A/B  
- Streaming QoS  
- Social graph tests  

---

## 29. Architecture Risks

| Risk | Guardrail |
|------|-----------|
| StoryExperience aggregate creep | DTO + use case only |
| Bypassing HS.6 discoverability | Re-check policies on every detail/consume |
| Unapproved representation leak | Authoritative-only playable projection |
| Private/unlisted leak | Fail closed; unlisted share-link requires approval |
| Coupling to HS.8 | Deterministic candidates only |
| Playback as evidence | HS-ADR-011; no evidence events from consume |
| Hero Journey = Life Journey | No HeroJourney aggregate; don’t store on Journey |
| Duplicate search | Reuse Discover\* only |
| Duplicate AdaptiveExperience | Reuse UI.3 model/port |
| Unnecessary persistence/events | In-memory; event-minimal |
| Social-media creep | Explicit non-goals |
| BeginExperience always reflects | Type-branched begin (approved) |
| Media vendor lock-in | Stay on StoryMediaStoragePort |
| Overloading DiscoverScreen | Separate Heroes/Stories surfaces |

---

## 30. Proposed ADRs

Next free number after **HS-ADR-047** is **HS-ADR-048**. Create during **implementation**, not this planning task.

### HS-ADR-048 — HS.7 Is Experience Over Discoverable Catalog, Not Personalization

- **Problem:** HS.7 could be mistaken for HS.8 ranking or social feed.  
- **Decision:** HS.7 delivers profiles, browsing UI, detail, consume/playback, and optional UI.3 story mapping over HS.6-eligible content only.  
- **Alternatives:** Personalized feed in HS.7; discovery-only with no UI.  
- **Consequences:** Clear non-goals; Discover\* reused.

### HS-ADR-049 — Experience Detail DTOs Are Discoverability-Gated Read Models

- **Problem:** HS.6 summaries omit narrative/media bodies needed to experience a Story.  
- **Decision:** Add `StoryExperienceDetail` / `HeroExperienceDetail` derived at query time; enforce policies; not new aggregates.  
- **Alternatives:** Expand discovery summaries; expose aggregates to UI.  
- **Consequences:** Safe narrative exposure; dual-store avoided.

### HS-ADR-050 — Playback Is Representation Consumption via Media Port, Not a Playback Aggregate

- **Problem:** Playback could spawn unnecessary aggregates/vendor ports.  
- **Decision:** Consume authoritative representations; text from entity; bytes via `StoryMediaStoragePort`; ephemeral UX state.  
- **Alternatives:** `PlaybackAggregate`; `StoryPlaybackPort` now.  
- **Consequences:** Simpler MVP; replaceable storage preserved.

### HS-ADR-051 — Story Interaction Remains Non-Evidence; Reflection Is Optional Bridge

- **Problem:** Teams may emit growth evidence from listen/complete.  
- **Decision:** Reinforce HS-ADR-011 for HS.7 consume APIs; reflection optional via existing pipeline.  
- **Alternatives:** Auto-evidence on complete.  
- **Consequences:** Evidence-first integrity.

### HS-ADR-052 — `ExperienceType.story` Integrates via UI.3 Selection Seam

- **Problem:** Hero Stories must not bypass Today’s Experience architecture.  
- **Decision:** Map Story → `AdaptiveExperience` through composer + `ExperienceSelectionService`; UI does not query StoryRepository for Home.  
- **Alternatives:** Home hardcodes StoryRepository; skip Today’s Experience.  
- **Consequences:** Seam preserved; begin-path must support story.

### HS-ADR-053 — Hero Journey Structure and Collections Deferred

- **Problem:** Foundation lists journeys/collections without current invariants.  
- **Decision:** HS.7 ships Hero’s Stories listing only; no HeroJourney/Collection aggregates; revisit with dedicated ADRs when needed.  
- **Alternatives:** Implement full journey taxonomy now.  
- **Consequences:** Avoids speculative domain.

*(If implementation scope excludes Slice 3, ADR-052 may be deferred to that slice’s kickoff.)*

---

## 31. Definition of Done

### Product

- [ ] User can discover a Hero (HS.6 API + HS.7 UI).  
- [ ] User can view a safe Hero experience detail.  
- [ ] User can discover a Story.  
- [ ] User can view Story experience detail (incl. narrative when eligible).  
- [ ] User can consume an approved/authoritative representation.  
- [ ] Story experience can map into UI.3 `AdaptiveExperience` (Slice 3).  
- [ ] Optional reflection reuses existing pipeline (Slice 4).  
- [ ] Language resolution is deterministic and authoritative-safe.  
- [ ] Discoverability rules enforced on all experience entry points.

### Architecture

- [ ] HS.6 discovery reused (no duplicate search).  
- [ ] UI.3 experience seam reused (not replaced).  
- [ ] No Personalization Engine / HS.8 ranking.  
- [ ] No AI/vendor streaming coupling.  
- [ ] Canonical Story remains authoritative.  
- [ ] Unapproved representations cannot leak.  
- [ ] Private/unlisted cannot leak on default paths.  
- [ ] Behavioral Evidence remains evidence-first.  
- [ ] Hero Journey ≠ Life Journey.  
- [ ] No unjustified aggregates/events/repos.

### Quality

- [ ] Focused HS.7 tests pass.  
- [ ] Full `flutter test` passes.  
- [ ] `dart analyze` clean on changed code.  
- [ ] Architecture boundary tests updated if needed.

---

## 32. Implementation Sequence

1. **Decision lock** — approve §39 table (especially unlisted, selector, begin-branch, journey naming, collections).  
2. **Slice 1** — Story experience application + UI + tests.  
3. **Slice 2** — Hero experience application + UI + tests.  
4. **Slice 3** — UI.3 story mapping + begin-path branch + tests.  
5. **Slice 4** — Optional reflection bridge + negative evidence tests.  
6. **ADRs + HS.7 Implementation Report** — analyzer, focused + full suite, report under `docs/architecture/`.  

No mega-PR; prefer vertical slices.

---

## 33. Explicit Non-Goals

- HS.8 personalization / semantic / ML ranking  
- Social graph (follow/like/comment/react/feed)  
- Monetization / marketplace / ads  
- Production backend, moderation platform, analytics platform  
- Notification infrastructure  
- Auth redesign  
- Production media streaming CDN  
- TTS / narration synthesis (deferred since HS.5)  
- Promote representation → narrative  
- Representation reject lifecycle  
- Structured Hero Journey acts taxonomy (unless separately approved)  
- Collections/saved stories (unless separately approved)  
- Rewriting unrelated Life Journey domain  
- Broad UI redesign unrelated to Hero Experience surfaces  

---

## 34. Open Decisions

| ID | Question | Recommendation |
|----|----------|----------------|
| O1 | Unlisted Story experience by known id? | **Not in Slice 1**; keep discoverability gate; approve later for share links |
| O2 | May `DeterministicExperienceSelectionService` return `ExperienceType.story` in HS.7? | **Optional Slice 3** with deterministic candidate source; else UI-only entry |
| O3 | How should `BeginExperienceUseCase` treat story? | **Branch**: story → consume; reflection → create reflection |
| O4 | Hero Stories order | `createdAt` asc for biography feel **or** `updatedAt` desc for recency — pick one and test |
| O5 | Reflection `sourceStoryId` on aggregate? | **No** in HS.7; prompt text / presentation context only |
| O6 | Collections in HS.7? | **Defer** |
| O7 | Persist playback progress? | **Defer** |
| O8 | New nav vs overload DiscoverScreen | **New Heroes/Stories surfaces**; don’t overload life Discover without approval |
| O9 | Audio/video required in Slice 1? | Slice 1 can ship **text/script consume first**; audio via media port in same slice if fixtures exist |
| O10 | Format priority order | Proposed in §23; confirm |

---

## 35. Human Approval Gate

| Decision | Recommendation | Requires Human Approval? |
|----------|----------------|--------------------------|
| Hero profile model | Application `HeroExperienceDetail` DTO; no new aggregate | **No** (consistent with HS-ADR-047 spirit) — confirm only if product wants richer profile claims |
| Story experience model | Application `StoryExperienceDetail` with narrative + authoritative playables | **Yes** (narrative exposure policy beyond HS.6 summaries) |
| Playback abstraction | No Playback aggregate; use representation + `StoryMediaStoragePort`; ephemeral UX | **Yes** |
| Hero Journey model | No aggregate; “Hero’s Stories” list only; structured acts deferred | **Yes** |
| Story → Adaptive Experience mapping | Composer + UI.3 seam; deterministic candidate optional in Slice 3 | **Yes** |
| Reflection integration | Optional CTA; no auto-evidence; don’t modify Reflection aggregate | **Yes** (esp. begin-path branching) |
| Collections | Defer | **Yes** (Foundation lists them; deferral is a scope call) |
| Persistence | In-memory only; no playback/collection persistence | **No** if deferrals accepted; **Yes** if product demands saves |
| Events | No new domain events for consume | **No** (aligns with event-minimalism) — confirm if analytics stakeholders disagree |
| Language selection | Deterministic preference cascade; authoritative only | **Yes** (priority table) |
| Unlisted known-id experience | Exclude from HS.7 Slice 1 | **Yes** |
| DiscoverScreen reuse | Do not overload life Discover; add Heroes/Stories UI | **Yes** |

**Existing decisions — no new approval required to *preserve*:**

- HS-ADR-011 (interaction ≠ evidence)  
- HS-ADR-041…047 (HS.6 discovery rules)  
- UI.3 `ExperienceSelectionService` seam  
- `ExperienceType.story` enum existence  

---

## 36. EXISTS vs PROPOSED Quick Index

| Item | Classification |
|------|----------------|
| `DiscoverStoriesUseCase` / `DiscoverHeroesUseCase` / `BrowseStoriesByCatalogUseCase` / `GetStoryDiscoverySummaryUseCase` | EXISTS |
| `StoryDiscoverySummary` / `HeroDiscoverySummary` | EXISTS |
| `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy` | EXISTS |
| `StoryMediaStoragePort` | EXISTS |
| `ExperienceType.story` / `AdaptiveExperience` / `ExperienceSelectionService` | EXISTS |
| `BeginExperienceUseCase` (reflection-only behavior) | EXISTS |
| `GetHeroExperienceUseCase` / `GetStoryExperienceUseCase` | PROPOSED |
| `StoryExperienceDetail` / `HeroExperienceDetail` | PROPOSED |
| `ResolvePlayableRepresentationUseCase` / `LoadStoryMediaUseCase` | PROPOSED |
| `ComposeStoryAdaptiveExperienceUseCase` | PROPOSED |
| hero_story presentation screens | PROPOSED |
| `HeroJourney` / `Collection` aggregates | PROPOSED **and rejected for MVP** |
| `StoryPlaybackPort` / Playback aggregate | PROPOSED **and rejected for MVP** |
| HS-ADR-048…053 | PROPOSED (write at implementation) |

---

## 37. Final Planning Verdict

| Item | Verdict |
|------|---------|
| HS.7 meaning | Meaningful experience over HS.6-discoverable Heroes/Stories |
| Smallest Slice 1 | Discover Story → Detail → Consume authoritative representation |
| UI.3 | Reuse seam; story begin-path needs approved branch |
| Personalization | Out → HS.8 |
| Collections / structured Hero Journey | Defer unless approval overturns |
| New aggregates | **None** recommended |
| Ready to implement? | **After §35 approvals** (especially narrative exposure, playback, journey, selector/begin, collections) |

**This document is planning-only. No HS.7 production implementation was performed in this planning phase.**

---

*End of HS.7 — Hero Experience Plan.*
