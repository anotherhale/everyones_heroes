# HS.10 — Story Persistence & UI Planning Investigation

**Status:** INVESTIGATION COMPLETE — NO IMPLEMENTATION  
**Date:** 2026-09-15  
**Inspected branch:** `main` @ `4b0b45e` (`Implement HS.9 web recording runtime (DeviceRecordingPort) (#26)`)  
**Report branch:** `cursor/hs10-story-persistence-ui-plan-414b`  
**Phase authorization context:** HS.1…HS.9 foundations exist; HS.9 deferred “owner draft list UI”

Legend used throughout:

- **FACT** — observed in repository source / tests / ADRs
- **RECOMMENDATION** — architectural proposal for HS.10
- **FUTURE** — intentionally deferred beyond HS.10

---

## 1. Executive summary

**FACT:** HS.9 already persists accepted Hero Stories on native (non-web) builds. On Accept, the app copies the temporary recording into durable media storage, creates a private draft `Story` with an original audio `StoryRepresentation` + `MediaReference`, saves JSON via `FileStoryRepository`, and records idempotent completion via `FileCaptureCompletionStore`. Integration tests prove Story + media survive process reload.

**FACT:** The user-facing gap is not “recordings disappear from disk.” The gap is that after Accept → Consent → Completed → Done, the UI pops back to `HeroCatalogScreen` with **no My Stories surface**. Private drafts are intentionally excluded from Discover*/Browse Stories. `ListHeroOwnedStoriesUseCase` exists but has no presentation wiring. Owner playback cannot reuse `LoadStoryMediaUseCase` / `GetStoryExperienceUseCase` because those are discoverability-gated (HS.7 D4).

**RECOMMENDATION:** Treat HS.10 primarily as **owner Story visibility and management on top of existing local-first persistence**, not as a greenfield storage rewrite. Keep JSON-file Story metadata + `StoryMediaStoragePort` binary media. Add owner-scoped application queries, presentation models, My Stories UI, owner detail/playback, completion UX continuity, and archive-with-media-cleanup. Defer SQLite/Drift until query/sync complexity demands it. Defer cloud sync and production AI.

---

## 2. Repository state inspected

| Item | Value |
|------|--------|
| Working tree at inspection | clean on `main` |
| Commit | `4b0b45e` |
| Package | single Flutter app `everyonesheroes` (`pubspec.yaml`) |
| Feature module | `lib/features/hero_story/` (domain / application / infrastructure / presentation) |
| Docs | `docs/architecture/HS.9-*`, ADRs HS-ADR-060…066, HS.3–HS.8 reports |
| Persistence deps | `path_provider`, `path`, `crypto` — **no** Drift / sqflite / Hive / SharedPreferences |
| Recording deps | `record`, `permission_handler`, `just_audio`, `web` |

Package structure is feature-first under `lib/features/hero_story/`, not a separate HS.1 multi-package monorepo. Shared kernel / eventing live under `lib/core/`.

---

## 3. Current HS.9 implementation findings

### 3.1 End-to-end call graph (FACT)

```text
AppShell [Heroes tab]
  → HeroCatalogScreen
      → TellYourStoryScreen
          → TellYourStoryController (Riverpod Notifier)
              → ensureActiveLocalHeroProvider / ActiveLocalHeroStore
              → RecordingSessionService
                  → DeviceRecordingPort
                      ├ RecordPackageDeviceRecordingAdapter (native)
                      ├ RecordPackageWebDeviceRecordingAdapter (web)
                      └ FakeDeviceRecordingAdapter (tests)
                  → CompleteStoryCaptureUseCase (on Accept)
                      → StoryMediaStoragePort.storeFromFile | store
                      → StoryRepository.save
                      → CaptureCompletionStore.save
                      → EventBus.publish(StoryCreated, StoryRepresentationAdded)
              → UpdateStoryConsentUseCase (post-accept consent UI)
```

| Layer | Path |
|-------|------|
| Entry CTA | `lib/features/hero_story/presentation/screens/hero_catalog_screen.dart` |
| UI | `…/presentation/screens/tell_your_story_screen.dart` |
| Controller | `…/presentation/providers/tell_your_story_controller.dart` |
| Session | `…/application/recording/recording_session_service.dart` |
| Device port | `…/application/recording/device_recording_port.dart` |
| Complete capture | `…/application/use_cases/complete_story_capture_use_case.dart` |
| Consent | `…/application/use_cases/update_story_consent_use_case.dart` |
| Durable composition | `lib/app/app_composition_root.dart` |
| File story repo | `…/infrastructure/repositories/file_story_repository.dart` |
| Local media | `…/infrastructure/media/local_file_story_media_storage_adapter.dart` |

There is **no separate iOS-only adapter**. iOS/Android share `RecordPackageDeviceRecordingAdapter`.

### 3.2 UI step machine vs session phase (FACT)

**Presentation** (`TellYourStoryStep`):

```text
prepare → record → review → consent → completed → Done (Navigator.pop)
```

**Application** (`RecordingSessionPhase`):

```text
idle | preparing | ready | consenting | recording | paused |
reviewing | persisting | completed | failed | cancelled
```

These are **not** Story lifecycle. HS.9 correctly keeps recording UX state out of the domain aggregate.

Note: `RecordingSessionService.enterConsenting()` exists but the Tell Your Story UI never calls it. Post-accept consent is a presentation step after Story persistence.

### 3.3 Transition inventory (FACT)

| Transition | Widget/step | Provider/controller | Application | Domain | Infrastructure | Persistence |
|------------|-------------|---------------------|-------------|--------|----------------|-------------|
| Open Tell Your Story | `HeroCatalogScreen` → push | — | — | — | — | — |
| Prepare | `_PrepareStep` | `TellYourStoryController.startFlow` | `beginSession`, `prepare` | IDs minted only | mic permission | session manifest write |
| Start/Pause/Resume | `_RecordStep` | controller | session start/pause/resume | none | `record` package | temp audio + manifest |
| Stop → Review | `_ReviewStep` | `stopRecording` | `stop` → artifact | none | returns path/bytes | temp file remains |
| Play review | review controls | `playReview` / `just_audio` | uses artifact path/bytes | none | filesystem / memory | none |
| Retake | review | `retake` | new sessionId + representationId | none | delete temp | no Story |
| Discard | review | `discard` | cancel temp | none | delete temp | no Story |
| Accept | review → consent | `acceptRecording` | `CompleteStoryCaptureUseCase` | `Story.createFromCapture`, representation, `markCaptureRecorded` | copy media + JSON save | durable Story + media |
| Consent save | `_ConsentStep` | `submitConsent` | `UpdateStoryConsentUseCase` | consent VO update | story JSON rewrite | durable |
| Consent skip | consent → completed | `skipConsentForNow` | none | recorded consent only | none | draft remains |
| Done | `_CompletedStep` | pop | none | none | none | Story remains on disk |

### 3.4 Domain events on capture path (FACT)

| When | Event |
|------|--------|
| Accept creates Story | `StoryCreated` |
| Accept adds original audio representation | `StoryRepresentationAdded` |
| Consent update | **no domain event** (`updateConsent` does not `raise`) |
| `markCaptureRecorded` | **no domain event** |

---

## 4. Actual recording storage behavior

### 4.1 What API returns the recording? (FACT)

`DeviceRecordingPort.stop()` → `LocalRecordingArtifact`:

- `localFilePath` (String)
- `duration`, `contentType`, `mode`
- optional `bytes`, `byteLength`, `checksum`

Native adapter writes:

```text
{getTemporaryDirectory()}/hero_story_recording/recording-{uuid}.m4a
```

and returns that filesystem path (`audio/mp4`, no bytes).

Web adapter returns:

```text
localFilePath = memory://recording-{uuid}.wav
bytes = Uint8List (authoritative)
```

### 4.2 Temporary vs durable (FACT)

| Location | API | Survives restart? | Role |
|----------|-----|-------------------|------|
| `{temp}/hero_story_recording/` | `getTemporaryDirectory()` | **No guarantee** (OS cache/temp) | In-progress recording |
| `{docs}/hero_story/media/…` | `getApplicationDocumentsDirectory()` | **Yes** (app-private documents) | Accepted original media |
| `{docs}/hero_story/stories/{id}.json` | documents | **Yes** | Story metadata |
| `{docs}/hero_story/recording_sessions/{sessionId}.json` | documents | File may survive; **session not restored** | Write-only manifest |
| `{docs}/hero_story/capture_completions.json` | documents | **Yes** | Idempotent accept replay |
| `{docs}/hero_story/heroes/…`, `active_hero_id.txt` | documents | **Yes** | Local Hero bootstrap |

Accept path (native): `storeFromFile` **copies** temp → durable media, then session **deletes** temp only after successful capture.

### 4.3 Lifecycle existence matrix (FACT)

| State | Temp recording | Durable media | Story aggregate |
|-------|----------------|---------------|-----------------|
| Recording started | yes (native) | no | no (StoryId only in session) |
| Recording stopped / review shown | yes | no | no |
| Accept succeeded | deleted | **yes** | **yes** (private draft) |
| Processing/AI consent accepted or skipped | n/a | yes | yes (consent may update) |
| Flow completed / Done | n/a | yes | yes |
| App backgrounded mid-review | temp may remain | no Story yet | no |
| App terminated mid-review | temp **may be cleared by OS** | no | no |
| App restarted after Accept | n/a | **yes** (native durable) | **yes** |
| Web Accept + restart | n/a | **no** (in-memory composition) | **no** |

### 4.4 Is a Story created during recording? (FACT)

**No.** `beginSession` generates `StoryId` / `StoryRepresentationId` in application memory only. Aggregate creation occurs **only** inside `CompleteStoryCaptureUseCase` on Accept via `Story.createFromCapture` + `addRepresentation` + `markCaptureRecorded`.

Created on Accept:

- `Story` (lifecycle `draft`, visibility `private`)
- `StoryId`
- `StoryRepresentation` (audio, `RepresentationOrigin.original`)
- `MediaReference` (`file://…` or `memory://…`)
- Provenance step with `StoryTransformationType.recording`
- Consent `recordedAt`

Hero is bootstrapped earlier (`ensureActiveLocalHeroProvider`), not created per recording.

---

## 5. Actual persistence behavior

### 5.1 StoryRepository (FACT)

**Exists.** Interface: `lib/features/hero_story/domain/repositories/story_repository.dart`

Methods: `save`, `findById`, `exists`, `delete`, `findByHeroId`, `findAll`, `findPublished`.

| Implementation | Persistence | Wired when |
|----------------|-------------|------------|
| `InMemoryStoryRepository` | process memory only | default Riverpod provider; web composition |
| `FileStoryRepository` | one JSON file per Story under `{root}/stories/` | native durable `AppCompositionRoot` |

Persists structured Story snapshot (lifecycle, visibility, consent, provenance, representations including `MediaReference` URIs). **Does not** embed audio bytes.

### 5.2 Media persistence (FACT)

**Exists.** Port: `StoryMediaStoragePort` (`store`, `storeFromFile`, `exists`, `retrieve`, `delete`).

| Adapter | URI scheme |
|---------|------------|
| `InMemoryStoryMediaStorageAdapter` | `memory://` |
| `LocalFileStoryMediaStorageAdapter` | `file://` under `{root}/media` |

Domain holds only `MediaReference` (opaque URI string). Matches HS-ADR-020 / HS-ADR-062.

### 5.3 What HS.9 actually persists after Accept (native) (FACT)

1. Durable original audio file  
2. Story JSON (private draft + original representation + recorded consent)  
3. Capture completion index entry (idempotent by `sessionId`)  
4. Local Hero JSON + active hero id (bootstrap)

Does **not** persist as a resumable UX session: unfinished recordings, review UI state, or Riverpod controller state.

### 5.4 Preferred persistence convention already in project (FACT)

Hero & Story durable local MVP:

1. Domain ports  
2. Snapshot mappers → JSON  
3. One JSON file per aggregate id  
4. Separate media object store behind port  
5. Composition root overrides for native durable mode  
6. In-memory defaults for tests / web  

Life Journey / Discovery remain in-memory-only. **No SQL stack exists.** Introducing Drift/SQLite would be a new technology choice, not an extension of an existing convention.

---

## 6. Architecture gaps

| Gap | Classification | Notes |
|-----|----------------|-------|
| No My Stories / owner list UI | **FACT** | HS.9 deferred Slice C |
| Completed UX only pops | **FACT** | `_CompletedStep` → `maybePop()` |
| Discover* excludes private drafts | **FACT** / intentional (HS-ADR-043) | Correct for catalog; wrong surface for owner |
| `ListHeroOwnedStoriesUseCase` returns raw `List<Story>` | **FACT** | No presentation model; unused by UI |
| Owner cannot load media via `LoadStoryMediaUseCase` | **FACT** | Discoverability-gated |
| Owner cannot open detail via `GetStoryExperienceUseCase` | **FACT** | Discoverability-gated |
| Session manifests write-only | **FACT** | No restore path |
| Web not durable | **FACT** | In-memory composition |
| No hard-delete use case that removes Story + all media | **FACT** | `ArchiveStoryUseCase` exists; `StoryRepository.delete` exists but no orchestrated owner delete |
| No separate AI processing job status | **FACT** | Lifecycle has `processing`; no Queued/Failed job model |
| `repository-map.md` omits Hero/Story file repos | Documentation drift | Report only; do not rewrite here |

---

## 7. Recommended persistence architecture

### RECOMMENDED ARCHITECTURE (summary)

**Story persistence:** Continue local-first `StoryRepository` with native `FileStoryRepository` (JSON per Story). Do not put audio blobs in Story JSON. Do not rewrite storage for HS.10 UI work.

**Media persistence:** Continue `StoryMediaStoragePort` + `LocalFileStoryMediaStorageAdapter` under application documents. Keep original recording immutable once stored.

**Story creation point:** Keep **Option B — create Story when recording is accepted** (already implemented). Do not create domain Story on mic start.

**Lifecycle:** Keep existing `StoryLifecycleStatus`. Accept → `draft` + private visibility + `recorded` consent. Accept ≠ publish.

**Repository:** Reuse `StoryRepository` / `HeroRepository`. Add owner-scoped **application** queries/DTOs; do not add a new repository merely for listing.

**Media storage port:** Reuse `StoryMediaStoragePort`. Add owner-scoped load use case; do not bypass port with raw paths in UI.

**Database/storage technology:** **Stay on JSON files + path_provider for HS.10.** Evaluate Drift/SQLite later when multi-dimensional catalog queries, sync queues, or large-scale indexing dominate. Do not introduce SQL “because Flutter docs mention it” while the project already has a working durable convention.

**UI:** Heroes → Tell Your Story + **My Stories** (owner). Browse Stories remains discoverable catalog only.

**AI readiness:** Preserve original representation; add future transcript/understanding as additional representations / understanding aggregates with provenance; introduce explicit processing **job** status when AI is wired — do not overload Accept or conflate with publication.

### 7.1 Structured data vs binary media (RECOMMENDATION)

```text
Application use cases
        │
        ├── StoryRepository  → structured Story metadata (JSON files today)
        │
        └── StoryMediaStoragePort → original/derivative media bytes
```

Story contains `MediaReference`, duration, provenance, consent — never bytes.

### 7.2 Local-first (RECOMMENDATION)

Keep:

```text
Flutter App
 ├── StoryRepository → local JSON
 └── StoryMediaStoragePort → app-private documents files
```

Accepted Stories must survive navigation, tab changes, backgrounding, and restart (already true on native durable mode). Temporary artifacts must remain distinct from accepted media (already true).

### 7.3 Cloud sync boundary (FUTURE, design now)

```text
Story application ──┬── Local StoryRepository (current)
                    └── Future RemoteStoryRepository / sync adapter

StoryMediaStoragePort ──┬── LocalFileStoryMediaStorageAdapter (current)
                        └── Future RemoteMediaStorage
```

Identifiers already suitable for later sync: stable `StoryId`, `HeroId`, `StoryRepresentationId`, `sessionId` (idempotency), `MediaReference` URI abstraction, provenance steps, consent timestamps, `createdAt` / `updatedAt`.

Do **not** implement remote storage in HS.10.

### 7.4 Persistence technology comparison (evaluation)

| Option | Fit for HS.10 | Pros | Cons |
|--------|---------------|------|------|
| **A. JSON/file (existing)** | **Recommended now** | Already implemented; tested; matches ports; simple migrations by mapper versioning | Weak for complex queries at scale |
| B. SQLite | Deferred | Strong querying | New stack; migration work; no existing usage |
| C. Drift | Deferred | Typed SQL over SQLite | Same as B + codegen |
| D. SharedPreferences | Reject | Fine for tiny prefs | Wrong for Stories/media |
| E. Hive | Reject | KV convenience | No project convention; blobs temptation |

**RECOMMENDATION:** A for HS.10. Revisit B/C when owner/library filters + sync outgrow file scanning (`findByHeroId` already sufficient for My Stories).

---

## 8. Recommended media architecture

### 8.1 Original recording representation (RECOMMENDATION)

Keep current shape:

```text
Story
 └── StoryRepresentation (origin=original, format=audio)
      ├── MediaReference (opaque)
      ├── duration
      ├── language
      ├── isAiGenerated=false
      └── Provenance step: recording
```

Do not put raw filesystem paths into domain entities. Infrastructure resolves `file://` / future remote URIs.

### 8.2 Immutability rule (RECOMMENDATION)

Never overwrite the original media object with transcript audio, narrated TTS, or edited derivatives. Always add new representations (or understanding records) with provenance linking back to the original.

### 8.3 Playback (RECOMMENDATION)

- Package `just_audio` already present — reuse.  
- Review playback may continue using session artifact.  
- Persisted playback must go: UI → owner load use case → `StoryMediaStoragePort.retrieve` / resolved reference → player.  
- Do not hardcode documents paths in widgets.

---

## 9. Recommended Story lifecycle

### 9.1 Existing domain lifecycle (FACT)

```text
draft → processing → review → approved → published
(+ archived | rejected | suspended | removed)
```

Visibility is separate: `private | draft | unlisted | community | public`.

### 9.2 Mapping HS.9 Accept (FACT + RECOMMENDATION)

| User action | Domain meaning |
|-------------|----------------|
| Accept recording | Persist private **draft** Story + original recording; set `consent.recordedAt` |
| Grant processing | `consent.processingApprovedAt` — **not** publish |
| Grant AI | `consent.aiTransformationApprovedAt` — **not** publish |
| Skip consent | Leave recorded-only consent; Story remains private draft |
| Publish | Separate future flow requiring publication consent + lifecycle rules |

**Accept must not mean Published.** Current code already enforces this. HS.10 UI must continue to communicate “private draft / saved,” not “published.”

### 9.3 User-facing status labels (RECOMMENDATION)

Map domain → human copy without leaking internals:

| Domain facts | Suggested UI label |
|--------------|--------------------|
| lifecycle=draft, recorded, no processing consent | Saved · Private |
| processing consent granted, not yet submitted | Ready to prepare |
| lifecycle=processing | Preparing |
| lifecycle=review | Ready for review |
| lifecycle=approved | Approved |
| lifecycle=published + eligible visibility | Published |
| lifecycle=archived | Archived |

Exact copy can be refined in UI slices; keep mapping centralized in a presentation mapper.

---

## 10. Recommended consent / privacy model

### 10.1 Existing model (FACT)

`StoryConsent` independent gates:

- recorded  
- processing approved  
- publication approved  
- AI transformation approved  

HS.9 UI only exposes processing + AI after Accept. Publication deferred.

### 10.2 HS.10 UI requirements (RECOMMENDATION)

On My Stories / Story detail, surface at minimum:

- “This recording is private.” (visibility=private)  
- Processing / AI consent state derived from `StoryConsent`  
- HS.9 consent flow remains the authoritative grant path; detail screen may deep-link later to update consent via existing `UpdateStoryConsentUseCase`

Do not collapse gates into a single `isApproved` boolean.

Visibility must remain independent of lifecycle and of AI artifacts (AGENTS.md §22).

---

## 11. Story creation timing analysis

| Option | Description | Crash recovery | Abandoned recordings | Domain purity |
|--------|-------------|----------------|----------------------|---------------|
| A | Create Story when recording begins | Better orphan Story cleanup needed | Many empty drafts | Couples mic UX to aggregate |
| **B (current)** | Create Story on Accept | Incomplete recordings not Stories | Temps discarded | Clean |
| C | Draft Story at Tell Your Story open | Similar to A | Draft spam | Premature aggregate |

**RECOMMENDATION: Keep Option B.**

Rationale:

- Matches implemented HS.9 / HS-ADR-060 (no CaptureSession aggregate).  
- Avoids private draft pollution from abandoned sessions.  
- Provenance starts at meaningful capture completion.  
- Crash mid-record does not leave half-Stories.  
- Future transcription attaches to an already-accepted original representation.

Optional FUTURE: restore review from durable manifest + surviving temp file — still without creating Story until Accept.

---

## 12. Recommended application boundaries

### 12.1 Ports (reuse)

- `StoryRepository`  
- `HeroRepository`  
- `StoryMediaStoragePort`  
- `DeviceRecordingPort` (unchanged)  
- `CaptureCompletionStore` (unchanged)

### 12.2 Use cases justified for HS.10

| Use case | Status | Purpose |
|----------|--------|---------|
| `ListHeroOwnedStoriesUseCase` | **exists** | Owner list; refine to DTO/summary |
| `GetOwnedStoryDetailUseCase` (name TBD) | **new** | Owner detail without discoverability gate |
| `LoadOwnedStoryMediaUseCase` (name TBD) | **new** | Owner playback media load |
| `ArchiveStoryUseCase` | **exists** | Soft remove from My Stories |
| `DeleteOwnedStoryUseCase` (optional later) | **new if needed** | Hard delete metadata + all media refs |
| `CompleteStoryCaptureUseCase` | exists | Unchanged |
| `UpdateStoryConsentUseCase` | exists | Unchanged |

Do **not** invent Create/Save/Submit variants that duplicate HS.3/HS.9.

### 12.3 Presentation boundary (RECOMMENDATION)

```text
Riverpod presentation provider
  → Application query / use case
  → StoryRepository / Media port
  → Presentation model (not raw Story aggregate in widgets)
```

Suggested models:

- `OwnedStoryListItemModel` — id, title, createdAt, duration, lifecycleLabel, privacyLabel, processingConsentLabel  
- `OwnedStoryDetailModel` — richer detail + representation summaries + consent flags  

Follow existing conventions (`StoryExperienceViewModel`, `FutureProvider.autoDispose`, application `Provider` for use cases).

---

## 13. Recommended UI information architecture

### 13.1 Heroes tab (RECOMMENDATION)

```text
Heroes
 ├── Tell Your Story          (existing)
 ├── My Stories                (NEW — owner library)
 ├── Browse stories            (existing discoverable catalog)
 └── Discoverable heroes list (existing)
```

Do not merge private drafts into Browse Stories.

### 13.2 My Stories (RECOMMENDATION)

List of owner Stories (including private drafts), newest first (already sorted by `updatedAt` in `ListHeroOwnedStoriesUseCase`).

Card fields:

- Title (or “Untitled Story”)  
- Recording date  
- Duration (from original audio representation)  
- Lifecycle / preparation label  
- Privacy label (“Private”)

### 13.3 Empty state (RECOMMENDATION)

```text
Your Stories
Your experiences can inspire someone else.
You haven't recorded a story yet.
[ Tell Your Story ]
```

### 13.4 Recording completion UX (RECOMMENDATION)

Replace dead-end Completed + Done-only with continuity:

```text
Recording saved
Your story is safely saved and private.
[ Listen to story ]  → owner detail
[ View My Stories ]  → owner list
[ Done ]             → Heroes
```

If processing consent granted (still no AI pipeline in HS.10):

```text
Your recording is saved.
We'll prepare your story for review when processing is available.
```

### 13.5 Story detail — implement now vs future

**Implement now (HS.10):**

- Title, recorded date, duration  
- Status + privacy  
- Play original recording  
- Consent summary (recorded / processing / AI)  
- Archive action  

**Future AI / later HS phases:**

- Transcript section  
- Understanding / classification  
- Additional representations  
- Edit narrative  
- Submit for processing UX  
- Publication controls  

Conceptual layout:

```text
Story Detail
[Title]
[Play Recording]
Recorded · date · duration · status · Private
--------------------------------
Original Recording [Play]
--------------------------------
Privacy & Consent (summary)
[Archive]
--------------------------------
Transcript / Understanding / Representations  (FUTURE placeholders OK)
```

### 13.6 Delete vs Archive (RECOMMENDATION)

**HS.10.1 preference: Archive** via existing `ArchiveStoryUseCase`.

Why:

- Stories may be deeply personal; accidental hard delete is high cost.  
- Archive is already a first-class lifecycle transition with events.  
- Media cleanup policy can still run for archived Stories later, or on explicit “Delete permanently.”

If a hard delete is required in a later slice: orchestrate `StoryRepository.delete` **and** delete every `MediaReference` on representations (and future AI artifacts). Never delete metadata alone.

---

## 14. Detailed UI implementation plan

| Slice focus | Screens / providers | Data |
|-------------|---------------------|------|
| My Stories list | `MyStoriesScreen`, `ownedStoriesProvider` | `ListHeroOwnedStories` → list models |
| Empty state | same | empty list |
| Owner detail | `OwnedStoryDetailScreen`, `ownedStoryDetailProvider` | new owner get use case |
| Playback | detail + `AudioPlayer` / small playback notifier | owner media load |
| Completion UX | update `_CompletedStep` | `capturedStoryId` navigation |
| Heroes IA | update `HeroCatalogScreen` | entry buttons |
| Archive | detail overflow / button | `ArchiveStoryUseCase` + invalidate providers |

Riverpod conventions to follow:

- Application: `Provider<UseCase>`  
- Presentation lists/details: `FutureProvider.autoDispose` / `.family`  
- Avoid duplicating capture session state into a second global store  

---

## 15. AI integration readiness

### 15.1 Required pipeline support (RECOMMENDATION / FUTURE)

```text
Original Recording (immutable)
  → Transcript representation (new)
  → Story Understanding (existing HS.4 types; in-memory repo today)
  → Classification updates
  → Story draft narrative edits
  → Hero review / approve representation
  → Approved Story
```

HS.4 understanding repository is still in-memory-only (**FACT**) — durable understanding persistence is FUTURE and out of core HS.10 UI scope, but owner Story persistence must not block it.

### 15.2 Processing state vs lifecycle (RECOMMENDATION)

Keep separate:

| Concern | Model |
|---------|-------|
| Story lifecycle | `StoryLifecycleStatus` |
| Consent | `StoryConsent` |
| AI/job processing | **Future** explicit status (`notStarted` / `queued` / `processing` / `complete` / `failed`) when async AI is introduced |

Do not treat Accept as processing start. HS-ADR-064: transcription/AI remain post-capture and non-blocking.

### 15.3 Human approval remains authoritative (RECOMMENDATION)

AI-generated representations stay `isAiGenerated=true` and non-authoritative until approval use cases run (already modeled on `StoryRepresentation`).

---

## 16. Crash recovery & migration

### 16.1 Crash scenarios (FACT + RECOMMENDATION)

| Scenario | Current behavior | HS.10 recommendation |
|----------|------------------|----------------------|
| During recording | temp may exist; no Story | Accept limitation: no resume in HS.10 unless explicitly sliced |
| After stop, before Accept | temp + write-only manifest | Document as non-resumable unless Slice adds restore |
| During Accept persistence | on failure, stay reviewing; temp kept | Already good; keep |
| After Accept, before consent | Story durable | Survives; consent optional |
| During AI processing | N/A today | FUTURE job status + retry |
| Mid media copy | failure → no completion entry; cleanup attempts | Keep idempotent sessionId semantics |

**HS.10 default:** do **not** require incomplete-recording recovery for Done. Optionally schedule a later slice to restore review from manifest if temp file still exists.

### 16.2 Migration of pre-HS.10 recordings (FACT)

| Population | Recoverable? | Why |
|------------|--------------|-----|
| Native durable Accepts since HS.9 file adapters | **Yes** | Stories under `stories/*.json` + media under `media/` |
| Web Accepts | **Not across restart** | In-memory repos/media |
| Abandoned review temps | **Unknown / unreliable** | OS temp; no Story metadata |
| Pre-HS.9 era | N/A in this codebase state | Durable path introduced in HS.9 |

**Existing HS.9 recordings: recoverable on native durable installs; not recoverable on web after process death; incomplete sessions not recoverable as Stories.**

No data migration script required for My Stories UI — list existing `FileStoryRepository` contents.

---

## 17. Testing strategy

### Domain

Already largely covered for Story/consent/lifecycle. Add only if new VOs (e.g., processing job status) appear.

### Application

- Owner list returns private drafts, excludes other heroes  
- Owner detail succeeds for private draft  
- Owner media load succeeds for private draft  
- Discoverability-gated use cases still fail for private drafts  
- Archive updates lifecycle and remains owner-listed or filtered per product rule  
- Hard delete (if built) removes Story JSON + media refs  

### Infrastructure

Already have durable reload tests. Extend:

- Owner list after Accept + new `FileStoryRepository` process  
- Missing media reference handling  
- Corrupted JSON handling (as needed)  

### Presentation

- My Stories empty state  
- Story appears after Accept  
- Survives navigation / provider refresh  
- Restart (integration / composition with durable dirs)  
- Detail + playback state  
- Archive behavior  
- Completion CTA navigates to list/detail  

### Integration

```text
Record → Accept → Persist Story + media → Navigate away →
My Stories shows item → Restart → Still listed → Play original
```

Reuse patterns from `test/features/hero_story/integration/hs9_recording_capture_integration_test.dart`.

---

## 18. Risks / tradeoffs

| Risk | Mitigation |
|------|------------|
| Reusing discoverable Story detail for private drafts | Build owner-scoped use cases; do not weaken HS.7 discoverability gates |
| JSON-file scale limits | Accept for MVP; revisit SQL when needed |
| Web users lose Stories on refresh | Document; optional web durable slice |
| Hard delete privacy leaks (orphan media) | Prefer archive; if delete, orchestrate media cleanup |
| Session restore complexity | Defer; don’t block My Stories |
| Exposing domain `Story` in widgets | Presentation models |
| Premature AI processing UI | Consent summary only; no fake progress |

---

## 19. Implementation roadmap

### IMPLEMENTATION ORDER

#### HS.10.1 — Owner read models & application queries

- **Objective:** Safe owner access to private drafts without breaking discoverability.  
- **Likely files:** `list_hero_owned_stories_use_case.dart` (DTO refinement), new `get_owned_story_*`, new `load_owned_story_media_*`, mappers, providers under `application/providers/use_cases/`.  
- **Domain:** none (or minimal helpers).  
- **Application:** owner get/list/media use cases; presentation DTOs.  
- **Infrastructure:** none required.  
- **UI:** none yet.  
- **Tests:** application unit tests for private draft access vs discoverability failure.  
- **Acceptance:** private draft loadable by owner APIs; Discover* still excludes it.  
- **Dependencies:** none.

#### HS.10.2 — My Stories list + empty state

- **Objective:** Heroes IA shows owner library.  
- **Likely files:** `hero_catalog_screen.dart`, new `my_stories_screen.dart`, presentation providers/models.  
- **Domain:** none.  
- **Application:** consume HS.10.1 list.  
- **Infrastructure:** none.  
- **UI:** My Stories entry, list, empty state → Tell Your Story.  
- **Tests:** widget tests empty + populated.  
- **Acceptance:** after durable Accept + relaunch, Story appears in My Stories.  
- **Dependencies:** HS.10.1.

#### HS.10.3 — Owner Story detail + original playback

- **Objective:** Listen to persisted original recording from My Stories.  
- **Likely files:** new owned detail screen, playback helper/notifier, `just_audio` usage.  
- **Domain:** none.  
- **Application:** owner detail + media load.  
- **Infrastructure:** none.  
- **UI:** detail + play/stop.  
- **Tests:** presentation + application; integration play after reload.  
- **Acceptance:** play works for private draft after restart (native durable).  
- **Dependencies:** HS.10.1–10.2.

#### HS.10.4 — Recording completion UX continuity

- **Objective:** Completed step routes into owner Story experience.  
- **Likely files:** `tell_your_story_screen.dart`, controller navigation hooks.  
- **Domain:** none.  
- **Application:** none (use capturedStoryId).  
- **Infrastructure:** none.  
- **UI:** Listen / View My Stories / Done.  
- **Tests:** UI controller/widget tests.  
- **Acceptance:** user never wonders if recording vanished after Accept.  
- **Dependencies:** HS.10.2–10.3.

#### HS.10.5 — Archive (and media-safe removal policy)

- **Objective:** Owner can remove Story from active library safely.  
- **Likely files:** detail actions, wire `ArchiveStoryUseCase`; optional later delete orchestrator.  
- **Domain:** existing archive transition.  
- **Application:** archive; decide list filter (hide archived by default).  
- **Infrastructure:** none for archive; delete would call media port.  
- **UI:** Archive confirm.  
- **Tests:** archive hides from default My Stories; media retained until explicit purge policy.  
- **Acceptance:** archive ≠ publish; private media not exposed via Discover*.  
- **Dependencies:** HS.10.3.

#### HS.10.6 — Privacy & consent presentation on detail

- **Objective:** Make privacy/AI processing consent visible without new grant model.  
- **Likely files:** owned detail UI, consent summary mapper.  
- **Domain:** read `StoryConsent` / visibility.  
- **Application:** optional thin mapper.  
- **UI:** “Private” + consent chips/sections.  
- **Tests:** presentation mapping tests.  
- **Acceptance:** user can see private + AI/processing consent state from HS.9.  
- **Dependencies:** HS.10.3.

#### HS.10.7 — Web durable persistence alignment (optional but recommended)

- **Objective:** Web Accepts survive refresh where technically feasible.  
- **Likely files:** `app_composition_root.dart`, web storage adapter strategy.  
- **Infrastructure:** choose web-capable durable strategy (IndexedDB/file APIs) behind same ports — **design spike first**.  
- **Tests:** web-focused persistence tests if environment supports.  
- **Acceptance:** documented either “durable on web” or explicit limitation remains.  
- **Dependencies:** can parallelize after 10.1; not blocking native My Stories.

#### HS.10.8 — AI readiness scaffold (no production AI)

- **Objective:** Ensure models can attach future transcript/processing without schema dead-ends.  
- **Likely files:** docs/ADR if introducing `StoryProcessingStatus` VO; avoid wiring providers to real AI.  
- **Domain:** optional processing job status VO **only if** needed before AI milestone; otherwise document mapping only.  
- **UI:** copy that preparation happens later (from 10.4).  
- **Acceptance:** original media immutable; placeholders don’t fake AI results.  
- **Dependencies:** after 10.4–10.6.

**Out of scope for HS.10 implementation:** production AI, remote object storage, social feed, weakening discoverability, SQLite migration, CaptureSession aggregate.

---

## 20. Definition of Done (planning checklist)

### Current state

- [x] Where recording files are currently stored  
- [x] Whether they survive restart  
- [x] Whether a Story is created  
- [x] Whether a StoryRepository exists  
- [x] Whether media persistence exists  
- [x] What HS.9 actually persists  

### Architecture

- [x] Recommended Story persistence architecture  
- [x] Recommended media storage architecture  
- [x] Recommended database/file technology  
- [x] Aggregate boundaries  
- [x] Application use cases  
- [x] Repository ports  
- [x] Media storage port  
- [x] Lifecycle model  
- [x] Consent model  
- [x] Future cloud-sync boundary  

### UI

- [x] Heroes information architecture  
- [x] My Stories screen  
- [x] Story list  
- [x] Story detail  
- [x] Recording completion UX  
- [x] Empty state  
- [x] Playback  
- [x] Privacy/consent presentation  
- [x] Delete/archive UX  

### AI readiness

- [x] Original recording preserved  
- [x] Transcript can be added later  
- [x] AI artifacts can be represented independently  
- [x] Provenance survives transformation  
- [x] Human approval remains authoritative  
- [x] AI processing state is modeled appropriately (separated; job status FUTURE)  

### Testing

- [x] Domain / application / infrastructure / presentation / integration / restart plans described  

---

## 21. Required recommendation block

```text
RECOMMENDED ARCHITECTURE
Story persistence:
  Keep local-first StoryRepository; native FileStoryRepository JSON files.
  Do not embed audio in Story documents.

Media persistence:
  Keep StoryMediaStoragePort + LocalFileStoryMediaStorageAdapter
  under application documents; immutable original objects.

Story creation point:
  Option B — create Story on Accept (already HS.9). Keep it.

Lifecycle:
  Accept → draft + private visibility + recorded consent.
  Accept ≠ published. Keep existing StoryLifecycleStatus transitions.

Repository:
  Reuse StoryRepository/HeroRepository; add owner-scoped application queries/DTOs.

Media storage port:
  Reuse StoryMediaStoragePort; add owner-scoped LoadOwnedStoryMedia use case.

Database/storage technology:
  Remain on JSON + path_provider for HS.10; defer Drift/SQLite until query/sync needs demand it.

UI:
  Heroes → My Stories (owner) + Tell Your Story; Browse Stories stays discoverable-only.
  Completion UX navigates to owner Story/list. Prefer Archive over hard delete initially.

AI readiness:
  Preserve original representation; add future transcripts/understanding as separate
  artifacts with provenance; introduce explicit AI job status later; do not conflate
  with lifecycle or publication consent.
```

```text
IMPLEMENTATION ORDER
HS.10.1 Owner read models & application queries
HS.10.2 My Stories list + empty state
HS.10.3 Owner Story detail + original playback
HS.10.4 Recording completion UX continuity
HS.10.5 Archive (media-safe removal policy)
HS.10.6 Privacy & consent presentation on detail
HS.10.7 Web durable persistence alignment (optional)
HS.10.8 AI readiness scaffold (no production AI)
```

---

## 22. Answers to the ten objective questions

1. **What happens to a recording today?**  
   Temp file (native) or memory bytes (web) until review; on Accept, durable media + private draft Story; consent optional; Completed pops UI without owner library.

2. **Where does the audio file actually go?**  
   Temp: `{temp}/hero_story_recording/`. After Accept: `{docs}/hero_story/media/capture/{sessionId}` as `file://` MediaReference (native).

3. **What survives an app restart?**  
   Native durable: Story JSON, media, hero, completion index. Not: unfinished sessions, review state, web in-memory data.

4. **Story vs recording?**  
   Recording alone is a session artifact. Story exists only after Accept.

5. **What persistence infrastructure exists?**  
   File/in-memory Story & Hero repos, StoryMediaStoragePort adapters, CaptureCompletionStore, ActiveLocalHeroStore, composition root wiring.

6. **What is missing?**  
   Owner UI, owner-scoped media/detail queries, completion continuity, archive UX, optional web durability, session resume.

7. **Correct long-term storage architecture?**  
   Ports + local-first metadata store + media object store; remote adapters later; SQL optional later.

8. **How should recorded Stories appear in UI?**  
   My Stories owner library + owner detail/playback; not Discover catalog.

9. **Prepare for AI?**  
   Immutable original, additional representations, consent gates, future job status, human approval.

10. **What first, in what slices?**  
    See HS.10.1–HS.10.8 above.

---

## 23. Validation notes

- This report is documentation only; **no production code or tests were modified** for implementation.  
- Findings verified against source under `lib/features/hero_story/`, `lib/app/app_composition_root.dart`, HS.9 docs/ADRs, and `test/features/hero_story/integration/hs9_recording_capture_integration_test.dart`.  
- Known documentation drift (`repository-map.md` incomplete for Hero/Story) reported, not rewritten.
