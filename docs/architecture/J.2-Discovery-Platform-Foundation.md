# J.2 — Discovery Platform Foundation

- **Document type:** Architecture + Implementation Report
- **Status:** Slices 1–4 implemented; Slices 5–6 not implemented
- **Phase:** J.2 — Platform Narrative Theme Foundation + Live Story candidate discovery
- **Baseline:** J.1 complete (`a8d92ad` / PR #58); planning baseline after D.1 plan (`56db481` / PR #59); Slices 1–3 at `5a0a279` / PR #60; Slice 4 plan at `db1225d` / PR #61
- **Date:** 2026-09-24 (Slice 4 implementation)

---

## Slice status

| Slice | Scope | Status |
|-------|-------|--------|
| **J.2 Slice 1** | Platform NarrativeTheme reference catalog | **COMPLETE** |
| **J.2 Slice 2** | Resolve themes → AdaptiveDiscoverySignals (catalog-aligned) | **COMPLETE** |
| **J.2 Slice 3** | Story candidate persistence / seeding | **COMPLETE** |
| **J.2 Slice 4** | Live candidate discovery / ranking refinement | **COMPLETE** — see [`J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md`](./J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md) |
| **J.2 Slice 5** | Candidate projection productization (ingest) | **COMPLETE** — see [`J2-Candidate-Projection-Productization-Plan.md`](./J2-Candidate-Projection-Productization-Plan.md) |
| **D.1** | DiscoveryProfile / Influence productization | **NOT IMPLEMENTED** (see D.1 plan) |
| **J.2 Slice 6** | Public Discovery REST / full personalization | **NOT IMPLEMENTED** |

---

## 0. Planning conclusion (authority for this phase)

J.2 is ready as a **bounded Discovery foundation**, but the full DiscoveryProfile / Discovery Activities / Influence productization is **not** ready and must not be forced into this phase.

Immediate scope (Slices 1–3):

```text
J.2 Slice 1
Platform NarrativeTheme reference catalog
        ↓
J.2 Slice 2
Resolve themes into AdaptiveDiscoverySignals
and replace self-discovery with catalog-aligned IDs
        ↓
J.2 Slice 3
Transitional seeded Story candidate source
behind DiscoverableStoryCandidatePort
```

Desired flow after Slices 1–3:

```text
Reflection / Journey
          │
          ▼
AdaptiveDiscoverySignals
          │
          ▼
DiscoverableStoryCandidatePort
          │
          ▼
Story candidate source (transitional seed)
          │
          ▼
AdaptiveExperienceComposer
          │
          ▼
Today's Experience (adaptive-story-{id} | reflection)
```

**Relationship to D.1:** `D.1-Discovery-Profile-Platform-Plan.md` proposes broader DiscoveryProfile / Influence / public Discovery API work and remains **planning-only**. J.2 deliberately stops before that surface. Do not treat D.1 as authorized by this implementation.

---

## 1. Exact catalog vocabulary (Slice 1)

Platform Discovery owns the same 14 themes as Flutter `NarrativeThemeReferenceCatalog` / `NarrativeThemeReferenceIds`. **No themes invented. No casual renames.**

| Opaque ID | Display name | Description |
|-----------|--------------|-------------|
| `overcoming-adversity` | Overcoming adversity | Facing hardship and continuing forward. |
| `courage` | Courage | Acting despite fear. |
| `service` | Service | Helping others through lived experience. |
| `leadership` | Leadership | Guiding or taking responsibility for others. |
| `loss` | Loss | Living through loss and its aftermath. |
| `failure` | Failure | Confronting failure and what follows. |
| `transformation` | Transformation | Meaningful personal change over time. |
| `perseverance` | Perseverance | Continuing despite difficulty. |
| `second-chances` | Second chances | Beginning again after a setback. |
| `sacrifice` | Sacrifice | Giving something up for a greater purpose. |
| `family` | Family | Family bonds, responsibility, and belonging. |
| `discovery` | Discovery | Finding meaning, identity, or direction. |
| `purpose` | Purpose | Seeking or living with purpose. |
| `love` | Love | Love as a central narrative force. |

Typed ID: `NarrativeThemeId` (shared kernel). Reference constants: `NarrativeThemeReferenceIds`.

---

## 2. Ownership decision

| Concern | Owner |
|---------|-------|
| NarrativeTheme entity + reference catalog | **Discovery** (platform + Flutter mirror) |
| Catalog ID constants | Shared kernel (`NarrativeThemeReferenceIds`) |
| Theme alignment / legacy map | Discovery domain (`NarrativeThemeAlignment`) |
| Catalog-aligned `NarrativeThemeResolver` | Discovery application → wired into Life Journey AnalyzeReflection |
| AdaptiveDiscoverySignals **resolution** | Discovery application (`CatalogAlignedAdaptiveDiscoverySignalResolver`) |
| AdaptiveDiscoverySignals **consumption DTO** | Experience application model (HS.8 composer input) |
| Experience Selection / Today | Experience (unchanged public API) |
| Story candidate **port** | Experience (`DiscoverableStoryCandidatePort`) |
| Story candidate **source / seed** | Hero & Story (`StoryCandidateSource`, transitional seed) |
| Reflection theme **persistence** | Life Journey (`reflections.narrative_themes` JSONB) |

Preserved AD:

```text
Narrative Themes → Owned by Discovery
Content Classification ≠ Personalization
Story candidates → Hero & Story (behind Experience port)
```

Experience Selection consumes theme vocabulary and candidates; it does **not** own the taxonomy, does **not** interpret raw Reflection themes, and does **not** know how candidates are stored.

---

## 3. Catalog storage decision (Slice 1)

**Decision: code-defined catalog seed (no SQL table in J.2).**

Rationale:

* Reference vocabulary needs stable IDs, deterministic availability, and testability.
* Matches Flutter `NarrativeThemeReferenceCatalog` (already code-defined).
* Avoids speculative taxonomy framework and unnecessary migration for immutable seed data.
* Future D.1 may introduce SQL `narrative_themes` if productization needs runtime-editable catalogs — not required for Slices 1–3.

Artifacts:

* `services/eh_platform/lib/src/discovery/domain/catalog/narrative_theme_reference_catalog.dart`
* `services/eh_platform/lib/src/shared_kernel/ids/narrative_theme_reference_ids.dart`

**No public Discovery REST endpoint** for the catalog. Internal domain/application ports only.

---

## 4. Resolver mapping (Slice 2)

### 4.1 FakeNarrativeThemeResolver replacement

| Before | After |
|--------|-------|
| Always emit `NarrativeThemeId('self-discovery')` | `CatalogAlignedNarrativeThemeResolver` |
| ID **outside** 14-theme catalog | Always emit catalog `discovery` |

Legacy Fake files remain as `@Deprecated` aliases that **delegate** to the catalog-aligned resolver (no semantically invalid IDs escape).

### 4.2 Mapping rules (deterministic, non-AI)

1. Catalog members pass through unchanged.
2. Legacy Fake ID `self-discovery` → catalog `discovery`.
3. All other unknown IDs are **dropped** (never invented).
4. Aligned signal theme lists are **deduped and sorted** by opaque ID value.

Implemented in `NarrativeThemeAlignment`.

### 4.3 Explicit limitation

The analyzer-path resolver does **not** classify reflection content against the full 14-theme vocabulary. It preserves the previous always-emit deterministic behavior with a catalog-valid ID (`discovery`).

A content-aware deterministic mapper (or AI behind a port) is **deferred**. This limitation is intentional for J.2 — do not silently invent sophistication.

---

## 5. Persisted Reflection themes

| Fact | Detail |
|------|--------|
| Storage | PostgreSQL `reflections.narrative_themes` JSONB (H.2 migration `002`) |
| Written by | `AnalyzeReflectionUseCase` via `NarrativeThemeResolver` |
| Pre-J.2 values | Often `self-discovery` (Fake) |
| J.2 write path | Catalog-aligned resolver → `discovery` |
| J.2 read path for Today | Discovery signal resolver loads Reflection themes via `ReflectionRepository.findByJourneyId`, aligns through `NarrativeThemeAlignment`, emits `AdaptiveDiscoverySignals.narrativeThemeIds` |

**Distinction preserved:**

```text
stored reflection observations  ≠  derived adaptive discovery signals
```

Signals are derived at read time; Reflection rows are not rewritten en masse. Legacy `self-discovery` rows are aligned when building signals.

No second theme store was introduced.

---

## 6. AdaptiveDiscoverySignals ownership

```text
Discovery
  └── CatalogAlignedAdaptiveDiscoverySignalResolver
           │  (reads Reflection themes + Journey patterns)
           ▼
Experience
  └── AdaptiveDiscoverySignalPort (consumption port)
           │
           ▼
ExperienceApplicationService
           │
           ▼
AdaptiveExperienceComposer + DiscoverableStoryCandidatePort
```

* Experience does **not** interpret raw Reflection themes.
* Patterns remain Journey understanding (Life Journey authority).
* HS.8 `AdaptiveExperienceComposer` preserved.
* Public API unchanged: `GET /v1/experiences/today`.

---

## 7. Slice 3 — Story candidate source

### 7.1 Existing Hero & Story model evaluation

Platform `HeroStoryModule` was a boundary stub only — **no** Story aggregate, repository, or Postgres tables on EH Platform.

Flutter still owns the full Hero & Story domain (`Story`, `Hero`, Discover*, file/in-memory repos). Migrating that aggregate into the platform would pull Slice 3 beyond scope (authoring, lifecycle, media, visibility, etc.).

**Decision: do not create a second Story aggregate.** Introduce the smallest additional representation:

```text
StoryCandidateRecord
  ├── storyId
  ├── heroId
  ├── title
  ├── themeIds[]   // canonical Discovery opaque IDs only
  └── updatedAt
```

This is a **discoverable projection** for HS.8 composition — not a parallel Story model.

### 7.2 Persistence / seed decision

**Chosen: transitional deterministic platform seed/fixture** (`SeededStoryCandidateCatalog`).

| Option | Verdict |
|--------|---------|
| Full Postgres Story persistence | Out of scope — no platform Story aggregate yet |
| Thin `discoverable_story_candidates` SQL table | Acceptable later; premature without HS authority migration |
| **Code-defined architectural seed** | **Selected for Slice 3** |

Rationale:

* Matches Slice 1 catalog strategy (code-defined, deterministic, no migration).
* Keeps domain boundary intact: Experience → port → adapter → `StoryCandidateSource`.
* Replacement by real Hero & Story persistence is a single `StoryCandidateSource` swap.
* Seed is explicitly labeled transitional — **not** permanent architecture.

**No SQL migration was added for Slice 3.** No migration smoke beyond the existing H.2 baseline was required.

### 7.3 Candidate contract

Experience receives candidates only as `DiscoverableStoryCandidate`:

| Field | Role |
|-------|------|
| `storyId` | Stable seed / future Story ID |
| `heroId` | Opaque Hero reference |
| `title` | Composer / Today DTO title |
| `matchedThemeIds` | Overlap with signal themes |
| `themeOverlapCount` | Primary ranking key |
| `patternBoost` | Secondary ranking key (0.0–1.0) |
| `updatedAt` | Tie-break |

No ML scores, popularity, engagement, or invented personalization fields.

### 7.4 Candidate adapter

```text
Experience
    ↓
DiscoverableStoryCandidatePort
    ↓
DiscoverableStoryCandidateAdapter  (Slice 4 rename; was Seeded*)
    ↓
StoryCandidateSource
  production: PostgresStoryCandidateSource
  tests: SeededStoryCandidateCatalog / in-memory projection
```

Adapter behavior:

1. If `!signals.hasThemes` → `[]` (patterns alone never invent Story relevance).
2. Load candidates from `StoryCandidateSource`.
3. Rank via `DeterministicStoryRelevanceRanker`.
4. Return top `limit` (default 20).

Composition root (`PlatformComposition.bootstrap`) wires:

```dart
HeroStoryModule.composePostgres(database: database)  // live projection
→ ExperienceModule.compose(storyCandidatePort: heroStory.storyCandidatePort)
```

Tests may omit the port (Empty fail-closed), inject
`SeededStoryCandidateCatalog.architecturalSeed()` explicitly, or use an
in-memory / Postgres projection via `ProjectDiscoverableStoryCandidateUseCase`.

> **Slice 4 note:** Section 7 describes the Slice 3 seed path historically.
> Production no longer defaults to the architectural seed — see §9b.
### 7.5 Deterministic relevance rule

Ported from Flutter HS.8 `DeterministicStoryRelevanceRanker`:

1. **Primary:** `themeOverlapCount` descending
2. **Secondary:** `patternBoost` (max pattern strength) descending — only when overlap > 0
3. **Tie-break:** `updatedAt` descending, then `storyId` ascending

`AdaptiveExperienceComposer` continues to take `relevant.first` after `themeOverlapCount > 0` filter — the adapter/ranker must already order candidates.

**Not used:** ML, embeddings, LLM ranking, popularity, CTR, social metrics, opaque scores.

### 7.6 Canonical theme validation

Unknown candidate theme IDs **fail validation at load time** (`ValidationException` in `StoryCandidateRecord` construction / seed catalog assembly).

Rationale: seed data is under our control; silent exclusion would hide catalog drift. Runtime signal alignment still **drops** unknown Reflection themes (Slice 2) because those are observations, not curated seed.

Hero & Story references `NarrativeThemeReferenceIds` only — it does **not** duplicate the Discovery catalog entity list.

### 7.7 Architectural seed catalog (deliberately small)

| storyId | Themes | Purpose |
|---------|--------|---------|
| `seed-story-finding-direction` | `discovery`, `purpose` | Overlaps Slice 2 analyzer signal (`discovery`) |
| `seed-story-rising-again` | `courage`, `perseverance` | Multi-theme / ranking winner |
| `seed-story-courage-alone` | `courage` | Lower-overlap peer for Case C |
| `seed-story-leading-through` | `leadership`, `service` | Non-overlapping with discovery-only signals |
| `seed-story-second-wind` | `second-chances`, `transformation` | Additional catalog coverage |

Titles are prefixed `[Seed]` — architectural fixtures, **not** production content.

### 7.8 Fail-closed behavior (preserved)

```text
Discovery signals
      ↓
no matching Story candidates (empty source, no themes, or zero overlap)
      ↓
Adaptive Story unavailable
      ↓
default reflection experience (UI.3)
```

Never invent a Story. Never select by popularity. Never fall back to an arbitrary seed entry.

### 7.9 End-to-end path (Slice 3)

```text
GET /v1/experiences/today
        ↓
Experience Selection
        ↓
AdaptiveDiscoverySignals
        ↓
DiscoverableStoryCandidatePort
        ↓
candidate matching + deterministic ranking
        ↓
AdaptiveExperienceComposer
        ↓
adaptive-story-{storyId}   OR   default-reflection / consistency-next-step
```

---

## 8. Tests

| Suite | Coverage | Result |
|-------|----------|--------|
| `j2_narrative_theme_catalog_test.dart` | Catalog integrity: 14 themes, unique stable IDs | Pass |
| `j2_adaptive_discovery_signals_test.dart` | Alignment, resolver validity, determinism | Pass |
| `j2_story_candidate_test.dart` | Cases A–E: match, fail-closed, deterministic, invalid theme, J.1 regression + HTTP | Pass |
| `j1_experience_*` | J.1 regression (consistency / default / empty candidates) | Pass |
| `architecture_dependency_test.dart` | Discovery purity; Experience ≠ catalog; Experience ≠ seed SQL; HS ≠ redefined catalog | Pass |
| Flutter `catalog_aligned_narrative_theme_resolver_test.dart` | Flutter transitional resolver validity | Pass |
| Full `services/eh_platform` `dart test` | Platform suite | **89/89** |
| Full `flutter test` | Flutter suite | **1124/1124** |
| `dart analyze` (platform) | Clean aside from 1 pre-existing info | Pass |
| `flutter analyze` | 47 pre-existing infos; no new errors in J.2 paths | Pass |

No new SQL migrations were added for Slice 3 (transitional code-defined seed). Existing Postgres migration smoke (PF.3 + H.2 via `h2_postgres_integration_test`) passed against a local cluster. No Slice 3 migration smoke was necessary beyond that baseline.

---

## 9. Deferred decisions (explicitly retained)

1. **Content-aware theme classification** — analyzer still always-`discovery`
2. **Dual Flutter/platform catalogs** — transitional mirror; keep in sync
3. **Production Story metadata/content pipeline** — full HS platform persistence
4. **DiscoveryProfile**
5. **Influence**
6. **Public Discovery API**

Also deferred to later slices:

* Slice 4 — live candidate discovery / ranking refinement — **COMPLETE** (see Slice 4 plan + implementation notes below).
* Slice 5 — candidate projection productization (Flutter publish/archive → HTTP ingest → Postgres → Today) — **COMPLETE** (see productization plan).
* D.1 — DiscoveryProfile / broader Discovery capabilities (separate authorization)

---

## 9b. Slice 4 — Live Story candidate discovery (summary)

```text
Story + Hero facts (Flutter authority today)
        ↓
AdaptiveStoryCandidateEligibilityPolicy (HS.6 + themes + authoritative rep)
        ↓
discoverable_story_candidates (Postgres projection)
        ↓
PostgresStoryCandidateSource
        ↓
DiscoverableStoryCandidateAdapter + DeterministicStoryRelevanceRanker
        ↓
DiscoverableStoryCandidatePort → AdaptiveExperienceComposer → Today
```

| Concern | Decision |
|---------|----------|
| Projection table | `discoverable_story_candidates` (`003_j2_discoverable_story_candidates.sql`) |
| Production source | `PostgresStoryCandidateSource` via `HeroStoryModule.composePostgres` |
| Seed | Test fixture only (`SeededStoryCandidateCatalog`) — not production default |
| Sync | Transitional `ProjectDiscoverableStoryCandidateUseCase` (Phase 7 replaces) |
| Ranking | Unchanged: themeOverlap → patternBoost → updatedAt DESC → storyId ASC |
| Fail-closed | Empty / no overlap → default reflection |

Full detail: [`J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md`](./J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md).

---

## 9c. Slice 5 — Candidate projection productization (summary)

Closes the Slice 4 **ingest gap**. Flutter Story remains authoritative for publish/archive.

```text
PublishStoryUseCase / ArchiveStoryUseCase (+ hero visibility / classify)
        ↓
StoryCandidateEligibilityFactsMapper
        ↓
SyncDiscoverableStoryCandidatePort → PUT /v1/hero-story/candidates/{storyId}
        ↓
ProjectDiscoverableStoryCandidateUseCase
        ↓
discoverable_story_candidates → existing Today read path
```

| Concern | Decision |
|---------|----------|
| Ingest API | `HeroStoryApi` — `PUT /v1/hero-story/candidates/{storyId}` |
| Flutter sync | Soft-fail after durable Story save; no publish rollback |
| No Candidate aggregate | Projection remains derived HS read model |
| Migration | Reuses `003` — no new schema |
| Phase 7 | Still replaces HTTP sync with platform Story authority + reactors |

Full detail: [`J2-Candidate-Projection-Productization-Plan.md`](./J2-Candidate-Projection-Productization-Plan.md).

---

## 10. Acceptance checklist

### Slices 1–2

* [x] Platform Discovery owns canonical NarrativeTheme vocabulary
* [x] Catalog contains exactly the intended 14 themes
* [x] Theme IDs stable and deterministic
* [x] Platform signal resolution uses catalog-valid IDs
* [x] FakeNarrativeThemeResolver no longer emits IDs outside the catalog
* [x] Reflection themes handled via explicit alignment path
* [x] AdaptiveDiscoverySignals resolution separate from Experience Selection rules
* [x] HS.8 AdaptiveExperienceComposer intact
* [x] No public Discovery API
* [x] J.1 Today contract preserved
* [x] Flutter does not regain selection authority in platform mode

### Slice 3

* [x] `DiscoverableStoryCandidatePort` remains the Experience seam
* [x] Transitional seed/fixture labeled and replaceable via `StoryCandidateSource`
* [x] No second Story aggregate invented
* [x] Candidate themes restricted to canonical 14 IDs (fail at load)
* [x] Deterministic ranking (themeOverlapCount → patternBoost → updatedAt → storyId)
* [x] Fail-closed when no match
* [x] Composition root wires real adapter (not Empty) for platform bootstrap
* [x] Vertical integration tests (Cases A–E)
* [x] Architecture boundary tests updated
* [x] No J.1 API contract change
* [x] No Flutter redesign / dual-catalog consolidation
* [x] No SQL migration required for Slice 3 seed

### Slice 4

* [x] `DiscoverableStoryCandidatePort` unchanged as Experience seam
* [x] Live Postgres projection replaces seed as platform production default
* [x] No second Story aggregate on platform
* [x] Eligibility mirrors HS.6 Story + Hero (+ catalog themes + authoritative rep)
* [x] No new discoverable lifecycle flag as source of truth
* [x] Ranking remains deterministic (no ML)
* [x] Fail-closed reflection behavior preserved
* [x] Narrative themes remain Discovery-owned
* [x] AdaptiveDiscoverySignals remain the only user-understanding input to candidates
* [x] DiscoveryProfile not required
* [x] Architecture + integration + regression suites updated
* [x] Phase 7 full HS migration not dragged into Slice 4

### Slice 5

* [x] Flutter Story remains authoritative for publish/archive
* [x] No Candidate aggregate introduced
* [x] `ProjectDiscoverableStoryCandidateUseCase` reused
* [x] Migration `003` reused
* [x] Backend HTTP ingest (`PUT /v1/hero-story/candidates/{storyId}`)
* [x] Flutter sync port/adapter after publish/archive/hero-visibility/classify
* [x] Soft-fail sync (publish not rolled back on projection failure)
* [x] Today read path unchanged; adaptive-story-* from projected candidates
* [x] Focused ingest + productization + Flutter sync tests
