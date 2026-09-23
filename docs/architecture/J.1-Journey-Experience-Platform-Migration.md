# J.1 — Journey & Experience Platform Migration

- **Document type:** Architecture Planning (implementation deferred)
- **Status:** Planning complete — do not implement from this pass alone without an authorized implementation task
- **Phase:** J.1 — next architectural migration after PF.3 + H.2
- **Baseline (code):** `d54106e` — *Reflection architecture migration (#56)* (PF.3 foundation + H.2 Life Journey on EH Platform)
- **Related:** `PF.2-Platform-Architecture-Decisions.md`, `PF.3-Platform-Foundation.md`, `H.2-Platform-Migration.md`, `docs/ui/Everyone's-Heroes-UI.3-Adaptive-Experience-Foundation.md`, `AGENTS.md` §10–11
- **Date:** 2026-09-23

---

## 1. Executive Summary

J.1 moves **authoritative ownership** of Experience Selection and Today’s Experience from Flutter into EH Platform, completing the next strangler step after H.2.

### Settled baseline (verified in code)

| Concern | Current owner after H.2 (`d54106e`) |
|---------|-------------------------------------|
| Identity lite + HTTP auth | **EH Platform** |
| Reflection submit → analyze → evidence → pattern detection | **EH Platform** (when `EH_PLATFORM_URL` / platform mode) |
| Journey aggregate persistence (vision, chapter, quest IDs, `behaviorPatterns`) | **EH Platform** Postgres |
| Current Journey query (`GET /v1/journeys/current`) | **EH Platform** |
| Understanding query (`GET /v1/understanding/current`) | **EH Platform** |
| Experience Selection / Today’s Experience decision | **Flutter** (UI.3 + HS.8) |
| Mission / Quest aggregates & lifecycle | **Flutter only** (platform stores `active_quest_ids` / reflection FK strings only) |
| Experience module on platform | **Stub boundary** (`ExperienceModule`) |

### J.1 goal

```text
Flutter presentation
        │  HTTP/JSON
        ▼
EH Platform
  ├── Current Journey resolution (existing)
  ├── Journey + H.2 understanding (existing)
  ├── Experience Selection (NEW authority)
  ├── Today's Experience query (NEW API)
  └── PostgreSQL (existing Journey/Reflection; no Mission/Quest expansion required)
```

Flutter becomes responsible for presentation, navigation, drafts, API client, View Models, and local transitional fallback — **not** for deciding what experience the user receives when platform mode is on.

### Explicit scope bound

J.1 migrates **UI.3 deterministic Experience Selection** (pattern → reflection experience) as the platform-authoritative path.

HS.8 Story composition (`AdaptiveExperienceComposer` + Discover* candidates) is **not** required to become production Discovery/HS authority in J.1. It is handled as a bounded transitional decision (see §11 and §26).

### Baseline SHA clarification

The brief referenced `612a0e1 Merge PF.3 platform foundation with H.2 migration`. That object **does not exist** in this repository. The equivalent integrated baseline on `main` is:

```text
d54106e Reflection architecture migration (#56)
```

which rehomes H.2 onto PF.3 (documented in `H.2-Platform-Migration.md`).

---

## 2. Current Architecture

### 2.1 Flutter (reconstructed from code)

```text
Flutter
  |
  +-- HomeScreen
  |     └── watches todayExperienceProvider
  |
  +-- Today experience presentation
  |     ├── todayExperienceProvider
  |     └── TodayExperienceViewModel
  |
  +-- ExperienceScreen / ReflectScreen
  |     ├── BeginExperienceUseCase → CreateReflection
  |     └── SubmitReflection (local or PlatformSubmitReflectionUseCase)
  |
  +-- Riverpod providers
  |     ├── getTodayExperienceUseCaseProvider  (always wires HS.8 composer)
  |     ├── experienceSelectionServiceProvider → DeterministicExperienceSelectionService
  |     ├── journeyRepositoryProvider → InMemoryJourneyRepository
  |     └── currentJourneyContextProvider → DefaultCurrentJourneyContext
  |
  +-- Application
  |     ├── DefaultGetTodayExperienceUseCase
  |     ├── AdaptiveExperienceComposer (HS.8 overlay)
  |     ├── DeterministicExperienceSelectionService (UI.3 rules)
  |     ├── ResolveAdaptiveDiscoverySignalsUseCase
  |     ├── BeginExperienceUseCase
  |     └── PlatformSubmitReflectionUseCase (H.2 client)
  |
  +-- Domain (parallel LJ tree)
  |     ├── Journey (vision, chapter, activeQuestIds, behaviorPatterns)
  |     ├── Reflection, Quest, Mission
  |     └── PatternDetector / rules (TRANSITIONAL local H.2)
  |
  +-- Local repos / cache
  |     └── InMemoryJourneyRepository (also hydrated from understanding DTO)
  |
  +-- EhPlatformClient / EhPlatformConfig
        └── journeys, reflections, understanding only — NO experiences API
```

### 2.2 EH Platform (reconstructed from code)

```text
EH Platform (services/eh_platform)
  |
  +-- PlatformComposition / runPlatformServer
  |
  +-- ApiRouter
  |     ├── GET /health, /ready, /v1/openapi.json
  |     ├── GET /v1/me
  |     └── LifeJourneyApi mount
  |           ├── POST /v1/journeys
  |           ├── GET  /v1/journeys/current
  |           ├── POST /v1/reflections
  |           ├── POST /v1/reflections/{id}/responses
  |           ├── POST /v1/reflections/{id}/submit
  |           └── GET  /v1/understanding/current
  |
  +-- Identity lite (BearerTokenAuthenticator → AuthenticatedPrincipal)
  |
  +-- LifeJourneyModule (real)
  |     ├── Journey + Reflection aggregates
  |     ├── H.2 use cases + reactors
  |     ├── PostgresJourneyRepository / PostgresReflectionRepository
  |     └── LifeJourneyApplicationService
  |
  +-- ExperienceModule (STUB — selection deferred)
  +-- DiscoveryModule / HeroStoryModule (boundary stubs)
  +-- AI StubAiProviderAdapter
  |
  +-- Persistence
  |     ├── 001_platform_foundation.sql
  |     └── 002_h2_life_journey.sql (journeys, reflections)
  |
  +-- Events (PF.3 in-process EventBus / Store / Dispatcher)
```

### 2.3 Responsibility split today

| Responsibility | Flutter | Platform |
|----------------|---------|----------|
| Decide Today’s Experience | **Yes (authoritative)** | No |
| Persist Journey behavioral state | Cache / local mode | **Yes (authoritative in platform mode)** |
| Run H.2 reactors | Transitional local only | **Yes** |
| Resolve current Journey for API principal | In-memory `CurrentJourneyContext` | `findCurrentByUserId` (latest `updated_at`) |
| Mission / Quest lifecycle | **Yes** | IDs only |
| Story relevance (HS.8) | **Yes** | No |

---

## 3. Current Journey Authority

### 3.1 Where the Journey aggregate lives

| Tree | Path | Role |
|------|------|------|
| Platform | `services/eh_platform/lib/src/life_journey/domain/aggregates/journey.dart` | **Authoritative** when platform mode is on |
| Flutter | `lib/features/life_journey/domain/aggregates/journey.dart` | Local mode authority **or** non-authoritative cache under platform mode |

### 3.2 Platform Journey fields (persisted)

From `002_h2_life_journey.sql` + aggregate:

| Field | Persisted | Notes |
|-------|-----------|-------|
| `id` | Yes | TEXT PK |
| `user_id` | Yes | FK → `identity_users` |
| `vision` | Yes | |
| `current_chapter` | Yes | |
| `active_quest_ids` | Yes JSONB | IDs only — no Quest aggregate on platform |
| `behavior_patterns` | Yes JSONB | Owned by Journey; updated by H.2 |
| `version` | Yes | Optimistic concurrency |
| timestamps | Yes | `created_at` / `updated_at` |

### 3.3 Flutter-only Journey-related state

| Concern | Owner | Notes |
|---------|-------|-------|
| `CurrentJourneyContext` | Flutter in-memory | DemoRunner sets after create; not durable |
| Quest / Mission aggregates | Flutter | Not required by UI.3 selection |
| Experience Selection inputs from local Journey | Flutter | Reads `behaviorPatterns` from local repo/cache |
| Cache hydration after platform submit | Flutter `PlatformSubmitReflectionUseCase` | Rebuilds patterns with placeholder supporting evidence |

### 3.4 How Journey is created / identified / “current”

**Platform**

1. Authenticated principal (`Authorization: Bearer …`).
2. `POST /v1/journeys` → `LifeJourneyApplicationService.createJourney` → `Journey.create` → `saveForUser`.
3. `GET /v1/journeys/current` → `_currentJourney(userId)` → `findCurrentByUserId` = **most recently `updated_at` Journey for user** (LIMIT 1). There is **no** separate session/current-pointer table.

**Flutter (local / demo)**

1. `DemoRunner.run()` if `CurrentJourneyContext` empty → `CreateJourneyUseCase` → `setCurrentJourney(journey.id)`.
2. Today’s Experience / Begin Experience fail if context is null.

### 3.5 Journey operations (current)

| Operation | Flutter | Platform |
|-----------|---------|----------|
| Create Journey | `CreateJourneyUseCase` (local) / client can call API | `POST /v1/journeys` |
| Get current Journey | `CurrentJourneyContext` + local repo | `GET /v1/journeys/current` |
| Update behavior patterns | Local H.2 **or** cache hydrate | H.2 `DetectPatternUseCase` |
| Attach quest / advance chapter | Flutter domain methods | Present on platform aggregate; **no dedicated HTTP commands** for Quest/Mission lifecycle |
| Select experience | Flutter only | — |

### 3.6 Repository / UI access

| Accessor | Path |
|----------|------|
| Flutter JourneyRepository | `InMemoryJourneyRepository` via `journeyRepositoryProvider` |
| Platform JourneyRepository | `PostgresJourneyRepository` / `OwnedInMemoryJourneyRepository` |
| UI that depends on Journey **internals** for selection | Presentation does **not** read patterns directly; selection is behind `GetTodayExperienceUseCase` (good UI.3 boundary). Understanding screen remains a placeholder. |
| Flutter code that still *decides* from Journey patterns | `DeterministicExperienceSelectionService`, `AdaptiveExperienceComposer` |

### 3.7 Capability ownership table

| Capability | Current Owner | Current Persistence | Target Owner (J.1) | Migration Required |
| ---------- | ------------- | ------------------- | ------------------ | ------------------ |
| Journey identity + vision + chapter | Platform (platform mode); Flutter local otherwise | Postgres `journeys` / in-memory | **Platform** | Tighten Flutter create/current to platform in platform mode |
| Journey `behaviorPatterns` | Platform authoritative; Flutter cache | Postgres JSONB | **Platform** | Already done (H.2); stop treating cache as selection input |
| Current Journey resolution (API) | Platform `findCurrentByUserId` | Derived from `journeys` | **Platform** | Minor: Flutter should prefer API when platform mode |
| Current Journey context (presentation pointer) | Flutter `CurrentJourneyContext` | Process memory | Flutter presentation pointer hydrated from platform | Adapt, do not put into Journey aggregate |
| Experience Selection | Flutter | N/A (computed) | **Platform Experience module** | **Yes — core J.1** |
| Today’s Experience decision | Flutter | N/A | **Platform** | **Yes — core J.1** |
| Understanding query | Platform | Derived on-read | Platform | No change required for J.1 |
| Reflection submit / H.2 | Platform | Postgres | Platform | Preserve; integration proof for Slice 4 |
| Mission / Quest lifecycle | Flutter | Flutter in-memory | **Remain Flutter (deferred)** | **No for J.1** |
| HS.8 Story candidate ranking | Flutter HS port | Local HS stores | Deferred / transitional (see §11, §26) | Not full Discovery migration |
| Behavioral Evidence storage | Platform (on Reflection) | Reflection JSONB | Platform | No change |
| Pattern detection | Platform | Via Journey update | Platform | No change — must stay separate from selection |

---

## 4. Current Experience Selection Flow

### 4.1 Implementations found

| Name | Path | Role |
|------|------|------|
| `ExperienceSelectionService` | `.../experience_selection_service.dart` | Interface `selectFor(Journey)` |
| `DeterministicExperienceSelectionService` | `.../deterministic_experience_selection_service.dart` | **UI.3 rules — actual decision for reflection path** |
| `AdaptiveExperienceComposer` | `.../adaptive_experience_composer.dart` | HS.8: Story if theme-overlapping candidates, else UI.3 |
| `GetTodayExperienceUseCase` / `DefaultGetTodayExperienceUseCase` | `.../get_today_experience_use_case.dart` | Orchestration |
| `AdaptiveExperience` | `.../adaptive_experience.dart` | Application-facing model |
| `TodayExperienceViewModel` | presentation models | UI mapping |
| Platform Experience selection | **None** | `ExperienceModule` stub only |

There is no class literally named `ExperienceSelector` / `DeterministicExperienceSelector`; the service names above are authoritative.

### 4.2 Production wiring (always HS.8-capable)

`getTodayExperienceUseCaseProvider` always injects:

* `ResolveAdaptiveDiscoverySignalsUseCase`
* `DiscoverableStoryCandidatePort` (`DiscoverStoriesCandidateAdapter`)
* `AdaptiveExperienceComposer` wrapping `DeterministicExperienceSelectionService`

Cold start with no themes / no candidates **collapses to UI.3 reflection rules**.

### 4.3 Actual UI.3 selection rules (code)

`DeterministicExperienceSelectionService.selectFor(journey)`:

| Input | Output |
|-------|--------|
| Any `behaviorPatterns` entry with `type == consistency` | `id: consistency-next-step`, `type: reflection`, title **Keep Showing Up**, rationale set, `action: begin` |
| Otherwise | `id: default-reflection`, `type: reflection`, title **Take the Next Step**, **no rationale**, `action: begin` |

Consumes **only** `journey.behaviorPatterns`. Does **not** consume Mission, Quest, chapter, vision, raw evidence, or hard-coded demo flags beyond these two constants.

### 4.4 HS.8 overlay rules (code)

`AdaptiveExperienceComposer.compose`:

1. Filter candidates with `themeOverlapCount > 0`.
2. If empty → UI.3 `selectFor(journey)`.
3. If any → take `relevant.first`; `id: adaptive-story-{storyId}`, `type: story`, optional rationale from themes/patterns.

Patterns strengthen rationale; they are **not** a hard gate for Story selection.

### 4.5 Understanding vs Recommendation (must remain separate)

```text
Understanding (H.2 — already platform)
  Behavior Pattern Detection
  "What is consistently happening?"

Recommendation / Selection (J.1 target — currently Flutter)
  Experience Selection
  "What experience should we offer next?"
```

J.1 must **not** fold selection into `DetectPatternUseCase`, reactors, or Journey aggregate methods.

---

## 5. Current Today’s Experience Flow

### 5.1 Call graph (verified)

```text
HomeScreen
  → ref.watch(todayExperienceProvider)
      → getTodayExperienceUseCaseProvider
          → DefaultGetTodayExperienceUseCase.execute()
              → CurrentJourneyContext.currentJourneyId
              → JourneyRepository.findById
              → ResolveAdaptiveDiscoverySignalsUseCase.execute(journey)   [wired]
              → DiscoverableStoryCandidatePort.findRelevant(signals)
              → AdaptiveExperienceComposer.compose(...)
                    → DeterministicExperienceSelectionService.selectFor  [fallback]
              → Success(AdaptiveExperience)
      → TodayExperienceViewModel.fromExperience
  → render card (title, description, CTA, optional rationale)

Begin Experience
  → ExperienceScreen(experience)
      → if story: StoryDetailScreen(storyId)   [HS.7 path; skips BeginExperience]
      → else: BeginExperienceUseCase → CreateReflectionUseCase
            → ReflectScreen → SubmitReflection
            → invalidate todayExperienceProvider → Home refresh
```

### 5.2 Where the decision is made

> **The decision is currently made in Flutter application code**, primarily by `DeterministicExperienceSelectionService` (reflection) and secondarily by `AdaptiveExperienceComposer` (Story override when candidates exist).

It is **not** made in:

* HomeScreen widgets (they only render View Models)
* Platform Experience module (stub)
* H.2 pattern detectors
* PostgreSQL

### 5.3 Slice 4 proof (Flutter local)

`test/integration/ui3_adaptive_experience_pipeline_test.dart`:

```text
Create journey → default-reflection
  → inject ≥3 discipline evidence → DetectPatternUseCase
  → consistency pattern on Journey
  → next experience consistency-next-step
```

Platform equivalent does **not** exist yet for Experience Selection (H.2 proves understanding only).

---

## 6. Current Flutter / Platform Boundary

### 6.1 Platform mode (`EhPlatformConfig.usePlatformAuthority`)

| Condition | Authority |
|-----------|-----------|
| `EH_H2_MODE=local` | Local Flutter H.2 |
| `EH_H2_MODE=platform` | Platform (requires URL) |
| URL set, mode unset | Platform |
| URL empty, mode unset | Local transitional |

When platform authority is on:

* `PlatformSubmitReflectionUseCase` → `EhPlatformClient.submitReflection`
* `ReactorRegistration` **skips** local H.2 reactors
* Local Journey cache hydrated from understanding DTO for **client-side selection**
* Today’s Experience still selected **locally** from that cache

### 6.2 What exists vs missing on the client

| Client capability | Exists? |
|-------------------|---------|
| `EhPlatformClient.createJourney` / `getCurrentJourney` | Yes |
| `submitReflection` / `getCurrentUnderstanding` | Yes |
| `getTodayExperience` | **No** |
| Local `GetTodayExperienceUseCase` selection | **Yes (authoritative today)** |

### 6.3 Known transitional coupling (H.2 doc)

H.2 intentionally left Experience Selection client-side, depending on hydrated Journey pattern cache. J.1 exists to remove that coupling.

---

## 7. Target Architecture

```text
Home
  ↓
TodayExperienceProvider
  ↓
EhPlatformClient.getTodayExperience()
  ↓
GET /v1/experiences/today
  ↓
EH Platform Experience application service
  ↓
Current Journey resolution (existing)
  ↓
Journey.behaviorPatterns (+ optional understanding read)
  ↓
Deterministic Experience Selection (platform)
  ↓
TodayExperienceDto (presentation-facing)
  ↓
Flutter TodayExperienceViewModel
  ↓
UI
```

Adaptive loop after reflection:

```text
Reflection submit (existing H.2 API)
  ↓
Platform H.2 → Journey patterns updated
  ↓
GET /v1/experiences/today
  ↓
New Today's Experience DTO
```

This is the platform version of UI.3 Slice 4.

---

## 8. Ownership Model

### Flutter owns

* Presentation / navigation / device capabilities
* Local drafts (pre-submit reflection UI state)
* Optional **read-through cache** of last Today Experience DTO (non-authoritative)
* `EhPlatformClient` + View Model mapping
* User interaction (Begin → Reflect UI)
* Transitional local selection **only** when platform mode is off (tests/offline demos)

### Flutter must not own (platform mode)

* Journey authoritative state
* Behavioral understanding / pattern detection
* Experience Selection rules
* Today’s Experience decision-making

### Platform owns

* Current Journey resolution for authenticated user
* Journey + Reflection + H.2 (already)
* Experience Selection (J.1)
* Today’s Experience query DTO (J.1)
* PostgreSQL authoritative state

### Module placement (aligns PF-ADR-002 / 013)

| Concern | Module |
|---------|--------|
| Journey / H.2 | `life_journey` |
| Experience Selection / Today’s Experience | `experience` (activate stub → real composition) |
| Discovery catalog / Influences | Deferred |
| Hero & Story candidate search | Deferred as platform dependency; see §11 |

Experience module may **read** Life Journey repositories/ports; it must not become a second pattern detector.

---

## 9. Journey Migration Plan

### What already moved (H.2) — reuse

* Journey aggregate on platform
* Postgres `journeys` including `behavior_patterns`
* `POST /v1/journeys`, `GET /v1/journeys/current`
* Ownership checks via `user_id`

### What J.1 still needs for Journey

1. **Platform-mode Flutter bootstrap** should create/load Journey via platform APIs (not only local `DemoRunner` create), then set `CurrentJourneyContext` from `journeyId` returned by platform.
2. **Stop using local Journey patterns as selection authority** once `GET /v1/experiences/today` is authoritative.
3. **Do not expand Quest/Mission** into platform lifecycle APIs for J.1.
4. **Do not invent a new current-Journey session framework** — continue principal → `findCurrentByUserId` (document limitations in §10 / §26).

### Journey fields required by selection (minimum)

| Field | Required for UI.3 selection? |
|-------|------------------------------|
| `behaviorPatterns` | **Yes** |
| Journey id | Yes (correlation / DTO context) |
| vision / chapter | No for current rules |
| `active_quest_ids` | No for current rules |
| Mission / Quest progress | No |

Therefore J.1 requires **no new Journey columns** for the UI.3 selector.

---

## 10. Current Journey Context

UI.3 distinguishes:

> Which Journey is the application currently presenting?

from Journey domain internals and from Experience Selection.

### Target model

```text
authenticated user
      ↓
platform current Journey resolution (findCurrentByUserId)
      ↓
Journey (authoritative)
      ↓
Experience Selection uses Journey understanding
```

Flutter `CurrentJourneyContext` remains a **presentation/application pointer** (for Begin Experience → create reflection with a journeyId, navigation continuity). It must be **hydrated from platform** in platform mode, not manufactured as a competing authority.

### Explicit non-goals for current context

* Do not embed “current” flag inside the Journey aggregate.
* Do not build a permanent multi-device session-management framework in J.1.
* Accept current heuristic: latest `updated_at` Journey per user (document as open product risk if multi-Journey becomes real).

---

## 11. Experience Selection Migration

### 11.1 What moves

| Component | Disposition |
|-----------|-------------|
| `DeterministicExperienceSelectionService` rules | **REIMPLEMENT** under `services/eh_platform/.../experience/` |
| `ExperienceSelectionService` seam | **REIMPLEMENT** platform port/interface |
| `GetTodayExperience` orchestration | **NEW** platform application query/service |
| `AdaptiveExperience` → DTO | **NEW** presentation-facing DTO (not domain aggregate) |
| Flutter selector as authority | **ADAPT** → call API in platform mode; keep local for transitional tests |

### 11.2 What selection consumes on platform (J.1)

**Required:** current Journey’s `behaviorPatterns` (same UI.3 rules).

**Not required:** Mission state, Quest state, Growth Opportunities, DiscoveryProfile, ML, AI.

### 11.3 HS.8 Story path (bounded)

Full HS.8 Story selection depends on Flutter Hero & Story discovery ports and Reflection narrative themes. Migrating that as production Discovery/HS platform authority is a **non-goal** for J.1.

**Recommended J.1 stance (settled for planning):**

1. Platform Experience Selection implements **UI.3 deterministic reflection selection** as the authoritative decision.
2. Platform may expose a replaceable `DiscoverableStoryCandidatePort` that **defaults to empty** (fail-closed / fallback to reflection), preserving the seam for a later phase.
3. Flutter must **not** override platform Today Experience with a second local composer when platform mode is on.
4. HS.8 Story-in-Today remains available under **local transitional mode** until a later Discovery/HS platform wiring phase explicitly migrates candidate search.

This preserves PF-ADR-013 (“platform owns experience selection”) without prematurely implementing Discovery Platform Integration.

### 11.4 Separation from H.2

Do **not**:

* Add selection logic to `DetectPatternUseCase`
* Raise selection from `BehavioralEvidenceDetectedReactor`
* Store “selected experience” on Journey as authoritative domain state (optional cache of last DTO is infrastructure/read-model only if needed later)

---

## 12. Today’s Experience API

### 12.1 Endpoint

```text
GET /v1/experiences/today
```

Authenticated. Uses existing Identity lite bearer principal. Resolves current Journey server-side — **client should not send JourneyId for authoritative selection** (optional debug override is rejected for production path).

Existing H.2 endpoints remain; they are **necessary but not sufficient** for J.1:

| Endpoint | Sufficient for Today’s Experience? |
|----------|-------------------------------------|
| `GET /v1/journeys/current` | No — summary only; client must not re-select |
| `GET /v1/understanding/current` | No — understanding ≠ recommendation |
| `GET /v1/experiences/today` | **Yes — required** |

### 12.2 Request

* Method: `GET`
* Headers: `Authorization: Bearer <token>`; optional `X-Correlation-Id`
* Body: none
* Query: none required for v1

### 12.3 Success response (`200`) — presentation DTO

Stable, UI-facing fields (no aggregate dump):

```json
{
  "experienceId": "consistency-next-step",
  "experienceType": "reflection",
  "title": "Keep Showing Up",
  "description": "Take one small step today...",
  "action": "begin",
  "rationale": "You have been building consistency across your recent journey.",
  "journeyId": "<id>",
  "explanation": {
    "sources": [
      { "kind": "behavior_pattern", "value": "consistency" }
    ]
  },
  "target": null
}
```

Story-shaped future extension (not required to be live in J.1):

```json
"target": { "kind": "story", "storyId": "..." }
```

### 12.4 Empty / unavailable

| Case | HTTP | Behavior |
|------|------|----------|
| No current Journey | `404` `not_found` | Flutter shows empty/unavailable Today state |
| Unauthenticated | `401` | Existing auth middleware |
| Forbidden / ownership | N/A for today query (resolved by principal) | — |
| Selection always yields default or consistency | `200` | UI.3 has no “empty experience” when Journey exists |

### 12.5 Errors

Reuse PF.3 / H.2 error envelope:

```json
{ "error": { "code": "...", "message": "...", "correlationId": "..." } }
```

### 12.6 Must NOT expose

* Journey aggregate internals beyond `journeyId` (+ optional chapter if product wants display later — **not required**)
* `BehaviorPattern` domain objects / strengths / supporting evidence arrays
* Domain events
* DB rows / repository details
* Detector rule names as user-facing copy (rationale may mention grounded pattern **types** already used by UI.3)

### 12.7 Begin Experience

J.1 does **not** require a new `POST /v1/experiences/{id}/begin` if Begin continues to mean “create reflection on current Journey” via existing `POST /v1/reflections`. Keep Begin as client orchestration over existing reflection commands unless product later needs experience-scoped begin semantics.

---

## 13. DTO / View Model Design

```text
Platform TodayExperienceDto
        ↓  EhPlatformClient JSON
Flutter TodayExperienceDto (infra mapping)  [optional thin type]
        ↓
TodayExperienceViewModel (presentation)
        ↓
Home / Experience UI
```

### Mapping rules

* Preserve existing View Model fields: `id`, `experienceType`, `title`, `description`, `action`, `callToAction`, `rationale`, `storyTargetId`.
* Prefer adapting `TodayExperienceViewModel.fromExperience` → `fromDto` rather than teaching widgets about HTTP.
* Do not map DTOs into Flutter domain `Journey` merely to re-run selection.

### AdaptiveExperience on Flutter

Under platform mode, Flutter application should treat `AdaptiveExperience` as optional transitional local model. Long-term, presentation can map DTO → View Model directly (Phase 9 simplification).

---

## 14. Stable Experience Identity

### Current model

UI.3 uses **stable string catalog ids**, not generated UUIDs per request:

| Id | Meaning |
|----|---------|
| `default-reflection` | Default next step |
| `consistency-next-step` | Consistency-informed reflection |
| `adaptive-story-{storyId}` | HS.8 Story experience (Flutter today) |

These ids are already used for rendering and tests; they are **catalog/template identities**, not per-day instance ids.

### J.1 minimum identity requirements

| Need | Approach |
|------|----------|
| Rendering / navigation | Reuse catalog `experienceId` strings |
| Action handling | `experienceType` + `action` (+ optional `target`) |
| Reflection correlation | Reflection links to `journeyId` (existing); optional later `experienceId` on create is **not required** for J.1 |
| Analytics / personalization later | Catalog id is enough to start; defer per-impression UUIDs |

**Do not invent** an elaborate experience-instance aggregate, experience repository, or daily rotation store unless product requires impression tracking. Selection remains **on-read composition** (PF.2 preference).

---

## 15. Persistence Changes

### Required for J.1

| Change | Needed? |
|--------|---------|
| New `experiences` table | **No** (on-read composition) |
| New Journey columns | **No** for UI.3 rules |
| Mission/Quest tables | **No** |
| Migrations beyond docs/tests wiring | **None expected** for minimum J.1 |

### Already sufficient

* `journeys.behavior_patterns`
* `reflections` (H.2 evidence lineage)
* Identity + idempotency tables (unchanged)

### Optional later (out of J.1 unless proven necessary)

* Projection table for today’s experience cache
* `domain_event_log` consumers
* Per-impression experience history

---

## 16. Mission / Quest Boundary

| Question | Finding |
|----------|---------|
| Does Today’s Experience depend on Mission? | **No** (UI.3/HS.8 code paths) |
| Does it depend on Quest? | **No** |
| Are Mission/Quest inside Journey? | Journey stores `activeQuestIds` only; Quest/Mission are separate Flutter aggregates |
| Migrated to platform? | **No** lifecycle; IDs only on Journey/Reflection rows |
| Can they remain client-side temporarily? | **Yes** |
| Does J.1 require migration? | **No** |

**Explicit:** Do not expand J.1 into Quest/Mission platform APIs merely because PF.2 Phase 4 listed them. J.1 is Journey + Experience Selection authority for the **current** selection behavior.

---

## 17. Authentication / Identity Boundary

Preserve H.2 / PF.3 Identity lite:

* `Authorization: Bearer <token>`
* `BearerTokenAuthenticator` → `AuthenticatedPrincipal`
* Dev token via `EH_DEV_AUTH_TOKEN` / Flutter `EH_PLATFORM_AUTH_TOKEN` / `EH_PLATFORM_USER_ID` fallback
* Ownership: Experience today resolves Journey by authenticated `userId` only

**Non-goals:** IdP providers, refresh tokens, RBAC expansion, subscriptions.

---

## 18. Transaction / Consistency Model

### Boundaries

| Operation | Transaction |
|-----------|-------------|
| `GET /v1/experiences/today` | Read-only UnitOfWork / read path; **no** write; no distributed transaction |
| `GET /v1/journeys/current`, `GET /v1/understanding/current` | Read |
| Reflection submit + H.2 | Existing write UnitOfWork wrapping submit → reactors → Journey pattern update |
| Journey create | Existing write UoW |

### Adaptive consistency sequence

```text
1. GET /experiences/today
     → read current Journey patterns → DTO A

2. User begins experience
     → create reflection draft (existing API / local draft)

3. User submits reflection
     → H.2 UoW commits evidence + updated patterns

4. Client invalidates Today provider / refetches
     → GET /experiences/today
     → DTO B (may differ if patterns changed)

5. No requirement that step 1 and step 4 share a transaction
```

Preserve eventual UI refresh semantics already used by UI.3 (`invalidate(todayExperienceProvider)`). Do not introduce 2PC across Flutter and platform.

---

## 19. Caching / Offline Strategy

### Authoritative source

In platform mode: **EH Platform** for Journey understanding and Today’s Experience decision.

### Minimum viable behavior

| Situation | Behavior |
|-----------|----------|
| Platform unavailable / timeout on Today fetch | Show error / unavailable Today state; do **not** silently run Flutter selector as if it were platform authority |
| Stale cached Today DTO | Optional short-lived UI cache for last successful DTO; label as stale if shown; refetch on resume |
| Stale Journey local cache | Must not drive platform-mode selection |
| Offline reflection draft | Allowed as UI/local draft (existing PF-ADR-012 spirit) |
| Offline reflection submit | Queue or fail; authoritative submit requires online (H.2 already) |
| Local mode (`EH_H2_MODE=local` or no URL) | Existing Flutter selection + local H.2 remain for tests/demos |

### Deferred

* Full sync protocol
* Conflict resolution beyond “server wins after ACK”
* Offline EventBus mirroring

### Later deletion candidates (Phase 9 style)

* Flutter `DeterministicExperienceSelectionService` production path
* Flutter `AdaptiveExperienceComposer` production override
* Journey cache hydration solely for selection
* Local H.2 reactors (already gated)

---

## 20. Event Strategy

### J.1 requirement

**No new domain event is required** for Experience Selection.

Selection is a **query**. Emitting `ExperienceSelected` would be optional analytics later, not an architectural necessity for authority migration.

### Preserve

* Existing H.2 events stay platform-internal
* PF.3 in-process EventBus / Dispatcher
* **Do not** introduce Kafka, outbox workers, or multi-service event mesh

### Do not

* HTTP-expose domain events
* Have Flutter construct or publish selection/H.2 events in platform mode

---

## 21. Testing Strategy

### Platform unit tests

**Journey (existing + tighten):**

* current Journey resolution
* persistence / ownership
* invariants needed by selection (`behaviorPatterns` update)

**Experience (new):**

* consistency pattern → `consistency-next-step`
* no / unknown patterns → `default-reflection`
* stable catalog ids
* does not read Mission/Quest
* empty Journey → not_found at API layer
* selection does not mutate Journey

### Application tests

```text
GetTodayExperience
  → Current Journey
  → patterns / understanding
  → Experience Selection
  → DTO
```

### API tests

```text
HTTP + Auth → Experience handler → application → DTO
401 without bearer
404 without journey
200 with default and consistency cases
```

### Critical integration test (platform Slice 4)

```text
Create Journey
  → default Today experience
  → create/submit reflections producing ≥3 discipline evidence
  → H.2 updates Journey consistency pattern
  → GET /v1/experiences/today
  → consistency-next-step
```

Do not remove existing H.2 behavioral understanding tests.

### Flutter tests

* DTO → View Model mapping
* `todayExperienceProvider` loading / success / empty / failure
* platform client `getTodayExperience`
* navigation / begin / reflection invalidate refresh under platform-backed fake client
* architecture test: presentation must not import platform selection rules / detectors
* keep local UI.3 tests for transitional local mode

---

## 22. Architecture Regression Checks

### Flutter must NOT (platform mode)

Automated (preferred) or CI grep/architecture tests:

* Import/call `DeterministicExperienceSelectionService` from production Today provider path
* Inspect `BehaviorPattern` lists to invent recommendations in presentation
* Invoke `PatternDetector` / analyze reactors
* Import `services/eh_platform` persistence
* Construct H.2 / selection domain events
* Manufacture Journey ids solely to drive selection instead of API

### Platform must

* Own Journey + H.2 state
* Own Experience Selection implementation under Experience module
* Own `GET /v1/experiences/today` decision
* Persist authoritative Journey/Reflection state in Postgres (or in-memory test double)

### Suggested test locations

* `services/eh_platform/test/architecture/...` dependency direction (Experience must not be owned by Flutter)
* `test/architecture/...` Flutter presentation import bans (extend H.2 authority tests)

---

## 23. Incremental Implementation Sequence

Adjusted from the brief based on code: Journey/current/understanding APIs **already exist**; J.1 centers on Experience Selection + Flutter cutover.

### Slice 1 — Platform Experience Selection core

* Activate `ExperienceModule` composition
* Port `DeterministicExperienceSelectionService` rules
* Unit tests for selection
* **Files likely:**  
  `services/eh_platform/lib/src/modules/experience/experience_module.dart`  
  `services/eh_platform/lib/src/experience/**` (new)  
  `services/eh_platform/lib/src/platform_composition.dart`

### Slice 2 — `GET /v1/experiences/today`

* Application query + API handler + DTO
* Auth + current Journey resolution reuse from Life Journey
* API tests  
* **Files likely:**  
  `services/eh_platform/lib/src/api/...` (experience routes or `ExperienceApi`)  
  `services/eh_platform/lib/src/api/api_router.dart`  
  OpenAPI update when contracts are published

### Slice 3 — Flutter Today Experience platform client

* `EhPlatformClient.getTodayExperience`
* Provider switch: platform mode → HTTP DTO → View Model
* Loading / error / empty states
* **Files likely:**  
  `lib/features/life_journey/infrastructure/platform/eh_platform_client.dart`  
  `lib/features/life_journey/presentation/providers/today_experience_provider.dart`  
  `get_today_experience_use_case_provider.dart` (platform adapter use case)  
  `today_experience_view_model.dart`

### Slice 4 — Adaptive loop integration proof

* Platform integration test: Reflection → H.2 → new Today experience
* Flutter integration with fake/real platform: submit → invalidate → new card
* Align with UI.3 Slice 4 acceptance

### Slice 5 — Remove Flutter selection authority (platform mode)

* Gate local selector behind local mode only
* Stop Journey cache hydration **for selection** (cache may remain for other UI if needed)
* Architecture regression tests
* Document remaining HS.8 local-only behavior

### Optional parallel (bootstrap hygiene)

* Platform-mode `DemoRunner` / startup: `getCurrentJourney` or `createJourney` via `EhPlatformClient` before Home loads

---

## 24. Explicit Non-Goals

J.1 must **not** implement:

* Discovery Platform Integration / DiscoveryProfile synthesis
* Growth Opportunity Detection
* Production Personalization Engine / ML ranking / recommendation optimization
* AI personalization / AI-generated experiences
* AI Story Builder / Coach changes
* Hero & Story authority migration
* Production media infrastructure
* Authentication providers beyond Identity lite
* Subscriptions / marketplace / social / push infra
* Kafka / outbox / microservices / Rust platform
* Major UX redesign
* Full Mission/Quest platform lifecycle (unless a later authorized phase)
* Premature shared domain packages across Flutter and platform (PF-ADR-011)

UI.3 deferred Personalization Engine etc.; J.1 preserves deterministic replaceable selection.

---

## 25. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| HS.8 Story Today regresses if Flutter composer is removed before platform candidates exist | Story experiences disappear in platform mode | Document intentional deferral; keep local mode; empty candidate port seam on platform |
| Dual Journey trees drift (Flutter vs platform) | Cache/selection inconsistency | Platform mode must not select locally; hydrate context from API |
| `findCurrentByUserId` = latest updated Journey | Wrong Journey if multi-Journey appears | Open product decision; acceptable for current single-Journey demos |
| Placeholder supporting evidence in Flutter cache hydration | Misleading if used for anything beyond patterns-by-type | Eliminate selection dependency on cache |
| Emoji analyzer vs ConsistencyPatternRule discipline threshold | Live UI may not flip to consistency as Slice 4 does with injected evidence | Known H.2/UI gap; do not “fix” via selection cheating |
| Treating understanding DTO as experience | Client reintroduces selection | Architecture tests + provider switch |
| Scope creep into Quest/Mission Phase 4 | Delays Experience authority | Keep Mission/Quest out of J.1 |
| Baseline SHA confusion (`612a0e1`) | Planning against wrong tree | Use `d54106e` / H.2 migration doc |

---

## 26. Open Decisions

Separated from settled planning decisions.

### Settled by this plan

1. Platform owns Experience Selection and Today’s Experience in platform mode.
2. UI.3 deterministic rules are the J.1 selection semantics.
3. `GET /v1/experiences/today` is the required API.
4. Mission/Quest lifecycle is out of J.1.
5. No new experience persistence table required.
6. No ExperienceSelected event required.
7. Understanding vs recommendation separation preserved.
8. Identity lite auth reused.
9. On-read selection composition preferred.

### Open (need product/architecture confirmation before or during implementation)

| # | Decision | Notes |
|---|----------|-------|
| O1 | Exact HS.8 Story Today behavior under platform mode for J.1 release | Recommend: reflection-only platform Today; Story overlay deferred |
| O2 | Whether Flutter may show last-known Today DTO when offline | Product UX choice; architecture allows optional stale read-only cache |
| O3 | Multi-Journey “current” semantics beyond latest `updated_at` | Only if product introduces multiple concurrent Journeys |
| O4 | Whether Begin Experience gains a dedicated platform command | Default: reuse reflection create |
| O5 | Whether explanation.sources is required in v1 DTO or rationale string alone | PF-ADR-013 prefers real sources; start minimal with pattern type sources |
| O6 | Timing of deleting Flutter local selector entirely | Exit criterion tied to mandatory `EH_PLATFORM_URL` (Phase 9-ish) |

---

## 27. Acceptance Criteria

### Planning phase (this document)

- [x] Actual Journey ownership documented
- [x] Actual Today Experience flow documented
- [x] Actual Experience Selection implementation documented
- [x] Current Flutter/platform boundary documented
- [x] Current H.2 integration understood
- [x] Target Journey / Selection / Today authority defined
- [x] API contract proposed
- [x] DTO / View Model boundary defined
- [x] Stable experience identity addressed
- [x] PostgreSQL changes identified (none required for minimum)
- [x] Mission/Quest scope bounded
- [x] Current Journey context bounded
- [x] Auth boundary preserved
- [x] Transaction/consistency defined
- [x] Caching/offline minimum defined
- [x] Event requirements identified
- [x] Platform + Flutter tests planned
- [x] Architecture regression checks planned
- [x] Incremental slices defined
- [x] Non-goals / risks / open decisions explicit
- [x] No production implementation code changed in this planning pass

### Future implementation phase (not this pass)

- [ ] `GET /v1/experiences/today` returns UI.3-equivalent decisions
- [ ] Platform Slice 4 integration green
- [ ] Flutter platform mode Home uses platform DTO only for Today decision
- [ ] `dart analyze` clean; focused + relevant suites green
- [ ] Architecture regression checks green

---

## 28. Proposed Next Phase

**Authorized next implementation work:** execute J.1 Slice 1–4 as an implementation task (separate from this planning document).

Suggested follow-ons after J.1:

1. **Client simplification** — delete Flutter selection authority when platform URL is mandatory.
2. **PF Discovery / HS candidate port on platform** — restore Story-in-Today without client-side selection authority.
3. **Quest/Mission platform APIs** — only if product requires them for Journey screens (PF.2 Phase 4 remainder).
4. **Personalization Engine** — still deferred; replace deterministic selector behind the same Experience seam when ready.

---

## Appendix A — Key files inspected

### Architecture / UI docs

* `docs/architecture/H.2-Platform-Migration.md`
* `docs/architecture/PF.2-Platform-Architecture-Decisions.md`
* `docs/architecture/PF.3-Platform-Foundation.md`
* `docs/architecture/Everyone's-Heroes-Overall-Architecture.md`
* `docs/architecture/Everyone's-Heroes-H2-Architecture-Updated.md`
* `docs/architecture/phase-h-2.md`
* `docs/ui/Everyone's-Heroes-UI.3-Adaptive-Experience-Foundation.md`

### Flutter

* `lib/features/life_journey/application/services/deterministic_experience_selection_service.dart`
* `lib/features/life_journey/application/services/adaptive_experience_composer.dart`
* `lib/features/life_journey/application/use_cases/get_today_experience_use_case.dart`
* `lib/features/life_journey/application/use_cases/begin_experience_use_case.dart`
* `lib/features/life_journey/application/use_cases/platform_submit_reflection_use_case.dart`
* `lib/features/life_journey/application/providers/use_cases/get_today_experience_use_case_provider.dart`
* `lib/features/life_journey/application/context/current_journey_context.dart`
* `lib/features/life_journey/application/models/adaptive_experience.dart`
* `lib/features/life_journey/presentation/providers/today_experience_provider.dart`
* `lib/features/life_journey/presentation/models/today_experience_view_model.dart`
* `lib/features/life_journey/presentation/screens/home_screen.dart`
* `lib/features/life_journey/infrastructure/platform/eh_platform_client.dart`
* `lib/features/life_journey/infrastructure/platform/eh_platform_config.dart`
* `lib/bootstrap/reactor_registration.dart`
* `lib/app/demo_runner.dart`
* `test/integration/ui3_adaptive_experience_pipeline_test.dart`

### Platform

* `services/eh_platform/lib/src/modules/experience/experience_module.dart`
* `services/eh_platform/lib/src/modules/life_journey/life_journey_module.dart`
* `services/eh_platform/lib/src/life_journey/domain/aggregates/journey.dart`
* `services/eh_platform/lib/src/life_journey/application/life_journey_application_service.dart`
* `services/eh_platform/lib/src/life_journey/application/dto/view_models.dart`
* `services/eh_platform/lib/src/life_journey/infrastructure/persistence/postgres_journey_repository.dart`
* `services/eh_platform/migrations/002_h2_life_journey.sql`
* `services/eh_platform/lib/src/api/api_router.dart`

---

## Appendix B — Mapping to PF.2 phases

| PF.2 phase | Status relative to J.1 |
|------------|-------------------------|
| Phase 2 Platform foundation | Done (PF.3) |
| Phase 3 Reflection / H.2 | Done (`d54106e`) |
| Phase 4 Journey / Understanding | **Partially done** by H.2 (Journey + understanding queries exist; Quest/Mission API not done) |
| Phase 5 Experience Selection | **J.1 implements the critical Experience Selection / Today API slice** without waiting on Quest/Mission expansion |
| Phase 6+ | Explicit non-goals |

J.1 is therefore best described as: **Experience Selection authority migration**, leveraging Journey state already present from H.2, rather than a full PF.2 Phase 4 Quest/Mission program.

---

**End of J.1 Journey & Experience Platform Migration planning document.**
