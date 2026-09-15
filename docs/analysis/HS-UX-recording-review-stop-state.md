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

## Changes

| File | Change |
|------|--------|
| `lib/features/hero_story/infrastructure/recording/record_package_device_recording_adapter.dart` | Add `_expectingIntentionalStop`; set around intentional `stop()`/`cancel()`; suppress `interrupted` emission for expected stop-state events |
| `lib/features/hero_story/infrastructure/recording/record_package_web_device_recording_adapter.dart` | Same intentional-stop guard for the web adapter |
| `lib/features/hero_story/presentation/providers/tell_your_story_controller.dart` | Clear errors on successful Stop → Review; ignore late `interrupted` when already in a clean reviewing session |
| `test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart` | Focused tests for intentional Stop vs genuine interruption |
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
5. **non-interruption device failures remain visible on review** — ensures we do not blanket-hide all errors

Existing capture-through-consent orchestration test retained.

## Validation

Commands run in this environment (Flutter `3.48.0-0.5.pre` / Dart `3.13.0-97.0.dev`, matching `.metadata`):

### `dart analyze`

```text
$ dart analyze
Analyzing workspace...
16 issues found.
```

Exit code: **0**

All 16 findings are pre-existing `info`/`prefer_initializing_formals` lints in unrelated files (and one pre-existing info on the native recording adapter constructor). No new analyzer errors or warnings were introduced by this change.

### Focused Flutter tests

```text
$ flutter test \
  test/features/hero_story/presentation/hs9_tell_your_story_ui_test.dart \
  test/features/hero_story/application/recording/ \
  test/features/hero_story/infrastructure/recording/ \
  test/features/hero_story/integration/hs9_recording_capture_integration_test.dart
...
00:02 +31: All tests passed!
```

Exit code: **0** (31/31)

### Full Flutter test suite

```text
$ flutter test
...
00:35 +799: All tests passed!
```

Exit code: **0** (799/799)

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
