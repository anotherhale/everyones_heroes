# HS.FG.1 — Owner Publish Path Composition

**Status:** COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/hs-fg-1-owner-publish-path-47ee`  
**Prerequisite:** SB.13; `docs/analysis/HS-architecture-checkpoint.md`  
**Plan:** `docs/analysis/HS-FG-1-owner-publish-path-plan.md`

---

## Summary

After SB.13, an accepted `StoryProposal` materializes into a canonical `Story` left in **`draft`**. Submit, Approve, and Publish use cases already existed, but were not composed into the owner-facing UI — so Builder-born Stories could not reach Discovery.

HS.FG.1 wires those existing capabilities into Owned Story Detail (and post-materialize navigation) without redesigning Story, lifecycle, visibility, or Discovery.

```text
Approved StoryProposal
        ↓
SB.13 Materialize → Story(draft)
        ↓
Owner Submit → processing (owner label: Submitted)
        ↓
Owner Approve → approved
        ↓
Owner Publish (+ public visibility when needed)
        ↓
DiscoverStories (existing eligibility)
```

---

## Inspection findings (pre-implementation)

```text
SB.13 materialization entry point:
  MaterializeStoryProposalUseCase → CreateStoryUseCase → draft
  UI: StoryBuilderUiPhase.storyCreated

Story lifecycle use cases:
  SubmitStoryUseCase, ApproveStoryUseCase, PublishStoryUseCase,
  UpdateStoryConsentUseCase

Story repository:
  StoryRepository (+ in-memory / file)

Owner authorization mechanism:
  Owned reads check ownerHeroId
  Lifecycle mutations: storyId only (no separate moderator role)
  Owner self-approval is allowed by the existing model

Visibility mechanism:
  StoryVisibility; publish rejects private/draft
  StoryDiscoverabilityPolicy: published + {public, community}

Current owner-facing Story UI:
  MyStoriesScreen → OwnedStoryDetailScreen (archive only before FG.1)

Discovery query:
  DiscoverStoriesUseCase

Current composition gap:
  Missing approve/publish providers + owned publication actions
  + post-materialize continue path
```

---

## Existing architecture reused

| Concern | Reused component |
|---------|------------------|
| Materialize | `MaterializeStoryProposalUseCase` (unchanged) |
| Submit | `SubmitStoryUseCase` / `Story.submit` |
| Approve | `ApproveStoryUseCase` / `Story.approve` (+ `markReadyForReview`) |
| Publish | `PublishStoryUseCase` / `Story.publish` |
| Consent | `UpdateStoryConsentUseCase` |
| Persistence | `StoryRepository` |
| Owner reads | `GetOwnedStoryDetailUseCase`, `OwnedStoryMapper` |
| Discoverability | `StoryDiscoverabilityPolicy`, `DiscoverStoriesUseCase` |
| UI shell | `OwnedStoryDetailScreen`, `MyStoriesScreen` |

No second Story aggregate, repository, lifecycle enum, or visibility model was introduced.

---

## Composition changes

1. **Providers** (`owned_story_use_case_providers.dart`):
   - `approveStoryUseCaseProvider`
   - `publishStoryUseCaseProvider`
   - `ownedSubmitStoryUseCaseProvider`
   - `ownedUpdateStoryConsentUseCaseProvider`

2. **Owned Story Detail**:
   - Publication section with lifecycle-gated Submit / Approve / Publish
   - Submit grants processing consent when missing, then calls Submit
   - Publish grants publication consent when missing and sets `StoryVisibility.public` when current visibility is private/draft/unlisted
   - Failures surface in-UI; providers are invalidated only after success
   - Canonical Story remains source of truth (no parallel Riverpod lifecycle)

3. **Story Builder post-materialize**:
   - “Continue to Story” → `OwnedStoryDetailScreen` via `pushReplacement`
   - Preserves “Not yet published” messaging

---

## Lifecycle

Domain transitions (unchanged):

```text
draft → processing → review → approved → published
```

Owner-facing labels:

| Domain status | Owner label |
|---------------|-------------|
| draft | Draft |
| processing | Submitted |
| review | Ready for Review |
| approved | Approved |
| published | Published |

`ApproveStoryUseCase` collapses `processing → review → approved` when approving from Submitted.

### Authorization boundary

- Existing mutation use cases do **not** enforce `ownerHeroId` (same as Archive).
- Owned detail **reads** reject non-owners.
- There is **no separate moderator role**; owner self-approval is permitted by the current model and is exposed in the owner UI.
- Identity BC / multi-user ownership enforcement remains deferred (HS-ADR-065).

---

## Visibility

- Materialization continues to set `StoryVisibility.draft`.
- Publish does not silently invent a new visibility enum.
- Owner Publish passes `StoryVisibility.public` when the Story is still private/draft/unlisted so domain publish preconditions are met.
- Discovery eligibility remains `{public, community}` and is **not** duplicated in Hero & Story UI logic.
- Hero discoverability (`HeroDiscoverabilityPolicy`) remains a separate gate for Discover results.

---

## Discovery

Integration test:

`test/features/hero_story/integration/hs_fg1_owner_publish_discovery_integration_test.dart`

Verifies:

```text
materialize → draft (not discoverable)
submit → processing (not discoverable)
approve → approved (not discoverable)
publish + public → discoverable via DiscoverStoriesUseCase
```

Provenance (`materializedFromProposalId`) is preserved through publish.

---

## Tests

```text
Focused tests:
  15/15 FG.1 (9 application + 1 integration + 5 UI)
  Related hs10 / hs11 / sb13 UI smoke: passed

Full Flutter suite:
  1078/1078

Analyzer:
  flutter analyze on Hero & Story — no new errors (pre-existing infos only)
```

---

## Deferred work

- HS.FG.2 — Builder theme → `NarrativeThemeId` bridge
- HS.FG.3 — Story Understanding generate/review/apply composition
- Owner mutation use cases gaining explicit `ownerHeroId` checks (Identity BC)
- Hero visibility management as part of publication UX
- Community moderation / non-owner approval workflows
- Auto-publish (explicitly out of scope; SB.13 remains draft-only)

---

## Architectural invariants preserved

- No SB.13 reimplementation
- No duplicate Story aggregate
- No duplicate lifecycle
- No duplicate NarrativeTheme
- No duplicated Discovery eligibility
- Provenance preserved on publish
