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
| `POST` | `/story-voice-renderings` | Synthetic Story voice narration (HS.12.6) |
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

Render has **no native Dart runtime**, so the Blueprint builds this package with
Docker (`services/ai_proxy/Dockerfile`) and runs the compiled `bin/server`
entrypoint. The Flutter app is not part of this service.

### Required Render environment variables (Dashboard secrets)

| Variable | Notes |
|----------|--------|
| `OPENAI_API_KEY` | Server only — never in Flutter or `render.yaml` values |
| `EH_AI_PROXY_AUTH_TOKEN` | Shared bearer token; also passed to Flutter via `--dart-define` only at run time |

Optional: `STABILITY_API_KEY` for live music generation.

Render injects `PORT` automatically. Do not hard-code a port in the Blueprint.
The proxy maps `PORT` when `EH_AI_PROXY_PORT` is unset.

### Public URL

After deploy:

```text
https://<service-name>.onrender.com
```

Default Blueprint service name: `eh-ai-proxy` → typically
`https://eh-ai-proxy.onrender.com` (exact hostname is shown in the Render Dashboard).

Health check path configured in the Blueprint: `GET /health`.

### Connect GitHub → Render (one-time UI steps)

`render.yaml` cannot grant Render access to GitHub by itself. In the Render Dashboard:

1. Sign in to [Render](https://dashboard.render.com).
2. Connect the GitHub account/organization that owns `anotherhale/everyones_heroes`
   (Account Settings → Linked Accounts / Git providers), and grant repo access.
3. **New → Blueprint** (or sync an existing Blueprint), point at this repository
   and the `main` branch, and select the root `render.yaml`.
4. When prompted for `sync: false` env vars, paste `OPENAI_API_KEY` and
   `EH_AI_PROXY_AUTH_TOKEN` (and optional `STABILITY_API_KEY`). Never commit them.
5. Create/sync the Blueprint. Render builds the Docker image from
   `services/ai_proxy` and deploys the web service.

### Automatic deploys

The Blueprint sets `autoDeployTrigger: commit` and `branch: main`. After the
repo is linked, pushes/merges to `main` that touch `services/ai_proxy/**`
trigger a new deploy:

```text
GitHub (push/merge to main)
  → Render automatic deploy
  → EH AI Proxy
  → OpenAI API
```

### Docker build / start (what Render runs)

| Step | Command / behavior |
|------|--------------------|
| Build | Docker build of `services/ai_proxy/Dockerfile` (`dart pub get` + `dart compile exe bin/server.dart`) |
| Start | `/app/bin/server` (Dockerfile `CMD`) |
| Port | Render-provided `PORT` env var |
| Health | `GET /health` |

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

Never commit or place in Flutter / `render.yaml` values / `--dart-define`:

* `OPENAI_API_KEY`

The Flutter app may know only:

* `EH_AI_PROXY_URL`
* `EH_AI_PROXY_AUTH_TOKEN` (proxy bearer — not the OpenAI key)

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
