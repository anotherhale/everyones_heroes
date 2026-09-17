# Recording Review Stop-State UX Correction

## Problem

When a Hero intentionally taps **Stop** during Tell Your Story recording, the review screen showed a large red banner:

> Recording was interrupted. You can review what was saved or retake.

That message is wrong for the normal Stop → Review workflow. The user did not experience an error; they completed the capture step and are reviewing a successfully finalized recording. Presenting Stop as an interruption made a calm success path feel like a failure.

## Root Cause

Infrastructure adapters listen to the `record` package `onStateChanged` stream and treat `RecordState.stop` as an unexpected interruption while a temp recording is still tracked:

- Native: emit `DeviceRecordingFailureKind.interrupted` when `RecordState.stop && _tempPath != null`
- Web: emit `interrupted` when `RecordState.stop && _segmentStartedAt != null`

Intentional `stop()` / `cancel()` also produce `RecordState.stop` **before** those tracking fields are cleared. The failure stream therefore emitted `interrupted` for normal Stop.

`TellYourStoryController` subscribed to that stream and mapped `interrupted` to the red banner text. Successful `stopRecording()` then moved to Review **without clearing** `errorMessage`, so the banner remained on the review screen.

### Follow-up (2026-09-17): fix missing from `main` on device

PR #31 (`853f578`) merged the original correction, but a subsequent force-update of `main` dropped that commit. Device builds from current `main` therefore still showed the red banner after intentional Stop (confirmed on iPhone).

This follow-up restores the fix onto current `main` and hardens the iOS path:

1. Native adapter clears `_tempPath` **before** `recorder.stop()` so late platform-channel `RecordState.stop` events cannot match the interruption predicate.
2. Controller tracks `_intentionalStopInProgress` for the whole Stop call and ignores `interrupted` while that flag is set (covers events that arrive before the UI step flips to review).

## Changes

| File | Change |
|------|--------|
| `lib/features/hero_story/infrastructure/recording/record_package_device_recording_adapter.dart` | `_expectingIntentionalStop`; clear `_tempPath` before platform `stop()`/`cancel()`; suppress expected stop-state interruptions |
| `lib/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart` | Same intentional-stop guard for the web adapter |
| `lib/features/hero_story/presentation/providers/tell_your_story_controller.dart` | Clear errors on successful Stop → Review; ignore `interrupted` during intentional Stop and after clean review |
| `test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart` | Focused tests for intentional Stop vs genuine interruption, including in-flight Stop race |
| `docs/analysis/HS-UX-recording-review-stop-state.md` | This report |

No new success banner was added. Review itself communicates readiness.

## State Semantics

### A. Intentional user Stop

Recording → user taps Stop → adapter sets `_expectingIntentionalStop` → device stop → session phase `reviewing` → UI step `review` → **no** interruption banner.

### B. Genuine recording failure

Failures such as `startFailed`, `stopFailed`, `microphoneUnavailable`, `permissionDenied`, `unknown` still emit on the failure stream / throw `DeviceRecordingException` and surface via existing error messaging.

### C. Unexpected interruption with possible partial audio

Unexpected `RecordState.stop` while still tracking an in-progress recording (and **not** inside intentional stop/cancel) still emits `DeviceRecordingFailureKind.interrupted` and the existing message:

> Recording was interrupted. You can review what was saved or retake.

A late `interrupted` event after a **clean** intentional Stop (phase `reviewing`, `lastError == null`, UI already on review) is ignored so the success path is not re-labeled as an error. Other failure kinds remain visible even on review.

## Tests

Added/updated in `hs9_tell_your_story_ui_test.dart`:

1. **intentional Stop transitions to review without interruption banner** — controller state after Stop
2. **intentional Stop review screen has controls and no error banner** — widget assertions for review controls and absence of error banner / interruption text
3. **genuine interruption while recording still shows interruption message** — `emitFailure(interrupted)` during record still shows the message
4. **late interrupted signal after clean Stop does not reintroduce banner** — race/safety-net coverage
5. **interrupted during intentional Stop does not surface banner** — in-flight Stop + late interruption callback
6. **non-interruption device failures remain visible on review** — ensures we do not blanket-hide all errors

Existing capture-through-consent orchestration test retained.

## Validation

### Restore follow-up (this branch)

Commands run against current `main` + this restore/hardening:

### `dart analyze`

```text
$ dart analyze
Analyzing workspace...
17 issues found.
```

Exit code: **0** (pre-existing `info` lints only)

### Focused Flutter tests

```text
$ flutter test \
  test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart \
  test/features/hero_story/application/recording/ \
  test/features/hero_story/infrastructure/recording/ \
  test/features/hero_story/integration/hs9_recording_capture_integration_test.dart
...
00:02 +32: All tests passed!
```

Exit code: **0** (32/32)

### Full Flutter test suite

```text
$ flutter test
...
00:36 +819: All tests passed!
```

Exit code: **0** (819/819)

### Original PR #31 validation (for history)

At original merge time: analyze exit 0; focused 31/31; full 799/799. That merge was later dropped from `main` by a force-update.

## Architecture Review

- **Presentation / application / domain boundaries:** Fix is in infrastructure adapters (correct device semantics) and presentation coordinator (clear/ignore only when session already reflects clean review). Domain Story ownership and H.2 / UI.3 pipelines untouched.
- **No business logic moved into widgets:** Screen still renders `errorMessage` from controller state only.
- **No unrelated architecture:** No new aggregates, ports, or state machines.
- **Genuine error handling intact:** Non-stop interruptions and other failure kinds still surface.

## UX Result

Tell Your Story → Record → **Stop** → Review shows:

- Review heading / “Review your recording”
- Duration
- Optional title
- Play / Accept recording / Retake / Discard

No red “Recording was interrupted” banner on the intentional Stop path.
