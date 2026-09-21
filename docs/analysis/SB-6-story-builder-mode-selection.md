# SB.6 — Story Builder Mode Selection & Resume

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-6-story-builder-mode-selection-470e`  
**Baseline:** SB.1–SB.5; suite was **897/897** after SB.5  
**Report path:** `docs/analysis/SB-6-story-builder-mode-selection.md`

---

## 1. Objective

SB.6 exposes Story Builder capabilities through product UX:

* **Mode selection** — Guided (complete, no-AI) vs AI (boundary only; SB.7)
* **Intent capture** — purpose (one) and themes (zero or more) before session creation
* **Durable session creation** with `mode` + `intent` via existing SB.5 persistence
* **Resume** of incomplete (`inProgress` / `paused`) sessions
* **Mode → strategy resolution** so Guided never silently shares an AI path

Central product principle:

> Everyone gets a complete Story Builder. AI makes the experience more adaptive, not more legitimate.

SB.6 does **not** implement the AI Story Coach.

---

## 2. Existing Architecture

Discovered and reused (code as source of truth):

| Component | Role |
|-----------|------|
| `StoryBuilderSession` + `StoryBuilderMode` | Single aggregate; mode is session metadata |
| `StartStoryBuilderSessionRequest.mode` | Already accepted mode at create |
| `StoryBuilderQuestionStrategy` port | SB.1; deterministic impl SB.3 |
| File + in-memory session repositories | SB.5 durable + test default |
| `findResumableByHeroId` | inProgress \| paused, newest first |
| Pause / Resume / Advance / Get use cases | Lifecycle already complete |
| `StoryBuilderController.resumeSession` | Existed but screen ignored `resumeSessionId` |
| Heroes → Build My Story CTA | Navigated straight into guided Builder |

**Gaps closed by SB.6:** mode-selection UI, intent UI, resume discovery surface, wire resume, mode-aware strategy resolution, explicit AI unavailable boundary.

---

## 3. Mode Model

```text
StoryBuilderMode
├── guided  → complete deterministic Builder (no AI, no credits, offline-capable)
└── ai      → session may store mode; strategy is explicit Unsupported placeholder until SB.7
```

There remains **one** `StoryBuilderSession` aggregate. No `GuidedStoryBuilderSession` / `AIStoryBuilderSession` split.

UI framing:

* **Guided Story Builder** — thoughtful step-by-step questions; complete; no AI required; works offline
* **AI Story Builder** — adaptive conversation (coming soon); option visible but disabled; does not fake AI

---

## 4. Strategy Resolution

```text
StoryBuilderMode
       │
       ▼
StoryBuilderQuestionStrategyResolver
       │
 ┌─────┴──────────────┐
 ▼                    ▼
Deterministic        UnsupportedAi
Strategy             Strategy (SB.7 replaces)
```

* `DefaultStoryBuilderQuestionStrategyResolver` — guided → `DeterministicStoryBuilderQuestionStrategy`; ai → `UnsupportedAiStoryBuilderQuestionStrategy`
* `AdvanceStoryBuilderUseCase` resolves strategy from **`session.mode`** (not a hard-coded guided strategy)
* AI strategy throws `UnsupportedError` with a clear message; Advance maps that to `Failure` (no LLM / network / credits)

---

## 5. Session Lifecycle

```text
Choose mode (Guided)
    ↓
Intent (purpose + themes)
    ↓
StartStoryBuilderSession (mode + intent) → persist
    ↓
Builder (advance / answer / skip)
    ↓
Pause / system back → paused, still resumable
    ↓
Resume → same session, same responses/IDs, strategy from mode
    ↓
Complete → not listed as draft
```

* Completed / abandoned sessions are **not** resume candidates
* Multiple incomplete sessions per Hero are preserved (repository already supports this)
* No Story is created on complete

---

## 6. Navigation

```text
Heroes → Build My Story
    ↓
StoryBuilderEntryScreen  (mode + resume list)
    ├─ Guided → StoryBuilderIntentScreen → StoryBuilderScreen(resumeSessionId)
    ├─ AI     → disabled / coming soon
    └─ Resume → StoryBuilderScreen(resumeSessionId)
```

* Uses existing `Navigator.push` / `MaterialPageRoute` (no new router)
* Back / Pause preserves the session (pauses when leaving mid-questioning)
* User is never trapped in Builder

---

## 7. AI Boundary

Deferred to **SB.7** (and later):

* LLM calls, adaptive questions, follow-ups
* AI story analysis / rewriting / coaching
* AI credits / provider selection / new proxy endpoints
* Story Understanding / Authoring from Builder

SB.6 only establishes the mode boundary and an explicit unavailable strategy/UI state.

---

## 8. Persistence

Reuses SB.5:

* `FileStoryBuilderSessionRepository` (production via `AppCompositionRoot`)
* In-memory default for tests
* Mode, intent, responses, response IDs, lifecycle survive save/load/resume

No new database or persistence package.

---

## 9. Testing

### Focused SB.6 tests

```bash
flutter test \
  test/features/hero_story/domain/services/story_builder_question_strategy_resolver_test.dart \
  test/features/hero_story/application/use_cases/sb6_mode_selection_and_resume_test.dart \
  test/features/hero_story/presentation/sb6_story_builder_mode_selection_ui_test.dart \
  test/features/hero_story/architecture/deterministic_story_builder_ai_independence_test.dart
```

**Result: 14/14 passed** (3 resolver + 5 application + 5 UI + 1 architecture)

Related regression in the same focused run (SB.3 UI, Advance, SB.5 persistence): **23/23** when those files are included.

Coverage includes:

* Guided vs AI mode selection / storage
* AI mode does not resolve to deterministic strategy
* Persist → reload keeps `mode == guided` (and AI mode metadata)
* Resume keeps responses + response IDs + intent + next question
* Completed sessions excluded from resume list
* Multiple resumable sessions preserved
* Heroes → entry navigation; pause leaves resumable draft
* Guided path independent of AI imports

### Full suite

```bash
flutter test
```

**Result: 910/910 passed** (baseline after SB.5 was **897/897**; delta is the **13** new SB.6 tests — architecture test already existed and was extended).

### Analyzer

```bash
dart analyze
```

* SB.6 changed files: **No issues found**
* Workspace: **0 errors**; pre-existing warnings/infos only (e.g. `prefer_initializing_formals`, `unawaited_return_in_try_block`) — none introduced by SB.6

---

## 10. Architectural Decisions

1. **Single session aggregate** — mode is a property, not a subtype.
2. **Explicit unsupported AI strategy** — never silently fall back to deterministic for AI mode.
3. **Advance resolves strategy from `session.mode`** — application does not hard-code Guided.
4. **AI option disabled in UI** — no fake coach; clear “Coming soon”.
5. **Intent before create** — purpose + themes captured, then `StartStoryBuilderSession` with intent.
6. **Resume via existing screen + controller** — wire `resumeSessionId`; no parallel Builder.
7. **Resume list on entry screen** — avoid inventing a full My Stories draft subsystem.
8. **No AI credit system** — Guided never depends on credits; credits remain unimplemented.
9. **Eager scroll content** — `SingleChildScrollView` + `Column` so mode/resume/intent widgets are always in the tree (testable; short forms).

---

## 11. Deferred Work

| Item | Slice |
|------|-------|
| AI Story Coach / adaptive questions | SB.7 |
| AI credits / availability gates | Later (with identity) |
| Story Understanding from Builder | SB.8 |
| AI story shaping / rewriting | SB.9 |
| Hero Approval | SB.10 |
| Tell Your Story hub consolidation | SB.13 |
| Reopen/edit completed Builder sessions | Not in scope (lifecycle respected) |
| Hybrid mid-session mode switch | Future (model supports `setMode`; UX not shipped) |

---

## 12. Files Added / Changed

### Added

| File | Purpose |
|------|---------|
| `domain/services/story_builder_question_strategy_resolver.dart` | Mode → strategy |
| `domain/services/unsupported_ai_story_builder_question_strategy.dart` | Explicit AI unavailable |
| `application/.../list_resumable_story_builder_sessions_*.dart` | Resume listing use case |
| `presentation/screens/story_builder_entry_screen.dart` | Mode + resume |
| `presentation/screens/story_builder_intent_screen.dart` | Purpose + themes |
| `presentation/models/story_builder_intent_labels.dart` | Display copy |
| `presentation/providers/resumable_story_builder_sessions_provider.dart` | Resume provider |
| Focused SB.6 tests | Resolver / use case / UI |
| `docs/analysis/SB-6-story-builder-mode-selection.md` | This report |

### Modified

| File | Purpose |
|------|---------|
| `advance_story_builder_use_case.dart` | Use strategy resolver from session mode |
| `story_builder_question_strategy_provider.dart` | Resolver provider |
| `story_builder_use_case_providers.dart` | Wire list + resolver |
| `story_builder_controller.dart` / `story_builder_screen.dart` | Mode, resume, unsupported phase |
| `hero_catalog_screen.dart` | Navigate to entry |
| Related tests | Constructor updates for resolver |

Work stops at SB.6.
