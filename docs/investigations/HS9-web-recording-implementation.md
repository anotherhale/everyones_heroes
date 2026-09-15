# HS.9 Web Recording Implementation

**Date:** 2026-09-15  
**Branch:** `cursor/hs9-web-recording-runtime-fix-21c6`  
**Status:** Implementation complete (automated verification green)  
**Context:** Flutter Web Tell Your Story at `http://127.0.0.1:18080`  
**Prior work:**  
- `docs/investigations/HS9-web-microphone-permission-investigation.md` (PR #24)  
- `docs/investigations/HS9-web-recording-runtime-investigation.md` (PR #25)

---

## Executive Summary

PR #24 and #25 correctly diagnosed that Flutter Web bound
`UnavailableDeviceRecordingAdapter` as `DeviceRecordingPort`, so prepare /
Allow microphone never reached the browser. This change **wires a real web
recording adapter** and keeps browser APIs behind infrastructure.

**Root cause fixed:** in-memory / web composition now overrides
`deviceRecordingPortProvider` with
`RecordPackageWebDeviceRecordingAdapter` (`record` / `record_web`), not
`UnavailableDeviceRecordingAdapter`.

**Web format:** WAV (`AudioEncoder.wav`) — always supported by `record_web`.

**Artifact:** stop materializes `Uint8List` bytes + synthetic `memory://…`
marker. Application/session/media-storage use bytes; no Blob / `dart:html`
types cross the port.

---

## Current Architecture

```text
TellYourStory UI / Controller
        │
        ▼
RecordingSessionService
        │
        ▼
DeviceRecordingPort  ◄── unchanged contract (optional bytes on artifact)
        │
        ├── native durable: RecordPackageDeviceRecordingAdapter
        │                     (permission_handler + aacLc + dart:io path)
        │
        └── web / in-memory: RecordPackageWebDeviceRecordingAdapter
                              (AudioRecorder.hasPermission + wav
                               + object-URL → bytes + revoke)
        │
        ▼
CompleteStoryCaptureUseCase (mediaBytes or mediaFilePath)
        │
        ▼
StoryMediaStoragePort (in-memory on web)
```

`UnavailableDeviceRecordingAdapter` remains for genuinely unsupported hosts
and for focused contract tests. It is **not** the normal web composition
selection.

---

## Implementation Changes

1. **Composition** (`lib/app/app_composition_root.dart`)  
   `_initializeInMemoryHeroStory()` sets:
   - `useRealDeviceRecordingProvider = true`
   - `deviceRecordingPortProvider = createRecordPackageWebDeviceRecordingAdapter()`

2. **Web adapter**  
   `RecordPackageWebDeviceRecordingAdapter` — permissions via
   `AudioRecorder.hasPermission`, encoder WAV, stop → fetch object URL bytes,
   revoke URL, lazy `AudioRecorder` construction.

3. **Artifact port extension**  
   `LocalRecordingArtifact.bytes` / `hasBytes` — application-facing bytes only.

4. **Session accept**  
   Prefer `mediaBytes` when `hasBytes`; skip filesystem delete for
   `memory://`, `blob:`, `http(s):` markers.

5. **Review playback**  
   Controller uses `AudioSource.uri(Uri.dataFromBytes(...))` when bytes exist.

6. **Object URL I/O seam**  
   Conditional export stub / web (`package:web` fetch + `revokeObjectURL`).

7. **Providers**  
   Recording providers document / export the web factory consistently.

---

## Web Recording Design

| Concern | Native adapter | Web adapter |
|---------|----------------|-------------|
| Permission | `permission_handler` | `AudioRecorder.hasPermission(request: …)` |
| Encoder | AAC-LC | **WAV** (`AudioEncoder.wav`) |
| Stop output | filesystem path | object URL → **bytes** + `memory://` marker |
| Cleanup | delete temp file | revoke object URL; cancel releases stream |

**Why WAV:** `record_web` documents WAV as always supported via MediaRecorder /
encoder checks. AAC-LC is not assumed on web (native path keeps AAC-LC).

Browser-specific types (`Blob`, object URLs, `package:web`) stay in:

- `record_package_web_device_recording_adapter.dart`
- `web_object_url_io_web.dart`

Application/domain only see `Uint8List`, `String` markers, and port enums.

---

## Permission Flow

```text
startFlow / prepare
  → checkMicrophonePermission()
      → hasPermission(request: false)
      → granted | notDetermined | unavailable (on hard failure)

Allow microphone (user gesture)
  → requestMicrophonePermission()
      → hasPermission(request: true)  // triggers getUserMedia when needed
      → granted | denied

Start recording
  → may re-check / request if not granted
  → AudioRecorder.start(RecordConfig(encoder: wav), path: …)
```

Permission is **not** requested at app startup. The Tell Your Story
“Allow microphone” control remains the intentional user gesture.

Denied / unavailable map to existing
`DevicePermissionStatus` / `DeviceRecordingFailureKind` values rather than a
silent generic “unavailable” when the browser can record.

---

## Media Artifact / Storage Handling

1. `stop()` returns `LocalRecordingArtifact` with:
   - `bytes`: recorded WAV payload
   - `localFilePath`: `memory://recording-<uuid>.wav` (log/manifest marker)
   - `contentType`: `audio/wav`
2. Review playback: data URI from bytes (no filesystem).
3. Accept: `CompleteStoryCaptureRequest.mediaBytes` → existing in-memory
   `StoryMediaStoragePort` on web.
4. Production remote persistence remains outside HS.9 web MVP scope; the
   bytes path matches the capture use case’s existing `mediaBytes` contract.

---

## Testing

| Area | Coverage |
|------|----------|
| Composition | In-memory root resolves `RecordPackageWebDeviceRecordingAdapter` |
| Web adapter | Factory, video rejection, cancel/dispose without plugin binding |
| Session bytes | Prepare → record → stop → accept with bytes-only fake port |
| Unavailable | Existing contract tests retained (not selected as web default) |
| Broader HS.9 | Existing suite preserved |

Browser MediaRecorder / getUserMedia are exercised through the
`record` / `record_web` stack at runtime; unit tests inject
`readObjectUrlBytes` / `revokeObjectUrl` seams rather than mocking globals.

---

## Manual Web Validation

**Target origin:** `http://127.0.0.1:18080` (secure context; do not use
hostname HTTP origins for mic validation).

### Cloud agent Chrome session (2026-09-15)

Served via `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=18080`.

| Step | Result |
|------|--------|
| Home / Heroes / Tell Your Story | Loaded |
| Prepare | **"Microphone: Not requested"** + **Allow microphone** — old stub text **"Microphone is unavailable on this device."** did **not** appear |
| Allow microphone (Chrome initially Ask) | UI showed **Denied** after first click (no prompt / no device) |
| Site setting → Allow + reload | **"Microphone: Granted"** + **Continue to record** |
| Record UI | Ready / Start reached |
| Start | `startFailed` / `NotFoundError: Requested device not found` — expected: VM has **no physical microphone** |
| Pause / Resume / Stop / Review with audio | **Not completed** in-agent (hardware blocker) |

Conclusion: composition + permission path are fixed. Full capture still needs an
operator browser with a real mic (e.g. Windows Chrome at `127.0.0.1:18080`
over SSH tunnel). SSH does not forward the Mac microphone.

Checklist for operator follow-up:

1. Tell Your Story  
2. Prepare (must not hard-fail as “unavailable” from the stub)  
3. Allow microphone → browser prompt if needed  
4. Start → speak → Pause → Resume → Stop  
5. Review → Continue / accept through HS.9 flow  
6. Cancel mid-recording releases the mic / recorder

---

## Architectural Decisions

1. **Keep `DeviceRecordingPort`** — no UI/application getUserMedia.  
2. **Separate web adapter** — do not force native AAC + `permission_handler` +
   `dart:io` assumptions onto web.  
3. **Optional bytes on artifact** — smallest port extension that keeps
   domain/application free of browser types.  
4. **WAV on web** — simplest reliably supported `record_web` encoder.  
5. **Unavailable adapter retained** — unsupported environments / tests only.  
6. **Lazy `AudioRecorder`** — composition and VM tests construct the adapter
   without requiring plugin binding until a mic op runs.

---

## Remaining Limitations

- Cloud agent Chrome validated prepare/permission/record UI, but **cannot
  capture audio** without a physical mic (`NotFoundError` on Start). Operator
  should finish pause/resume/stop/review on a machine with a mic at
  `http://127.0.0.1:18080`.
- Video recording remains unsupported (MVP).
- Web persistence uses in-memory media storage; durable remote upload is
  out of HS.9 web scope.
- Pause/resume behavior depends on browser MediaRecorder support via
  `record_web`.
- Synthetic `memory://` paths must never be treated as `dart:io` files
  (session delete already guards this).

---

## Files Changed

- `lib/app/app_composition_root.dart`
- `lib/features/hero_story/application/recording/device_recording_port.dart`
- `lib/features/hero_story/application/recording/recording_session_service.dart`
- `lib/features/hero_story/application/providers/recording/recording_providers.dart`
- `lib/features/hero_story/presentation/providers/tell_your_story_controller.dart`
- `lib/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart` *(new)*
- `lib/features/hero_story/infrastructure/recording/web_object_url_io.dart` *(new)*
- `lib/features/hero_story/infrastructure/recording/web_object_url_io_stub.dart` *(new)*
- `lib/features/hero_story/infrastructure/recording/web_object_url_io_web.dart` *(new)*
- `test/bootstrap/app_composition_root_test.dart`
- `test/features/hero_story/application/recording/recording_session_web_bytes_artifact_test.dart` *(new)*
- `test/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter_test.dart` *(new)*
- `pubspec.yaml` (`web` direct dependency)
- `docs/investigations/HS9-web-recording-implementation.md` *(this file)*

---

## Verification Results

| Check | Result |
|-------|--------|
| Focused recording / composition tests | **24/24** pass |
| Full Flutter test suite | **777/777** pass |
| `flutter build web --release` | **Success** (build retains `memory://`, `audio/wav`, `hasPermission`) |
| `dart analyze` (touched areas) | No errors; `web` dep added to clear referenced-package info |
| Manual web (127.0.0.1:18080) | Prepare/permission/record UI OK; Start fails only for missing mic hardware |

---

## Why Unavailable Was Previously Selected

`AppCompositionRoot.initialize()` defaults web to
`_initializeInMemoryHeroStory()` (avoid path_provider / dart:io). That path
previously forced:

```text
useRealDeviceRecordingProvider = false
deviceRecordingPortProvider = UnavailableDeviceRecordingAdapter()
```

so the real `record` stack was never selected and was tree-shaken from web
builds.

## What Selects Web Now

Same in-memory composition path, but:

```text
useRealDeviceRecordingProvider = true
deviceRecordingPortProvider = RecordPackageWebDeviceRecordingAdapter()
```

Durable/native composition continues to use
`RecordPackageDeviceRecordingAdapter` with AAC-LC and filesystem temps.
