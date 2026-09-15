# HS.11 — AI Story Understanding Foundation — Implementation Plan

**Status:** PLANNING COMPLETE — NO IMPLEMENTATION  
**Date:** 2026-09-15  
**Inspected repository:** `main` @ `b8821b9` (`feat(hero-story): implement HS.10 Story Persistence & Owner Story Experience (#28)`)  
**Constraint:** Planning only. Do not implement production code, AI SDKs, provider adapters, or UI in this deliverable.

---

## 1. Executive Summary

HS.11 should **not** reinvent Story Understanding. HS.4 already delivered the domain/application foundation for AI-assisted transcription and understanding behind replaceable ports. HS.9 delivered production recording and durable local Story/media persistence. HS.10 delivered the owner-facing My Stories / detail / playback experience.

**HS.11’s job is the production bridge:**

```text
Tell Your Story (HS.9)
        ↓
Story + original audio persisted (HS.9 / FileStoryRepository)
        ↓
Owner experience (HS.10 My Stories / Owned Story Detail)
        ↓
HS.11: consent-gated transcription against real media
        ↓
Derived AI transcript StoryRepresentation (already modeled in HS.4)
        ↓
Hero reviews / edits / approves transcript (UI missing today)
```

**Recommended MVP focus for HS.11:**

```text
Original Recording → Transcription → Transcript → Hero Review
```

**Explicitly out of HS.11 MVP:** production catalog classification UI, automatic Story narrative rewriting, translation/narration, personalization, cloud sync, SQL migration, AI coaching, and full `StoryUnderstanding` review/apply UI (HS.4 domain remains available for a later slice).

**Prime rule (unchanged):** *AI may help tell the story. It does not own the story.*

**Planning readiness:** Ready for implementation **after** Andy decides the credential/proxy model and whether transcription starts automatically after AI consent or only on explicit owner action (see §21).

---

## 2. Current Implementation State

### 2.1 Story domain (verified)

| Concern | Current implementation | Path / type |
|---------|------------------------|-------------|
| Aggregate | `Story` | `lib/features/hero_story/domain/aggregates/story.dart` |
| Capture factory | `Story.createFromCapture` | same |
| Lifecycle | `StoryLifecycleStatus` (`draft`…`removed`) | `…/enums/story_lifecycle_status.dart` |
| Visibility | `StoryVisibility` | `…/enums/story_visibility.dart` |
| Representation entity | `StoryRepresentation` | `…/entities/story_representation.dart` |
| Formats | `StoryRepresentationFormat` includes `transcript` | `…/enums/story_representation_format.dart` |
| Origin | `RepresentationOrigin` (`original` / `translated` / `derived`) | `…/enums/representation_origin.dart` |
| Narrative | `StoryNarrative` (+ `provisional()`) | `…/value_objects/story_narrative.dart` |
| Provenance | `StoryProvenance` + `ProvenanceStep` | `…/value_objects/story_provenance.dart`, `provenance_step.dart` |
| Classification / suitability / spirituality | authoritative VOs on Story | existing HS.2 model |
| Consent | `StoryConsent` (independent gates) | `…/value_objects/story_consent.dart` |
| Media pointer | `MediaReference` (opaque `uri`) | `…/value_objects/media_reference.dart` |
| AI proposal aggregate | `StoryUnderstanding` | `…/aggregates/story_understanding.dart` |
| Dedicated AI job status VO | **Does not exist** | — |

`Story.addRepresentation` appends provenance and raises `StoryRepresentationAdded`. Derived/translated reps require `sourceRepresentationId`. AI reps are non-authoritative until `approveRepresentation`.

### 2.2 Recording / media (HS.9 — verified)

| Concern | Implementation |
|---------|----------------|
| Device capture | `DeviceRecordingPort` + `RecordingSessionService` |
| Native adapter | `RecordPackageDeviceRecordingAdapter` |
| Web adapter | `RecordPackageWebDeviceRecordingAdapter` |
| Media port | `StoryMediaStoragePort` (`store`, `storeFromFile`, `retrieve`, `exists`, `delete`) |
| Durable media | `LocalFileStoryMediaStorageAdapter` → `{docs}/hero_story/media/…` |
| Capture completion | `CompleteStoryCaptureUseCase` + `FileCaptureCompletionStore` |
| Original association | Original `StoryRepresentation` (`format=audio`, `origin=original`) with `MediaReference`; provenance step `StoryTransformationType.recording` |
| Playback (owner) | `LoadOwnedStoryMediaUseCase` + `OwnedStoryPlaybackController` (`just_audio`) |
| Playback (seeker) | Discoverability-gated `LoadStoryMediaUseCase` / `StoryConsumeScreen` |

Original recording bytes remain in media storage; Story JSON stores only `MediaReference`. Transcription must load bytes via `StoryMediaStoragePort.retrieve` (already done in `TranscribeStoryRepresentationUseCase`).

### 2.3 Persistence (HS.9 / HS.10 — verified)

| Concern | Implementation |
|---------|----------------|
| Story metadata | `FileStoryRepository` → `{root}/stories/{id}.json` |
| Mapper | `StorySnapshotMapper` serializes representations, provenance, consent |
| Hero metadata | `FileHeroRepository` |
| Composition | `HeroStoryDurablePersistence` + `AppCompositionRoot` |
| Web | In-memory Story/media for process lifetime (documented limitation) |
| Understanding persistence | **`InMemoryStoryUnderstandingRepository` only** — no `FileStoryUnderstandingRepository` |
| Transcription idempotency | `InMemoryTranscriptionCompletionStore` only |

**Important:** Once `TranscribeStoryRepresentationUseCase` saves the Story, the **transcript text already persists** inside the Story JSON (`representations[].textContent`) via `FileStoryRepository`. HS.11 does **not** need a new database for transcripts. What is missing for production continuity is durable **processing/job** state and durable **idempotency** across app restarts.

### 2.4 Application layer (AI-relevant)

**Already implemented (HS.4):**

- `StoryTranscriptionPort` / `TranscribeStoryMediaRequest` / `StoryTranscriptionResult`
- `StoryUnderstandingPort` (+ authoring/translation ports from HS.5)
- `TranscribeStoryRepresentationUseCase` (consent + media load + add derived transcript)
- `GenerateStoryUnderstandingUseCase`, `ReviewStoryUnderstandingUseCase`, `ApplyStoryUnderstandingUseCase`
- `TranscriptionCompletionStore`, `UnderstandingCompletionStore`
- Events: `StoryUnderstandingProposed`, `StoryUnderstandingReviewed`, `StoryUnderstandingSuperseded`; transcript uses `StoryRepresentationAdded`

**Owner queries (HS.10):**

- `ListHeroOwnedStoriesUseCase`, `GetOwnedStoryDetailUseCase`, `LoadOwnedStoryMediaUseCase`
- `OwnedStoryMapper`, `OwnedStoryDetail`, `OwnedRepresentationSummary`

**Missing for HS.11 production path:**

- Riverpod providers for AI ports / transcription use cases
- Wiring in `AppCompositionRoot`
- Production (or proxy) transcription adapter
- Explicit transcription processing status (distinct from `StoryLifecycleStatus.processing`)
- Owner UI entry points for start / progress / transcript review
- Durable completion-store / job persistence

### 2.5 UI (verified)

| Flow | Current screen / state |
|------|------------------------|
| Tell Your Story | `TellYourStoryScreen` + `TellYourStoryController` |
| Record / Review / Accept | steps: prepare → record → review → consent → completed |
| Consent | `_ConsentStep` — processing + AI switches; `UpdateStoryConsentUseCase` |
| Story Saved | View Story / My Stories / Done |
| My Stories | `MyStoriesScreen` |
| Owner detail | `OwnedStoryDetailScreen` — original recording + consent summary + archive |
| Transcript review | **Missing** |
| AI processing UX | **Missing** |

### 2.6 Where AI can enter the existing flow

```text
Tell Your Story
  prepare → record → review → Accept (persist Story + original audio)
        → consent (optional processing + AI)
        → Story Saved → View Story / My Stories
                ↓
         OwnedStoryDetailScreen   ← ★ HS.11 primary entry
                ↓
         Start / resume transcription (if AI+processing consent)
                ↓
         Processing status
                ↓
         Transcript review / edit / approve
```

**Do not** block Accept on transcription (HS-ADR-064). Optional post-consent auto-start is an Andy decision (§21).

---

## 3. Relevant HS.1 Architectural Principles

From HS.1 Foundation + AGENTS.md (binding for HS.11):

1. **AI may help tell the story. It does not own the story.**
2. AI must not silently manufacture facts, experiences, quotations, identity claims, or meaning.
3. Original recording remains the authoritative provenance source.
4. Representations form a chain; do not collapse into one mutable Story body.
5. Consent stages are independent: recorded ≠ processing ≠ publication ≠ AI transformation.
6. AI artifacts are non-authoritative until reviewed/approved.
7. AI providers sit behind ports; domain never depends on OpenAI/Anthropic/Gemini.
8. Catalog ≠ Discovery ≠ Personalization.
9. Story interaction / capture ≠ BehavioralEvidence (HS-ADR-066).

Conceptual transformation chain (HS.1):

```text
Original Recording
        ↓
Transcript
        ↓
Edited Transcript
        ↓
Story Draft
        ↓
Approved Story
        ↓
Translation / Narrated Audio
```

**Code mapping today:**

| Conceptual step | Existing mechanism |
|-----------------|--------------------|
| Original Recording | `StoryRepresentation` audio + `MediaReference` |
| Transcript | Derived AI `StoryRepresentation` (`format=transcript`) via HS.4 use case |
| Edited Transcript | `EditUnapprovedStoryRepresentationUseCase` / `Story.replaceUnapprovedRepresentationText` (provenance `editing`) |
| Story Draft narrative | `UpdateStoryNarrativeUseCase` (human-only; AI scripts must not mutate narrative — HS-ADR-035) |
| Approved representation | `ApproveStoryRepresentationUseCase` / `Story.approveRepresentation` |

HS.11 should use this existing chain — not invent a parallel transcript aggregate.

---

## 4. HS.9 Implementation Findings

**Status:** COMPLETE (PR #22 + web runtime PRs).

Findings relevant to HS.11:

- Accept creates a **private draft** Story with durable original audio on native.
- Transcription/AI intentionally **non-blocking** (HS-ADR-064).
- `StoryMediaStoragePort.retrieve` can supply bytes for transcription.
- Durable composition lives in `AppCompositionRoot` / `HeroStoryDurablePersistence` — AI ports are **not** wired there yet.
- Web Accepts are not durable across restart; HS.11 production transcription should treat **native durable** as the primary validated path.
- Capture raises `StoryCreated` + `StoryRepresentationAdded`; consent updates raise **no** domain event.

Deferred by HS.9 and still relevant: async transcription hook, production AI, remote storage.

---

## 5. HS.10 Implementation Findings

**Status:** COMPLETE (PR #28; report `docs/analysis/HS.10-implementation-completion.md`).

Findings relevant to HS.11:

- Owner list/detail/playback exist and bypass Discoverability gates correctly.
- `OwnedStoryDetail` already exposes consent flags and representation summaries, but UI does not surface transcript text or AI-vs-original distinction beyond consent summary.
- HS.10 explicitly deferred **AI job status** and warned not to overload Accept or `StoryLifecycleStatus.processing`.
- Archive is soft; original media retained — transcription must not delete originals.
- Persistence technology unchanged (JSON files + media port) — HS.11 should continue this pattern.

Investigation note: earlier `docs/analysis/HS.10-story-persistence-and-ui-plan.md` said “NO IMPLEMENTATION”; that is superseded by the completion report and `main` @ `b8821b9`.

---

## 6. Proposed HS.11 Architecture

### 6.1 Relationship to HS.4

| Layer | HS.4 delivered | HS.11 adds |
|-------|----------------|------------|
| Domain ports | `StoryTranscriptionPort`, `StoryUnderstandingPort` | Keep; do not replace with a generic `AIService` |
| Use cases | Transcribe / Generate / Review / Apply | Wire + optionally thin orchestration wrapper for owner UX |
| Adapters | In-memory deterministic only | Proxy-backed (or staged) production transcription adapter |
| UI | None | Owner processing + transcript review |
| Persistence | Transcript via Story JSON; understanding in-memory | Durable job/idempotency; keep Story JSON for transcript text |
| Composition | Test-only wiring | Riverpod + `AppCompositionRoot` |

**Do not** reimplement HS.4 domain. Treat HS.4 as the AI boundary authority; HS.11 is the productionization + owner UX milestone for **transcription**.

### 6.2 Target pipeline (MVP)

```text
OwnedStoryDetailScreen
        ↓
(ensure processing + AI consent — UpdateStoryConsentUseCase if needed)
        ↓
StartStoryTranscription orchestration (application)
        ↓
persist job status = processing
        ↓
TranscribeStoryRepresentationUseCase
        ↓
StoryMediaStoragePort.retrieve(original MediaReference)
        ↓
StoryTranscriptionPort.transcribe(...)
        ↓
Story.addRepresentation(transcript) + provenance
        ↓
FileStoryRepository.save(story)
        ↓
job status = completed | failed
        ↓
Transcript Review UI (read / edit / approve)
```

### 6.3 What stays out of domain

- Provider SDKs, HTTP clients, API keys
- UI controllers / Riverpod notifiers
- Network retry policy details (application/infrastructure)
- Logging of raw audio or transcript PII to analytics

---

## 7. AI Boundary

### 7.1 Existing boundary (reuse)

Keep HS-ADR-024 ports:

- `lib/features/hero_story/domain/services/story_transcription_port.dart`
- `lib/features/hero_story/domain/services/story_understanding_port.dart` (later; not MVP-required)

Request/response models already exist on the transcription port:

- Input: `storyId`, `sourceRepresentationId`, `mediaReference`, `language`, `processingVersion`, optional `requestId`, optional `mediaBytes`
- Output: `text`, `language`, `sourceMediaReference`, optional `providerLabel`, `supportLevel`, `opaqueProviderConfidence`
- Errors: `StoryTranscriptionException`

### 7.2 Provider abstraction

```text
Application / Use Case
        ↓
StoryTranscriptionPort   (domain service interface)
        ↓
Infrastructure adapter
        ↓
(optional) EH backend AI proxy
        ↓
External STT provider
```

**Do not** put OpenAI/Anthropic/Gemini types in domain or application imports. Extend `test/features/hero_story/architecture/ai_boundary_test.dart` accordingly (today it asserts no production adapters exist — that assertion must evolve to “no SDK imports in domain/application,” not “no adapters at all”).

### 7.3 Dependency injection

Add providers under something like:

- `lib/features/hero_story/application/providers/ai/story_transcription_port_provider.dart`
- `lib/features/hero_story/application/providers/use_cases/transcription_use_case_providers.dart`

Wire durable overrides in `AppCompositionRoot` alongside existing Story/media overrides.

Default for tests / offline: keep `InMemoryStoryTranscriptionAdapter`.

### 7.4 Error model

Prefer mapping provider failures into `StoryTranscriptionException` / use-case `Failure` strings already used by `TranscribeStoryRepresentationUseCase`. Optionally introduce a typed `TranscriptionFailureKind` at the **application** layer for UI (unavailable media, consent, network, timeout, unsupported format, provider, persistence) without leaking vendor codes into domain.

---

## 8. Transcription Boundary

### 8.1 Input representation

Reuse existing:

1. Resolve Story + original audio `StoryRepresentation` (owner-scoped).
2. Require `mediaReference`.
3. Load bytes via `StoryMediaStoragePort.retrieve`.
4. Pass `TranscribeStoryMediaRequest` including bytes (current use case already does this).

**Do not** pass filesystem paths into the domain port. Adapters may use temp files internally if a provider SDK requires them.

### 8.2 Output representation

Reuse HS-ADR-025:

- New `StoryRepresentation` with `format=transcript`, `origin=derived`, `isAiGenerated=true`, `sourceRepresentationId=<original audio id>`, `textContent=<transcript>`
- Transformation type: `StoryTransformationType.transcription`
- Event: existing `StoryRepresentationAdded` (do **not** require a new `StoryTranscribed` event for MVP)

### 8.3 Metadata guidance (avoid over-engineering)

| Field | Guidance |
|-------|----------|
| `providerLabel` | Keep optional string on result (already present) |
| `supportLevel` | Keep categorical `AnalysisSupportLevel` (HS-ADR-027) |
| `opaqueProviderConfidence` | Keep opaque; never treat as domain truth |
| Word-level timestamps | **Defer** unless a concrete UI need appears |
| Separate transcript document store | **Do not add** — Story JSON is sufficient |

### 8.4 Retry / idempotency

Reuse `TranscriptionCompletionStore` keyed by `requestId` (successful results only). For production:

- Persist completion records (file JSON next to capture store), **or**
- Derive “already transcribed” from existing derived transcript representation for the same source + processingVersion

Recommendation: durable file completion store **plus** guard that refuses duplicate transcript representation IDs (already present). Retries after failure use a **new** `requestId` or clear failed job state without deleting the original audio.

---

## 9. Story Representation / Provenance Model

### 9.1 Required chain for HS.11

```text
Original Recording (audio, origin=original, immutable bytes)
        │
        └── Transcript (format=transcript, origin=derived, isAiGenerated=true)
               │
               └── Edited Transcript (same representation id, human edit + provenance editing step)
                      │
                      └── (FUTURE) Story Draft narrative via UpdateStoryNarrativeUseCase
```

### 9.2 Guarantees

- Original audio representation and media bytes are **never overwritten** by transcription.
- Transcript does **not** replace `Story.narrative`.
- `sourceRepresentationId` links transcript → original.
- Provenance steps record `transcription` then optional `editing`.
- Approval uses `ApproveStoryRepresentationUseCase` — still does not mutate narrative.

### 9.3 Owner visibility

Extend owner DTOs/UI so the Hero can distinguish:

1. Original recording (playable)
2. AI-generated transcript (labeled AI / unapproved)
3. Human-edited transcript (provenance note / edited state)
4. Approved transcript (authoritative representation flag)

`OwnedRepresentationSummary` today lacks `isAiGenerated`, `isApproved`, `textContent`, and `sourceRepresentationId` — extend in HS.11 UI slices.

---

## 10. Consent Model

### 10.1 Existing model (reuse)

`StoryConsent` gates:

- `recordedAt`
- `processingApprovedAt`
- `publicationApprovedAt`
- `aiTransformationApprovedAt`

HS-ADR-030 / HS-ADR-021: AI ports require **processing + AI** consent. Publication not required. Recording alone insufficient.

Enforcement already exists in `TranscribeStoryRepresentationUseCase` (application boundary) — **keep and rely on this**; UI must not be the only gate.

### 10.2 HS.11 enforcement points

| Layer | Responsibility |
|-------|----------------|
| UI | Show consent state; allow grant/revoke via existing `UpdateStoryConsentUseCase`; disable Start Transcription when missing |
| Application | Hard fail before port call if consent missing/revoked |
| Infrastructure | Must not bypass use case |

### 10.3 Revocation

Per HS-ADR-030: revoke blocks **future** AI calls; existing transcript representations retained by default. Auto-delete on revoke remains **deferred** (HS.4 debt).

### 10.4 Gap

Consent update currently raises **no** domain event. For MVP, UI/use-case polling of Story consent is enough. A `StoryConsentUpdated` event is optional and not required to start HS.11.

---

## 11. Processing Lifecycle

### 11.1 Problem

`StoryLifecycleStatus.processing` means **submitted for publication/review pipeline** (`Story.submit`), not “AI transcription running.” Overloading it would break HS.10 owner semantics and HS-ADR-064.

### 11.2 Recommendation

Introduce an explicit **application/domain VO** for AI transcription processing, conceptually:

```text
notStarted | queued | running | completed | failed | cancelled
```

Suggested name (final naming in ADR): `StoryTranscriptionStatus` or `AiTranscriptionJobStatus` — **not** reuse of `StoryLifecycleStatus`.

Storage options (pick one in ADR):

1. **Preferred for MVP:** Application-level durable job record keyed by `storyId` + `sourceRepresentationId` (JSON file under `{root}/transcription_jobs/`), analogous to `FileCaptureCompletionStore`.
2. Alternative: value object embedded on Story snapshot — couples Story aggregate to ephemeral job failure details.

Do **not** invent a second Story aggregate for jobs.

### 11.3 Distinguish from publication lifecycle

| Concept | Type | Meaning |
|---------|------|---------|
| Capture saved | lifecycle `draft`, visibility `private` | HS.9 Accept |
| AI transcription | `StoryTranscriptionStatus` | HS.11 |
| Submit for review | lifecycle `processing` | existing `SubmitStoryUseCase` |
| Understanding proposal | `UnderstandingStatus` | HS.4 (future UI) |

---

## 12. Persistence Strategy

### 12.1 Keep local JSON + media port

Do **not** introduce SQL, cloud sync, or a new DB for HS.11.

| Artifact | Persistence |
|----------|-------------|
| Original audio | `LocalFileStoryMediaStorageAdapter` (unchanged) |
| Transcript text | `StoryRepresentation.textContent` inside `FileStoryRepository` JSON (already supported by `StorySnapshotMapper`) |
| Provenance | Story JSON `provenance.steps` (already supported) |
| Consent | Story JSON `consent` (already supported) |
| Transcription idempotency | New durable store mirroring `FileCaptureCompletionStore` pattern |
| Processing job status | New durable JSON job records (recommended) |
| `StoryUnderstanding` | Remain in-memory for HS.11 MVP (defer `FileStoryUnderstandingRepository`) |

### 12.2 Web

Native durable path is the acceptance target. Web may use in-memory adapters + in-memory transcription (or disabled production adapter) until web durable media exists.

---

## 13. Provider Strategy

### 13.1 Replaceability

Architecture remains:

```text
Application → StoryTranscriptionPort → Adapter → (Proxy) → External STT
```

Likely first production direction (research item, not hard-coded into domain):

- Speech-to-text provider behind an **Everyone’s Heroes backend proxy**, not a direct Flutter→vendor call with embedded secrets.

Repository today has **no** AI SDK dependencies in `pubspec.yaml` (`record`, `just_audio`, `path_provider`, etc. only).

### 13.2 Credentials

**Hard constraint:** production AI secrets must **not** live in the Flutter client.

Options for Andy:

| Option | Pros | Cons |
|--------|------|------|
| **A. Backend AI proxy (recommended)** | Secrets server-side; policy/logging control; consent audit | Requires backend service not yet in repo |
| B. Dev-only local key via `--dart-define` / env for prototypes | Fast local demos | Must never ship as production default |
| C. Direct vendor SDK in app with user-supplied key | No EH backend | Poor UX; still not EH-managed production |

HS.11 implementation should ship:

1. Port + wiring + fake/in-memory adapter (always)
2. A **proxy HTTP adapter** skeleton **or** clearly gated dev adapter
3. No committed API keys

### 13.3 If proxy is not ready

Implement end-to-end owner UX against `InMemoryStoryTranscriptionAdapter` / a `FakeProxyStoryTranscriptionAdapter`, and isolate the real network adapter behind a feature flag. Do not block transcript review UI on vendor access.

---

## 14. Security / Privacy Considerations

| Topic | HS.11 requirement |
|-------|-------------------|
| Consent | Processing + AI required before any external send |
| Credentials | Server-side proxy; never in client binaries for production |
| PII / sensitive stories | Treat audio + transcript as sensitive; minimize logs |
| Transport | HTTPS only to proxy/provider |
| Logging | Log job ids / story ids / failure kinds — not raw audio or full transcripts in client logs |
| Provider retention | **Research item** — do not invent guarantees; document vendor policy verification before production enablement |
| Local persistence | Transcript remains on-device in Story JSON; original audio retained |
| User visibility | Owner UI must show processing/running/failed/completed |
| Cancel / revoke | Best-effort cancel in-flight; revoke blocks new calls; retain artifacts by default |
| Failure | Leave original recording and Story narrative intact (already HS.4 tested behavior) |

---

## 15. Event Flow

### 15.1 Existing events to reuse

| Event | When | HS.11 use |
|-------|------|-----------|
| `StoryRepresentationAdded` | Transcript attached | Primary signal that transcription produced an artifact |
| `StoryRepresentationApproved` | Hero approves transcript | Review completion |
| `StoryUnderstanding*` | Understanding pipeline | **Defer** from MVP UI |

### 15.2 Recommended new events (only if needed)

| Candidate | Necessary? | Rationale |
|-----------|------------|-----------|
| `StoryTranscriptionStarted` | **Optional** | Useful if reactors/UI subscribe asynchronously; otherwise job store + UI polling suffices for MVP |
| `StoryTranscriptionFailed` | **Optional** | Same — job record may be enough |
| `StoryTranscribed` | **Not required** | HS.4 intentionally deferred; `StoryRepresentationAdded` covers artifact creation |
| `StoryConsentUpdated` | **Optional / defer** | Helpful later; not blocking |

**Recommendation:** MVP relies on durable job status + existing representation events. Add `StoryTranscriptionStarted` / failed events only if a reactor or multi-listener need appears during implementation.

Do not auto-chain `StoryRepresentationAdded` → `GenerateStoryUnderstandingUseCase` in HS.11 without explicit product decision (would expand beyond transcription MVP).

---

## 16. Architectural Gaps (classified)

| Gap | Classification |
|-----|----------------|
| No Riverpod / composition wiring for HS.4 AI ports | **Required during HS.11** |
| No production/proxy transcription adapter | **Required during HS.11** (or gated fake + proxy skeleton) |
| No explicit AI transcription job status | **Required during HS.11** |
| Owner DTOs lack AI/transcript fields for UI | **Required during HS.11** |
| No transcript review UI | **Required during HS.11** |
| `TranscriptionCompletionStore` in-memory only | **Required during HS.11** (durable) |
| Consent update has no domain event | **Can be deferred** |
| `FileStoryUnderstandingRepository` missing | **Can be deferred** (MVP is transcription) |
| Understanding review/apply UI missing | **Deferred future work** |
| Web durable media missing | **Architectural concern** — native-first validation |
| `ai_boundary_test` forbids production adapters by filename | **Required during HS.11** (update test intent) |
| Backend AI proxy not in repository | **Required before production provider** (Andy decision) |
| Provider data-retention policy unverified | **Research / decision item** |
| Auto-start vs explicit start after consent | **Architectural decision required** |
| Clock / `DateTime.now()` (TD-007) | **Can be deferred** (continue request timestamps) |

No gap requires redesigning `Story`, `StoryConsent`, or `StoryTranscriptionPort` before starting HS.11.

---

## 17. Detailed Implementation Slices

Optimized order based on repository reality (HS.4 ports exist; HS.10 owner UI exists; production wiring does not).

### HS.11.1 — Scope Lock & ADR

- **Objective:** Record that HS.11 reuses HS.4 ports; introduces transcription job status separate from Story lifecycle; production secrets stay out of the client.
- **Files:** `docs/architecture/architecture-decisions.md` (new HS-ADR-06x+)
- **Domain/App/Infra/UI:** documentation only
- **Tests:** none
- **Dependencies:** Andy decisions in §21 where marked blocking
- **Acceptance:** ADRs accepted; MVP boundary explicit (transcription + review only)

### HS.11.2 — Transcription Processing Status

- **Objective:** Model AI transcription job state without overloading `StoryLifecycleStatus`.
- **Likely files:**  
  - `lib/features/hero_story/domain/enums/` or application VO for status  
  - durable job store interface + `File…` / `InMemory…` adapters  
  - tests under `test/features/hero_story/`
- **Domain:** status enum/VO only if truly domain-relevant; otherwise application job record
- **Application:** job repository/store port
- **Infrastructure:** JSON file under `{root}/transcription_jobs/`
- **UI:** none yet
- **Dependencies:** HS.11.1
- **Acceptance:** statuses distinguishable from publication lifecycle; restart restores last job state

### HS.11.3 — AI Port Wiring (Riverpod + Composition)

- **Objective:** Make `StoryTranscriptionPort` and `TranscribeStoryRepresentationUseCase` injectable in app composition.
- **Likely files:**  
  - new providers under `application/providers/ai/` and `…/use_cases/`  
  - `lib/app/app_composition_root.dart`  
  - `HeroStoryDurablePersistence` (optional helpers)
- **Default adapter:** `InMemoryStoryTranscriptionAdapter`
- **Tests:** provider/composition tests; existing HS.4 tests still pass
- **Dependencies:** HS.11.1
- **Acceptance:** app can construct transcription use case without test-only manual wiring

### HS.11.4 — Durable Transcription Idempotency Store

- **Objective:** Survive app restart without duplicate transcripts for the same successful `requestId`.
- **Likely files:**  
  - extend `application/understanding/transcription_completion_store.dart`  
  - `infrastructure/…/file_transcription_completion_store.dart` (new)  
  - mirror patterns from `file_capture_completion_store.dart`
- **Dependencies:** HS.11.3
- **Acceptance:** successful transcription replay returns prior result; failure does not poison store

### HS.11.5 — Owner Transcription Orchestration Use Case

- **Objective:** Application entrypoint that checks ownership + consent, sets job status, invokes `TranscribeStoryRepresentationUseCase`, maps failures.
- **Likely files:**  
  - `application/use_cases/start_owned_story_transcription_use_case.dart` (name TBD)  
  - request/response DTOs  
  - providers
- **Must:** leave original media untouched; never mutate narrative
- **Dependencies:** HS.11.2–11.4
- **Acceptance:** consent enforced; job transitions running→completed/failed; idempotent behavior defined

### HS.11.6 — Provider Adapter (Proxy / Dev)

- **Objective:** First non-domain adapter capable of real or simulated network transcription **without** client secrets in production builds.
- **Likely files:**  
  - `infrastructure/ai/proxy_story_transcription_adapter.dart` (or `http_proxy_…`)  
  - keep `in_memory_story_transcription_adapter.dart`  
  - update `ai_boundary_test.dart`
- **Dependencies:** HS.11.3; proxy availability decision
- **Acceptance:** domain/application still SDK-free; adapter failures map to `StoryTranscriptionException`; feature-flagged

### HS.11.7 — Owner DTO / Mapper Extensions

- **Objective:** Surface transcript + AI flags to presentation without exposing aggregates to widgets.
- **Likely files:**  
  - `owned_story_detail.dart`, `owned_story_mapper.dart`  
  - `OwnedRepresentationSummary` fields: `isAiGenerated`, `isApproved`, `textPreview`/`hasText`, `sourceRepresentationId`  
  - view models / labels
- **Dependencies:** none beyond HS.10
- **Acceptance:** detail query returns enough to render original vs AI transcript distinction

### HS.11.8 — Transcript Review UI

- **Objective:** On `OwnedStoryDetailScreen` (or child route), show processing controls and transcript review.
- **Flow:** My Stories → Owned Story Detail → Understanding/Transcription section → Transcript Review
- **Likely files:**  
  - `owned_story_detail_screen.dart`  
  - new controller/provider for transcription actions  
  - optional `transcript_review_section.dart`
- **Actions:** Start / Retry; show status; display transcript text; edit via `EditUnapprovedStoryRepresentationUseCase`; approve via `ApproveStoryRepresentationUseCase`
- **Dependencies:** HS.11.5, HS.11.7
- **Acceptance:** Hero can distinguish original recording vs AI transcript vs edited/approved; narrative unchanged

### HS.11.9 — Consent UX Continuity

- **Objective:** If AI consent was skipped at capture, allow granting from owner detail before transcription.
- **Reuse:** `UpdateStoryConsentUseCase`
- **Enforce:** still at use-case boundary
- **Dependencies:** HS.11.8
- **Acceptance:** cannot start transcription without both consents; UI reflects revoke

### HS.11.10 — Error / Retry Hardening

- **Objective:** Cover failure modes without duplicate/contradictory transcripts.
- **Cases:** missing media, unsupported format, provider/network/timeout, malformed response, consent revoke mid-flight, persistence failure, interrupted processing
- **Dependencies:** HS.11.5–11.6
- **Acceptance:** failed jobs retryable; originals intact; successful idempotency preserved

### HS.11.11 — End-to-End Validation

- **Objective:** Prove the full native path with fakes/proxy.
- **Flow under test:**

```text
Tell Your Story → Record → Accept → Consent (processing+AI)
  → My Stories → Detail → Start transcription → Persist transcript
  → Display transcript → Edit → Approve
```

- **Tests:** integration under `test/features/hero_story/integration/`; UI tests beside `hs10_my_stories_ui_test.dart`
- **Analyzer:** `dart analyze` clean for touched code
- **Dependencies:** prior slices
- **Acceptance:** focused + relevant broader Flutter tests pass; architecture boundary tests updated

---

## 18. Files Likely Affected

### Existing (verified) — extend / wire

- `lib/features/hero_story/domain/services/story_transcription_port.dart`
- `lib/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart`
- `lib/features/hero_story/application/understanding/transcription_completion_store.dart`
- `lib/features/hero_story/application/use_cases/edit_unapproved_story_representation_use_case.dart`
- `lib/features/hero_story/application/use_cases/approve_story_representation_use_case.dart`
- `lib/features/hero_story/application/use_cases/update_story_consent_use_case.dart`
- `lib/features/hero_story/application/owned/owned_story_mapper.dart`
- `lib/features/hero_story/application/dto/responses/owned_story_detail.dart`
- `lib/features/hero_story/presentation/screens/owned_story_detail_screen.dart`
- `lib/features/hero_story/presentation/models/owned_story_detail_view_model.dart`
- `lib/features/hero_story/presentation/providers/owned_story_providers.dart`
- `lib/app/app_composition_root.dart`
- `lib/features/hero_story/application/providers/persistence/hero_story_persistence_providers.dart`
- `lib/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart`
- `test/features/hero_story/architecture/ai_boundary_test.dart`
- `docs/architecture/architecture-decisions.md`

### Likely new

- AI / transcription Riverpod providers
- Owner start-transcription use case + DTOs
- File-backed transcription completion store
- Transcription job store + status type
- Proxy/dev transcription adapter
- Transcript review presentation widgets/controller
- `test/features/hero_story/application/use_cases/hs11_*_test.dart`
- `test/features/hero_story/presentation/hs11_*_ui_test.dart`
- `test/features/hero_story/integration/hs11_*_integration_test.dart`

### Explicitly not inventing

- New Story body field that overwrites narrative with AI text
- SQL/Drift schema
- Production OpenAI package import in domain/application
- `StoryTranscribed` event unless a concrete subscriber appears

---

## 19. Testing Strategy

Follow existing `test/features/hero_story/` layout (no new framework).

| Layer | Focus |
|-------|-------|
| Domain | Job status transitions (if domain VO); representation/provenance invariants already covered — extend only if new types appear |
| Application | Consent enforcement; orchestration; idempotency; retry; failure leaves originals intact |
| Infrastructure | Adapter mapping; durable job/completion serialization; media retrieve integration with fake adapter |
| UI | Processing states; transcript display; edit/approve; error/empty/consent-blocked |
| Architecture | Domain/application remain free of AI SDKs / HTTP imports |
| Integration | Full capture → consent → transcribe → review path (native durable composition) |

Reuse patterns from:

- `test/features/hero_story/application/use_cases/hs4_story_understanding_use_cases_test.dart`
- `test/features/hero_story/integration/hs10_owner_story_experience_integration_test.dart`
- `test/features/hero_story/presentation/hs10_my_stories_ui_test.dart`
- `test/features/hero_story/architecture/ai_boundary_test.dart`

---

## 20. Acceptance Criteria (HS.11 complete)

- [ ] No production AI secrets in the Flutter client
- [ ] Domain does not import provider SDKs
- [ ] Original recording bytes and representation remain immutable provenance source
- [ ] Transcript persisted as derived `StoryRepresentation`, not as Story narrative replacement
- [ ] Processing + AI consent enforced in application before port invocation
- [ ] Transcription processing status exists and is distinct from Story publication lifecycle
- [ ] Owner can view AI transcript separately from original recording
- [ ] Owner can edit unapproved transcript and/or approve it via existing use cases
- [ ] Failures do not delete/corrupt original media or fabricate narrative
- [ ] Retries do not create contradictory duplicate successes for the same completion key
- [ ] `dart analyze` clean for changed code; focused HS.11 tests pass; relevant full suite green
- [ ] HS.4 understanding generation / catalog apply UI still deferred unless explicitly pulled in later

---

## 21. Architectural Risks

1. **Credential/proxy absence** — cannot enable real STT in production without a server-side secret holder.
2. **Lifecycle confusion** — misusing `StoryLifecycleStatus.processing` for AI jobs would corrupt owner UX and submit semantics.
3. **Auto-start after consent** — surprising network upload of intimate audio; privacy risk if not explicit.
4. **Large audio uploads** — memory/time; may need streaming/temp-file adapter internals (port still byte/media-ref based).
5. **Web durability gap** — E2E claims must specify native.
6. **Scope creep into HS.4 understanding UI** — threatens MVP delivery and review complexity.
7. **Provider retention/compliance** — legal/privacy review needed before production enablement.
8. **Updating `ai_boundary_test`** — must tighten the real invariant (no SDK in domain/app) rather than ban all adapters.

---

## 22. Open Questions / Decisions (Andy)

### Blocking before production adapter enablement

1. **Credential architecture:** Backend AI proxy (recommended) vs temporary dev-only keys?
2. **First STT vendor / proxy contract:** which provider and what request/response schema should the adapter target?
3. **Provider data retention / training policy:** acceptable for Hero audio?

### Blocking for UX semantics

4. **Transcription start mode:** explicit button on Owned Story Detail (recommended) vs automatic after AI consent at capture?
5. **Mid-flight cancel:** required in MVP or best-effort defer?

### Non-blocking (can decide during implementation)

6. Exact type name/location for transcription job status (domain enum vs application record).
7. Whether to emit `StoryTranscriptionStarted` / failed events in MVP.
8. Whether granting AI consent from Owned Story Detail should deep-link from consent summary.
9. Whether approved transcripts should ever seed `UpdateStoryNarrativeUseCase` suggestions (likely **future**, not HS.11).

---

## 23. Explicitly Deferred Future Work

Not part of HS.11 MVP:

```text
Transcript
   ↓
Story Understanding generation UI
   ↓
Themes / Classification candidates review
   ↓
Apply catalog proposals
   ↓
Story Draft assistance
   ↓
Editing assistance beyond transcript text
   ↓
Translation
   ↓
Narration
```

Also deferred:

- `FileStoryUnderstandingRepository`
- Auto-delete AI artifacts on consent revoke
- Production authoring/translation providers (HS.5 ports remain in-memory)
- Cloud media, SQL, sync
- Personalization / embeddings / coaching
- Automatic publishing
- Weakening Discoverability gates
- BehavioralEvidence from transcription

HS.4 domain for understanding remains available for a later phase (e.g., HS.12) once transcripts are reliably produced and reviewable.

---

## 24. Recommended Implementation Order

```text
HS.11.1  Scope lock & ADRs
   ↓
HS.11.2  Transcription processing status (job model)
   ↓
HS.11.3  Riverpod + AppCompositionRoot wiring (in-memory adapter)
   ↓
HS.11.4  Durable transcription completion store
   ↓
HS.11.5  Owner transcription orchestration use case
   ↓
HS.11.7  Owner DTO/mapper extensions          ⎤ can overlap after 11.5
HS.11.8  Transcript review UI                 ⎦
   ↓
HS.11.9  Consent continuity on owner detail
   ↓
HS.11.6  Proxy/dev provider adapter (as credentials allow)
   ↓
HS.11.10 Error/retry hardening
   ↓
HS.11.11 End-to-end validation
```

**Rationale for ordering:** unlock testable owner UX against the existing in-memory adapter before depending on network credentials; keep provider adapter swappable last-mile.

---

## 25. Plan Validation Checklist

- [x] Referenced existing files/classes verified under `lib/features/hero_story/**` and `lib/app/app_composition_root.dart`
- [x] Plan reuses `StoryTranscriptionPort` / `TranscribeStoryRepresentationUseCase` (does not bypass ports)
- [x] HS.10 owner persistence/UI behavior verified (`FileStoryRepository`, My Stories, Owned Detail)
- [x] HS.9 recording/media behavior verified (`DeviceRecordingPort`, `StoryMediaStoragePort`, durable media)
- [x] Consent model verified (`StoryConsent` + use-case enforcement in transcription)
- [x] Plan does not overwrite original recordings
- [x] Plan keeps production AI secrets out of the Flutter client
- [x] Tests follow existing `test/features/hero_story/` conventions
- [x] Distinguishes HS.11 MVP transcription from future understanding/authoring platform work
- [x] Notes HS.4 already implemented foundational AI domain — HS.11 productionizes and surfaces it

---

## 26. Documentation Drift Noted (not fixed here)

- `AGENTS.md` still frames HS.1 as next phase (HS.1–HS.10 exist).
- `aggregate-map.md`, `use-case-map.md`, `event-flow.md`, `repository-map.md`, `domain-glossary.md` omit or under-specify Hero & Story / HS.4–HS.10.
- `architecture-drift.md` is Life Journey–centric.
- Earlier HS.10 investigation doc status line (“NO IMPLEMENTATION”) is stale relative to PR #28.

These are reported only; reconciling maps is out of scope for this planning deliverable.

---

## Final Principle Recap

> **AI may help tell the story. It does not own the story.**

HS.11 should connect the Hero’s durable original recording to a consent-gated, replaceable transcription port, persist the transcript as a derived representation with provenance, and give the Hero clear authority to review it — without collapsing the representation chain or smuggling provider SDKs into the domain.
