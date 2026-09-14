# HS.9 — Production Hero Story Recording & Capture

**Status:** PLANNING COMPLETE — READY FOR IMPLEMENTATION (pending ADR acceptance at kickoff)  
**Date:** 2026-09-14  
**Phase:** HS.9 — Production Hero Story Recording & Capture  
**Document type:** Implementation-ready architectural plan  
**Constraint:** Planning only. This document introduces no production recording code, device SDKs, cloud providers, or UI implementation.

**Authority hierarchy used:**

1. Current ADRs (`architecture-decisions.md`, through HS-ADR-059)
2. Current implementation under `lib/features/hero_story/` and app shell
3. HS.3–HS.8 plans/reports (especially HS.3 capture foundation)
4. Hero & Story Platform Foundation (roadmap context; superseded where code/ADRs differ)
5. Architecture maps / glossary (informational; known stale for Hero & Story)
6. `AGENTS.md` / legacy `CLAUDE.md`

---

## A. Executive Summary

HS.1–HS.8 established a complete **Hero & Story domain and application foundation**, including capture orchestration (HS.3), understanding (HS.4), authoring (HS.5), discovery (HS.6), experience UI (HS.7), and adaptive Today’s Experience relevance (HS.8).

**What is missing for a real Hero to record a real story is not the Story model.**  
It is the **production recording vertical slice**: device capture, local durable media, review/retake, consent UX, application session recovery, and replaceable persistence that outlives process memory.

### Recommended model (one sentence)

**HS.9 is a presentation + infrastructure + application-session vertical slice that records opaque media on-device, reviews it, then completes the existing HS.3 `CompleteStoryCaptureUseCase` path into a draft `Story` with original `StoryRepresentation` + `StoryConsent` + provenance — without expanding AI, discovery, or personalization scope.**

### Critical boundary decisions (summary)

| Concept | HS.9 recommendation |
|---------|---------------------|
| Canonical Story | **Reuse** existing `Story` aggregate (HS-ADR-002). Do not redefine Story as a recording. |
| Capture | **Reuse** HS.3 `CompleteStoryCaptureUseCase` + `sessionId` + `CaptureCompletionStore` (HS-ADR-018). |
| Device recording | **New infrastructure/presentation concern** behind a thin application/recording port. Not a domain aggregate. |
| Media storage | **Extend** `StoryMediaStoragePort` with a durable local (and later remote) adapter. Keep domain on `MediaReference` only (HS-ADR-020). |
| Consent | **Reuse** independent `StoryConsent` gates; ship real consent UX (HS-ADR-021). |
| Format | **MVP = audio** (matches HS.3 hardcoding). Video is an explicit optional extension, not required for first real story. |
| Transcription / AI | **Deferred / async optional** after capture succeeds. Recording must not depend on AI (HS.4 ports already exist). |
| H.2 Behavioral Understanding | **No automatic interaction.** Recording/capture ≠ evidence (align HS-ADR-051). |
| Auth / Identity | **MVP bootstrap Hero** (create/select local Hero). Full Identity BC deferred. |
| Backend / cloud object storage | **Not required for first real story.** Local durable persistence is MVP; cloud adapter must remain replaceable. |
| HS.8 / UI.3 | **Do not change adaptive experience selection** for HS.9 MVP. Entry is Hero-facing “Tell Your Story,” not Today’s Experience. |

### Final recommendation

**HS.9 READY FOR IMPLEMENTATION** as a phased vertical slice (see §19), contingent on accepting the architectural decisions in §X at kickoff.

---

## B. Repository Inspection Results

### B.1 Phase status (code on `main` as of 2026-09-14)

| Phase | Status | Evidence |
|-------|--------|----------|
| HS.1 Hero & Story Domain Foundation | **Complete** | `Hero`, `Story`, lifecycle, repos, events under `lib/features/hero_story/` |
| HS.2 Story Catalog | **Complete** | Classification, suitability, spirituality, search adapters |
| HS.3 Story Capture Foundation | **Complete** | Consent, provisional narrative, `StoryMediaStoragePort`, `CompleteStoryCaptureUseCase`, ADRs 017–021 |
| HS.4 Story Understanding / AI | **Complete** | `StoryUnderstanding`, transcription/understanding ports + use cases, in-memory AI stubs |
| HS.5 Story Authoring | **Complete** | Authoring/translation ports, generate/edit/approve representation use cases |
| HS.6 Discovery | **Complete** | Discover*/Search* use cases, discoverability policies |
| HS.7 Hero Experience | **Complete** | Experience use cases + Heroes tab screens (catalog/detail/consume) |
| HS.8 Adaptive Hero Discovery | **Complete** | Adaptive signals → Discover* → Today’s Experience story routing; ADRs 054–059 |
| HS.9 Production Recording | **Not started** | No recording UI, no device packages, no local/cloud media adapters, no capture providers |

### B.2 What already exists (Hero & Story)

**Aggregates**

- `Hero` — profile, visibility, status; `HeroRepository` (in-memory)
- `Story` — narrative, lifecycle, visibility, classification, suitability, spirituality, provenance, consent, representations; `StoryRepository` (in-memory)
- `StoryUnderstanding` — proposed/reviewed AI understanding; separate from Story

**Capture-related**

- `CompleteStoryCaptureUseCase` — bytes → store → Story.createFromCapture / attach original audio representation → `markCaptureRecorded`
- `CancelStoryCaptureUseCase` — clear completion store + optional media delete
- `UpdateStoryConsentUseCase` — grant/revoke processing / publication / AI
- `CaptureCompletionStore` / `InMemoryCaptureCompletionStore` — application idempotency by `sessionId`
- `StoryMediaStoragePort` + `InMemoryStoryMediaStorageAdapter` only
- Legacy `StoryCapturePort` + `UnsupportedStoryCaptureAdapter` — **do not expand**; HS-ADR-020

**Downstream pipeline (already coded; stub AI / in-memory)**

```text
CompleteStoryCapture
  → draft Story + original audio StoryRepresentation + recorded consent
  → UpdateStoryConsent (processing / AI / publication)
  → SubmitStoryUseCase (requires processing consent) → lifecycle processing
  → TranscribeStoryRepresentationUseCase (HS.4, requires processing + AI)
  → GenerateStoryUnderstandingUseCase / Review / Apply (HS.4)
  → UpdateStoryNarrativeUseCase / GenerateStoryScriptUseCase / ApproveRepresentation (HS.5)
  → ApproveStoryUseCase / PublishStoryUseCase (publication consent + non-provisional narrative)
  → Discover* (HS.6) → Experience/Consume (HS.7) → Adaptive Today’s Experience (HS.8)
```

**UI present**

- App shell: Home / Journey / Discover / **Heroes** / Reflect
- Heroes tab → catalog → profile → story detail → consume (text/byte-length; no AV player)
- Home Today’s Experience can route to Story (HS.8)
- **No** Tell Your Story / prepare / consent / record / review screens
- Capture use cases are **not** Riverpod-wired

**Packages (`pubspec.yaml`)**

Present: `flutter`, `uuid`, `cupertino_icons`, `collection`, `flutter_riverpod`, `meta`  
Absent: camera, recorders, video_player, just_audio, permission_handler, path_provider, firebase/supabase/AWS SDKs, go_router, Hive/SQLite/SharedPreferences

**Platform permissions**

- iOS: no `NSCameraUsageDescription` / `NSMicrophoneUsageDescription`
- Android: no `CAMERA` / `RECORD_AUDIO` manifests

**Infrastructure reality**

| Capability | Status |
|------------|--------|
| Backend HTTP APIs | Missing |
| Authentication / Identity BC | Missing (`Hero.identityUserId` optional only) |
| Object storage / signed URLs / CDN | Missing |
| Durable Story/Hero DB | Missing (in-memory only) |
| Local filesystem media store | Missing |
| Resumable upload | Missing |
| Production AI | Missing (deterministic in-memory stubs) |

### B.3 Documentation vs implementation notes

| Item | Classification | HS.9 action |
|------|----------------|-------------|
| Foundation §20 capture pipeline includes Transcribe before Review | Intentional evolution (A) — HS.3/HS.4 put capture before AI | Follow code: record → capture → Story; transcription async later |
| Foundation HS.3 listed “transcript representation” in capture slice | Superseded by HS.3/HS.4 split | Do not re-bundle transcription into HS.9 MVP |
| Architecture maps omit/under-document Hero & Story | Documentation drift (C) | Report; do not rewrite maps unless needed for HS.9 clarity |
| Legacy `StoryCapturePort` unused by real capture | Intentional (HS-ADR-020) | Leave stub; do not revive as recording API |
| HS.8 now implemented on main | Intentional (A) | Plan against completed HS.8; do not alter adaptive selection for capture entry |

---

## C. HS.3 Capture Design — Explicit Answers

Answers are based on repository code and HS.3 ADRs/reports.

### 1. What is the current definition of a Story Capture?

Capture is an **application workflow**, not a domain aggregate (HS-ADR-018).  
Operationally: a `sessionId`-keyed completion that stores media bytes via `StoryMediaStoragePort` and attaches an original audio `StoryRepresentation` to a draft `Story` via `CompleteStoryCaptureUseCase`.

### 2. What constitutes a canonical Story?

The `Story` aggregate: title, narrative (canonical; may start provisional), original language, lifecycle, visibility, classification, suitability, spirituality, provenance, consent, and representations.  
Audio/video files are **representations**, not the Story itself (HS-ADR-002 / HS-ADR-019).

### 3. How is a recording represented?

As `StoryRepresentation` with:

- `format: StoryRepresentationFormat.audio` (hardcoded in `CompleteStoryCaptureUseCase`)
- `origin: RepresentationOrigin.original`
- `mediaReference: MediaReference(uri)`
- `isAiGenerated: false`
- attached with `StoryTransformationType.recording` provenance

### 4. Where is raw media stored?

Only behind `StoryMediaStoragePort`. Current adapter stores bytes in a process-local `Map` with `memory://…` URIs. Domain never holds bytes.

### 5. What does StoryMediaStoragePort currently provide?

```text
store(StoreStoryMediaRequest) → MediaReference
exists(MediaReference) → bool
retrieve(MediaReference) → Uint8List?
delete(MediaReference) → void
```

Request fields: `bytes`, optional `contentType`, `checksum`, `suggestedKey`.

### 6. Is there already an application use case for recording/capturing?

Yes for **completion**: `CompleteStoryCaptureUseCase`, plus `CancelStoryCaptureUseCase` and `UpdateStoryConsentUseCase`.  
There is **no** use case for device start/pause/resume/stop recording.

### 7. Can the current implementation accept an actual video/audio file?

**Yes, as opaque bytes**, if a caller supplies non-empty `Uint8List` to `CompleteStoryCaptureUseCase`.  
It does **not** open files, record devices, or validate codecs. Format is labeled `audio` regardless of content.

### 8. Is there an abstraction separating Flutter/device recording from domain/application logic?

**No device-recording port.** Separation exists only for **media persistence** (`StoryMediaStoragePort`). Legacy `StoryCapturePort` is an unused HS.1 stub and must not become the device API.

### 9. Is local storage currently supported?

**No** durable local filesystem adapter. In-memory only.

### 10. Is cloud/remote storage supported?

**No.**

### 11. Is resumable upload supported?

**No.**

### 12. What metadata is captured?

On completion request (optional unless noted): `sessionId`, `heroId`, `storyId`, `representationId`, `originalLanguage`, `mediaBytes`, `title?`, `originalSourceDescription?`, `contentType?`, `checksum?`, `duration?`, `occurredAt?`.  
Representation may store `duration`. Provenance records recording transformation step.

### 13. What consent is currently persisted?

`StoryConsent` on Story with independent timestamps:

- `recordedAt` (set by `markCaptureRecorded` on successful capture)
- `processingApprovedAt`
- `publicationApprovedAt`
- `aiTransformationApprovedAt`

### 14. What happens if recording fails?

**Undefined in product code** — no recording layer exists.

### 15. What happens if storage fails?

`CompleteStoryCaptureUseCase` catches `StoryMediaStorageException` → `Failure`. On other post-store failures, best-effort `delete` of stored media.

### 16. What happens if the app is interrupted?

**No recovery.** In-memory repos/media/completion store are lost on process death. No recording session persistence.

### 17. What happens if the Hero abandons a recording?

`CancelStoryCaptureUseCase` clears completion-store entry and optionally deletes a known `MediaReference`. It does **not** delete an already-persisted Story aggregate. Pre-completion abandonment of device files is unimplemented.

### 18. Can a Hero review a recording?

**No UI.** HS.7 consume shows byte length for discoverable authoritative media; it is not a capture-review player.

### 19. Can a Hero retake it?

**No product flow.** Retake would require discarding temp media before calling complete (or cancel + new session). Not implemented.

### 20. Can a Hero recover an unfinished recording?

**No.**

---

## D. Downstream Story Pipeline (HS.4–HS.8)

### D.1 Concept mapping (preserve distinctions)

| User-facing idea | Repository terminology |
|------------------|------------------------|
| Raw Recording | Local temp media file(s) + presentation/application session state (not domain) |
| Capture | `CompleteStoryCaptureUseCase` success → durable `MediaReference` + original representation |
| Canonical Story | `Story` aggregate (narrative may be provisional until authored) |
| Representation | `StoryRepresentation` (audio/video/written/transcript/script/…) |
| Understanding | `StoryUnderstanding` aggregate (AI proposal; non-authoritative until reviewed/applied) |
| Authoring | Unapproved derived `StoryRepresentation`s + explicit `approveRepresentation` / `UpdateStoryNarrativeUseCase` |
| Hero Review / Approval | Story lifecycle `review` → `approved`; representation `isApproved` |
| Publication / Discoverability | `publish` + visibility + HS.6 policies; HS.7/HS.8 consume discoverable catalog |

### D.2 What exists vs planned for “after capture”

| Stage | Exists in code? | Production-ready? | HS.9 obligation |
|-------|-----------------|-------------------|-----------------|
| Capture completion | Yes | Orchestration yes; durable media no | **Must complete** for first story |
| Consent gates | Yes | Domain yes; UX no | **Must ship consent UX** for processing at minimum if submitting |
| Transcription | Yes (port + UC) | Stub AI only | **Defer** from recording critical path |
| Understanding | Yes | Stub AI only | Defer |
| Authoring / scripts | Yes | Stub AI only | Defer |
| Hero narrative authorship | Yes (`UpdateStoryNarrativeUseCase`) | App yes; UI no | Optional post-capture; required before approve/publish |
| Approve / Publish | Yes | Domain yes; UI no | Optional for first capture success; not required to “submit recording” |
| Discovery / Experience | Yes | In-memory catalog | Out of HS.9 recording scope |
| Adaptive Today’s Experience | Yes (HS.8) | Deterministic over Discover* | Do not couple recording entry to HS.8 |

### D.3 H.2 interaction decision

**HS.9 must not feed BehavioralEvidence automatically.**

Recording, reviewing, accepting, capturing, or submitting a Story is **not** growth evidence.  
Optional reflection remains the existing HS.7 bridge (`StartStoryReflectionUseCase` → Life Journey `CreateReflectionUseCase`) and is out of HS.9 recording MVP.

---

## E. Production Recording Boundary

### E.1 Desired dependency direction

```text
Presentation (Tell Your Story UI / Riverpod state)
        ↓
Application (recording session orchestration + existing capture/consent use cases)
        ↓
Domain (Story / Hero / Consent / Representation / Provenance)
        ↑
Ports (StoryMediaStoragePort + new DeviceRecordingPort)
        ↑
Infrastructure (device recorder, local FS, optional remote uploader)
```

### E.2 Ports justified for HS.9

| Port | Introduce? | Why |
|------|------------|-----|
| `StoryMediaStoragePort` | **Reuse / extend adapters** | Already the media boundary (HS-ADR-020) |
| `DeviceRecordingPort` (name TBD) | **Yes — thin application or infrastructure port** | Separates Flutter camera/mic packages from application orchestration |
| Playback port | **No separate domain port for MVP** | Review playback is presentation + local file URI / bytes; align HS-ADR-050 spirit |
| Upload/resumable port | **Optional later extension of media storage**, not a second domain concept | Only if remote persistence is in scope for a slice |
| Permission port | **Prefer OS APIs via recording adapter**, not a domain port | Permissions are device concerns |
| `StoryCapturePort` (legacy) | **Do not expand** | HS-ADR-020 |

### E.3 Proposed `DeviceRecordingPort` (application/infrastructure boundary)

Minimal surface (illustrative; finalize at implementation):

```text
prepare() / checkPermissions()
start({ mode: audio | video }) → RecordingHandle
pause() / resume() / stop() → LocalRecordingArtifact
cancel()
observe interruptions / failures (stream or callbacks)
```

`LocalRecordingArtifact` carries local path/URI, duration, content type, checksum — **not** domain types.

Presentation never calls repositories or constructs domain events.  
Application maps accepted artifact → `CompleteStoryCaptureRequest.mediaBytes` (or path-based store extension).

### E.4 Media storage extension

Keep port methods stable. Add adapters:

1. **`LocalFileStoryMediaStorageAdapter`** (HS.9 MVP) — durable on-device object store; `file://` or app-documents URI scheme
2. **Optional later:** remote object-storage adapter implementing same port (possibly with multipart/resumable internals hidden inside adapter)

Consider optional port evolution **only if needed**:

- `storeFromFile(path)` to avoid loading multi-minute recordings entirely into `Uint8List` RAM
- If added, keep it on the port; do not put paths into `Story`

---

## F. Production Hero Recording Experience

### F.1 Entry — “Tell Your Story”

**Recommended primary entry (HS.9 MVP):**

Extend the existing **Heroes** surface (or a Hero-owned area reached from Heroes tab) with a clear **Tell Your Story** action for the current local Hero.

Rationale:

- HS.7 already established Heroes as the Hero/Story navigation home (HS-ADR-052)
- Home Today’s Experience is seeker/adaptive (HS.8); do not overload it as capture entry
- Discover tab remains seeker catalog/placeholder — not capture
- Avoid inventing a new bottom-nav destination

**Secondary entry (optional):** Home shortcut card currently has empty `onTap`s — may deep-link to the same flow without redesigning shell.

**Prerequisite bootstrap:** because Identity/auth is missing, HS.9 must include a minimal **local Hero bootstrap** (create Hero if none; select active HeroId for capture). This is application/presentation composition, not a new Identity BC.

### F.2 Preparation

Before recording, show:

- Short story prompt / invitation to share lived experience
- Expected length guidance (e.g., several minutes; soft target, not hard product score)
- Environment guidance (quiet place, stable phone, lighting if video)
- Privacy reminder (private by default; capture ≠ publish)
- Link into consent step

Preparation content is **presentation copy**, not domain rules.

### F.3 Consent UX (respect HS.3)

Do **not** collapse to one checkbox.

**HS.9 MVP consent screens must distinguish:**

| Gate | When required in HS.9 MVP |
|------|---------------------------|
| Recording awareness / recorded | Capture success sets `recordedAt` via existing `markCaptureRecorded` |
| Processing | Required before `SubmitStoryUseCase` / any HS.4 AI |
| AI transformation | Required before transcription/understanding/authoring AI ports |
| Publication | Required before `PublishStoryUseCase` — **can be deferred** from first-record MVP if story remains private draft |

**Recommended MVP UX sequence:**

1. Pre-record: explain recording will create a **private draft** owned by the Hero
2. Pre-accept or pre-submit: explicit toggles for **Processing** and **AI** (independent)
3. Publication consent: separate later screen when Hero chooses to publish

Wire through existing `UpdateStoryConsentUseCase`.

### F.4 Recording UX

Plan:

- **MVP mode: audio** (matches HS.3). Video optional extension behind same recording port.
- Request microphone (and camera only if video enabled)
- Start / elapsed timer / Pause / Resume / Stop / Cancel
- Handle permission denial with clear recovery (settings guidance)
- Handle recorder init failure, mid-recording device loss, low storage
- Keep UI portrait-stable for audio MVP; video rotation policy only if video slice is scheduled
- On stop → navigate to Review with local artifact (not yet `CompleteStoryCapture`)

### F.5 Review UX

- Playback of local artifact (seek/scrub)
- Display duration; optional title field
- Actions: **Accept**, **Retake**, **Discard**
- Accept → durable store + `CompleteStoryCaptureUseCase`
- Retake → discard temp artifact, return to Record (new or same `sessionId` policy: **new sessionId recommended**)
- Discard → cancel session + delete temp; no Story if none created yet

### F.6 Recovery support matrix

| Scenario | HS.9 MVP | Deferred |
|----------|----------|----------|
| App backgrounding during record | Best-effort pause/stop + keep temp file | Perfect OS-call continuity |
| Incoming call / audio interruption | Stop or pause; preserve temp if OS allows | Guaranteed seamless resume across all OEMs |
| Device lock | Same as backgrounding | — |
| App crash mid-record | Recover temp file if flushed to disk + session manifest | Crash-safe encoded partials for all codecs |
| Insufficient storage | Fail before/during record with message | Smart compression pipeline |
| Failed local persist on accept | Keep temp; retry accept; do not mark complete | — |
| Failed upload / network loss | N/A if local-only MVP | Required when remote adapter ships |
| Resumable multipart upload | Deferred | Explicit post-MVP |
| Partially uploaded media | Deferred | With remote adapter |
| Corrupt media on review | Detect playback failure; force retake | Repair tools |

---

## G. Media Lifecycle

### G.1 Recommended lifecycle (aligned to existing architecture)

```text
RecordingStarted
      ↓
Local Temporary Media (app cache/temp; not a MediaReference yet)
      ↓
RecordingStopped
      ↓
Review (playback of temp)
      ├── Retake / Discard → delete temp; no domain capture
      └── Accept
            ↓
      Durable store via StoryMediaStoragePort → MediaReference
            ↓
      CompleteStoryCaptureUseCase
            ↓
      Draft Story + original StoryRepresentation + recorded consent + recording provenance
            ↓
      (Optional later) remote replication of same MediaReference scheme
            ↓
      (Much later / separate) published representations for discoverability
```

### G.2 Distinctions

| Kind | Definition | Mutability |
|------|------------|------------|
| Temporary media | Pre-accept local recording file | Disposable |
| Accepted / durable media | Stored via `StoryMediaStoragePort`; referenced by Story representation | **Immutable after successful capture complete** (replace via retake-before-complete or new representation; do not silently overwrite captured original) |
| Published media | Same bytes/reference may become discoverable only after lifecycle+visibility+consent gates | Access gated by HS.6/HS.7 policies; not a different blob type |

### G.3 Immutability rule

After `CompleteStoryCaptureUseCase` succeeds for a `sessionId`, that session’s media reference and original representation are durable facts.  
Retake **before** accept is free.  
Post-accept “retake” is a **new capture session** (new representation / product decision); do not mutate the original captured representation in place.

---

## H. Story Lifecycle / State Model

### H.1 States that already exist (domain)

`StoryLifecycleStatus`:

`draft → processing → review → approved → published → archived`  
(+ `rejected`, `suspended`, `removed`)

Capture defaults: **draft + private** (`Story.createFromCapture`).

### H.2 What HS.9 should add

**Do not invent a giant parallel Story state machine for recording.**

| Concern | Layer | Recommendation |
|---------|-------|----------------|
| draft/processing/review/… | Domain (existing) | Reuse |
| recorded/processing/publication/AI consent | Domain VO (existing) | Reuse |
| preparing / recording / paused / reviewing / accepting / failed | **Presentation + application session** | New lightweight session state |
| uploading / uploaded | Infrastructure (if remote) | Adapter-internal; surface progress DTO only |
| ReadyForReview / Failed as Story statuses | — | **Do not add**; map to existing lifecycle + session failure UX |

### H.3 Application session states (proposed)

```text
idle → preparing → consenting → recording ↔ paused → reviewing
 → persisting → completed
 → failed / cancelled
```

Persisted session manifest (local) should include: `sessionId`, `heroId`, intended `storyId`, paths, timestamps, phase — **application only** (HS-ADR-018).

---

## I. Failure Semantics

For each failure class:

### I.1 Recording failure (camera/mic unavailable)

| Layer | Behavior |
|-------|----------|
| Domain | No change |
| Application | Session → failed; no CompleteCapture |
| UI | Error + retry permissions / switch mode |
| Persistence | Delete partial temp if unusable |
| Recovery | Return to prepare/record |

### I.2 Storage failure (cannot persist accepted media)

| Layer | Behavior |
|-------|----------|
| Domain | No Story mutation |
| Application | Do not call complete; or complete fails and rolls back media best-effort (existing) |
| UI | Keep review screen; Retry Accept |
| Persistence | Temp retained |
| Recovery | Retry store → complete |

### I.3 Upload failure / network loss

| Layer | Behavior |
|-------|----------|
| MVP (local-only) | N/A |
| Later remote | Adapter retries; session remains completed locally; upload queue separate |

### I.4 App interruption

| Layer | Behavior |
|-------|----------|
| Application | On resume, reload session manifest; if recording was active, mark interrupted → reviewing or record-again |
| UI | Explain interruption; offer continue review if file intact |

### I.5 User cancellation

| Layer | Behavior |
|-------|----------|
| Application | `CancelStoryCaptureUseCase` if session completed earlier; else delete temp + clear manifest |
| Domain | Do not delete existing Story unless product explicitly adds that use case (currently cancel does not delete Story) |

### I.6 Retake

| Layer | Behavior |
|-------|----------|
| Application | New `sessionId`; discard previous temp |
| Domain | Unchanged until a completion succeeds |

### I.7 Corrupt media

| Layer | Behavior |
|-------|----------|
| UI | Playback error → Retake required |
| Application | Block Accept if artifact fails validation (non-empty + playable/probe) |

### I.8 Duplicate submission

| Layer | Behavior |
|-------|----------|
| Application | Existing `CaptureCompletionStore` idempotency by `sessionId` returns prior success |
| Durable store | Completion store must become durable in HS.9 (not memory-only) for crash-safe idempotency |

---

## J. Privacy, Consent, and Ownership

Preserve HS.3 / HS-ADR-021.

| Concern | Representation |
|---------|----------------|
| Who owns the story | `Story.heroId` |
| Who created capture | Same Hero; optional `identityUserId` on Hero when Identity exists |
| When captured | `Story.createdAt` / representation provenance `occurredAt` / `consent.recordedAt` |
| Consent status | Independent `StoryConsent` timestamps |
| Visibility / discoverability | `StoryVisibility` default **private**; HS.6 policies ignore private/unlisted |
| Withdrawal | Reuse revoke processing/publication/AI + lifecycle archive/remove/suspend; full legal deletion workflow deferred |

HS.9 must not invent a parallel privacy framework.

---

## K. Provenance

Reuse `StoryProvenance` / `ProvenanceStep`.

| Artifact | Provenance expectation |
|----------|------------------------|
| Original recording capture | `StoryTransformationType.recording` on representation add (already done by CompleteCapture) |
| Capture original source description | `Story.createFromCapture` default / request override |
| Transcription | Existing HS.4 transcription path (`transcription` transformation; AI-assisted) |
| Understanding | `UnderstandingProvenance` on `StoryUnderstanding` (separate) |
| Authoring / translation | Existing HS.5 provenance on derived representations |
| Hero approval of representation | `StoryRepresentationApproved` + `isApproved` (authoritative only when approved or non-AI) |

**Rule:** AI-derived content remains non-authoritative until explicit approval (HS-ADR-006 / 034). HS.9 must not auto-promote transcripts/scripts into canonical narrative.

---

## L. Transcription and AI

**Recommendation: Defer transcription from HS.9 critical path.**

Preferred flow:

```text
Recording → Review → Accept → Capture succeeds → Story exists
        ↓ (async / later phase or optional HS.9 Slice C)
Transcription / Understanding / Authoring (existing HS.4/HS.5 use cases)
```

Reasons:

- Recording must work offline and without AI credentials
- HS.4 already owns transcription ports/use cases
- Production AI providers still absent
- First Real Hero Story goal is durable capture, not AI output quality

If a late HS.9 slice triggers transcription, it must:

- require processing + AI consent
- be asynchronous after capture
- use existing ports only
- never block Accept/Capture success

---

## M. Backend / Storage Reality

### M.1 Current reality

No backend, auth, object storage, or durable DB.

### M.2 Distinguish MVP vs eventual production

| Concern | MVP capture infrastructure (HS.9) | Eventual production |
|---------|-----------------------------------|---------------------|
| Hero/Story persistence | Local durable repository adapters (file/JSON/SQLite — choose at impl) behind existing repository ports | Remote API + synced store |
| Media bytes | `LocalFileStoryMediaStorageAdapter` | Cloud object storage adapter of same port |
| Capture idempotency | Durable `CaptureCompletionStore` | Server-side idempotency keys |
| Auth | Local active Hero bootstrap | Identity BC + auth |
| Upload | None or opportunistic later | Signed URL / resumable upload inside remote adapter |
| CDN / streaming | None | Later; HS.7 playback remains representation consumption |

**Architectural rule:** temporary local adapters must implement the same ports so they can be replaced without rewriting domain/application capture orchestration.

---

## N. First Real Hero Story

**Scenario:** A real Hero on an iPhone opens Everyone’s Heroes, taps Tell Your Story, records several minutes, reviews, accepts, consents as required, and submits successfully.

| Step | Existing | Required for HS.9 | Dependency | Risk |
|------|----------|-------------------|------------|------|
| 1. Install/run iOS app | Flutter iOS project exists | Dev/TestFlight build with mic permission strings | Xcode signing / device | Medium |
| 2. Open app | App shell works | — | — | Low |
| 3. Have a Hero identity | `CreateHeroUseCase` exists; no UI/bootstrap | Local Hero bootstrap UI + persistence | Durable Hero repo | Medium |
| 4. Navigate to Tell Your Story | Heroes tab exists; no capture entry | Entry CTA + flow routing | Navigation conventions | Low |
| 5. Prepare | None | Preparation screen copy | — | Low |
| 6. Consent (processing/AI as needed) | Domain + UpdateConsent UC | Consent UI wired to UC | — | Low |
| 7. Grant mic permission | None | Permission UX + Info.plist | iOS privacy strings | Medium |
| 8. Record several minutes | None | DeviceRecordingPort + audio recorder adapter + pause/resume | Package selection | **High** |
| 9. Interruptions | None | Temp file + session manifest | OS audio session behavior | High |
| 10. Review/playback | None | Local audio playback + scrub | Player package | Medium |
| 11. Retake / discard | Cancel UC partial | Temp cleanup + new session | — | Low |
| 12. Accept | CompleteCapture UC (bytes) | Read file → store durable → complete; prefer file-based store to avoid RAM blowups | Media port extension | **High** |
| 13. Persist Story across relaunch | In-memory only | Durable Story/Hero repos + durable media + durable completion store | Storage choice | **High** |
| 14. Confirm success | None | Confirmation + “your private draft is saved” | — | Low |
| 15. Optional submit for processing | SubmitStory UC | Consent already granted; submit button | — | Low |
| 16. Transcription/AI | HS.4 stubs | **Not required** for success definition of first story | AI provider | Deferred |
| 17. Publish/discover | HS.5–HS.8 | **Not required** for first capture success | Authored narrative | Deferred |

**Definition of success for First Real Hero Story:**

> After accept, the Hero can kill the app, reopen it, and still find their private draft Story with playable original recording media and recorded consent — without any backend or AI.

---

## O. Testing Strategy

### O.1 Domain tests (extend existing)

- Capture invariants already covered (`story_capture_test`, consent, provisional narrative) — keep green
- Add only if HS.9 changes domain (prefer **not** changing domain)
- If audio/video format parameterization is added to CompleteCapture, test representation format + provenance

### O.2 Application tests

- Recording session orchestration (start/pause/resume/stop/cancel/retake) with fake `DeviceRecordingPort`
- Accept path → CompleteCapture integration with fake media store
- Durable completion-store idempotency across “restart” (rehydrate fake durable store)
- Storage failure retry; cancel cleanup; corrupt artifact rejection
- Consent update wiring before submit

### O.3 Infrastructure tests

- `LocalFileStoryMediaStorageAdapter` store/exists/retrieve/delete
- Large-ish fixture file handling
- DeviceRecordingPort fake; optional integration test harness behind flags
- Do not require a physical device for CI unit/application tests

### O.4 UI tests

- Prepare → Consent → Record (fake recorder) → Review → Accept happy path
- Pause/resume controls
- Permission denied state
- Retake / discard
- Failure banners + recovery
- Entry from Heroes tab

### O.5 Integration proof (minimum)

```text
Hero bootstrap
  → Record (fake device)
  → Review
  → Accept
  → CompleteStoryCaptureUseCase
  → StoryRepository.findById
  → media retrieve playable bytes
  → (optional) UpdateConsent + Submit
```

Avoid tests that only mock away persistence and capture completion.

---

## P. Architecture Constraints (non-negotiable)

HS.9 must preserve:

- DDD + hexagonal boundaries
- Hero & Story bounded context ownership
- Domain free of Flutter/Riverpod/device SDKs/AI SDKs
- Riverpod as composition/UI state, not business rules
- Application use cases as the write path
- Existing HS.3 concepts (no `StorySource`, no CaptureSession aggregate)
- Existing HS.5 authoring authority rules
- HS.6 discoverability fail-closed privacy
- HS.7 experience consumption boundaries
- UI.3/HS.8 adaptive selection **unchanged** for MVP
- H.2 evidence boundaries (no auto evidence from recording)

Presentation must not manipulate aggregates, access repositories directly, construct domain events, or invoke detectors.

Before any new abstraction: search for an existing equivalent (especially `StoryMediaStoragePort`, CompleteCapture, StoryConsent).

---

## Q. Explicit Reuse Evaluation

| Existing Component | Reuse? | How | Changes Needed |
|--------------------|--------|-----|----------------|
| Hero | Yes | Owner of captured Story; bootstrap active Hero | Durable repo adapter; bootstrap UI |
| Story | Yes | `createFromCapture` / lifecycle / visibility | Prefer no domain change |
| Story Capture (workflow) | Yes | `CompleteStoryCaptureUseCase` + sessionId | Wire providers; durable completion store; optional format param |
| Story Narrative | Yes | Provisional until authored | None for MVP recording |
| Story Consent | Yes | Independent gates + UpdateConsent UC | Consent screens |
| Story Representation | Yes | Original audio representation | Optional video format later |
| StoryMediaStoragePort | Yes | Durable media boundary | Local file adapter; optional `storeFromFile` |
| In-memory media adapter | Yes | Tests / demos | Keep; not production default |
| Legacy StoryCapturePort | No expand | Leave stub | None |
| Repositories (Hero/Story) | Yes | Persist capture results | Durable local adapters |
| Provenance | Yes | Recording transformation already appended | None |
| Authoring (HS.5) | Later | After capture, optional | No HS.9 dependency |
| Discovery (HS.6) | No for capture entry | Keep private drafts undiscoverable | None |
| HS.7 Story Experience | Partial | Possible post-capture “view my draft” using private owner path — **careful**: HS.7 is discoverability-gated | Prefer Hero-owned draft list use case rather than weakening Discover* |
| HS.8 Adaptive Discovery | No | Seeker relevance; not capture | None |
| Application providers | Extend | Add capture/consent/recording providers | New provider files |
| Navigation / App shell | Extend | Tell Your Story entry on Heroes (or Home deep link) | Minimal shell change |
| UI components (HS.7 screens) | Reuse patterns | New capture screens alongside HS.7 | Do not overload consume screen as recorder |

---

## R. Missing Infrastructure Inventory

### Already Exists

- Hero / Story / StoryUnderstanding domain model
- StoryConsent (4 gates)
- Complete / Cancel capture use cases
- StoryMediaStoragePort contract + in-memory adapter
- CaptureCompletionStore (memory)
- Downstream HS.4–HS.8 pipelines (stub AI / in-memory)
- Heroes tab navigation shell
- Event bus / Result / ID generators

### Exists but Needs Extension

- `StoryMediaStoragePort` adapters → local durable (and later remote)
- `CaptureCompletionStore` → durable implementation
- `HeroRepository` / `StoryRepository` → durable local adapters for MVP survival across relaunch
- `CompleteStoryCaptureUseCase` → possibly accept file-backed store / format audio|video
- Riverpod composition → wire capture/consent/recording use cases
- Platform permission manifests
- HS.7-style UI patterns → new capture flow screens
- Playback: today byte-length only → real local review player

### Completely Missing

- Device recording port + adapters
- Tell Your Story / prepare / consent / record / review UI
- Session manifest recovery
- Auth / Identity production
- Backend APIs, signed URLs, CDN, resumable upload
- Production AI providers
- Owner-private “my drafts” experience API (Discover* intentionally excludes private)

### Should Be Deferred

- Production cloud object storage & resumable upload
- Full Identity/auth
- Video recording (unless explicitly pulled into a slice)
- Transcription/understanding/authoring in the recording critical path
- Publication/discovery of the first captured story
- Automatic H.2 evidence from capture
- Social/feed/marketplace
- Changing HS.8 adaptive selection to promote capture

---

## S. Determine Phase / Implementation Slices

### S.1 Phase identity

**HS.9 — Production Hero Story Recording & Capture** is the correct next phase after HS.8.

It is **not** a redo of HS.3. HS.3 remains the capture foundation. HS.9 makes that foundation operable for a real human on a real device.

### S.2 Recommended slices

#### Slice A — Durable Capture Foundation (blocking)

1. Local durable `StoryMediaStoragePort` adapter
2. Durable Hero/Story repository adapters (minimum viable)
3. Durable `CaptureCompletionStore`
4. Riverpod providers for Complete/Cancel/UpdateConsent
5. Optional `storeFromFile` port extension if large recordings require it
6. Tests for persistence + idempotency across relaunch simulation

**Exit:** bytes/file → CompleteCapture → survives process restart in local persistence.

#### Slice B — Device Recording + Review UX (blocking for First Real Story)

1. ADR(s) for DeviceRecordingPort + session-state non-aggregate confirmation
2. Package evaluation task (audio recorder + player + permissions + path_provider) — pick at impl kickoff, not in this plan
3. Recording session application service
4. Screens: Prepare → Consent → Record → Review
5. Heroes-tab Tell Your Story entry + local Hero bootstrap
6. iOS/Android permission configuration
7. Failure/recovery MVP behaviors
8. UI + application tests with fake recorder

**Exit:** First Real Hero Story success definition met on a physical iPhone (audio).

#### Slice C — Submit & Optional Downstream Hooks (non-blocking for “captured”)

1. Post-capture confirmation + “Submit for processing” using existing Submit UC
2. Optional async trigger to HS.4 transcription **only if** AI consent granted and a non-stub provider is configured
3. Owner draft list (Hero’s private stories) without weakening HS.6 Discover*

**Exit:** Hero can move a captured draft into processing without publication.

#### Slice D — Remote Media / Upload (explicitly post-MVP unless product mandates)

1. Remote object-storage adapter for `StoryMediaStoragePort`
2. Upload progress DTO + retry
3. Resumable upload if required by payload size
4. Keep local durable copy until remote ACK

**Exit:** Same capture UX; media also lands in replaceable remote storage.

### S.3 Suggested ADR candidates at kickoff

| ID (provisional) | Decision |
|------------------|----------|
| HS-ADR-060 | HS.9 is production recording vertical slice over HS.3; no CaptureSession aggregate |
| HS-ADR-061 | Introduce DeviceRecordingPort; do not expand legacy StoryCapturePort |
| HS-ADR-062 | MVP media durability via local StoryMediaStoragePort adapter; remote deferred but replaceable |
| HS-ADR-063 | MVP recording format is audio; video optional extension |
| HS-ADR-064 | Transcription/AI remain post-capture asynchronous; not recording dependencies |
| HS-ADR-065 | Local Hero bootstrap allowed until Identity BC exists |
| HS-ADR-066 | Recording/capture does not create BehavioralEvidence |

Exact ADR numbers to be assigned when recorded in `architecture-decisions.md`.

### S.4 Explicit non-goals

- Redesigning Story/Hero aggregates
- Personalization engine work
- Feed/social
- Production AI vendor lock-in
- Weakening private/discoverability rules to show drafts in Discover*
- Collapsing consent gates
- Making Today’s Experience the capture entry point

---

## T. Implementation Plan (engineer checklist)

### T.1 Kickoff

1. Accept §S.3 ADRs
2. Confirm Slice A → B → C order
3. Run package evaluation spike for audio record/playback/permissions (Spike output: chosen packages + license/constraints note)
4. Confirm First Real Hero Story success definition with product owner

### T.2 Slice A work items

- [ ] `LocalFileStoryMediaStorageAdapter`
- [ ] Durable local `HeroRepository` / `StoryRepository` adapters
- [ ] Durable `CaptureCompletionStore`
- [ ] Provider wiring; composition root defaults for MVP
- [ ] Analyzer + focused persistence tests

### T.3 Slice B work items

- [ ] `DeviceRecordingPort` + audio adapter
- [ ] Recording session application service + DTOs
- [ ] Prepare / Consent / Record / Review screens
- [ ] Tell Your Story entry + Hero bootstrap
- [ ] Platform permission strings/manifests
- [ ] Fake-recorder UI/application tests
- [ ] Manual device validation checklist (iPhone)

### T.4 Slice C work items

- [ ] Post-capture submit UX
- [ ] Owner drafts list use case/UI
- [ ] Optional async transcription hook behind consent + port

### T.5 Validation gates

| Gate | Command / proof |
|------|-----------------|
| Analyze | `flutter analyze` clean |
| Focused tests | HS.9 unit/application/UI tests green |
| Regression | Full `flutter test` green |
| First story | Manual iPhone walkthrough recorded in implementation report |

---

## U. Open Decisions (stop conditions)

Implementation may proceed on recommended defaults below unless product overrides:

| Question | Recommended default |
|----------|---------------------|
| Audio vs video for MVP | **Audio** |
| Local DB technology | Prefer simplest durable approach consistent with repo (evaluate at Slice A; avoid premature multi-engine abstraction) |
| Must first story support remote upload? | **No** |
| Must first story auto-transcribe? | **No** |
| Where does Tell Your Story live? | **Heroes tab entry** |
| Private draft listing API | New owner-scoped application query; do not use Discover* |

If any of these defaults are rejected in a way that requires new aggregates, cross-context coupling, or consent model changes: **stop and re-decide before coding**.

---

## V. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Multi-minute `Uint8List` RAM pressure | Capture OOM | `storeFromFile` / streaming in media adapter |
| In-memory repos make “success” illusory | Lost stories | Slice A durable persistence before device demo claims |
| Package churn / OS audio session quirks | Flaky recording | Fake port for CI; device checklist for release |
| Accidental Discover* leakage of private drafts | Privacy bug | Keep drafts private; owner query separate |
| Expanding legacy StoryCapturePort | Architecture confusion | Explicit ADR; prefer DeviceRecordingPort |
| Scope creep into AI/publish | Delays first story | Slice boundaries in §S |

---

## W. Definition of Done (HS.9)

HS.9 is complete when:

1. Architecture boundaries preserved (no domain device coupling)
2. HS.3 capture/consent/provenance reused correctly
3. A Hero can complete Tell Your Story → Record → Review → Accept on a real iOS device
4. Captured Story + media survive app relaunch via local durable adapters
5. Consent gates remain independent and enforced
6. Transcription/AI are not required for capture success
7. H.2 evidence is not auto-created
8. Tests + analyzer gates pass
9. Implementation report + ADRs recorded
10. Deferred remote/AI/video/Identity work explicitly listed

---

## X. Architectural Decisions To Accept At Kickoff

See provisional HS-ADR-060…066 in §S.3. Summarized locked intent:

1. **HS.9 builds on HS.3; does not replace it.**
2. **Device recording is a port/adapter concern; CaptureSession remains non-domain.**
3. **Media remains behind StoryMediaStoragePort; local durable MVP; remote replaceable later.**
4. **Audio-first; video optional.**
5. **AI/transcription asynchronous and optional.**
6. **Local Hero bootstrap until Identity exists.**
7. **No BehavioralEvidence from recording/capture.**

---

## Y. Final Recommendation

**Proceed to implement HS.9 in slices A → B (required), then C (optional), deferring D.**

The repository already contains the canonical Story capture model.  
HS.9’s job is to make that model reachable by a real Hero with a real microphone, durable storage, honest consent, and recovery semantics — as an independent vertical slice that does not wait for the rest of the platform to be finished.
