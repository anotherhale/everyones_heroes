# HS.9 — Production Hero Story Recording & Capture — Implementation Report

**Status:** IMPLEMENTED (local durable + device recording vertical slice)  
**Date:** 2026-09-14  
**Phase:** HS.9  
**Branch:** `cursor/hs9-production-recording-capture-d189`

---

## Executive Summary

HS.9 delivers the production-ready vertical slice that lets a Hero **Tell Your Story**: prepare, grant microphone permission, record audio (pause/resume), review, retake/discard, accept into durable local media, create a draft `Story` through existing HS.3 `CompleteStoryCaptureUseCase`, and set independent processing/AI consent.

This builds on HS.1–HS.8 without redesigning Story, Capture, Consent, Discovery, or Adaptive Experience.

**First Real Hero Story success definition (local):** after accept, killing and reopening the app still finds the private draft Story with durable original media and `recorded` consent — without backend or AI.

---

## Existing Architecture Reused

| Component | Reuse |
|-----------|--------|
| `Story` / `Story.createFromCapture` | Unchanged canonical aggregate |
| `CompleteStoryCaptureUseCase` | Extended only with optional `mediaFilePath` → `storeFromFile` |
| `CancelStoryCaptureUseCase` / `UpdateStoryConsentUseCase` | Wired via Riverpod; consent gates remain independent |
| `CaptureCompletionStore` | Interface kept; durable `FileCaptureCompletionStore` added |
| `StoryMediaStoragePort` | Extended with `storeFromFile`; local file adapter added |
| `Hero` / `CreateHeroUseCase` | Local bootstrap until Identity BC |
| Heroes tab navigation | Entry CTA only; no second nav system |
| HS.4–HS.8 pipeline | Untouched; capture does not invoke AI or H.2 evidence |

Legacy `StoryCapturePort` was **not** expanded (HS-ADR-061).

---

## Implementation

### Recording

- `DeviceRecordingPort` (application boundary) with prepare/permission/start/pause/resume/stop/cancel + failure stream
- `RecordPackageDeviceRecordingAdapter` — package `record` + `permission_handler` (audio/m4a MVP)
- `FakeDeviceRecordingAdapter` — deterministic CI/tests
- `RecordingSessionService` — session orchestration (not a domain aggregate)

### Permissions

- Explicit `DevicePermissionStatus`: notDetermined / granted / denied / permanentlyDenied / unavailable
- Prepare UI shows status and settings guidance when permanently denied/unavailable
- Domain has no permission logic

### Local media

- Temp recordings under app temp/cache
- Accept → `StoryMediaStoragePort.storeFromFile` → durable `file://` under documents/`hero_story/media`
- Temp deleted only after successful capture

### Review / retake / discard

- Review step: play/stop (just_audio), optional title, Accept / Retake / Discard
- Retake: new `sessionId` + representation id; prior temp deleted; no Story until accept
- Discard: cancel temp + clear session

### Consent

- Independent switches for **Processing** and **AI** after accept
- Publication deferred (private draft)
- Wired through `UpdateStoryConsentUseCase`
- Recording success sets `recordedAt` via existing `markCaptureRecorded`

### Story Capture / persistence

- UI → controller → `RecordingSessionService.accept` → `CompleteStoryCaptureUseCase`
- Durable: `FileHeroRepository`, `FileStoryRepository`, `LocalFileStoryMediaStorageAdapter`, `FileCaptureCompletionStore`
- Session manifests for recovery under `recording_sessions/`

### Recovery

- Storage failure on accept: remain reviewing; temp retained; retry allowed
- Idempotent completion by `sessionId` survives process restart via durable completion store
- Device interruptions surface via failure stream / user-visible error

---

## Files Changed (important)

### Application / ports

- `application/recording/device_recording_port.dart`
- `application/recording/recording_session_service.dart`
- `application/recording/recording_session_state.dart`
- `application/recording/recording_session_manifest.dart`
- `application/use_cases/complete_story_capture_use_case.dart` (+ `mediaFilePath`)
- `application/use_cases/list_hero_owned_stories_use_case.dart` (owner drafts; not Discover*)
- Capture / recording / hero bootstrap Riverpod providers

### Infrastructure

- `infrastructure/media/local_file_story_media_storage_adapter.dart`
- `infrastructure/media/in_memory_story_media_storage_adapter.dart` (`storeFromFile`)
- `infrastructure/repositories/file_hero_repository.dart` / `file_story_repository.dart`
- `infrastructure/persistence/*_snapshot_mapper.dart`
- `infrastructure/capture/file_capture_completion_store.dart`
- `infrastructure/recording/record_package_device_recording_adapter.dart`
- `infrastructure/recording/fake_device_recording_adapter.dart`

### Presentation

- `presentation/screens/tell_your_story_screen.dart`
- `presentation/providers/tell_your_story_controller.dart`
- Heroes catalog **Tell Your Story** entry
- `app/app_composition_root.dart` — durable defaults + real recorder wiring

### Platform

- iOS `NSMicrophoneUsageDescription` (+ camera string reserved)
- Android `RECORD_AUDIO` / `CAMERA` permissions
- Packages: `record`, `permission_handler`, `path_provider`, `just_audio`, `path`, `crypto`

### Docs

- ADRs HS-ADR-060…066 in `architecture-decisions.md`
- This report

---

## Architecture

```text
Presentation (TellYourStoryScreen / TellYourStoryController / Riverpod)
        ↓
Application (RecordingSessionService + Complete/Cancel/UpdateConsent use cases)
        ↓
Domain (Story / Hero / StoryConsent / StoryRepresentation / Provenance)
        ↑
Ports (StoryMediaStoragePort + DeviceRecordingPort)
        ↑
Infrastructure (LocalFile media, File repos, record adapter, Fake adapter)
        ↑
Device APIs (microphone / filesystem)
```

Domain remains free of Flutter, Riverpod, camera/recorder packages, and filesystem APIs.

---

## State Model

| Concern | Layer | Model |
|---------|-------|--------|
| Story lifecycle | Domain | Existing `StoryLifecycleStatus` (draft after capture) |
| Consent gates | Domain | Existing `StoryConsent` timestamps |
| Recording UX | Application/UI | `RecordingSessionPhase` + `TellYourStoryStep` |

These are **not** conflated. `RecordingSessionPhase.recording` ≠ `StoryLifecycleStatus`.

---

## Failure Handling

| Failure | Outcome |
|---------|---------|
| Mic permission denied | Clear UI status + settings guidance |
| Mic unavailable | Session failed; no capture |
| Storage failure on accept | Stay reviewing; keep temp; retry |
| Playback failure | Error; do not silently accept corrupt media |
| Retake | Temp cleanup; new session; no domain mutation |
| Duplicate session complete | Idempotent replay from durable completion store |

---

## Testing

| Gate | Result |
|------|--------|
| Focused recording/session/infra tests | Passing (prior commits + this slice) |
| UI / controller HS.9 tests | Passing |
| Integration durable e2e | Passing |
| Composition root | Passing (injectable roots for tests) |
| `dart analyze` | Clean of errors (pre-existing infos only) |
| Full `flutter test` | Re-run after composition-root fix — see commit notes |

---

## Device Validation

**Environment:** Linux Cloud Agent VM (no iOS device / no Android SDK / no physical microphone).

| Check | Result |
|-------|--------|
| App launches (composition) | Validated in tests with fake recorder + durable dirs |
| Tell Your Story entry | Validated (widget test) |
| Camera permission | N/A for audio MVP; Android/iOS strings/manifest present |
| Microphone permission UX | Validated with fake permission states |
| Real device record/pause/playback | **Not performed** — no iPhone/Android device in this environment |
| Durable accept across “relaunch” | Validated via file-backed repo/media/completion integration test |

Manual iPhone/TestFlight walkthrough remains recommended before claiming production device readiness.

---

## Deferred Work

- Slice C: Submit-for-processing UX, owner draft list UI, optional async transcription hook
- Slice D: Remote object storage / resumable upload
- Video recording mode
- Full Identity/auth BC (local Hero bootstrap remains temporary — HS-ADR-065)
- Production AI providers
- Changing HS.8 adaptive selection or Discover* for private drafts

---

## Architectural Deviations

None material from the HS.9 plan.

Clarifications:

1. **Audio MVP** (not video) per plan §U / HS-ADR-063 — aligns with HS.3 audio representation hardcoding.
2. **Widget tests** drive some recording transitions via the Riverpod controller (with UI assertions) because autoDispose + periodic timers make pure `tap`+`pumpAndSettle` unreliable; end-to-end capture is covered by controller + durable integration tests.
3. **Composition root** accepts injectable storage directories for tests; production still uses path_provider documents/temp.

---

## Temporary Development Identity

Until Identity BC exists, `ensureActiveLocalHeroProvider` creates or selects a local active Hero (`ActiveLocalHeroStore` persists the id under the durable root). Presentation does not hard-code Hero IDs.
