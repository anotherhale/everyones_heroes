# Everyone's Heroes AI Proxy (HS.11 / SB.7)

Production AI credentials stay on this server. The Flutter app never embeds
OpenAI secrets (HS-ADR-067 / HS-ADR-068).

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/story-transcriptions` | Speech-to-text (HS.11) |
| `POST` | `/story-builder-questions` | AI Story Coach next question (SB.7) |
| `GET` | `/health` | Liveness (auth exempt) |

## Run

```bash
cd services/ai_proxy
dart pub get
export OPENAI_API_KEY=sk-...
# optional:
# export OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
# export OPENAI_CHAT_MODEL=gpt-4o-mini
# export EH_AI_PROXY_PORT=8787
# export EH_AI_PROXY_AUTH_TOKEN=dev-token
dart run bin/server.dart
```

## Flutter wiring

```bash
flutter run \
  --dart-define=EH_AI_PROXY_URL=http://localhost:8787 \
  --dart-define=EH_TRANSCRIPTION_MODE=proxy \
  --dart-define=EH_STORY_BUILDER_COACH_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token
```

Without `EH_AI_PROXY_URL`, the app uses development in-memory adapters for
transcription and Story Builder coaching.

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
