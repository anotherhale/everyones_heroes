# HS.FG.3 — Owner Hero Discoverability Composition

**Status:** COMPLETE  
**Date:** 2026-09-23  
**Branch:** `cursor/hs-fg-3-owner-hero-discoverability-ff84`  
**Prerequisite:** HS.FG.1; HS.FG.2; Post-FG Integration Checkpoint (`docs/analysis/HS-post-FG-integration-checkpoint.md`)

---

## Purpose

After SB.13 / HS.FG.1 / HS.FG.2, an owner can materialize, classify, submit, approve, and publish a Story. Discovery eligibility for the Story itself was already correct, but the default local Hero remains `private`.

Existing Discovery requires:

```text
published Story
+
eligible Story visibility ({public, community})
+
non-provisional narrative
+
discoverable Hero ({public, community}, active)
```

Therefore the closed-loop break was:

```text
Published Story
      +
Private Hero
      ↓
Discovery excludes Story
```

HS.FG.3 composes the existing Hero visibility capability into the owner-facing experience so the Hero can **explicitly** control whether their Hero is discoverable.

```text
Hero private + published eligible Story → undiscoverable
Hero explicitly discoverable + published eligible Story → Discovery may return it
```

---

## Existing architecture reused

| Concern | Component |
|---------|-----------|
| Visibility type | `HeroVisibility` (`private`, `unlisted`, `community`, `public`) |
| Domain mutation | `Hero.changeVisibility` |
| Discoverability rules | `HeroDiscoverabilityPolicy` (`{public, community}` + active) |
| Story eligibility | `StoryDiscoverabilityPolicy` (unchanged) |
| Discovery query | `DiscoverStoriesUseCase` (unchanged) |
| Persistence | `HeroRepository` (`InMemoryHeroRepository` / `FileHeroRepository`) |
| Local ownership bootstrap | `ensureActiveLocalHeroProvider` (default `HeroVisibility.private`) |
| Owner UI surface | `MyStoriesScreen` (Hero-scoped owner library) |

No second Hero aggregate, visibility model, or Discovery policy was introduced.

---

## Composition

```text
Owner visibility action (My Stories)
        ↓
ChangeHeroVisibilityUseCase
        ↓
Hero.changeVisibility + HeroRepository.save
        ↓
Canonical Hero visibility
        ↓
DiscoverStoriesUseCase
  (StoryDiscoverabilityPolicy ∧ HeroDiscoverabilityPolicy)
```

### Application

- `ChangeHeroVisibilityRequest` — `heroId`, `ownerHeroId`, `visibility`
- `ChangeHeroVisibilityUseCase` — owner authorization (`ownerHeroId == heroId`), mutate, persist, restore prior visibility on save failure
- `changeHeroVisibilityUseCaseProvider` — wired in owner providers

### Presentation

- `OwnerHeroDiscoverabilityViewModel` — Private / Discoverable labels (does **not** expose `HeroDiscoverabilityPolicy`)
- `ownerHeroDiscoverabilityProvider` / `OwnerHeroDiscoverabilityController`
- My Stories section: current status, consequence copy, **Make Discoverable** / **Make Private**

Discoverable maps to `HeroVisibility.public`. Private maps to `HeroVisibility.private`. Existing `community` remains discoverable if already set.

---

## Consent boundary

```text
Story publication ≠ Hero discoverability
```

- Publishing a Story does **not** change Hero visibility (`PublishStoryUseCase` loads Hero for referential integrity only).
- Making a Hero discoverable does **not** publish Stories or change Story visibility.
- Default local Hero remains private (`ensureActiveLocalHeroProvider`).
- Discoverability requires an explicit owner action.

---

## Owner authorization

Until Identity BC exists (HS-ADR-065), ownership follows the local single-Hero model:

- UI only acts on `ensureActiveLocalHeroProvider`
- Use case requires `ownerHeroId == heroId`
- Non-matching owner fails closed; prior visibility preserved

No admin/moderator role was introduced.

---

## Persistence

Visibility is stored on the Hero snapshot (`visibility` field) via the existing Hero repository path.

Verified:

```text
private → change → reload (new FileHeroRepository) → public
public → change → reload → private
```

UI invalidates providers only after a successful use-case result (no optimistic mutation).

---

## Discovery integration

Integration test proves the closed loop with the **default private** Hero (not a pre-seeded public Hero):

1. Create private Hero  
2. Publish eligible Story (`published` + `public` + non-provisional)  
3. `DiscoverStoriesUseCase` excludes it  
4. Owner sets Hero to `public`  
5. Same Discovery query includes it  
6. Owner sets Hero back to `private`  
7. Discovery excludes it again  

Regression: publish leaves Hero private.

`StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy` were not modified.

---

## Deferred work

Explicitly out of scope for FG.3:

- Theme filtering UI (`NarrativeThemeId` → `StoryCatalogScreen` filters)
- Owner → seeker handoff / catalog navigation after publish
- Seeker audio playback parity
- HS.7 Hero journeys
- Collections
- Personalization / Discovery Profile updates from visibility
- BehavioralEvidence from visibility changes
- Identity BC multi-user ownership

---

## Tests

| Suite | Coverage |
|-------|----------|
| Domain | `Hero.changeVisibility` active/archived; default private |
| Application | owner/non-owner; persistence; failure restore; archived |
| Infrastructure | FileHeroRepository reload round-trip |
| Integration | private ↔ discoverable Discovery closed loop; publish independence |
| UI | My Stories status display; Make Discoverable / Make Private; reload |

### Validation (this branch)

```text
Focused FG.3 tests: 22/22 passed
Full Flutter:       1111/1111 passed
flutter analyze (touched paths): No issues found
```

---

## Architectural invariants

- Existing Hero visibility reused
- Discovery owns discoverability eligibility
- Story publication does not change Hero visibility
- Hero discoverability does not publish Stories
- No duplicate Hero aggregate
- No duplicate visibility model
- No personalization side effect
- No behavioral evidence from visibility change
