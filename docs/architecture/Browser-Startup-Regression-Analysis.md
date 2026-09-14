# Browser Startup Regression Analysis

**Date:** 2026-09-14  
**Branch:** `cursor/fix-flutter-web-startup-ada8`  
**Status:** Fixed and validated in Chrome

---

## Executive Summary

Flutter Web failed before `runApp` because `AppCompositionRoot.initialize()` always called `path_provider` (`getApplicationDocumentsDirectory`) as part of HS.9 durable local capture composition. On Chrome that threw `MissingPluginException` — `path_provider` has no web implementation in the current dependency tree — so the real UI never mounted.

The fix branches composition: **native durable filesystem** vs **web/in-memory**. Browser startup now uses default in-memory Hero & Story providers, still runs event bootstrap + local Hero + `DemoRunner`, and keeps `RecordingSessionService` lazy. An `UnavailableDeviceRecordingAdapter` prevents microphone/filesystem access when Tell Your Story is opened on web. Native HS.9 durable recording remains intact.

---

## Root Cause

**Exact failure (reproduced with `flutter run -d chrome`):**

```text
DartError: MissingPluginException(
  No implementation found for method getApplicationDocumentsDirectory
  on channel plugins.flutter.io/path_provider
)
```

**Call site:** `AppCompositionRoot.initialize()` → `getApplicationDocumentsDirectory()` / `getTemporaryDirectory()` before `runApp`.

**Failure class:** **B** — process starts, then crashes during application initialization (before `EveryonesHeroesApp` builds).

**Contributing HS.9 behavior (not the exception itself, but incorrect for web launch):**

- Eager construction of file-backed Hero/Story/media adapters
- Eager warm of `recordingSessionServiceProvider` at composition time

`flutter build web` and the VM test suite could pass because they never executed the browser path_provider channel call the same way the Chrome runtime does.

---

## Startup Flow

### Final runtime flow

```text
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
AppCompositionRoot.initialize()
  ├─ [native] durable local Hero & Story + device recording overrides
  └─ [web / in-memory] default in-memory Hero & Story + UnavailableDeviceRecordingAdapter
  ↓
ApplicationBootstrap.initialize()
  ├─ EventStore / EventDispatcher / EventBus
  └─ ReactorRegistration
  ↓
ensureActiveLocalHeroProvider (local Hero bootstrap)
  ↓
DemoRunner.run()  (seed Journey if none)
  ↓
runApp(
  UncontrolledProviderScope(container)
    ↓
  EveryonesHeroesApp
    ↓
  AppShell (IndexedStack)
    ↓
  Home / Journey / Discover / Heroes / Reflect
)
```

### What is initialized when

| Phase | Objects |
|-------|---------|
| Before `runApp` | Single `ProviderContainer` from composition; event bus/store/dispatcher; reactors; active local Hero; DemoRunner journey seed |
| By `UncontrolledProviderScope` | Same container lifetime (no second competing container) |
| Lazily by Riverpod / screens | Today’s Experience, journey reads, Discover, Heroes catalog, Reflect |
| Only when entering Tell Your Story | `RecordingSessionService` (lazy); device recording port already bound but does not request mic until prepare/permission actions |
| Tests only | Temp `Directory` durable composition; fake recorder |

`main.dart` remains a thin entry point. The UI continues to render `EveryonesHeroesApp`, not `Placeholder`.

---

## Why It Worked / Failed

| Check | Result before fix | Why |
|-------|-------------------|-----|
| `dart analyze` | Pass | Static analysis does not invoke path_provider channels |
| `flutter test` | Pass | VM tests override composition with temp dirs / skip web path |
| `flutter build web` | Pass | Compile succeeds; `dart:io` is stubbed; failure is runtime plugin channel |
| `flutter run -d chrome` | **Fail** | Composition called path_provider → MissingPluginException → blank/no app |

---

## Changes Made

| File | Why |
|------|-----|
| `lib/app/app_composition_root.dart` | Branch durable vs in-memory/web; skip path_provider on web; stop eager recording-session warm |
| `lib/features/hero_story/infrastructure/recording/unavailable_device_recording_adapter.dart` | Web-safe recording port: reports mic unavailable, no FS, no permission request |
| `lib/features/hero_story/application/providers/recording/recording_providers.dart` | Document browser vs native recording composition |
| `test/bootstrap/app_composition_root_test.dart` | Regression: in-memory init, lazy session, app renders Home under composition + DemoRunner |
| `docs/architecture/Browser-Startup-Regression-Analysis.md` | This report |

`lib/main.dart` was **not** rewritten. HS.9 Tell Your Story / durable native path were **not** removed.

---

## HS.9 Impact

HS.9 **did** contribute: durable capture composition assumed local filesystem + path_provider at every launch.

**After fix:**

- App launch does **not** request browser microphone permission
- Heroes tab does **not** initialize recording session
- Tell Your Story on web opens prepare UI with **Microphone: Unavailable** (no automatic permission prompt)
- Native durable composition still wires file repos + real/fake device recording; session remains lazy until first recording-flow read

A full browser media-recorder adapter is **not** part of this fix (remaining work below).

---

## Web Compatibility

Native-only / filesystem-touching dependencies found on the old cold-start path:

| Dependency | Cold-start before | After |
|------------|-------------------|-------|
| `path_provider` | Always | Native durable only |
| `dart:io` `Directory` / `File` repos | Always via durable adapters | Native durable only |
| `RecordPackageDeviceRecordingAdapter` | Eager port + session warm | Native durable overrides; session lazy |
| Default in-memory Hero/Story providers | Overridden away | Used on web |

Life Journey repositories were already in-memory and were never the web failure.

---

## Proxy Decision

**No development proxy is required** for the current application to launch in Chrome.

Startup uses local composition + in-memory Life Journey repositories and (on web) in-memory Hero & Story providers. There is no HTTP backend dependency during cold start. A proxy would only be appropriate later for real `/api` backend traffic.

---

## Tests

### Commands and results

| Command | Result |
|---------|--------|
| `dart analyze` | Exit 0 — 17 pre-existing infos/warnings; no errors from this change |
| `flutter test` | **766/766 passed** |
| `flutter build web` | **✓ Built build/web** |
| `flutter run -d chrome` | Starts; `Starting application from main method…`; **no** `MissingPluginException` |

### Regression coverage

`test/bootstrap/app_composition_root_test.dart`:

1. Durable composition still initializes with temp dirs  
2. In-memory composition initializes without path_provider; recording session not warmed  
3. `EveryonesHeroesApp` + `DemoRunner` under `UncontrolledProviderScope` renders Home  

### Manual Chrome validation

Confirmed:

- Home renders (“Good morning.” / Today’s Experience)  
- Journey, Discover, Heroes, Reflect navigation  
- Tell Your Story opens; mic shown unavailable; no launch-time mic permission  

Artifacts: screenshots under `/opt/cursor/artifacts/chrome_*.webp` and  
`/opt/cursor/artifacts/chrome_web_startup_navigation_validation.mp4`.

Cosmetic note: Flutter logged missing Noto fonts for some characters; unrelated to startup crash.

---

## Architecture Validation

Dependency direction remains:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↑
Infrastructure
```

Confirmed:

- `main.dart` stays thin composition/entry  
- One `ProviderContainer` via `UncontrolledProviderScope` (no competing second app container)  
- Domain/application boundaries unchanged  
- UI.3 adaptive experience still behind application use cases (no Journey ID manufactured in widgets)  
- Hero & Story catalog vs Discovery vs Personalization not collapsed  
- HS.9 capture/recording ports remain infrastructure/application concerns  

---

## Remaining Issues

1. **Web device recording** — Tell Your Story reports microphone unavailable; no browser MediaRecorder adapter yet. Native HS.9 recording is unchanged.  
2. **Noto font warning** on web for some glyphs — cosmetic.  
3. **Known repo hygiene** (from AGENTS.md) — naming mismatches, stale maps, etc. — unrelated; deferred.  
4. **Linux desktop target** — not validated in this environment (toolchain incomplete); Chrome web was the acceptance target.

---

## Definition of Done Checklist

**Browser**

- [x] `flutter run -d chrome` starts successfully  
- [x] Real Everyone’s Heroes application displays  
- [x] No uncaught startup exception  
- [x] No permanent blank/loading screen  
- [x] Home renders; navigation works  

**Architecture / HS.9 / Web / Testing**

- [x] Thin `main.dart`; single Riverpod scope; boundaries intact  
- [x] HS.9 retained; recording not initialized at launch; no launch mic prompt  
- [x] Web build succeeds; no unnecessary proxy; no SW/cache workaround  
- [x] Analyze clean (exit 0); full suite pass; regression tests; Chrome manual validation  
