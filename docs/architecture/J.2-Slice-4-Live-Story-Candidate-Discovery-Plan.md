# J.2 Slice 4 — Live Hero & Story Candidate Discovery and Ranking

- **Document type:** Architecture + Implementation Plan (planning only)
- **Status:** Planning complete — implementation not started
- **Phase:** J.2 Slice 4 — Live Story candidate discovery / ranking refinement
- **Baseline (code):** `5a0a279` — J.2 Discovery and Story candidate foundation (#60); Slices 1–3 COMPLETE
- **Related:** `J.2-Discovery-Platform-Foundation.md`, `HS.6-Hero-Story-Discovery-Implementation-Plan.md`, `HS.8-Adaptive-Hero-Discovery-Implementation-Report.md`, `PF.2-Platform-Architecture-Decisions.md` (Phase 7), `D.1-Discovery-Profile-Platform-Plan.md` (planning-only)
- **Date:** 2026-09-24

---

## 0. Planning conclusion

Slice 4 should replace the platform **architectural seed** with a **live, eligibility-gated Story candidate projection** behind the existing seams:

```text
AdaptiveDiscoverySignals
        ↓
DiscoverableStoryCandidatePort
        ↓
StoryCandidateSource   ← live projection query (not seed)
        ↓
DeterministicStoryRelevanceRanker
        ↓
AdaptiveExperienceComposer
```

**Do not** migrate the full Hero & Story aggregate / authoring / media stack to EH Platform (that remains PF.2 Phase 7).

**Do** reuse the Flutter HS.6 discoverability contract and the J.2 Slice 3 projection/port shape so Experience never learns Story persistence mechanics.

### Dual-stack fact (authoritative)

| Surface | Candidate source today | Slice 4 implication |
|---------|------------------------|---------------------|
| **Flutter** | Live: `DiscoverStoriesUseCase` → `DiscoverStoriesCandidateAdapter` | Already production-oriented for local HS; preserve; use as eligibility/ranking reference |
| **EH Platform** | Transitional: `SeededStoryCandidateCatalog` → `SeededDiscoverableStoryCandidateAdapter` | **Primary Slice 4 target** — replace seed with live projection query |

There is **no** Postgres `stories` / `heroes` table on platform today (migrations `001` + `002` only). Flutter authority remains `Story` + `Hero` aggregates with InMemory / File JSON repositories.

---

## 1. Current Slice 3 architecture (platform)

```text
GET /v1/experiences/today
  → ExperienceApplicationService
  → AdaptiveDiscoverySignalPort.resolve(journey)
       CatalogAlignedAdaptiveDiscoverySignalResolver
         Reflection.narrativeThemes → NarrativeThemeAlignment
         ∪ Journey.behaviorPatterns
  → DiscoverableStoryCandidatePort.findRelevant(signals)
       SeededDiscoverableStoryCandidateAdapter
         → StoryCandidateSource.listCandidates()
              SeededStoryCandidateCatalog.architecturalSeed()  // 5 [Seed] fixtures
         → DeterministicStoryRelevanceRanker.rank(...)
  → AdaptiveExperienceComposer.compose(...)
       themeOverlapCount > 0 → adaptive-story-{storyId}
       else → DeterministicExperienceSelectionService (UI.3 reflection)
```

### Key types (platform)

| Type | Path | Role |
|------|------|------|
| `DiscoverableStoryCandidatePort` | `experience/application/ports/` | Experience seam |
| `AdaptiveDiscoverySignals` | `experience/application/models/` | Consumption DTO |
| `DiscoverableStoryCandidate` | `experience/application/models/` | Ranked candidate DTO |
| `StoryCandidateSource` | `hero_story/application/ports/` | Replaceable HS store |
| `StoryCandidateRecord` | `hero_story/domain/models/` | Thin projection (not aggregate) |
| `SeededStoryCandidateCatalog` | `hero_story/infrastructure/` | Transitional seed |
| `SeededDiscoverableStoryCandidateAdapter` | `hero_story/application/services/` | Port adapter + rank |
| `DeterministicStoryRelevanceRanker` | `hero_story/application/services/` | Ranking policy |
| `AdaptiveExperienceComposer` | `experience/application/services/` | Selection decision |

### Ranking (Slice 3 — preserve)

1. `themeOverlapCount` DESC  
2. `patternBoost` (max Journey pattern strength) DESC — only when overlap > 0  
3. `updatedAt` DESC  
4. `storyId` ASC  

Patterns never create relevance without themes. Fail-closed when `!signals.hasThemes` or zero overlap.

---

## 2. Current Hero & Story persistence capabilities

### Flutter (authoritative Story model today)

**Aggregate:** `lib/features/hero_story/domain/aggregates/story.dart`

| Concern | Existing representation |
|---------|-------------------------|
| Identity | `StoryId` |
| Hero association | `HeroId heroId` (authoritative; Hero does not store story lists) |
| Narrative | `StoryTitle`, `StoryNarrative` (`isProvisional`) |
| Lifecycle | `StoryLifecycleStatus`: draft, processing, review, approved, published, archived, rejected, suspended, removed |
| Visibility | `StoryVisibility`: private, draft, unlisted, community, public |
| Themes | `StoryClassification.narrativeThemeIds: List<NarrativeThemeId>` (IDs only) |
| Catalog dims | subjects, challenges, outcomes, emotionalCharacters, audience, geography |
| Suitability | `ContentSuitability` + `SuitabilityLevel` |
| Spirituality | `SpiritualityClassification` (content classification ≠ Hero identity) |
| Representations | `StoryRepresentation[]` with `isAuthoritative` |
| Consent | recorded / processing / publication / AI transformation gates |
| Timestamps | `createdAt`, `updatedAt` |
| Persistence | `StoryRepository` → InMemory + File JSON (`FileStoryRepository`) |
| Queries | `findById`, `findByHeroId`, `findAll`, `findPublished`, `findByStoryProposalId` |
| Search | `StorySearchPort` / `InMemoryStorySearchAdapter` |
| Discovery UC | `DiscoverStoriesUseCase` (HS.6) |
| Adaptive adapter | `DiscoverStoriesCandidateAdapter` (HS.8) |

**Hero:** `Hero` aggregate with `HeroVisibility` + `HeroStatus`; discoverability requires active + `{public, community}`.

### EH Platform (today)

| Capability | Status |
|------------|--------|
| Story / Hero aggregates | **Absent** |
| Postgres stories/heroes | **Absent** |
| Candidate projection | `StoryCandidateRecord` + code seed only |
| Candidate port wiring | `HeroStoryModule.compose()` → seed adapter |

**Authoritative source for “what is a Story?”:** Flutter Hero & Story domain until Phase 7.

**Authoritative source for “what may platform Experience select?” after Slice 4:** a Hero & Story–owned **discoverable candidate projection** queried through `StoryCandidateSource`, derived from HS.6 eligibility semantics — not a second Story aggregate.

---

## 3. Discoverability / eligibility semantics (discovered)

### Existing distinctions (do not invent a new flag)

The repository already distinguishes lifecycle and visibility. There is **no** separate `discoverable` enum or boolean.

**Story discoverability** — `StoryDiscoverabilityPolicy` (HS.6 / HS-ADR-043):

```text
lifecycleStatus == published
AND visibility ∈ {public, community}
AND !hasProvisionalNarrative
```

Private and unlisted are **never** discoverable.

**Hero discoverability** — `HeroDiscoverabilityPolicy`:

```text
status == active
AND visibility ∈ {public, community}
```

**Catalog Discover\*** additionally searches with:

* `publishedOnly: true`
* discoverable visibilities
* `authoritativeRepresentationsOnly: true`

Then re-checks Story + Hero policies before returning `StoryDiscoverySummary`.

### Adaptive candidate eligibility (Slice 4 minimum)

A Story may participate in **adaptive** discovery only if all of the following hold:

| Rule | Source | Rationale |
|------|--------|-----------|
| HS.6 Story discoverable | `StoryDiscoverabilityPolicy` | Do not bypass catalog safety |
| HS.6 Hero discoverable | `HeroDiscoverabilityPolicy` | Known-id / catalog consistency with HS.7 |
| ≥1 catalog-valid `NarrativeThemeId` | Discovery `NarrativeThemeReferenceIds` | Adaptive ranking requires theme overlap; empty themes can never match signals |
| Theme IDs are Discovery-owned opaque IDs | AD-002 / J.2 Slice 1 | No HS theme vocabulary |
| Projection fields present | `storyId`, `heroId`, `title`, `themeIds`, `updatedAt` | Sufficient for Experience composer |

**Not required for Slice 4 projection membership (but respected by Discover\* when full Story exists):**

* Suitability max filters (seeker preference — future signal input)
* Full narrative body (HS.6 summaries intentionally omit it)
* Media bytes (HS.7 consume path)

**Do not create** a new lifecycle state or `isDiscoverable` column that becomes a parallel truth. If a projection table stores denormalized eligibility facts, they must be **derived** from lifecycle + visibility (+ hero status) and invalidated when those change.

### Lifecycle vs adaptive eligibility (mapping)

| State / concept | Adaptive candidate? |
|-----------------|---------------------|
| draft / processing / review / approved | No |
| published + public/community + non-provisional | **Eligible** (if themes + discoverable Hero) |
| published + private/unlisted | No |
| archived / rejected / suspended / removed | No |
| captured / processed (capture pipeline terms) | Not lifecycle states; do not invent as eligibility |

---

## 4. Proposed live candidate architecture

```text
Hero & Story authoritative Story (+ Hero)
        │  (Flutter today; Phase 7 platform later)
        ▼
Eligibility derivation
  StoryDiscoverabilityPolicy
  + HeroDiscoverabilityPolicy
  + ≥1 catalog theme IDs
        │
        ▼
Candidate projection write
  → StoryCandidateRecord (or equivalent row)
        │
        ▼
StoryCandidateSource.listCandidates()     // LIVE query
        │
        ▼
DiscoverableStoryCandidateAdapter         // rename of Seeded* adapter
  + DeterministicStoryRelevanceRanker     // relevance
        │
        ▼
DiscoverableStoryCandidatePort            // Experience seam (unchanged)
        │
        ▼
AdaptiveExperienceComposer                // selection
        │
        ▼
Today's Experience
  adaptive-story-{id}  |  default reflection (fail-closed)
```

### Boundary rules (locked)

| Concern | Owner | Must not |
|---------|-------|----------|
| Story content, lifecycle, visibility, suitability | Hero & Story | Experience |
| Candidate eligibility | Hero & Story | Experience / Discovery |
| Narrative Theme vocabulary | Discovery | Hero & Story must not redefine catalog entities |
| AdaptiveDiscoverySignals resolution | Discovery → Experience port | Candidate source must not read Reflection/Journey directly |
| Relevance ranking | Hero & Story application | Experience (except consuming ranked DTO) |
| Selection (story vs reflection) | Experience | Hero & Story |
| DiscoveryProfile | Deferred (D.1 / Slice 5) | Required for Slice 4 |

---

## 5. Candidate projection / query boundary

### Keep `StoryCandidateRecord` as the projection

Preferred architecture:

```text
Hero & Story authoritative model
        ↓
Candidate query / projection
        ↓
StoryCandidateRecord
        ↓
StoryCandidateSource
        ↓
DiscoverableStoryCandidatePort
```

**Do not** expose `Story` aggregates across the Experience port.

### Why not expose Story domain objects?

1. Experience must not depend on lifecycle, consent, media, or classification internals.
2. Platform does not yet own the Story aggregate; leaking Flutter Story types into platform Experience would reverse dependency direction.
3. Slice 3 deliberately chose a thin projection; Slice 4 should **replace the seed behind the same projection**, not widen Experience’s surface.
4. HS.6 already uses `StoryDiscoverySummary` as a safe catalog projection — `StoryCandidateRecord` is the adaptive-experience subset of that idea.

### Contract sufficiency

Current `StoryCandidateRecord` fields are **sufficient** for Slice 4:

| Field | Keep? | Notes |
|-------|-------|-------|
| `storyId` | Yes | Today target id |
| `heroId` | Yes | Opaque reference / future HS.7 |
| `title` | Yes | Composer / Today DTO |
| `themeIds` | Yes | Catalog-valid only; fail at construction |
| `updatedAt` | Yes | Deterministic tie-break |

**Do not add** to the Experience-facing `DiscoverableStoryCandidate` in Slice 4:

* narrative body / description  
* suitability dimensions  
* media references  
* ML relevance scores  
* popularity / engagement  

Optional **internal** projection columns (not exposed to Experience) may store denormalized eligibility facts (`lifecycle_status`, `visibility`, `hero_status`, `hero_visibility`) for query filtering and invalidation — still not a Story aggregate.

### `DiscoverableStoryCandidate` (Experience DTO) — preserve

`storyId`, `heroId`, `title`, `matchedThemeIds`, `themeOverlapCount`, `patternBoost`, `updatedAt`.

Explanation/rationale continues to be derived in `AdaptiveExperienceComposer` from matched themes + Journey patterns (PF-ADR-013), not from opaque AI text.

---

## 6. Retrieval vs relevance ownership

```text
Candidate retrieval  →  Which Stories are eligible to be considered?
Candidate relevance  →  Which eligible Stories match AdaptiveDiscoverySignals?
Experience selection →  Story experience vs reflection fallback?
```

| Step | Owner | Implementation |
|------|-------|----------------|
| Retrieval / eligibility | Hero & Story | Projection membership + `StoryCandidateSource.listCandidates()` (or filtered query) |
| Relevance / ranking | Hero & Story | `DeterministicStoryRelevanceRanker` |
| Signal production | Discovery (+ Journey patterns) | `AdaptiveDiscoverySignalPort` |
| Selection | Experience | `AdaptiveExperienceComposer` |

**Ranking policy placement (Slice 3 → Slice 4):**

| Key | Belongs where | Notes |
|-----|---------------|-------|
| `themeOverlapCount` | HS relevance | Overlap of candidate themes ∩ signal themes |
| `patternBoost` | HS relevance | Uses signal patterns; does not invent themes |
| `updatedAt` / `storyId` tie-break | HS relevance | Deterministic; preserve |
| Future DiscoveryProfile themes | Discovery → signals | Enter via `AdaptiveDiscoverySignals`, not ranker rewrite |
| Future content-aware relevance | Deferred | No ML/AI ranking in Slice 4 |
| Story vs reflection choice | Experience | `themeOverlapCount > 0` gate |

Rename recommendation: `SeededDiscoverableStoryCandidateAdapter` → `DiscoverableStoryCandidateAdapter` (source-agnostic). Keep seed catalog only for tests / explicit fixtures.

---

## 7. Narrative Theme ownership

**Confirmed from repository:**

* Discovery owns the 14-theme reference catalog (`NarrativeThemeReferenceCatalog`).
* Shared kernel holds opaque ID constants (`NarrativeThemeReferenceIds`).
* Story stores `List<NarrativeThemeId>` only.
* Story Builder enum `StoryBuilderTheme` is bridged 1:1 to Discovery IDs (`StoryBuilderThemeNarrativeThemeBridge`) — not a second catalog.
* Platform seed / `StoryCandidateRecord` validates against `NarrativeThemeReferenceIds` and must **not** import Discovery catalog entity lists into a redefined vocabulary (architecture test already enforces this).

**Slice 4 rule:** Live projection theme IDs must be catalog members. Unknown IDs fail at projection write (same as Slice 3 construction validation). Signal alignment continues to **drop** unknown Reflection themes (Slice 2).

---

## 8. AdaptiveDiscoverySignals boundary

The current boundary remains correct when the candidate source becomes live:

```text
Reflection themes + Journey patterns
        ↓
AdaptiveDiscoverySignalResolver (Discovery)
        ↓
AdaptiveDiscoverySignals
        ↓
DiscoverableStoryCandidatePort
```

**Port contract:** keep `findRelevant(AdaptiveDiscoverySignals, {limit})`.

**Required change:** none to the Experience port. Candidate source must consume `AdaptiveDiscoverySignals` only via the adapter — never ReflectionRepository, JourneyRepository, DiscoveryProfile, Flutter Riverpod, or raw SQL from Experience.

**Optional refinement (implementation detail, not an AD):** `StoryCandidateSource` may later accept a theme-prefilter for query efficiency (`listCandidates({themeIds})`) while still ranking in the adapter. Default Slice 4.1–4.3 can keep `listCandidates()` and filter in the ranker if the corpus is small.

---

## 9. DiscoveryProfile compatibility

Slice 4 **must not** require DiscoveryProfile.

Future path (D.1 / J.2 Slice 5):

```text
DiscoveryProfile.narrativeThemeIds  ∪  Reflection themes
        ↓
AdaptiveDiscoverySignals.narrativeThemeIds
        ↓
same DiscoverableStoryCandidatePort / StoryCandidateSource
```

Because relevance is signal-driven and eligibility is Story-driven, adding profile themes does **not** require redesigning the candidate architecture — only the signal resolver.

---

## 10. Persistence strategy (smallest production-oriented choice)

### Options evaluated

| Option | Verdict |
|--------|---------|
| Full Postgres Story/Hero aggregates (Phase 7) | **Out of scope** for Slice 4 |
| Query Flutter FileStoryRepository from platform process | Wrong process boundary; not platform authority |
| Keep code seed as “live” with non-seed titles | Not live; does not enforce eligibility |
| Dedicated CQRS event projection with full Story events | Premature without platform Story events |
| **Thin Postgres `discoverable_story_candidates` projection** | **Recommended** |
| In-memory / file projection only | Acceptable for early micro-slices/tests; insufficient as platform production default |

### Recommended: thin Hero & Story–owned projection table

```text
discoverable_story_candidates
  story_id TEXT PK
  hero_id TEXT NOT NULL
  title TEXT NOT NULL
  theme_ids JSONB NOT NULL   -- catalog-valid opaque IDs
  updated_at TIMESTAMPTZ NOT NULL
  -- optional denormalized eligibility facts for invalidation/debug:
  story_visibility TEXT
  hero_visibility TEXT
  projected_at TIMESTAMPTZ
```

| Concern | Decision |
|---------|----------|
| Ownership | Hero & Story module (platform) |
| Authoritative Story truth | Still Flutter Story (until Phase 7) |
| Synchronization (transitional) | Application upsert / sync use case projecting from eligibility-checked Story facts (tests + controlled ingest). Not Experience. |
| Synchronization (Phase 7) | `StoryPublished` / archive / visibility-change reactors refresh or delete projection rows |
| Consistency | Eventual OK for adaptive Today; fail-closed if empty/no overlap |
| Why not query full Story model? | Platform has no Story tables; full migration is Phase 7 |

### Transitional ingest (Slice 4, not Phase 7)

Introduce an HS application capability such as:

* `UpsertDiscoverableStoryCandidateUseCase` / `ProjectDiscoverableStoryCandidate`
* Inputs: projection fields + eligibility proof (or accept a Flutter-side export DTO that already passed HS.6 policies)
* Rejects rows that violate catalog themes or fail eligibility invariants

Production content enters the platform candidate set **only** through this projection path — never by Experience writing SQL.

### Flutter path

No new persistence required. Continue:

```text
StoryRepository → DiscoverStoriesUseCase → DiscoverStoriesCandidateAdapter
```

Align naming/docs so Flutter and platform share the same eligibility + ranking contracts.

---

## 11. HS.8 / composer compatibility

Preserve:

```text
No candidate / no themes / zero overlap
        ↓
default reflection experience (UI.3)

Candidate with themeOverlapCount > 0
        ↓
adaptive Story experience (adaptive-story-{storyId})
```

`AdaptiveExperienceComposer` already trusts pre-ranked candidates and filters `themeOverlapCount > 0`. Live source must not change that contract.

Explanation sources remain `kind: narrative_theme` from `matchedThemeIds`; rationale remains deterministic theme ± pattern text. **No AI explanations.**

---

## 12. Performance and query shape

Expected Slice 4 pattern:

1. Resolve signals (small).  
2. Load eligible candidates (projection; ideally theme-prefiltered later).  
3. Rank in memory for `limit` (default 20).  
4. Composer takes first relevant.

| Concern | Guidance |
|---------|----------|
| Load all Stories into memory? | Avoid for platform production; query projection table |
| Filter before relevance? | Prefer SQL/theme containment filter when corpus grows; OK to rank in memory initially |
| Pagination | Adapter `limit` sufficient for Today; Discover\* offset remains catalog concern |
| Indexing (later) | GIN on `theme_ids`; btree on `updated_at` |
| User-specific retrieval? | Eligibility is not user-specific; **relevance** is signal-specific |
| Deterministic ordering | Preserve ranker comparator; stable DB order is not a substitute |

Do not prematurely add search engines or embeddings.

---

## 13. Safety / suitability

Existing constraints that adaptive discovery **must not bypass**:

| Constraint | Mechanism |
|------------|-----------|
| Publication | `StoryLifecycleStatus.published` |
| Visibility | `{public, community}` only |
| Provisional narrative | Excluded by policy |
| Hero visibility/status | Hero policy |
| Authoritative reps (catalog search) | Discover\* flag; projection should only include experience-ready stories |
| Consent for publication | Enforced on Flutter `Story.publish` before published state exists |
| Suitability | Exists on Story; seeker max filters are Discover\* query params — optional later signal input, not Slice 4 invent-moderation |

**No new moderation system in Slice 4.** Lifecycle states `rejected` / `suspended` / `removed` already exclude via non-published status.

---

## 14. Implementation sequence (revised Slice 4.x)

Suggested decomposition (dependency order). Adjust only if implementation discovers a cleaner cut.

### J.2 Slice 4.1 — Eligibility contract + projection invariants

* Codify adaptive eligibility as an HS domain/application policy mirror of HS.6 policies + theme requirement (platform-safe; no Flutter imports).
* Document mapping lifecycle/visibility → projection membership.
* Unit tests for eligible / ineligible matrices.

### J.2 Slice 4.2 — Live `StoryCandidateSource` (projection query)

* Add platform Postgres migration for `discoverable_story_candidates` (or equivalent).
* Implement `PostgresStoryCandidateSource implements StoryCandidateSource`.
* Upsert/delete use case for projection rows (eligibility enforced at write).
* Architecture tests: Experience still must not import projection persistence.

### J.2 Slice 4.3 — Replace seed wiring

* Rename/generalize adapter (`DiscoverableStoryCandidateAdapter`).
* `HeroStoryModule.compose()` wires live source by default.
* Keep `SeededStoryCandidateCatalog` for tests / explicit fixtures only.
* Deprecation path: seed no longer production composition default.

### J.2 Slice 4.4 — Relevance against live data

* Reuse `DeterministicStoryRelevanceRanker` unchanged unless projection data forces a documented change.
* Verify Cases A–E from Slice 3 against projected (non-seed) rows.
* Optional: theme-prefilter on `listCandidates` for query shape — only if needed.

### J.2 Slice 4.5 — Flutter alignment / dual-stack verification

* Confirm Flutter HS.8 live path remains the reference implementation of eligibility + ranking.
* Add/adjust architecture or integration tests that prove both stacks honor the same fail-closed and ranking contracts.
* Do **not** force Flutter to use the platform projection table.

### J.2 Slice 4.6 — Integration verification

End-to-end platform proof:

```text
Persist/project discoverable Story candidate
        ↓
Reflection themes + Journey patterns → AdaptiveDiscoverySignals
        ↓
Live StoryCandidateSource → ranked candidates
        ↓
AdaptiveExperienceComposer → GET /v1/experiences/today
```

Plus fail-closed (empty projection, unpublished story, private visibility, no themes).

---

## 15. Testing strategy

### Unit

* Eligibility matrix (lifecycle × visibility × provisional × hero status/visibility × empty themes)
* Projection upsert rejects unknown theme IDs
* `PostgresStoryCandidateSource` / in-memory double list + filter
* Ranker: themeOverlap → patternBoost → updatedAt → storyId
* Adapter: `!hasThemes` → `[]`; limit truncation
* Composer: overlap → story; else reflection

### Integration

* Projection row → port → composer → Today DTO (`adaptive-story-…`)
* HTTP `GET /v1/experiences/today` with live source (extend `j2_story_candidate_test.dart` Cases A–E)
* Removing/archiving projection → fail-closed reflection
* J.1 consistency / default reflection regression

### Architecture

* Experience ↛ `seeded_story_candidate_catalog.dart` (already)
* Experience ↛ `story_candidate_record.dart` (already)
* Experience ↛ postgres / new projection repository files
* Hero & Story ↛ redefine Discovery catalog entities
* Discovery remains signal owner; no Flutter imports in platform candidate selection
* Production composition root does not default to architectural seed

### Regression

* J.2 Slices 1–3 suites green
* HS.6 discoverability / HS.8 Flutter adaptive tests green
* H.2 / J.1 platform suites green
* Full `eh_platform` + Flutter test suites before close

---

## 16. Documentation updates (this planning slice)

| Document | Action |
|----------|--------|
| **This file** | Slice 4 plan (authoritative for Slice 4 decisions) |
| `J.2-Discovery-Platform-Foundation.md` | Point Slice 4 status to this plan; keep Slices 1–3 report intact |
| `services/eh_platform/README.md` | Update when implementation lands (not required for planning-only) |

Do not duplicate the full Slice 1–3 report into this document.

---

## 17. Architectural risks

| Risk | Mitigation |
|------|------------|
| Projection becomes a second Story model | Keep fields minimal; no narrative/media/lifecycle aggregate behavior on the row |
| Slice 4 secretly starts Phase 7 | Explicit non-goal: no Story aggregate, builder, media, or full catalog search on platform |
| Seed left as production default | Composition + architecture test forbids seed default after 4.3 |
| Eligibility drift vs HS.6 | Shared rule matrix tests; mirror policy names/semantics |
| Experience learns persistence | Port-only dependency; architecture tests |
| Inventory without themes never selected but still “live” | Require ≥1 catalog theme for projection membership |
| DiscoveryProfile pressure | Keep signals seam; defer profile to D.1 / Slice 5 |
| Dual Flutter/platform ranker drift | Keep identical comparator; shared test cases |

---

## 18. Open decisions

### Genuine architectural decisions (need conscious choice if challenged)

1. **Platform persistence for Slice 4:** thin Postgres projection (**recommended**) vs defer SQL and keep file/in-memory projection until Phase 7.  
2. **Transitional ingest mechanism:** explicit upsert/sync use case (**recommended**) vs waiting for Phase 7 domain events only (would leave platform without live content).  
3. **Whether adaptive projection requires authoritative representation:** recommend **yes** for parity with Discover\* seeker path; confirm if any published stories lack authoritative reps in fixtures.

### Implementation details (resolve during coding)

* Exact table/column names and migration number (`003_…`)
* Adapter class rename vs keep `Seeded*` with live source injected
* Whether `StoryCandidateSource.listCandidates` gains optional theme filter in 4.4 or later
* How Flutter test fixtures export into platform projection in CI
* Whether optional denormalized visibility columns are stored or re-derived only at upsert

### Explicitly deferred

* Full Hero & Story Postgres authority (Phase 7)
* DiscoveryProfile (D.1 / J.2 Slice 5)
* Public Discovery REST (Slice 6)
* ML / embedding / LLM ranking
* Content-aware Reflection theme classification beyond catalog-aligned `discovery`
* Suitability preference signals in AdaptiveDiscoverySignals
* New moderation workflow

---

## 19. Migration / deprecation path for Slice 3 seed

```text
Slice 3 (current)
  HeroStoryModule.compose() → SeededStoryCandidateCatalog.architecturalSeed()

Slice 4.3+
  HeroStoryModule.compose() → PostgresStoryCandidateSource (live)
  SeededStoryCandidateCatalog retained for tests / empty() / explicit fixtures
  [Seed] fixture IDs must not be required for production Today path
```

Deprecation checklist:

* [ ] Production composition uses live `StoryCandidateSource`
* [ ] Architecture test fails if compose defaults to architectural seed
* [ ] Slice 3 Cases A–E re-proven with projected rows
* [ ] README notes seed as test fixture only
* [ ] J.2 foundation doc marks Slice 4 complete when implementation lands

---

## 20. Acceptance checklist (for future implementation)

* [ ] `DiscoverableStoryCandidatePort` unchanged as Experience seam
* [ ] Live source replaces seed as platform default
* [ ] No second Story aggregate on platform
* [ ] Eligibility mirrors HS.6 Story + Hero policies (+ theme requirement)
* [ ] No new discoverable lifecycle flag as source of truth
* [ ] Ranking remains deterministic (no ML)
* [ ] Fail-closed reflection behavior preserved
* [ ] Narrative themes remain Discovery-owned
* [ ] AdaptiveDiscoverySignals remain the only user-understanding input to candidates
* [ ] DiscoveryProfile not required
* [ ] Architecture + integration + regression suites green
* [ ] Phase 7 full HS migration not dragged into Slice 4

---

## 21. Planning investigation inventory

### Read / analyzed

* `J.2-Discovery-Platform-Foundation.md`, `J.1-Journey-Experience-Platform-Migration.md`, `PF.2-Platform-Architecture-Decisions.md` (Phase 7), `H.2-Platform-Migration.md` (context), HS.6/HS.8 plans & reports, D.1 plan
* Platform: Experience composer/ports, Discovery signal resolver/catalog, HeroStoryModule, seed catalog, ranker, `StoryCandidateRecord`, J.2 tests, architecture dependency tests, migrations `001`/`002`
* Flutter: `Story`/`Hero` aggregates, repositories (InMemory/File), `StoryDiscoverabilityPolicy`, `HeroDiscoverabilityPolicy`, `DiscoverStoriesUseCase`, `DiscoverStoriesCandidateAdapter`, HS.8 composer path, theme bridge, DiscoveryProfile aggregate (unwired)

### Remains uncertain until implementation

* Exact operational ingest of first non-seed platform candidates in deployed environments (process/tooling), given Phase 7 not started
* Whether any existing production-shaped Flutter file fixtures should be auto-projected in platform test bootstraps

These are operational/implementation uncertainties, not blockers for the architectural shape above.
