# EH Platform (`services/eh_platform`)

Dart modular monolith foundation for Everyone's Heroes (PF.3 / Phase 2).

## Boundaries

```text
Flutter Client
    │ REST/JSON (/v1)
    ▼
EH Platform
    ├── Application
    ├── Domain (module boundaries)
    ├── Events (in-process)
    ├── Persistence (PostgreSQL)
    └── AI Orchestration (ports + adapters)
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

## Foundation endpoints

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

## Tests

```bash
cd services/eh_platform
dart test
```

## Intentionally deferred

- H.2 Reflection / Behavioral Evidence migration (Phase 3)
- Journey / Experience / Discovery / Hero & Story authority
- Login provider product choice (PF-ADR-008 open)
- Absorbing `ai_proxy` (Phase 8)
- Kafka, microservices, Rust
