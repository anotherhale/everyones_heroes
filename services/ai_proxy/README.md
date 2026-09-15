# Everyone's Heroes AI Proxy (HS.11)

Production speech-to-text credentials stay on this server. The Flutter app
calls `POST /story-transcriptions` through `ProxyStoryTranscriptionAdapter`
and never embeds OpenAI secrets (HS-ADR-067 / HS-ADR-068).

## Run

```bash
cd services/ai_proxy
dart pub get
export OPENAI_API_KEY=sk-...
# optional:
# export OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
# export EH_AI_PROXY_PORT=8787
# export EH_AI_PROXY_AUTH_TOKEN=dev-token
dart run bin/server.dart
```

## Flutter wiring

```bash
flutter run \
  --dart-define=EH_AI_PROXY_URL=http://localhost:8787 \
  --dart-define=EH_TRANSCRIPTION_MODE=proxy \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token
```

Without `EH_AI_PROXY_URL`, the app uses the development
`InMemoryStoryTranscriptionAdapter`.

## Contract

`POST /story-transcriptions`

Request (JSON):

```json
{
  "storyId": "...",
  "sourceRepresentationId": "...",
  "mediaReferenceUri": "...",
  "language": "en",
  "processingVersion": "hs4-v1",
  "requestId": "...",
  "mediaBase64": "...",
  "contentType": "audio/mp4"
}
```

Response (JSON):

```json
{
  "text": "...",
  "language": "en",
  "providerLabel": "openai_via_eh_proxy",
  "supportLevel": "moderate"
}
```
