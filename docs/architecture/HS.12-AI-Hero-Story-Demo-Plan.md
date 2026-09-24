# HS.12 — AI Hero Story Demo

**Status:** PLANNING ONLY — no production code in this document  
**Date:** 2026-09-24  
**Phase:** HS.12 — Demo-ready Hero Story experience  
**Authority:** current code under `lib/features/hero_story/`, `services/ai_proxy/`, and accepted ADRs through HS-ADR-070

The hero owns the story. AI owns the presentation.

This plan is the smallest vertical path that can show that principle in two to four minutes. It does not build a personalization engine, a music platform, or voice cloning.

---

## A. Current-State Assessment

### What the live path does today

Tell Your Story is an imperative screen, not a named route. Entry is the Heroes tab (`HeroCatalogScreen`) or an empty My Stories state. `TellYourStoryScreen` drives `TellYourStoryController`, which drives `RecordingSessionService`, which completes capture through the existing `CompleteStoryCaptureUseCase`.

```text
Prepare → Record → Stop → Review → Accept → Consent → Story Saved
```

After save the user stays on a **Story Saved** panel (`_CompletedStep`). The body says the story was safely saved and remains private. It prints the story id. The user must tap **View Story**, **My Stories**, or **Done**.

**View Story** replaces the route with `OwnedStoryDetailScreen`. That screen is an owner operations page: title, date, duration, privacy and lifecycle chips, publication actions, original-recording playback, a manual AI Transcript section, consent summary, and archive. There is no hero portrait, no “a real story from a real person,” no themes, and no experience player.

Save does not open Reflect, Today’s Experience, or adaptive discovery. The Reflect tab is a separate shell destination. The demo does not need HS.8.

### Recording reliability

| Concern | Current code |
|---|---|
| Permission | `DeviceRecordingPort` + `permission_handler`. iOS `NSMicrophoneUsageDescription` is set. Web permission is requested only from the Prepare **Allow microphone** tap. |
| Timer | One-second poll of session elapsed while recording. |
| Stop → Review | `stopRecording()` sets step `review` and phase `reviewing` and clears the error. |
| Intentional stop | Both adapters set `_expectingIntentionalStop` and clear the interruption sentinel (`_tempPath` on device, `_segmentStartedAt` on web) **before** platform `stop()`. The controller ignores `DeviceRecordingFailureKind.interrupted` while `_intentionalStopInProgress` is true, and ignores a late `interrupted` on a clean review. |
| Genuine interruption | Still maps to “Recording was interrupted…” |
| Review | Play, title, Accept, Retake, Discard. |
| Playback | `just_audio` `AudioPlayer`. Device uses `setFilePath` (`.m4a` / `audio/mp4`). Web uses a data URI of WAV bytes. |
| Save | Accept persists Story + original audio representation and calls `markCaptureRecorded()`. Consent is a later optional step. |

Focused tests already encode the stop contract in `test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart`:

- intentional Stop transitions to review without interruption banner
- intentional Stop review screen has controls and no error banner
- late interrupted signal after clean Stop does not reintroduce banner
- interrupted during intentional Stop does not surface banner
- genuine interruption while recording still shows interruption message
- non-interruption device failures remain visible on review

This environment has no Flutter SDK and no iPhone, so those tests were read, not executed, and the iPhone path was not re-run. Slice 1 must re-run them and confirm Stop on a device. The code path is present; device proof is not.

### Defect that will break a retake-by-discard demo

`RecordingSessionService.discard()` cancels the temp file and `_clearSessionIdentity()` returns the session to `idle` with null ids. The controller then shows Prepare. `continueToRecord()` does not call `beginSession()` again. The next `startRecording()` hits `_ensureActiveSession()` and throws `Recording session has not been begun.`

Retake is safe: it keeps the hero and story ids and returns to `ready`. Discard inside the same screen is not. Slice 1 fixes this. Until then, a demo that discards must leave Tell Your Story and enter it again.

### Persistence and playback

- Native: durable file repositories and `LocalFileStoryMediaStorageAdapter` under app documents.
- Web: in-memory repositories. A refresh loses the story. Do not use web refresh as the live demo.
- Saved-story playback: `OwnedStoryPlaybackController` + `LoadOwnedStoryMediaUseCase` + `just_audio`.
- Seeker `StoryConsumeScreen` shows text and a byte count. It does not play audio. The demo player is a new owner experience, not Story Consume.

### AI that already exists — and what it is for

`services/ai_proxy` (`bin/server.dart`, default port 8787) is the only AI stack:

| Method | Path | Used for |
|---|---|---|
| POST | `/story-transcriptions` | HS.11 speech-to-text |
| POST | `/story-builder-questions` | SB.7 coach |
| POST | `/story-understanding` | SB.8 **Story Builder** understanding |
| POST | `/story-authoring` | SB.11 proposal authoring |
| GET | `/health` | liveness, auth-exempt |

Auth is optional `EH_AI_PROXY_AUTH_TOKEN` bearer. Errors are `{"error": "..."}` with 400 / 401 / 502 / 500. OpenAI types stay inside the proxy (`OpenAiChatClient`, `OpenAiTranscriptionClient`). Flutter talks to ports.

HS.11 transcription is real and reusable:

- Port: `StoryTranscriptionPort`
- App adapter: `ProxyStoryTranscriptionAdapter` when `EH_AI_PROXY_URL` is set; otherwise `InMemoryStoryTranscriptionAdapter`
- Use case: `StartOwnedStoryTranscriptionUseCase` → `TranscribeStoryRepresentationUseCase`
- UI: **Start Transcription** on Owned Story Detail, after processing consent and AI-transformation consent
- HS-ADR-069: transcription does not start at Accept
- Failure stores a failed job and leaves the original recording in place
- Transcript is a derived `StoryRepresentation` (`format: transcript`, `origin: derived`)

The in-memory transcription adapter is for tests. A live “it understood *this* story” demo needs the proxy and `OPENAI_API_KEY`.

### Two understandings that must not be overloaded

| Type | What it is | Why it is the wrong demo object |
|---|---|---|
| `StoryUnderstanding` (HS.4) | Separate aggregate. Catalog candidates: subjects, challenges, narrative theme ids, outcomes, suitability, spirituality, plus `StoryObservation` kinds `languageSignal`, `contentMention`, `uncertainty`, `other`. Hero review before anything is applied to Story. | No turning point, no pauses, no music, no presentation direction. No app provider and no proxy adapter. |
| `StoryBuilderUnderstanding` (SB.8) | Value object on a Builder session. Has themes, narrative elements, and `UnderstoodKeyStoryElements` (challenge, turning point, decision, outcome, …). | Requires Builder purpose, structure, and response ids. A recorded story has none of those. `POST /story-understanding` is this contract. |

`SourceSpanReference` already exists for pointing at a representation by character offset or timestamp. `StoryConsent` already separates recorded, processing, publication, and AI transformation. There is no voice-cloning consent. `HeroProfile` has a display name and no portrait. `AppTheme` is Material 3 from seed `0xFFD4AF37`.

There is no Story Experience Plan, no music playback, no pause-as-presentation, and no voice-rendering port.

### Reuse list

Reuse `DeviceRecordingPort` and both recording adapters, `RecordingSessionService`, `CompleteStoryCaptureUseCase`, `Story` + original audio representation, `StoryConsent`, `UpdateStoryConsentUseCase`, `StartOwnedStoryTranscriptionUseCase`, `StoryTranscriptionPort`, the AI proxy process, `just_audio`, `AppTheme`, `OwnedStoryPlaybackController`’s media load, and `SourceSpanReference`’s span idea.

Leave HS.4, SB.7–SB.13, HS.6–HS.8 discovery, publication lifecycle, and Reflect alone.

---

## B. Demo User Journey

Primary device: iPhone, durable storage, proxy reachable from the phone. Web is a secondary check and must not be refreshed mid-demo.

```text
Heroes
  → Tell Your Story
  → Allow microphone
  → Continue
  → Record 30–90 seconds
  → Stop                         (Review, no error banner)
  → optional Play / title
  → Accept recording
  → grant processing + AI transformation
  → Save consent
  → Hero Story screen            (back is available; Reflect is not opened)
  → Understand my story          (explicit; this is the HS-ADR-069 action)
  → Story Understanding appears
  → Create Hero Story Experience
  → Play
       voice of the original recording
       music follows the segments
       silence before the turning point
  → My recording                 (always available if any AI step failed)
```

Consent stays explicit. Accept still only records `recordedAt`. The consent step, or the Hero Story screen if the user skipped, collects processing and AI-transformation consent before any upload. That consent covers transcription, a presentation reading of the transcript, and an experience plan for the existing recording. It does not cover a synthesized voice.

The Hero Story screen is the post-save destination. `OwnedStoryDetailScreen` stays the operations page (publish, archive, transcript edit) behind a secondary control.

---

## C. Story Experience Plan

Smallest model that can drive the demo. It is a derived presentation artifact keyed by `StoryId`. It is not a field on `Story`, not an HS.4 `StoryUnderstanding`, and not an SB.8 `StoryBuilderUnderstanding`.

```text
Canonical Story
  original audio representation
  transcript representation
        ↓
CapturedStoryReading          (what the audience reads)
        ↓
StoryExperiencePlan           (how the player presents it)
        ↓
Hero Story player
```

### CapturedStoryReading

Grounded reading of one transcript. Every claim carries a span into that transcript (character offsets and, when known, recording timestamps). Allowed claims:

- narrative movement (one or two sentences about the story, e.g. “The story shifts from uncertainty to determination here.”)
- themes (short labels)
- challenge
- turning point
- outcome
- meaningful moments (quote span + one-line note)

The schema has no field for personality, diagnosis, self-worth, or motive. The proxy instructions tell the model to describe the story’s movement and to quote only text present in the transcript. The handler drops a claim whose span is outside the transcript.

The hero remains authoritative. v1 correction is a visible choice: play the experience, or play the original recording. Inline claim editing can wait.

### StoryExperiencePlan

```text
StoryExperiencePlan
  storyId
  sourceRecordingRepresentationId
  sourceTranscriptRepresentationId
  processingVersion
  voiceStrategy          original | enhanced | aiVoice
  segments[]
  provenance             provider label, model label, createdAt

ExperienceSegment
  purpose                opening | challenge | uncertainty | turningPoint
                         | decision | resolution | closing
  presentationDirection  quiet | courageous | strong | hopeful
                         | vulnerable | reflective | inspirational
  span                   into the transcript / recording
  pauseBefore            Duration, capped
  music                  stem id, intensity, transition

MusicCue
  stemId                 quiet | tension | build | expansive | resolve
  intensity              low | medium | high
  transition             fadeIn | hold | fadeOut | crossfade | silence
```

v1 `voiceStrategy` is always `original`. `enhanced` and `aiVoice` are stored as future values and rejected at generation time until slice 6.

The model describes segments. It does not choose audio files. A closed stem map in the player turns `purpose` into a stem:

| Purpose | Stem | Intensity | Transition |
|---|---|---|---|
| opening | quiet | low | fadeIn |
| challenge | tension | medium | hold |
| uncertainty | quiet | low | fadeOut |
| turningPoint | — | — | silence, plus `pauseBefore` |
| decision | build | medium | fadeIn |
| resolution | expansive | high | crossfade |
| closing | resolve | medium | fadeOut |

Pause cap for v1: 0.6–2.0 seconds, and at least the turning-point segment asks for one. The canonical audio file is never rewritten. Silence is a playback gap.

Plans are cached (file repository beside the other Hero & Story stores, in-memory in tests and on web) because regenerating them is nondeterministic and costs a model call. They stay recomputable. Deleting a plan does not damage the Story.

No new domain event is required for the demo. The use case returns the plan to the screen. Add an event later only when another context must react.

---

## D. Architecture Impact

### Domain

Add, under Hero & Story:

- `CapturedStoryReading` value object and a small repository
- `StoryExperiencePlan` value object (or a thin aggregate whose only invariant is “references this story’s recording and transcript, segments non-empty, pauses in range, voice strategy allowed by consent”)
- `StoryExperiencePlanRepository`
- `CapturedStoryReadingPort` and `StoryExperiencePlanPort` next to the existing domain ports (`StoryTranscriptionPort` is the pattern)

Do not add these fields to `Story`. Do not extend `ObservationKind`. Do not call `Story.classify()` from the demo path.

### Application

- `GenerateCapturedStoryReadingUseCase` — requires owner, transcript representation, processing consent, AI-transformation consent. On failure, returns failure and leaves playback on the original recording.
- `GenerateStoryExperiencePlanUseCase` — same gates, requires a reading. On failure, the reading can still show and playback stays original.
- A presentation-timeline builder that is a pure function of plan + recording duration. No `DateTime.now()` inside it.

### Infrastructure

- Proxy adapters beside `ProxyStoryTranscriptionAdapter`, selected by the same `EH_AI_PROXY_URL` define. In-memory adapters for tests.
- File repositories following `FileStoryRepository`.
- Demo stem assets referenced only by stem id from the player. Domain code does not contain file paths or vendor names.

### AI proxy

Same server, same auth middleware, same `OpenAiChatClient.completeJson`, same error JSON.

Proposed routes, matching the existing plural resource style (`/story-transcriptions`, not a guessed singular path):

- `POST /captured-story-readings`
- `POST /hero-story-experience-plans`

Request bodies are EH-owned JSON: transcript text, language, story id, representation id, and for the plan the accepted reading. Responses echo ids plus `providerLabel` and `processingVersion`. The handler validates the schema and span bounds before returning 200. Malformed model output is 502, as the other chat handlers already do.

Do not retarget `POST /story-understanding`. That route remains SB.8.

### Presentation

New `HeroStoryScreen` using `Theme.of(context)` and the gold seed. Layout:

```text
HERO STORY
[monogram from HeroProfile.displayName]
"title"
▶  Play my recording
A real story from a real person

Story Understanding
  movement, themes, challenge, turning point, outcome

[ Understand my story ]          until a reading exists
[ Create Hero Story Experience ] once a reading exists
[ Play experience ]              once a plan exists
```

`HeroProfile` has no image. The demo uses a monogram. A portrait pipeline is out of scope.

`OwnedStoryDetailScreen` keeps publication, archive, and transcript edit. The completed capture step’s primary button opens `HeroStoryScreen` and keeps My Stories / Done as the way back.

Playback of the experience is a presentation controller with two `just_audio` players (voice and music). It schedules pauses and stem changes from the timeline. It is not a new audio framework.

### Tests

- Domain: reading and plan invariants, span required, pause cap, `aiVoice` rejected without voice-cloning consent.
- Application: consent gate, transcription-missing failure, plan failure does not delete the recording, timeline function is deterministic.
- Proxy: fake chat client, 400 on bad JSON, 502 on schema violation, span outside transcript dropped or rejected.
- Presentation: Stop still has no banner; discard can record again; Hero Story screen shows title and original play with no reading; reading section appears from a fake port; music failure still plays voice.

### Explicitly unchanged

- `Story` aggregate shape, lifecycle, visibility, classification, representations
- `StoryUnderstanding` (HS.4) and `StoryBuilderUnderstanding` (SB.8)
- `POST /story-understanding`, `/story-authoring`, `/story-builder-questions`, `/story-transcriptions`
- Discovery, relevance ranking, Today’s Experience, UI.3 selection
- Behavioral evidence and pattern detection
- Publication / Reflect flows
- Riverpod as composition only
- Provider SDKs out of domain and application

### Proposed decisions (accept when the slice starts, not before)

| Id | Decision |
|---|---|
| HS-ADR-071 | A Story Experience Plan is derived presentation. It is not stored on `Story` and it does not rewrite narrative, transcript, or the original recording. |
| HS-ADR-072 | A captured-story reading is a new grounded transcript reading. It is not HS.4 and not SB.8. Claims require source spans. The schema cannot carry a psychological diagnosis. |
| HS-ADR-073 | Experience playback is a timeline over the original recording, demo stems, and inserted silence. Any failed enhancement falls back to the original recording. |
| HS-ADR-074 | Voice cloning is a later derived audio representation behind a port. It requires `voiceCloningApprovedAt`, which recording consent and AI-transformation consent do not set. |

---

## E. PR-Sized Implementation Plan

Six slices. One slice per PR. Slices 1–5 are the demo. Slice 6 is designed here and built later.

### Slice 1 — Recording reliability and Save handoff

- Re-begin the session after Discard so Prepare → Record works again. Add a regression test.
- Re-run the existing Stop tests. On an iPhone, Stop must land on Review with play, retake, discard, and accept, and without the interruption banner.
- After consent (or skip), the primary action opens the Hero Story screen shell instead of stopping on “Story Saved.” Keep My Stories and Done.
- Do not auto-start transcription.

### Slice 2 — Hero Story presentation

- Build the screen in section D on top of the existing theme: monogram, title, “A real story from a real person,” original play via the current media load and `just_audio`.
- Secondary link to the existing owner detail for publish and archive.
- Empty understanding and empty experience states are calm, not errors.

### Slice 3 — Transcription and Story Understanding

- **Understand my story** checks consent, calls `StartOwnedStoryTranscriptionUseCase`, then `GenerateCapturedStoryReadingUseCase`.
- Add `POST /captured-story-readings` on the existing proxy.
- Show movement, themes, challenge, turning point, and outcome with their spans.
- If transcription or reading fails, the original play button still works and the screen says the recording is ready.

### Slice 4 — Story Experience Plan

- **Create Hero Story Experience** calls `GenerateStoryExperiencePlanUseCase` and `POST /hero-story-experience-plans`.
- Persist the plan outside `Story`.
- Show the segments (purpose, direction, pause, music cue) before playback exists.
- If generation fails, slice 3’s reading and the original recording remain.

### Slice 5 — Music, pauses, and the player

- Commit a closed set of short demo-safe stems (original or clearly licensed). No generator, no catalog service.
- Presentation player: voice track is the original file; music track follows the stem map; turning-point `pauseBefore` is real silence.
- Missing stem or player error: voice-only, same screen.
- This slice is the emotional demo. Stop here for the live showing.

### Slice 6 — My AI Voice (later)

Not required for the demo. See section G. Do not start this PR until slices 1–5 have been shown.

---

## F. Demo Script

Target length: about three minutes. Stand on the iPhone. The proxy is already running with a key. The app is built with `EH_AI_PROXY_URL` and `EH_TRANSCRIPTION_MODE=proxy`.

Have one story already saved as a backup, so a microphone failure can jump to step 6. Do not mention the backup unless you need it.

**0:00 — The story is human**

Tap **Heroes**, then **Tell Your Story**.  
Say: “I have a story. I’m going to tell it the way I would tell it to a person.”

**0:20 — Record**

Tap **Allow microphone**, then **Continue**, then **Start**.  
Speak 45–60 seconds with a shape the plan can hear:

1. A quiet opening.  
2. A difficulty.  
3. A sentence of uncertainty.  
4. A short line you want silence before, such as “I knew I had to step forward.”  
5. “And that’s what I did.”  
6. One closing sentence.

The audience sees the timer moving and no extra chrome.

**1:20 — Stop and review**

Tap **Stop**.  
The audience sees **Review your recording**, the duration, and Play / Accept / Retake / Discard. They do not see a red interruption banner.  
Optionally tap **Play** for a few seconds so they hear the raw voice.  
Type a title, for example “Stepping Forward.”  
Tap **Accept recording**.

**1:40 — Consent, then the story looks like a story**

Turn on processing and AI transformation. Say: “This lets Everyone’s Heroes read the recording so it can present it. It does not let it speak as me.”  
Tap **Save consent choices**.  
The audience sees the Hero Story screen: monogram, the title, **Play my recording**, and “A real story from a real person.” The way back is the app bar. Reflect is not in this path.

**2:00 — Understanding**

Tap **Understand my story**.  
Say: “Everyone’s Heroes is transcribing my voice and reading the story.”  
When the section appears, read one line aloud — the movement sentence or the turning point — and point at the fact that it quotes the recording.  
Say: “It understood the story. It did not diagnose me.”

**2:30 — The transformation**

Tap **Create Hero Story Experience**. A short beat while the plan is built. Segments appear (opening, challenge, turning point, resolution).  
Tap **Play experience**.

What the audience hears, in order:

- the same voice, quiet music under the opening  
- the music tightens on the difficulty  
- the music recedes on the uncertainty  
- silence before “I knew I had to step forward”  
- music builds on the decision  
- a fuller bed on the last sentence, then it resolves  

Say, as it ends: “My story is still my story. Everyone’s Heroes helped me present it in a way I would not have built myself.”

If music fails, tap **Play my recording** and say the recording was never at risk. That is the principle, not a rescue.

---

## G. Future Voice-Cloning Architecture

The canonical story does not change when this is added.

```text
Story
  original audio representation          My Voice
  transcript representation
        ↓
StoryExperiencePlan.voiceStrategy
  original     → play the original representation
  enhanced     → original audio + the slice 5 timeline
  aiVoice      → a derived audio representation
        ↓
VoiceRenderingPort
        ↓
EH AI proxy (vendor client lives only here)
        ↓
StoryRepresentation
  format: audio
  origin: derived
  transformation: narration
  isAiGenerated: true
  isApproved: false until the hero approves
  sourceRepresentationId: the transcript
```

`StoryConsent` gains `voiceCloningApprovedAt`, with grant and revoke, independent of `aiTransformationApprovedAt`. The plan generator may emit `voiceStrategy: aiVoice` only when that timestamp is set. Otherwise it emits `original`.

Directions (courageous, strong, hopeful, vulnerable, reflective, inspirational) are fields on the plan segment. They direct the render. They are not written onto `HeroProfile` and they are not behavioral evidence.

The player’s fallback order is: approved AI-voice representation → original recording. A failed render leaves **My Voice** on the same screen.

No ElevenLabs (or other vendor) type crosses the domain or application boundary. The first implementation of this slice is a proxy endpoint plus `VoiceRenderingPort`, after the demo in slices 1–5 has been given.

---

## Definition of demo success

A person records a real story, sees that Everyone’s Heroes read its structure without inventing a diagnosis, then hears that same voice presented with music that follows the story and a silence before the line that matters. The original recording still plays. The story was not rewritten.

## Known discrepancies (reported, not fixed here)

- `docs/analysis/HS-UX-recording-review-stop-state.md` matches the current stop code. Device confirmation is still owed by slice 1.
- `POST /story-understanding` is SB.8. HS.4 `StoryUnderstanding` has no production adapter. This plan does not “finish HS.4” in order to demo presentation.
- Web capture is in-memory. A refresh is data loss. The live demo is the native app.
- `HeroProfile` has no portrait. The demo uses a monogram.
- Flutter tests were not executed in this planning environment because the Flutter SDK is not installed here.
