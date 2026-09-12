# HS.3 — Story Capture Foundation Plan

**Status:** PLANNING COMPLETE — READY FOR IMPLEMENTATION  
**Date:** 2026-09-12  
**Phase:** HS.3 — Story Capture Foundation  
**Authority hierarchy used:** Current ADRs → current `lib/features/hero_story/` implementation → HS.1/HS.2 phase docs → architecture maps → AGENTS.md / legacy guidance  
**Constraint:** Planning only. No HS.3 production code, tests, adapters, AI, or cloud providers are introduced by this document.

---

## A. Executive Summary

HS.3 establishes the foundation for capturing a Hero’s lived experience and attaching the resulting raw material to the existing Hero & Story domain **without** introducing AI transcription, classification, semantic search, personalization, feed ranking, translation, narration, or production cloud media.

### Recommended model (one sentence)

**Capture is an application/infrastructure workflow that stores opaque media bytes behind a replaceable storage port and attaches an original audio `StoryRepresentation` (plus provenance) to a draft `Story`; it does not introduce `CaptureSession` or `StorySource` as domain aggregates.**

### Critical boundary decisions (summary)

| Concept | HS.3 recommendation |
|---------|---------------------|
| `CaptureSession` | **Not a domain aggregate.** Ephemeral application/presentation workflow state (+ local temp media in infrastructure). |
| `StorySource` | **Not a separate entity/aggregate.** “Source” is expressed as original `StoryRepresentation` + `StoryProvenance`. |
| `Story` | Remains the **canonical narrative** aggregate (HS-ADR-002). Capture never redefines Story as an audio file. |
| `StoryRepresentation` | **Reuse existing entity.** Capture creates `format=audio`, `origin=original`, `transformationType=recording`. |
| `StoryMedia` / blobs | **Not domain state.** Bytes live behind a new `StoryMediaStoragePort`; domain keeps `MediaReference`. |
| Consent | **Minimal `StoryConsent` VO** on Story (recorded / processing / publication / AI). Not a privacy platform. |
| Visibility | **Reuse existing `StoryVisibility`.** Default capture stories to `private` or `draft`. Do not conflate with lifecycle. |
| Transcription | **Deferred to HS.4.** Keep `requestTranscription` unsupported; do not attach AI transcripts in HS.3. |
| Existing `StoryCapturePort` | **Redesign/narrow via new ADR.** Separate media storage from capture orchestration; do not treat the HS.1 stub as the final capture API. |

### Final recommendation

**HS.3 READY FOR IMPLEMENTATION**, contingent on accepting the architectural decisions in §X (especially provisional narrative for capture-first drafts, media storage port, consent VO, and CaptureSession non-aggregate status) at implementation kickoff.

Implementation starting point: domain additions for provisional narrative + `StoryConsent`, then `StoryMediaStoragePort` + in-memory adapter, then capture orchestration use cases, then focused tests.

---

## B. Source-of-Truth Review

### B.1 Documents reviewed

| Artifact | Role for HS.3 |
|----------|---------------|
| `AGENTS.md` | Implementation contract; Hero/Story terminology; capture deferred in HS.1 scope list |
| `docs/architecture/architecture-decisions.md` | Binding ADRs (AD-*, HS-ADR-001…016) |
| `docs/architecture/Everyone’s Heroes - Hero and Story Platform Foundation.md` | HS.1 foundation; §20 capture pipeline; §48–49 privacy/consent; §72 HS.3 roadmap |
| `docs/architecture/HS.2-Story-Catalog-Foundation-Plan.md` | Explicit deferral of capture/transcription/media storage |
| `docs/architecture/HS.2-Final-Architectural-Cleanup-Report.md` | Confirms catalog-only HS.2; AI → HS.4 |
| `docs/architecture/HS.2-Implementation-Report.md` | HS.2 complete; deferred capture/media |
| `docs/architecture/bounded-contexts.md` | Partially updated for Hero & Story |
| `docs/architecture/aggregate-map.md` | **Stale** (no Hero/Story) |
| `docs/architecture/event-flow.md` | **Stale** (no Hero/Story events) |
| `docs/architecture/repository-map.md` | **Stale** (no Story/Hero repos) |
| `docs/architecture/use-case-map.md` | **Stale** (no hero_story use cases) |
| `docs/architecture/domain-glossary.md` | **Missing** Hero/Story/Capture terms |
| `docs/architecture/architecture-drift.md` | Pre-HS.1 Life Journey items; does not track Hero/Story doc drift |
| `docs/architecture/technical-debt.md` | Clock/`DateTime.now()` class of debt relevant to Story |
| `docs/architecture/testing-strategy.md` | Domain-first pyramid; deterministic fakes |
| `docs/architecture/codebase-analysis.md` | **Pre-HS.1**; do not use as inventory |
| Mission Statement file | **Not present**; use foundation Product North Star / Anchor Statement |

### B.2 Implementation inspected

Primary:

- `lib/features/hero_story/**` (domain, application, infrastructure)
- `test/features/hero_story/**`
- Shared kernel: `AggregateRoot`, `Entity`, `ValueObject`, `LanguageCode`, IDs, eventing, `Result`

Key existing capture-related code:

- `domain/services/story_capture_port.dart` — HS.1 stub contract (`captureAudio`, `requestTranscription`)
- `infrastructure/capture/unsupported_story_capture_adapter.dart` — accepts audio, rejects transcription
- `MediaReference`, `StoryProvenance`, `ProvenanceStep`, `StoryRepresentation`
- `AddStoryRepresentationUseCase`, `CreateStoryUseCase`, `SubmitStoryUseCase`
- Lifecycle + visibility already implemented on `Story`

### B.3 Source-of-truth hierarchy applied

1. **ADRs** (especially HS-ADR-002, 004, 005, 006, 012, 015, 016) — binding
2. **Current code** under `lib/features/hero_story/` — authoritative for naming and aggregate shape
3. **HS.2 plan + reports** — authoritative for what was deferred to HS.3
4. **HS.1 foundation** — roadmap and conceptual capture pipeline; some proposals superseded by code
5. **Stale maps/glossary** — informational only; discrepancies reported, not “fixed” by guessing

### B.4 Documentation vs implementation discrepancies (relevant to HS.3)

| Discrepancy | Classification | HS.3 action |
|-------------|----------------|-------------|
| Foundation listed “don’t automatically make Representation a child entity”; code has `StoryRepresentation` entity on Story | Intentional HS.1 evolution (A) | Follow code + HS-ADR-002 |
| Foundation candidate events `StoryRepresentationCreated` / `StoryMediaAdded`; code has `StoryRepresentationAdded` | Intentional (A) | Prefer existing event |
| Foundation suggested Hero published-story ID lists; HS.2 removed | Intentional (A) | Do not reintroduce |
| Aggregate/event/repo/use-case maps omit Hero & Story | Documentation drift (C) | Report; update only if needed for HS.3 clarity (this plan is the capture SoT until maps reconciled) |
| `domain-glossary.md` lacks Story/Capture terms | Documentation drift (C) | Deferred unless HS.3 docs explicitly update glossary |
| AGENTS.md still frames HS.1 as “next phase” while HS.1+HS.2 are implemented | Documentation drift (C) | Treat HS.3 as next Hero & Story phase |
| Foundation HS.3 includes “transcript representation”; task + HS.4 defer AI transcription | Ambiguous product boundary (D → resolved in this plan) | HS.3 may record *language of capture* and original audio; AI transcript deferred to HS.4. Optional *manual* transcript text only if explicitly provided by Hero — not AI |
| Consent documented but absent in code | Intentional deferral until now | Introduce **minimal** consent in HS.3 |
| `StoryCapturePort` exists but is unused by use cases / providers | Intentional incomplete stub | Redesign in HS.3 |

---

## C. Current Architecture Findings

### C.1 What already exists and should be reused

```text
Hero (aggregate)
Story (aggregate)
  ├── StoryTitle / StoryNarrative (required today; non-empty)
  ├── originalLanguage (LanguageCode)
  ├── lifecycleStatus (draft→…→published…)
  ├── visibility (independent)
  ├── classification / suitability / spirituality (HS.2; not capture)
  ├── StoryProvenance { originalSourceDescription?, ProvenanceStep[] }
  └── StoryRepresentation[] {
        language, format, origin,
        MediaReference? | textContent?,
        sourceRepresentationId?, duration?,
        isAiGenerated, isApproved
      }

Ports:
  StorySearchPort / HeroSearchPort (HS.2)
  StoryCapturePort (HS.1 stub — needs redesign)

Repos:
  CreateStory, SubmitStory, AddStoryRepresentation, Approve, Publish, Archive,
  Classify, UpdateSuitability, UpdateSpirituality, Search*
```

### C.2 What does **not** exist (HS.3 surface)

- CaptureSession type / repository
- StorySource type / repository
- Consent model
- Media storage port / adapters
- Capture orchestration use cases
- Wiring of `StoryCapturePort` into providers/use cases
- Presentation / recording UI
- Deletion/revocation of raw media workflows
- Authorization beyond Hero active checks

### C.3 Architectural tension discovered (must resolve in HS.3)

**Capture-first vs narrative-required:**

- `Story.create` requires non-empty `StoryTitle` and `StoryNarrative`.
- Real capture often starts with recording **before** the Hero has authored canonical narrative text.
- HS-ADR-002 forbids treating audio as the Story.

This is the primary design hinge for HS.3. Resolution in §X Decision D-01.

### C.4 Package conventions to follow

```text
lib/features/hero_story/
  domain/{aggregates,entities,enums,events,repositories,services,value_objects}
  application/{dto/requests,use_cases,providers}
  infrastructure/{capture,repositories,search}  (+ media/ for HS.3)
test/features/hero_story/{domain,application,infrastructure}
```

No `presentation/` folder exists yet for Hero & Story. HS.3 may add thin presentation contracts later, but **UI is not required for HS.3 Definition of Done** unless a later slice explicitly authorizes it.

---

## D. HS.3 Architectural Invariants

1. **Story is the canonical narrative** (HS-ADR-002). Audio/transcript/media never replace Story.
2. **Domain independence:** no Flutter, Riverpod, SDKs, cloud storage, mic frameworks, or AI SDKs in domain.
3. **Hexagonal ports:** media bytes and recording devices stay behind replaceable ports/adapters.
4. **Provenance preserved** when original recording is attached (HS-ADR-005).
5. **Multilingual foundation:** capture records language; original representation language must match `Story.originalLanguage` (HS-ADR-004).
6. **Visibility ≠ lifecycle ≠ consent ≠ processing.**
7. **AI does not own the story** (HS-ADR-006). HS.3 does not implement AI transcription/understanding.
8. **Catalog ≠ Discovery ≠ Personalization** (HS-ADR-010). Capture must not become recommendation.
9. **Story interaction / capture ≠ Behavioral Evidence** (HS-ADR-011).
10. **No production cloud media provider** in HS.3; deterministic in-memory/local fake only.
11. **No new bounded context** for capture; capture lives in Hero & Story application + infrastructure.
12. **Prefer existing aggregates/events/use cases** over inventing parallel nouns.

---

## E. Domain Model

### E.1 Conceptual flow (HS.3)

```text
Hero’s Lived Experience          (real world — not a domain entity)
        ↓
Capture workflow                 (application + presentation + device infra)
        ↓
Raw media bytes                  (infrastructure storage)
        ↓
MediaReference                   (domain VO — opaque pointer)
        ↓
Original audio StoryRepresentation  (domain entity inside Story)
        ↓
StoryProvenance step (recording)    (domain VO)
        ↓
Draft Story                      (canonical aggregate; provisional narrative allowed)
        ↓
(optional) Submit → processing   (existing lifecycle; gates on consent)
```

Future (out of scope):

```text
HS.4: transcription / understanding / AI classification proposals
HS.5: authoring / script / translation / narration
Later: publish → Discovery inspiration source
```

### E.2 Domain concepts HS.3 adds or changes

| Concept | Kind | Action |
|---------|------|--------|
| `StoryConsent` | Value object on Story | **Add** (minimal) |
| Provisional / capture draft narrative rules | Aggregate invariant | **Add** (see D-01) |
| `StoryMediaStoragePort` | Port (domain/services or application port) | **Add** |
| Capture orchestration use cases | Application | **Add** |
| In-memory media storage adapter | Infrastructure | **Add** |
| `CaptureSession` | — | **Do not add as domain type** |
| `StorySource` | — | **Do not add as entity/aggregate** |
| `StoryMedia` entity | — | **Do not add** |
| AI transcription | — | **Do not add** |

### E.3 Layer assignment

| Concern | Layer |
|---------|-------|
| Mic permission, pause/resume UI, recorder SDK | Presentation + infrastructure device adapter |
| Ephemeral capture session state (recording/paused) | Application/presentation workflow (not aggregate) |
| Store/delete/retrieve bytes | Infrastructure via `StoryMediaStoragePort` |
| MediaReference validity | Domain VO (existing) |
| Attach original audio + provenance | Domain (`Story.addRepresentation`) via use case |
| Consent flags / gates | Domain VO + aggregate invariants |
| Submit for processing | Existing `Story.submit` + consent gate |
| Event publish | Application use cases (existing pattern) |
| Classification / suitability | Existing HS.2; not required by capture |
| Transcription AI | Deferred HS.4 |

---

## F. Aggregate Boundary Analysis

### F.1 Candidates vs aggregate rules

Rule (HS.2 plan §4.1, AGENTS.md): *If a concept does not participate in Story invariants, it is not Story aggregate state.*

| Candidate | Own invariants? | Persistence needed? | Concurrent consistency with Story? | Recommendation |
|-----------|-----------------|---------------------|------------------------------------|----------------|
| Story | Yes | Yes | N/A (root) | Keep as root |
| StoryRepresentation | Yes (via Story) | With Story | Yes | Keep as entity inside Story |
| MediaReference | Validation only | Pointer only | Via representation | Keep VO |
| StoryProvenance | Lineage integrity | With Story | Yes | Keep VO on Story |
| CaptureSession | Device/workflow only | Temp at most | No | **Not aggregate** |
| StorySource | Overlaps representation+provenance | Would duplicate | No | **Not introduced** |
| StoryMedia (blob) | Storage | Infra | No | **Infra only** |
| StoryConsent | Publication/processing gates | With Story | Yes | **VO on Story** |

### F.2 Ownership diagram (HS.3)

```text
Hero ──<id>── Story
                ├── consent (StoryConsent)          [NEW]
                ├── provenance
                └── representations[]
                      └── mediaReference → [StoryMediaStoragePort] → bytes

Capture workflow (application)
  ├── sessionId (ephemeral)
  ├── heroId / storyId?
  ├── local temp handle (infra)
  └── orchestrates storage + Story mutation
```

### F.3 What Story must **not** own

- Microphone state
- Upload progress percentages
- Provider bucket names / signed URLs as first-class domain types
- Raw `Uint8List` / file paths as durable domain fields
- Search indexes, personalization scores, behavioral evidence

---

## G. CaptureSession Analysis

### G.1 Possible interpretations evaluated

| Interpretation | Fit? | Why |
|----------------|------|-----|
| Domain aggregate | **No** | No durable business invariants beyond Story; would create second consistency boundary for temp process state |
| Domain entity inside Story | **No** | Recording pause/resume is not Story narrative state; pollutes aggregate |
| Value object | **No** | Sessions are identity-bearing process instances, but still not domain |
| Application workflow concept | **Yes** | Orchestrates start → record → complete/cancel; coordinates ports |
| Infrastructure concept | **Partial** | Local temp files, recorder handles are infra |
| Separate repository | **No** | Avoid CaptureSessionRepository in HS.3 |

### G.2 Recommended definition

**CaptureSession = ephemeral application workflow handle**, optionally represented as an immutable application DTO:

```text
CaptureSessionDto {
  sessionId        // client/application generated idempotency key
  heroId
  storyId?         // null until Story created/bound
  language
  status           // preparing | recording | paused | completing | completed | cancelled | failed
  startedAt
  mediaStorageKey? // after store
}
```

- **Lifecycle:** short-lived; ends at complete/cancel/fail/abandon.
- **Persistence:** not required for domain correctness. Optional local recovery of unfinished uploads is an **infrastructure/application concern** (may use local cache), not a domain repository.
- **Concurrency:** one active recording session per device/user UX; not an aggregate concurrency problem.
- **Retry:** retries apply to **storage upload** and **Story persistence**, keyed by `sessionId` / media content hash / representation id — not by replaying a domain CaptureSession aggregate.
- **Relationship to Hero:** session references `heroId` for authorization.
- **Relationship to Story:** session may create or bind a draft Story at completion.
- **Relationship to media:** session produces bytes → storage port → `MediaReference`.

### G.3 Why CaptureSession must not be a domain concept

1. It does not protect Story narrative invariants.
2. It duplicates lifecycle concepts already on Story (`draft` / `processing`).
3. It invites event proliferation (`CaptureStarted` for UI noise).
4. Device failure modes (mic denied) are not domain facts.
5. HS.2 explicitly warned against stuffing non-invariant concepts into Story; a new aggregate for the same reason is still wrong.

### G.4 Cancellation / abandonment

| Case | Handling |
|------|----------|
| Cancel before store | Discard local temp; no Story mutation |
| Cancel after store, before attach | Delete stored object via storage port (best effort); no representation |
| Abandon after attach | Draft Story remains with original audio; Hero may delete later (future) or archive/remove |
| App kill mid-record | Local recovery optional; no domain event required |

---

## H. StorySource Analysis

### H.1 What “source” means in EH

Distinct meanings must not be collapsed:

| Meaning | HS.3 modeling |
|---------|----------------|
| Hero’s lived experience | Real-world; not an entity |
| Original recording bytes | Infrastructure object behind `MediaReference` |
| Original captured artifact in domain | **Original `StoryRepresentation`** (`origin=original`, `format=audio`) |
| Provenance / lineage | `StoryProvenance` + `ProvenanceStep(transformationType=recording)` |
| Human description of origin | `originalSourceDescription` (existing) |
| Application submission payload | Request DTO fields |

### H.2 StorySource vs peers

| | CaptureSession | StorySource (rejected) | StoryRepresentation | MediaReference / media |
|--|----------------|------------------------|---------------------|------------------------|
| Layer | Application | — | Domain entity | VO + infra |
| Identity | sessionId | would duplicate representation id | `StoryRepresentationId` | opaque uri |
| Durable? | No | would be yes | Yes (on Story) | Bytes in storage |
| Role | Process | — | Language/format presentation | Pointer / bytes |

### H.3 Recommendation

**Do not introduce `StorySource` as a type in HS.3.**

If future phases need a richer “source package” (multiple takes, multi-track, external import packages), revisit then — likely as application packaging or a dedicated VO group, not a second aggregate competing with Story.

“Source preservation” in HS.3 means:

1. Bytes retained in media storage until explicitly deleted.
2. Original representation retained on Story.
3. Provenance step records `recording`.
4. Consent distinguishes raw retention vs processing/publication/AI.

---

## I. StoryRepresentation Analysis

### I.1 Existing contract (binding)

From code:

- Requires `mediaReference` **or** non-empty `textContent`
- `translated` requires `sourceRepresentationId`
- Story requires original representation language == `originalLanguage`
- Derived/translated must reference an existing source representation on the same Story
- AI representations non-authoritative until `approveRepresentation`

### I.2 What HS.3 creates

On successful capture completion:

```text
StoryRepresentation(
  format: StoryRepresentationFormat.audio,
  origin: RepresentationOrigin.original,
  language: <capture language == story.originalLanguage>,
  mediaReference: <from storage port>,
  duration: <optional, from recorder metadata>,
  isAiGenerated: false,
  isApproved: false, // N/A for non-AI; isAuthoritative == true
)
```

Attached via `Story.addRepresentation(..., transformationType: StoryTransformationType.recording)`.

### I.3 What HS.3 does **not** create automatically

| Representation | HS.3 |
|----------------|------|
| Transcript (AI) | **No** (HS.4) |
| Edited transcript | **No** (HS.5) |
| Written narrative as representation | **No** (canonical narrative remains `Story.narrative`) |
| Script / translation / narrated audio / video / short/long form | **No** |

### I.4 Is captured audio a representation or a source?

**Both conceptually, one technically:**

- Conceptually it is the **original captured source material**.
- Technically it is modeled as an **original `StoryRepresentation`**, which is the established HS.1/HS.2 pattern and preserves future derived reps (transcript ← audio).

Do **not** invent a parallel “source representation” type.

### I.5 Duration / language / origin placement

| Field | Placement |
|-------|-----------|
| Capture language | Session DTO → becomes `Story.originalLanguage` (if new Story) and representation.language |
| Duration | Representation only (HS-ADR-016) |
| Origin | `RepresentationOrigin.original` |
| Media pointer | `MediaReference` on representation |
| Transformation | Provenance step `recording` |

### I.6 Future-proofing

Because original audio is a representation with id, future transcript can set:

- `origin: derived` (or keep domain rule: transcript as `derived` with `sourceRepresentationId` = audio id)
- Note: current entity requires `sourceRepresentationId` only for `translated`; **derived** is enforced at Story aggregate level for translated **or** derived. Good — HS.4 can add transcript as `derived` from audio id.

---

## J. StoryMedia / Media Reference Model

### J.1 Minimum model

**Keep:**

- `MediaReference` (existing opaque URI VO)

**Add (storage port result metadata — application/infra, not bloating Story):**

```text
StoredMediaRef {
  MediaReference reference
  contentType?     // e.g. audio/m4a — optional string, not provider-specific
  byteLength?
  checksum?        // for idempotent retry
  duration?        // may also flow into representation
}
```

**Do not add:**

- `StoryMedia` entity
- `MediaId` strongly-typed id (unless later persistence requires it; URI can encode id)
- `MediaMetadata` aggregate
- Domain knowledge of S3/GCS/Firebase/path schemes beyond opaque strings

### J.2 Separation

```text
Domain:     MediaReference("media://...")
Application: orchestrates store → reference → addRepresentation
Infrastructure: maps reference ↔ bytes (in-memory map for HS.3)
```

### J.3 Deletion semantics (foundation only)

- Deleting a `MediaReference` object must be explicit via storage port.
- Removing a representation from Story (future) should not silently orphan or cascade without policy.
- HS.3: support `delete` on storage port; do **not** build full GC. Document orphan risk as deferred debt.

---

## K. Provenance Model

### K.1 Minimum viable provenance for HS.3

Reuse existing:

1. `StoryProvenance.originalSourceDescription` — set at Story create (e.g. `"Hero original audio capture"`).
2. On attach audio: `ProvenanceStep` with:
   - `transformationType: recording`
   - `producedRepresentationId: <audio rep id>`
   - `sourceRepresentationId: null`
   - `isAiAssisted: false`
   - `occurredAt: injectable clock`
   - optional `note` (e.g. sessionId for correlation)

### K.2 Questions HS.3 must be able to answer

| Question | Answer mechanism |
|----------|------------------|
| Where did this Story originate? | `originalSourceDescription` + first recording step |
| Derived from Hero recording? | Presence of original audio rep + recording step |
| Which source produced a representation? | `sourceRepresentationId` + provenance steps (future derivatives) |
| Which media belongs to which representation? | `representation.mediaReference` |
| Original vs derivative media? | `RepresentationOrigin` + transformation type |
| Trace derivatives to source? | Chain of provenance steps / sourceRepresentationId |

### K.3 Explicitly deferred

- Full provenance graph DB
- Cross-story provenance
- Cryptographic attestation
- Media-level provenance separate from representation provenance
- Automatic reconstruction of deleted sources

---

## L. Consent / Authorization / Visibility

### L.1 Separate axes (do not merge)

```text
Capture workflow status   → ephemeral session (application)
Story lifecycle           → draft/processing/review/... (existing)
Story visibility          → private/draft/unlisted/community/public (existing)
Consent                   → recorded / processing / publication / AI (NEW minimal VO)
Authorization/ownership   → Hero ownership via Story.heroId (+ future Identity auth)
```

### L.2 Minimal `StoryConsent` (recommended)

```text
StoryConsent {
  recordedAt: DateTime?                 // set when original capture attached
  approvedForProcessingAt: DateTime?    // required before submit() in HS.3
  approvedForPublicationAt: DateTime?   // required before publish() — may already be implied by publish UX; still record
  approvedForAiTransformationAt: DateTime?  // default null; HS.4+ gate
}
```

Defaults: all null/false.

**HS.3 gates:**

| Action | Required consent |
|--------|------------------|
| Attach original recording | Sets `recordedAt` |
| `submit()` → processing | Requires `approvedForProcessingAt` |
| `publish()` | Requires `approvedForPublicationAt` (in addition to visibility rules) |
| Any AI transformation port call | Requires `approvedForAiTransformationAt` (enforce when HS.4 arrives; field exists now) |

Revocation (minimal):

- Clearing processing/publication/AI timestamps is allowed while not published (exact rules in tests).
- Full legal retention/deletion platform deferred.

### L.3 Authorization (HS.3 minimum)

- Story capture only for **active** Hero (`hero.isActive`), matching `CreateStoryUseCase`.
- `Story.heroId` is ownership anchor.
- Production authentication/identity integration **out of scope**; use cases accept `heroId` as today.
- Document dependency: future Identity context must enforce caller == hero owner.

### L.4 Visibility

- **No enum changes** required.
- Capture-created stories default to `StoryVisibility.private` (recommended) or `draft`.
- Raw media access is not granted by Story visibility alone; storage port access control is future work. For HS.3 in-memory adapter, treat all access as trusted test/dev.
- Do not auto-promote visibility on capture complete.

### L.5 Why not over-model consent

Full privacy platforms include policies, regional retention, guardian consent, audit ledgers, etc. HS.3 only needs **safe defaults and explicit gates** so HS.4 AI and publication cannot silently proceed.

**New ADR warranted** for `StoryConsent` (see §X D-08).

---

## M. Capture Lifecycle

### M.1 Do not invent a second domain state machine

Story already has lifecycle. Capture workflow is separate.

### M.2 Application capture states (minimal)

```text
idle
  → starting
  → recording ⇄ paused
  → stopping
  → storing
  → attaching
  → completed
  → (optional) submitted   // Story.lifecycle → processing

cancel/fail branches from recording/storing/attaching → cancelled | failed
```

These states live in application/presentation — **not** on `Story`.

### M.3 Mapping to Story

| Capture outcome | Story effect |
|-----------------|--------------|
| Completed attach | Draft Story + original audio representation + consent.recorded |
| Submitted | Existing `submit()` if processing consent granted |
| Cancelled pre-attach | No Story change (or no Story created) |
| Failed store | No representation |
| Failed persist after store | Compensating delete of media (best effort) + Failure result |

### M.4 Edge cases

| Case | Layer | Behavior |
|------|-------|----------|
| Empty recording (0 duration / 0 bytes) | Application | Reject before store; no domain mutation |
| Partial recording (user stop early) | Application | Allowed if non-empty; duration recorded |
| Interrupted (OS pause) | Presentation/infra | Resume or fail session; no domain event |
| Duplicate complete with same sessionId | Application | Idempotent: return existing Story/representation |
| Duplicate submit | Domain/application | `submit()` transition rules; second call fails or no-ops per existing transitions |
| Upload failure | Infra → application | Retry store; do not attach |
| Persistence failure after attach attempted | Application | Return Failure; avoid double representation id |

---

## N. Application Use Cases

### N.1 Smallest coherent set

| Use case | Needed? |
|----------|---------|
| `StartStoryCaptureUseCase` | **Optional/thin** — may only validate hero + create session DTO; can be presentation-local |
| `CompleteStoryCaptureUseCase` | **Yes** — store media + ensure draft Story + add original audio + consent.recorded + events |
| `CancelStoryCaptureUseCase` | **Yes (light)** — discard session; best-effort delete temp/stored object if any |
| `GrantStoryProcessingConsentUseCase` | **Yes** — sets processing consent |
| `GrantStoryPublicationConsentUseCase` | **Yes** — sets publication consent |
| `GrantStoryAiTransformationConsentUseCase` | **Yes (minimal)** — sets AI consent for future; no AI call |
| `SubmitStoryUseCase` | **Reuse/extend** — add processing-consent gate |
| `PublishStoryUseCase` | **Extend** — add publication-consent gate |
| `AddStoryRepresentationUseCase` | **Reuse** for non-capture adds; capture should prefer Complete use case to enforce recording provenance |
| Dedicated `SubmitCapturedStoryUseCase` | **No** — reuse `SubmitStoryUseCase` |

Recommended **required** HS.3 use cases:  
`CompleteStoryCaptureUseCase`, `CancelStoryCaptureUseCase`, consent grant use cases (can be one `UpdateStoryConsentUseCase` with explicit fields), and gates on existing submit/publish.

### N.2 `CompleteStoryCaptureUseCase` (primary)

**Purpose:** Persist captured audio and attach it as the Story’s original recording representation with provenance and recorded consent.

**Request (DTO):**

```text
CompleteStoryCaptureRequest {
  sessionId: String              // idempotency
  heroId: HeroId
  storyId: StoryId?              // null → create draft Story
  language: LanguageCode
  title: StoryTitle?             // required if creating; else keep existing
  provisionalNarrative: StoryNarrative? // see D-01
  originalSourceDescription: String?
  mediaBytes / mediaHandle       // opaque to domain; application passes to storage port
  contentType: String?
  duration: Duration?
  checksum: String?
}
```

**Response:**

```text
CompleteStoryCaptureResponse {
  story: Story
  representationId: StoryRepresentationId
  mediaReference: MediaReference
  createdStory: bool
}
```

**Dependencies:**

- `HeroRepository`
- `StoryRepository`
- `StoryMediaStoragePort`
- `EventBus`
- Clock abstraction (recommended; see debt)

**Domain behavior:**

1. Validate hero active.
2. Idempotency: if sessionId already completed → return prior result (application store or representation note match).
3. `storage.store(...)` → `MediaReference`.
4. Load or `Story.create` draft (provisional rules).
5. Build original audio representation; `addRepresentation(..., recording)`.
6. Mark consent recorded.
7. Save Story; publish pulled events.

**Events emitted:**

- `StoryCreated` (if new)
- `StoryRepresentationAdded`
- Optionally **no** new `StoryCaptureCompleted` if representation event + transformation type suffice (recommended: **defer** dedicated capture event unless a consumer exists)

**Failure modes:** hero missing/archived; empty media; storage failure; duplicate representation id; language mismatch; persistence failure.

**Idempotency:** keyed by `sessionId` (application) and/or checksum+storyId.

**Retry:** safe to retry store if storage is content-addressed/idempotent; safe to retry complete if session completion recorded.

### N.3 `CancelStoryCaptureUseCase`

**Purpose:** Abandon in-progress capture without attaching representation.

**Request:** `{ sessionId, heroId, mediaReference? }`  
**Response:** `{ cancelled: true }`  
**Deps:** `StoryMediaStoragePort` (optional delete)  
**Events:** none  
**Idempotency:** cancel twice = success

### N.4 Consent use case(s)

Prefer one:

`UpdateStoryConsentUseCase` with explicit nullable grant timestamps / booleans for processing, publication, AI — never “set all true” helper that hides intent.

Emit **no** new events unless a concrete consumer needs them (prefer none in HS.3).

### N.5 Changes to existing use cases

| Use case | Change |
|----------|--------|
| `SubmitStoryUseCase` | Fail if processing consent missing |
| `PublishStoryUseCase` | Fail if publication consent missing |
| `CreateStoryUseCase` | Unchanged for text-first create; capture path uses Complete |
| `AddStoryRepresentationUseCase` | Unchanged; document that capture should use Complete for recording semantics |

---

## O. Domain Events

### O.1 Existing events to reuse

| Event | HS.3 role |
|-------|-----------|
| `StoryCreated` | New draft from capture |
| `StoryRepresentationAdded` | Original audio attached (**primary capture fact**) |
| `StorySubmitted` | Hero submits for processing |
| `StoryApproved` / `StoryPublished` / … | Unchanged later stages |

### O.2 Candidate new events — decisions

| Candidate | Required now? | Recommendation |
|-----------|---------------|----------------|
| `StoryCaptureStarted` | No | **Defer** — UI/process noise |
| `StoryCaptureCompleted` | No | **Defer** — redundant with `StoryRepresentationAdded` + recording provenance |
| `StorySourceStored` | No | **Defer** — storage is infra; representation add is domain fact |
| `StoryConsentGranted` | Maybe | **Defer** unless cross-context consumer appears |
| `StoryProcessingStarted` | No | Already implied by `StorySubmitted` → processing |
| `StoryTranscribed` | No | **HS.4** |
| `StoryMediaAdded` | No | Prefer existing representation event |

### O.3 Event discipline

Only add an event when:

1. Meaningful fact occurred  
2. Another component may react  
3. Belongs to context  
4. Not an implementation detail  

**HS.3 default:** emit existing Story events only.

### O.4 Cross-context

No Discovery / Life Journey reactors in HS.3.  
Future: `StoryPublished` → Discovery inspiration (document only).

---

## P. Repository Boundaries

| Repository | HS.3 change |
|------------|-------------|
| `StoryRepository` | **No interface change required** (save/find sufficient). Persist new consent field with Story. |
| `HeroRepository` | **No change** |
| `CaptureSessionRepository` | **Do not create** |
| `StorySourceRepository` | **Do not create** |
| Media “repository” | **Do not create as domain repository**; use `StoryMediaStoragePort` |

Optional application-level `CaptureIdempotencyStore` (in-memory) for sessionId → result mapping in tests/adapters — not a domain repo.

---

## Q. Media / Storage Port

### Q.1 Name and location

**Name:** `StoryMediaStoragePort`  
**Location:** `lib/features/hero_story/domain/services/story_media_storage_port.dart`  
(Consistent with existing `StorySearchPort` / `StoryCapturePort` placement.)

### Q.2 Contract (minimum)

```text
abstract interface class StoryMediaStoragePort {
  Future<StoredMediaRef> store({
    required MediaStoreRequest request, // bytes/stream handle, contentType, checksum?, suggestedKey?
  });

  Future<bool> exists(MediaReference reference);

  Future<void> delete(MediaReference reference);

  // retrieve bytes: optional for HS.3 tests; include for adapter completeness
  Future<StoredMediaBytes?> retrieve(MediaReference reference);
}
```

**Must not** expose: S3 APIs, GCS, Azure, Firebase, filesystem paths as required domain types, vendor SDKs.

### Q.3 HS.3 adapter

`InMemoryStoryMediaStorageAdapter` under `infrastructure/media/`:

- Deterministic map `uri → bytes`
- URI scheme e.g. `memory://{uuid}` or content-hash based for idempotency
- No network

### Q.4 Relationship to `StoryCapturePort`

HS.1 `StoryCapturePort` currently:

- Assumes `storyId` + `MediaReference` already exist
- Bundles transcription request (AI)

**Recommendation (D-06):**

1. Introduce `StoryMediaStoragePort` for bytes.
2. Capture orchestration moves to use cases.
3. Narrow or deprecate `StoryCapturePort.captureAudio` as a processing hook:
   - **Preferred:** mark `StoryCapturePort` as legacy stub; HS.3 use cases do not depend on it; keep `UnsupportedStoryCaptureAdapter.requestTranscription` for HS.4 compatibility **or** move transcription to future `StoryTranscriptionPort`.
4. Update HS-ADR-012 via new ADR (do not invent number here).

Do **not** implement production provider.

---

## R. Cross-Context Integration

### R.1 Boundaries preserved

| Context | HS.3 interaction |
|---------|------------------|
| Discovery | None (NarrativeThemeId only if classification touched — it is not) |
| Life Journey | None; capture ≠ evidence |
| Behavioral understanding | None |
| Personalization / feed | None |
| Identity | Ownership dependency documented; not implemented |

### R.2 Future integration (not HS.3)

```text
StoryPublished → Discovery → available inspiration source
```

### R.3 AI boundary reminder

AI may help tell the story later; AI does not own the story. HS.3 stores raw Hero-originated media only.

---

## S. Multilingual Foundation

### S.1 Preserve

- `Story.originalLanguage` — set from capture language when Story created via capture
- `StoryRepresentation.language` — same for original audio
- Available languages remain **derived** from representations
- Translations remain future representations, not new Stories

### S.2 HS.3 requirements

1. Capture request **must** include `LanguageCode`.
2. Enforce existing invariant: original rep language == story.originalLanguage.
3. Do not add `availableLanguages` storage field.
4. Do not implement translation.
5. Do not assume English.

### S.3 Deferred

- Locale negotiation UX
- Multi-language simultaneous capture
- Translation provenance beyond existing model

---

## T. Failure & Recovery Model

| Failure | Layer | Handling |
|---------|-------|----------|
| Microphone unavailable | Presentation/infra | Block start; no domain call |
| Permission denied | Presentation/infra | Block start |
| Recording interrupted | Presentation/infra | Pause/fail session |
| Recording canceled | Application | Cancel use case |
| Empty recording | Application | Validation failure |
| Invalid media (corrupt) | Application/infra | Reject store |
| Upload/storage failure | Infra → application | Retry store; no attach |
| Persistence failure | Application | Failure result; compensate delete if stored |
| Event publication failure | Application | Follow existing use case pattern (today: publish after save); document at-least-once risk as known debt — do not redesign event bus in HS.3 |
| Duplicate submission | Domain transitions | Existing `canTransitionTo` |
| Partial upload | Infra | Treat as failed store; idempotent retry |
| Abandoned capture | Application | Cancel or leave draft Story if already attached |

Avoid over-engineering sagas. Compensating delete + idempotent complete is enough.

---

## U. Security & Privacy Considerations

### U.1 Architectural requirements (HS.3)

1. Default visibility private/draft.
2. Explicit consent gates for processing/publication/AI.
3. Ownership via `heroId`.
4. Media references opaque; no public URLs required in domain.
5. In-memory adapter is **not** a security boundary — document as test/dev only.
6. Raw recordings are sensitive; treat deletion capability as required port method even if product policy deferred.

### U.2 Future dependencies (deferred)

- Authenticated caller checks (Identity)
- Authorization policies for who can retrieve raw audio vs published derivatives
- Retention schedules / GDPR-style erasure workflows
- Audit log of consent changes
- Encryption at rest
- Signed URL access

### U.3 HS.3 explicit non-goals

Complete security platform, moderation, production authn/z.

---

## V. File-Level Implementation Plan

Paths relative to repo root. **New** vs **Modified** noted. Tests listed alongside.

### V.1 Domain

| Path | N/M | Responsibility | Deps | Tests |
|------|-----|----------------|------|-------|
| `lib/features/hero_story/domain/value_objects/story_consent.dart` | N | Consent VO | shared ValueObject | `test/.../story_consent_test.dart` |
| `lib/features/hero_story/domain/aggregates/story.dart` | M | Hold consent; gates on submit/publish; capture factory / provisional narrative helpers | consent, existing | update `story_test.dart` |
| `lib/features/hero_story/domain/value_objects/story_narrative.dart` | M (if D-01 Option A/B) | Possibly allow provisional marker or empty-in-draft | — | narrative tests |
| `lib/features/hero_story/domain/services/story_media_storage_port.dart` | N | Storage port + DTOs | MediaReference | contract via adapter tests |
| `lib/features/hero_story/domain/services/story_capture_port.dart` | M | Narrow/deprecate per ADR; keep transcription unsupported | — | update adapter tests |
| `lib/features/hero_story/domain/domain.dart` | M | Exports | — | — |

**No new:** CaptureSession, StorySource, StoryMedia entity, new repositories, transcription events.

### V.2 Application

| Path | N/M | Responsibility | Tests |
|------|-----|----------------|-------|
| `application/dto/requests/complete_story_capture_request.dart` | N | Request DTO | via use case tests |
| `application/dto/requests/cancel_story_capture_request.dart` | N | Cancel DTO | via use case tests |
| `application/dto/requests/update_story_consent_request.dart` | N | Consent DTO | via use case tests |
| `application/dto/responses/complete_story_capture_response.dart` | N | Response DTO | via use case tests |
| `application/use_cases/complete_story_capture_use_case.dart` | N | Orchestration | `complete_story_capture_use_case_test.dart` |
| `application/use_cases/cancel_story_capture_use_case.dart` | N | Cancel | cancel tests |
| `application/use_cases/update_story_consent_use_case.dart` | N | Consent updates | consent tests |
| `application/use_cases/submit_story_use_case.dart` | M | Processing consent gate | update use case tests |
| `application/use_cases/publish_story_use_case.dart` | M | Publication consent gate | update use case tests |
| `application/providers/...` | N/M | Wire media storage (+ optional capture) | provider smoke optional |

### V.3 Infrastructure

| Path | N/M | Responsibility | Tests |
|------|-----|----------------|-------|
| `infrastructure/media/in_memory_story_media_storage_adapter.dart` | N | Deterministic bytes map | `in_memory_story_media_storage_adapter_test.dart` |
| `infrastructure/capture/unsupported_story_capture_adapter.dart` | M | Align with redesigned port | adapter test |
| `infrastructure/capture/in_memory_capture_idempotency_store.dart` | N (optional) | sessionId → completion | via use case tests |

### V.4 Documentation (implementation phase)

| Path | N/M |
|------|-----|
| `docs/architecture/architecture-decisions.md` | M — append new HS.3 ADRs when accepted |
| `docs/architecture/HS.3-Implementation-Report.md` | N — after implementation |
| Maps/glossary | Optional reconciliation; not required to start coding |

### V.5 Presentation

**Out of scope for HS.3 foundation DoD** unless separately authorized. Recording UI can consume use cases later.

---

## W. Testing Strategy

### W.1 Domain tests

Cover:

- `StoryConsent` equality/defaults
- `submit` without processing consent → failure
- `publish` without publication consent → failure
- Attach original audio via `addRepresentation(recording)` provenance step
- Original language mismatch still rejected
- Provisional narrative invariants (cannot approve/publish while provisional — per D-01)
- Invalid transitions unchanged
- AI consent field present but unused by capture

### W.2 Application tests

Cover:

- Complete capture: creates Story + stores media + adds representation + recorded consent
- Complete capture binds existing Story
- Idempotent complete (same sessionId)
- Empty media rejected
- Storage failure → no Story representation
- Persist failure compensation path (best effort delete)
- Cancel before/after store
- Consent update + submit/publish gates
- Hero archived rejected
- Events: `StoryCreated` (if new), `StoryRepresentationAdded`
- Does **not** call transcription successfully

### W.3 Infrastructure tests

Cover:

- In-memory store/exists/retrieve/delete
- Deterministic URI assignment
- Idempotent store by checksum (if implemented)

### W.4 Determinism rules

- No real mic
- No network
- No cloud storage
- No AI
- Prefer injectable `DateTime` for provenance timestamps where touching Story (align with TD clock debt if practical; do not boil ocean)

### W.5 Analyzer / suites

Implementation phase should run:

1. Focused `flutter test test/features/hero_story`
2. `flutter analyze`
3. Full `flutter test` before declaring HS.3 complete

---

## X. Architecture Decisions Required

> DO NOT invent ADR numbers in this plan. Mark where a new ADR is warranted or an existing ADR must be updated.

### D-01 Capture-first Story narrative

**Decision:** How to create/bind Story when canonical narrative text does not yet exist.

**Options:**

1. **Provisional narrative required string** (e.g. explicit provisional placeholder) + invariant blocking approve/publish until replaced  
2. **Allow empty narrative in draft only** (relax `StoryNarrative`)  
3. **Forbid Story create until Hero supplies narrative**; capture only stores media, Story created later  
4. **CaptureSession aggregate holds media until narrative exists**

**Recommendation:** **Option 1** (or Option 1 with optional title default `"Untitled Story"`).

**Reasoning:** Preserves HS-ADR-002 (Story exists as narrative aggregate from the start), allows capture-first UX, prevents publishing audio-only “stories”, avoids CaptureSession aggregate.

**Consequence:** Small domain change to Story create path + publish/approve guards; tests mandatory. **New ADR warranted.**

### D-02 CaptureSession boundary

**Decision:** CaptureSession is not a domain aggregate/entity.

**Options:** domain aggregate / entity / VO / application workflow / infra-only  

**Recommendation:** **Application workflow (+ infra temp).**

**Consequence:** No CaptureSessionRepository; sessionId for idempotency only. **New ADR warranted** (or fold into capture ADR).

### D-03 StorySource boundary

**Decision:** Do not introduce StorySource type.

**Recommendation:** Original audio `StoryRepresentation` + provenance expresses source.

**Consequence:** Avoids dual models. **New ADR warranted.**

### D-04 StoryRepresentation relationship

**Decision:** Capture creates original audio representation; does not create transcript automatically.

**Recommendation:** As above; transcript → HS.4.

**Consequence:** Aligns foundation HS.3 “transcript” wording to “foundation ready for transcript,” not AI transcript implementation. **Clarify in ADR / phase note.**

### D-05 StoryMedia / MediaReference

**Decision:** Keep MediaReference; no StoryMedia entity; bytes behind storage port.

**Recommendation:** Affirm existing HS.1 model.

**Consequence:** Update HS-ADR-012 companion ADR for storage port.

### D-06 Storage port + StoryCapturePort redesign

**Decision:** Add `StoryMediaStoragePort`; narrow/deprecate HS.1 `StoryCapturePort` captureAudio as orchestration moves to use cases; transcription remains unsupported until HS.4.

**Options:**

1. Extend StoryCapturePort with store methods (mixes concerns)  
2. **Separate StoryMediaStoragePort** (preferred)  
3. Put storage in application without port (violates hexagonal replaceability)

**Recommendation:** Option 2 + ADR updating HS-ADR-012.

**Consequence:** Clear boundaries; unsupported adapter remains for transcription stub or migrates later.

### D-07 Provenance

**Decision:** Reuse StoryProvenance; recording step on attach; no new provenance platform.

**Recommendation:** Affirm HS-ADR-005 application to capture.

### D-08 Consent

**Decision:** Add minimal `StoryConsent` VO with four stages; gate submit/publish; AI gate reserved.

**Options:** omit until later / full privacy engine / minimal VO  

**Recommendation:** **Minimal VO.** **New ADR warranted.**

### D-09 Authorization

**Decision:** HS.3 continues hero-active checks; production auth deferred.

**Recommendation:** Document dependency; no Identity coupling in domain.

### D-10 Visibility

**Decision:** No enum change; default private/draft for capture-created stories.

**Recommendation:** Prefer `private`.

### D-11 Capture lifecycle

**Decision:** Application session states only; Story lifecycle unchanged.

### D-12 Repository ownership

**Decision:** No new domain repositories.

### D-13 Domain events

**Decision:** Reuse `StoryCreated` + `StoryRepresentationAdded`; no capture-specific events in HS.3.

### D-14 Language metadata

**Decision:** Capture requires LanguageCode; sets originalLanguage + representation language.

### D-15 Ownership / access control

**Decision:** `Story.heroId` ownership; raw media ACL deferred; storage delete supported.

### ADR update summary

| Item | Action |
|------|--------|
| HS-ADR-002 | Remains binding |
| HS-ADR-004/005/006 | Remains binding |
| HS-ADR-012 | **Update or supersede** for media storage port + capture port narrowing |
| HS-ADR-015 | Remains binding (AI classification/transcription understanding → HS.4) |
| New ADRs | CaptureSession non-aggregate; StorySource not introduced; StoryConsent; provisional narrative; CompleteStoryCapture orchestration |

---

## Y. Architecture Drift / Technical Debt

| Item | Type | HS.3 should address? |
|------|------|----------------------|
| Stale aggregate/event/repo/use-case maps omit Hero & Story | Doc drift | Report; optional doc update after implementation, not blocking |
| Glossary missing Hero/Story/Capture terms | Doc drift | Optional |
| AGENTS.md phase status still says HS.1 next | Doc drift | Optional |
| `StoryCapturePort` unused / incomplete vs name “capture” | Intentional stub drift | **Yes — redesign in HS.3** |
| `DateTime.now()` in Story / EventBase | Known debt | Prefer injectable time on new capture paths; full cleanup deferred |
| Foundation vs code Representation entity | Intentional evolution | Follow code |
| No consent in code vs docs | Deferred → now in scope | **Yes — minimal** |
| Capture port transcription method in HS.1 | Premature AI surface | Keep unsupported; don’t implement |
| Missing presentation layer | Expected | Out of scope for foundation DoD |
| Event bus publish-after-save failure semantics | Pre-existing | Do not redesign in HS.3 |
| Duplicate/legacy Life Journey debt list in AGENTS §29 | Unrelated | Leave |

---

## Z. Deferred Work

### Z.1 Explicitly out of scope (HS.3)

- AI transcription / summarization / understanding / classification  
- Semantic/vector search  
- Recommendations / personalization / feed ranking  
- Hero feed / Discovery UI  
- Production cloud storage / auth / subscriptions / marketplace  
- Script generation / translation / AI narration  
- Moderation platform  
- Behavioral evidence integration  
- Full privacy/compliance platform  
- CaptureSession aggregate / StorySource aggregate / StoryMedia entity  
- Production microphone UX (may be later slice)

### Z.2 HS.4 boundary

- Transcription adapters  
- Story understanding  
- AI classification proposals + review/approval  
- Extraction / semantic analysis / AI metadata  

### Z.3 HS.5 boundary

- Authoring / editing workflows  
- Script generation  
- Translation  
- Alternate narrative forms  
- Narrated representations  

### Z.4 Dependencies to document

- Identity authn/z for ownership enforcement  
- Production `StoryMediaStoragePort` adapter  
- Optional recording device port for Flutter mic  
- Discovery consumption of `StoryPublished`  

---

## AA. Implementation Sequence

Adapted to current repository (not a generic template).

### Step 1 — Accept ADRs / decisions

- Record D-01…D-15 decisions into `architecture-decisions.md` (implementation kickoff)  
- **Prereq:** none  
- **Tests:** none  
- **Risk:** starting code before D-01/D-06/D-08 freezes waste  

### Step 2 — Domain: StoryConsent + provisional narrative invariants

- Files: `story_consent.dart`, `story.dart`, possibly `story_narrative.dart`  
- Tests: domain consent + transition guards  
- **Prereq:** Step 1  

### Step 3 — Domain port: StoryMediaStoragePort

- Files: `story_media_storage_port.dart` (+ small request/result types)  
- Tests: via adapter in Step 5  
- **Prereq:** Step 1  

### Step 4 — Narrow StoryCapturePort (documentation + signature alignment)

- Keep transcription unsupported  
- Remove pressure to call captureAudio from use cases  
- **Prereq:** Step 3 ADR  

### Step 5 — In-memory media storage adapter

- Files: `infrastructure/media/in_memory_story_media_storage_adapter.dart`  
- Tests: store/exists/retrieve/delete/idempotency  
- **Prereq:** Step 3  

### Step 6 — Application DTOs

- Complete/Cancel/Consent requests + Complete response  
- **Prereq:** Steps 2–3  

### Step 7 — CompleteStoryCaptureUseCase + Cancel + Consent

- Orchestration + idempotency  
- Tests: application suite  
- **Prereq:** Steps 2–6  

### Step 8 — Gate Submit/Publish use cases

- Modify existing use cases + tests  
- **Prereq:** Step 2  

### Step 9 — Providers wiring (optional but recommended)

- Media storage provider; do not wire production cloud  
- **Prereq:** Step 5–7  

### Step 10 — Analyzer + focused tests + full suite

- `flutter analyze`, `test/features/hero_story`, full `flutter test`  

### Step 11 — Implementation report + ADR finalization

- `HS.3-Implementation-Report.md`  
- Confirm scope discipline (no AI/cloud)  

### Step 12 — Presentation (explicitly optional / later)

- Only if authorized; not required for HS.3 foundation DoD  

---

## AB. Definition of Done

HS.3 is done when **all** of the following are objectively true:

### Domain

- [ ] `StoryConsent` exists and is owned by Story  
- [ ] Provisional narrative rules (D-01) enforced  
- [ ] Capture attaches original audio representation with `recording` provenance  
- [ ] Story remains canonical; audio is not treated as Story  
- [ ] No CaptureSession/StorySource/StoryMedia domain types  

### Application

- [ ] `CompleteStoryCaptureUseCase` orchestrates store → attach → consent.recorded  
- [ ] Cancel path exists without spurious domain events  
- [ ] Consent update path exists  
- [ ] `submit` / `publish` enforce processing / publication consent  
- [ ] Idempotent complete defined and tested  

### Infrastructure

- [ ] `StoryMediaStoragePort` + in-memory adapter  
- [ ] No production cloud provider  
- [ ] Transcription remains unsupported  

### Media abstraction

- [ ] Domain holds only `MediaReference`  
- [ ] Bytes only in infrastructure  

### Provenance / consent / authorization / visibility

- [ ] Recording provenance step written  
- [ ] Four consent stages represented; AI unused but gated for future  
- [ ] Default capture visibility private/draft  
- [ ] Lifecycle not conflated with visibility/consent  

### Multilingual

- [ ] Capture requires language; original language invariants hold  

### Lifecycle / failure / idempotency

- [ ] Empty/fail/cancel/retry paths tested at correct layers  

### Tests / quality

- [ ] Domain + application + infra tests added  
- [ ] `flutter analyze` clean  
- [ ] Focused hero_story tests pass  
- [ ] Full suite pass  

### Documentation / scope

- [ ] ADRs recorded for accepted decisions  
- [ ] Implementation report written  
- [ ] No AI/personalization/feed/cloud provider leakage  
- [ ] Architecture boundaries preserved  

---

## AC. Final Architectural Recommendation

# HS.3 READY FOR IMPLEMENTATION

### Blocking decisions to accept at kickoff (not open-ended research)

These are **resolved by recommendation** in this plan; implementation must formally record them as ADRs before coding:

1. **D-01** Provisional narrative for capture-created draft Stories  
2. **D-02** CaptureSession is application workflow, not aggregate  
3. **D-03** No StorySource type  
4. **D-06** `StoryMediaStoragePort` + capture port narrowing  
5. **D-08** Minimal `StoryConsent` VO with submit/publish gates  

If product rejects D-01 Option 1 in favor of Option 3 (media-only until narrative exists), re-plan the Complete use case before coding — that would be the only likely reversion to **NOT READY**.

### Exact implementation starting point

1. Append HS.3 ADRs to `docs/architecture/architecture-decisions.md`  
2. Implement `StoryConsent` + Story gates + provisional narrative invariants with domain tests  
3. Add `StoryMediaStoragePort` + in-memory adapter  
4. Implement `CompleteStoryCaptureUseCase`  

### Major architectural decisions (summary)

- Capture is workflow, not a new aggregate  
- Source material is original audio representation + provenance  
- Media bytes behind replaceable storage port  
- Consent is minimal and explicit  
- AI transcription/understanding deferred to HS.4  
- Reuse Story lifecycle, visibility, representation, and existing events  

### Artifact paths

- `/opt/cursor/artifacts/HS.3-Story-Capture-Foundation-Plan.md`  
- `docs/architecture/HS.3-Story-Capture-Foundation-Plan.md`  

---

## Appendix A — Recommended conceptual pipeline (HS.3 slice)

```text
Start capture (presentation)
  → Record / pause / resume (device infra)
  → Stop with non-empty audio
  → CompleteStoryCaptureUseCase
        → StoryMediaStoragePort.store
        → Story.create (draft, provisional narrative, private, originalLanguage)
           OR bind existing draft Story
        → addRepresentation(audio, original, recording)
        → consent.recordedAt = now
        → save + publish StoryCreated? + StoryRepresentationAdded
  → (later) UpdateStoryConsent(processing)
  → SubmitStoryUseCase → processing
  → HS.4+ understanding / transcription
  → review / approve
  → consent.publication + visibility
  → PublishStoryUseCase
```

## Appendix B — Mapping foundation §20 stages to phases

| Foundation stage | Phase |
|------------------|-------|
| Tell Your Story / Record / Upload | **HS.3** |
| Transcribe | **HS.4** (AI) / optional manual text later |
| Review | HS.1 lifecycle already; consent+capture feed it in **HS.3** |
| Understand / Categorize | **HS.4** |
| Edit | **HS.5** |
| Approve / Publish | Existing HS.1 use cases + consent gates **HS.3** |

## Appendix C — Inspection evidence (code anchors)

- `Story` canonical narrative: `lib/features/hero_story/domain/aggregates/story.dart`  
- `StoryRepresentation` + media/text invariants: `.../entities/story_representation.dart`  
- `MediaReference`: `.../value_objects/media_reference.dart`  
- Provenance: `story_provenance.dart`, `provenance_step.dart`  
- Capture stub: `story_capture_port.dart`, `unsupported_story_capture_adapter.dart`  
- HS.2 deferral: `docs/architecture/HS.2-Implementation-Report.md` §E  
- HS.3 roadmap: foundation doc §72  

---

*End of HS.3 — Story Capture Foundation Plan*
