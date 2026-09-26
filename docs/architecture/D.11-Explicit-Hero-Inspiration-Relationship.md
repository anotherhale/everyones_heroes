# D.11 — Explicit Hero Inspiration Relationship

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter local Discovery write path)
- **Phase:** D.11 Explicit Hero Inspiration Relationship
- **Baseline:** D.9 Today Experience Explanation Provenance; D.10 product
  decision (assessment) that EH supports an explicit current-state private
  user preference for Heroes who inspire them
- **Date:** 2026-09-26

---

## 0. Objective delivered

Establish an explicit, current-state, private relationship between a seeker
user and Everyone’s Heroes Hero aggregates that inspire them:

```text
Seeker views discoverable Hero
        ↓
"Inspires me" preference
        ↓
DiscoveryProfile.inspiringHeroIds
        ↓
(read) HeroRepository + HeroDiscoverabilityPolicy
        ↓
Seeker-facing presentation (discoverable only)
```

This is **not** Influences, favorites, follows, Story consumption, or
adaptive ranking.

---

## 1. Decision (from D.10)

Everyone’s Heroes supports an explicit, current-state, private user
preference for Heroes who inspire them, distinct from:

* Influences (curated catalog entities)
* `DiscoveryType.favoriteHero` (dormant string vocabulary — untouched)
* Follows / social graph
* Story consumption

Canonical terminology:

* Field: `inspiringHeroIds`
* UI: **"Inspires me"**

---

## 2. Ownership

| Concern | Owner |
|---------|--------|
| Hero identity, profile facts, lifecycle, visibility, discoverability | **Hero & Story** |
| User’s inspiring HeroIds preference | **Discovery** (`DiscoveryProfile`) |

Cross-context link is `HeroId` only. Discovery does not become authoritative
for Hero facts.

---

## 3. Representation

```text
DiscoveryProfile
  └── inspiringHeroIds: List<HeroId>
```

Semantics:

* many Heroes
* current state (no history)
* private to the owning user
* unordered / set-like membership
* no ranking semantics
* no timestamps
* no social visibility
* no follower semantics
* no Story-consumption semantics

Operations:

* `addInspiringHero(HeroId)` — idempotent
* `removeInspiringHero(HeroId)` — idempotent

Invariants mirror `influenceIds`:

* A HeroId may occur at most once
* Duplicate add is a no-op
* Absent remove is a no-op
* Does **not** automatically become a NarrativeTheme signal

No new `HeroInspiration` aggregate.

---

## 4. Application

| Use case | Role |
|----------|------|
| `AddInspiringHeroUseCase` | Ensure current profile → add → save |
| `RemoveInspiringHeroUseCase` | Ensure current profile → remove → save |
| `ListInspiringHeroesUseCase` | Resolve IDs via HeroRepository; filter with HeroDiscoverabilityPolicy |

Read DTO: `InspiringHeroSummary` (`heroId`, `displayName`, `biography?`).

No EventBus consumers. No new repository for Hero inspiration.
No theme re-resolution on add/remove.

---

## 5. Lifecycle / discoverability

```text
DiscoveryProfile retains HeroId
        ↓
Seeker-facing read re-checks Hero existence + discoverability
        ↓
Undiscoverable / missing → omit from presentation
        ↓
DiscoveryProfile is NOT silently mutated
```

Deletion workflows are out of scope for D.11.

---

## 6. UI

| Surface | Behavior |
|---------|----------|
| `HeroProfileScreen` (seeker, discoverable Hero) | **"Inspires me"** / **"Inspires me ✓"** via Discovery `InspiresMeToggle` |
| Discover — **Heroes Who Inspire Me** | Lists currently discoverable inspiring Heroes; remove; navigate to profile |

Composition keeps Hero & Story free of Discovery imports: App composition
injects the control via `heroProfileActionBuilderProvider`.

Private / personal only. Does not imply following, friendship, or public
endorsement.

Riverpod:

* `isHeroInspiringMeProvider(heroId)`
* `inspiringHeroesProvider`
* After mutation: invalidate `currentDiscoveryProfileProvider` +
  `inspiringHeroesProvider` only
* **Does not** invalidate Today / adaptive ranking providers

---

## 7. Adaptive boundary (confirmed unchanged)

D.11 does **not** modify:

* `AdaptiveDiscoverySignals`
* `DeterministicStoryRelevanceRanker`
* `AdaptiveExperienceComposer`
* Today experience selection

Architectural rule:

> Relationship existence ≠ recommendation signal.

Inspiring Heroes do not boost Stories/Heroes, generate NarrativeThemes, or
affect ranking, recommendations, reflections, missions, or coaching.

---

## 8. Influence boundary (confirmed unchanged)

Influences and inspiring Heroes remain separate:

```text
Influences:           Rocky, David Goggins, Atomic Habits
Inspiring Heroes:     EH Hero A, EH Hero B
```

No Influence ↔ Hero conversion. No NarrativeTheme resolution from Heroes.
`favoriteHero` UserDiscovery type remains untouched.

---

## 9. Persistence

Extended existing in-memory `DiscoveryProfileRepository` so
`inspiringHeroIds` round-trips with the aggregate.

Platform DiscoveryProfile authority remains deferred.

---

## 10. Explicit non-goals (confirmed)

Not implemented:

* PersonalizationEngine / ranking / Story boosting
* Following / social graph / public endorsements / notifications
* DiscoveryHistory / DiscoveryActivity / EventBus consumers
* favoriteHero migration
* Hero aggregate / lifecycle changes
* Identity BC / Hero deletion workflows
* AI/ML

---

## 11. Deferred decisions

1. Whether inspiring Heroes eventually influence Story ranking
2. Whether they influence Hero discovery ranking
3. Whether they contribute to personalization / AdaptiveDiscoverySignals
4. Whether platform persistence becomes authoritative for DiscoveryProfile
5. Whether public/social semantics are ever introduced
6. Whether inspiring Heroes ever contribute NarrativeThemes

---

## 12. Files (primary)

Domain / application / presentation under `lib/features/discovery/` plus
`HeroProfileScreen` and Discover section; focused tests under
`test/features/discovery/` and D.11 UI tests.
