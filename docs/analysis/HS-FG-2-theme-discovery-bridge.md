# HS.FG.2 — Story Builder Theme → Discovery NarrativeThemeId Bridge

**Status:** COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/hs-fg-2-theme-bridge-bdd7`  
**Prerequisite:** HS.FG.1; SB.13; `docs/analysis/HS-architecture-checkpoint.md`

---

## Purpose

After SB.13 / HS.FG.1, Builder-born Stories can reach Discovery eligibility, but adaptive relevance could not see Builder themes because materialization never populated `Story.classification.narrativeThemeIds`.

HS.FG.2 establishes the missing taxonomy/reference bridge:

```text
Story Builder theme intent (StoryBuilderTheme)
        ↓
Application bridge (HS.FG.2)
        ↓
Discovery-owned NarrativeThemeId
        ↓
Story.classification.narrativeThemeIds
```

Without inventing a second NarrativeTheme definition in Hero & Story.

---

## Ownership

```text
Discovery owns NarrativeTheme.
Hero & Story references NarrativeThemeId.
Story Builder owns StoryBuilderTheme (authoring intent only).
```

Hard constraints preserved:

* No `hero_story/.../narrative_theme.dart` entity/aggregate
* No Hero & Story `NarrativeThemeRepository`
* No personalization / Discovery Profile update from theme selection
* No BehavioralEvidence from theme selection
* Provenance unchanged by theme mapping

---

## Existing implementation discovered

| Concern | Finding |
|---------|---------|
| Story Builder theme type | `StoryBuilderTheme` enum (14 values) in `lib/features/hero_story/domain/enums/story_builder_theme.dart` |
| Session storage | `StoryBuilderIntent.themes` on `StoryBuilderSession` |
| Proposal storage | `StoryProposal.intent` snapshots Builder themes (enum `.name`) |
| Story catalog field | `StoryClassification.narrativeThemeIds: List<NarrativeThemeId>` already existed |
| SB.13 materialization | Mapped title/narrative/provenance only — **classification empty** |
| Discovery NarrativeTheme | Entity in `lib/features/discovery/domain/entities/narrative_theme.dart` |
| NarrativeThemeId | Shared Kernel `lib/core/ids/narrative_theme_id.dart` (opaque string) |
| NarrativeThemeRepository | Interface + in-memory impl; **no seed catalog before FG.2** |
| Reflection pattern | `NarrativeThemeResolver` → `reflection.addNarrativeThemes` (Life Journey); production fake returns `NarrativeThemeId('self-discovery')` — **no string→ID mapper reusable for Builder** |
| Prior bridge | **None** for `StoryBuilderTheme` → `NarrativeThemeId` |

Case classification: **Case B** — Story already referenced `NarrativeThemeId` via classification; FG.2 adds mapping + population at materialization (no Story model redesign).

---

## Mapping

Discovery reference catalog establishes stable opaque IDs (not display labels):

| StoryBuilderTheme | NarrativeThemeId.value |
|-------------------|------------------------|
| overcomingAdversity | `overcoming-adversity` |
| courage | `courage` |
| service | `service` |
| leadership | `leadership` |
| loss | `loss` |
| failure | `failure` |
| transformation | `transformation` |
| perseverance | `perseverance` |
| secondChances | `second-chances` |
| sacrifice | `sacrifice` |
| family | `family` |
| discovery | `discovery` |
| purpose | `purpose` |
| love | `love` |

Canonical IDs live in Discovery:

* `NarrativeThemeReferenceIds`
* `NarrativeThemeReferenceCatalog` (entity seed: id + English name + description)

Bridge lives at the application boundary:

* `StoryBuilderThemeNarrativeThemeBridge`
* Imports Discovery **reference IDs only** (not NarrativeTheme entity ownership into Hero & Story domain)
* Does not import Flutter / AI / personalization

---

## Unknown themes

* All **current** `StoryBuilderTheme` values have Discovery mappings.
* Bridge `mapTheme` returns `NarrativeThemeId?`; `mapThemes` **omits** nulls (never invents fake IDs).
* Empty intent / `themesUnsure` → empty `narrativeThemeIds` on Story.
* Future enum values without a switch arm fail at compile time (exhaustive switch).

Display labels (`StoryBuilderIntentLabels.theme`) remain presentation-only and are never persisted as IDs.

---

## Story persistence path

```text
StoryBuilderSession.intent.themes (StoryBuilderTheme[])
        ↓
StoryProposal.intent (snapshot)
        ↓
MaterializeStoryProposalUseCase
        ↓ CreateStory (SB.13 — draft, provenance unchanged)
        ↓ ClassifyStory with mapped NarrativeThemeIds (HS.FG.2)
        ↓
Story.classification.narrativeThemeIds
```

* Themes remain Builder intent on Session/Proposal (source of authoring truth).
* Canonical Story holds Discovery references (catalog truth).
* Draft refresh from re-approval also re-applies theme classification (preserves other classification dimensions).
* Idempotent rematerialize of an already-linked Story does not re-classify.

---

## Personalization boundary

Theme mapping does **not** create:

* Discovery preferences / DiscoveryProfile updates
* Behavioral Evidence
* Behavior Patterns
* Growth Opportunities
* Personalization signals

Choosing a Builder theme classifies the Story; it does not assert what the Hero personally prefers.

---

## Provenance

Theme classification does not alter:

* `contentOrigin` on proposal sections
* `proposalContainedDerivedContent`
* `proposalDerivationKind`
* Hero-authored vs AI-derived semantics

---

## Composition changes

1. Discovery reference catalog + IDs
2. `InMemoryNarrativeThemeRepository.withReferenceCatalog()`
3. `StoryBuilderThemeNarrativeThemeBridge`
4. `MaterializeStoryProposalUseCase` applies classification after create / draft refresh
5. Provider wires `ClassifyStoryUseCase` into materialize

UI unchanged — bridge is invisible to the Hero.

---

## Tests

| Suite | Result |
|-------|--------|
| Focused bridge + catalog + FG.2 integration | see Final Cursor report |
| Full Flutter | see Final Cursor report |
| Analyzer | see Final Cursor report |

---

## Deferred work

* Broader Discovery NarrativeTheme catalog beyond Builder-overlap seeds
* Mapping Builder **understanding** themes through the same bridge outside materialization (already covered when proposal carries intent)
* HS.FG.3 durable Story Understanding + apply wiring for non-Builder classification dimensions
* Replacing Life Journey `FakeNarrativeThemeResolver` with catalog-aware resolution (known hygiene; out of scope)
* Presentation boundary cleanup on Story Builder (checkpoint item 4)

---

## Architectural invariants

* Discovery owns NarrativeTheme
* Hero & Story references NarrativeThemeId
* No duplicate NarrativeTheme
* No duplicate taxonomy ownership
* No personalization side effect
* No behavioral evidence from theme selection
* Provenance preserved
