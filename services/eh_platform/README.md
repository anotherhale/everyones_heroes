# EH Platform (`services/eh_platform`)

Everyone's Heroes modular monolith (PF.3 foundation + H.2 Behavioral Understanding).

## Run (PostgreSQL)

```bash
export EH_DATABASE_URL=postgresql://eh:eh@localhost:5432/eh_platform
export EH_PLATFORM_PORT=8080
dart run bin/server.dart
```

## Run (in-memory)

```bash
export EH_PLATFORM_USE_MEMORY=true
dart run bin/server.dart
```

## H.2 API

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/journeys` | Create journey |
| GET | `/v1/journeys/current` | Current journey summary |
| POST | `/v1/reflections` | Create reflection draft |
| POST | `/v1/reflections/{id}/responses` | Add emoji response |
| POST | `/v1/reflections/{id}/submit` | **SubmitReflection** (H.2 command) |
| GET | `/v1/understanding/current` | Patterns + recent evidence |
| GET | `/health` | Liveness |

Identity lite: `Authorization: Bearer <userId>` or `X-User-Id`.

Idempotency: `Idempotency-Key` on submit.

## Tests

```bash
dart analyze
dart test
```
