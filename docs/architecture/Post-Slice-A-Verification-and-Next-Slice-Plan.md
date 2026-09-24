# Post–Slice A Verification and Next Slice Plan

- **Document type:** Verification + next-slice plan (planning only)
- **Status:** Complete — **does not authorize implementation**
- **Baseline (code):** `main` @ `e9f383b` — Merge PR #68 (Story Discovery Experience Slice A)
- **Implementation commit:** `0f995d7` — presentation continuity + focused Slice A tests only
- **Predecessor plans:** `Story-Discovery-Experience-Plan.md` (PR #67), `Post-J2-Slice5-Verification.md` (PR #66)
- **Constraint:** Planning only. Do not modify application code under this document. Do not reopen J.2. Do not perform a broad architecture reassessment.

---

## 1. Purpose

Verify that PR #68 actually closes Story Discovery Experience Slice A against the live codebase, then identify the **smallest remaining adaptive gap** and the **smallest next vertical slice** that can prove updated understanding influences a subsequent Story experience — using architecture that already exists.

This document is evidence-based. Claims below were traced in code and tests on current `main`, not taken from the PR description alone.

---

## 2. Slice A Verification (PR #68)

### 2.1 What PR #68 changed

Diff is **five presentation/test files** (`0f995d7`):

| File | Change |
|------|--------|
| `home_screen.dart` | “Why this Story?” label when Today experience is story-typed |
| `experience_screen.dart` | Pass `discoveryRationale` into Detail; “Why this Story?” on Experience |
| `story_detail_screen.dart` | Accept/display `discoveryRationale` |
| `story_consume_screen.dart` | AppBar title → “Story Experience” |
| `story_discovery_experience_slice_a_test.dart` | 10 focused widget tests |

**Confirmed absent from PR #68:** new domain aggregates, new use cases, composer/ranker changes, H.2 changes, J.2 projection changes, Candidate aggregate, Story content API.

Slice A is **continuity and proof** over seams already present from HS.7 / HS.8 / H.2 / J.2 / UI.3.

### 2.2 End-to-end path verified

```text
Today
  ↓ todayExperienceProvider → GetTodayExperienceUseCase
adaptive-story-{storyId}
  ↓ AdaptiveExperienceComposer (theme overlap > 0)
matching local Story (Flutter authority)
  ↓ storyTargetId + existing grounded rationale
ExperienceScreen (“Why this Story?”)
  ↓ no BeginExperienceUseCase for story type
StoryDetailScreen(discoveryRationale)
  ↓ Begin story (disabled if no primaryPlayable)
StoryConsumeScreen (“Story Experience”)
  ↓ text-first (representation text → narrative body)
  ↓ media optional (failure does not block)
  ↓ Mark complete → ephemeral session only
optional explicit Reflect
  ↓ StartStoryReflectionUseCase → ReflectScreen
ReflectionSubmitted
  ↓ EventBus → (local) ReflectionSubmittedReactor → AnalyzeReflection…
  ↓ BehavioralEvidenceDetected → DetectPatternUseCase → Journey patterns
Today invalidate
  ↓ ref.invalidate(todayExperienceProvider) + popUntil(isFirst)
Home recomposes Today
```

### 2.3 Checklist (code + Slice A tests)

| Concern | Status | Evidence |
|---------|--------|----------|
| Today candidate identity (`adaptive-story-*`) | **Verified** | `AdaptiveExperienceComposer` emits `adaptive-story-${top.storyId}`; VM/`storyTargetId` propagate |
| Existing rationale propagation | **Verified** | Composer `buildRationale` → Today → Experience → Detail `discoveryRationale`; “Why this Story?” on all three |
| Story target resolution | **Verified** | `StoryExperienceTarget` → `storyTargetId`; empty target → snackbar, stay on Experience |
| Story Detail behavior | **Verified** | `GetStoryExperienceUseCase` discoverability-gated; unavailable → `story-unavailable` |
| Text-first consumption | **Verified** | Prefer representation `textContent`, else narrative; Slice A written-form test |
| Media-optional | **Verified** | Missing media → no block; complete + Reflect still available |
| Completion behavior | **Verified** | `ConsumeStoryExperienceUseCase` marks session complete; no events/evidence |
| Explicit Reflection | **Verified** | CTA only; `StartStoryReflectionUseCase`; requires Journey |
| Reflection → H.2 entry | **Verified** | Submit publishes `ReflectionSubmitted`; reactors registered when not platform authority |
| Today invalidation/refresh | **Verified** | `ReflectScreen` invalidates `todayExperienceProvider`; Slice A asserts `todayBuilds > 1` |
| Fail-closed | **Verified** | Missing target; missing local Story; incomplete content (Begin disabled); no Journey |
| Existing Journey requirement | **Verified** | Reflect without current Journey → snackbar; no ReflectScreen |
| Story consume ≠ Behavioral Evidence | **Verified** | Complete path: no Reflection / no `ReflectionSubmitted` / no `BehavioralEvidenceDetected`; reflection repo empty |

### 2.4 Evidence boundary (preserved)

```text
Story view / begin / consume / complete
        ≠ Behavioral Evidence

Explicit Reflection submit
        → ReflectionSubmitted
        → (analysis) Behavioral Evidence + Narrative Themes
        → Pattern detection
        → Journey.behaviorPatterns
```

PR #68 does **not** weaken this boundary. Slice A tests assert consume produces no evidence events; explicit Reflect creates a Reflection and submits it without inventing evidence from consume.

### 2.5 Slice A test scope (important)

Focused Slice A tests (`story_discovery_experience_slice_a_test.dart`) **override** `todayExperienceProvider` with a fixed ViewModel. They prove **UI continuity / fail-closed / evidence boundary / invalidate**, not live composer selection or full H.2 analysis → new Story identity.

Live selection remains covered by earlier suites (`hs8_*`, `adaptive_experience_composer_test`, platform `j2_*`, UI.3 pipeline for reflection experiences).

### 2.6 Slice A verdict

**PR #68 completes Story Discovery Experience Slice A** as intended:

* Seeker can go from Today’s `adaptive-story-*` through Detail and text-first Story Experience.
* Optional explicit Reflection enters H.2 and refreshes Today.
* No architecture deviation; no domain expansion.

---

## 3. Remaining Adaptive Gap

### 3.1 The question

> After an explicit Reflection updates H.2, does the updated understanding actually have a **meaningful** path to influence the **next Story** experience?

### 3.2 Traced path (current `main`)

```text
ReflectionSubmitted
  ↓ InMemoryEventBus → dispatcher (awaits reactors)
AnalyzeReflectionUseCase
  ↓ insights + BehavioralEvidence + NarrativeThemeResolver.resolveThemes
  ↓ BehavioralEvidenceDetected
DetectPatternUseCase
  ↓ Journey.updateBehaviorPatterns() → BehaviorPatternsDetected
ReflectScreen invalidates todayExperienceProvider
  ↓
GetTodayExperienceUseCase
  ↓ ResolveAdaptiveDiscoverySignalsUseCase
       themes = ∪ Reflection.narrativeThemes
       patterns = Journey.behaviorPatterns
  ↓ DiscoverableStoryCandidatePort.findRelevant(signals)
  ↓ DeterministicStoryRelevanceRanker
  ↓ AdaptiveExperienceComposer
       themeOverlapCount > 0 → adaptive-story-*
       else → DeterministicExperienceSelectionService (reflection)
  ↓
Today card / Story Experience (unchanged Slice A path)
```

### 3.3 Already implemented

| Capability | Status |
|------------|--------|
| H.2 analysis + pattern pipeline (local + platform authority modes) | **Done** |
| Today refresh after Reflect submit | **Done** |
| AdaptiveDiscoverySignals (themes ∪ patterns) | **Done** |
| Discover* / candidate port + deterministic ranker + composer | **Done** |
| Theme-overlap gate for Story vs reflection fallback | **Done** |
| Pattern-aware **rationale** copy when patterns exist | **Done** |
| UI.3 Slice 4 for **reflection** Today (`default-reflection` → `consistency-next-step`) | **Done** (no Story candidates wired in that test) |
| HS.8 proof: **manually** changing reflection themes changes Story A → Story B | **Done** (integration; themes planted, not via production resolver) |
| Slice A Story Experience continuity | **Done** |

### 3.4 Partially implemented

| Seam | What exists | What is incomplete |
|------|-------------|-------------------|
| Patterns → Story ranking | `patternBoost` field + secondary sort key | Boost is computed **once from signals** and applied **identically** to every candidate → **cannot change relative Story order** |
| Themes → Story identity | Ranker primary key is theme overlap; HS.8 proves mechanism | Production `CatalogAlignedNarrativeThemeResolver` **always emits** catalog `discovery` only — no content-dependent variety |
| Dual-stack signals | Platform `CatalogAlignedAdaptiveDiscoverySignalResolver` + Flutter `DefaultResolveAdaptiveDiscoverySignalsUseCase` | Flutter lacks platform’s `NarrativeThemeAlignment` filter (known DRIFT); both stacks still feed constant analyzer themes |
| End-to-end Story adaptation | Full chain of ports exists | **No** integration test: Reflection submit → analysis → **different** `adaptive-story-*` |

### 3.5 Not implemented (and not required for the next slice)

* Growth Opportunity Detection
* Discovery Profile synthesis / D.1 productization
* Personalization Engine / ML ranking / AI personalization
* Candidate aggregate
* Platform Story narrative / multi-device content API
* Per-Story pattern affinity model
* New events beyond existing H.2 / UI.3 set

### 3.6 Critical finding (do not assume H.2 ⇒ adaptive Story)

**H.2 updating Journey patterns does not, by itself, change which Story Today selects.**

Reasons, from code:

1. **Eligibility is theme-gated.** `DiscoverStoriesCandidateAdapter`: `if (!signals.hasThemes) return []`. Patterns alone never invent Story matches.
2. **Composer hard-requires `themeOverlapCount > 0`.** Otherwise UI.3 reflection selection runs (where patterns *do* matter — `consistency-next-step`).
3. **`patternBoost` is uniform** across candidates for a given signal set (`DeterministicStoryRelevanceRanker._patternBoost(signals)`), so secondary sort never reorders Stories relative to each other.
4. **Theme analyzer is constant.** Both Flutter and platform `CatalogAlignedNarrativeThemeResolver.resolveThemes` return `[NarrativeThemeReferenceIds.discovery]` for every reflection. After the first analyzed reflection, the theme union is stably `{discovery}`; further Reflections do not diversify Story overlap under production wiring.

**What Reflection → H.2 → Today refresh *does* change today for Story experiences:**

* Rationale may gain “patterns of {consistency|…}” wording once patterns exist.
* If **no** overlapping Story candidates exist, Today may switch to a pattern-based **reflection** experience (UI.3 Slice 4).
* The Today card **rebuilds** (same Story id is the common case when `discovery`-tagged Stories remain available).

**What it does *not* currently prove:**

```text
Updated understanding → different / newly relevant adaptive-story-* → new Story Experience
```

That is the remaining adaptive gap for Stories.

---

## 4. UI.3 Reference vs Smallest Next Slice

UI.3 incremental model:

| Slice | Intent | Story-specific status after PR #68 |
|-------|--------|--------------------------------------|
| 1 | Pattern → deterministic Today | Story uses HS.8 composer; reflection fallback is UI.3 |
| 2 | Today → Action → Reflection | **Complete** for Story (Slice A) |
| 3 | Reflection → Evidence → Patterns | **Complete** (H.2) |
| 4 | Updated understanding → new Today experience | **Proven for reflection experiences**; **not proven for Story candidate identity** |

A naïve “do UI.3 Slice 4 for Stories” without addressing signal thinness would authorize work that **cannot produce an observable Story-id change** under current production theme resolution.

**Therefore the smallest useful next capability is not “rewire Today” (already wired).**  
It is the **missing signal seam** that makes the existing Story selection path able to express differentiated understanding:

```text
Explicit Reflection (content varies)
  ↓
Deterministic, catalog-aligned theme resolution (content-aware)
  ↓
AdaptiveDiscoverySignals.narrativeThemeIds diversify
  ↓
DeterministicStoryRelevanceRanker / composer select a different Story
  ↓
Today shows a new adaptive-story-*
  ↓
Existing Slice A Story Experience path
```

This is Post–J.2 Candidate D enabled by TD-J2-002 / Candidate C “signal quality,” **not** a new Personalization Engine.

If content-aware theme resolution were rejected as out of scope, the next-smallest alternative would be a micro-fix to make patterns affect **relative** Story ranking — but Stories have **no pattern-type affinity** in the model today; inventing one would be a larger design than improving the existing theme port. **Prefer themes.**

---

## 5. Scope Guardrails

The next slice must **not** become:

* Growth Opportunity Detection
* Generalized Discovery Profile synthesis / D.1 productization
* Personalization Engine
* ML ranking / recommendation engine
* AI personalization
* Generalized adaptive framework
* Candidate aggregate
* Generalized Story content service
* Multi-device Story content API / platform Story narrative read
* Platform-wide Story synchronization redesign
* Phase 7
* Contribution / social / community
* Marketplace / subscriptions
* Reopening J.2 eligibility/projection work

Goal: prove the smallest remaining adaptive behavior with architecture that already exists.

---

## 6. Implementation Trace (reuse inventory)

### 6.1 Today

| Component | Path | Role |
|-----------|------|------|
| `adaptive-story-*` id | `AdaptiveExperienceComposer` (Flutter + platform mirror) | Candidate identity |
| Local Today UC | `DefaultGetTodayExperienceUseCase` | Signals → port → compose |
| Platform Today UC | `PlatformGetTodayExperienceUseCase` / platform Experience service | Dual-stack read |
| Providers | `todayExperienceProvider`, `getTodayExperienceUseCaseProvider` | Presentation |
| Rationale | `AdaptiveExperienceComposer.buildRationale` | Explainability string |
| Target | `StoryExperienceTarget` → `storyTargetId` | Continuity into Detail |

### 6.2 H.2

| Component | Role |
|-----------|------|
| `DefaultSubmitReflectionUseCase` / `PlatformSubmitReflectionUseCase` | Publish / platform authority |
| `ReflectionSubmittedReactor` → `AnalyzeReflectionUseCase` | Themes + evidence |
| `BehavioralEvidenceDetectedReactor` → `DetectPatternUseCase` | Journey patterns |
| `ReflectScreen` invalidate | Today refresh (no dedicated BehaviorPatternsDetected→Today reactor) |

### 6.3 Story

| Component | Role |
|-----------|------|
| Story classification `narrativeThemeIds` | Catalog overlap source |
| Discover* / J.2 projection | Candidate set |
| `DeterministicStoryRelevanceRanker` | Deterministic ordering |
| Detail / Consume / StartStoryReflection | Unchanged Slice A experience |

### 6.4 Application boundary for the next slice

**Primary seam to change:** `NarrativeThemeResolver` implementations:

* `lib/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart`
* `services/eh_platform/.../catalog_aligned_narrative_theme_resolver.dart`

**Keep unchanged:** composer API, ranker contract, Discover* port, Story Experience UI, H.2 reactor registration, evidence boundary, J.2 projection schema.

**Optional companion (defer unless blocking):** Flutter signal-side `NarrativeThemeAlignment` parity with platform (DRIFT) — only if non-catalog IDs appear in tests/fixtures.

### 6.5 Existing tests that already prove portions

| Test | Proves |
|------|--------|
| `story_discovery_experience_slice_a_test.dart` | Continuity, fail-closed, consume≠evidence, Reflect→invalidate |
| `hs8_adaptive_hero_discovery_pipeline_test.dart` | Theme union change → Story A→B (manual themes) |
| `ui3_adaptive_experience_pipeline_test.dart` | Patterns → reflection Today id change |
| `behavior_pattern_detection_pipeline_test.dart` / `reflection_analysis_pipeline_test.dart` | H.2 internals |
| `adaptive_experience_composer_test.dart` / ranker / adapter tests | Selection rules |
| `catalog_aligned_narrative_theme_resolver_test.dart` | Always-`discovery` (current contract) |

**Smallest missing integration test:**

```text
Reflection content (or resolver output) that yields theme B
  ↓ AnalyzeReflectionUseCase (real resolver)
  ↓ AdaptiveDiscoverySignals include B
  ↓ GetTodayExperienceUseCase
  ↓ adaptive-story-{storyB} (≠ prior storyA)
```

Optionally extend one step further with ReflectScreen invalidate, but application-level Today UC proof is sufficient for the adaptive claim.

---

## 7. Smallest Next Vertical Slice

### Name

**Slice B — Differentiated Story Selection from Updated Understanding**  
(working title; authorization separate)

### Intent

Prove:

```text
Explicit Reflection
  ↓
H.2 updates understanding (themes via existing analysis path)
  ↓
Today recomposes
  ↓
Story selection consumes diversified theme signals
  ↓
adaptive-story-* changes (or becomes newly eligible)
  ↓
User enters the same Slice A Story Experience flow
```

Deterministic and explainable. **Not** intelligent personalization.

### Why this is the smallest useful slice

* Composer / Today / Story Experience / H.2 reactors already exist.
* The binding constraint is **constant theme emission**, already documented as TD-J2-002 / Post–J.2 signal-quality follow-on.
* Fixing that seam unlocks the HS.8 mechanism for production Reflections without new aggregates or ranking frameworks.
* A “selection wiring” slice alone would not change observable Story identity.

### Product behavior (concrete, code-supported)

Assumptions (must be true in fixtures / seeded data):

* Two discoverable Stories with **distinct catalog** theme sets (e.g. Story A: `courage`; Story B: `perseverance`), both otherwise eligible.
* Deterministic theme resolver maps reflection response content to catalog themes (not always-only `discovery`). Exact keyword/rule table is an implementation detail of the slice; it must be **deterministic, catalog-bounded, and tested** — no AI required.

Observable journey:

1. User’s Today shows Story A (`adaptive-story-{A}`) under initial understanding.
2. User consumes Story A (no evidence).
3. User explicitly Reflects and submits content that resolves to theme(s) favoring Story B.
4. H.2 analyzes: themes added on Reflection; evidence/patterns may also update.
5. Today invalidates and recomposes.
6. Selection yields Story B (`adaptive-story-{B}` ≠ A) **or** Story B newly appears where only reflection fallback existed.
7. User can open Detail → Story Experience unchanged from Slice A.
8. Rationale remains grounded in matched themes/patterns (existing composer strings).

**Do not invent** pattern→Story semantics the code does not have. Observable proof is **theme-driven Story identity change** (primary), with optional assertion that rationale may mention patterns when present (secondary, already implemented).

### Evidence boundary (unchanged)

```text
Story viewing / completion ≠ Behavioral Evidence
Explicit Reflection → Behavioral Evidence → H.2
```

Consume must still not create evidence. Theme resolution remains part of **Reflection analysis**, not consume.

---

## 8. Architecture Impact

| Layer | Change required? | Notes |
|-------|------------------|-------|
| Domain aggregates / invariants | **No** | `NarrativeThemeResolver` port already exists |
| Domain events | **No** | Reuse `ReflectionSubmitted`, `NarrativeThemesAdded`, `BehavioralEvidenceDetected`, `BehaviorPatternsDetected` |
| Application Today / composer / ranker | **No** (preferred) | Already consume diversified themes |
| Discovery application theme resolver | **Yes** | Replace always-`discovery` with deterministic content-aware catalog mapping; keep catalog-only IDs |
| Platform mirror resolver | **Yes** (parity) | Same deterministic rules as Flutter |
| H.2 reactors / pattern rules | **No** | Unchanged |
| Story classification / eligibility / J.2 projection | **No** | Stories already carry theme IDs |
| Today providers / Slice A UI | **No** | Invalidate + Experience path reuse |
| Infrastructure vendors / AI | **No** | Explicitly out of scope |

**Remain unchanged by design:** Story Experience screens, evidence boundary, fail-closed Detail, single Today card, no Candidate aggregate.

---

## 9. Testing Strategy

### 9.1 Minimum new coverage

1. **Resolver unit tests** — Given reflection responses, emit deterministic catalog theme sets; never emit non-catalog IDs; identical input → identical output.
2. **Integration (primary DoD test)** — Seed Stories A/B with distinct themes; run analyze (or full submit+reactor) with content mapping to B; `GetTodayExperienceUseCase` returns `adaptive-story-{B}` after prior A (or after reflection-only Today).
3. **Selection consumes updated state** — Assert Today UC / signals after analysis differ from pre-analysis (theme list membership), not a hard-coded experience id in the test double.

### 9.2 Regression

* Slice A continuity suite still passes.
* HS.8 / composer / ranker suites still pass.
* Consume still produces no `BehavioralEvidenceDetected`.
* Unavailable Story still fail-closed.
* Text-first + media-optional still valid.
* UI.3 reflection Today (`consistency-next-step`) still works when no Story overlap.
* Always-catalog-valid theme IDs preserved.

Do **not** prescribe tests for pattern-driven Story reordering until/unless a future slice introduces per-candidate pattern affinity (not recommended now).

---

## 10. Implementation Sequence

1. Add the **smallest failing integration test** proving updated understanding (via diversified themes from analysis) changes Story selection identity.
2. Trace the failure to `CatalogAlignedNarrativeThemeResolver` (always-`discovery`).
3. Implement deterministic content-aware mapping against `NarrativeThemeReferenceIds` (Flutter + platform parity).
4. Keep composer, ranker, Discover*, Story Experience, and H.2 reactors unchanged.
5. Add resolver unit coverage; update any tests that encoded always-`discovery` as the sole contract.
6. Verify Slice A Story Experience and evidence boundary unchanged.
7. Run focused suites (resolver, HS.8, Slice A, H.2/reflection analysis, Today adaptive).
8. Run full Flutter validation + platform tests touching the resolver.

---

## 11. Definition of Done

The next slice is **not** complete merely because Today refreshes.

Complete when:

1. **Behavior:** After an explicit Reflection is analyzed, Adaptive Discovery Signals can include catalog themes beyond the prior always-`discovery`-only union in a content-deterministic way.
2. **Selection:** `GetTodayExperienceUseCase` (local path at minimum) can return a **different** `adaptive-story-*` id solely because understanding themes changed — demonstrated by a passing integration test with seeded Stories.
3. **Experience:** The new candidate still uses the Slice A Detail → text-first Consume → optional Reflect path.
4. **Boundary:** Story consume still creates no Behavioral Evidence.
5. **Architecture:** No new aggregates, no Personalization/ML/AI, no J.2 reopen, no Story content API.
6. **Quality:** Analyzer clean on touched files; focused + relevant full suites green.
7. **Explainability:** Rationale remains grounded in actual matched themes/patterns (existing composer).

---

## 12. Explicit Non-Goals

The next slice does **not** implement:

* Growth Opportunity Detection
* Full Discovery Profile synthesis
* Personalization Engine
* ML
* AI personalization
* Generalized recommendation infrastructure
* Candidate aggregate
* Generalized Story content service
* Multi-device Story API
* Platform-wide Story synchronization redesign
* Phase 7
* Contribution / community / social
* Marketplace
* Subscriptions
* J.2 reopening

Also deferred (related but not this slice):

* Structured `explanationSources` UI beyond rationale string
* Making `patternBoost` per-candidate / pattern–Story affinity
* Flutter `NarrativeThemeAlignment` parity (unless required for the DoD test)
* Stronger post-Story reflection prompts (Post–J.2 Candidate B uptake UX)

---

## 13. Final Readiness Verdict

1. **What did PR #68 prove?**  
   The seeker Story Discovery Experience from Today’s `adaptive-story-*` through Detail, text-first Consume, optional Reflect, `ReflectionSubmitted`, and Today refresh — with fail-closed behavior and consume≠evidence — without domain expansion.

2. **What adaptive capability remains unproven?**  
   That updated understanding after Reflection can change the **next Story candidate identity** (`adaptive-story-*`). Today refresh and H.2 pattern updates are real; Story identity adaptation is blocked by constant theme emission and non-differentiating patternBoost.

3. **Is the existing architecture sufficient?**  
   **Yes**, for a narrow slice: improve `NarrativeThemeResolver` implementations and prove selection through existing HS.8 / Today seams. No new selection engine required.

4. **What is the smallest next vertical slice?**  
   **Differentiated Story Selection from Updated Understanding** — deterministic content-aware catalog theme resolution → diversified AdaptiveDiscoverySignals → existing ranker/composer → new Story Today card → reuse Slice A experience.

5. **What existing components will be reused?**  
   H.2 analysis/reactors, `ResolveAdaptiveDiscoverySignalsUseCase` / platform signal port, Discover* / candidate projection, `DeterministicStoryRelevanceRanker`, `AdaptiveExperienceComposer`, Today providers, Slice A Detail/Consume/Reflect path.

6. **What, if anything, must change in the domain?**  
   **Nothing** in aggregates/events. Only Discovery application resolver behavior behind the existing port (dual-stack parity).

7. **What is the exact first implementation step?**  
   Add a failing integration test: analyzed Reflection themes diversify → `GetTodayExperienceUseCase` selects a different `adaptive-story-*` than before.

8. **What remains explicitly deferred?**  
   All §12 non-goals; pattern–Story affinity; structured explanation sources UI; multi-device Story content; D.1; Phase 7; J.2 reopen.

---

## 14. Recommendation

**Authorize (separately) Slice B: Differentiated Story Selection from Updated Understanding**, scoped to deterministic catalog theme resolution + one integration proof that Reflection → H.2 themes → Today Story identity can change.

Do **not** reopen J.2.  
Do **not** treat UI.3 Slice 4 as a copy-paste mandate for Stories without fixing the signal seam.  
Do **not** implement application code from this document alone.

---

*Verification baseline: `main` @ `e9f383b` (PR #68). Planning only.*
