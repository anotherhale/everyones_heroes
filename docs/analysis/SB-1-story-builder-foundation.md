# SB.1 — Story Builder Foundation

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-1-story-builder-foundation-1684`  
**Baseline:** [`docs/analysis/SB-0-story-builder-master-plan.md`](SB-0-story-builder-master-plan.md)  
**Inspected main:** `e2eb2f8` (SB.0 merged)

Legend: **FACT** / **RECOMMENDATION** / **FUTURE**

---

## 1. Executive summary

SB.1 delivers an **AI-agnostic, durable Story Builder session foundation** inside the existing Hero & Story feature module.

Implemented:

- `StoryBuilderSession` aggregate with lifecycle, intent slots, prompts, responses, progress
- Hero-authored `StoryBuilderResponse` source material (exact text preserved; stable IDs for future section maps)
- `StoryBuilderQuestionStrategy` port (abstraction only — no guided catalog, no AI)
- `StoryBuilderSessionRepository` + in-memory adapter
- Application use cases for start / present / answer / skip / edit / intent / pause / resume / complete / abandon / get
- Minimal Riverpod providers
- Focused domain, repository, use-case, and strategy-boundary tests

**Not** implemented (by design): deterministic question sequence, AI coach, AI credits, File persistence, Story materialization on complete, Builder UI, Story Understanding/Authoring glue.

Success criterion met: both future Guided Builder (SB.3) and AI Story Coach (SB.7) can share one session model without competing pipelines or AI hard-dependencies.

---

## 2. Architecture

```text
Presentation (deferred SB.3/SB.6/SB.13)
        │
Application use cases + StoryBuilderQuestionStrategy port
        │
StoryBuilderSession  (NEW — JUSTIFIED, AI-agnostic)
        │
Story Material (responses on session)
        │
        └──▶ existing Story / Understanding / Authoring  (later slices)
```

### Fit vs CaptureSession

| Concern | Capture / recording | Story Builder |
|---------|---------------------|---------------|
| Domain type | **None** (HS-ADR-018/060) | `StoryBuilderSession` aggregate |
| Purpose | Device media capture | Guided Q&A / story drafting |
| Persistence | Completion store + Story on Accept | Session repository (in-memory in SB.1) |
| AI | Post-capture optional | Optional strategy later |

Recording and Builder remain independent entry paths that converge later on `Story` + representations.

---

## 3. Model

### 3.1 `StoryBuilderSession`

| Field | Notes |
|-------|-------|
| `StoryBuilderSessionId` | Stable identity |
| `HeroId` | Owner |
| `StoryId?` | Optional link only — **does not create Story** (SB.0 default) |
| `StoryBuilderMode` | `guided` \| `ai` (metadata; no AI behavior) |
| `StoryBuilderSessionStatus` | `inProgress` → `paused` ↔ `inProgress` → `completed` \| `abandoned` |
| `StoryBuilderIntent` | Purpose/themes capacity (SB.2 vocabulary later) |
| `prompts[]` | Presented prompts |
| `responses[]` | Hero-authored / skipped entries |
| `createdAt` / `updatedAt` | Timestamps |

### 3.2 Response / source material

`StoryBuilderResponse`:

- Stable `StoryBuilderResponseId`
- Links to `StoryBuilderPromptId`
- Ordinal preserved
- Exact `text` (no rewrite/summary)
- `skipped` without inventing text
- `updatedAt` when edited (identity preserved)

### 3.3 Lifecycle

```text
inProgress ──pause──▶ paused ──resume──▶ inProgress
    │                    │
    └──────── complete / abandon ────────▶ terminal
```

Terminal sessions reject mutations (`StateError`).

### 3.4 Purpose / type handling

`StoryBuilderIntent` holds optional purpose string, theme labels, and “unsure” flags. Session-local only — does **not** apply to `StoryClassification` or Discovery `NarrativeTheme` entities. SB.2 will refine vocabulary/UX.

### 3.5 Persistence boundary

`StoryBuilderSessionRepository`:

- `save` / `findById` / `exists` / `delete`
- `findByHeroId` / `findResumableByHeroId` / `findByHeroIdAndStatus`

SB.1 ships `InMemoryStoryBuilderSessionRepository` + Riverpod provider. File adapter deferred to SB.5.

---

## 4. Strategy boundary

```text
StoryBuilderQuestionStrategy  (domain/services port)
        ├── (SB.3) Deterministic static catalog
        └── (SB.7) AI adaptive coach
                │
                ▼
        presentPrompt → answer/skip on StoryBuilderSession
```

Port methods:

- `nextPrompt(session)`
- `isQuestioningComplete(session)`

Domain session never imports AI/HTTP. SB.1 includes **no** production strategy implementation. Tests use a fixed non-AI strategy to prove agnosticism.

---

## 5. Decisions (following SB.0)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Session vs CaptureSession | New domain aggregate | Durable Q&A ≠ ephemeral recording |
| Story creation timing | No Story on start/complete in SB.1 | SB.0 default: create draft Story at Complete/Save in later slice |
| Events | `Created` + `Completed` only | Avoid proliferation; match create/publish convention; no reactors yet |
| Intent | Minimal VO capacity | Enables SB.2 without blocking foundation |
| Strategy location | Domain port (like Understanding/Authoring) | Matches HS port placement |
| Persistence | In-memory first | Matches StoryUnderstanding / early HS testing pattern |
| UI | None | Foundation slice only |

### Event justification

| Event | Why | Consumer in SB.1 |
|-------|-----|------------------|
| `StoryBuilderSessionCreated` | Create→publish EventBus consistency | None (store only) |
| `StoryBuilderSessionCompleted` | Meaningful completion fact for later materialization | None yet |

No `Updated` event: would churn on every keystroke-level save.

---

## 6. Existing vs new

| Concept | Classification |
|---------|----------------|
| `Story` / `Hero` / representations / consent / provenance | EXISTING — REUSE (unchanged) |
| EventBus publish-after-save / `UseCase` / `Result` | EXISTING — REUSE |
| `AggregateType` | EXISTING — EXTEND (`storyBuilderSession`) |
| `domain.dart` barrel | EXISTING — EXTEND |
| Riverpod repository/use-case provider pattern | EXISTING — REUSE |
| CaptureSession domain type | NOT CURRENTLY PRESENT (by design) |
| `StoryBuilderSession` + related VOs/enums/IDs | NEW — JUSTIFIED |
| `StoryBuilderQuestionStrategy` | NEW — JUSTIFIED |
| `StoryBuilderSessionRepository` + in-memory | NEW — JUSTIFIED |
| Builder use cases + providers | NEW — JUSTIFIED |
| File session repository | NOT CURRENTLY PRESENT (SB.5) |
| Deterministic prompt catalog | NOT CURRENTLY PRESENT (SB.3) |
| AI coach / credits | NOT CURRENTLY PRESENT (SB.7 / Identity) |

---

## 7. Files added/changed (summary)

**Added (domain):** IDs, enums, VOs, aggregate, events, repository interface, question strategy port  
**Added (application):** request DTOs, use cases, providers  
**Added (infrastructure):** `InMemoryStoryBuilderSessionRepository`  
**Added (tests):** domain / strategy / repository / use-case tests  
**Added (docs):** this report  
**Changed:** `AggregateType`, `domain/domain.dart`

---

## 8. Tests

### Added

| File | Focus |
|------|-------|
| `test/.../domain/aggregates/story_builder_session_test.dart` | Create, intent, answer/edit, skip, order, pause/resume, complete/abandon, invalid transitions |
| `test/.../domain/services/story_builder_question_strategy_test.dart` | Non-AI strategy against session |
| `test/.../infrastructure/repositories/in_memory_story_builder_session_repository_test.dart` | Save/load/update/resumable/delete |
| `test/.../application/use_cases/story_builder_session_use_cases_test.dart` | End-to-end use-case orchestration |

### Results (executed)

| Check | Result |
|-------|--------|
| Focused SB.1 + `ai_boundary_test` | **20/20 passed** |
| `flutter analyze` (hero_story + SB.1 IDs) | No errors; existing-style `prefer_initializing_formals` infos only (same pattern as `StoryUnderstanding`) |
| Full `flutter test` | **840/840 passed** |

### Analyzer notes

Initial `prefer_initializing_formals` infos aligned to existing `CreateHeroUseCase` `this._` style. Domain/application remain free of AI SDK / HTTP imports (`ai_boundary_test` green).

---

## 9. Deferred work

| Slice | Deferred item |
|-------|---------------|
| SB.2 | Purpose/type vocabulary, UX, persistence of curated choices |
| SB.3 | Deterministic question catalog + guided strategy implementation |
| SB.4 | Deterministic section map (response ID references) |
| SB.5 | File repository, durable resume UX, optional Story link timing |
| SB.6 | Mode selection product UI |
| SB.7 | AI question strategy + proxy + credits gate |
| SB.8–SB.13 | Understanding extensions, shaping, approval, representations, moments, Tell Your Story hub |

Also deferred: reactors for Builder events; creating `Story` / `written` representation from session material.

---

## 10. Risks / open questions

| Item | Status |
|------|--------|
| When Complete should create `Story` | Still open (SB.0 §16); SB.1 preserves “not yet” |
| Mid-session Guided↔AI switch UX | Model allows `setMode`; product later |
| File persistence before SB.5 | Sessions lost on process restart (acceptable for foundation) |
| Intent equality nested-list matcher quirk | Tests assert fields; VO equality may need SB.2 polish |

No hard architecture conflict discovered vs SB.0 or HS-ADRs.

---

## 11. Recommended next slice

**SB.2 — Story Intent / Type** (purpose & themes on the session), then **SB.3 — Deterministic Story Builder**.

Do not start SB.7 until SB.3 proves a complete zero-AI path.
