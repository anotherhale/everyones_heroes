# D.3 — Curated Influence Discovery

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter local Discovery write path)
- **Phase:** D.3 Curated Influence Discovery
- **Baseline:** D.1 Discovery Profile Runtime Foundation (`5acd8dc` / PR #87)
- **Date:** 2026-09-26

---

## 0. Objective delivered

Establish the missing human-facing Discovery write path:

```text
Curated Influence
    ↓
User selects Influence
    ↓
DiscoveryProfile
    ↓
Resolve Narrative Themes
    ↓
AdaptiveDiscoverySignals (existing D.1 path)
    ↓
Today's Experience
```

A person can tell Everyone’s Heroes something that inspires them, and that
information can influence what is presented next — without claiming behavioral
understanding from Influence selection alone.

---

## 1. AD-D3-001 — Curated Influence catalog

**Decision:** Seed a small curated catalog (`InfluenceReferenceCatalog`, ~12
Influences) behind the existing `InfluenceRepository` port via
`InMemoryInfluenceRepository.withReferenceCatalog()`.

**Why:** Smallest implementation compatible with existing ports. Catalog owns
`InfluenceId → Influence`; `DiscoveryProfile` stores `InfluenceId[]` only.

**Themes:** Influences reference only existing `NarrativeThemeReferenceIds`.
No second theme vocabulary.

**Not:** AI-generated Influences, external Influence service, CMS, HeroId links.

---

## 2. AD-D3-002 — Selection orchestration

**Decision:** `SelectInfluencesUseCase` orchestrates:

```text
EnsureCurrentDiscoveryProfile
  → AddInfluenceUseCase (per Influence)
  → ResolveNarrativeThemesUseCase (once)
```

Influence selection and theme resolution remain separate domain/application
concepts; orchestration exists only for the user journey.

**Events:** Aggregate still raises `InfluenceAdded` /
`NarrativeThemesResolved`. Application use cases do **not** publish them on
an EventBus in D.3. Direct orchestration is sufficient for the write path.
Event publication remains deferred.

---

## 3. AD-D3-003 — Discover screen hosts Influence picker

**Decision:** Replace Discover tab stub cards with a “What inspires you?”
Influence picker. Do not restructure AppShell navigation. Hero Catalog remains
on the Heroes tab.

---

## 4. Explicit boundaries (confirmed)

| Boundary | D.3 status |
|----------|------------|
| BehavioralEvidence from Influence selection | **Not emitted** — inspiration ≠ behavior |
| Hero ↔ Discovery (`favoriteHero` → HeroId, InspiredByHero) | **Deferred** — later delivered as D.11 `inspiringHeroIds` (not favoriteHero) |
| HeroProfile.experienceAreas as preferences | **Not used** |
| PersonalizationEngine / AI ranking | **Not introduced** |
| GrowthOpportunity / GrowthProfile | **Not introduced** |
| DiscoveryActivity | **Not implemented** |
| Platform DiscoveryProfile persistence | **Deferred** (local in-memory continues) |
| Duplicate NarrativeTheme vocabulary | **Not introduced** |

---

## 5. Adaptive integration

D.1 path is unchanged:

```text
DiscoveryProfile.narrativeThemeIds
  → RepositoryDiscoveryProfileThemeSource
  → AdaptiveDiscoverySignals
  → DeterministicStoryRelevanceRanker
  → Today's Experience
```

Relationship remains Influence → NarrativeTheme and Story → NarrativeTheme.
No hard-coded Influence → Story mapping.

---

## 6. Seeded Influences

| Influence | Themes |
|-----------|--------|
| Rocky Balboa | perseverance, overcoming-adversity, courage |
| David Goggins | perseverance, overcoming-adversity, purpose |
| Aragorn | leadership, courage, sacrifice |
| Michael Jordan | perseverance, failure, transformation |
| Atomic Habits | transformation, purpose, discovery |
| The Lord of the Rings | courage, sacrifice, perseverance |
| United States Navy SEALs | service, leadership, sacrifice |
| Malala Yousafzai | courage, purpose, overcoming-adversity |
| Nelson Mandela | leadership, second-chances, overcoming-adversity |
| Fred Rogers | love, family, service |
| Marie Curie | discovery, perseverance, purpose |
| Brené Brown | courage, transformation, love |

---

## 7. Recommended next steps

- **D.5 Implemented:** Influence removal / editable Current Inspirations UI
  (see `D.5-Editable-Current-Inspirations.md`)
- Publish Discovery domain events on EventBus when a consumer needs them
- Platform DiscoveryProfile persistence (platform D.1 plan)
- Hero ↔ Discovery inspiration relationship (architectural decision required)
