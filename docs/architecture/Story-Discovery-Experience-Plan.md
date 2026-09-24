# Story Discovery Experience Plan

- **Document type:** Implementation plan (planning only)
- **Slice:** A — Story Discovery Experience Completion
- **Status:** Planning complete — **do not implement from this document alone until separately authorized**
- **Baseline (code):** `main` @ `8743854` (includes PR #65 J.2 Slice 5 + PR #66 Post–J.2 Slice 5 Verification)
- **Predecessor:** `docs/architecture/Post-J2-Slice5-Verification.md` (merged)
- **Constraint:** Planning only. Do not modify application code, reopen J.2, start Phase 7, or introduce a multi-device Story content API under this plan.

---

## 1. Purpose

Define the **smallest complete vertical slice** that finishes the user-visible Story discovery path already selected by Today:

```text
Today
  ↓
Story Candidate (single adaptive-story-* experience)
  ↓
Story Detail
  ↓
Story Experience
  ↓
explicit path to Reflection
  ↓
(optional) Reflection submit → H.2 → Today refresh
```

This slice validates the product claim that a seeker can discover and meaningfully experience a Story through Today under **current Flutter Story authority / same-device assumptions**.

It does **not**:

* redesign Today or the Story domain
* create a Candidate aggregate
* migrate Story content to the platform
* treat Story consume as Behavioral Evidence
* introduce Growth Opportunities, Personalization, ML ranking, or generalized frameworks

---

## 2. Current Implementation

Code-traced on current `main`. The chain already exists; this slice is **completion and continuity**, not greenfield.

### 2.1 End-to-end chain (exists)

```text
HomeScreen (_ExperienceCard)
  → todayExperienceProvider
  → GetTodayExperienceUseCase
       ├─ PlatformGetTodayExperienceUseCase → GET /v1/experiences/today
       │     + DiscoverableStoryCandidatePort (Postgres projection)
       │     + AdaptiveExperienceComposer
       └─ DefaultGetTodayExperienceUseCase (local)
             + DiscoverStoriesCandidateAdapter (Flutter Discover*)
  → TodayExperienceViewModel (id=adaptive-story-{storyId}, storyTargetId)
  → ExperienceScreen
       ├─ ExperienceType.story → StoryDetailScreen(storyId)
       └─ reflection → BeginExperienceUseCase → ReflectScreen
  → GetStoryExperienceUseCase (discoverability-gated)
  → StoryDetailScreen → “Begin story”
  → StoryConsumeScreen
       → BeginStoryExperienceUseCase
       → LoadStoryMediaUseCase (bytes meta only on seeker path)
       → ConsumeStoryExperienceUseCase (mark complete; no evidence)
       → StartStoryReflectionUseCase (optional CTA)
  → ReflectScreen → submit
       → invalidate todayExperienceProvider
       → popUntil(isFirst)
```

### 2.2 Inventory by concern

| Concern | Status | Primary symbols / paths |
|---------|--------|-------------------------|
| Today candidate presentation | **Exists** (single card, not a feed) | `HomeScreen` / `_ExperienceCard`; `todayExperienceProvider` |
| Candidate selection | **Exists** (deterministic) | `AdaptiveExperienceComposer`; platform/local Today UCs |
| Navigation Today → Detail | **Exists** | `Navigator` + `MaterialPageRoute` via `ExperienceScreen` |
| Story Detail | **Exists** | `StoryDetailScreen`; `storyExperienceProvider`; `GetStoryExperienceUseCase` |
| Story Experience / Consume | **Exists** (text-first) | `StoryConsumeScreen`; `Begin*` / `Consume*` / `ResolvePlayable*` |
| Representation selection | **Exists** | `PlayableRepresentationSelector` (HS.7 D3) |
| Seeker media load | **Exists** | `LoadStoryMediaUseCase` + `StoryMediaStoragePort` |
| Seeker A/V playback UI | **Partial** | Bytes length only; owner path has `OwnedStoryPlaybackController` + `just_audio` |
| Explicit Reflect CTA | **Exists** | `StartStoryReflectionUseCase` → `ReflectScreen` |
| StoryId on Reflection aggregate | **Absent by design** (HS.7) | StoryId validated then discarded; prompt/UX context only |
| Post-submit Today refresh | **Exists** | `ref.invalidate(todayExperienceProvider)` + `popUntil(isFirst)` |
| Named routes / `go_router` | **Absent** | Imperative `Navigator` only — keep it |
| Candidate → platform projection | **Exists** (J.2 Slice 5) | Soft-fail sync after publish/archive/visibility/classify |
| Platform Story narrative API | **Absent** | Deferred (Phase 7 / multi-device) |

### 2.3 What “candidate” means on Today

Today does **not** render a list of Story candidates.

`AdaptiveExperienceComposer` ranks discoverable candidates (theme overlap → pattern boost → `updatedAt` → `storyId`) and emits **one** `AdaptiveExperience`:

* `id`: `adaptive-story-{storyId}`
* `type`: `ExperienceType.story`
* `title`: candidate title
* `description`: fixed grounded copy about journey themes
* `rationale`: grounded string from matched themes / patterns
* `target`: `StoryExperienceTarget(storyId)`

Fail-closed: no theme overlap → reflection experience (existing UI.3 path).

### 2.4 Relevant existing tests

| Area | Tests |
|------|-------|
| Today card / begin | `home_screen_test.dart` |
| ExperienceScreen story routing | `hs8_experience_screen_story_routing_test.dart` |
| Today VM / provider | `today_experience_view_model_test.dart`, `today_experience_provider_test.dart` |
| Adaptive composition | `adaptive_experience_composer_test.dart`, `hs8_get_today_experience_adaptive_test.dart` |
| HS.7 experience UCs + UI | `hs7_hero_experience_test.dart`, `hs7_hero_experience_ui_test.dart` |
| Reflect + Today invalidate | `reflect_screen_test.dart` |
| Integration | `hs8_adaptive_hero_discovery_pipeline_test.dart`, `ui3_adaptive_experience_pipeline_test.dart` |
| Platform candidates | `services/eh_platform/test/j2_*` |

**Gap:** focused tests that assert the **Today → Detail → Consume → Reflect** continuity story as one product path (including unavailable Story fail-closed from a Today-selected id).

---

## 3. Verified Product Boundary

Inherited from Post–J.2 Slice 5 Verification and confirmed against code:

### In bounds

* Flutter `Story` aggregate remains narrative authority
* Platform remains authority for Today selection + candidate projection when platform mode is on
* Same-device / shared Flutter Story-store assumptions
* Deterministic adaptive selection (not Personalization Engine)
* Consume / listen / complete **does not** create Behavioral Evidence
* Reflection remains the evidence-producing boundary
* Reuse HS.7 screens and use cases; reuse media storage port; reuse H.2 Reflect workflow

### Out of bounds

* Multi-device Story content API / platform Story narrative read
* Phase 7 Hero & Story migration
* New Candidate aggregate
* Growth Opportunity Detection
* Personalization Engine / ML ranking / AI personalization
* Generalized recommendation or adaptive-experience frameworks
* D.1 DiscoveryProfile productization
* Contribution / social / marketplace / subscriptions
* Redesign of Today or Story domain model
* Reopening J.2 eligibility / projection schema unless a defect blocks this slice

### Critical behavioral boundary

```text
Story view / open / begin / consume / mark complete
        ↓
NO Behavioral Evidence

Story → explicit Reflection submit → H.2 → updated understanding → Today refresh
        ↓
YES Behavioral Evidence (and patterns)
```

---

## 4. User Journey

### Intended narrow flow

```text
1. Seeker opens Home (Today)
2. Today shows one Story experience (adaptive-story-*) when theme overlap exists
3. Seeker taps Begin Experience
4. ExperienceScreen confirms context (title, description, rationale)
5. Seeker continues → Story Detail (narrative + forms + Begin story)
6. Seeker enters Story Experience (consume)
7. Seeker reads narrative / selected representation text; media degrades gracefully
8. Seeker may Mark complete (ephemeral; no evidence)
9. Seeker may Reflect on this story (explicit)
10. Seeker submits Reflection → H.2 → Today invalidated → return to Home
```

### Product behaviors (defined)

| Step | Behavior |
|------|----------|
| **Candidate card presents** | Story title; short description; optional grounded rationale; CTA “Begin Experience”; optional stale banner. Does **not** show popularity, engagement, ML scores, or a candidate list. |
| **On select** | Navigate to `ExperienceScreen` with the same `TodayExperienceViewModel` (do not redesign Home). From there, Story type routes to `StoryDetailScreen(storyId)` without calling `BeginExperienceUseCase`. |
| **Story Detail displays** | Title; optional Hero display name; narrative body; authoritative “AVAILABLE FORMS”; primary CTA “Begin story” when a primary playable exists. Unavailable/non-discoverable → fail-closed “This story is not available.” |
| **Enter Story Experience** | Detail CTA pushes `StoryConsumeScreen(storyId, representationId)` using `primaryPlayable.representationId`. |
| **Representation/media selection** | Existing `PlayableRepresentationSelector` / Detail `primaryPlayable`: preferred language → original language → format priority (audio → video → written → …). Explicit `representationId` on consume session. |
| **Media unavailable** | Continue with representation text content, else Story narrative body. Do not invent narrative. Do not block Reflect solely because media failed. Seeker A/V player is **not** required for slice DoD (text-first remains authoritative experience). |
| **Exit Story** | AppBar back pops to previous screen (Detail → Experience → Home). No second navigation system. Mark complete does not auto-pop. |
| **Reach Reflection** | Explicit “Reflect on this story” on Consume → `StartStoryReflectionUseCase` → `ReflectScreen`. Requires current Journey; otherwise snackbar. |
| **After Reflection submit** | Existing Reflect submit: invalidate `todayExperienceProvider`; `popUntil(isFirst)` so Home recomposes Today. |
| **Today refresh** | Recompose via existing selection path; may change Story or fall back to reflection based on updated themes/patterns. |

### Discovery feel (not a feed)

The experience remains a **guided single Today opportunity**, not a browse feed, not a social timeline, and not engagement-ranked content.

---

## 5. Today Integration

### Do not redesign Today

Keep:

* Single “TODAY'S EXPERIENCE” card on `HomeScreen`
* `todayExperienceProvider` / `TodayExperienceViewModel`
* Intermediate `ExperienceScreen` for Story and reflection types
* Composer fail-closed reflection when no theme-overlapping Story candidate

### Slice A Today work (presentation only)

1. **Explainability label** — When `experienceType == story` and `rationale != null`, present a clear “Why this Story?” affordance using the **existing grounded rationale string**. Prefer labeling on `ExperienceScreen` and/or the Today card without inventing new selection logic.
2. **Optional sources surfacing** — Platform DTO already carries `explanationSources`, but `toAdaptiveExperience()` currently drops them. If sources are surfaced in this slice, map them through ViewModel with **no fabricated kinds**. If mapping is non-trivial, keep rationale-only and defer structured sources UI.
3. **Continuity** — Ensure Story-type CTA always carries a non-empty `storyTargetId` into Detail; keep existing snackbar when missing.
4. **Stubs** — Do **not** unstub Home Journey / Discover / Reflect secondary cards as part of this slice.

### Not Today’s job in this slice

* Candidate browsing lists
* Changing eligibility or ranker
* Theme analyzer improvements (TD-J2-002) — companion follow-on, not Slice A core
* Offline platform sync observability for owners

---

## 6. Story Detail

### Responsibility

Presentation of a discoverability-gated Story for a seeker who arrived from Today (or Heroes catalog — same screen).

### Reuse

* `storyExperienceProvider(storyId)`
* `GetStoryExperienceUseCase`
* `StoryExperienceViewModel` / `StoryExperienceMapper`
* Existing fail-closed copy: “This story is not available.”

### Slice A Detail work

| Item | Action |
|------|--------|
| Valid Today `storyTargetId` | Confirm Detail loads when Story exists locally and is discoverable |
| Missing / non-discoverable Story | Keep fail-closed; ensure messaging is clear when projection selected an id the local store cannot serve (same-device limitation — do not add platform content fetch) |
| Begin story disabled | When `primaryPlayable == null`, keep CTA disabled; do not invent a representation |
| No domain changes | Detail remains a pure consumer of experience UC |

### Explicitly not Detail’s job

* Playback
* Creating Reflections
* Writing candidates
* Ranking

---

## 7. Story Experience

### Responsibility

Ephemeral seeker consumption session for one Story + one selected representation.

### Reuse

* `BeginStoryExperienceUseCase`
* `ConsumeStoryExperienceUseCase`
* `ResolvePlayableRepresentationUseCase`
* `LoadStoryMediaUseCase`
* `StoryMediaStoragePort` (local / in-memory)
* `StartStoryReflectionUseCase` for optional Reflect

### Product shape (text-first)

1. Load session via Begin
2. Show title + format
3. Show representation text, else narrative body
4. If `hasMedia`, attempt `LoadStoryMediaUseCase`
5. Media success → optional meta / future audio reuse; media failure → silent degrade to text path
6. Mark complete → session flag only; **no** evidence, **no** domain events required for Slice A
7. Reflect CTA → existing workflow

### Slice A Experience work

| Item | Action |
|------|--------|
| Naming / feel | Replace generic “Consume” chrome with Story-oriented title (e.g. Story title or “Story Experience”) — presentation only |
| Media unavailable | Documented degrade to text/narrative; user-visible calm message only if Begin itself fails |
| Playback | **Do not require** seeker `just_audio` for DoD. Optional thin reuse of owner playback patterns for **audio-only** representations is allowed only if it stays presentation-local and does not invent remote media infrastructure |
| Video | Out of scope |
| Exit | Keep AppBar back; do not auto-navigate on complete |
| Evidence boundary | Preserve comments/docs that Begin/Consume never create evidence |

---

## 8. Navigation

### Current architecture (keep)

* `AppShell` `IndexedStack` tabs
* Imperative `Navigator.push(MaterialPageRoute(...))`
* No `go_router` route table

### Smallest route/state change

```text
HomeScreen
  → push ExperienceScreen(experience)
    → push StoryDetailScreen(storyId)          // Story type only
      → push StoryConsumeScreen(storyId, representationId)
        → push ReflectScreen(reflectionId)     // optional explicit
          → on submit: invalidate Today + popUntil(isFirst)
```

### Exit / return

| From | Back behavior |
|------|----------------|
| ExperienceScreen | Pop → Home |
| Story Detail | Pop → ExperienceScreen |
| Story Experience | Pop → Detail |
| Reflect (from Story) | Submit → pop to shell root; Cancel/back → previous (Consume) |

### Rules

* Do **not** introduce a second navigation architecture
* Do **not** add named deep links unless already present (they are not)
* Do **not** bypass `ExperienceScreen` for Story without a strong product reason (current HS.8 path is intentional)
* Story path must **never** call `BeginExperienceUseCase` (reflection-producing)

---

## 9. Reflection Integration

### Path

```text
StoryConsumeScreen “Reflect on this story”
  → StartStoryReflectionUseCase
       (GetStoryExperience proves discoverability;
        CreateReflectionUseCase creates Reflection;
        StoryId NOT stored on Reflection — HS.7)
  → ReflectScreen(reflectionId)
  → user submits responses
  → AnalyzeReflection / H.2 pipeline
  → BehavioralEvidence → Pattern detection → Journey patterns
  → todayExperienceProvider invalidate
  → Home Today refresh
```

### Slice A rules

* Reuse existing Reflection workflow only — **no** Story-specific reflection system
* Keep Reflect **optional and explicit**
* Do not auto-open Reflect after Mark complete
* Do not add `sourceStoryId` to Reflection in this slice (verification: by design)
* If Journey context is missing, keep existing snackbar fail-closed
* Smallest integration if anything is missing: ensure Consume → Reflect → submit → invalidate still works when entered from Today (tests), not new H.2 features

### Evidence boundary (non-negotiable)

Consuming a Story is **not** Behavioral Evidence. Only Reflection submit (and other explicit evidence-producing actions already in H.2) enters Behavioral Understanding.

---

## 10. Application Boundaries

### Presentation

| Surface | Responsibility |
|---------|----------------|
| Today candidate UI | Render selected experience; begin → ExperienceScreen |
| ExperienceScreen | Confirm context; route Story vs reflection correctly |
| Story Detail | Load/display discoverable Story; enter Experience |
| Story Experience | Begin/consume session UI; media degrade; Reflect CTA; exit via back |
| Navigation | Existing `Navigator` stack only |
| Loading / error / empty | Provider `AsyncValue` loading; Detail unavailable copy; Consume Begin failure message; Today provider error/stale already present |

### Application — reuse (preferred)

| Use case / service | Role |
|--------------------|------|
| `GetTodayExperienceUseCase` (platform/local) | Today selection |
| `AdaptiveExperienceComposer` | Story vs reflection composition |
| `GetStoryExperienceUseCase` | Detail payload |
| `BeginStoryExperienceUseCase` | Session start |
| `ConsumeStoryExperienceUseCase` | Mark complete |
| `ResolvePlayableRepresentationUseCase` | Representation resolve |
| `LoadStoryMediaUseCase` | Media bytes |
| `StartStoryReflectionUseCase` | Explicit Reflect bridge |
| `CreateReflectionUseCase` / Reflect submit path | H.2 entry |

### New application boundary?

**None required** for the minimum vertical slice.

Only propose a new UC if an unforeseen gap appears during implementation (e.g. a presentation-safe “resolve Today story target” helper). Prefer ViewModel / screen continuity over new orchestration services.

Do **not** create:

* `ExperienceStoryUseCase`
* Candidate aggregate services
* Personalized ranking services
* Story content sync use cases (Phase 7)

---

## 11. Domain Impact

### Verdict: **No domain changes required**

The current Story model already provides:

* Narrative, lifecycle, visibility
* Representations + `MediaReference`
* Discoverability policies
* Authoritative representation rules

Life Journey already provides Reflection + H.2 evidence/pattern path.

### Prefer

* Presentation polish
* Provider/ViewModel mapping for explainability (if sources are surfaced)
* Tests

### Avoid

* New Story fields for seeker UX
* Candidate aggregate
* Reflection↔Story foreign key
* New domain events solely for UI (`StoryCandidateProjected`, consume events, etc.)

If implementation discovers a true invariant gap, stop and escalate — do not silently expand domain scope.

---

## 12. Infrastructure Reuse

| Capability | Reuse |
|------------|-------|
| Story repository | Flutter `StoryRepository` (`File*` / `InMemory*`) |
| Hero repository | Flutter `HeroRepository` |
| Representation / media | `StoryRepresentation`, `MediaReference`, `StoryMediaStoragePort` |
| Playback | Owner `OwnedStoryPlaybackController` patterns only if optional audio polish is taken; no new media CDN |
| Local persistence | Existing file/in-memory adapters |
| Network | Existing `EhPlatformClient` for Today + candidate sync only |
| Candidate projection | Already productized (J.2 Slice 5) — do not rebuild |

### Do not create

* Platform Story narrative/read API
* Platform-wide Story synchronization for seekers
* Remote media delivery network
* New Postgres Story content tables under this slice

---

## 13. Failure States

Prefer graceful degradation over new infrastructure.

| Failure | Behavior |
|---------|----------|
| **Candidate disappears** (recompose returns reflection or different Story) | After return to Home / invalidate, show whatever Today recomposes. Do not cache fake Story detail. |
| **Story unavailable locally** | `GetStoryExperienceUseCase` fails → Detail shows “This story is not available.” Do not fetch platform narrative. |
| **Story representation unavailable** | No `primaryPlayable` → Begin story disabled; user can still leave via back. |
| **Media unavailable** | Load media fails or absent → continue with text/narrative; do not block Mark complete or Reflect. |
| **Playback failure** | If optional audio polish is present, fail closed to text path; no crash; no evidence side effects. |
| **Navigation failure** | Missing `storyTargetId` → snackbar on ExperienceScreen; stay put. |
| **Reflection unavailable** | Missing Journey → snackbar; StartStoryReflection failure → snackbar; Story become undiscoverable mid-flight → StartStoryReflection fails closed. |
| **Platform Today stale** | Existing stale banner on Today card remains valid. |

Cross-device seeker without local Story remains an **accepted fail-closed** outcome for this slice (see §18).

---

## 14. Test Strategy

Focused tests only for portions the architecture already supports. Prefer widget/application tests over broad redesign.

### Today

* Story-type experience Begin opens `ExperienceScreen`, then Story CTA opens `StoryDetailScreen` with expected `storyId`
* Rationale / “Why this Story?” visible when rationale present (once labeled)
* Does **not** call `BeginExperienceUseCase` for Story type (extend existing HS.8 routing test if needed)

### Story Detail

* Valid discoverable Story id resolves title/narrative/Begin story
* Missing / non-discoverable Story shows unavailable state (`story-unavailable`)

### Story Experience

* Begin loads session; text/narrative renders
* Media missing → text path still usable
* Mark complete does not invoke reflection/evidence UCs
* Exit via back returns to Detail
* Reflect CTA invokes `StartStoryReflectionUseCase` (mock/fake)

### Reflection

* Existing Reflect workflow invoked from Consume
* StoryId not required on Reflection aggregate (preserve current contract)
* Submit invalidates `todayExperienceProvider` (existing coverage may suffice — extend only if Today-origin path differs)

### Integration (supported portions)

```text
Today story experience
  → Detail (local Story present)
  → Consume
  → Reflect CTA
  → submit
  → Today invalidate
```

Do **not** invent tests that require platform Story content API.

Do **not** assert Behavioral Evidence from Mark complete.

Analyzer + focused suite green before claiming slice complete; broader Flutter suite as closing gate.

---

## 15. Implementation Sequence

Smallest coherent sequence. Stop after each step if an architecture decision appears.

1. **Lock fixtures** — Add/extend focused failing tests for Today → Detail continuity and Detail unavailable for a Today-selected id.
2. **Explainability UX** — Label existing rationale as “Why this Story?” on ExperienceScreen (and Today card if low-cost). Do not change composer ranking.
3. **Detail continuity check** — Confirm/adjust fail-closed messaging only; no domain changes.
4. **Experience presentation polish** — Story-oriented chrome; ensure media degrade path is clear; keep Begin/Consume evidence-free.
5. **Reflection path verification** — Consume → StartStoryReflection → Reflect → submit → Today invalidate; fix only wiring gaps.
6. **Optional audio polish (deferrable)** — Only if steps 1–5 are green and scope remains presentation-local.
7. **Analyze + focused tests + relevant broader suite**
8. **Docs touch** — Short pointer from Post–J.2 verification / phase notes that Slice A plan exists (no map rewrite).

### Exact first implementation step

**Write focused tests that prove a Today `adaptive-story-{id}` Begin path opens `StoryDetailScreen` for that id, and that a missing local Story shows the unavailable state — then make any presentation gaps fail those tests green.**

Do not start with Phase 7, new UCs, or playback infrastructure.

---

## 16. Definition of Done

1. From a Today `adaptive-story-{id}` experience, user can open Story Detail when the Story is present under current Flutter authority.
2. User can begin/consume the Story and mark complete **without** creating Behavioral Evidence.
3. Grounded “Why this Story?” (existing rationale) is visibly labeled; no fabricated explanation.
4. Unavailable Story content fails closed with clear UX (no fake narrative; no platform content fetch).
5. Media/representation gaps degrade to text/narrative without blocking exit or optional Reflect.
6. Explicit Reflect CTA remains available and uses existing Reflection + H.2 path; Today refreshes after submit.
7. Navigation remains the existing `Navigator` stack with clear back/exit behavior.
8. No Candidate aggregate; no Personalization Engine; no Phase 7 migration; no multi-device Story API.
9. No J.2 architecture reopen (eligibility/projection untouched unless defect-blocking).
10. `dart analyze` clean for touched code; focused Story+Today tests pass; relevant broader suite pass.
11. No unrelated cleanup / drift remediations.

---

## 17. Explicit Non-Goals

* Growth Opportunity Detection
* Personalization Engine
* ML ranking / engagement / popularity ranking
* Generalized recommendation framework
* Generalized adaptive-experience framework
* AI personalization of Story selection
* D.1 DiscoveryProfile platform productization
* Phase 7 Hero & Story migration
* Contribution context
* Social / community systems
* Marketplace / subscriptions
* Multi-device Story content API
* Platform-wide Story synchronization for seekers
* New Candidate aggregate
* Generalized Story content service
* Redesigning Today or Story aggregates
* Adding `sourceStoryId` to Reflection
* Unstubbing Home secondary cards
* Theme analyzer enrichment (companion follow-on)
* Video player / remote media CDN
* Reopening J.2

---

## 18. Deferred Multi-Device Capability

### Current limitation (accepted)

There is **no** platform Story narrative/content API. Today may select `adaptive-story-{id}` from the Postgres candidate projection while narrative/media remain in the Flutter `StoryRepository` / `StoryMediaStoragePort`.

### Same-device assumption

Slice A claims success when the seeker device that runs Today also holds the Flutter Story authority used by `GetStoryExperienceUseCase` (typical dual-stack demo / single-device path).

### Multi-device seeker path

**Explicitly deferred.** Cross-device experience requires a Phase 7 decision (platform Story content authority + sync/read), not silent scope inside Slice A.

### Slice A handling

When local Story is absent: fail closed with clear unavailable UX. Do not approximate with empty narrative, AI-generated content, or a half-built content API.

---

## 19. Documentation Updates

When Slice A is implemented (separate authorization), update only what this slice makes stale:

| Document | Update |
|----------|--------|
| `Post-J2-Slice5-Verification.md` | Add a one-line “Slice A plan / status” pointer when implemented |
| This plan | Mark status Implemented + link PR |
| `technical-debt.md` / drift | Only if Slice A closes a filed item; no broad cleanup |
| Architecture maps | Additive footnote at most — no LJ-centric map rewrite |

Do **not** rewrite HS.7/HS.8 historical plans, AGENTS.md HS.1 wording, or J.2 foundation as part of planning or implementation unless required for unambiguous Slice A status.

---

## Implementation Readiness Verdict

### 1. Is the existing architecture sufficient?

**Yes.** HS.7 experience UCs/screens, HS.8 Today Story routing, J.2 candidate projection → Today selection, and H.2 Reflection already compose the path. Slice A is continuity, explainability, fail-closed polish, and tests — not a new subsystem.

### 2. Which existing components should be reused?

* Today: `todayExperienceProvider`, `TodayExperienceViewModel`, `HomeScreen`, `ExperienceScreen`, `AdaptiveExperienceComposer`, platform/local `GetTodayExperienceUseCase`
* Story: `GetStoryExperienceUseCase`, `StoryDetailScreen`, `BeginStoryExperienceUseCase`, `ConsumeStoryExperienceUseCase`, `ResolvePlayableRepresentationUseCase`, `LoadStoryMediaUseCase`, `StoryConsumeScreen`, `PlayableRepresentationSelector`, `StoryRepository` / `HeroRepository`, `StoryMediaStoragePort`
* Reflection: `StartStoryReflectionUseCase`, `CreateReflectionUseCase`, `ReflectScreen`, Today invalidate on submit
* Navigation: existing `Navigator` + `MaterialPageRoute` stack

### 3. What is the smallest complete vertical slice?

```text
Today (adaptive-story-*)
  → ExperienceScreen (labeled Why this Story?)
  → Story Detail (fail-closed if local Story missing)
  → Story Experience (text-first consume; media degrade)
  → optional Reflect CTA
  → Reflection submit → H.2 → Today refresh
```

Presentation + tests under Flutter Story authority. No new domain. No platform Story content API.

### 4. Are domain changes required?

**No** — prefer none. Escalate if a true invariant gap appears.

### 5. What is the exact first implementation step?

**Add focused tests for Today `adaptive-story-*` → `StoryDetailScreen(storyId)` continuity and for Detail unavailable when the local Story cannot be served; then close only the presentation gaps those tests expose.**

### 6. What must remain explicitly deferred?

Multi-device / platform Story content API; Phase 7 HS migration; Candidate aggregate; Growth Opportunities; Personalization Engine; ML ranking; generalized recommendation/adaptive frameworks; AI personalization; D.1; Contribution; social/community; marketplace; subscriptions; Reflection↔Story foreign key; theme-analyzer enrichment as a substitute for this slice; reopening J.2.

---

**Planning readiness:** READY FOR IMPLEMENTATION after separate authorization.

**This document does not authorize code changes.**
