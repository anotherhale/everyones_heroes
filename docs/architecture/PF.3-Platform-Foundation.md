# PF.3 — EH Platform Foundation

- **Document type:** Platform Foundation Implementation Report (PF.3)
- **Status:** Foundation implemented
- **Date:** 2026-09-23
- **Baseline:** PF.1 Overall Architecture + PF.2 Platform Architecture Decisions
- **Code location:** `services/eh_platform`

---

## 1. Purpose

PF.3 establishes the **EH Platform modular-monolith foundation** without migrating H.2 or other domain verticals.

This document distinguishes **IMPLEMENTED** work from **PLANNED** follow-on phases.

---

## 2. Platform location — IMPLEMENTED

```text
everyones_heroes/
├── lib/                         # Flutter client (unchanged authority)
├── services/
│   ├── ai_proxy/                # Interim AI credential boundary (kept)
│   └── eh_platform/             # NEW — Dart modular monolith
└── docs/architecture/
    ├── Everyone's-Heroes-Overall-Architecture.md   # PF.1
    ├── PF.2-Platform-Architecture-Decisions.md     # PF.2
    └── PF.3-Platform-Foundation.md                 # this file
```

### Decision rationale

* Existing server foothold lives under `services/` (`ai_proxy`).
* Placing the platform beside the proxy keeps Flutter client vs platform vs AI infrastructure clearly separated.
* Single Dart package (not a package explosion) with folder modules enforces BC boundaries (PF-ADR-002/004).
* PF-ADR-011 forbids sharing Flutter domain packages with the platform long-term — platform owns its own `shared_kernel`.

---

## 3. Modules — IMPLEMENTED (boundaries only)

| Module | Path | Status |
|--------|------|--------|
| `shared_kernel` | `lib/src/shared_kernel` | **IMPLEMENTED** — IDs, Clock, Result, Guard |
| `identity` | `lib/src/modules/identity` + `lib/src/identity` | **IMPLEMENTED** — Identity lite |
| `life_journey` | `lib/src/modules/life_journey` | **IMPLEMENTED** — ownership marker; BU subdomain noted |
| `discovery` | `lib/src/modules/discovery` | **IMPLEMENTED** — ownership marker |
| `hero_story` | `lib/src/modules/hero_story` | **IMPLEMENTED** — ownership marker |
| `experience` | `lib/src/modules/experience` | **IMPLEMENTED** — ownership marker (+ personalization submodule name) |
| `ai` | `lib/src/modules/ai` + `lib/src/ai` | **IMPLEMENTED** — orchestration seam |
| `contribution` | — | **PLANNED / frozen** (PF.2) — not scaffolded |

Per PF-ADR-002, **Behavioral Understanding stays inside Life Journey** — no separate top-level module.

---

## 4. Dependency direction — IMPLEMENTED

```text
API (Shelf handlers)
  → Application (commands/queries)
    → Domain (identity User / principal; shared_kernel)
      ↑
Infrastructure (postgres adapters, stub AI adapter, HTTP middleware)
```

Rules enforced by layout + architecture tests:

* Domain does not import Shelf, Postgres, HTTP, or provider SDKs.
* Application does not import Shelf/Postgres.
* API handlers are thin and delegate to application handlers.
* Flutter does not import `eh_platform`.

---

## 5. API foundation — IMPLEMENTED

| Method | Path | Kind | Notes |
|--------|------|------|-------|
| `GET` | `/health` | probe | Liveness |
| `GET` | `/ready` | probe | Readiness (PostgreSQL) |
| `GET` | `/v1/me` | query | Authenticated hello (Identity lite) |
| `GET` | `/v1/openapi.json` | contract | OpenAPI 3 document |

Conventions from PF.2 §6.5:

* `/v1` prefix
* Structured error envelope `{ error: { code, message, details, correlationId } }`
* `X-Correlation-Id` request/response
* `Authorization: Bearer <token>`

**Not implemented (intentionally):** reflection/journey/experience/story command surfaces.

---

## 6. Event foundation — IMPLEMENTED

In-process mechanism matching today’s EH mental model (PF-ADR-006):

```text
EventBus.publish
  → EventStore.append
  → EventDispatcher.dispatch (deterministic registration order)
  → DomainEventReactor.react
```

* Typed `DomainEvent` with correlation/causation + `schemaVersion`
* No Kafka / NATS / distributed bus
* Flutter does not publish platform domain events
* Boot publishes `PlatformStarted` as a smoke event

Durable outbox: **PLANNED** when a second process consumer appears.

---

## 7. Persistence foundation — IMPLEMENTED

| Concern | Choice |
|---------|--------|
| Engine | PostgreSQL (PF-ADR-007) |
| Driver | `package:postgres` |
| Migrations | SQL files under `migrations/` + `MigrationRunner` |
| Transactions | `UnitOfWork` → `runInTransaction` |
| Schema in PF.3 | `identity_users`, `identity_sessions`, `command_idempotency`, `schema_migrations` |

Object storage / media: **PLANNED** (Phase 7 / PF-ADR-009).

LJ/HS aggregate schemas: **PLANNED** (Phases 3–7).

---

## 8. Identity foundation — IMPLEMENTED

Identity lite (PF-ADR-008 architecture Ready; providers open):

* `User` + `UserId` (platform identity)
* Opaque bearer sessions (hashed at rest)
* Development token bootstrap via config (`EH_DEV_AUTH_TOKEN`)
* `GET /v1/me` authenticated hello path (Phase 2 exit criterion)

**Not decided / not hard-coded:** email vs OAuth login providers.

**Not merged:** Hero remains a future Hero & Story aggregate linked by `UserId`, never equated to User.

---

## 9. AI orchestration seam — IMPLEMENTED

```text
Application
  → AiOrchestrationPort
    → StubAiProviderAdapter (PF.3)
    → (future) Provider adapters
```

* `services/ai_proxy` **kept separate** (PF-ADR-010 near-term)
* Absorb into platform AI module: **PLANNED Phase 8**
* No provider SDK imports in domain/application

---

## 10. Configuration & observability — IMPLEMENTED

Configuration (env):

* `EH_ENV`, `EH_HTTP_HOST`, `EH_HTTP_PORT`
* `EH_DATABASE_URL`
* `EH_LOG_LEVEL`
* `EH_DEV_AUTH_TOKEN`, `EH_DEV_USER_ID`, `EH_DEV_USER_DISPLAY_NAME`
* `EH_AI_MODE` (`stub` default)

Observability:

* Structured JSON logs
* Request correlation IDs
* Startup / shutdown / signal logging
* Application error envelope for unhandled errors

---

## 11. Testing — IMPLEMENTED

Platform suite (`services/eh_platform`):

* configuration
* API health/readiness + authenticated hello
* application boundary
* domain-event dispatch
* PostgreSQL connectivity / migrations / UnitOfWork
* Identity lite
* AI seam
* dependency-direction static checks

Flutter application suite must remain green; PF.3 does not migrate or delete Flutter domain code.

---

## 12. Architecture validation checklist

| Check | Result |
|-------|--------|
| API does not contain domain logic | **Pass** — handlers delegate to application |
| Application does not depend on HTTP | **Pass** |
| Domain does not depend on infrastructure | **Pass** |
| Domain does not depend on AI provider SDKs | **Pass** |
| Persistence does not leak into domain models | **Pass** |
| Flutter need not know platform internals | **Pass** |
| Platform owns domain events | **Pass** |
| Modular boundaries exist | **Pass** |
| No Kafka | **Pass** |
| No Rust | **Pass** |
| No microservices | **Pass** |
| No speculative full-domain migration | **Pass** |

---

## 13. Intentionally deferred

* H.2 Reflection → BehavioralEvidence → BehaviorPattern migration (**next expected phase**)
* Journey / Quest / Mission API authority
* Experience selection migration
* DiscoveryProfile product wiring
* Hero & Story authority + media object storage
* Absorbing `ai_proxy`
* Product login providers
* OpenAPI codegen for Flutter client
* Contribution BC
* Durable event outbox / Kafka
* Language rewrite to Rust

---

## 14. Next phase

**H.2 Platform Migration** (PF.2 Phase 3) — do not begin automatically from PF.3.

Exit criterion for that phase (from PF.2):

`SubmitReflection` → patterns visible via understanding query; Flutter stops competing reactors when API flag is on.

---

*End of PF.3 Platform Foundation document.*
