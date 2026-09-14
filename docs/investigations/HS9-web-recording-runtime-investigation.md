# HS.9 Web Recording Runtime Investigation

**Date:** 2026-09-14  
**Branch:** `cursor/hs9-web-recording-runtime-investigation-21c6`  
**Status:** Diagnosis only — no production recording fix  
**Context:** Flutter Web in Windows Chrome at `http://127.0.0.1:18080`; browser `getUserMedia({ audio: true })` succeeds; Tell Your Story still cannot record

---

## Executive Summary

**PR #24 did not implement a web recording fix.** It merged only the prior investigation document (`docs/investigations/HS9-web-microphone-permission-investigation.md`) and explicitly stated “No implementation fix.”

On `main` today, Flutter Web still starts through `AppCompositionRoot._initializeInMemoryHeroStory()`, which **overrides** `deviceRecordingPortProvider` with **`UnavailableDeviceRecordingAdapter`**.

That adapter:

- hardcodes `DevicePermissionStatus.unavailable` for check **and** request
- never constructs `AudioRecorder`
- never calls `record` / `record_web` / `getUserMedia` / `MediaRecorder`
- rejects `start` / `pause` / `resume` / `stop` with `microphoneUnavailable`

**First failing operation (runtime):**  
`UnavailableDeviceRecordingAdapter.checkMicrophonePermission()` during `RecordingSessionService.prepare()`, invoked from Tell Your Story `startFlow()` — returns `unavailable` **without any browser media call**.

Clicking **Allow microphone** fails next at:  
`UnavailableDeviceRecordingAdapter.requestMicrophonePermission()` — same hardcoded `unavailable`. Still no browser call.

**Start / Stop never execute** on the happy UI path because permission never becomes `granted`, so the Record step is unreachable.

Chrome Network evidence that `record` / `record_web` / `permission_handler_html` modules appear in the dependency graph is **not** evidence they are the live `DeviceRecordingPort`. A `flutter build web` of current `main` retains `UnavailableDeviceRecordingAdapter` in `main.dart.js` and **tree-shakes `RecordPackageDeviceRecordingAdapter` out entirely** (`RecordPackageDeviceRecordingAdapter` string count = 0).

---

## Verified Browser Evidence

| Check | Result |
|-------|--------|
| Origin | `http://127.0.0.1:18080` (localhost → secure context) |
| `window.isSecureContext` | `true` (user-verified) |
| `navigator.mediaDevices` | exists (user-verified) |
| Direct `getUserMedia({ audio: true })` | **succeeds** — `MICROPHONE WORKS` |
| Chrome site setting Microphone | Allow |
| App UI renders | Yes |

Conclusion: browser permission / secure-context / SSH tunnel are **eliminated** as the first failure.

---

## Actual Runtime Call Chain

### App startup (web)

```text
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → AppCompositionRoot.initialize()
       useDurable = enableDurableLocalPersistence ?? (storageRoot != null || !kIsWeb)
       on web default → useDurable == false
  → _initializeInMemoryHeroStory()
       overrides:
         useRealDeviceRecordingProvider = false
         deviceRecordingPortProvider = UnavailableDeviceRecordingAdapter()
  → DemoRunner / EveryonesHeroesApp
```

### Enter Tell Your Story → prepare

```text
TellYourStoryScreen.initState (post-frame)
  → TellYourStoryController.startFlow()
      → ensureActiveLocalHeroProvider
      → RecordingSessionService.beginSession(...)
      → RecordingSessionService.prepare()
          → DeviceRecordingPort.prepare()                 // Unavailable: no-op
          → DeviceRecordingPort.checkMicrophonePermission()
              → UnavailableDeviceRecordingAdapter
                  returns DevicePermissionStatus.unavailable   ★ FIRST FAILURE
          → phase = failed
          → lastError = "Microphone is unavailable on this device."
      → UI: permissionStatus = unavailable
      → UI label: "Microphone: Unavailable"
      → button: "Allow microphone"
```

### Allow microphone

```text
FilledButton("Allow microphone")   // real user gesture
  → TellYourStoryController.requestPermissions()
      → RecordingSessionService.requestPermissions()
          → DeviceRecordingPort.requestMicrophonePermission()
              → UnavailableDeviceRecordingAdapter
                  returns DevicePermissionStatus.unavailable   ★ STILL NO BROWSER CALL
          → phase = failed
          → lastError = "Microphone permission was not granted."
      → UI error banner shows that string
      → permission label remains Unavailable
```

### Start recording / Stop (not reached on web UI)

```text
continueToRecord() requires permissionStatus == granted
  → blocked

If start were forced despite phase:
  RecordingSessionService.startRecording()
    → guards: only ready/consenting → StateError while phase == failed
    → would never call AudioRecorder.start / MediaRecorder

Stop path similarly unreachable.
```

### Hypothetical chain if `RecordPackageDeviceRecordingAdapter` were selected (not current web)

```text
UI → Controller → RecordingSessionService
  → RecordPackageDeviceRecordingAdapter
      check/request via permission_handler (Permission.microphone)
        NOT AudioRecorder.hasPermission()
      start → AudioRecorder.start(RecordConfig(encoder: aacLc), path: dart:io temp path)
      stop  → AudioRecorder.stop() → on web: blob object URL (record_web)
           → File(blobUrl).exists()/length() via dart:io   ★ latent failure
  → LocalRecordingArtifact(localFilePath: ...)
  → accept → File(localFilePath) + StoryMediaStoragePort.storeFromFile
           → InMemoryStoryMediaStorageAdapter also uses dart:io File(path)
```

---

## Concrete Adapter Selected on Web

| Evidence | Finding |
|----------|---------|
| Source: `AppCompositionRoot._initializeInMemoryHeroStory` | Explicitly constructs `UnavailableDeviceRecordingAdapter()` |
| Provider default | `useRealDeviceRecordingProvider` defaults `false`; real port must be overridden |
| Unit test | `app_composition_root_test` asserts in-memory composition yields `UnavailableDeviceRecordingAdapter` |
| Web build (`flutter build web`) | `UnavailableDeviceRecordingAdapter` present in `build/web/main.dart.js` (6 refs) |
| Web build | `RecordPackageDeviceRecordingAdapter` **absent** (0 refs) — tree-shaken |
| Web build | Error strings `"Microphone is unavailable"` / `"Microphone permission was not granted"` present |
| PR #24 files | **Only** `docs/investigations/HS9-web-microphone-permission-investigation.md` |

**`RecordPackageDeviceRecordingAdapter` is not instantiated and not even retained in the web JS bundle.**

Why Network may still list `record` / `record_web` / `permission_handler_html`: source imports the record-package factory from providers / composition for the **native durable** path. DevTools/source maps can surface the package graph even when the concrete adapter class is tree-shaken from the executed web entry.

---

## Record Package Configuration

Pinned versions (`pubspec.lock`):

| Package | Version |
|---------|---------|
| `record` | **7.1.1** |
| `record_web` | **2.1.3** |
| `record_platform_interface` | **2.1.0** |
| `permission_handler` | **13.0.2** |
| `permission_handler_html` | **0.1.4+1** |

`record` 7.1.1 API (authoritative for this repo):

- Class: `AudioRecorder`
- `Future<bool> hasPermission({bool request = true})`
- `Future<void> start(RecordConfig config, {required String path})`
- `Future<String?> stop()`

`record_web` 2.1.3 behavior:

- `hasPermission(request: true)` → Permissions API query; if not granted, `getUserMedia({audio:true})`, then stops tracks
- `start` → `MediaRecorder` / mic delegate; path argument is not a real filesystem file on web
- `stop` → builds a `Blob`, returns `URL.createObjectURL(blob)` (blob URL string)

---

## Permission Request Path

### What “Allow microphone” actually does today

| Step | Behavior |
|------|----------|
| UI | `FilledButton` → `TellYourStoryController.requestPermissions` (user gesture ✓) |
| Session | `RecordingSessionService.requestPermissions` |
| Port | `requestMicrophonePermission()` |
| Adapter | **`UnavailableDeviceRecordingAdapter` → hardcoded `unavailable`** |
| `record.hasPermission(request: true)` | **Never called** |
| `permission_handler` request | **Never called** |
| Browser prompt / getUserMedia | **Never called** |

A permission **check** and a permission **request** are both stubbed identically. The button does **not** perform a real browser permission request.

### What `RecordPackageDeviceRecordingAdapter` would do (native / if wired)

```dart
checkMicrophonePermission  → Permission.microphone.status
requestMicrophonePermission → Permission.microphone.request()
```

It does **not** use `AudioRecorder.hasPermission()`. On web, `permission_handler_html` can call `getUserMedia` on request — but this adapter is not selected on web today.

---

## Recording Start Path

**Current web:** not reached (phase `failed`, UI stays on prepare).

**If forced / if RecordPackage were live:**

```dart
await _recorder.start(
  const RecordConfig(encoder: AudioEncoder.aacLc),
  path: <tempDirectory>/recording-<uuid>.m4a,
);
```

Latent web risks after wiring:

1. `dart:io` `Directory` temp path assumptions
2. Encoder `aacLc` depends on `MediaRecorder.isTypeSupported(...)` in the browser; Chrome often prefers `audio/webm;codecs=opus` — may throw “encoder not supported”
3. Same `AudioRecorder` instance is retained for the session (good) when constructed in the adapter field

---

## Recording Stop Path

**Current web:** not reached.

**RecordPackage `stop()` (source):**

1. `final path = await _recorder.stop();`
2. resolve `path ?? _tempPath`
3. `File(resolved).exists()` / `length()` via **`dart:io`**
4. Build `LocalRecordingArtifact(localFilePath: resolved, ...)`

On web, `stop()` from `record_web` returns a **blob URL**, not a filesystem path. `File(blobUrl)` does not yield usable bytes. This is a **secondary failure** that would surface only after the Unavailable stub is removed.

---

## Artifact Representation

| Layer | Representation |
|-------|----------------|
| Port contract | `LocalRecordingArtifact.localFilePath` (`String`) — filesystem-shaped |
| `record_web` stop | `blob:` object URL string |
| Session accept | `File(artifact.localFilePath).exists()` / `length()` |
| Web media store default | `InMemoryStoryMediaStorageAdapter.storeFromFile` → also `File(path).readAsBytes()` |
| Native durable store | `LocalFileStoryMediaStorageAdapter.storeFromFile` |

**Mismatch:** port + session + media adapters assume dart:io files. Web recorder returns blob URLs / bytes. PR #24 recommended “handle blob/bytes artifacts” but **did not implement that**.

---

## Persistence Path

On web composition, Hero/Story/media stay on **in-memory** providers (correct for startup). Accept still requires a readable file path today. Even with a working recorder, accept/persist would fail on blob URLs until artifact + `StoryMediaStoragePort` gain a bytes/blob path.

---

## First Failing Operation

**Operation:** `DeviceRecordingPort.checkMicrophonePermission()`  
**Concrete type:** `UnavailableDeviceRecordingAdapter`  
**Caller:** `RecordingSessionService.prepare()` ← `TellYourStoryController.startFlow()`  
**Result:** `DevicePermissionStatus.unavailable` (hardcoded)  
**Browser API invoked:** none  

**Next user-visible failure on Allow microphone:**  
`requestMicrophonePermission()` on the same adapter — again hardcoded `unavailable`, mapped by the session to `"Microphone permission was not granted."`

This is **not** a browser microphone failure.

---

## Root Cause

1. **Primary (proven):** Web composition still binds `UnavailableDeviceRecordingAdapter`. PR #24 did not change composition, adapters, or providers — only documentation. Runtime recording therefore never reaches `record` / `record_web`.

2. **Misconception to clear:** Observing `record_web` in Chrome’s Network/package list does not mean `RecordPackageDeviceRecordingAdapter` is the live port. The web JS bundle does not contain that class.

3. **Secondary (latent, after primary fix):** Naively wiring today’s `RecordPackageDeviceRecordingAdapter` on web would still be insufficient because it:
   - uses `permission_handler` instead of `AudioRecorder.hasPermission()` as recorder SoT
   - uses `dart:io` File/Directory paths
   - treats `stop()` result as a filesystem path (blob URL mismatch)
   - may start with `AudioEncoder.aacLc` unsupported in some browsers

---

## Recommended Fix

Do **not** weaken security or bypass `DeviceRecordingPort`.

1. **Composition:** On web/in-memory path, stop overriding with `UnavailableDeviceRecordingAdapter` as the default recording port. Keep Unavailable only for explicitly unsupported targets if needed.

2. **Adapter:** Provide a web-capable `DeviceRecordingPort` implementation that:
   - uses **`AudioRecorder.hasPermission(request: false|true)`** as the permission SoT on web (user-gesture request on Allow microphone)
   - uses `AudioRecorder.start/stop/pause/resume` via `record_web`
   - chooses a web-supported encoder (probe `isEncoderSupported`, prefer opus/webm or wav as appropriate)
   - returns artifacts as **bytes and/or blob URL + metadata**, not fake filesystem paths
   - retains one `AudioRecorder` instance for the session; dispose only when the port is disposed

3. **Session / media:** Extend accept/persist to consume bytes (or a web-safe URI) through `StoryMediaStoragePort` without requiring `dart:io` `File.exists()` for blob URLs. In-memory media adapter should accept bytes directly on web.

4. **UI:** Keep Allow microphone as the only automatic permission request trigger (already correct wiring; needs a real adapter behind it).

5. **Tests:** Unit-test web adapter permission/start/stop with fakes; composition test asserting web does **not** bind Unavailable; integration/manual Chrome checklist.

6. **Do not:** put `getUserMedia` in widgets; use Unavailable as web fallback; fake success; use Chrome flags.

---

## Tests Reviewed

| Area | Coverage | Gap |
|------|----------|-----|
| In-memory composition → Unavailable adapter | Yes | Treated stub as desired; no “web should record” assertion |
| Session happy path with Fake adapter | Yes | No unavailable→error-string tests (added in this investigation) |
| Unavailable adapter contract | **Added** | — |
| RecordPackage permission/recording | None | No unit tests |
| Blob/bytes artifact → accept | None | Critical for fix |
| Browser getUserMedia vs app port | None | Manual only |

---

## Tests Run

| Command | Result |
|---------|--------|
| Focused unavailable + composition + HS.9 recording/UI/integration | **24/24 passed** |
| `flutter test` (full suite) | **772/772 passed** |
| `flutter build web` | **Succeeded**; used for adapter-presence proof |

**Distinction:** Unit/widget test success proves the Unavailable stub and session mapping. It does **not** prove browser MediaRecorder success. Actual web runtime success requires a post-fix Chrome gesture test.

---

## Tests Recommended

1. Composition: web/in-memory binding must be recording-capable after fix (not Unavailable).
2. Web adapter: `hasPermission(request:false/true)` mapping; start/stop produce bytes/blob artifact.
3. Session: accept with bytes artifact against in-memory media store (no dart:io file).
4. UI: Allow microphone → granted → Continue to record when adapter grants.
5. Regression: Unavailable adapter retained only when explicitly selected.
6. Manual Chrome: permission prompt on click only; 3s record; stop; review; accept.

---

## Architectural Assessment

- **Port boundary is correct** (`DeviceRecordingPort`). Keep it.
- **Composition incorrectly couples** “no durable filesystem” with “no microphone.”
- **Artifact model is filesystem-centric**; web requires bytes/blob without collapsing architecture.
- Prefer **`record` as web permission SoT** over a parallel `permission_handler` stack.
- Loading `record_web` in the package graph ≠ using it at runtime.

---

## Files Examined

| File | Role |
|------|------|
| `lib/app/app_composition_root.dart` | Web → Unavailable override |
| `lib/main.dart` | Composition entry |
| `lib/features/hero_story/application/providers/recording/recording_providers.dart` | Provider defaults / RecordPackage factory |
| `lib/features/hero_story/application/recording/device_recording_port.dart` | Port + artifact shape |
| `lib/features/hero_story/application/recording/recording_session_service.dart` | prepare/request/start/stop/accept |
| `lib/features/hero_story/presentation/providers/tell_your_story_controller.dart` | UI orchestration |
| `lib/features/hero_story/presentation/screens/tell_your_story_screen.dart` | Allow microphone / labels |
| `lib/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart` | Hardcoded unavailable |
| `lib/features/hero_story/infrastructure/recording/record_package_device_recording_adapter.dart` | permission_handler + AudioRecorder + dart:io |
| `lib/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart` | storeFromFile via dart:io |
| `docs/investigations/HS9-web-microphone-permission-investigation.md` | Prior diagnosis (fix deferred) |
| `docs/architecture/Browser-Startup-Regression-Analysis.md` | Documents intentional web stub |
| `pubspec.lock` | Pinned record / permission_handler versions |
| Pub cache `record-7.1.1`, `record_web-2.1.3` | hasPermission / blob URL stop |
| `build/web/main.dart.js` | Runtime adapter presence proof |
| GitHub PR #24 metadata | Investigation-only merge |

---

## Conclusion Checklist

| # | Answer |
|---|--------|
| 1. FIRST FAILING OPERATION | `UnavailableDeviceRecordingAdapter.checkMicrophonePermission()` during prepare |
| 2. ACTUAL ROOT CAUSE | Web still uses Unavailable stub; PR #24 never wired RecordPackage on web |
| 3. EXACT FILE(S) | `lib/app/app_composition_root.dart`; `unavailable_device_recording_adapter.dart`; session/UI only surface the stub |
| 4. RECOMMENDED FIX | Wire web-capable record/`record_web` adapter + blob/bytes artifacts; keep ports; don’t use Unavailable as web default |
| 5. TESTS RUN | Focused 24/24 passed; full suite **772/772** passed; web build succeeded |
| 6. REPORT PATH | `docs/investigations/HS9-web-recording-runtime-investigation.md` |
