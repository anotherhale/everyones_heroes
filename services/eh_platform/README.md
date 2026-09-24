# EH Platform (`services/eh_platform`)

Dart modular monolith for Everyone's Heroes.

**PF.3** is the authoritative platform foundation (composition, Identity, shared
kernel, persistence, events, API router). **H.2** Life Journey / Behavioral
Understanding is a platform module on that foundation — not a second runtime.

## Boundaries

```text
Flutter Client
    │ HTTP/JSON
    ▼
EH Platform API (ApiRouter)
    │
    ▼
PlatformComposition / PlatformServer
    ├── Identity
    ├── Life Journey / H.2
    ├── Discovery (boundary)
    ├── Hero & Story (boundary)
    ├── Experience (boundary)
    ├── AI (ports)
    ├── Shared Kernel
    ├── Persistence (PostgreSQL + UnitOfWork)
    └── Events (in-process EventBus / EventStore)
```

`services/ai_proxy` remains a separate deployable until Phase 8 (PF-ADR-010).

## Run

```bash
# PostgreSQL must be reachable via EH_DATABASE_URL
cd services/eh_platform
dart pub get
export EH_DATABASE_URL=postgres://eh:eh_dev@127.0.0.1:5432/eh_platform
export EH_DEV_AUTH_TOKEN=dev-platform-token
dart run bin/server.dart
```

Migrations (ordered):

1. `001_platform_foundation.sql` — identity, sessions, command_idempotency
2. `002_h2_life_journey.sql` — journeys, reflections (FK → identity_users)

## Foundation endpoints (PF.3)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/health` | Liveness |
| `GET` | `/ready` | Readiness (PostgreSQL) |
| `GET` | `/v1/me` | Authenticated hello (Identity lite) |
| `GET` | `/v1/openapi.json` | OpenAPI 3 contract |

```bash
curl -s localhost:8080/health
curl -s localhost:8080/ready
curl -s -H "Authorization: Bearer dev-platform-token" localhost:8080/v1/me
```

## H.2 Behavioral Understanding endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/v1/journeys` | Create journey |
| `GET` | `/v1/journeys/current` | Current journey summary |
| `POST` | `/v1/reflections` | Create reflection draft |
| `POST` | `/v1/reflections/{id}/responses` | Add emoji response |
| `POST` | `/v1/reflections/{id}/submit` | **SubmitReflection** (H.2 command) |
| `GET` | `/v1/understanding/current` | Patterns + recent evidence |

## J.1 Experience Selection endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/v1/experiences/today` | **Today's Experience** (platform selection) |

Identity: `Authorization: Bearer <token>` resolved by PF.3 Identity
(`BearerTokenAuthenticator` / sessions) to an `AuthenticatedPrincipal`.

Idempotency: `Idempotency-Key` on submit (PF.3 `command_idempotency` table).

Experience Selection is on-read from Journey understanding — no experience
table. HS.8 Story composition uses `DiscoverableStoryCandidatePort`; platform
bootstrap wires a J.2 Slice 3 transitional seeded Hero & Story adapter.
J.2 Slice 4 (live candidate projection) is planned — see
`docs/architecture/J.2-Slice-4-Live-Story-Candidate-Discovery-Plan.md`.
Unwired tests may still use the Empty fail-closed default.

## Tests

```bash
cd services/eh_platform
dart analyze
dart test
```

## Intentionally deferred / follow-ups

- Replace transitional Story candidate seed with live Hero & Story candidate
  projection (J.2 Slice 4 — planned; see architecture doc)
- DiscoveryProfile / Influence / public Discovery API (D.1 / J.2 Slices 5–6)
- Content-aware theme classification beyond catalog-aligned `discovery`
- Quest / Mission platform lifecycle
- Login provider product choice (PF-ADR-008 open)
- Absorbing `ai_proxy` (Phase 8)
- Kafka, microservices, Rust
