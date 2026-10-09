# Everyone's Heroes AI Proxy (HS.11 / SB.7 / SB.8 / SB.11 / HS.12.3 / HS.12.4 / HS.12.6 / Experiment A)

Production AI credentials stay on this server. The Flutter app never embeds
vendor secrets (HS-ADR-067 / HS-ADR-068).

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/story-transcriptions` | Speech-to-text (HS.11) |
| `POST` | `/story-builder-questions` | AI Story Coach next question (SB.7) |
| `POST` | `/story-understanding` | Story Builder Understanding (SB.8) |
| `POST` | `/story-authoring` | AI Story Proposal authoring (SB.11) |
| `POST` | `/captured-story-readings` | Grounded Captured Story Reading (HS.12.3) |
| `POST` | `/story-experience-plans` | Typed Story Experience Plan (HS.12.4) |
| `POST` | `/story-voice-renderings` | Synthetic Story voice narration (HS.12.6 / HS-ADR-077) |
| `POST` | `/experience-creative-directions` | Experiment A presentation creative direction |
| `POST` | `/story-music-generations` | Experiment A Stable Audio instrumental bed |
| `GET` | `/health` | Liveness (auth exempt; no OpenAI call) |

`GET /health` returns HTTP 200 with JSON:

```json
{"status":"ok"}
```

## Local run

```bash
cd services/ai_proxy
dart pub get
export OPENAI_API_KEY=sk-...
export EH_AI_PROXY_PORT=8787
export EH_AI_PROXY_AUTH_TOKEN=dev-token
# optional:
# export OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
# export OPENAI_CHAT_MODEL=gpt-4o-mini
# export OPENAI_SPEECH_MODEL=tts-1
# export OPENAI_SPEECH_VOICE=alloy
# HS.12.7 — provider selection stays in the proxy (not Flutter):
# export EH_TTS_PROVIDER=openai   # openai | qwen3 | cosyvoice
# export EH_TTS_ALLOW_PROVIDER_HINTS=false
# export EH_LOCAL_TTS_URL=http://127.0.0.1:8791
# export STABILITY_API_KEY=sk-...
# export STABILITY_BASE_URL=https://api.stability.ai
# export STABILITY_AUDIO_MODEL=stable-audio-3
dart run bin/server.dart
```

The server binds to `0.0.0.0` by default (`EH_AI_PROXY_HOST`). Port selection:

1. `EH_AI_PROXY_PORT` when set
2. else `PORT` (used by Render and similar hosts)
3. else `8787` for local development

Confirm locally:

```bash
curl -s http://localhost:8787/health
# {"status":"ok"}
```

## Flutter wiring (local)

Do **not** put `OPENAI_API_KEY` in Flutter, `--dart-define`, or source control.

```bash
flutter run \
  --dart-define=EH_AI_PROXY_URL=http://localhost:8787 \
  --dart-define=EH_TRANSCRIPTION_MODE=proxy \
  --dart-define=EH_STORY_BUILDER_COACH_MODE=proxy \
  --dart-define=EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy \
  --dart-define=EH_STORY_AUTHORING_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token
```

Without `EH_AI_PROXY_URL`, the app uses development in-memory adapters for
transcription, Story Builder coaching, Story Understanding, and Story Authoring.

## Render deployment

Repository Blueprint: [`render.yaml`](../../render.yaml) at the repo root.

The Blueprint defines **two** services:

| Service | Type | Role |
|---------|------|------|
| `eh-web` | Static Site | Flutter Web (`build/web`) |
| `eh-ai-proxy` | Docker web service | This AI proxy |

Render has **no native Dart runtime**, so `eh-ai-proxy` builds with Docker
(`services/ai_proxy/Dockerfile`) and runs the compiled `bin/server` entrypoint.

`eh-web` clones Flutter during its Static Site build
([`scripts/render_build_flutter_web.sh`](../../scripts/render_build_flutter_web.sh))
and injects proxy settings via `--dart-define` (same `String.fromEnvironment`
keys used locally / on iPhone).

### Required Render environment variables (Dashboard secrets)

On **`eh-ai-proxy` only**:

| Variable | Notes |
|----------|--------|
| `OPENAI_API_KEY` | Server only — **never** on `eh-web` / Flutter / `render.yaml` values |
| `EH_AI_PROXY_AUTH_TOKEN` | Shared bearer token |

Optional on `eh-ai-proxy`: `STABILITY_API_KEY` for live music generation.

On **`eh-web`** (build-time, via Blueprint wiring — not pasted as OpenAI secrets):

| Variable | Source |
|----------|--------|
| `EH_AI_PROXY_URL` | `fromService` → `eh-ai-proxy` `RENDER_EXTERNAL_URL` |
| `EH_AI_PROXY_AUTH_TOKEN` | `fromService` → `eh-ai-proxy` `EH_AI_PROXY_AUTH_TOKEN` |
| `EH_TRANSCRIPTION_MODE` | Blueprint value `proxy` |

Render injects `PORT` automatically on the proxy. Do not hard-code a port in
the Blueprint. The proxy maps `PORT` when `EH_AI_PROXY_PORT` is unset.

### Public URLs

After deploy (exact hostnames are shown in the Render Dashboard):

```text
https://eh-web.onrender.com          # Flutter Web
https://eh-ai-proxy.onrender.com     # AI proxy
```

Health check path configured in the Blueprint: `GET /health` → `{"status":"ok"}`.

### CORS (Flutter Web → proxy)

The proxy adds a minimal CORS middleware so browsers on the `eh-web` origin can
call the proxy:

* Reflects `Origin` (or `*` when absent)
* Allows `GET`, `POST`, `OPTIONS`
* Allows `Authorization`, `Content-Type`
* Answers `OPTIONS` preflight with `204` **before** auth runs

This is intentional for the initial test deployment — not a production allowlist.

### Connect GitHub → Render (one-time UI steps)

`render.yaml` cannot grant Render access to GitHub by itself. In the Render Dashboard:

1. Sign in to [Render](https://dashboard.render.com).
2. Connect the GitHub account/organization that owns `anotherhale/everyones_heroes`
   (Account Settings → Linked Accounts / Git providers), and grant repo access.
3. **New → Blueprint** (or sync an existing Blueprint), point at this repository
   and the `main` branch, and select the root `render.yaml`.
4. When prompted for `sync: false` env vars on **`eh-ai-proxy`**, paste
   `OPENAI_API_KEY` and `EH_AI_PROXY_AUTH_TOKEN` (and optional `STABILITY_API_KEY`).
   Never commit them. Do **not** paste `OPENAI_API_KEY` onto `eh-web`.
5. Create/sync the Blueprint. Render deploys both services.

### Automatic deploys

Both services use `autoDeployTrigger: commit` and `branch: main`, with
independent `buildFilter` paths:

```text
GitHub (push/merge to main)
        │
   ┌────┴────┐
   ▼         ▼
 eh-web   eh-ai-proxy
 (Flutter) (Docker)
```

* `eh-web` rebuilds when `lib/**`, `web/**`, `assets/**`, `pubspec.*`, etc. change
* `eh-ai-proxy` rebuilds when `services/ai_proxy/**` changes

### Docker build / start (what Render runs for eh-ai-proxy)

| Step | Command / behavior |
|------|--------------------|
| Build | Docker build of `services/ai_proxy/Dockerfile` (`dart pub get` + `dart compile exe bin/server.dart`) |
| Start | `/app/bin/server` (Dockerfile `CMD`) |
| Port | Render-provided `PORT` env var |
| Health | `GET /health` |

### Flutter Web build (what Render runs for eh-web)

Equivalent to:

```bash
flutter build web --release \
  --dart-define=EH_AI_PROXY_URL=https://<eh-ai-proxy>.onrender.com \
  --dart-define=EH_TRANSCRIPTION_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=$EH_AI_PROXY_AUTH_TOKEN
```

Publish directory: `build/web`. SPA rewrite: `/*` → `/index.html`.

### Remote Flutter / iPhone (placeholders only — do not commit tokens)

```bash
flutter run \
  --dart-define=EH_AI_PROXY_URL=https://<render-service>.onrender.com \
  --dart-define=EH_TRANSCRIPTION_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=<token>
```

Keep local defaults (`http://localhost:8787`) for day-to-day Mac development.
The Render URL is supplied only at launch time via `--dart-define`.

## Security

Never commit or place in Flutter / `render.yaml` values / the `eh-web` build:

* `OPENAI_API_KEY`

⚠ **Temporary test-only limitation:** `EH_AI_PROXY_AUTH_TOKEN` is embedded in the
public Flutter Web JavaScript bundle for this initial Render deployment. Treat
the token as publicly inspectable. Do not reuse a production secret. Proper web
authentication will come later.

The Flutter app may know only:

* `EH_AI_PROXY_URL`
* `EH_AI_PROXY_AUTH_TOKEN` (proxy bearer — not the OpenAI key)
* Mode defines such as `EH_TRANSCRIPTION_MODE=proxy`

Do not log or return vendor API keys from any endpoint.

## Story Coach contract

`POST /story-builder-questions`

Request (JSON, EH-owned — minimized session context):

```json
{
  "purpose": "inspireSomeone",
  "themes": ["perseverance"],
  "themesUnsure": false,
  "presentedNarrativeRoles": ["beginning"],
  "turns": [
    {
      "promptText": "...",
      "ordinal": 0,
      "narrativeRole": "beginning",
      "responseText": "...",
      "skipped": false
    }
  ]
}
```

Response (JSON):

```json
{
  "question": "What happened next?",
  "narrativeRole": "challenge",
  "reason": "internal rationale",
  "readyToComplete": false,
  "providerLabel": "openai_via_eh_proxy"
}
```

Hero response text is treated as untrusted user content and is never merged
into the system prompt.

## Story Understanding contract

`POST /story-understanding`

Request (JSON, EH-owned — minimized Builder material + SB.4 structure):

```json
{
  "purpose": "inspireSomeone",
  "themes": ["perseverance"],
  "themesUnsure": false,
  "structureSections": [
    {
      "narrativeRole": "challenge",
      "order": 1,
      "sourceResponseIds": ["sb-response-123"],
      "wasSkipped": false,
      "hasSourceMaterial": true
    }
  ],
  "responses": [
    {
      "id": "sb-response-123",
      "ordinal": 1,
      "narrativeRole": "challenge",
      "text": "...",
      "skipped": false
    }
  ]
}
```

Response (JSON): structured themes / narrativeElements / keyElements /
significantEvents with `sourceResponseIds` provenance — never a polished story.

## Story Authoring contract

`POST /story-authoring`

Request (JSON, EH-owned — minimized StoryProposal payload):

```json
{
  "purpose": "inspireSomeone",
  "themes": ["perseverance"],
  "themesUnsure": false,
  "title": null,
  "summary": "optional existing narrative",
  "understandingSummary": "optional derived understanding — not fact",
  "sections": [
    {
      "role": "struggle",
      "content": "I kept going even when I wanted to quit.",
      "sourceResponseIds": ["sb-response-17"],
      "contentOrigin": "heroAuthored",
      "wasSkipped": false
    }
  ]
}
```

Response (JSON):

```json
{
  "title": "optional grounded title",
  "summary": "optional short derived summary",
  "sections": [
    {
      "role": "struggle",
      "content": "derived prose grounded in Hero material",
      "sourceResponseIds": ["sb-response-17"]
    }
  ],
  "warnings": [],
  "providerLabel": "openai_via_eh_proxy",
  "promptOrTemplateVersion": "sb11.ai.v1"
}
```

Hero-authored content is the factual source of truth. Derived understanding is
guidance only. The model must not invent facts or sourceResponseIds.

## Story Voice Rendering contract (HS.12.6 / HS-ADR-077)

`POST /story-voice-renderings`

Provider-neutral **synthetic narration** only. Complete-file audio (base64).
Voice cloning / VoiceProfile are out of scope and rejected when
`renderingMode` is not `syntheticNarration`. Narration does not authorize cloning.

Request (JSON, EH-owned):

```json
{
  "storyId": "story-1",
  "experiencePlanId": "plan-1",
  "experiencePlanProcessingVersion": "hs12.4.v1",
  "sourceRepresentationId": "transcript-1",
  "sourceText": "Transcript or script text to narrate.",
  "language": "en",
  "renderingMode": "syntheticNarration",
  "processingVersion": "hs12.6.v1",
  "providerHint": "openai",
  "modelHint": "tts-1"
}
```

`language` is required (BCP 47). `providerHint` / `modelHint` are optional opaque
infrastructure routing hints — not domain voice identities.

Response (JSON):

```json
{
  "storyId": "story-1",
  "experiencePlanId": "plan-1",
  "experiencePlanProcessingVersion": "hs12.4.v1",
  "sourceRepresentationId": "transcript-1",
  "language": "en",
  "renderingMode": "syntheticNarration",
  "audioBase64": "...",
  "contentType": "audio/mpeg",
  "providerLabel": "openai_tts_via_eh_proxy",
  "modelLabel": "tts-1",
  "processingVersion": "hs12.6.v1"
}
```

Errors: `{"error":"..."}` with 400 / 401 / 502 / 500.

### HS.12.7 provider selection (proxy only)

Provider switching stays inside this service. Flutter continues to call only
`POST /story-voice-renderings` via `VoiceRenderingPort`.

| Variable | Values | Notes |
|----------|--------|-------|
| `EH_TTS_PROVIDER` | `openai` (default), `qwen3` | Verified adapters |
| `EH_TTS_ALLOW_PROVIDER_HINTS` | `false` (default) / `true` | Lab-only hint override |
| `EH_LOCAL_TTS_URL` | e.g. `http://127.0.0.1:8791` | Required when provider is `qwen3` |

`cosyvoice` was investigated in HS.12.7 but **not** successfully verified; selecting
it returns a 502 with an explicit verification failure message.

Local sidecar (Python): `services/ai_proxy/tts_sidecar/`

Reproducible benchmark: `dart run tool/tts_benchmark/run_benchmark.dart`

See: `docs/architecture/HS.12.7-TTS-Provider-Benchmark.md`

The `qwen3` provider in this proxy is the HS.12.7 CustomVoice synthetic path. It is not the separate local Qwen3-TTS Base/ICL cloning experiment. That experiment, and the Story Performance direction, are documented in `docs/architecture/Voice-Cloning-and-Story-Performance-Architecture.md`. Base/ICL cloning does not currently apply `instruct` or `speed`.
