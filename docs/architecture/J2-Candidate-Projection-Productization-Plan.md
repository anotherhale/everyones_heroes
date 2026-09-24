# J.2 Candidate Projection Productization — Implementation Plan

- **Document type:** Architecture + Implementation Plan (planning only)
- **Status:** Implemented — J.2 Slice 5 candidate projection productization
- **Working name:** J.2.5 / Candidate Projection Productization
- **Baseline (code):** `main` @ `7392cd4` — Post-J.2 architecture reassessment (#63); Slice 4 at `4b84f0a` (#62)
- **Upstream:** [`Post-J2-Architecture-Reassessment.md`](./Post-J2-Architecture-Reassessment.md) (Candidate A), [`J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md`](./J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md), [`J.2-Discovery-Platform-Foundation.md`](./J.2-Discovery-Platform-Foundation.md)
- **Date:** 2026-09-24
- **Constraint:** Planning document retained as architecture record. Implementation authorized and completed separately (Slice 5).

---

## 1. Purpose

Close the **ingest gap** left by J.2 Slice 4 so that eligible owner-published Stories become durable rows in `discoverable_story_candidates` and can surface as `adaptive-story-{storyId}` on platform Today when AdaptiveDiscoverySignals overlap.

Slice 4 built:

* eligibility policy + facts
* Postgres projection schema + read/write adapter
* transitional `ProjectDiscoverableStoryCandidateUseCase`
* live Today read path through `DiscoverableStoryCandidatePort`

Slice 4 did **not** wire Flutter Story authority (publish / archive / visibility / classification) to that projection. Tests call the project use case directly. Production Today therefore fails closed to reflection whenever the table is empty.

This plan defines the **smallest architecture-consistent vertical** that productizes that transitional projection without Phase 7 Story migration, without a generalized CQRS/projection framework, and without a Personalization Engine.

---

## 2. Current J.2 State

### 2.1 Verified git facts (2026-09-24)

| Fact | Value |
|------|-------|
| Branch evaluated | `main` (synced with `origin/main`) |
| HEAD | `7392cd4` — Add Post-J.2 architecture reassessment and next-slice plan (#63) |
| J.2 Slice 4 implementation | `4b84f0a` — Implement J.2 Slice 4 live Story candidate discovery (#62) |
| J.2 Slice 4 plan | `db1225d` — Plan J.2 Slice 4 live Story candidate discovery architecture (#61) |
| J.2 Slices 1–3 | `5a0a279` — Implement J.2 Discovery and Story candidate foundation (#60) |
| Working tree at discovery | clean |

**Note:** Local checkouts may lag `origin/main`. Agents must `git fetch origin main` before treating HEAD as current.

### 2.2 Dual-stack authority (code truth)

| Concern | Authority today |
|---------|-----------------|
| Hero / Story / publish / archive | **Flutter** `lib/features/hero_story` (File / InMemory repos) |
| Journey / Reflection / evidence / patterns | **EH Platform** Postgres (when platform mode on) |
| Today Experience Selection | **EH Platform** `GET /v1/experiences/today` |
| Discoverable Story candidates (**read**) | **EH Platform** `discoverable_story_candidates` via `PostgresStoryCandidateSource` |
| Discoverable Story candidates (**write / ingest**) | **Transitional only** — `ProjectDiscoverableStoryCandidateUseCase`; **no API, no reactor, no Flutter caller** |
| Flutter local Today (offline) | Live `DiscoverStoriesUseCase` → `DiscoverStoriesCandidateAdapter` (aggregates, not projection) |

### 2.3 J.2 seams already in place (reuse; do not reinvent)

| Seam | Location | Role |
|------|----------|------|
| `StoryCandidateEligibilityFacts` | `eh_platform/.../story_candidate_eligibility_facts.dart` | Projection input (not aggregate) |
| `AdaptiveStoryCandidateEligibilityPolicy` | `eh_platform/.../adaptive_story_candidate_eligibility_policy.dart` | HS.6 + catalog-theme gates |
| `StoryCandidateRecord` | `eh_platform/.../story_candidate_record.dart` | Thin projection DTO |
| `DiscoverableStoryCandidateProjection` | port | `upsert` / `remove` / `exists` |
| `StoryCandidateSource` | port | `listCandidates()` |
| `ProjectDiscoverableStoryCandidateUseCase` | application | Eligibility → upsert or remove |
| `PostgresStoryCandidateSource` | infrastructure | Dual Source + Projection |
| `DiscoverableStoryCandidateAdapter` | application | Source → rank → Experience port |
| `DeterministicStoryRelevanceRanker` | application | Theme overlap → pattern boost → recency |
| `DiscoverableStoryCandidatePort` | Experience | Consumption boundary |
| `AdaptiveExperienceComposer` | Experience | `adaptive-story-{id}` or reflection |
| Migration `003_j2_discoverable_story_candidates.sql` | Postgres | Derived table |

### 2.4 Explicit absences (verified)

* No platform `Story` / `Hero` aggregates or Postgres `stories` / `heroes` tables
* No platform `StoryPublished` / `StoryArchived` event types
* No `DomainEventReactor` for Story publish/archive on Flutter or platform (`ReactorRegistration` is H.2-only)
* No Hero & Story HTTP surface on platform (`ApiRouter` mounts Life Journey + Experience only)
* No Flutter call from `PublishStoryUseCase` / `ArchiveStoryUseCase` into projection sync
* No `StoryCandidate` aggregate and none should be created

---

## 3. Current Candidate Lifecycle

### 3.1 Flutter (authoritative Story path)

```text
StoryBuilder / Capture / Classify
        ↓
Story (draft → processing → review → approved)
        ↓
PublishStoryUseCase
  → optional story.changeVisibility
  → story.publish()  // StoryPublished(storyId, heroId)
  → StoryRepository.save
  → EventBus.publish(StoryPublished)
        ↓
DiscoverStoriesUseCase + StoryDiscoverabilityPolicy
  (+ HeroDiscoverabilityPolicy, authoritativeRepresentationsOnly)
        ↓
DiscoverStoriesCandidateAdapter
        ↓
DiscoverableStoryCandidatePort (Flutter local Today only)
```

Archive:

```text
ArchiveStoryUseCase
  → story.archive()  // StoryArchived(storyId)
  → save + EventBus
  → Story no longer discoverable via Discover*
```

**Discoverability is query-time on Flutter.** There is no candidate table on Flutter. Policies derive eligibility from aggregate state.

### 3.2 Platform (derived projection path — Slice 4)

```text
StoryCandidateEligibilityFacts  (caller-supplied; tests today)
        ↓
ProjectDiscoverableStoryCandidateUseCase
  → AdaptiveStoryCandidateEligibilityPolicy.evaluate
  → upsert StoryCandidateRecord  OR  remove(storyId)
        ↓
discoverable_story_candidates (Postgres)
        ↓
PostgresStoryCandidateSource.listCandidates
        ↓
DiscoverableStoryCandidateAdapter + DeterministicStoryRelevanceRanker
        ↓
DiscoverableStoryCandidatePort.findRelevant
        ↓
ExperienceApplicationService.getTodayExperience
        ↓
AdaptiveExperienceComposer
        ↓
TodayExperienceDto id = adaptive-story-{storyId} | reflection fallback
```

### 3.3 What makes a candidate discoverable (platform)

`AdaptiveStoryCandidateEligibilityPolicy` (mirrors HS.6 + adaptive theme gate):

1. `lifecycleStatus == published`
2. Story visibility ∈ `{public, community}`
3. `!hasProvisionalNarrative`
4. `hasAuthoritativeRepresentation`
5. `heroStatus == active`
6. Hero visibility ∈ `{public, community}`
7. ≥1 catalog-valid `NarrativeThemeReferenceIds` theme

There is **no** separate `isDiscoverable` flag. Eligibility is always derived.

### 3.4 Authoritative vs transitional

| Layer | Status |
|-------|--------|
| Flutter `Story` / `Hero` | **Authoritative** lifecycle + catalog |
| `discoverable_story_candidates` | **Derived** read model; authoritative **only for Experience selection on platform** |
| `ProjectDiscoverableStoryCandidateUseCase` | **Transitional sync** (Slice 4 comments; Phase 7 replacement path documented) |
| Seeded catalog | **Test fixture only** — not production default after Slice 4 |

### 3.5 Publish / archive representation today

| Concern | Representation |
|---------|----------------|
| Publish | Flutter `Story.publish()` → `StoryLifecycleStatus.published` + `StoryPublished` |
| Archive | Flutter `Story.archive()` → `archived` + `StoryArchived` |
| Republish | Lifecycle matrix allows `archived → published` via `publish()` again |
| Visibility change | `Story.changeVisibility` / `Hero.changeVisibility` — **no dedicated domain events** |
| Classification | `Story.classify` → `StoryClassified` |
| Projection membership | **Not** updated by any of the above |

Publishing **does** emit a domain event on Flutter (`StoryPublished`). That event currently has **no reactors** and does **not** reach the platform projection.

### 3.6 Persistence today

| Data | Where |
|------|-------|
| Story / Hero | Flutter File JSON / InMemory |
| Candidate projection | Platform Postgres `discoverable_story_candidates` |
| Slice 4 projection population | In-process UC call (tests / manual) — **not** product ingest |

### 3.7 What Today consumes

| Mode | Candidate input |
|------|-----------------|
| Platform (`EH_PLATFORM_URL`) | `PlatformGetTodayExperienceUseCase` → `GET /v1/experiences/today` → Postgres projection (via port) |
| Flutter local | `DiscoverStoriesCandidateAdapter` → live Discover* over Flutter aggregates |

**Platform Today already depends on the transitional projection table**, not on Flutter Story repositories. Empty table ⇒ always reflection. Productizing ingest does **not** require changing the Today composer contract.

---

## 4. Current Transitional Projection

### 4.1 Schema (`003_j2_discoverable_story_candidates.sql`)

```sql
discoverable_story_candidates (
  story_id TEXT PRIMARY KEY,
  hero_id TEXT NOT NULL,
  title TEXT NOT NULL,
  theme_ids JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  story_visibility TEXT,          -- optional diagnostics
  hero_visibility TEXT,           -- optional diagnostics
  projected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
-- indexes: updated_at DESC; GIN(theme_ids)
```

### 4.2 Writer / reader

`PostgresStoryCandidateSource` implements both `StoryCandidateSource` and `DiscoverableStoryCandidateProjection`. Upsert is `ON CONFLICT (story_id) DO UPDATE` (naturally idempotent).

`ProjectDiscoverableStoryCandidateUseCase` currently calls `upsert(record)` **without** filling `story_visibility` / `hero_visibility` (those exist via `upsertWithEligibilityMeta` but are unused by the UC). Productization should prefer writing diagnostic visibility columns when facts are available — still non-authoritative.

### 4.3 Module wiring

`HeroStoryModule.composePostgres` exposes `projectCandidate` on `HeroStoryComponents`, but `PlatformComposition` does **not** mount any Hero & Story API. Experience only receives `storyCandidatePort`.

### 4.4 Sequence / data-flow (current gap)

```text
┌──────────────────────────── Flutter ────────────────────────────┐
│  Owner PublishStoryUseCase                                      │
│       │                                                         │
│       ├─► StoryRepository.save (authoritative)                  │
│       └─► EventBus(StoryPublished) ──► (no reactors)            │
│                                                                 │
│  Local Today (offline): Discover* ──► adaptive-story-*          │
└─────────────────────────────────────────────────────────────────┘

                         ✗ no ingest path

┌────────────────────────── EH Platform ──────────────────────────┐
│  discoverable_story_candidates  ◄── Project UC (tests only)     │
│       │                                                         │
│       ▼                                                         │
│  StoryCandidateSource → Port → Ranker → Composer                │
│       │                                                         │
│       ▼                                                         │
│  GET /v1/experiences/today → adaptive-story-* | reflection      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Architectural Boundary

### 5.1 Decision (preserve current design)

| Question | Decision |
|----------|----------|
| Who owns publish / archive? | **Flutter `Story` aggregate** via existing `PublishStoryUseCase` / `ArchiveStoryUseCase` |
| Is there a Story Candidate aggregate? | **No.** Do not create one. |
| Who owns the projection? | **Hero & Story platform module** (derived read model) |
| Who owns Experience selection? | **Experience application module** (consumes port only) |
| Who owns NarrativeTheme vocabulary? | **Discovery** (catalog IDs only on the projection) |
| Does Experience write candidates? | **Never** |

### 5.2 Publish / archive boundary verdict

**Publish and archive remain Story aggregate lifecycle operations on Flutter.**

Candidate projection membership is a **derived consequence** evaluated by `AdaptiveStoryCandidateEligibilityPolicy` from eligibility facts — not a parallel lifecycle owned by a Candidate aggregate or by Experience.

Application orchestration (not a new domain event type, not Experience) owns the sync call into `ProjectDiscoverableStoryCandidateUseCase`.

### 5.3 Ambiguity check

| Ambiguity | Resolution for this slice |
|-----------|---------------------------|
| HTTP sync vs platform reactor | **HTTP command from Flutter** — Story events remain Flutter-local; platform has no Story aggregate to raise them. Prefer honesty about dual-stack over fake event theater. |
| New `StoryCandidateProjected` event? | **No** unless a second consumer appears. Projection is an application side-effect of eligibility sync. |
| Visibility / classify without lifecycle event | Sync must also run after **Hero visibility**, **Story classification** (themes), and any future Story visibility use case when story is published — eligibility can change without `StoryPublished`. |
| Auth identity linking owner User ↔ Hero | Existing platform auth is bearer session (Identity lite). Ingest API should require auth like other module routes; do **not** invent Hero ownership enforcement beyond current Identity lite unless an existing ownership check already exists. Document as open residual risk (see §19). |

No genuine aggregate-ownership ambiguity blocks implementation: **do not** introduce a Candidate aggregate to “clean up” dual-stack.

---

## 6. Publish / Archive Lifecycle

### 6.1 Existing Flutter transitions (unchanged)

```text
approved ──publish()──► published ──archive()──► archived
                              ▲                     │
                              └────── publish() ────┘  (republish allowed)
```

Publish invariants (existing): non-private/draft visibility, publication consent, non-provisional narrative.

### 6.2 Projection membership (derived)

```text
eligible facts  → upsert discoverable_story_candidates
ineligible facts → DELETE row (idempotent no-op if absent)
```

Ineligible includes: archived, suspended, removed, non-discoverable visibility, inactive/non-discoverable Hero, missing catalog themes, provisional narrative, missing authoritative representation.

### 6.3 Sync trigger points (minimum product set)

| Flutter mutation | Sync required? | Why |
|------------------|----------------|-----|
| `PublishStoryUseCase` success | **Yes** | Primary ingest path |
| `ArchiveStoryUseCase` success | **Yes** | Must remove / invalidate |
| `ChangeHeroVisibilityUseCase` success | **Yes** | Hero visibility gates eligibility for all owned published stories |
| `ClassifyStoryUseCase` success (when published) | **Yes** | Theme IDs drive ranking / eligibility |
| Story visibility change while published | **Yes if/when a dedicated UC exists** | Today visibility is mainly set at publish; still map if added |
| Submit / Approve only | No | Not published yet |
| Platform Today GET | No | Read-only composition |

### 6.4 Platform mode gating

Sync should run when `EhPlatformConfig.usePlatformAuthority` (or equivalent “platform configured”) is true. Offline / local Flutter Today continues to use Discover* and must not fail if platform is unreachable for projection sync — see §11.

---

## 7. Proposed Durable Projection

### 7.1 Minimum durable row (already established)

Reuse existing table and `StoryCandidateRecord` fields. **Do not add speculative ranking / personalization columns.**

| Field | Source | Required |
|-------|--------|----------|
| `story_id` | Story.id | Yes (PK) |
| `hero_id` | Story.heroId | Yes |
| `title` | Story title string | Yes |
| `theme_ids` | Catalog-filtered NarrativeThemeIds | Yes (≥1 when row exists) |
| `updated_at` | Story.updatedAt (UTC) | Yes |
| `story_visibility` | StoryVisibility.name | Optional diagnostic |
| `hero_visibility` | HeroVisibility.name | Optional diagnostic |
| `projected_at` | DB `NOW()` on upsert | Yes (server-set) |

### 7.2 Eligibility facts payload (ingest contract)

Reuse `StoryCandidateEligibilityFacts` as the platform command body shape (JSON mirror of existing Dart fields). No second DTO family unless HTTP layer needs a thin request wrapper.

| Field | Maps from Flutter |
|-------|-------------------|
| `storyId` | `Story.id.value` |
| `heroId` | `Story.heroId.value` |
| `title` | Story title |
| `themeIds` | `classification.narrativeThemeIds` (`.value`) |
| `updatedAt` | `Story.updatedAt` ISO-8601 UTC |
| `lifecycleStatus` | `StoryLifecycleStatus.name` |
| `storyVisibility` | `StoryVisibility.name` |
| `hasProvisionalNarrative` | `Story.hasProvisionalNarrative` |
| `hasAuthoritativeRepresentation` | any representation with `isAuthoritative` |
| `heroStatus` | `HeroStatus.name` |
| `heroVisibility` | `HeroVisibility.name` |

### 7.3 Explicitly excluded from projection

* Suitability / spirituality / subjects / challenges / outcomes
* Media URLs / representations payloads
* Relevance scores / pattern boosts (computed at read time)
* DiscoveryProfile / Influence fields
* Source Story blob / version vector / event store position

`projected_at` is sufficient “when last synced” metadata. Do not invent a generalized source-version framework for this slice.

### 7.4 Today-required fields

Composer needs from ranked `DiscoverableStoryCandidate`: `storyId`, `title`, `matchedThemeIds`, `themeOverlapCount`, `patternBoost`, `updatedAt`. Ranker derives overlap/boost from projection `theme_ids` + signals. **No Today schema change.**

---

## 8. Application Flow

### 8.1 Intended product flow (names from code)

```text
PublishStoryUseCase (Flutter)
  → Story.publish + StoryRepository.save + EventBus(StoryPublished)
  → SyncDiscoverableStoryCandidate (Flutter application helper / port call)
       → map Story + Hero → eligibility facts
       → EhPlatformClient.projectDiscoverableStoryCandidate(facts)
            → PUT|POST /v1/hero-story/candidates/{storyId}   (new thin API)
                 → ProjectDiscoverableStoryCandidateUseCase.execute(facts)
                      → AdaptiveStoryCandidateEligibilityPolicy
                      → DiscoverableStoryCandidateProjection.upsert|remove
                           → PostgresStoryCandidateSource
  → (owner UX continues; sync failure does not roll back publish)

Seeker opens Home (platform mode)
  → PlatformGetTodayExperienceUseCase
  → GET /v1/experiences/today
  → ExperienceApplicationService
       → AdaptiveDiscoverySignalPort.resolve
       → DiscoverableStoryCandidatePort.findRelevant
       → AdaptiveExperienceComposer
  → adaptive-story-{storyId} when theme overlap > 0
```

Archive:

```text
ArchiveStoryUseCase
  → Story.archive + save + StoryArchived
  → SyncDiscoverableStoryCandidate(facts with lifecycle=archived)
       → Project UC → remove(storyId)
```

### 8.2 Recommended Flutter orchestration shape

Prefer a **small application collaboration** over mutating domain aggregates:

* Option A (preferred): thin `SyncDiscoverableStoryCandidatePort` + adapter; invoked at end of publish/archive/hero-visibility/classify use cases (or a dedicated owner composition wrapper used by presentation — same pattern as HS.FG.1 owner path).
* Option B: Flutter reactor on `StoryPublished` / `StoryArchived` that calls the sync port.

**Prefer Option A** for visibility/classify (no events) and for explicit failure handling. Option B alone is insufficient.

Do **not** put HTTP calls inside the `Story` aggregate.

### 8.3 Platform application shape

* Keep `ProjectDiscoverableStoryCandidateUseCase` as the sole write orchestrator.
* Add thin `HeroStoryApi` (or `DiscoverableStoryCandidateApi`) that deserializes facts → UC.execute → JSON result.
* Wire `projectCandidate` from `HeroStoryComponents` into `ApiRouter` cascade (auth-protected like Life Journey / Experience).

---

## 9. Event Flow

### 9.1 Existing events (reuse; do not replace)

```text
Flutter Story.publish  → StoryPublished(storyId, heroId)
Flutter Story.archive  → StoryArchived(storyId)
Flutter Story.classify → StoryClassified(storyId)
```

These remain **Flutter-local facts**. They do not automatically become platform events in this slice.

### 9.2 Projection sync is application-driven

```text
Flutter UC success
  → SyncDiscoverableStoryCandidatePort.sync(facts)
  → Platform ProjectDiscoverableStoryCandidateUseCase
  → Postgres upsert/remove
```

### 9.3 Events explicitly **not** introduced

* `StoryCandidateProjected`
* `DiscoverableStoryCandidateUpserted`
* Platform clones of `StoryPublished` / `StoryArchived`
* Experience selection events

Phase 7 may replace HTTP sync with platform Story authority + reactors; that replacement path is already documented in Slice 4 and remains out of scope.

---

## 10. Postgres Changes

### 10.1 Migrations

| Change | Required? |
|--------|-----------|
| New migration for core candidate columns | **No** — reuse `003_j2_discoverable_story_candidates.sql` |
| New stories/heroes tables | **No** |
| Alter for ranking/personalization | **No** |
| Optional: populate visibility diagnostics via existing columns | **Yes (code only)** — use `upsertWithEligibilityMeta` from Project UC or extend upsert |

If implementation discovers a hard need for an ingest audit column, prefer documenting it as a follow-up rather than expanding scope. Do **not** invent outbox tables.

### 10.2 Indexes / constraints (already present)

* PK `story_id`
* `idx_discoverable_story_candidates_updated_at`
* GIN `theme_ids`

No new indexes required for Slice productization at current load-all ranking.

### 10.3 Repository / port methods (reuse)

| Port / type | Methods |
|-------------|---------|
| `DiscoverableStoryCandidateProjection` | `upsert`, `remove`, `exists` |
| `StoryCandidateSource` | `listCandidates` |
| `PostgresStoryCandidateSource` | SQL INSERT…ON CONFLICT; DELETE; SELECT |

### 10.4 Serialization

* Theme IDs: JSONB array (existing `jsonEncode` / decode)
* Timestamps: UTC `TIMESTAMPTZ`
* HTTP body: JSON object mirroring `StoryCandidateEligibilityFacts`

### 10.5 Migration test requirements

Reuse patterns from `j2_live_candidate_discovery_test.dart` / `h2_postgres_integration_test.dart`:

* Table exists after migrate
* Upsert round-trip
* Remove clears discoverability
* Idempotent re-upsert
* Clean migrate smoke includes `discoverable_story_candidates` (already listed in Slice 4 tooling)

No new migration file ⇒ no new migration-number test unless a schema change is later justified.

### 10.6 Idempotency store

Reuse PF.3 `command_idempotency` + `Idempotency-Key` header pattern from Life Journey submit for the ingest HTTP command when practical. Projection upsert is already idempotent by PK; idempotency store primarily protects duplicate HTTP command side effects / response replay consistency.

---

## 11. Failure and Idempotency Semantics

Keep proportional to dual-stack reality. Do **not** introduce transactional outbox / Kafka.

| Scenario | Behavior |
|----------|----------|
| **Publish succeeds, projection fails** | Flutter publish remains committed (Story authority). Sync returns soft failure / logged error. Owner UX may show non-blocking warning when platform mode is on. Retry on next relevant mutation or explicit retry helper. Do **not** roll back Story.publish. |
| **Duplicate publication / duplicate sync** | Upsert `ON CONFLICT` overwrites same `story_id`. Optional `Idempotency-Key` returns prior success. Safe. |
| **Archive after publication** | Sync with archived lifecycle → Project UC `remove`. DELETE is idempotent. |
| **Republish (`archived → published`)** | Sync with published eligible facts → upsert again. Supported by existing lifecycle matrix. |
| **Stale projections** | Last successful sync wins. `projected_at` refreshes. No multi-version concurrency control in this slice. |
| **Missing source Story on Flutter** | Publish/Archive UC already fails before sync. Ingest API trusts caller-supplied facts (platform has no Story to verify). |
| **Ineligible publish attempt** | If somehow facts are ineligible, Project UC removes any prior row and reports `wasUpserted: false` — correct. |
| **Hero made private** | Sync all affected published stories for that Hero (or sync-on-read deferred — **prefer explicit sync of owned published stories** in `ChangeHeroVisibilityUseCase` composition). Minimum: sync each published story id for that hero. |
| **Transaction boundaries** | Flutter Story save and platform projection write are **separate** transactions / processes. Accept eventual consistency for this transitional dual-stack seam. |
| **Platform unreachable (offline)** | Skip or queue-best-effort; local Discover* Today still works. Do not block owner publish. |
| **Idempotency** | PK upsert + optional HTTP idempotency key. Project UC remove when ineligible is safe to repeat. |

---

## 12. Today Integration

### 12.1 No composer / presentation redesign

Platform Today already:

```text
ExperienceApplicationService
  → DiscoverableStoryCandidatePort.findRelevant
  → AdaptiveExperienceComposer
  → id: adaptive-story-{storyId}
```

Flutter platform mode already:

```text
PlatformGetTodayExperienceUseCase → EhPlatformClient.getTodayExperience
```

**Presentation changes are out of scope unless a smoke demo requires wiring owner publish to call sync.** Prefer application-layer sync from use cases so UI stays thin.

### 12.2 Acceptance path for adaptive-story

1. Owner publishes eligible Story (themes overlap seeker’s signals)
2. Projection row exists
3. Seeker with catalog-aligned reflection themes opens Today
4. `GET /v1/experiences/today` returns `adaptive-story-{storyId}`
5. Empty / no overlap still fails closed to reflection

### 12.3 Flutter local Today

Unaffected. Continues Discover* over aggregates. Dual-stack temporary difference remains acceptable until Phase 7.

---

## 13. Test Strategy

Define tests that establish architectural behavior — not HTTP framework trivia.

### Domain (platform)

* Existing eligibility policy tests remain green (`j2_candidate_eligibility_test.dart`)
* Add/extend only if facts mapping introduces new derived fields (unlikely)

### Application (platform)

* Existing `ProjectDiscoverableStoryCandidateUseCase` upsert/remove tests remain green
* Prefer writing visibility diagnostics if UC updated — assert meta columns when using Postgres
* New API handler tests: valid facts → upsert; ineligible → remove; auth required

### Application (Flutter)

* Mapper: `Story` + `Hero` → eligibility facts (field parity with policy expectations)
* Publish success + platform configured → sync port invoked with published facts
* Archive success → sync with archived lifecycle (or explicit remove path)
* Hero visibility change → sync invoked for owned published stories
* Classify published story → sync with updated theme IDs
* Publish success + platform sync failure → Story still published (Result success); sync error surfaced/logged without rollback
* Platform not configured → no sync call

### Infrastructure

* Postgres upsert/remove/idempotent re-upsert (extend `j2_live_candidate_discovery_test` patterns)
* HTTP ingest → Project UC → table row visible to `listCandidates`

### Integration

* Published eligible candidate → Today `adaptive-story-*` when signals overlap (platform composition)
* Archived candidate disappears from discovery / Today falls back to reflection
* Seed catalog **not** required for the path

### Presentation

* Only if owner publish screen currently bypasses the application sync composition — then a focused provider/use-case wiring test. No new Discover UI.

### Architecture dependency

* Existing `architecture_dependency_test.dart` constraints remain: Experience must not import Story aggregates; HS projection must not own Experience selection.

---

## 14. Files / Modules Affected

### Likely to add

| Area | Candidate path |
|------|----------------|
| Platform API | `services/eh_platform/lib/src/api/hero_story_api.dart` (name flexible; thin) |
| Flutter mapper | `lib/features/hero_story/application/mappers/story_candidate_eligibility_facts_mapper.dart` |
| Flutter sync port | `lib/features/hero_story/application/ports/sync_discoverable_story_candidate_port.dart` |
| Flutter sync adapter | `lib/features/hero_story/infrastructure/platform/platform_sync_discoverable_story_candidate_adapter.dart` |
| Flutter tests | mapper + publish/archive sync collaboration tests |
| Platform tests | API ingest + integration extension under `test/j2_*` |

### Likely to change

| File | Change |
|------|--------|
| `services/eh_platform/lib/src/api/api_router.dart` | Mount Hero & Story candidate ingest routes |
| `services/eh_platform/lib/src/platform_composition.dart` | Pass `projectCandidate` into API |
| `services/eh_platform/lib/src/modules/hero_story/hero_story_module.dart` | Expose API composition helper if needed |
| `ProjectDiscoverableStoryCandidateUseCase` | Optionally write visibility diagnostics via `upsertWithEligibilityMeta` |
| `lib/.../eh_platform_client.dart` | `projectDiscoverableStoryCandidate` HTTP method |
| `PublishStoryUseCase` and/or owner composition | Invoke sync after success |
| `ArchiveStoryUseCase` and/or owner composition | Invoke sync after success |
| `ChangeHeroVisibilityUseCase` / classify path | Invoke sync when platform on |
| Providers under `owned_story_use_case_providers.dart` | Wire sync port |
| `services/eh_platform/README.md` | Document candidate ingest route |
| Focused docs listed in §18 | After implementation |

### Unlikely / do not touch

* `AdaptiveExperienceComposer` contract
* Ranking algorithm
* Migration `001` / `002`
* Story / Hero aggregate redesign
* DiscoveryProfile / D.1
* Seed catalog production reintroduction

### Migrations

* **None required** for baseline productization (reuse `003`)

### Documentation (this PR)

* **This plan only**

---

## 15. Implementation Sequence

1. **Flutter mapper** Story+Hero → eligibility facts (+ unit tests)
2. **Platform API** thin ingest → existing `ProjectDiscoverableStoryCandidateUseCase` (+ handler tests)
3. **Wire ApiRouter + PlatformComposition** (+ auth)
4. **EhPlatformClient** method + Flutter sync port/adapter
5. **Hook publish / archive** success paths (platform-gated)
6. **Hook hero visibility + classify** (published) success paths
7. **Optional:** Project UC writes visibility diagnostics
8. **Integration tests:** publish facts → Postgres → Today adaptive-story; archive → reflection
9. **Analyzer + focused j2 / Flutter tests**
10. **Short implementation note** updating J.2 foundation / Slice 4 status + drift/debt IDs (see §18)

Do not start with Phase 7 Story tables or event-sourcing infrastructure.

---

## 16. Definition of Done

1. Eligible Flutter publish (platform configured) results in a `discoverable_story_candidates` row.
2. Archive (or otherwise ineligible facts) removes / omits that row.
3. Hero visibility / classification changes that break or restore eligibility refresh the projection.
4. `GET /v1/experiences/today` can return `adaptive-story-{storyId}` for overlapping catalog themes **without** the architectural seed catalog.
5. Empty / ineligible / no-overlap cases still fail closed to default reflection.
6. Publish is not rolled back when projection sync fails; failure is observable/logged.
7. No Story/Hero aggregate migration to platform; no new Candidate aggregate; no GrowthOpportunity / Personalization Engine / public Discovery REST.
8. `dart analyze` clean on touched packages; focused platform j2 + Flutter sync tests pass; relevant broader suite green.
9. Short post-implementation note records sync mechanism (HTTP command) and Phase 7 replacement path.
10. Documentation updates in §18 applied (minimal; no unrelated rewrites).

---

## 17. Explicit Non-Goals

Do **not** include in this slice:

* Growth Opportunity Detection / Narrative Guidance Engine
* Personalization Engine or ML ranking
* Generalized adaptive-experience framework beyond existing composer
* **D.1** DiscoveryProfile platform productization (unless a hard dependency appears — it does **not**; signals already exist)
* PF.2 Phase 7 full Hero & Story platform authority migration
* Broad architecture cleanup (orphan `PatternsDetected`, duplicate `BasePatternRule`, etc.)
* Generalized CQRS / event sourcing / projection framework / outbox
* Speculative ranking / recommendation algorithms beyond `DeterministicStoryRelevanceRanker`
* Unrelated Story Builder work (SB proposal aggregate promotion, coach changes)
* Public Discovery REST / Influence marketplace
* Second Story source of truth on platform
* Suitability filtering on the adaptive projection
* Kafka / message bus introduction

---

## 18. Documentation Updates

Update **after implementation** (not as a substitute for this plan):

| Document | Update |
|----------|--------|
| `J.2-Discovery-Platform-Foundation.md` | Mark candidate ingest productized; note HTTP sync transitional |
| `J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md` | Point to productized ingest; keep Phase 7 replacement path |
| `Post-J2-Architecture-Reassessment.md` | Reference implementation outcome when done (optional status line) |
| `architecture-drift.md` | Open/close **DRIFT-012** (StoryPublished ↛ projection) when sync lands |
| `technical-debt.md` | Add/close **TD-J2-001** candidate projection sync |
| `event-flow.md` | Document application sync path (not fake platform Story events) |
| `repository-map.md` | Note projection writer + ingest API |
| `use-case-map.md` | Project UC + Flutter sync collaboration |
| `services/eh_platform/README.md` | Candidate ingest route |
| HS Master Plan / Roadmap | Cross-link platform adaptive ingest vs Flutter catalog handoff |

### ADR?

**No new ADR required** if implementation preserves Slice 4 decisions:

* Projection is derived, not a Story aggregate
* Experience consumes port only
* Sync is transitional until Phase 7

An ADR is warranted **only if** implementation chooses a materially different sync topology (e.g. shared DB writes from Flutter, or promoting Experience to own projection writes). Prefer preserving the reassessment’s HTTP-command recommendation.

Do **not** rewrite `AGENTS.md` / maps merely because this plan exists; refresh authorization language when the slice ships or in a dedicated docs pass.

---

## 19. Open Questions

Resolved enough to implement unless marked **blocking**:

| # | Question | Proposed default | Blocking? |
|---|----------|------------------|-----------|
| 1 | Sync transport before Phase 7? | **HTTP command** Flutter → platform Project UC | No — default locked by dual-stack |
| 2 | Exact HTTP verb/path? | `PUT /v1/hero-story/candidates/{storyId}` with facts body (or POST upsert); DELETE optional because ineligible PUT already removes | No — implementer may pick consistent Shelf style |
| 3 | Sync on Hero visibility for many stories? | Load `findByHeroId`, sync each published story | No |
| 4 | Owner identity authorization on ingest? | Require bearer auth; defer strict Hero-ownership checks to Identity↔Hero linkage maturity | **Residual risk** — document; do not invent Identity BC |
| 5 | Should sync failure surface in owner UI? | Non-blocking log + optional soft warning | No |
| 6 | Populate visibility diagnostic columns now? | Yes, if cheap via existing `upsertWithEligibilityMeta` | No |
| 7 | Flutter reactor vs explicit UC hooks? | Explicit hooks / composition (covers classify + hero visibility) | No |
| 8 | Current Journey dual definition? | Out of scope for this slice | No |
| 9 | Content-aware theme resolution beyond `discovery`? | Out of scope (Candidate B in reassessment) | No |

**No stop-condition ambiguity on aggregate ownership.** Proceed under the defaults above when implementation is authorized.

---

## Implementation Readiness Verdict

### 1. Is the boundary clear enough to implement?

**Yes.** Publish/archive stay on the Flutter `Story` aggregate. The candidate projection remains a Hero & Story–owned derived read model on platform. Experience continues to consume `DiscoverableStoryCandidatePort` only. No Candidate aggregate is required or justified.

### 2. What existing abstractions should be reused?

* `StoryCandidateEligibilityFacts` + `AdaptiveStoryCandidateEligibilityPolicy`
* `ProjectDiscoverableStoryCandidateUseCase`
* `DiscoverableStoryCandidateProjection` / `StoryCandidateSource` / `PostgresStoryCandidateSource`
* Migration `003` table + indexes
* `DiscoverableStoryCandidateAdapter` + `DeterministicStoryRelevanceRanker`
* `AdaptiveExperienceComposer` + `GET /v1/experiences/today`
* Flutter `PublishStoryUseCase` / `ArchiveStoryUseCase` / `ChangeHeroVisibilityUseCase` / `ClassifyStoryUseCase`
* `EhPlatformClient` + `EhPlatformConfig` platform gating
* PF.3 auth + optional `command_idempotency`

### 3. What, if anything, must be changed before implementation?

**Nothing architectural must be redesigned first.** Missing pieces are productization wiring only:

* Platform ingest HTTP surface for the existing Project UC
* Flutter facts mapper + sync port
* Hooks after publish/archive/(hero visibility|classify)

Optional non-blocking hygiene: have Project UC write visibility diagnostics already present on the table.

### 4. What is the smallest complete vertical slice?

```text
Flutter Publish/Archive (existing)
  → eligibility facts mapper
  → HTTP ingest
  → ProjectDiscoverableStoryCandidateUseCase
  → discoverable_story_candidates
  → DiscoverableStoryCandidatePort
  → Today adaptive-story-*
```

That single path — plus archive removal and the eligibility-affecting visibility/classify hooks — is the complete productization slice.

### 5. Are there any architectural risks that warrant another reassessment before coding?

**No full reassessment needed.** Residual risks are acceptable for a transitional dual-stack seam:

* Eventual consistency between Flutter Story save and platform projection
* Ingest API trusts caller-supplied facts (no platform Story to verify)
* Identity lite may not yet enforce Hero ownership on ingest

These are documented dual-stack limitations already accepted by PF.2 / J.2 Slice 4, not new architectural contradictions. Phase 7 remains the proper place to replace transitional sync with platform Story authority + reactors.

---

*End of plan. Planning-only — no implementation authorized by this document.*
