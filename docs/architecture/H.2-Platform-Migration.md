# H.2 Platform Migration

- **Document type:** Architecture / Implementation Report
- **Status:** Implemented — H.2 integrated onto the PF.3 platform foundation
- **Phase:** PF.3 foundation + H.2 Life Journey module
- **Date:** 2026-09-23
- **Platform location:** `services/eh_platform` (Dart modular monolith per PF.2 ADR-003)
- **Related:** `docs/architecture/PF.2-Platform-Architecture-Decisions.md`, `docs/architecture/PF.3-Platform-Foundation.md`, `docs/architecture/Everyone's-Heroes-H2-Architecture-Updated.md`, `AGENTS.md` §10

---

## Purpose

This document records the **H.2 Platform Migration** as implemented: moving authoritative Behavioral Understanding (Reflection submit → analysis → evidence → pattern detection → Journey pattern ownership) from the Flutter in-process EventBus onto the **EH Platform**.

It is the source-of-truth description of:

1. What H.2 looked like **before** migration (client-owned, in-memory).
2. What moved, what was reimplemented, what stayed on the client, and what was deferred.
3. The **target** platform architecture, HTTP API, event flow, and persistence model.
4. Authority transition, transitional compatibility, testing, equivalence, limitations, and completion criteria.

### Relationship to PF.2 / PF.3

PF.2 (`PF.2-Platform-Architecture-Decisions.md`) planned:

* **Phase 2** — Platform foundation + Identity lite + PostgreSQL
* **Phase 3** — Reflection / H.2 migration

**PF.3** (`PF.3-Platform-Foundation.md`, PR `#55`) landed on `main` as the authoritative platform foundation while H.2 had independently scaffolded `services/eh_platform`. Those branches were **merged by rehoming H.2 onto PF.3** — not by keeping two parallel runtimes.

| Concern | Owner after integration |
|---------|-------------------------|
| Platform composition / server startup | **PF.3** `PlatformComposition` / `runPlatformServer` |
| API router, Identity, shared Result/Clock | **PF.3** |
| UnitOfWork, migrations, command_idempotency | **PF.3** |
| EventBus / EventStore / EventDispatcher | **PF.3** `lib/src/events/` |
| Life Journey domain + H.2 application behavior | **H.2** under `modules/life_journey` + `life_journey/` |
| Flutter | **Client only** (`EhPlatformClient`) |

### Non-goals honored

This phase did **not** migrate:

* Experience Selection / Today’s Experience (UI.3 remains client-side)
* Discovery context (Influences, NarrativeTheme entities)
* Hero & Story (HS.*)
* AI proxy / production AI orchestration
* Kafka, outbox workers, Rust, or microservices

---

## 1. Previous H.2 architecture

Before migration, H.2 lived entirely inside the Flutter app as an **in-process, in-memory** Life Journey capability.

### Ownership

| Concern | Owner |
|---------|--------|
| Reflection aggregate | Flutter `lib/features/life_journey/domain/aggregates/reflection.dart` |
| Journey aggregate (incl. `behaviorPatterns`) | Flutter `lib/features/life_journey/domain/aggregates/journey.dart` |
| Submit / Analyze / Detect use cases | Flutter application layer |
| Reactors | Flutter `EventDispatcher` via `lib/bootstrap/reactor_registration.dart` |
| EventBus / EventStore | Flutter in-process (`lib/` core eventing) |
| Persistence | In-memory Journey / Reflection repositories |
| Narrative themes | `FakeNarrativeThemeResolver` (port; Discovery not authoritative) |
| Experience Selection | Flutter `DeterministicExperienceSelectionService` (UI.3) — **unchanged / not part of H.2 ownership** |

### Layering (Flutter)

```text
Presentation (Riverpod)
        ↓
Application (use cases, reactors)
        ↓
Domain (Journey, Reflection, PatternDetector, PatternRule, …)
        ↑
Infrastructure (in-memory repos, EmojiBehavioralEvidenceAnalyzer, RuleBasedPatternDetector)
```

### Naming (code is authoritative)

H.2 code uses:

* `DetectPatternUseCase` / `DefaultDetectPatternUseCase`
* `PatternDetector` / `RuleBasedPatternDetector`

**Not** `DetectBehaviorPatternsUseCase` / `BehaviorPatternDetector` (documentation drift in older maps).

### Key Flutter paths (pre-migration / transitional local path)

| Role | Path |
|------|------|
| Submit | `lib/features/life_journey/application/use_cases/submit_reflection_use_case.dart` |
| Analyze | `lib/features/life_journey/application/use_cases/analyze_reflection_use_case.dart` |
| Detect | `lib/features/life_journey/application/use_cases/detect_pattern_use_case.dart` |
| ReflectionSubmitted reactor | `lib/features/life_journey/application/reactors/reflection/reflection_submitted_reactor.dart` |
| BehavioralEvidenceDetected reactor | `lib/features/life_journey/application/reactors/behavioral_evidence_detected_reactor.dart` |
| Reactor wiring | `lib/bootstrap/reactor_registration.dart` |
| Pattern detector | `lib/features/life_journey/infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart` |
| Emoji evidence analyzer | `lib/features/life_journey/infrastructure/services/behavioral_analysis/emoji_behavioral_evidence_analyzer.dart` |
| Fake theme resolver | `lib/features/life_journey/application/providers/fake/fake_narrative_theme_resolver.dart` |
| Orphan event (not part of live chain) | `lib/features/life_journey/domain/events/patterns_detected.dart` (`PatternsDetected`) |

---

## 2. Actual event flow before migration

Verified from Flutter code (local transitional path still implements this when platform authority is off):

```text
UI / provider
    ↓
SubmitReflectionUseCase (DefaultSubmitReflectionUseCase)
    ↓
Reflection.submit()
    ↓
ReflectionSubmitted  ──publish──► EventBus
    ↓
ReflectionSubmittedReactor
    ↓
AnalyzeReflectionUseCase
    ├── RuleBasedInsightExtractionService → Insights (+ InsightsGenerated)
    ├── BehavioralEvidenceAnalysisOrchestrator
    │       └── EmojiBehavioralEvidenceAnalyzer → BehavioralEvidence
    │               (+ BehavioralEvidenceDetected)
    └── FakeNarrativeThemeResolver → NarrativeThemeId[]
            (+ NarrativeThemesAdded)
    ↓
BehavioralEvidenceDetected  ──publish──► EventBus
    ↓
BehavioralEvidenceDetectedReactor
    ↓
DetectPatternUseCase (DefaultDetectPatternUseCase)
    ↓
RuleBasedPatternDetector (Consistency, Courage, Leadership, …)
    ↓
Journey.updateBehaviorPatterns(...)
    ↓
BehaviorPatternsDetected
```

### Characteristics of the pre-migration flow

* **All in-memory** — no durable Journey/Reflection store for H.2.
* **Synchronous in-process reactors** — publish inside use cases; dispatcher invokes reactors immediately.
* **No HTTP boundary** — Flutter owned both command and reaction.
* **No UnitOfWork** — multi-aggregate updates (Reflection evidence + Journey patterns) were not wrapped in a DB transaction.
* **No command idempotency** — retries could double-submit depending on client behavior.
* **Orphan `PatternsDetected`** existed in `lib/.../events/patterns_detected.dart` but was **not** raised by `Journey.updateBehaviorPatterns()` (which raises `BehaviorPatternsDetected`).

---

## 3. Migration map

Disposition legend:

| Disposition | Meaning |
|-------------|---------|
| **MOVE** | Capability ownership moves to EH Platform; Flutter stops being authoritative |
| **REIMPLEMENT** | Domain/application types recreated under `services/eh_platform` (no shared Flutter domain package) |
| **ADAPT** | Flutter keeps a thin adapter / cache / config shim |
| **REMAIN CLIENT-SIDE** | Intentionally still Flutter-owned |
| **DELETE AFTER MIGRATION** | Remove once platform authority is mandatory everywhere |
| **DEFER** | Explicitly out of scope for this phase |

| Component | Disposition | Notes |
|-----------|-------------|-------|
| `Reflection` aggregate + invariants | **REIMPLEMENT** | `services/eh_platform/lib/src/life_journey/domain/aggregates/reflection.dart` |
| `Journey` aggregate + `behaviorPatterns` | **REIMPLEMENT** (+ partial **MOVE** of pattern authority) | Platform Journey is H.2 authority; Flutter Journey cache hydrated from understanding DTO |
| `DefaultSubmitReflectionUseCase` | **REIMPLEMENT** on platform; Flutter **ADAPT** via `PlatformSubmitReflectionUseCase` | Local default remains **TRANSITIONAL** |
| `AnalyzeReflectionUseCase` | **MOVE** / **REIMPLEMENT** | Platform-only when `usePlatformAuthority` |
| `DetectPatternUseCase` / `PatternDetector` / pattern rules | **MOVE** / **REIMPLEMENT** | Same naming as Flutter code |
| `ReflectionSubmittedReactor` / `BehavioralEvidenceDetectedReactor` | **MOVE** / **REIMPLEMENT** | Registered by `LifeJourneyModule` on PF.3 `EventDispatcher`; Flutter registration **skipped** under platform authority |
| `EmojiBehavioralEvidenceAnalyzer` + orchestrator/registry | **REIMPLEMENT** | Platform infrastructure services |
| `FakeNarrativeThemeResolver` | **REIMPLEMENT** (still fake) | Discovery ownership deferred; port preserved |
| In-memory EventBus / EventStore / Dispatcher | **REIMPLEMENT** on platform | Platform-owned events; not HTTP-exposed |
| Journey / Reflection persistence | **MOVE** to Postgres | `PostgresJourneyRepository`, `PostgresReflectionRepository` |
| UnitOfWork | **MOVE** (new) | Wraps H.2 submit chain |
| Command idempotency | **MOVE** (new) | `command_idempotency` + `Idempotency-Key` on submit |
| Identity lite (principal) | **MOVE** onto PF.3 Identity | Bearer session → `AuthenticatedPrincipal` |
| HTTP API (`LifeJourneyApi`) | **MOVE** (new) | Thin adapter over application service |
| `EhPlatformClient` / `EhPlatformConfig` | **ADAPT** (new) | Flutter infrastructure |
| Local Flutter H.2 reactors + local submit | **DELETE AFTER MIGRATION** | Kept for tests/offline without `EH_PLATFORM_URL` |
| Orphan `PatternsDetected` | **DEFER** / not migrated | Do not port; prefer `BehaviorPatternsDetected` |
| Experience Selection / Today’s Experience | **REMAIN CLIENT-SIDE** / **DEFER** | Reads local Journey cache patterns |
| Discovery / NarrativeTheme catalog | **DEFER** | Themes still fake-resolved |
| Hero & Story, AI proxy, Kafka, Rust, microservices | **DEFER** | Non-goals |
| `domain_event_log` durable outbox | **DEFER** (table created only) | In-process `InMemoryEventStore` still used for dispatch |

---

## 4. Target H.2 architecture

### Platform process

```text
Flutter (presentation + thin client)
        │  HTTP JSON (commands / queries)
        ▼
services/eh_platform  (Dart modular monolith)
├── platform_composition.dart / platform_server.dart   PF.3 runtime
├── api/                 ApiRouter + LifeJourneyApi (thin HTTP)
├── modules/life_journey LifeJourneyModule (composition boundary)
├── life_journey/
│   ├── application/     LifeJourneyApplicationService, use cases, reactors, DTOs
│   ├── domain/          aggregates, events, PatternDetector, rules
│   └── infrastructure/  Postgres + in-memory repos, SessionHolder, analyzers
├── events/              PF.3 EventBus, EventStore, EventDispatcher (in-process)
├── identity/            PF.3 Identity lite (BearerTokenAuthenticator)
├── persistence/         PF.3 UnitOfWork, MigrationRunner, CommandIdempotencyStore
└── shared_kernel/       PF.3 Result, Clock, UserId, …
```

Composition root: `services/eh_platform/lib/src/platform_composition.dart`

Entry: `services/eh_platform/bin/server.dart` → `runPlatformServer()`

### Authoritative command path (platform)

```text
HTTP POST /v1/reflections/{id}/submit
    ↓
PF.3 authenticationMiddleware → requireAuth → AuthenticatedPrincipal
    ↓
LifeJourneyApi  (idempotency replay, DTO mapping)
    ↓
LifeJourneyApplicationService.submitReflection(userId: …)
    ↓  PlatformTransactionBoundary → PF.3 UnitOfWork.execute
DefaultSubmitReflectionUseCase
    ↓ ReflectionSubmitted
ReflectionSubmittedReactor → AnalyzeReflectionUseCase
    ↓ BehavioralEvidenceDetected
BehavioralEvidenceDetectedReactor → DefaultDetectPatternUseCase
    ↓ RuleBasedPatternDetector → Journey.updateBehaviorPatterns
BehaviorPatternsDetected
    ↓
PostgresJourneyRepository / PostgresReflectionRepository
    ↓
SubmitReflectionResultDto { reflection, understanding }
```

### Flutter role after migration

When `EhPlatformConfig.usePlatformAuthority` is true:

```text
submitReflectionUseCaseProvider
    → PlatformSubmitReflectionUseCase
        → EhPlatformClient.submitReflection(...)
        → hydrate local Journey cache from understanding DTO
        → hydrate/local-save Reflection snapshot (cache)
        → discard any local domain events (must not re-publish H.2)

ReactorRegistration.register(...)
    → early return (no ReflectionSubmitted / BehavioralEvidenceDetected reactors)
```

Experience Selection continues to read the **local Journey cache** (non-authoritative snapshot of patterns).

### Key platform files

| Role | Path |
|------|------|
| Runtime composition | `services/eh_platform/lib/src/platform_runtime.dart` |
| HTTP API | `services/eh_platform/lib/src/api/life_journey_api.dart` |
| Application facade | `services/eh_platform/lib/src/life_journey/application/life_journey_application_service.dart` |
| Submit | `.../use_cases/submit_reflection_use_case.dart` |
| Analyze | `.../use_cases/analyze_reflection_use_case.dart` |
| Detect | `.../use_cases/detect_pattern_use_case.dart` |
| Reactors | `.../reactors/reflection/reflection_submitted_reactor.dart`, `.../reactors/behavioral_evidence_detected_reactor.dart` |
| Pattern detector | `.../infrastructure/services/behavioral_analysis/rule_based_pattern_detector.dart` |
| Postgres Journey | `.../infrastructure/persistence/postgres_journey_repository.dart` |
| Postgres Reflection | `.../infrastructure/persistence/postgres_reflection_repository.dart` |
| JSON codecs | `.../infrastructure/persistence/h2_json_codec.dart` |
| UnitOfWork | `services/eh_platform/lib/src/persistence/unit_of_work.dart` |
| Idempotency | `services/eh_platform/lib/src/persistence/command_idempotency_store.dart` |
| Migration SQL | `services/eh_platform/migrations/001_h2_foundation.sql` |
| DTOs | `.../application/dto/view_models.dart` |

### Key Flutter files (client adaptation)

| Role | Path |
|------|------|
| Config | `lib/features/life_journey/infrastructure/platform/eh_platform_config.dart` |
| HTTP client | `lib/features/life_journey/infrastructure/platform/eh_platform_client.dart` |
| Platform submit | `lib/features/life_journey/application/use_cases/platform_submit_reflection_use_case.dart` |
| Provider switch | `lib/features/life_journey/application/providers/use_cases/submit_reflection_use_case_provider.dart` |
| Reactor gate | `lib/bootstrap/reactor_registration.dart` |

---

## 5. API contract

Base URL: `EH_PLATFORM_URL` (Flutter) / server bind via `EH_PLATFORM_PORT` (default 8080).

### Identity (PF.3)

| Mechanism | Behavior |
|-----------|----------|
| `Authorization: Bearer <token>` | Resolved by `BearerTokenAuthenticator` to `AuthenticatedPrincipal` |
| Development token | `EH_DEV_AUTH_TOKEN` maps to configured `EH_DEV_USER_ID` session |
| Missing identity on protected routes | `401 unauthenticated` |
| `X-User-Id` | **Removed** — not used for production API authentication |

Flutter sends `Authorization: Bearer <EH_PLATFORM_AUTH_TOKEN>` only.

### Endpoints

| Method | Path | Purpose | Success |
|--------|------|---------|---------|
| `POST` | `/v1/journeys` | Create journey | `201` `JourneySummaryDto` |
| `GET` | `/v1/journeys/current` | Current journey summary for principal | `200` |
| `POST` | `/v1/reflections` | Create reflection draft | `201` `ReflectionDto` |
| `POST` | `/v1/reflections/{id}/responses` | Add response (H.2: **emoji only**) | `200` |
| `POST` | `/v1/reflections/{id}/submit` | **SubmitReflection** (authoritative H.2 command) | `200` |
| `POST` | `/v1/reflections/{id}:submit` | Alternate submit path (shelf_router compatibility) | `200` |
| `GET` | `/v1/understanding/current` | Patterns + recent evidence | `200` `UnderstandingDto` |
| `GET` | `/health` | Liveness | `200` `ok` |

### Submit headers

| Header | Required | Purpose |
|--------|----------|---------|
| `Idempotency-Key` | Recommended | Replay stored response for same user+key |
| `X-Correlation-Id` | Optional | Echoed; generated if absent |

### Request / response shapes (summary)

**Create journey**

```json
{ "vision": "string", "journeyId": "optional-string" }
```

**Create reflection**

```json
{ "journeyId": "string", "reflectionId": "optional-string" }
```

**Add emoji response**

```json
{ "type": "emoji", "emotion": "ReflectionEmotion.name" }
```

**Submit reflection response**

```json
{
  "reflection": {
    "reflectionId": "...",
    "journeyId": "...",
    "createdAt": "...",
    "submittedAt": "...",
    "responseCount": 1,
    "evidenceCount": 1
  },
  "understanding": {
    "journeyId": "...",
    "patterns": [
      {
        "type": "consistency",
        "strength": 0.8,
        "observationCount": 3,
        "firstObservedAt": "...",
        "lastObservedAt": "..."
      }
    ],
    "recentEvidence": [
      {
        "type": "discipline",
        "strength": 0.8,
        "observedAt": "...",
        "sourceKind": "reflection",
        "sourceId": "..."
      }
    ]
  }
}
```

**Errors** — envelope:

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": {},
    "correlationId": "optional"
  }
}
```

Notable codes: `validation_error`, `unsupported_response_type`, `reflection_already_submitted` (`409`), `forbidden` (`403`), `not_found` (`404`).

### What is **not** an HTTP API

Domain events (`ReflectionSubmitted`, `InsightsGenerated`, `BehavioralEvidenceDetected`, `NarrativeThemesAdded`, `BehaviorPatternsDetected`) are **platform-internal**. Clients consume **understanding** via query/result DTOs, not event streams.

---

## 6. Event flow

### Platform-owned chain (authoritative)

```text
DefaultSubmitReflectionUseCase
    → Reflection.submit()
    → ReflectionSubmitted
        → ReflectionSubmittedReactor
            → AnalyzeReflectionUseCase
                → InsightsGenerated
                → BehavioralEvidenceDetected
                → NarrativeThemesAdded
                    → BehavioralEvidenceDetectedReactor
                        → DefaultDetectPatternUseCase
                            → PatternDetector.detect(...)
                            → Journey.updateBehaviorPatterns(...)
                            → BehaviorPatternsDetected
```

Wiring: `LifeJourneyModule` registers the two reactors on the PF.3 `InMemoryEventDispatcher` during `PlatformComposition.bootstrap`.

### Transactional boundary

`LifeJourneyApplicationService.submitReflection` runs the **entire** use-case + reactor chain inside `PlatformTransactionBoundary` → PF.3 `UnitOfWork.execute` so Reflection evidence writes and Journey pattern updates commit or roll back together (PostgreSQL). Repositories bind to the active `TxSession` via `SessionHolder` (no second UnitOfWork type).

### Event storage / dispatch

| Concern | Implementation |
|---------|----------------|
| Dispatch | PF.3 in-process `InMemoryEventBus` → `InMemoryEventStore` → `InMemoryEventDispatcher` |
| Separate H.2 `eventing/` stack | **Removed** — migrated onto `lib/src/events/` |
| Durable platform event log table | Not introduced (in-memory EventStore for PF.3/H.2) |
| Outbox / Kafka | Not introduced |

### Events migrated vs not

| Event | Migrated to platform domain? | HTTP-exposed? |
|-------|------------------------------|---------------|
| `ReflectionSubmitted` | Yes | No |
| `InsightsGenerated` | Yes | No |
| `BehavioralEvidenceDetected` | Yes | No |
| `NarrativeThemesAdded` | Yes | No |
| `BehaviorPatternsDetected` | Yes | No |
| `PatternsDetected` (orphan) | **No** | No |
| `JourneyCreated` / `ChapterAdvanced` | Present on platform Journey for completeness | No |

---

## 7. Persistence model

Schema: `services/eh_platform/migrations/001_h2_foundation.sql`

### Tables

#### `users`

Identity lite anchor.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | Principal user id |
| `created_at` | `TIMESTAMPTZ` | |

#### `journeys`

Authoritative Journey behavioral state for H.2.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `user_id` | `TEXT` FK → users | Ownership |
| `vision` | `TEXT` | |
| `current_chapter` | `TEXT` | |
| `active_quest_ids` | `JSONB` | |
| `behavior_patterns` | `JSONB` | Serialized `BehaviorPattern[]` |
| `version` | `INT` | Optimistic concurrency |
| `created_at` / `updated_at` | `TIMESTAMPTZ` | |

#### `reflections`

Authoritative Reflection with embedded analysis outputs.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `user_id` | `TEXT` FK → users | |
| `journey_id` | `TEXT` FK → journeys | |
| `quest_id` / `mission_id` | `TEXT` nullable | |
| `created_at` / `submitted_at` | timestamps | |
| `responses` | `JSONB` | |
| `insights` | `JSONB` | |
| `behavioral_evidence` | `JSONB` | Embedded evidence (not separate evidence table) |
| `narrative_themes` | `JSONB` | `NarrativeThemeId[]` references only |
| `version` | `INT` | |

#### `command_idempotency`

| Column | Type | Notes |
|--------|------|-------|
| `(idempotency_key, user_id)` | composite PK | |
| `command_name` | `TEXT` | e.g. `SubmitReflection` |
| `request_hash` | `TEXT` | |
| `response_status` / `response_body` | int / JSONB | Replay payload |
| `created_at` | `TIMESTAMPTZ` | |

#### `domain_event_log`

Prepared for future durable event recording; **current dispatch still uses in-process EventStore**.

### Repository adapters

| Mode | Journey | Reflection | UoW |
|------|---------|------------|-----|
| Postgres | `PostgresJourneyRepository` | `PostgresReflectionRepository` | `PostgresUnitOfWork` |
| In-memory (tests / `EH_PLATFORM_USE_MEMORY=true`) | `OwnedInMemoryJourneyRepository` | `OwnedInMemoryReflectionRepository` | `InMemoryUnitOfWork` |

JSON encode/decode: `h2_json_codec.dart`.

### Design notes

* **Behavioral evidence is embedded** on Reflection JSONB — matches domain ownership (evidence belongs to reflections; Journey owns patterns).
* **No `BehaviorPatternRepository`** — patterns persist as Journey state (same H.2 rule as Flutter).
* Historical evidence for detection is loaded via Reflection repository (`findByJourneyId`), not a separate evidence store.

---

## 8. Authority transition

### Decision

> For H.2 Behavioral Understanding, **EH Platform is the sole authority** when Flutter runs with platform mode enabled. Flutter must not run Analyze/Detect reactors or publish H.2 domain events in that mode.

### Flutter switch

`EhPlatformConfig.usePlatformAuthority` (`lib/.../eh_platform_config.dart`):

| Condition | Authority |
|-----------|-----------|
| `EH_H2_MODE=local` | Local transitional H.2 (Flutter EventBus) |
| `EH_H2_MODE=platform` | Platform (requires `EH_PLATFORM_URL`) |
| URL set, mode unset | Platform |
| URL empty, mode unset | Local transitional (offline tests / demos) |

Defines:

* `EH_PLATFORM_URL`
* `EH_H2_MODE` = `platform` \| `local`
* `EH_PLATFORM_AUTH_TOKEN` / `EH_PLATFORM_USER_ID`

### Enforcement points

1. **`submitReflectionUseCaseProvider`** — selects `PlatformSubmitReflectionUseCase` vs `DefaultSubmitReflectionUseCase`.
2. **`ReactorRegistration.register`** — returns immediately under platform authority (no local H.2 reactors).
3. **`PlatformSubmitReflectionUseCase`** — after submit, hydrates Journey cache then **`pullDomainEvents()` and discards** so Flutter never re-publishes `BehaviorPatternsDetected`.

### Cache vs authority

| Data | Authoritative store | Flutter local copy |
|------|---------------------|--------------------|
| Reflection (submitted) + evidence | Postgres / platform memory | Optional cache for UI continuity |
| Journey `behaviorPatterns` | Platform Journey | Cache for Experience Selection |
| Understanding query | `GET /v1/understanding/current` | Derived from cache or fresh HTTP |

---

## 9. Transitional compatibility

### Why dual paths exist

PF.2 allows temporary duplication only with:

1. Named dual path
2. Platform designated future sole authority
3. Exit criterion

This phase keeps a **local TRANSITIONAL** H.2 path so:

* Unit/widget/integration tests without a platform URL continue to pass.
* Offline demos remain possible with `EH_H2_MODE=local`.

### What remains transitional on Flutter

| Artifact | Status |
|----------|--------|
| `DefaultSubmitReflectionUseCase` | TRANSITIONAL fallback |
| Local `AnalyzeReflectionUseCase` + providers | TRANSITIONAL (wired only if reactors registered) |
| Local `DetectPatternUseCase` + `RuleBasedPatternDetector` | TRANSITIONAL |
| Local reactors in `ReactorRegistration` | TRANSITIONAL; skipped when platform authority |
| In-memory LJ repositories | Still used for UI/cache and local mode |

### Exit criterion (removal)

Remove local H.2 reactors/use-case authority when:

* `EH_PLATFORM_URL` is required in all non-test environments, **and**
* Contract/integration tests cover Flutter → platform submit + understanding hydration, **and**
* Experience Selection either consumes understanding via API or an explicit later migration provides platform Experience.

Documented in code comments as Phase 9–style cleanup (`ReactorRegistration`).

### Experience Selection note

Experience Selection is **intentionally not migrated**. It remains client-side and depends on the hydrated Journey pattern cache. That is a known transitional coupling, not dual H.2 authority.

---

## 10. Testing strategy

### Platform (`services/eh_platform`)

| Suite | Path | Focus |
|-------|------|-------|
| Behavioral understanding | `test/h2_behavioral_understanding_test.dart` | Pattern rules, in-memory application chain, HTTP submit → understanding |
| Postgres integration | `test/h2_postgres_integration_test.dart` | Durable Journey/Reflection + UoW (when DB available) |
| Architecture dependency | `test/architecture_dependency_test.dart` | Module / dependency direction inside platform |

Commands:

```bash
cd services/eh_platform
dart analyze
dart test
```

In-memory server: `EH_PLATFORM_USE_MEMORY=true dart run bin/server.dart`

### Flutter

| Suite | Path | Focus |
|-------|------|-------|
| Platform authority architecture | `test/architecture/h2_platform_authority_test.dart` | Presentation must not import detectors / construct H.2 events; client must not import postgres |
| Config | `test/features/life_journey/infrastructure/platform/eh_platform_config_test.dart` | Default local without URL |
| Existing H.2 pipeline tests | `test/integration/behavior_pattern_detection_pipeline_test.dart` etc. | Continue against **local transitional** path |

### Recommended verification matrix

| Scenario | Expected |
|----------|----------|
| Platform submit with ≥3 discipline emoji evidence | Consistency pattern appears in understanding |
| Replay `Idempotency-Key` | Same status/body; `X-Idempotent-Replay: true` |
| Platform authority on Flutter | No local reactor registration; submit uses HTTP |
| Local mode / no URL | Previous in-process H.2 still works for tests |
| Cross-user journey access | `403` / not authorized |

---

## 11. Behavioral equivalence

### Equivalence claims (intended)

Given the same reflection responses and deterministic analyzers/rules:

1. **Evidence types / strengths** produced by `EmojiBehavioralEvidenceAnalyzer` match the Flutter H.2 analyzer semantics (reimplemented, same rules).
2. **Pattern detection** via `RuleBasedPatternDetector` + the same rule set (`ConsistencyPatternRule`, `CouragePatternRule`, `LeadershipPatternRule`, `ResponsibilityPatternRule`, `ServicePatternRule`, `RecoveryPatternRule`) yields equivalent `BehaviorPattern` types and observation counts.
3. **Journey ownership** of patterns is preserved — detection updates Journey, not a pattern repository.
4. **Event sequence** after submit remains: submit → analyze (insights/evidence/themes) → detect → `BehaviorPatternsDetected` when patterns change.
5. **Naming** remains `DetectPatternUseCase` / `PatternDetector` (not the drifted doc names).

### Accepted differences (not failures)

| Area | Difference |
|------|------------|
| Persistence | Platform durable vs Flutter in-memory |
| Transactionality | Platform UoW wraps the chain |
| Idempotency | Platform only |
| Identity | Platform principal checks; Flutter local mode had implicit ownership |
| HTTP surface | Commands/queries only; events not streamed |
| Flutter cache hydration | Pattern supporting evidence in cache may be synthesized placeholders for Experience Selection — **not** a second authority |
| Response types on HTTP | Emoji-only acceptance on `POST .../responses` for this migration slice |
| Narrative themes | Still fake resolver on both sides until Discovery migrates |

### Non-equivalence by design

* Flutter under platform authority **does not** publish H.2 events locally.
* Understanding is returned synchronously on submit (and via GET), rather than UI reacting only to local `BehaviorPatternsDetected`.

---

## 12. Known limitations

1. **Experience Selection not migrated** — still client-side; depends on cache hydration.
2. **Identity is lite** — opaque bearer = user id; no real IdP, sessions, or RBAC beyond ownership checks.
3. **Emoji-only HTTP responses** — other `ReflectionResponse` types exist in domain but are rejected at the API boundary for this slice.
4. **`FakeNarrativeThemeResolver`** still wired on platform (same transitional Discovery gap as Flutter).
5. **`domain_event_log` unused for dispatch** — table exists; live path is in-process EventStore.
6. **No Kafka / outbox / multi-process workers**.
7. **Dual domain trees** — Flutter `lib/features/life_journey` and `services/eh_platform/.../life_journey` are parallel reimplementations (PF-ADR-011: contracts over shared packages).
8. **Cache hydration approximations** — `PlatformSubmitReflectionUseCase` may construct placeholder supporting evidence when rebuilding `BehaviorPattern` objects locally.
9. **Orphan `PatternsDetected`** remains in Flutter tree; not part of platform model.
10. **Incomplete pattern rules / hygiene** called out in `AGENTS.md` §29 (e.g. `RecoveryPatternRule` completeness) may still apply to the reimplemented rule set.
11. **Quest/Mission lifecycle** beyond IDs on Reflection is not the focus of this migration.
12. **No OpenAPI artifact yet** — contract is code + this document.

---

## 13. Deferred cleanup

| Item | Disposition |
|------|-------------|
| Delete Flutter local H.2 reactors when platform URL is mandatory | **DELETE AFTER MIGRATION** (exit criterion in §9) |
| Delete or gate `DefaultSubmitReflectionUseCase` production path | After exit criterion |
| Remove orphan `PatternsDetected` from Flutter | Cleanup; do not migrate |
| Wire `domain_event_log` or transactional outbox | Later PF phase when a second consumer exists |
| Migrate Experience Selection to platform | PF.2 Phase 5 |
| Real NarrativeTheme / Discovery ownership | PF.2 Phase 6 |
| Full Identity (tokens, refresh, providers) | Expand Identity lite |
| Support non-emoji reflection responses over HTTP | Extend API when product needs them |
| Reconcile stale maps (`event-flow.md`, `use-case-map.md`, naming drift) | Doc hygiene; not blocking |
| Share OpenAPI / contract tests between Flutter client and platform | Follow-on |
| Absorb/replace `services/ai_proxy` | Out of scope |

Known hygiene from `AGENTS.md` §29 remains **findings**, not an automatic cleanup mandate for this phase.

---

## 14. Migration completion criteria

This H.2 Platform Migration is **complete** when all of the following are true:

### Architecture

- [x] EH Platform exists as Dart modular monolith at `services/eh_platform` (PF-ADR-003).
- [x] Minimum PF.3 foundation present: UnitOfWork, idempotency, Identity lite, Postgres schema, modular Life Journey module.
- [x] Authoritative H.2 chain runs on platform EventBus (Submit → Analyze → Detect → Journey patterns).
- [x] Domain events are platform-owned and not HTTP-exposed.
- [x] Experience / Discovery / HS / AI-proxy / Kafka / Rust / microservices **not** prematurely migrated.

### API & persistence

- [x] Commands: `POST /v1/journeys`, `POST /v1/reflections`, `POST /v1/reflections/{id}/responses`, `POST /v1/reflections/{id}/submit` (and `:submit`).
- [x] Queries: `GET /v1/journeys/current`, `GET /v1/understanding/current`.
- [x] Postgres tables: `users`, `journeys` (patterns JSONB), `reflections` (evidence JSONB), `command_idempotency`, `domain_event_log` (created).
- [x] Submit wrapped in UnitOfWork; idempotent replay supported.

### Flutter authority transition

- [x] `EhPlatformClient` + `EhPlatformConfig` (`EH_PLATFORM_URL`, `EH_H2_MODE`).
- [x] `PlatformSubmitReflectionUseCase` hydrates Journey cache from understanding DTO.
- [x] `ReactorRegistration` skips H.2 reactors when `usePlatformAuthority`.
- [x] Local reactors/use cases retained as **TRANSITIONAL** only.

### Behavioral / naming fidelity

- [x] `DetectPatternUseCase` / `PatternDetector` naming preserved.
- [x] `BehaviorPatternsDetected` migrated; orphan `PatternsDetected` not migrated.
- [x] Evidence → Patterns separation retained; Journey owns patterns.

### Validation

- [x] Platform tests cover in-memory H.2 behavioral understanding (and Postgres when available).
- [x] Flutter architecture smoke tests assert presentation does not import detectors / construct H.2 events.
- [x] This document records the migration as implemented.

### Explicitly **not** required for completion

* Experience Selection migration
* Discovery / real NarrativeTheme resolver
* Durable event outbox consumers
* Deletion of transitional Flutter H.2 code (tracked as deferred cleanup)
* Production IdP

---

## Appendix A — Before / after comparison

| Dimension | Before (Flutter H.2) | After (EH Platform) |
|-----------|----------------------|---------------------|
| Authority | Flutter process | `services/eh_platform` |
| Transport | In-process EventBus | HTTP commands/queries + internal EventBus |
| Persistence | In-memory | Postgres (or in-memory for tests) |
| Transactions | None | `UnitOfWork` around submit chain |
| Idempotency | None | `command_idempotency` |
| Identity | Implicit local | Identity lite principal |
| Flutter role | Full H.2 owner | Client + cache (+ transitional local mode) |
| Experience Selection | Client | Client (unchanged) |

## Appendix B — Runtime configuration

### Platform server

```bash
export EH_DATABASE_URL=postgresql://eh:eh@localhost:5432/eh_platform
export EH_PLATFORM_PORT=8080
dart run bin/server.dart

# or
export EH_PLATFORM_USE_MEMORY=true
dart run bin/server.dart
```

### Flutter (platform authority)

```bash
flutter run \
  --dart-define=EH_PLATFORM_URL=http://localhost:8080 \
  --dart-define=EH_H2_MODE=platform \
  --dart-define=EH_PLATFORM_USER_ID=dev-user
```

### Flutter (local transitional)

```bash
flutter run --dart-define=EH_H2_MODE=local
# or omit EH_PLATFORM_URL
```

## Appendix C — Product loop position

H.2 on platform still implements only the understanding slice:

```text
Experience → Action → Reflection → Understanding → Personalization → Growth → New Experience
                              ▲
                              │
                     This migration (platform authority)
```

Personalization / Experience Selection remain consumer-side until a later PF phase.

---

**End of H.2 Platform Migration architecture document.**
