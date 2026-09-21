# SB.2 — Story Intent / Type

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-2-story-intent-1684`  
**Baseline:** SB.1 foundation (`docs/analysis/SB-1-story-builder-foundation.md`); suite was **840/840**  
**Inspected main:** `a94633a` (SB.1 merged)

---

## 1. Executive summary

SB.2 replaces SB.1’s free-form string intent capacity with **typed, session-local purpose and theme vocabulary** on `StoryBuilderSession`.

Implemented:

- `StoryBuilderPurpose` enum (why the Hero is telling the story, including `notSureYet`)
- `StoryBuilderTheme` enum (what kind of story; multi-select)
- Typed `StoryBuilderIntent` value object
- Independent `setPurpose` / `setThemes` on the session (and matching use cases)
- Persistence coverage through the existing in-memory repository
- Focused tests for separation, editing, lifecycle, and save/load

**Not** implemented: UI, deterministic questions, AI, file persistence, Story catalog apply, events for intent changes.

---

## 2. Purpose vs Type

| Dimension | Question | Representation |
|-----------|----------|----------------|
| **Purpose** | Why tell this story? | Single `StoryBuilderPurpose?` |
| **Theme / type** | What kind of story is it? | Zero or more `StoryBuilderTheme` |

These stay independent: changing purpose does not change themes, and vice versa.

Unset purpose (`null`) ≠ intentional uncertainty (`StoryBuilderPurpose.notSureYet`).  
Themes use either a selected list **or** `themesUnsure: true` (mutually exclusive).

Builder intent remains **session metadata**. It does not write `StoryClassification` or Discovery `NarrativeTheme` entities.

---

## 3. Vocabulary

### Purpose (`StoryBuilderPurpose`) — implemented

| Value | Meaning |
|-------|---------|
| `inspireSomeone` | Inspire someone |
| `encourageSomeone` | Encourage someone |
| `helpSomeoneFeelLessAlone` | Help someone feel less alone |
| `preserveAMemory` | Preserve a memory |
| `honorSomeone` | Honor someone |
| `shareALesson` | Share something learned |
| `helpSomeoneFacingSomethingSimilar` | Help someone facing something similar |
| `simplyTellMyStory` | Simply tell my story |
| `notSureYet` | Intentional “I’m not sure yet” |

### Themes (`StoryBuilderTheme`) — implemented

| Value |
|-------|
| `overcomingAdversity` |
| `courage` |
| `service` |
| `leadership` |
| `loss` |
| `failure` |
| `transformation` |
| `perseverance` |
| `secondChances` |
| `sacrifice` |
| `family` |
| `discovery` |
| `purpose` |
| `love` |

### Deferred / excluded

| Item | Status |
|------|--------|
| Mapping Builder themes → Discovery `NarrativeThemeId` | Deferred (SB.8+ / Understanding apply) |
| Mapping to authoritative `StoryClassification` | Deferred |
| Free-form custom purpose/theme strings | Excluded (typed vocab preferred for SB.3) |
| Localization of display labels | Deferred (no UI yet; enums are domain keys) |
| DB-backed configurable vocabulary | Excluded (overbuilt for current product) |
| AI theme detection | Excluded (SB.7/SB.8) |

---

## 4. Domain model

```text
StoryBuilderSession
  └── StoryBuilderIntent
        ├── StoryBuilderPurpose? purpose
        ├── List<StoryBuilderTheme> themes   (deduped, ordered)
        └── bool themesUnsure
```

Aggregate methods:

- `setIntent(StoryBuilderIntent)` — full replace (SB.1)
- `setPurpose(StoryBuilderPurpose?)` — purpose only
- `setThemes({themes, themesUnsure})` — themes only

No new aggregate. No intent data on `Story`.

---

## 5. Behavior

| Operation | Editable statuses | Notes |
|-----------|-------------------|-------|
| Select / change purpose | `inProgress`, `paused` | `null` clears purpose |
| Select / change themes | `inProgress`, `paused` | Multi-select; duplicates removed |
| Themes unsure | `inProgress`, `paused` | Requires empty theme list |
| Modify after `completed` / `abandoned` | Rejected | `StateError` (SB.1 lifecycle) |

Changing intent does **not** regenerate prompts (question engine is SB.3/SB.7).

No new domain events for intent updates (application save/load is sufficient; no reactors need intent churn).

---

## 6. Persistence

Still in-memory only (SB.5 for File adapter).

Verified: create → set purpose/themes → save → load → same values; purpose update does not wipe themes.

---

## 7. Architecture (feeds SB.3 / SB.7)

```text
StoryBuilderSession.intent
        │
        ├── SB.3 Deterministic strategy may branch on purpose/themes
        └── SB.7 AI coach may use purpose/themes as context
```

Neither strategy owns the vocabulary. Both read the same session intent. Deterministic path needs no AI infrastructure.

---

## 8. Decisions

| Decision | Choice | Alternative considered |
|----------|--------|------------------------|
| Vocabulary form | Domain enums | Free-form strings (SB.1) — too weak for SB.3; DB config — overbuilt |
| Multiple themes | Yes | Single theme enum — too limiting per SB.0 |
| Purpose “not sure” | Enum value `notSureYet` | Separate bool — redundant with typed purpose |
| Themes “not sure” | `themesUnsure` flag | Fake theme enum — would pollute multi-select |
| Independent setters | `setPurpose` / `setThemes` use cases | Only full `setIntent` — risks accidental clobbering |
| Events on intent change | None | Updated event — no consumer yet |
| Catalog coupling | None | Immediate `NarrativeThemeId` — premature |

---

## 9. Tests

| Suite | Result |
|-------|--------|
| Focused SB.2 + related SB.1 + `ai_boundary` | **30/30 passed** |
| `flutter analyze` (SB.2 surfaces) | No errors; existing-style `prefer_initializing_formals` infos on aggregate |
| Full `flutter test` | **851/851 passed** (baseline was 840/840) |

### Test files

- `test/.../domain/value_objects/story_builder_intent_test.dart` (new)
- `test/.../application/use_cases/story_builder_intent_use_cases_test.dart` (new)
- Updates to session / repository / use-case tests for typed vocabulary

---

## 10. Deferred work

| Slice | Item |
|-------|------|
| SB.3 | Deterministic question catalog using purpose/themes |
| SB.4 | Section structure |
| SB.5 | File persistence of typed intent |
| SB.6 | Mode selection UI (and later purpose/theme UI) |
| SB.7 | AI coach consuming intent as context |

---

## 11. Open questions

| Question | Notes |
|----------|-------|
| Display copy / localization for enum values | Needed when UI ships; domain keeps stable keys |
| Whether SB.3 should hard-branch prompts per purpose | Product decision inside SB.3 |
| Exact mapping table to Discovery themes | Deferred until Understanding apply |

No blockers for SB.3.

---

## 12. Recommended next slice

**SB.3 — Deterministic Story Builder**
