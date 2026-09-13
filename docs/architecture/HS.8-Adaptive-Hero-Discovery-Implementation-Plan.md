# HS.8 — Adaptive Hero Discovery Implementation Plan

**Phase:** HS.8 — Adaptive Hero Discovery  
**Document type:** Implementation-ready architectural plan (planning only)  
**Status:** DRAFT — Planning Complete  
**Date:** 2026-09-13  
**Predecessor:** HS.7 Hero Experience (COMPLETE on `origin/cursor/hs7-hero-experience-31d3`; **not yet merged to `main`**)  
**Anchors:** Hero & Story Platform Foundation §72; UI.3 Adaptive Experience Foundation; HS-ADR-041…053; AGENTS.md  

**Constraint honored:** This document plans HS.8 only. No production Dart, tests, migrations, UI, AI, networking, or recommendation engine implementation was performed for this task.

---

## 1. Executive Summary

HS.8 should deliver the **smallest coherent relevance layer** that connects current user understanding to discoverable Hero/Story content and surfaces it through the existing UI.3 Adaptive Experience seam—without becoming the production Personalization Engine, without bypassing HS.6 `Discover*`, and without duplicating HS.7 experience/consume paths.

### What is new in HS.8

| Phase | Question answered | Exists today? |
|-------|-------------------|---------------|
| **HS.6** | What Heroes/Stories are *findable*? | Yes — `Discover*` + discoverability policies |
| **HS.7** | Can a discoverable Hero/Story be *experienced*? | Yes on HS.7 branch — experience DTOs + consume |
| **UI.3** | Can understanding influence *today’s experience*? | Yes — but **reflection-only**, pattern presence only |
| **HS.8** | Which discoverable Hero/Story is *relevant to this person now*? | **No** — this is the gap |

HS.6 already discovers. UI.3 already selects. **HS.8 adds relevance** between understanding signals and the Hero & Story catalog, then feeds that relevance into the existing selection seam.

### Recommended minimum capability

```text
Current Journey understanding
  (BehaviorPatterns + Reflection NarrativeThemeIds
   + optional DiscoveryProfile theme IDs if present)
        ↓
AdaptiveDiscoverySignals (application read model)
        ↓
DiscoverStoriesUseCase / DiscoverHeroesUseCase  (HS.6 — locked eligibility)
        ↓
Deterministic relevance ranking + grounded rationale
        ↓
ExperienceSelectionService / GetTodayExperienceUseCase  (UI.3 seam)
        ↓
AdaptiveExperience(type: story | reflection | discovery, rationale?)
        ↓
HS.7 GetStoryExperience / GetHeroExperience / Consume
```

### Discovery Profile strategy (decision)

**Option B (recommended):** Introduce a minimal application-facing **AdaptiveDiscoverySignals** context sufficient for adaptive Hero/Story relevance.  
Do **not** implement full Discovery Profile synthesis (Option A).  
Do **not** pretend a production profile already exists (Option C is false today).  
Do leave a clear seam so a future synthesized Discovery Profile can feed the same signals object (Option D as evolution path).

### Personalization Engine strategy (decision)

HS.8 **extends the UI.3 `ExperienceSelectionService` / `GetTodayExperienceUseCase` composition**, not a new `PersonalizationEngine`.  
The future Personalization Engine may replace the selection implementation behind the same port.

---

## 2. Current Architecture

### 2.1 Bounded contexts (implemented)

```text
Identity (thin / incomplete)
 │
 ├──────────────┐
 │              │
 ▼              ▼
Discovery       Hero & Story
 (foundation)   (HS.1–HS.7)
 │              │
 │              │
 └──────┬───────┘
        ▼
   Life Journey
   (H.2 + UI.3)
        ▼
   Contribution (future)
```

### 2.2 Understanding → Experience loop today

```text
Reflection (Life Journey)
  → AnalyzeReflectionUseCase
  → BehavioralEvidenceDetected
  → DetectPatternUseCase / PatternDetector
  → Journey.updateBehaviorPatterns()
  → BehaviorPatternsDetected
        ↓
GetTodayExperienceUseCase
  → CurrentJourneyContext
  → JourneyRepository.findById
  → ExperienceSelectionService.selectFor(Journey)
        ↓
AdaptiveExperience (mostly ExperienceType.reflection)
        ↓
HomeScreen → ExperienceScreen → BeginExperienceUseCase
  → CreateReflectionUseCase  (always Reflection today)
```

### 2.3 Hero & Story seeker loop today (HS.6 on `main`; HS.7 on branch)

```text
DiscoverHeroesUseCase / DiscoverStoriesUseCase
  → StoryDiscoverabilityPolicy / HeroDiscoverabilityPolicy
  → summaries (no narrative body in HS.6)
        ↓
[HS.7] GetHeroExperienceUseCase / GetStoryExperienceUseCase
  → narrative + authoritative playables
  → BeginStoryExperienceUseCase / ConsumeStoryExperienceUseCase
  → optional StartStoryReflectionUseCase → CreateReflectionUseCase
```

### 2.4 Key concrete types

| Concern | Path / type |
|---------|-------------|
| Selection port | `lib/features/life_journey/application/services/experience_selection_service.dart` |
| Deterministic selector | `…/deterministic_experience_selection_service.dart` |
| Today’s experience UC | `…/use_cases/get_today_experience_use_case.dart` |
| Adaptive experience DTO | `…/models/adaptive_experience.dart` (`ExperienceType` includes `story`, `discovery`) |
| Begin experience | `…/use_cases/begin_experience_use_case.dart` (**always creates Reflection**) |
| Current journey | `…/context/current_journey_context.dart` |
| Discover Stories | `lib/features/hero_story/application/use_cases/discover_stories_use_case.dart` |
| Discover Heroes | `…/discover_heroes_use_case.dart` |
| Discoverability | `StoryDiscoverabilityPolicy`, `HeroDiscoverabilityPolicy` |
| Discovery Profile aggregate | `lib/features/discovery/domain/aggregates/discovery_profile.dart` (stub/foundation) |
| Reflection themes | `Reflection.narrativeThemes` + `ReflectionRepository.findByJourneyId` **EXISTS** |

---

## 3. Completed HS.1–HS.7 Assessment

| Phase | Status on `main` | Status elsewhere | HS.8 implication |
|-------|------------------|------------------|------------------|
| H.2 Behavioral Understanding | Complete | — | Consume Journey patterns; do not reinvent evidence |
| UI.3 Adaptive Experience | Complete | — | **Must reuse** selection seam |
| HS.1 Foundation | Complete | — | Preserve ownership boundaries |
| HS.2 Catalog | Complete | — | Themes/subjects/challenges available as catalog dims |
| HS.3 Capture | Complete | — | Out of HS.8 scope |
| HS.4 Understanding | Complete | — | Catalog candidates ≠ personalization |
| HS.5 Authoring | Complete | — | Authoritative-rep rules already enforced by Discover* |
| HS.6 Discovery | Complete (`#15`) | Report + HS-ADR-041…047 | **Mandatory Discover* boundary** |
| HS.7 Hero Experience | **Docs on `main` only** (plan + lock via `#17`) | **Implementation COMPLETE** on `origin/cursor/hs7-hero-experience-31d3` (HS-ADR-048…053) | **Merge prerequisite** for consume/presentation integration |

### HS.7 dependency (blocker for implementation, not for planning)

HS.8 planning assumes HS.7 capabilities. Implementation must not begin against `main` until HS.7 is merged (or HS.8 is branched from the HS.7 branch). Required HS.7 reuse:

- `GetStoryExperienceUseCase`, `GetHeroExperienceUseCase`
- `ListHeroStoriesUseCase` → `DiscoverStories`
- `BeginStoryExperienceUseCase` / `ConsumeStoryExperienceUseCase`
- `PlayableRepresentationSelector` / `ResolvePlayableRepresentationUseCase`
- Hero Experience UI screens (routing targets)
- HS-ADR-051: consumption ≠ evidence
- HS-ADR-052: UI.3 story integration was **deferred in HS.7** — HS.8 **intentionally reopens** that seam

---

## 4. UI.3 Integration Analysis

### 4.1 What UI.3 established

- Application-facing selection boundary: `ExperienceSelectionService`
- Orchestration: `GetTodayExperienceUseCase`
- Presentation model: `TodayExperienceViewModel` + Home/Experience screens
- Replaceable deterministic strategy: `DeterministicExperienceSelectionService`
- Optional grounded `rationale` string
- `ExperienceType.story` / `discovery` reserved in enum but **never selected**

### 4.2 What UI.3 deferred (still deferred entering HS.8)

From `docs/ui/Everyone's-Heroes-UI.3-Adaptive-Experience-Foundation.md`:

- Production Personalization Engine
- Growth Opportunity Detection
- Full Discovery Profile synthesis
- AI experiences / coaching
- ML ranking / recommendation optimization
- Story/Hero as selected experience types (taxonomy only)

### 4.3 Current selection inputs vs available understanding

| Signal | Available? | Used by UI.3 selector? |
|--------|------------|------------------------|
| `Journey.behaviorPatterns` | Yes | Yes — only `consistency` presence |
| Pattern strength / evidence | Yes on pattern | No |
| Reflection `narrativeThemes` | Yes via `findByJourneyId` | No |
| Discovery Profile themes/influences | Aggregate exists; **not wired** | No |
| Hero/Story catalog | Yes (HS.6/HS.7) | No |
| Growth Opportunities | No | No |

### 4.4 Integration rule for HS.8

```text
Understanding
  ↓
Application-facing selection boundary (UI.3)
  ↓
AdaptiveExperience
  ↓
Presentation
```

**Forbidden:**

```text
UI → Hero Recommendation Algorithm
UI → HeroRepository / StoryRepository
Presentation → DiscoveryProfile → recommendation logic
Parallel “AdaptiveHeroEngine” beside ExperienceSelectionService
```

### 4.5 Signature / composition gap

Today:

```dart
abstract interface class ExperienceSelectionService {
  AdaptiveExperience selectFor(Journey journey); // sync
}
```

HS.8 relevance requires **async** Discover* calls and signals beyond `Journey`. Therefore HS.8 must extend composition carefully:

**Recommended approach (preserve UI.3 seam):**

1. Keep `GetTodayExperienceUseCase` as the single presentation entry.
2. Introduce an application composition step (name proposed: `AdaptiveExperienceComposer` **or** evolve `ExperienceSelectionService` to async with an injected candidate port).
3. Do **not** invent a second Home-facing use case for “personalized story of the day.”

**Preferred concrete shape:**

```text
GetTodayExperienceUseCase
  → load Journey (CurrentJourneyContext)
  → ResolveAdaptiveDiscoverySignalsUseCase
  → ExperienceSelectionService.select(...)  // evolved: may accept signals + optional candidates
        or
  → AdaptiveExperienceComposer.compose(journey, signals)
       internally calls ExperienceSelectionService + DiscoverableStoryCandidatePort
```

Either way, presentation continues to call only `GetTodayExperienceUseCase`.

### 4.6 Begin-path gap (must address in HS.8)

`DefaultBeginExperienceUseCase` **always** creates a Reflection.  
HS.7 correctly introduced a **separate** `BeginStoryExperienceUseCase` (HS-ADR-051).

For `ExperienceType.story`, presentation must **not** call `BeginExperienceUseCase`. It must route into HS.7 Story Experience (detail → begin/consume). Reflection remains the optional explicit bridge via `StartStoryReflectionUseCase`.

---

## 5. HS.6 Integration Analysis

### 5.1 Locked discoverability (must remain true under personalization)

```text
Discoverable Story =
  published
  + visibility ∈ {public, community}
  + !hasProvisionalNarrative
  + Hero also discoverable

Discoverable Hero =
  active
  + visibility ∈ {public, community}
```

Also: Discover* defaults `authoritativeRepresentationsOnly: true`.

**Personalization must never bypass these rules**—including known IDs, adaptive experiences, direct navigation, and fallbacks.

### 5.2 Discover* vs Search*

| Path | Role | HS.8 |
|------|------|------|
| `DiscoverStoriesUseCase` / `DiscoverHeroesUseCase` | Seeker findability | **Required** |
| `BrowseStoriesByCatalogUseCase` | Dimension browse façade | Optional helper |
| `GetStoryDiscoverySummaryUseCase` | Known-id summary fail-closed | Optional |
| `SearchStoriesUseCase` / `SearchHeroesUseCase` | Low-level/admin pass-through | **Forbidden** for seeker adaptive paths |

### 5.3 What HS.6 explicitly deferred to HS.8

- Personalized ranking / “what next”
- DiscoveryProfile relevance / serendipity
- Personalized “Why this story?”

HS.6 ordering remains deterministic non-personalized (`updatedAt`/`createdAt` + id). HS.8 may **re-rank Discover* result sets in application code** after eligibility, without changing Discover* defaults or Search* misuse.

### 5.4 Theme filter already exists

`DiscoverStoriesRequest.narrativeThemeIds` is the natural HS.8 relevance lever.  
HS.6 D5 / HS-ADR-041: Discover* **must not load DiscoveryProfile**; callers may pass theme IDs.

---

## 6. HS.7 Integration Analysis

### 6.1 Reuse, do not duplicate

| Capability | Reuse |
|------------|-------|
| Hero catalog / profile | `DiscoverHeroes` → `GetHeroExperienceUseCase` |
| Story detail / narrative | `GetStoryExperienceUseCase` |
| Playables / language / format | `PlayableRepresentationSelector` |
| Consume / media | `BeginStoryExperienceUseCase`, `LoadStoryMediaUseCase`, `ConsumeStoryExperienceUseCase` |
| Optional reflect | `StartStoryReflectionUseCase` |
| Discoverability on known-id | Re-check policies (HS-ADR-049) |

### 6.2 HS.7 decisions HS.8 must honor

- **HS-ADR-048:** Experience ≠ personalization (HS.8 owns personalization-lite relevance)
- **HS-ADR-051:** Interaction non-evidence
- **HS-ADR-052:** UI.3 story integration deferred in HS.7 → **HS.8 is the authorized phase to wire it**
- **HS-ADR-053:** No HeroJourney / collections in this phase either

### 6.3 HS.7 vs Foundation wording drift

Foundation §72 listed “Hero journeys / collections” under HS.7. Implementation correctly deferred them (HS-ADR-053). **Do not reopen** in HS.8.

HS-ADR-043 historically suggested unlisted might be reachable by known id later; HS.7 locked **fail-closed for unlisted** (D4 / HS-ADR-049). **HS.8 must keep fail-closed.** Prefer updating ADR-043 clarifying note during HS.8 docs pass (documentation drift, not code blocker).

---

## 7. Problem Statement

The platform can:

1. Understand a person (H.2 patterns; reflection themes).
2. Find eligible Heroes/Stories (HS.6).
3. Let a person experience those Stories (HS.7).
4. Select a next experience from understanding (UI.3).

It cannot yet:

> **Use current understanding to choose a relevant discoverable Hero/Story and present it as an adaptive experience—with an honest explanation—without building a full Personalization Engine.**

That is the HS.8 problem.

---

## 8. HS.8 Scope

### 8.1 In scope (minimum valuable HS.8)

1. **AdaptiveDiscoverySignals** — application read model resolving available understanding inputs.
2. **Deterministic Hero/Story relevance** over HS.6 Discover* results (theme overlap primary).
3. **UI.3 seam integration** — `ExperienceType.story` (and optionally `discovery`) selectable when a relevant candidate exists.
4. **Grounded rationale** — evidence-linked explanation strings (extend optional `rationale`).
5. **Presentation routing** — Today’s Experience → HS.7 Story Experience when type is story.
6. **Discoverability regression guarantees** — private/unlisted never surface.
7. **Tests + ADRs** for the above.
8. **Light deterministic serendipity** (optional late slice) — testable adjacency rule, not ML.

### 8.2 Explicit non-goals

- Full Discovery Profile synthesis (Growth Opportunities + patterns + influences + style into one holistic profile)
- Production `PersonalizationEngine` product
- AI / embeddings / vector / semantic search
- ML ranking / engagement optimization / A/B ranking
- Social feeds, follows, likes, comments
- Collections / bookmarks (still deferred)
- Inferring Behavioral Evidence from views/clicks/search/playback
- New bounded context
- Moving NarrativeTheme ownership into Hero & Story
- Bypassing Discover* via Search* or raw repositories in seeker paths
- Device-locale inference (unless already established elsewhere; prefer explicit preferred language later)
- Replacing HS.6 catalog Discover UI wholesale (Life Journey `DiscoverScreen` remains non-catalog)
- Production search engines / persistent discovery projections

### 8.3 What is adapting (and what is not)

| Candidate adaptation | In minimum HS.8? | Notes |
|----------------------|------------------|-------|
| Which Stories are surfaced as Today’s Experience | **Yes** | Primary |
| Ordering among Discover* candidates | **Yes** | Application re-rank after Discover* |
| Thematic relevance (NarrativeThemeId overlap) | **Yes** | Primary signal |
| Current Journey pattern gating (when to offer story vs reflection) | **Yes** | Reuse UI.3 pattern presence idea |
| Discovery-profile themes (if profile present) | **Optional enhancement** | Not required for MVP if reflection themes work |
| Explanation / rationale | **Yes** | Required for honesty |
| Exploration vs familiarity / serendipity | **Optional late slice** | Deterministic only |
| Which Heroes are surfaced in Heroes tab | **Optional slice** | Secondary; same signals |
| Format/language selection | **No (reuse HS.7)** | After selection |
| Full coaching/mission personalization | **No** | Future engine |

---

## 9. Architectural Boundaries

### 9.1 Ownership

| Owns | Does not own |
|------|--------------|
| **Hero & Story** — discoverable content, catalog metadata, experience DTOs, consume | Personalization decisions, DiscoveryProfile, evidence/patterns |
| **Discovery** — NarrativeTheme, Influence, DiscoveryProfile aggregate | Story catalog, Journey patterns |
| **Life Journey** — Journey, Reflection, BehaviorPatterns, UI.3 selection seam | Hero/Story aggregates |
| **HS.8 relevance (application)** — signals resolution + ranking composition | Domain ownership of themes or stories |

### 9.2 Where HS.8 sits

```text
Catalog (HS.2)        What is this story?
Discovery findability (HS.6)   What can I find?
Adaptive relevance (HS.8)      What is relevant to me *among findable content*?
Adaptive experience selection (UI.3 + HS.8)  What should I experience next?
Future Personalization Engine  Generalized multi-experience personalization
```

**HS.8 is personalization-lite relevance for Hero/Story**, delivered through the UI.3 experience-selection seam, operating strictly over HS.6 discoverability.

### 9.3 Hard constraints (must preserve)

1. No UI business rules  
2. No direct repository access from presentation  
3. No aggregate manipulation from presentation  
4. No detector invocation from presentation  
5. No raw Search* for seeker discovery  
6. Discover* for seeker Hero/Story discovery  
7. No private/unlisted leakage  
8. Narrative Themes owned by Discovery  
9. Behavioral Evidence remains observational  
10. Story consumption ≠ Behavioral Evidence  
11. AI is not a domain dependency  
12. Deterministic implementation remains replaceable  
13. Do not build the complete Personalization Engine  
14. Do not create a second adaptive-experience architecture beside UI.3  
15. Do not hard-code Journey identity in presentation  

---

## 10. Proposed Architecture

### 10.1 Target flow

```text
Home / Today’s Experience
        ↓
GetTodayExperienceUseCase
        ↓
ResolveAdaptiveDiscoverySignalsUseCase
   ├─ Journey.behaviorPatterns
   ├─ ReflectionRepository.findByJourneyId → union NarrativeThemeIds
   └─ optional DiscoveryProfilePort.findThemesForUser (if wired)
        ↓
DiscoverableStoryCandidatePort.findRelevant(signals)
   └─ DiscoverStoriesUseCase(narrativeThemeIds: …, limit: N)
   └─ DeterministicStoryRelevanceRanker
   └─ (optional) SerendipityRule
        ↓
AdaptiveExperienceComposer / ExperienceSelectionService
   ├─ if relevant story candidate → ExperienceType.story + rationale
   └─ else existing reflection rules (UI.3 behavior)
        ↓
TodayExperienceViewModel
        ↓
ExperienceType.story? → HS.7 StoryDetail / Consume
ExperienceType.reflection? → existing BeginExperience → Reflect
```

### 10.2 Cross-context dependency direction

```text
life_journey/application
   depends on ports (interfaces) for story candidates / discovery signals
        ↑
hero_story/application implements DiscoverableStoryCandidatePort
   using DiscoverStoriesUseCase (not Search*, not repos in presentation)

discovery/application (optional later)
   implements ThemeSignalSource from DiscoveryProfile
```

Life Journey **must not** import Hero/Story aggregates.  
Hero & Story **must not** own selection policy for Today’s Experience.

### 10.3 Proposed application components

| Component | Layer | Responsibility |
|-----------|-------|----------------|
| `AdaptiveDiscoverySignals` | Life Journey application model | Immutable signals bag (theme IDs, pattern types, optional language) |
| `ResolveAdaptiveDiscoverySignalsUseCase` | Life Journey application | Builds signals from Journey + Reflections (+ optional profile port) |
| `DiscoverableStoryCandidate` | Shared application DTO (or life_journey port DTO) | `storyId`, `heroId`, `title`, `matchedThemeIds`, `relevanceScore`, `rationaleFactors` |
| `DiscoverableStoryCandidatePort` | Life Journey application port | `Future<List<DiscoverableStoryCandidate>> findRelevant(AdaptiveDiscoverySignals)` |
| `DiscoverStoriesCandidateAdapter` | Hero & Story application | Implements port via `DiscoverStoriesUseCase` + ranker |
| `DeterministicStoryRelevanceRanker` | Hero & Story application service | Pure ranking/explainability over Discover* summaries |
| `AdaptiveExperienceComposer` | Life Journey application | Combines signals + candidates + reflection fallback into `AdaptiveExperience` |
| Evolved `ExperienceSelectionService` | Life Journey application | Remains the replaceable selection abstraction; may delegate to composer |

### 10.4 AdaptiveExperience extension

Today `AdaptiveExperience` lacks a typed target reference. HS.8 should add an optional, presentation-safe reference:

```text
AdaptiveExperience
  + ExperienceTarget? target
       storyId? / heroId? / experienceKey
```

Do **not** embed full `Story` aggregates.  
Do **not** put narrative body on `AdaptiveExperience` (HS.7 detail remains authoritative for narrative).

`ExperienceAction` may remain `begin`; presentation interprets begin by `ExperienceType`.

---

## 11. Domain Model Impact

### 11.1 Prefer no new aggregates

HS.8 **should not** introduce:

- `PersonalizationContext` mega-object
- `Recommendation` aggregate
- `HeroDiscovery` aggregate
- `AdaptiveSelection` aggregate
- Consumption/evidence aggregates

### 11.2 Possibly justified new types (application / value-level)

| Name | Kind | Context | Why existing is insufficient |
|------|------|---------|------------------------------|
| `AdaptiveDiscoverySignals` | Application model / VO-like | Life Journey (or thin shared application) | Need a stable input contract beyond raw `Journey` |
| `ExperienceTarget` | Application VO | Life Journey | `AdaptiveExperience.id` string alone is too weak for routing |
| `SelectionRationale` (optional) | Application VO | Life Journey | If structured factors are needed beyond `String? rationale`; otherwise keep string for MVP |
| `StoryRelevanceScore` | Application value | Hero & Story application | Ranking needs an explicit deterministic score |
| `ThemeOverlapRule` / ranker | Application service | Hero & Story application | Pure function over Discover* results |

### 11.3 Domain objects to reuse unchanged

- `NarrativeThemeId` (Discovery-owned concept, ID in Shared Kernel)
- `StoryClassification.narrativeThemeIds`
- `BehaviorPattern` / `BehaviorPatternType`
- `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy`
- `DiscoveryMatchReason` (filter dimension codes; not personalized scoring)

### 11.4 DiscoveryProfile

Treat as **optional signal source**, not HS.8 deliverable product.

If demo wiring is needed:

- Add `DiscoveryProfileRepository.findByUserId` (small repository contract extension)
- Seed profile themes in demo runner
- Still do **not** synthesize Growth Opportunities / pattern ingestion into the profile

---

## 12. Application Model

### 12.1 Use cases

| Use case | Action |
|----------|--------|
| `ResolveAdaptiveDiscoverySignalsUseCase` | **New** |
| `GetTodayExperienceUseCase` | **Extend** orchestration to use composer/signals |
| `DiscoverStoriesUseCase` / `DiscoverHeroesUseCase` | **Reuse** only |
| `GetStoryExperienceUseCase` / `GetHeroExperienceUseCase` | **Reuse** (post-selection) |
| `BeginExperienceUseCase` | **Unchanged** (reflection path only) |
| `BeginStoryExperienceUseCase` | **Reuse** (story path) |

### 12.2 Selection strategy service

Replace or wrap `DeterministicExperienceSelectionService`:

Proposed rules (deterministic, testable):

1. Resolve signals.  
2. If theme signals non-empty → request Discover* candidates filtered by those themes.  
3. Rank by theme-overlap count, then HS.6 tie-break (`updatedAt`/`storyId`).  
4. If top candidate exists → return `ExperienceType.story` with rationale grounded in matched themes (and optionally pattern).  
5. Else if consistency pattern exists → existing `consistency-next-step` reflection.  
6. Else → `default-reflection`.

Pattern types beyond consistency may later gate *whether* to offer story vs reflection, but MVP should not invent unsupported coaching claims.

### 12.3 Providers

Likely files:

- `lib/features/life_journey/application/providers/services/experience_selection_service_provider.dart` — swap implementation
- New providers for signals use case + composer
- `lib/features/hero_story/application/providers/...` — candidate port adapter wiring to Discover*

Riverpod remains composition only.

---

## 13. Infrastructure Model

| Change | Needed in HS.8 MVP? |
|--------|---------------------|
| New DB / migrations | **No** |
| Production search | **No** |
| AI ranking | **No** |
| In-memory Discover* adapters | Reuse |
| Demo seed data (stories with themes matching reflection themes) | **Yes** (demo/test fixtures) |
| `DiscoveryProfileRepository.findByUserId` + in-memory | Optional |
| Event store changes | **No** for selection |

---

## 14. Presentation Model

### 14.1 Smallest UI vertical slice

**Primary:** Enhance Today’s Experience (Home) to support `ExperienceType.story`:

```text
HomeScreen
  → shows AdaptiveExperience (title/description/rationale)
  → Begin
       ├─ reflection → ExperienceScreen → BeginExperienceUseCase → ReflectScreen
       └─ story → StoryDetailScreen / StoryConsumeScreen (HS.7)
```

### 14.2 What not to do in MVP UI

- Do not replace Life Journey `DiscoverScreen` (still life-meaning prompts).
- Do not replace Heroes catalog with a opaque recommendation feed.
- Do not show private “For You” algorithms language.
- Do not invent rationale in widgets.

### 14.3 Optional secondary UI

- Heroes tab: “Relevant to your journey” section powered by same signals + `DiscoverHeroes` / story-derived hero IDs — only after Today’s Experience story path works.

### 14.4 UI.3 deferred Story decision

HS.7 deferred UI.3 story selection (HS-ADR-052).  
HS.8 **explicitly changes that product timing**: Story becomes an adaptive experience candidate **now**, still behind the same UI.3 seam—not a redesign of UI.3 architecture.

---

## 15. Discovery Profile Strategy

### Options evaluated

| Option | Meaning | Verdict |
|--------|---------|---------|
| **A** Full Discovery Profile synthesis | Growth ops + patterns + influences + preferences | **Reject for HS.8** — premature Personalization/Discovery epic |
| **B** Minimal application discovery context | `AdaptiveDiscoverySignals` | **Accept** |
| **C** Consume existing usable profile | Profile aggregate exists but unwired / unsynthesized | **False today** |
| **D** Seam only | Port with empty/fake signals | Insufficient alone; combine with B |

### Recommended

**B + evolutionary seam toward A/C:**

1. Ship `AdaptiveDiscoverySignals`.  
2. Source #1 (required): union of `Reflection.narrativeThemes` for current journey.  
3. Source #2 (required): `Journey.behaviorPatterns` types.  
4. Source #3 (optional): `DiscoveryProfile.narrativeThemeIds` when a profile can be loaded.  
5. Keep Discover* free of profile loading (HS.6 D5 remains).

This proves relevance without pretending the holistic Discovery Profile exists.

---

## 16. Personalization Boundary

| Layer | Responsibility | HS.8 |
|-------|----------------|------|
| H.2 | Evidence → Patterns | Consume only |
| Growth Opportunities | Future interpretation | Out |
| Discovery Profile synthesis | Holistic person model | Out (optional thin read) |
| **HS.8 Adaptive Hero Discovery** | Relevant discoverable Hero/Story selection + rationale into AdaptiveExperience | **In** |
| UI.3 seam | Experience selection abstraction | Extend |
| Future Personalization Engine | Multi-type experiences (mission/coaching/music/story), richer policies | Later; replace selector impl |

**HS.8 responsibility:** Hero/Story relevance for adaptive experience.  
**Future engine responsibility:** General “what experience should inspire this person next?” across all experience types and richer inputs.

---

## 17. Selection Strategy

### 17.1 Signal matrix

| Signal | Exists? | Owner | Safe to use? | Why |
|--------|---------|-------|--------------|-----|
| Journey behavior patterns | Yes | Life Journey | **Yes** | Established UI.3 input |
| Reflection NarrativeThemeIds | Yes | Life Journey / Discovery IDs | **Yes** | Strongest available thematic signal; query via `findByJourneyId` |
| DiscoveryProfile.narrativeThemeIds | Aggregate yes; DI no | Discovery | **Conditional** | Safe if loaded via port; do not block MVP |
| Influence IDs | Aggregate yes | Discovery | Later | Needs influence→theme resolution wiring in app DI |
| Story catalog theme IDs | Yes | Hero & Story classification | **Yes** | Match target |
| Language preference | Not really wired | — | Defer / optional | Prefer HS.7 representation selection after pick |
| Format preference | No user preference store | — | Defer | HS.7 format cascade |
| Suitability max prefs | Request fields exist; no user store | — | Defer | Can pass defaults only |
| Click/view/search history | No first-class model | — | **No as evidence** | Do not invent; not behavioral evidence |
| Playback completion | Ephemeral HS.7 session | Hero & Story app | **No as evidence** | HS-ADR-051 |
| Growth Opportunities | No | — | No | Not implemented |
| Random engagement scores | No | — | No | Non-goal |

### 17.2 Deterministic ranking (proposed)

For candidates returned by Discover* with requested theme filters:

1. `overlapCount = |story.themes ∩ signal.themes|`  
2. Sort by `overlapCount` desc  
3. Tie-break: existing HS.6 story ordering (`updatedAt` desc, `storyId` asc)  
4. Stable for tests given same fixtures  

No randomness in MVP ranking (serendipity is a separate explicit rule if added).

### 17.3 Replaceability

Ranker + composer implementations must be swappable behind ports so a future Personalization Engine / AI-assisted ranker can replace them without Home redesign.

---

## 18. Explainability

### 18.1 Requirement

HS.8 must answer: **Why was this Hero or Story shown to me?**

### 18.2 Representation

MVP: continue UI.3 `String? rationale` on `AdaptiveExperience` / view model.

Examples of **allowed** rationale:

- “This story shares the theme Perseverance with your recent reflections.”
- “Selected because it matches themes from your journey reflections: Courage, Service.”

Examples of **forbidden** rationale:

- “You need more discipline.”
- “This will fix your avoidance.”
- “Because you watched similar stories” (if no such evidence store exists)

### 18.3 Optional structured rationale (later slice)

```text
SelectionRationale
  factors: [ThemeOverlap(themeIds), PatternContext(type?), Serendipity(flag)]
  summary: String
```

Only add if presentation needs structured UI; otherwise string is enough and matches UI.3.

---

## 19. Serendipity

### 19.1 Intent

Foundation values meaningful serendipity:

```text
Known interest → Related Narrative Theme → Unexpected Hero
```

### 19.2 Reality check

`NarrativeTheme` currently has **no relation graph**. Do not invent opaque similarity.

### 19.3 Recommendation

- **MVP:** exact theme overlap only.  
- **Optional late slice:** deterministic exploration rule, e.g.  
  - If exact-overlap candidates ≥ 1, with probability 0 based on `hash(journeyId + day) % K == 0`, pick a discoverable story that shares a **Challenge** or **Subject** with the top match but **zero** theme overlap.  
  - Rationale must say exploration honestly (“Exploring a related challenge outside your usual themes.”).  
- No ML, no embeddings, no engagement maximization.

---

## 20. Privacy / Discoverability

### 20.1 Required mental test matrix

| Content | Adaptive discovery may surface? |
|---------|----------------------------------|
| Public Hero | Yes |
| Community Hero | Yes |
| Private Hero | **Never** |
| Unlisted Hero | **Never** |
| Public Story | Yes |
| Community Story | Yes |
| Private Story | **Never** |
| Unlisted Story | **Never** |

### 20.2 Enforcement points

1. Candidate port uses only Discover*.  
2. Before emitting `AdaptiveExperience(type: story)`, re-validate via `GetStoryExperienceUseCase` **or** re-check policies (fail closed).  
3. Presentation never receives non-discoverable IDs from adaptive APIs.  
4. Tests must attempt private/unlisted known IDs and expect exclusion.

Personalization is **not** a privilege escalation path.

---

## 21. Language / Representation

```text
Adaptive Discovery (pick StoryId)
        ↓
Discover* eligibility (authoritative reps already considered for filters)
        ↓
HS.7 GetStoryExperience / PlayableRepresentationSelector
        ↓
Language + format selection
```

**Do not** duplicate representation selection inside HS.8.  
If signals later include preferred language, pass through to Discover* `availableLanguage` / GetStoryExperience `preferredLanguage`—do not reimplement cascades.

---

## 22. Vertical Slices

### Slice 0 — Prerequisite

**Purpose:** Ensure HS.7 is available on the integration branch.  
**Work:** Merge or branch-from `cursor/hs7-hero-experience-31d3`.  
**Acceptance:** HS.7 experience use cases and Heroes UI present; HS-ADR-048…053 on branch.  
**Risk:** Planning against docs-only `main` would invent duplicate experience APIs.

---

### Slice 1 — AdaptiveDiscoverySignals

**Purpose:** Resolve understanding inputs without ranking content.  

| Area | Change |
|------|--------|
| Architecture | Signals read model + resolver use case |
| Files | New under `life_journey/application/models|use_cases|providers` |
| Domain | None |
| Application | `ResolveAdaptiveDiscoverySignalsUseCase` |
| Infrastructure | None (optional profile `findByUserId` later) |
| Presentation | None |
| Tests | Unit: themes union from reflections; patterns copied; empty journey → empty themes |
| Acceptance | Given reflections with themes T1/T2, signals contain {T1,T2} + pattern types |
| Dependencies | ReflectionRepository.findByJourneyId (exists) |
| Risks | Theme ID inconsistency across demo data |

---

### Slice 2 — Discover*-backed relevance (no UI.3 wiring yet)

**Purpose:** Prove deterministic relevance over eligible catalog.  

| Area | Change |
|------|--------|
| Architecture | Candidate port + Discover* adapter + ranker |
| Files | `hero_story/application/relevance/…`, port in life_journey or shared application contracts |
| Domain | None (reuse policies) |
| Application | Ranker + adapter |
| Infrastructure | Demo/test fixtures with classified themes |
| Presentation | None |
| Tests | Application: overlap ranking; private/unlisted excluded; Search* not used |
| Acceptance | Signals with T1 return discoverable stories tagged T1, ordered by overlap |
| Dependencies | Slice 1, HS.6 Discover* |
| Risks | Empty catalog → empty candidates (must be handled) |

---

### Slice 3 — UI.3 AdaptiveExperience composition

**Purpose:** Select `ExperienceType.story` when candidate exists; else reflection fallback.  

| Area | Change |
|------|--------|
| Architecture | Composer / evolved selection service; extend `AdaptiveExperience` with target |
| Files | `experience_selection_service.dart`, `deterministic_…`, `get_today_experience_use_case.dart`, `adaptive_experience.dart`, providers |
| Domain | None |
| Application | Composition rules + rationale strings |
| Presentation | View model mapping for target/rationale (minimal) |
| Tests | Selector/composer unit tests; GetTodayExperience integration |
| Acceptance | With themes+matching story → story experience + rationale; without → existing reflection behavior |
| Dependencies | Slices 1–2 |
| Risks | Sync→async selection signature migration; keep provider tests green |

---

### Slice 4 — Presentation begin routing + HS.7 consume

**Purpose:** User can open the adaptive Story and consume it.  

| Area | Change |
|------|--------|
| Architecture | Presentation branching only; reuse HS.7 |
| Files | `home_screen.dart`, `experience_screen.dart`, possibly navigation helpers; **do not** change `BeginExperienceUseCase` into a story begin |
| Domain | None |
| Application | None beyond Slice 3 |
| Presentation | Route story → HS.7 detail/consume |
| Tests | Widget/UI tests for story vs reflection paths; loading/empty/error |
| Acceptance | Begin on story experience opens discoverable story detail; reflection path unchanged |
| Dependencies | Slice 3 + HS.7 UI |
| Risks | Breaking ExperienceScreen reflection tests |

---

### Slice 5 — Understanding refresh proof

**Purpose:** Updated understanding changes adaptive Hero/Story discovery.  

| Area | Change |
|------|--------|
| Architecture | Integration test pipeline only (fixtures) |
| Files | `test/integration/hs8_adaptive_hero_discovery_pipeline_test.dart` (proposed) |
| Tests | Reflect → themes/patterns update → Today’s Experience story candidate changes |
| Acceptance | Analogous to UI.3 Slice 4 proof, but for story relevance |
| Dependencies | Slices 1–4, H.2 pipeline |
| Risks | Theme resolution still uses `FakeNarrativeThemeResolver` in production providers (drift) — tests must seed explicit theme IDs on reflections |

---

### Slice 6 (optional) — Deterministic serendipity

**Purpose:** Occasional related-but-unexpected story with honest rationale.  
**Only after** Slices 1–5 are green.  
**Acceptance:** Rule is pure/deterministic; never surfaces non-discoverable content.

---

### Slice 7 (optional) — Heroes tab relevance section

**Purpose:** Surface relevant Heroes using same signals (via DiscoverHeroes or heroes of relevant stories).  
**Do not** replace catalog browse semantics entirely.

---

## 23. Testing Strategy

Aligned with `docs/architecture/testing-strategy.md` and AGENTS.md §27.

### Domain

- Minimal: discoverability unchanged (existing policy tests remain source of truth).  
- No new aggregates expected → few/no new domain tests unless a pure VO is introduced.

### Application

- Signals resolution  
- Ranker determinism / tie-breaks  
- Composer selection matrix (story vs reflection)  
- Discover* usage (mock port asserting DiscoverStoriesRequest flags)  
- Rationale grounded when themes match; null/absent when fallback default reflection  
- Fail-closed when candidate becomes non-discoverable between list and select  

### Integration

- Adaptive selection with real in-memory Discover* + repos  
- Private/unlisted never returned  
- Authoritative representation filters still applied by Discover*  
- End-to-end: understanding change → different story experience  

### Presentation

- Story experience card shows rationale when present  
- Begin routes correctly  
- Loading / error / unavailable / empty candidates fallback  

### Regression

Must remain green:

- H.2, UI.1–UI.3, HS.1–HS.7 suites  
- Especially: HS.6 discoverability tests; UI.3 adaptive pipeline; HS.7 experience tests  

### Analyzer

`dart analyze` clean on touched packages/files.

---

## 24. ADRs

**Numbering:** After HS.7 merge, last accepted is **HS-ADR-053**. HS.8 ADRs start at **HS-ADR-054**.  
(On current `main` without HS.7 merge, last is HS-ADR-047 — implementers must not renumber 048–053.)

Write ADRs during implementation (not as empty stubs now). Proposed set:

### HS-ADR-054 — HS.8 Is Adaptive Relevance Over Discoverable Catalog via UI.3 Seam

- **Problem:** HS.8 could be mistaken for a full Personalization Engine or a parallel recommendation UI.  
- **Decision:** HS.8 delivers deterministic Hero/Story relevance into `GetTodayExperienceUseCase` / `ExperienceSelectionService`, consuming HS.6 Discover* only.  
- **Rationale:** Preserves UI.3 replaceable seam and HS.6 eligibility.  
- **Consequences:** `ExperienceType.story` becomes selectable; HS-ADR-052 deferral ends for story selection.  
- **Rejected:** New PersonalizationEngine product; UI-owned ranking; Search*-based seeker paths.

### HS-ADR-055 — AdaptiveDiscoverySignals Instead of Full Discovery Profile Synthesis

- **Problem:** Foundation cites Discovery Profile as personalization input, but synthesis does not exist.  
- **Decision:** Introduce application `AdaptiveDiscoverySignals` sourced primarily from Journey patterns + Reflection theme IDs; optional DiscoveryProfile themes later.  
- **Rationale:** Option B — smallest truthful input contract.  
- **Consequences:** Future profile synthesis feeds the same signals object.  
- **Rejected:** Option A full synthesis in HS.8; pretending Option C exists.

### HS-ADR-056 — Adaptive Candidates Must Use Discover* and Remain Fail-Closed

- **Problem:** Personalized paths historically risk leaking unlisted/private by known id.  
- **Decision:** Candidate generation uses Discover* (or equivalent forced eligibility). Known-id hydrate for experience must re-apply policies / Get*Experience.  
- **Rationale:** Continuity of HS-ADR-043/049.  
- **Rejected:** Personalized bypass; Search* defaults.

### HS-ADR-057 — Story Adaptive Begin Routes Through HS.7, Not BeginExperienceUseCase

- **Problem:** `BeginExperienceUseCase` creates Reflections; story begin must not.  
- **Decision:** Presentation branches by `ExperienceType`; story uses HS.7 begin/consume; reflection remains optional explicit bridge.  
- **Rationale:** HS-ADR-051.  
- **Rejected:** Overloading BeginExperienceUseCase to return Story|Reflection unions.

### HS-ADR-058 — Rationale Must Be Evidence-Grounded and Non-Prescriptive

- **Problem:** Explainability can slide into fabricated coaching claims.  
- **Decision:** Rationale cites actual matched signals (themes/patterns/serendipity flag) only.  
- **Rejected:** “You need this” language; inferred pathology.

### HS-ADR-059 — (Optional) Deterministic Serendipity Is Explicit and Testable

- Only if Slice 6 ships.  
- **Decision:** Serendipity is a named rule with honest rationale; never opaque ML.

### ADR not needed now

- New NarrativeTheme ownership ADR (already AD-002 / HS-ADR-003)  
- AI-in-domain ADR (already forbidden)  
- Playback aggregate ADR (already HS-ADR-050)

---

## 25. Architecture Drift

Relevant items for HS.8 (do **not** institutionalize):

| Drift / mismatch | Classification | HS.8 handling |
|------------------|----------------|---------------|
| `technical-debt.md` TD-001 claims Pattern Detection missing; H.2 implemented patterns | Documentation drift | Report; do not “reimplement patterns” in HS.8 |
| DRIFT-005 / TD-004 closed DiscoveryProfile aggregate, but synthesis/DI still missing | Intentional incomplete foundation | Use AdaptiveDiscoverySignals; don’t claim profile complete |
| `FakeNarrativeThemeResolver` in production providers (AGENTS.md known issue) | Architectural hygiene | Manageable risk; seed explicit theme IDs in HS.8 fixtures rather than relying on fake resolver quality |
| HS.7 implementation not on `main` while docs say phase complete | Process/merge drift | **Blocker** for HS.8 implementation start |
| HS-ADR-043 unlisted known-id hint vs HS.7 fail-closed | Intentional evolution (049) | Follow fail-closed; clarify docs |
| Life Journey `DiscoverScreen` name collision with HS.6 Discover* | Naming confusion | Do not overload DiscoverScreen for HS.8 MVP |
| Maps (`aggregate-map`, `use-case-map`) still call DiscoveryProfile “Planned” | Documentation drift | Report only unless HS.8 needs map clarity |

---

## 26. Technical Debt

| Item | Classification for HS.8 |
|------|-------------------------|
| TD-001 Pattern Detection “missing” (stale) | Unrelated / docs stale — patterns exist |
| TD-002 Growth Opportunity Detection | Unrelated — out of scope |
| TD-003 Narrative Guidance Engine | Unrelated |
| TD-004 DiscoveryProfile (closed but incomplete synthesis) | Manageable — Option B avoids depending on synthesis |
| FakeNarrativeThemeResolver in prod providers | Manageable prerequisite for realistic theme signals in demo; optional fix if blocks Slice 5 |
| TD-007 Clock injection | Manageable if serendipity uses day-hash — inject clock |
| TD-008 Reflection query | **Not a blocker** — `findByJourneyId` already exists |
| Incomplete pattern rules / naming mismatches (AGENTS.md §29) | Unrelated unless consistency-only gating is insufficient |
| HS.7 unmerged | **Blocker prerequisite** |

Do not expand HS.8 into a debt cleanup program.

---

## 27. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Empty theme signals → never selects stories | Feature appears dead | Seed demo reflections/themes; keep reflection fallback |
| Theme ID mismatch between reflections and story classification | No overlaps | Shared fixture catalog of theme IDs |
| Async selection breaks UI.3 tests | Regression | Careful provider migration; keep interface tests |
| Accidentally using Search* | Privacy bug | Code review + tests asserting Discover* |
| Turning consumption into evidence | Architecture violation | Reaffirm HS-ADR-051; no new consume events |
| Scope creep into PersonalizationEngine | Delay / boundary collapse | Non-goals + ADR-054 |
| Implementing against `main` without HS.7 | Duplicate experience APIs | Slice 0 merge prerequisite |
| Hard-coding journey IDs in UI | Constraint 15 | Keep CurrentJourneyContext |

---

## 28. Open Questions

1. **Should adaptive story selection require a behavior pattern gate** (e.g. only when consistency exists), or is theme overlap alone enough?  
   - *Recommendation:* theme overlap sufficient for story candidate; patterns influence rationale and future engine, not a hard gate in MVP.  
2. **Should `AdaptiveExperience` gain structured `ExperienceTarget`, or encode `story:<id>` in `id`?**  
   - *Recommendation:* typed `ExperienceTarget` (clearer, safer).  
3. **Is optional DiscoveryProfile loading in MVP desirable for demos?**  
   - *Recommendation:* defer to after Slice 5 unless demo seeding is easier via profile.  
4. **Heroes-tab personalization in HS.8 or later?**  
   - *Recommendation:* optional Slice 7; not required for HS.8 Done.  
5. **Does selecting `ExperienceType.discovery` (vs `story`) mean anything distinct?**  
   - *Recommendation:* use `story` for a specific story experience; reserve `discovery` for future multi-item discovery experiences.  
6. **Human confirmation:** Ending HS-ADR-052 deferral (wire Stories into Today’s Experience) is intended for HS.8 — confirm product acceptance.

---

## 29. Dependencies

| Dependency | Type |
|------------|------|
| HS.7 merge / branch availability | **Hard** |
| HS.6 Discover* + policies | Hard |
| UI.3 GetTodayExperience + selection port | Hard |
| H.2 Journey patterns | Soft (fallback works without) |
| Reflection themes via findByJourneyId | Hard for thematic relevance |
| DiscoveryProfile synthesis | Not required |
| Growth Opportunities | Not required |
| Production search / AI | Not required |

---

## 30. Implementation Sequence

```text
0. Merge HS.7 (or branch from HS.7) + confirm HS-ADR-048…053 present
1. ADR drafts 054–058 (accept during impl)
2. Slice 1 — AdaptiveDiscoverySignals
3. Slice 2 — Discover*-backed relevance + privacy tests
4. Slice 3 — UI.3 composition + AdaptiveExperience target + rationale
5. Slice 4 — Presentation routing to HS.7
6. Slice 5 — Integration proof (understanding → changed story)
7. Optional Slice 6 serendipity / Slice 7 Heroes relevance
8. Update architecture decisions + HS.8 implementation report
9. Full analyze + full test suite
```

---

## 31. Definition of Done (Implementation)

HS.8 implementation is done when:

- [ ] Adaptive relevance selects a discoverable Story for Today’s Experience when theme signals match catalog content  
- [ ] Reflection fallback still works when no candidate exists  
- [ ] Selection goes through UI.3 application seam (`GetTodayExperienceUseCase`)  
- [ ] Candidates come from Discover* (not Search*, not raw repos in seeker UI)  
- [ ] Private/unlisted never appear (tests prove)  
- [ ] Rationale is present and grounded when story is selected for thematic reasons  
- [ ] Story begin uses HS.7 paths; does not create evidence automatically  
- [ ] NarrativeTheme ownership remains Discovery  
- [ ] No PersonalizationEngine product introduced  
- [ ] No second selection architecture beside UI.3  
- [ ] ADRs HS-ADR-054+ accepted and recorded  
- [ ] `dart analyze` clean  
- [ ] Focused HS.8 tests pass  
- [ ] Full suite (including H.2, UI.3, HS.6, HS.7) remains passing  
- [ ] Implementation report written  
- [ ] Open questions resolved or explicitly deferred  

---

## 32. Future Evolution

```text
Behavioral Evidence
  ↓
Behavior Patterns          ← already H.2 / Journey-owned
  ↓
Growth Opportunities       ← future
  ↓
Discovery Profile synthesis ← feeds AdaptiveDiscoverySignals
  ↓
Personalization Engine     ← replaces AdaptiveExperienceComposer / selection impl
  ↓
Adaptive Experiences       ← UI.3 seam survives
```

### Contracts that should survive

- `ExperienceSelectionService` / `GetTodayExperienceUseCase`  
- `AdaptiveExperience` (+ target/rationale)  
- `AdaptiveDiscoverySignals`  
- `DiscoverableStoryCandidatePort`  
- HS.6 Discover* eligibility  
- HS.7 experience/consume APIs  
- Evidence-first non-inference from consumption  

### What may be replaced

- Deterministic ranker implementation  
- Composer rule tables  
- Optional profile theme source adapters  

---

## 33. Final Recommendation

**Proceed with HS.8 as Adaptive Relevance for Hero/Story**, not as the Personalization Engine.

1. **Scope:** Theme/pattern-informed deterministic selection of discoverable Stories into Today’s Experience via UI.3, reusing HS.6 Discover* and HS.7 experience.  
2. **Discovery Profile:** Option B — `AdaptiveDiscoverySignals`, not full synthesis.  
3. **Engine:** Extend UI.3 selection composition; do not create `PersonalizationEngine`.  
4. **Prerequisite:** Merge HS.7 before implementation.  
5. **Serendipity / Heroes-tab extras:** Optional after the core proof loop works.  
6. **Do not implement** AI, ML, engagement optimization, or evidence-from-views.

This yields a small, testable, explainable capability that advances:

```text
User Understanding + Discoverable Catalog → Relevant Hero/Story Experience
```

…while preserving architecture boundaries and leaving a clean path to the future Personalization Engine.

---

## Appendix A — Documents Inspected

- `AGENTS.md`, `CLAUDE.md`
- `docs/architecture/Everyone’s Heroes - Hero and Story Platform Foundation.md` (§72 HS.8)
- `docs/ui/Everyone's-Heroes-UI.3-Adaptive-Experience-Foundation.md`
- `docs/architecture/architecture-decisions.md` (through HS-ADR-047 on main; 048–053 on HS.7 branch)
- `docs/architecture/architecture-drift.md`
- `docs/architecture/bounded-contexts.md`
- `docs/architecture/aggregate-map.md`
- `docs/architecture/event-flow.md`
- `docs/architecture/repository-map.md`
- `docs/architecture/use-case-map.md`
- `docs/architecture/codebase-analysis.md`
- `docs/architecture/technical-debt.md`
- `docs/architecture/testing-strategy.md`
- `docs/architecture/domain-glossary.md`
- `docs/architecture/Adaptive-Discovery-and-Evidence-Engine.md`
- `docs/architecture/phase-h-2.md`
- `docs/architecture/Everyone's-Heroes-H2-Architecture-Updated.md`
- `docs/architecture/HS.5-*`, `HS.6-*`, `HS.7-Hero-Experience-Plan.md`, `HS.7-Architecture-Decision-Lock.md`
- `origin/cursor/hs7-hero-experience-31d3` implementation report + experience use cases

## Appendix B — Discrepancy Log (docs vs code)

| Discrepancy | Intentional? | Recommendation |
|-------------|--------------|----------------|
| Foundation HS.8 text assumes Discovery Profile ready | Outdated relative to code | Plan Option B; update Foundation note when implementing |
| Foundation HS.7 lists journeys/collections | Deferred by HS-ADR-053 | Keep deferred |
| Tech debt TD-001 pattern detection missing | Stale docs | Update TD later; patterns exist |
| DiscoveryProfile “Planned” in maps vs aggregate exists | Docs lag | Treat as thin foundation |
| HS.7 “complete” vs not on `main` | Process lag | Merge before HS.8 impl |
| ADR-043 unlisted known-id vs HS.7 fail-closed | Intentional lock evolution | Prefer 049; clarify 043 |

---

*End of HS.8 Implementation Plan*
