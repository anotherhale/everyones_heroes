# D.7 — Inspiration-Grounded Story Exploration

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter local Discover exploration path)
- **Phase:** D.7 Inspiration-Grounded Story Exploration
- **Baseline:** D.5 Editable Current Inspirations
- **Date:** 2026-09-26

---

## 0. Objective delivered

Make Discover an inspiration-grounded Story exploration experience using the
existing DiscoveryProfile → NarrativeTheme path and existing Hero & Story
Discover* eligibility:

```text
Discover
  What inspires you?
  [Influence selection / current inspirations]
  --------------------------------
  Explore Stories
  Stories connected to your inspirations
  [Story]
  [Story]
  ...
```

---

## 1. Runtime flow

```text
DiscoverScreen
      ↓
currentDiscoveryProfileProvider
      ↓
DiscoveryProfile.influenceIds / narrativeThemeIds
      ↓
ExploreStoriesByInspirationUseCase
      ↓
DiscoverStoriesUseCase(narrativeThemeIds: profile themes)
      ↓
eligible Stories ∩ theme overlap
      ↓
InspirationStoryExploration (inspiration provenance)
      ↓
Discover Explore Stories section
```

Influence save still invalidates:

* `currentDiscoveryProfileProvider`
* `inspirationGroundedStoriesProvider`
* `todayExperienceProvider`

Theme re-resolution remains the D.5 invariant (set union of remaining
Influences). Shared themes survive when another Inspiration still supplies them.

---

## 2. Bounded-context responsibilities

| Context | D.7 responsibility |
|---------|--------------------|
| **Discovery** | Inspiration state (`influenceIds`, resolved `narrativeThemeIds`) |
| **Hero & Story** | Story catalog facts + discoverability (`DiscoverStoriesUseCase`) |
| **Life Journey / Experience** | Application orchestration for Discover exploration + Today's Experience (unchanged) |
| **Life Journey behavioral** | Not involved — browsing does not create BehavioralEvidence |

Discovery does **not** inspect Story aggregate internals.

Hero & Story does **not** own DiscoveryProfile.

---

## 3. Story eligibility boundary

Exploration reuses existing Discover* contracts:

* published lifecycle
* discoverable visibility (`public`, `community`)
* non-provisional narrative
* Hero discoverability gate
* catalog NarrativeTheme filter (OR overlap)

Relationship path:

```text
Influence → NarrativeTheme → Story.classification.narrativeThemeIds
```

Not:

```text
Influence → Story
```

---

## 4. Provenance semantics

Exploration is sourced **only** from DiscoveryProfile themes.

It does **not** use `AdaptiveDiscoverySignals` (which unions Reflection themes).

UI copy:

* Section: “Stories connected to your inspirations”
* Per Story: “Connected through {ThemeName}” (or “Connected to your inspirations”)

Must **not** claim “recently reflected on” for Inspiration-derived matches.

---

## 5. Empty state

No current Inspirations → no fabricated Stories.

Copy: “Choose a few inspirations to discover related Stories.”

---

## 6. Explicit non-goals (confirmed)

| Boundary | D.7 status |
|----------|------------|
| PersonalizationEngine / AI / ML ranking | **Not introduced** |
| Signal weighting | **Not introduced** |
| Hero ↔ Discovery relationship | **Not introduced** |
| DiscoveryHistory / DiscoveryActivity | **Not introduced** |
| Platform DiscoveryProfile persistence | **Not introduced** |
| EventBus consumers / unnecessary publication | **Not introduced** |
| BehavioralEvidence from browsing | **Not introduced** |
| GrowthOpportunity | **Not introduced** |
| Full Discover redesign | **Not performed** |
| HeroProfile changes | **Not touched** |

---

## 7. Deferred work (from D.5 / D.6 assessment)

1. Explicit vs inferred multi-source signal provenance for Today's Experience
2. Hero ↔ Discovery relationship ADR
3. Platform DiscoveryProfile authority
4. Whether Discover later gains richer serendipity / personalization (out of D.7)
5. Fixing AdaptiveExperienceComposer rationale wording for DiscoveryProfile-only Today matches (separate from Discover exploration)

D.7 completes inspiration-grounded Story exploration on Discover only.
