# SB.4 — Deterministic Story Structure

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-4-deterministic-story-structure-1684`  
**Baseline:** SB.1–SB.3; suite was **859/859**  
**Report path:** `docs/analysis/SB-4-deterministic-story-structure.md`

---

## 1. Executive Summary

SB.4 establishes an explicit **deterministic narrative structure** derived from a `StoryBuilderSession`'s Hero-authored responses.

```text
StoryBuilderSession
   ↓
DeterministicStoryStructure
```

The structure identifies **where each piece of Hero-authored material belongs** in the narrative arc. It does **not** author prose, invoke AI, create a `Story`, or rewrite responses.

Canonical source material remains the session responses. Structure is a **derived view** regenerated on demand via `BuildDeterministicStoryStructureUseCase`.

---

## 2. Structure Model

| Type | Layer | Role |
|------|-------|------|
| `DeterministicStoryStructureSection` | Domain VO | One ordered section: role, order, promptId, sourceResponseIds, wasSkipped |
| `DeterministicStoryStructure` | Domain VO | Session-scoped ordered sections + intent snapshot |
| `DeterministicStoryStructureBuilder` | Domain service | Pure catalog → section mapping |
| `BuildDeterministicStoryStructureUseCase` | Application | Load session, validate lifecycle, return derived structure |
| `BuildDeterministicStoryStructureRequest` | Application DTO | `sessionId` only |

```text
DeterministicStoryStructure
├── sessionId
├── intent (purpose/themes metadata; does not branch structure)
└── sections[]
    ├── narrativeRole   (StoryBuilderNarrativeRole)
    ├── order
    ├── promptId
    ├── sourceResponseIds[]
    └── wasSkipped
```

**Not a Story aggregate.** No second enum (`StorySection`, etc.) — reuses `StoryBuilderNarrativeRole`.

Descriptive completeness counters only:

* `populatedSectionCount` — answered (non-skip) material present
* `skippedSectionCount` — explicitly skipped
* `emptySectionCount` — no response yet

No quality, inspiration, or confidence scores.

---

## 3. Narrative Mapping

Reuse of SB.3 `StoryBuilderNarrativeRole` ↔ catalog prompts:

| Order | Role | Prompt ID |
|------:|------|-----------|
| 0 | beginning | `sb.q.beginning` |
| 1 | challenge | `sb.q.challenge` |
| 2 | importance | `sb.q.importance` |
| 3 | struggle | `sb.q.struggle` |
| 4 | stakes | `sb.q.stakes` |
| 5 | turningPoint | `sb.q.turningPoint` |
| 6 | decision | `sb.q.decision` |
| 7 | action | `sb.q.action` |
| 8 | outcome | `sb.q.outcome` |
| 9 | reflection | `sb.q.reflection` |
| 10 | message | `sb.q.message` |

Mapping is 1:1 with the deterministic catalog. No semantic inference. Intent/themes do not alter section order or membership.

---

## 4. Provenance

Each section references **response IDs**, not copied text:

```text
StoryBuilderSession
  → StoryBuilderPrompt (stable promptId + narrativeRole)
  → StoryBuilderResponse (id)
  → DeterministicStoryStructureSection.sourceResponseIds
```

* Answered → `sourceResponseIds = [responseId]`, `wasSkipped = false`, `hasSourceMaterial = true`
* Skipped → `sourceResponseIds = [skipResponseId]`, `wasSkipped = true`, `hasSourceMaterial = false` (skip identity preserved for provenance)
* Unanswered → empty `sourceResponseIds`, not skipped

Edits preserve response identity (`editResponse` keeps the same ID), so rebuilds remain correct without stale text copies.

HS.1 Story provenance is not duplicated here — structure provenance is session/prompt/response/role linkage, which is sufficient for SB.4.

---

## 5. Optional / Missing Material

All SB.3 prompts remain optional. Gaps are first-class:

| State | Representation |
|-------|----------------|
| Answered | Populated section with response ID |
| Skipped | Skipped section with skip response ID; no fabricated text |
| Not yet answered | Empty section slot (still present at its order) |

Structure always contains **11 ordered slots** so missing material is visible rather than collapsed.

---

## 6. Derived vs Persisted

**Decision: derived, not persisted.**

Rationale:

* Canonical source is `StoryBuilderSession.responses`
* Structure can be regenerated cheaply and deterministically
* Avoids stale structure after edits
* No demonstrated need for durability at SB.4

Use case loads the session and returns the structure; it does **not** save a structure repository entry.

---

## 7. AI Boundary

SB.4 is entirely AI-free:

* No OpenAI / Anthropic / HTTP client imports in structure files
* No embeddings, semantic similarity, or LLM classification
* No network or credit consumption

Verified by `deterministic_story_structure_ai_independence_test.dart`.

SB.4 knows only:

> "The Hero answered/skipped the `struggle` prompt, so this response belongs under Struggle."

It does **not** attempt to discover additional turning points, rewrite voice, or judge quality.

---

## 8. Story Understanding Boundary

| SB.4 Deterministic Structure | Future AI Story Understanding |
|------------------------------|-------------------------------|
| Maps known questionnaire roles | May find narrative elements not captured by prompts |
| Role comes from catalog | Role/content may be inferred |
| No AI | May use AI behind ports |
| Baseline | Adaptive overlay |

Do not collapse these capabilities.

---

## 9. Story Authoring Boundary

SB.4 does **not** generate narrative prose.

Hero text such as *"I was terrified, but I decided to keep going."* remains referenced under Decision/Action as authored.  
It is **not** rewritten into literary narrative. That belongs to future Story Authoring after Hero approval.

---

## 10. Lifecycle

| Session status | Structure generation |
|----------------|----------------------|
| inProgress | Allowed (partial/empty OK) |
| paused | Allowed |
| completed | Allowed |
| abandoned | **Rejected** |

Missing session → Failure. No Story is created.

---

## 11. UI

**No new Story Structure screen.** SB.4 is domain/application only.  
`buildDeterministicStoryStructureUseCaseProvider` is wired for later consumers.

---

## 12. Tests

### Analyzer (SB.4 files)

```text
dart analyze <SB.4 domain/application files>
No issues found!
```

### Focused SB.4 tests

```text
flutter test \
  test/features/hero_story/domain/services/deterministic_story_structure_builder_test.dart \
  test/features/hero_story/application/use_cases/build_deterministic_story_structure_use_case_test.dart \
  test/features/hero_story/architecture/deterministic_story_structure_ai_independence_test.dart

16/16 passed
```

Coverage includes: all 11 role mappings, stable ordering, provenance, skips, edits, partial/empty/completed sessions, abandoned rejection, missing session, non-persistence, AI independence.

### Full suite

*(Filled after `flutter test` completes for this branch.)*

---

## 13. Deferred Work

* SB.5 file persistence
* SB.6 mode selection/UI
* SB.7 AI Story Coach
* Story Understanding
* Story Authoring
* Hero Approval
* Story creation from Builder
* Hero Moments
* Compilation pipeline
* Structure presentation UI
* Intent/theme-based structure branching (explicitly out of scope)

---

## 14. Open Questions

None blocking SB.4. Optional later product choices (not required here):

* Whether a future read-only structure preview should appear before Complete/Save
* Whether skip provenance should remain response-ID-based once Story Understanding starts annotating sections

---

## 15. Scope Guard (met)

> A StoryBuilderSession's Hero-authored responses can be deterministically mapped into an explicit narrative structure with stable ordering and provenance, without AI, rewriting, or Story creation.
