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
| `GET` | `/health` | Liveness (auth exempt) |

## Run

```bash
cd services/ai_proxy
dart pub get
export OPENAI_API_KEY=sk-...
# optional:
# export OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
# export OPENAI_CHAT_MODEL=gpt-4o-mini
# export OPENAI_SPEECH_MODEL=tts-1
# export OPENAI_SPEECH_VOICE=alloy
# export STABILITY_API_KEY=sk-...
# export STABILITY_BASE_URL=https://api.stability.ai
# export STABILITY_AUDIO_MODEL=stable-audio-3
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
  --dart-define=EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy \
  --dart-define=EH_STORY_AUTHORING_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token
```

Without `EH_AI_PROXY_URL`, the app uses development in-memory adapters for
transcription, Story Builder coaching, Story Understanding, and Story Authoring.

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
