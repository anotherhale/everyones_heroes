# Post-FG Integration Checkpoint — Hero & Story End-to-End Audit

**Status:** COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/hs-post-fg-integration-checkpoint-e2c6`  
**Baseline:** `main` @ `9139f2a` (SB.13 ✓, HS.FG.1 ✓, HS.FG.2 ✓)  
**Nature:** Inspection and verification only — no production feature implementation.

**Companion docs:**
- `docs/analysis/HS-architecture-checkpoint.md`
- `docs/analysis/HS-FG-1-owner-publish-path.md`
- `docs/analysis/HS-FG-2-theme-discovery-bridge.md`
- `docs/architecture/Hero and Story Platform Implementation Master Plan.md`

---

## 1. Executive Summary

After SB.13, HS.FG.1, and HS.FG.2, a Hero can create a Story through the Builder, approve a proposal, materialize a **canonical draft `Story`**, classify it with Discovery `NarrativeThemeId`s, and walk Submit → Approve → Publish on Owned Story Detail.

Discovery eligibility for the Story itself is correct:

```text
draft / processing / review / approved  → not discoverable
published + {public, community} + non-provisional  → Story-eligible
```

Theme filtering works at the application layer (`DiscoverStoriesRequest.narrativeThemeIds`, `BrowseStoriesByCatalogUseCase`).

**The closed product loop is still broken for the default local owner:** bootstrap creates `HeroVisibility.private`, and `DiscoverStoriesUseCase` also requires `HeroDiscoverabilityPolicy`. FG.1/FG.2 integration tests seed a **public** Hero, so they pass while the real owner path cannot surface a published Story in Browse Stories / Heroes.

```text
Now working (application + owner UI, given a discoverable Hero):
  Builder → Proposal → Approve → Materialize → Classify →
  Submit → Approve → Publish → DiscoverStories

Broken for default local owner:
  Publish succeeds → Story remains invisible in seeker Discovery
  because Hero stays private and no owner composition changes Hero visibility
```

**No production feature code was changed in this checkpoint.**

---

## 2. Verified Story Lifecycle

```text
StoryBuilderSession
        ↓  Start / intent / prompts / complete
StoryProposal (build / shape)
        ↓  Hero review (edit / reject / revise / approve)
StoryProposal[accepted]
        ↓  MaterializeStoryProposalUseCase (SB.13)
Story[draft]  ← CANONICAL
        ↓  ClassifyStoryUseCase + Theme bridge (HS.FG.2)
Story.classification.narrativeThemeIds
        ↓  Continue to Story → OwnedStoryDetailScreen
Submit → processing (owner label: Submitted)
        ↓
Approve → review → approved  (ApproveStoryUseCase collapses when needed)
        ↓
Publish (+ consent + public visibility when needed)
        ↓
DiscoverStoriesUseCase  (Story + Hero eligibility)
```

### Stage table

| Stage | Existing implementation | Persistence | Verified? |
|-------|-------------------------|-------------|-----------|
| Story Builder | `StoryBuilderSession`, session use cases, `StoryBuilderController` / screens | `StoryBuilderSessionRepository` (file + in-memory) | Yes |
| Story Proposal | `BuildStoryProposalUseCase`, `ShapeStoryProposalUseCase`, `StoryProposal` | `StoryProposalRepository` | Yes |
| Proposal approval | `ApproveStoryProposalUseCase` (+ edit/reject/revise) | Proposal repo | Yes |
| Materialization | `MaterializeStoryProposalUseCase`, `StoryMaterializationMapper`, `CreateStoryUseCase` | `StoryRepository` + proposal link | Yes |
| Story creation | `Story.create` → lifecycle `draft`, visibility `draft` | Story repo | Yes |
| Classification | `StoryBuilderThemeNarrativeThemeBridge` → `ClassifyStoryUseCase` at materialize | Story classification VO | Yes |
| Owner navigation | “Continue to Story” → `OwnedStoryDetailScreen` (`pushReplacement`) | N/A (nav) | Yes |
| Submission | `SubmitStoryUseCase` / `Story.submit` (consent granted in UI if needed) | Story repo | Yes |
| Approval | `ApproveStoryUseCase` / `markReadyForReview` + `approve` | Story repo | Yes |
| Publication | `PublishStoryUseCase` / `Story.publish` (+ visibility upgrade) | Story repo | Yes |
| Visibility | `StoryVisibility`; publish rejects private/draft; FG.1 sets `public` when needed | On Story | Yes |
| Discovery retrieval | `DiscoverStoriesUseCase` + `StoryDiscoverabilityPolicy` + **Hero** policy | Live filter via `StorySearchPort` | Yes* |
| Theme filtering | Request/query filters + browse-by-catalog use case | Same search path | Yes (app); UI unwired |

\*Story eligibility verified. Full seeker visibility for the **default local Hero** is blocked by Hero privacy (see §5).

### Actual lifecycle terminology (code)

`StoryLifecycleStatus`:

```text
draft → processing → review → approved → published
(+ archived | rejected | suspended | removed)
```

Owner-facing labels map `processing` → “Submitted”.

### Canonicality after SB.13

| Check | Result |
|-------|--------|
| `Story` is the published artifact | **Pass** — only `Story.publish` |
| `StoryProposal` is not published content | **Pass** — separate proposal lifecycle |
| `StoryBuilderSession` is not published content | **Pass** — Builder statuses only |
| AI is not authoritative | **Pass** — derived proposal content; Hero approval required; AI reps need approve |
| Provenance preserved | **Pass** — `materializedFromProposalId`, `sourceSessionId`, derivation flags |
| Materialization = transition into canonical Story | **Pass** — explicit SB.13 boundary |

No model redesign performed.

---

## 3. Cross-Context Boundaries

```text
Hero & Story
  owns: Hero, Story, Builder session, Proposal, classification refs,
        lifecycle, visibility, provenance, representations, Discover* ports
  does not own: NarrativeTheme entity, personalization, BehavioralEvidence

Discovery
  owns: NarrativeTheme (+ reference catalog seed for Builder overlap)
  referenced by: Story.classification.narrativeThemeIds (IDs only)

Life Journey
  owns: adaptive experience selection / Today’s Experience
  consumes: DiscoverStories candidates via HS.8 adapter (separate from catalog UI)
```

Interactions verified:

- Theme bridge uses shared-kernel `NarrativeThemeReferenceIds` — no Hero & Story → Discovery domain import for mapping.
- Begin/Consume/Load media do **not** create BehavioralEvidence.
- Optional reflection bridge is explicit (`StartStoryReflectionUseCase`).
- Catalog/Discover do not personalize; adaptive ranking lives in Life Journey (HS.8), not inside Hero & Story Discover UI.

---

## 4. Capability Matrix

| Capability | Status | Evidence |
| ---------- | ------ | -------- |
| Story Builder | Implemented | Session aggregate, use cases, durable repo, UI (`StoryBuilderScreen`) |
| Story Proposal | Implemented | Build/shape/edit/approve/reject; proposal repo; SB.12 review UI |
| Story Materialization | Implemented | `MaterializeStoryProposalUseCase`; SB.13 tests/report |
| Story Classification | Partially implemented | Themes from FG.2 at materialize; other dims (subjects/challenges/suitability/spirituality) not filled by Builder path; HS.4 Understanding apply unwired |
| Owner Publication | Implemented | Owned detail Submit/Approve/Publish + consent; FG.1 integration/UI tests |
| Story Discovery | Implemented | `DiscoverStoriesUseCase` + `StoryCatalogScreen`; eligibility policy |
| Theme Filtering | Partially implemented | App-layer filters + browse use case + FG.2 integration; **catalog UI passes empty request** |
| Hero Discovery | Implemented | `DiscoverHeroesUseCase` + `HeroCatalogScreen` + policy |
| Story Playback | Partially implemented | Owner `just_audio` playback; seeker consume shows media byte length only |
| Hero Profiles | Implemented | `GetHeroExperienceUseCase` + `HeroProfileScreen` |
| Collections | Missing | Deferred (HS-ADR-053); no collection types |

### HS.6 roadmap capabilities (verified)

| Capability | Status |
| ---------- | ------ |
| Search | Partially implemented — use cases + in-memory ports; no seeker search UI; no production engine |
| Structured filtering | Partially implemented — full filter model; no filter UI |
| Hero discovery | Implemented |
| Story discovery | Implemented |
| Catalog browsing | Partially implemented — `BrowseStoriesByCatalogUseCase` exists; UI is flat Discover list |

### HS.7 roadmap capabilities (verified)

| Capability | Status |
| ---------- | ------ |
| Hero profiles | Implemented |
| Story browsing | Partially implemented — flat lists; no dimension browse UX |
| Story playback | Partially implemented — seeker audio play incomplete |
| Hero journeys | Missing — deferred HS-ADR-053 |
| Collections | Missing — deferred HS-ADR-053 |

---

## 5. Remaining Composition Gaps

Only gaps newly visible because SB.13 + FG.1 + FG.2 are complete:

1. **Default local Hero blocks seeker Discovery after Publish**  
   `ensureActiveLocalHeroProvider` creates `HeroVisibility.private`.  
   `DiscoverStoriesUseCase` drops Stories whose Hero fails `HeroDiscoverabilityPolicy`.  
   There is **no** `ChangeHeroVisibility` use case, provider, or owner UI.  
   `UpdateHeroProfileUseCase` updates profile fields only.  
   FG.1/FG.2 tests seed public Heroes — masking the owner loop failure.

2. **FG.2 theme IDs unused by seeker presentation**  
   Themes populate classification and Discover can filter; `StoryCatalogScreen` always calls `DiscoverStoriesRequest()` with no themes / never invokes browse-by-catalog.

3. **Owner finishes at “Published” with no seeker handoff**  
   Published note cites eligibility; no CTA to Story Detail / Catalog; publish success does not invalidate `discoverableStoriesProvider`.

4. **Seeker media load ≠ playback**  
   Consume path loads bytes; UI shows “Media available (N bytes)” without audio play (owner path already plays).

### Explicitly not selected as “the” next gap

- Durable Story Understanding (former Master Plan FG.3) — real, but not the closed-loop break exposed by FG.1/FG.2 completion.
- Search/browse UI redesign — valuable, but meaningless while default published Stories stay invisible.
- Seeker playback — polish after Stories can appear in Discovery.

### Documentation drift noted

Master Plan §6/§10 still stated HS.5 “publish composition missing”, HS.8 “Builder themes not mapped”, and “next = Durable Story Understanding.” Code + FG.1/FG.2 reports supersede those items. This checkpoint revises the next slice accordingly.

---

## 6. Next Slice

### HS.FG.3 — Owner Hero Discoverability Composition

**Why it is next**

FG.1 completed Story publish. The remaining break in the owner → Discovery loop is **Hero discoverability composition**, not another Story lifecycle step and not theme UI. Without it, a Hero can publish and still see an empty Stories catalog for the default local bootstrap Hero.

**What it composes**

- Existing `Hero.changeVisibility`
- Existing `HeroDiscoverabilityPolicy` / `HeroRepository`
- Existing FG.1 Owned Story Detail / publish flow
- Existing `DiscoverStoriesUseCase` / `StoryCatalogScreen` / discoverable providers
- Thin new application use case + provider (e.g. `ChangeHeroVisibilityUseCase`) and owner UI affordance (Owned Detail and/or publish gate)

**What it does not change**

- Story lifecycle model
- Discover\* algorithms / personalization / HS.8 ranking
- Theme mapping (FG.2)
- Story Understanding durability
- Seeker audio player
- Search/Browse UI redesign
- Identity BC / multi-user ownership (still deferred HS-ADR-065)

**Dependencies**

- SB.13, HS.FG.1, existing Hero aggregate/repo (local single-hero sufficient)

**Acceptance criteria**

1. Owner can set active Hero visibility to `public` or `community` (and see current value).
2. With Hero discoverable + Story published/public, Story appears via `DiscoverStoriesUseCase` and in `StoryCatalogScreen` after refresh/navigation.
3. With Hero `private`, published Story remains excluded (policy preserved).
4. Focused application + UI + one integration test covering **local private Hero → visibility change → publish → Discover** (not only pre-seeded public Hero).
5. Analyzer clean on touched paths; no personalization or BehavioralEvidence side effects.

**Follow-ons (after FG.3), not this slice**

- Theme-aware catalog composition (wire existing browse/filter)
- Owner → seeker handoff CTA / provider invalidation
- Seeker playback parity
- Durable Story Understanding generate/review/apply

---

## 7. Architectural Invariants

Confirmed against current code:

| Invariant | Status |
|-----------|--------|
| Discovery owns `NarrativeTheme` | Confirmed |
| Hero & Story references `NarrativeThemeId` only | Confirmed |
| Story is canonical after SB.13 | Confirmed |
| StoryProposal is not canonical published content | Confirmed |
| AI is not authoritative | Confirmed |
| Provenance is preserved through materialize/publish | Confirmed |
| Publication is explicit (not automatic from materialize) | Confirmed |
| Discovery owns discovery eligibility (Story + Hero policies) | Confirmed |
| Classification is not personalization | Confirmed (FG.2 bridge) |
| Story interaction is not automatically BehavioralEvidence | Confirmed |
| No duplicate NarrativeTheme taxonomy in Hero & Story | Confirmed |

---

## 8. Test Baseline

Recorded on this checkpoint branch from `main` @ `9139f2a` before any doc-only commit:

```text
Focused:
  113/113 passed
  (FG.1 path + FG.1 UI + FG.1/FG.2 integrations + theme bridge + HS.6 discovery + Discovery BC tests)

Full Flutter:
  1093/1093 passed

Dart analyze:
  0 errors
  1 pre-existing warning (unawaited_futures in browse_stories_by_catalog_use_case.dart)
  41 infos (prefer_initializing_formals and similar; no new issues introduced)
```

No production feature implementation performed.

---

## 9. Representation Boundaries (reference)

| Concern | Status |
|---------|--------|
| Narrative / title | Implemented on Story |
| Summary | Partially — proposal `derivedSummary` not copied onto Story |
| Classification | Implemented VO; Builder path fills themes only |
| Provenance | Implemented (incl. SB.13 linkage) |
| Language | Implemented (`LanguageCode` + representations) |
| Representations | Implemented entity/use cases |
| Audio / transcript / media | Implemented on capture path; **not created by SB.13** materialization |

---

## 10. Conclusion

The repository can now run the full owner authoring → materialization → publication pipeline, with Builder themes bridged into Discovery IDs.

The smallest real missing composition is **not** HS.6/HS.7 greenfield work and **not** speculative Story Understanding wiring. It is making the **owner’s Hero discoverable** so a published Story can appear through the Discovery surfaces that already exist.
