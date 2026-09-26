# D.5 — Editable Current Inspirations

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter local Discovery write path)
- **Phase:** D.5 Editable Current Inspirations
- **Baseline:** D.3 Curated Influence Discovery (`59e07ad` / PR #88)
- **Date:** 2026-09-26

---

## 0. Objective delivered

Complete DiscoveryProfile current-state semantics so a person can edit their
current Inspirations:

```text
Select Influences
        ↓
Current DiscoveryProfile
        ↓
Narrative Themes (union of Influence themes)
        ↓
Remove Influence
        ↓
Current DiscoveryProfile
        ↓
Re-resolve Narrative Themes
        ↓
AdaptiveDiscoverySignals
        ↓
Today's Experience
```

Persisted Influences are no longer append-only in the Discover UI.

---

## 1. AD-D5-001 — Narrow RemoveInfluenceUseCase

**Decision:** Introduce `RemoveInfluenceUseCase` as the sole application removal
path:

```text
EnsureCurrentDiscoveryProfile
  → DiscoveryProfile.removeInfluence
  → ResolveNarrativeThemesUseCase
  → Repository.save
```

**Invariant after every mutation:**

```text
profile.narrativeThemeIds
  == union(themes of profile.influenceIds)
```

Themes are always re-resolved from the remaining Influence set (set union),
never decrementally subtracted. Shared themes remain when another Influence
still supplies them; exclusive themes disappear.

**Not:** PersonalizationEngine, DiscoveryHistory, generic updateDiscoveryProfile
abstraction, EventBus publication (no consumer yet).

---

## 2. AD-D5-002 — Pending vs persisted removal in Discover UI

**Decision:** Extend the existing D.3 save-oriented Discover picker:

* Persisted Influences appear under **Current Inspirations** as removable chips.
* Marking a persisted Influence for removal updates pending state only.
* Save applies pending removals (`RemoveInfluenceUseCase`) then pending adds
  (`SelectInfluencesUseCase`).
* Provider invalidation reuses D.3:
  `currentDiscoveryProfileProvider` + `todayExperienceProvider`.

**Not:** New Discover screen, Hero feed, Story feed, social/follow behavior.

---

## 3. Explicit boundaries (confirmed)

| Boundary | D.5 status |
|----------|------------|
| BehavioralEvidence from Influence removal | **Not emitted** |
| DiscoveryHistory / DiscoveryActivity | **Not introduced** |
| Hero ↔ Discovery (`HeroId`, InspiredByHero, favorite) | **Deferred** |
| HeroProfile changes | **Not touched** |
| PersonalizationEngine / AI / ML ranking | **Not introduced** |
| Signal provenance (explicit vs inferred) | **Deferred** |
| Platform DiscoveryProfile persistence | **Deferred** (local in-memory continues) |
| EventBus publication of InfluenceRemoved | **Deferred** (no consumer) |
| GrowthOpportunity | **Not introduced** |

---

## 4. Adaptive verification

Removing an Influence whose exclusive themes made a Story eligible can remove
that Story’s theme-based adaptive match. Remaining Influences continue to feed
`AdaptiveDiscoverySignals`. Reflection/Journey signals remain unchanged.

Deterministic ranking is unchanged.

---

## 5. Remaining D.4 / deferred decisions (not solved by D.5)

1. Explicit vs inferred signal provenance
2. Hero ↔ Discovery relationship
3. Platform DiscoveryProfile authority
4. Whether Discover eventually becomes a richer content-discovery experience

D.5 completes the current Inspiration preference loop only.
