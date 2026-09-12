# HS.3 — Story Capture Foundation Implementation Report

## A. Executive Summary

HS.3 Story Capture Foundation is **complete and verified**.

Capture is an application workflow that stores opaque media bytes behind `StoryMediaStoragePort`, attaches an original audio `StoryRepresentation` (with provenance) to a draft `Story`, and enforces independent `StoryConsent` gates. No `StorySource`, no domain `CaptureSession` aggregate, no AI/transcription/translation, and no cloud provider SDKs were introduced.

ADRs **HS-ADR-017 … HS-ADR-021** are recorded in `docs/architecture/architecture-decisions.md`.

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test test/features/hero_story` | **58/58 passed** |
| `flutter test` | **580/580 passed** |

## B. Implementation Status

**COMPLETE** for authorized HS.3 scope.

| Capability | Status |
|---|---|
| StoryConsent | Done |
| Provisional capture narrative | Done |
| CaptureSession application-only | Done (`sessionId` + `CaptureCompletionStore`) |
| No StorySource | Confirmed absent |
| StoryMediaStoragePort + in-memory adapter | Done |
| Opaque MediaReference | Done |
| CompleteStoryCaptureUseCase | Done |
| Consent gates on submit/publish | Done |
| Lifecycle/visibility reuse | Done |
| StoryRepresentationAdded reuse | Done |
| Original language preservation | Done |
| Implementation report | Done |

## C. Source Documents Reviewed

1. `AGENTS.md`
2. `docs/architecture/HS.3-Story-Capture-Foundation-Plan.md`
3. `docs/architecture/architecture-decisions.md`
4. Existing HS.1 / HS.2 Hero & Story implementation and tests
5. `Story` aggregate, `StoryRepresentation`, `StoryRepresentationAdded`
6. Lifecycle / visibility models
7. Legacy `StoryCapturePort` stub
8. Repository interfaces and in-memory adapters
9. Testing conventions under `test/features/hero_story/`

## D. Architectural Decisions Applied

| Decision | ADR | Implementation |
|---|---|---|
| D-01 Provisional narrative | HS-ADR-017 | `StoryNarrative.provisional()`; `Story.createFromCapture`; approve/publish blocked while provisional |
| D-02 CaptureSession application-only | HS-ADR-018 | `sessionId` + `CaptureCompletionStore` (application layer only) |
| D-03 No StorySource | HS-ADR-019 | Original audio = `StoryRepresentation` + provenance |
| D-06 Media storage port | HS-ADR-020 | `StoryMediaStoragePort` + `InMemoryStoryMediaStorageAdapter` |
| D-08 StoryConsent | HS-ADR-021 | Independent recorded / processing / publication / AI timestamps |

## E. Implementation Summary

1. Domain: `StoryConsent`, provisional narrative, capture factory, consent/lifecycle gates.
2. Port: `StoryMediaStoragePort` (bytes never enter aggregate state).
3. Infrastructure: deterministic `InMemoryStoryMediaStorageAdapter`.
4. Application: `CompleteStoryCaptureUseCase`, `UpdateStoryConsentUseCase`, `CancelStoryCaptureUseCase`, DTOs, idempotent `CaptureCompletionStore`.
5. Events: reuse `StoryRepresentationAdded`.
6. Tests for consent, provisional narrative, media storage, capture use case; existing lifecycle tests updated for consent.

## F. Domain Model Changes

- Added `StoryConsent` value object; owned by `Story`.
- Added `StoryNarrative.provisional()` / provisional flag.
- Added `Story.createFromCapture(...)` (provisional narrative, private visibility, draft lifecycle).
- Added `Story.updateConsent`, `Story.markCaptureRecorded`.
- `submit` requires processing consent; `publish` requires publication consent; `approve`/`publish` reject provisional narrative.
- Captured audio attached via existing representation + recording provenance path.
- Legacy `StoryCapturePort` documentation narrowed (transcription remains HS.4).

## G. Application Layer Changes

- `CompleteStoryCaptureUseCase` — validate → store media → create/bind Story → attach original audio representation → mark recorded → persist → publish events → return DTO; session idempotency via `CaptureCompletionStore`.
- `UpdateStoryConsentUseCase` — grant/revoke independent consent stages.
- `CancelStoryCaptureUseCase` — clear session completion + optional media delete.
- Request/response DTOs under `application/dto/`.
- `CaptureCompletionStore` / `InMemoryCaptureCompletionStore`.

## H. Infrastructure Changes

- `InMemoryStoryMediaStorageAdapter` implementing `StoryMediaStoragePort`.
- Deterministic in-memory URI keys; store/exists/retrieve/delete.
- No cloud SDKs.

## I. StoryConsent

Independent timestamps: `recordedAt`, `processingApprovedAt`, `publicationApprovedAt`, `aiTransformationApprovedAt`.

Mutators: `markRecorded`, `grantProcessing`, `grantPublication`, `grantAiTransformation`, `revokeProcessing`, `revokePublication`, `revokeAiTransformation`.

Semantics: recorded ≠ processing ≠ publication ≠ AI.

## J. Provisional Narrative

- `StoryNarrative.provisional()` creates an explicit provisional placeholder.
- Capture drafts use provisional narrative until authoring (HS.5).
- Provisional content is not AI-authored and is not a substitute for the canonical Story narrative.
- Approve/publish require non-provisional narrative.

## K. StoryRepresentation Changes

No parallel capture representation type. HS.3 uses existing `StoryRepresentation` as original audio with opaque `MediaReference`, capture language, and `isAiGenerated: false`, attached with recording transformation provenance → `StoryRepresentationAdded`.

## L. MediaReference

Existing opaque URI value object retained. Domain stores references only; never bytes.

## M. StoryMediaStoragePort

```dart
abstract interface class StoryMediaStoragePort {
  Future<MediaReference> store(StoreStoryMediaRequest request);
  Future<bool> exists(MediaReference reference);
  Future<Uint8List?> retrieve(MediaReference reference);
  Future<void> delete(MediaReference reference);
}
```

Plus `StoreStoryMediaRequest` and `StoryMediaStorageException`.

## N. In-Memory Media Adapter

`InMemoryStoryMediaStorageAdapter`: deterministic store/retrieve/exists/delete; empty bytes fail; suitable for tests.

## O. CompleteStoryCaptureUseCase

Orchestrates capture completion without AI/classification/translation/discovery. Returns `CompleteStoryCaptureResponse` including story/representation/media identifiers and idempotent replay metadata.

## P. Consent Gates

| Action | Gate |
|---|---|
| Capture completion | `markCaptureRecorded` sets recorded consent |
| `submit` | requires `isProcessingApproved` |
| `publish` | requires `isPublicationApproved` |
| AI transformation | consent field present; AI pipeline deferred to HS.4 |

## Q. Lifecycle and Visibility

Reuses existing Story lifecycle and visibility. Capture defaults: draft + private. Capture does not imply public or published.

## R. Provenance

Recording transformation recorded through existing provenance append on representation add. Original source description preserved on capture-created stories. No `StorySource`.

## S. Multilingual Preservation

Original capture language stored as Story original language and representation language. Non-English capture covered by tests. Translation not implemented (HS.5).

## T. Events

Reused: `StoryRepresentationAdded` (and existing create/lifecycle events as applicable).

Not introduced: CaptureStarted, MediaUploaded, CaptureStored, CaptureCompleted.

## U. Repository Interaction

Persists through existing `StoryRepository` (+ hero lookup). No CaptureSession/Media/StorySource/Consent repositories.

## V. Failure and Recovery

Handled deterministically: empty media/sessionId, missing/inactive hero, media storage exception, story/hero mismatch, language mismatch, duplicate representation, idempotent session replay, best-effort media delete after partial failure. No distributed transactions.

## W. Tests Added/Updated

**Added**

- `story_consent_test.dart` (2)
- `story_narrative_provisional_test.dart` (2)
- `story_capture_test.dart` (4)
- `in_memory_story_media_storage_adapter_test.dart` (5)
- `complete_story_capture_use_case_test.dart` (5)

**Updated**

- `story_test.dart`, `hero_story_use_cases_test.dart`, `search_adapters_test.dart` for consent gates

## X. Test Results

| Command | Result |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test test/features/hero_story` | **58 passed** |
| `flutter test` | **580 passed** |

## Y. Architecture Verification

| Invariant | Result |
|---|---|
| DDD boundaries | PASS |
| Hexagonal architecture | PASS |
| Aggregate ownership (Story canonical) | PASS |
| Application/domain separation | PASS |
| Event semantics | PASS |
| Canonical Story vs representation | PASS |
| No StorySource | PASS |
| CaptureSession application-only | PASS |
| MediaReference opacity | PASS |
| Replaceable media storage | PASS |
| Consent independence | PASS |
| Lifecycle/visibility separation | PASS |
| Multilingual foundation | PASS |
| AI boundary | PASS |
| Discovery boundary | PASS |
| Personalization boundary | PASS |

Confirmed **not** introduced: AI behavior, personalization, recommendations, social feed, Discovery logic, behavioral evidence/patterns, semantic ranking, cloud-provider coupling, UI business rules.

## Z. Drift / Technical Debt

1. Architecture maps/glossary still under-document Hero & Story — deferred docs reconciliation.
2. Legacy `StoryCapturePort` stub retained; capture orchestration uses `StoryMediaStoragePort` + use case (HS-ADR-020).
3. `DateTime.now()` remains in Story/Hero and consent update fallback — known debt; clock port not introduced in HS.3.
4. Constructor style aligned to existing `this._field` pattern for analyze cleanliness.

## AA. Deferred Work

- **HS.4**: AI-assisted understanding / transcription / classification assistance.
- **HS.5**: Story authoring, script generation, translation.
- Production object-storage adapter for `StoryMediaStoragePort`.
- UI / composition wiring for capture flows.
- Broader architecture-map documentation updates.

## AB. Files Changed

```
docs/architecture/HS.3-Story-Capture-Foundation-Plan.md
docs/architecture/architecture-decisions.md
docs/architecture/HS.3-Story-Capture-Foundation-Implementation-Report.md
lib/features/hero_story/application/capture/capture_completion_store.dart
lib/features/hero_story/application/dto/requests/cancel_story_capture_request.dart
lib/features/hero_story/application/dto/requests/complete_story_capture_request.dart
lib/features/hero_story/application/dto/requests/update_story_consent_request.dart
lib/features/hero_story/application/dto/responses/complete_story_capture_response.dart
lib/features/hero_story/application/use_cases/cancel_story_capture_use_case.dart
lib/features/hero_story/application/use_cases/complete_story_capture_use_case.dart
lib/features/hero_story/application/use_cases/update_story_consent_use_case.dart
lib/features/hero_story/domain/aggregates/story.dart
lib/features/hero_story/domain/domain.dart
lib/features/hero_story/domain/services/story_capture_port.dart
lib/features/hero_story/domain/services/story_media_storage_port.dart
lib/features/hero_story/domain/value_objects/story_consent.dart
lib/features/hero_story/domain/value_objects/story_narrative.dart
lib/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter.dart
test/features/hero_story/application/use_cases/complete_story_capture_use_case_test.dart
test/features/hero_story/application/use_cases/hero_story_use_cases_test.dart
test/features/hero_story/domain/aggregates/story_capture_test.dart
test/features/hero_story/domain/aggregates/story_test.dart
test/features/hero_story/domain/value_objects/story_consent_test.dart
test/features/hero_story/domain/value_objects/story_narrative_provisional_test.dart
test/features/hero_story/infrastructure/media/in_memory_story_media_storage_adapter_test.dart
test/features/hero_story/infrastructure/search/search_adapters_test.dart
```

## AC. Definition of Done

- [x] Required HS.3 ADRs recorded (HS-ADR-017…021)
- [x] StoryConsent implemented
- [x] Provisional capture narrative implemented
- [x] CaptureSession remains application-only
- [x] StorySource does not exist
- [x] StoryMediaStoragePort replaceable
- [x] MediaReference opaque to domain
- [x] In-memory media adapter exists
- [x] CompleteStoryCaptureUseCase implemented
- [x] Consent gates enforced
- [x] Original language preserved
- [x] Provenance preserved
- [x] Existing lifecycle reused
- [x] Existing visibility reused
- [x] StoryRepresentationAdded reused
- [x] Story remains canonical
- [x] Captured audio remains original StoryRepresentation
- [x] No AI implementation
- [x] No translation implementation
- [x] No Discovery/personalization
- [x] No cloud provider dependency
- [x] Focused tests pass (58/58)
- [x] flutter analyze passes
- [x] Full flutter test passes (580/580)
- [x] Architecture boundaries reviewed
- [x] Drift/debt documented
- [x] HS.3 implementation report written

## AD. Final Recommendation

**Accept HS.3 as complete.** Proceed to HS.4 for AI-assisted understanding behind ports, without changing the capture foundation’s Story / Representation / Consent / MediaReference boundaries.
