# HS.12.6 — Voice Rendering / AI Voice Implementation Report

**Phase:** HS.12.6  
**Date:** 2026-09-24  
**ADR:** HS-ADR-076

## Summary

HS.12.6 adds the first production-oriented voice-rendering boundary for Story
Experiences. Generated voice is a **derived presentation artifact** behind
`VoiceRenderingPort` and the EH AI proxy. The canonical Story, original
recording, CapturedStoryReading, and StoryExperiencePlan are not rewritten.
Playback uses persisted bytes and never invokes AI.

## Architecture

```text
HeroStoryScreen
  Authorize AI voice narration (StoryConsent.voiceRenderingApprovedAt)
  Create narrated version
    → RenderStoryVoiceUseCase
    → VoiceRenderingPort
    → ProxyVoiceRenderingAdapter
    → POST /story-voice-renderings (EH AI proxy)
    → OpenAI TTS (server-side only)
    → StoryVoiceRendering + media bytes
  Play narrated version (persisted bytes via OriginalRecordingPlayer)
Play my recording / Play my experience remain unchanged (original audio)
```

## Consent behavior

- New gate: `StoryConsent.voiceRenderingApprovedAt`
- Independent of recording / processing / publication / AI transformation
- Use case hard-blocks rendering without voice-rendering consent
- UI requires **Authorize AI voice narration** before Create is enabled

## Proxy contract

`POST /story-voice-renderings`

Request (JSON): `storyId`, `experiencePlanId`,
`experiencePlanProcessingVersion`, `sourceRepresentationId`, `sourceText`,
`renderingMode` (`syntheticNarration` only), `processingVersion`

Response (JSON): `audioBase64`, `contentType`, `renderingMode`,
`providerLabel`, `modelLabel`, `processingVersion`, provenance echo fields

Errors: `{"error":"..."}` with 400 / 401 / 502 / 500

v1 mode is ordinary synthetic narration only — not voice cloning.

## Provenance

`StoryVoiceRendering` retains:

- `storyId`
- `experiencePlanId` + `experiencePlanProcessingVersion`
- `sourceRepresentationId` (transcript)
- `renderingMode`
- `providerLabel` / `modelLabel` / `processingVersion` (`hs12.6.v1`)
- `createdAt`, media reference, content type, byte length

## Persistence

- Metadata: `{appDocs}/hero_story/story_voice_renderings/{id}.json`
- Latest index: `_by_story.json`
- Audio bytes: existing `StoryMediaStoragePort`
- Regeneration creates a **new id** (does not overwrite in place)

## Fallback behavior

Consent missing / proxy unavailable / provider failure / empty-malformed audio /
persistence failure → no artifact persisted; original recording remains
playable; recoverable error surfaced.

## Files changed (high level)

- Domain: `VoiceRenderingPort`, `StoryVoiceRendering`, `VoiceRenderingMode`,
  consent gate, repository interface
- Application: `RenderStoryVoiceUseCase`, DTOs, providers
- Infrastructure: proxy + in-memory adapters, file/in-memory repos, parser
- Proxy: `OpenAiSpeechClient`, `StoryVoiceRenderingHandler`, `/story-voice-renderings`
- Presentation: Hero Story narrated-version section + controller
- ADR: HS-ADR-076
- Tests: use-case, UI, consent, proxy

## Validation commands

```bash
flutter analyze
flutter test test/features/hero_story/application/use_cases/hs12_6_voice_rendering_use_case_test.dart
flutter test test/features/hero_story/presentation/hs12_6_voice_rendering_ui_test.dart
flutter test test/features/hero_story/domain/value_objects/story_consent_test.dart
flutter test test/features/hero_story # HS.12.1–12.5 + related
flutter test
cd services/ai_proxy && dart test
```

## Device validation status

**Not performed** in this environment (no iPhone/device attached).

## Known limitations

- Only `syntheticNarration` (ordinary TTS); no Hero-voice transformation or cloning
- OpenAI TTS 4096-character input limit
- Generated narration is standalone audio; experience player still defaults to original recording
- No music generation, discovery, personalization, or behavioral evidence
