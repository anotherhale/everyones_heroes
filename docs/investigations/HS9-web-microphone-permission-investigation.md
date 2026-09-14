# HS.9 Web Microphone Permission Investigation

**Date:** 2026-09-14  
**Branch:** `cursor/hs9-web-mic-permission-investigation-21c6`  
**Status:** Diagnosis only — no implementation change  
**Context:** Flutter web on Windows Chrome via SSH tunnel `http://127.0.0.1:18080`; browser `getUserMedia({ audio: true })` succeeds; Tell Your Story shows mic unavailable / permission not granted

---

## Executive Summary

This is **not** a Chrome microphone permission failure and **not** a secure-context failure.

On Flutter web, `AppCompositionRoot` intentionally selects the in-memory composition path and wires **`UnavailableDeviceRecordingAdapter`**. That adapter **hardcodes** `DevicePermissionStatus.unavailable` for both check and request. It never calls:

- `permission_handler` / `Permission.microphone`
- `AudioRecorder.hasPermission()`
- `navigator.mediaDevices.getUserMedia()`

The UI strings **"Microphone: Unavailable"** and **"Microphone permission was not granted."** are produced by presentation + `RecordingSessionService` reacting to that stub. Browser packages (`record_web`, `permission_handler_html`) are present in the dependency tree but are **not on the runtime permission path** for Tell Your Story on web.

The browser-startup fix documented this as remaining work: web device recording was deferred so launch would not touch filesystem/mic APIs.

---

## Evidence

### User-visible strings (exact sources)

| String | Source |
|--------|--------|
| `Microphone permission was not granted.` | `RecordingSessionService.requestPermissions()` when status is `permanentlyDenied` **or** `unavailable` — `lib/features/hero_story/application/recording/recording_session_service.dart` |
| `Microphone: Unavailable` | `TellYourStoryScreen` `_PrepareStep` → `_permissionLabel(DevicePermissionStatus.unavailable)` — `lib/features/hero_story/presentation/screens/tell_your_story_screen.dart` |
| `Allow microphone` button | Same screen; `onPressed` → `TellYourStoryController.requestPermissions` |

Related (set on prepare, but not always shown in the error banner until request):

| String | Source |
|--------|--------|
| `Microphone is unavailable on this device.` | `RecordingSessionService.prepare()` when check returns `unavailable` |

### Stub that forces unavailable

```dart
// unavailable_device_recording_adapter.dart
Future<DevicePermissionStatus> checkMicrophonePermission() async {
  return DevicePermissionStatus.unavailable;
}

Future<DevicePermissionStatus> requestMicrophonePermission() async {
  return DevicePermissionStatus.unavailable;
}
```

No media APIs, no plugins, no user-gesture path to the browser.

### Web composition wiring

```dart
// app_composition_root.dart
final useDurable = enableDurableLocalPersistence ??
    (storageRoot != null || !kIsWeb);

if (!useDurable) {
  return _initializeInMemoryHeroStory(); // web default
}

// _initializeInMemoryHeroStory overrides:
useRealDeviceRecordingProvider.overrideWithValue(false),
deviceRecordingPortProvider.overrideWithValue(
  UnavailableDeviceRecordingAdapter(),
),
```

Confirmed by prior architecture note (`docs/architecture/Browser-Startup-Regression-Analysis.md`):

> Tell Your Story on web opens prepare UI with **Microphone: Unavailable** (no automatic permission prompt)  
> A full browser media-recorder adapter is **not** part of this fix (remaining work)

### What production native path would use (not web today)

`RecordPackageDeviceRecordingAdapter`:

- Check: `ph.Permission.microphone.status`
- Request: `ph.Permission.microphone.request()`
- Record: `AudioRecorder.start(...)` / pause / resume / stop
- Does **not** call `AudioRecorder.hasPermission()`

### Browser console DWDS WebSocket errors

`ws://127.0.0.1:18080/$dwdsSseHandler` failures are **out of scope** for this mic diagnosis. The app renders and the unavailable status is fully explained by composition + stub adapter without needing DWDS.

### Packages loaded vs packages used

| Package | In dependency tree | Used by web Tell Your Story permission flow today |
|---------|--------------------|-----------------------------------------------------|
| `record` / `record_web` | Yes | **No** |
| `permission_handler` / `permission_handler_html` | Yes | **No** |
| `UnavailableDeviceRecordingAdapter` | App code | **Yes** |

---

## Call Chain

```text
main()
  → AppCompositionRoot.initialize()
      [kIsWeb] → _initializeInMemoryHeroStory()
          overrides deviceRecordingPortProvider
            = UnavailableDeviceRecordingAdapter()
  → DemoRunner / EveryonesHeroesApp

TellYourStoryScreen.initState (post-frame)
  → TellYourStoryController.startFlow()
      → RecordingSessionService.beginSession(...)
      → RecordingSessionService.prepare()
          → DeviceRecordingPort.prepare()          // no-op on Unavailable*
          → DeviceRecordingPort.checkMicrophonePermission()
              → returns DevicePermissionStatus.unavailable  // HARDCODED
          → phase = failed
          → lastError = "Microphone is unavailable on this device."
      → UI: permissionStatus = unavailable
      → UI label: "Microphone: Unavailable"
      → "Allow microphone" button shown

User taps "Allow microphone"  (valid Flutter button → user gesture)
  → TellYourStoryController.requestPermissions()
      → RecordingSessionService.requestPermissions()
          → DeviceRecordingPort.requestMicrophonePermission()
              → returns DevicePermissionStatus.unavailable  // HARDCODED
          → phase = failed
          → lastError = "Microphone permission was not granted."
      → UI: errorMessage = lastError
      → UI still: "Microphone: Unavailable"
```

Layers:

| Layer | Component | Role in failure |
|-------|-----------|-----------------|
| Presentation | `TellYourStoryScreen` / `TellYourStoryController` | Displays status; correctly forwards request |
| Application | `RecordingSessionService` | Maps `unavailable` → failed + error strings |
| Application port | `DeviceRecordingPort` | Boundary preserved |
| Infrastructure (web) | `UnavailableDeviceRecordingAdapter` | **Root cause: always unavailable** |
| Infrastructure (native only) | `RecordPackageDeviceRecordingAdapter` | Not selected on web |

Domain aggregates (`Story`, `Hero`, consent, etc.) are **not** involved in the permission check.

---

## Root Cause

**Primary (definitive):** On Flutter web, Tell Your Story is bound to `UnavailableDeviceRecordingAdapter`, which always reports microphone unavailable and never requests browser microphone access. Chrome can grant `getUserMedia` successfully while the app still shows unavailable/denied because the app never asks the browser.

**Classification (AGENTS.md conflict protocol):**

- **Intentional implementation change** relative to “always use real recorder”: introduced by the browser-startup / path_provider isolation fix so web launch would not depend on durable filesystem or mic plugins.
- **Product gap / incomplete HS.9 web path:** startup safety was achieved by stubbing recording rather than providing a web-capable `DeviceRecordingPort`.

**Not the root cause:**

- Chrome site setting “Microphone: Allow”
- Insecure origin / non-localhost (user already proved `getUserMedia` works on this origin)
- DWDS WebSocket handler failures
- Missing `record_web` / `permission_handler_html` package registration in pubspec (they are transitive; they simply are unused on this path)

**Secondary / latent risks (would matter after removing the stub):**

1. **`RecordPackageDeviceRecordingAdapter` uses `permission_handler`, not `record.hasPermission()`.** On web, `permission_handler_html` check uses the Permissions API; request uses `getUserMedia` and stops tracks. `record_web.hasPermission()` also uses Permissions API + `getUserMedia` fallback. Prefer **one** source of truth aligned with the recorder that will actually start capture — the `record` package — to avoid dual permission stacks drifting.
2. **Native adapter assumes `dart:io` `Directory`/`File` paths.** `record_web` ignores the path argument and returns a **blob object URL** from `stop()`. `RecordingSessionService.accept()` currently does `File(artifact.localFilePath)` existence/length checks — that will break for blob URLs without a web-safe artifact / media-storage path.
3. **Composition couples two axes:** “no durable filesystem” and “no device recording.” Web can keep in-memory Hero/Story storage while still offering a real mic adapter.
4. **Error copy conflates unavailable with permission denied** (`requestPermissions` uses the same “was not granted” string for `unavailable`).

---

## Recommended Fix

Do **not** weaken security, add Chrome flags, or bypass secure-context rules.

Preserve `DeviceRecordingPort` / adapters / session orchestration.

### Recommended approach

1. **Keep** `UnavailableDeviceRecordingAdapter` for explicitly unsupported targets if needed, but **stop selecting it as the default web recording port** solely because durable FS is off.

2. **Add a web-capable infrastructure adapter** (either extend `RecordPackageDeviceRecordingAdapter` with platform-conditional permission + artifact handling, or add e.g. `RecordPackageWebDeviceRecordingAdapter`) that:
   - Uses **`AudioRecorder.hasPermission(request: false|true)` as the web source of truth** for mic check/request (backed by `record_web` → Permissions API / `getUserMedia`).
   - On native, may continue using `permission_handler` *or* unify on `hasPermission()` for both platforms — prefer unification if tests allow.
   - Starts/stops via `AudioRecorder` (web MediaRecorder path).
   - Produces a web-safe `LocalRecordingArtifact` (blob URL and/or bytes) that capture completion / `StoryMediaStoragePort` can persist without `dart:io` file assumptions.

3. **Wire web composition** in `AppCompositionRoot._initializeInMemoryHeroStory` (or a sibling web branch) to provide the real/web recording adapter + `RecordingSessionService`, while keeping in-memory Hero/Story/media providers.

4. **Keep “Allow microphone” on a user gesture** (already true via `FilledButton`). Ensure the adapter’s request path actually invokes `hasPermission(request: true)` / `getUserMedia` on that click — do not auto-prompt at cold start.

5. **Do not** make UI call `getUserMedia` directly; keep browser APIs behind the port/adapter.

6. **Clarify messaging:** distinguish true permission denial from platform-unavailable so web stubs (if retained anywhere) do not say “permission was not granted.”

### Explicit non-goals for the fix

- Chrome flags / insecure-origin workarounds
- Moving mic logic into domain
- Expanding Story aggregate for device APIs
- Removing native durable HS.9 path

---

## Tests Reviewed

Commands run (2026-09-14):

```bash
flutter test \
  test/bootstrap/app_composition_root_test.dart \
  test/features/hero_story/application/recording/recording_session_service_test.dart \
  test/features/hero_story/infrastructure/recording/fake_device_recording_adapter_test.dart \
  test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart

flutter test \
  test/features/hero_story/integration/hs9_recording_capture_integration_test.dart
```

Results:

| Suite | Result |
|-------|--------|
| Composition root + recording session + fake adapter + Tell Your Story UI | **All passed** (18 tests in combined run) |
| HS.9 durable capture integration | **1/1 passed** |

Coverage notes:

| Area | Coverage today | Gap |
|------|----------------|-----|
| In-memory composition binds `UnavailableDeviceRecordingAdapter` | Yes (`app_composition_root_test`) | Treats stub as desired; no assertion that web *should* eventually record |
| Session prepare/request with fake granted mic | Yes | No session tests for `unavailable` → exact error strings |
| UI permanentlyDenied guidance | Yes | No UI test for `unavailable` + Allow microphone → error banner text |
| `RecordPackageDeviceRecordingAdapter` permission mapping | **None** | No unit tests; no web fake of Permissions/`hasPermission` |
| Web blob-URL artifact → accept/media store | **None** | Critical for a real web fix |
| Browser `getUserMedia` success while app reports unavailable | **None** | Would have caught this composition bug/gap |

---

## Tests Recommended

Add before/with the implementation fix:

1. **`unavailable_device_recording_adapter_test.dart`**  
   - `check` / `request` return `unavailable`  
   - `start` throws `microphoneUnavailable`

2. **`recording_session_service` permission matrix**  
   - `prepare` + `unavailable` → phase `failed`, lastError contains unavailable wording  
   - `requestPermissions` + `unavailable` → lastError `"Microphone permission was not granted."` (or updated copy after fix)  
   - `requestPermissions` + `denied` vs `permanentlyDenied` distinctions

3. **Composition regression (web intent)**  
   - After fix: web/in-memory composition provides a **recording-capable** port (not `Unavailable*`), still without path_provider  
   - Keep a separate test that `Unavailable*` remains available if explicitly selected

4. **Adapter unit tests with injectable recorder/permission**  
   - Map `hasPermission(request: false)` true/false → `DevicePermissionStatus`  
   - `requestMicrophonePermission` calls `hasPermission(request: true)`  
   - Prefer **not** asserting `permission_handler` on the web adapter path

5. **Tell Your Story UI**  
   - With port returning `unavailable`, expect `mic-permission-status` = Unavailable and Allow button  
   - Tap Allow → expect error banner key `tell-your-story-error` with the session lastError  
   - After fix: granted → Continue to record

6. **Web artifact / media path (integration or adapter)**  
   - Simulate blob-URL/`bytes` artifact through `RecordingSessionService.accept` against in-memory `StoryMediaStoragePort` without `dart:io` file existence assumptions

7. **Manual Chrome checklist (post-fix)**  
   - Origin where raw `getUserMedia` works  
   - Prepare shows Not requested / Denied / Granted accurately  
   - Allow microphone triggers browser prompt only when needed and only on click  
   - Start → pause → resume → stop → review → accept works

---

## Files Examined

| File | Relevance |
|------|-----------|
| `lib/features/hero_story/presentation/screens/tell_your_story_screen.dart` | UI labels, Allow microphone button |
| `lib/features/hero_story/presentation/providers/tell_your_story_controller.dart` | `startFlow` / `requestPermissions` |
| `lib/features/hero_story/application/recording/recording_session_service.dart` | Error string production |
| `lib/features/hero_story/application/recording/device_recording_port.dart` | Port + `DevicePermissionStatus` |
| `lib/features/hero_story/application/providers/recording/recording_providers.dart` | Default fake / real override contract |
| `lib/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart` | Hardcoded unavailable |
| `lib/features/hero_story/infrastructure/recording/record_package_device_recording_adapter.dart` | Native permission_handler + record |
| `lib/features/hero_story/infrastructure/recording/fake_device_recording_adapter.dart` | Test double behavior |
| `lib/app/app_composition_root.dart` | `kIsWeb` → Unavailable adapter |
| `lib/main.dart` | Composition entry |
| `docs/architecture/Browser-Startup-Regression-Analysis.md` | Documents intentional web stub |
| `docs/architecture/architecture-decisions.md` (HS-ADR-061+) | Port boundary ADRs |
| `test/bootstrap/app_composition_root_test.dart` | Asserts Unavailable on in-memory |
| `test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart` | UI permission guidance |
| `test/features/hero_story/application/recording/recording_session_service_test.dart` | Happy-path session |
| `test/features/hero_story/infrastructure/recording/fake_device_recording_adapter_test.dart` | Fake permission denial |
| `test/features/hero_story/integration/hs9_recording_capture_integration_test.dart` | Durable native-style e2e with fake mic |
| `pubspec.yaml` / `pubspec.lock` | `record` 7.1.1, `record_web` 2.1.3, `permission_handler` 13.0.2, `permission_handler_html` 0.1.4+1 |
| Pub cache: `record` / `record_web` / `permission_handler_html` | Confirmed `hasPermission` → getUserMedia; web stop → blob URL |

---

## Architectural Concerns

1. **Port boundary is correct** (`DeviceRecordingPort` / HS-ADR-061). Fix belongs in infrastructure + composition, not UI/domain.

2. **Composition conflates persistence mode with recording capability.** Durable local FS (path_provider) and microphone access are independent. Web should be able to use in-memory Story/media **and** a real recorder.

3. **Permission source of truth on web should be the recorder stack (`record` / `record_web`),** not a parallel `permission_handler` check that can disagree or never run.

4. **`LocalRecordingArtifact.localFilePath` is filesystem-shaped.** Web MediaRecorder yields blob URLs; accept/media storage must become path-or-bytes aware without collapsing architecture ports.

5. **Do not delete the Unavailable adapter** if it remains useful as an explicit “recording unsupported” implementation — but it must not be the silent default for browsers that already support getUserMedia.

6. **Documentation drift:** Browser-startup analysis already states web mic is unavailable by design; HS.9 “production recording” docs describe native `record` + `permission_handler` without calling out the web stub. Update those docs when implementing the fix (in scope of the fix PR, not this investigation-only change beyond this report).

---

## Conclusion

| Item | Finding |
|------|---------|
| Root cause | Web composition binds `UnavailableDeviceRecordingAdapter`, which hardcodes mic unavailable and never calls browser media APIs |
| Why browser test succeeds | Direct `getUserMedia` works; the Flutter permission path never reaches it |
| Recommended fix | Web-capable `DeviceRecordingPort` adapter using `record`/`record_web` (`hasPermission` + MediaRecorder), wired from web composition; keep ports/adapters; handle blob/bytes artifacts; do not use Unavailable as the web default |
| Report path | `docs/investigations/HS9-web-microphone-permission-investigation.md` |
