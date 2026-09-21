# SB.5 — Story Builder Persistence

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-5-story-builder-persistence-df8b`  
**Baseline:** SB.1–SB.4; suite was **875/875** after SB.4  
**Report path:** `docs/analysis/SB-5-story-builder-persistence.md`

---

## 1. Objective

SB.5 makes `StoryBuilderSession` durable across application restarts using the existing Hero & Story file-persistence infrastructure (HS.9).

A Hero who starts a Story Builder session, answers questions, pauses or leaves, and later returns can recover the same session with responses, intent, presented prompts, timestamps, and lifecycle status intact.

This slice is **persistence only** — not Story Builder resume UX (SB.6), Story creation, or AI.

---

## 2. Existing Persistence Architecture

Discovered and reused:

| Component | Path | Role |
|-----------|------|------|
| `FileHeroRepository` / `FileStoryRepository` | `infrastructure/repositories/` | Lazy cache + `{root}/{aggregate}/{id}.json` |
| `HeroSnapshotMapper` / `StorySnapshotMapper` | `infrastructure/persistence/` | Domain ↔ JSON; public constructors on load |
| `HeroStoryDurablePersistence` | `application/providers/persistence/` | Composes durable adapters from storage root |
| `AppCompositionRoot` | `lib/app/` | Overrides providers with durable adapters on native |
| Temp-dir test pattern | `test/.../file_*_repository_test.dart` | `Directory.systemTemp.createTempSync(...)` |

Conventions reused:

* Storage root: `getApplicationDocumentsDirectory()/hero_story`
* Files: `{id}.json` under an aggregate subdirectory
* Enum serialization: `.name`
* Dates: ISO-8601
* Writes: `writeAsString(..., flush: true)` (no temp+rename atomicity)
* Missing `findById`: returns `null`
* Domain stays free of `dart:io`

**Not introduced:** Hive, SQLite, Isar, SharedPreferences, or any new persistence package.

---

## 3. Files Changed

### Added

| File | Purpose |
|------|---------|
| `lib/features/hero_story/infrastructure/persistence/story_builder_session_snapshot_mapper.dart` | Serialize/deserialize `StoryBuilderSession` |
| `lib/features/hero_story/infrastructure/repositories/file_story_builder_session_repository.dart` | Durable `StoryBuilderSessionRepository` |
| `test/.../persistence/story_builder_session_snapshot_mapper_test.dart` | Serialization round-trip + malformed data |
| `test/.../repositories/file_story_builder_session_repository_test.dart` | File repo save/load/restart/errors |
| `test/.../use_cases/story_builder_session_persistence_integration_test.dart` | Use case → disk → reload → SB.4 structure |
| `docs/analysis/SB-5-story-builder-persistence.md` | This report |

### Modified

| File | Purpose |
|------|---------|
| `lib/.../persistence/hero_story_persistence_providers.dart` | Expose `FileStoryBuilderSessionRepository` on durable composition |
| `lib/app/app_composition_root.dart` | Override `storyBuilderSessionRepositoryProvider` when durable |
| `lib/.../repositories/story_builder_session_repository_provider.dart` | Document in-memory default vs durable override |

---

## 4. Serialization Model

Persisted fields (canonical aggregate only):

```text
StoryBuilderSession JSON
├── id
├── heroId
├── status          (inProgress | paused | completed | abandoned)
├── mode            (guided | ai)
├── intent
│   ├── purpose?    (enum.name or null; notSureYet preserved)
│   ├── themes[]    (enum.name; insertion order)
│   └── themesUnsure
├── storyId?        (optional link only — does not create Story)
├── prompts[]
│   ├── id, text, ordinal, narrativeRole?, isOptional
├── responses[]
│   ├── id, promptId, ordinal, text?, skipped, createdAt, updatedAt?
├── createdAt
└── updatedAt
```

**Not persisted:**

* `DeterministicStoryStructure` / sections / `sourceResponseIds` projection
* `StoryBuilderProgress` (derived from prompts/responses)
* Domain events

On load, the mapper reconstitutes via the public `StoryBuilderSession(...)` constructor (no factory events).

---

## 5. Repository Design

```text
StoryBuilderSessionRepository  (domain port — unchanged API)
        │
        ├── InMemoryStoryBuilderSessionRepository  (default provider / tests)
        └── FileStoryBuilderSessionRepository      (durable production)
                ↓
        {root}/story_builder_sessions/{sessionId}.json
```

Existing repository methods are implemented:

* `save` / `findById` / `exists` / `delete`
* `findByHeroId` / `findResumableByHeroId` / `findByHeroIdAndStatus`

`listForHero` was **not** added — `findByHeroId` / `findResumableByHeroId` already cover resume listing needs without speculative APIs.

Use cases from SB.1 already call `repository.save` after every mutation; no use-case changes were required.

Production wiring:

```text
AppCompositionRoot (durable)
  → HeroStoryDurablePersistence.storyBuilderSessionRepository
  → override storyBuilderSessionRepositoryProvider
```

Web / in-memory composition keeps the default in-memory provider (no filesystem).

---

## 6. Schema / Versioning

**Decision:** No `schemaVersion` field.

Reason: Existing HS Hero/Story file mappers also omit schema versions. SB.5 follows that convention rather than inventing a migration framework.

Malformed or unrecognized enum values throw `FormatException` during deserialization — they are **not** silently coerced to current defaults.

---

## 7. Error Handling

| Case | Behavior |
|------|----------|
| Missing session | `findById` → `null` (established repository convention) |
| Malformed JSON | `FormatException` during `_ensureLoaded` / mapper — no partial session |
| Invalid types / missing required fields | `FormatException` from mapper |
| Unsupported enum name | `FormatException` (via `byName` wrapped) |
| Empty/corrupt file body | Fail load; do not invent an empty session |

Matches `FileStoryRepository` fail-hard loading (no silent skip of corrupt aggregate files).

---

## 8. Canonical vs Derived State

> **`StoryBuilderSession` is the canonical persisted aggregate. `DeterministicStoryStructure` remains derived and is not persisted.**

After reload:

```text
load StoryBuilderSession
        ↓
reconstruct aggregate
        ↓
DeterministicStoryStructureBuilder.build(session)  // on demand
```

### Cursor / progress decision

Progress (`StoryBuilderProgress.currentPromptOrdinal`) is **derived** from presented prompts — not a separate persisted cursor.

Resume position after restart:

1. Persisted prompts + responses reconstruct what was already asked/answered.
2. `DeterministicStoryBuilderQuestionStrategy` selects the next unanswered catalog prompt.

No redundant cursor field was added to the domain model.

---

## 9. Provenance

Response IDs are serialized as stable string values and restored unchanged.

Integration test flow:

```text
answer A, skip B, answer C, edit A
→ persist → new FileStoryBuilderSessionRepository
→ reload
→ BuildDeterministicStoryStructureUseCase
```

Verifies:

* `responseA.id` / `responseB.id` / `responseC.id` survive
* Structure `sourceResponseIds` still reference those same IDs
* Structure before persist equals structure after reload

This protects the SB.4 provenance model.

---

## 10. Testing

### Focused SB.5 tests

```bash
flutter test \
  test/features/hero_story/infrastructure/persistence/story_builder_session_snapshot_mapper_test.dart \
  test/features/hero_story/infrastructure/repositories/file_story_builder_session_repository_test.dart \
  test/features/hero_story/application/use_cases/story_builder_session_persistence_integration_test.dart
```

**Result: 22/22 passed**

Coverage includes:

* Complete / minimal / intent / themes / uncertainty round trips
* Response ID + skip + edit survival
* Lifecycle: inProgress, paused, completed, abandoned
* Missing session, overwrite, process restart
* Malformed JSON / incomplete object
* Use-case → durable repo → reload → SB.4 structure parity
* DeterministicStoryStructure keys absent from JSON

### Full suite

```bash
flutter test
```

**Result: 897/897 passed** (baseline after SB.4 was **875/875**; delta is the **22** new SB.5 tests).

### Analyzer

```bash
dart analyze
```

* SB.5 changed files: **No issues found**
* Workspace: **0 errors**; pre-existing warnings/infos only (e.g. `prefer_initializing_formals`, `unawaited_return_in_try_block`) — none introduced by SB.5.

---

## 11. Architectural Decisions

1. **Reuse HS.9 file layout** under `hero_story/story_builder_sessions/` — no parallel storage hierarchy.
2. **Infrastructure mapper, not domain `toJson`** — domain remains persistence-agnostic.
3. **No schemaVersion** — match Hero/Story; document rather than invent migrations.
4. **No atomic temp+rename** — match existing `flush: true` overwrite convention.
5. **Keep in-memory default provider** — tests stay filesystem-free; durable only via composition override.
6. **Do not persist derived structure** — regenerate via SB.4 builder after load.
7. **Do not persist a cursor** — prompts + responses + question strategy suffice for resume.
8. **No Story creation on complete** — deferred (SB.0 product decision remains).
9. **No AI** — persistence works fully offline.

---

## 12. Deferred Work

| Item | Slice |
|------|-------|
| Mode selection / resume discovery UI ("My Stories") | SB.6 |
| AI Story Coach | SB.7+ |
| Story creation from completed session | Later product decision |
| Atomic write framework (temp + rename) | Optional HS persistence hygiene |
| Schema versioning / migrations | Only if HS Hero/Story adopt it |
| Resume UX navigation flow | SB.6 |

---

## Definition of Done Checklist

* [x] `StoryBuilderSession` durably persisted
* [x] Reconstructable after repository recreation
* [x] Meaningful aggregate state survives
* [x] Response IDs unchanged across round trip
* [x] SB.4 structure regenerates correctly after reload
* [x] Intent survives exactly (including uncertainty)
* [x] Lifecycle state survives
* [x] Missing/corrupt data handled safely
* [x] Existing HS persistence infrastructure reused
* [x] No new DB/storage framework
* [x] `DeterministicStoryStructure` not persisted
* [x] No Story created
* [x] No AI involved
* [x] In-memory testing remains possible
* [x] Focused tests pass (22/22)
* [x] Report written at this path
