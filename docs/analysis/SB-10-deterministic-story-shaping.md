# SB.10 — Deterministic Story Shaping

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/sb-10-deterministic-story-shaping-c946`  
**Baseline:** SB.9 Story Proposal Foundation on `main` @ `f12fd14`  
**Report path:** `docs/analysis/SB-10-deterministic-story-shaping.md`

---

## Purpose

Deterministic story shaping improves the **presentation** of an existing
`StoryProposal` without inventing facts or replacing Hero-authored wording.

Central principle:

> SB.10 may shape, organize, select, and tighten existing material, but it must
> not invent facts or silently replace Hero-authored content.

The resulting artifact remains a `StoryProposal`. SB.10 does **not** create a
`Story`.

---

## Relationship to SB.9 / SB.11

```text
SB.9  = Story Proposal foundation (build proposal from session)
SB.10 = Deterministic shaping of that proposal
SB.11 = Future AI shaping (same StoryProposal model; deferred)
```

Architecture:

```text
StoryBuilderSession
        ↓
DeterministicStoryStructure
        ↓
StoryBuilderUnderstanding
        ↓
StoryProposal                    ← SB.9
        ↓
StoryShaperPort
        ↓
DeterministicStoryShaper         ← SB.10
        ↓
StoryProposal (shaped)
```

Future:

```text
                         ┌──────────────────────────┐
                         │      StoryShaperPort     │
                         └────────────┬─────────────┘
                                      │
                     ┌────────────────┴────────────────┐
                     │                                 │
                     ▼                                 ▼
          DeterministicStoryShaper             AiStoryShaper
                    SB.10                            SB.11
```

SB.10 establishes only the port + deterministic implementation. No strategy
resolver yet — that can arrive with SB.11 if needed.

---

## Shaping rules

`DeterministicStoryShaper` is allowed to:

* Reorder sections into the canonical SB.4 narrative role order
* Rebuild `narrative` from populated sections only
* Omit empty / whitespace-only / skipped sections from narrative presentation
* Detect **exact** duplicates via normalized string equality and include the
  first occurrence only in the narrative
* Preserve an existing title (never invent one)
* Preserve an existing `derivedSummary` (never regenerate)
* Preserve proposal identity (`StoryProposalId`) and session provenance
* Update `provenance.processingVersion` to `sb10.deterministic.v1`
* Return lifecycle `readyForReview` (never `accepted`)

It is **not** allowed to:

* Paraphrase, polish, rewrite, summarize, or embellish Hero-authored content
* Invent facts, events, emotions, motivations, or quotes
* Write fictional transitions presented as fact
* Convert skipped responses into generated prose
* Call AI / network / proxies
* Mutate the source proposal or the Story Builder session
* Create, persist, publish, or catalog a `Story`

When in doubt, preserve the original material.

---

## Preservation rules

### Hero-authored content

If `contentOrigin == heroAuthored`, section `content` is copied **byte-for-byte**.
The shaper may move the section or omit it from narrative presentation when
empty/duplicate; it must not change the string.

### Source response IDs

Every shaped section retains its `sourceResponseIds`. Moving or reordering does
not drop provenance.

### Content origin

* Hero words remain `heroAuthored`
* Existing `derived` material remains `derived`
* SB.10 does not invent new Hero wording labeled as derived (or vice versa)

### Skipped responses

Skipped sections stay in the proposal model (`wasSkipped: true`, `content: null`,
source IDs retained). They are omitted from the assembled `narrative` and from
the review UI presentation list.

### Empty vs skipped

SB.9 always materializes the full SB.4 slot set. SB.10 keeps that inventory so
“skipped” and “never answered” remain distinguishable. Presentation omits both
from the narrative body.

---

## Narrative ordering

Canonical SB.3/SB.4 role order (enum declaration order):

```text
beginning
challenge
importance
struggle
stakes
turningPoint
decision
action
outcome
reflection
message
```

Populated sections are never reordered arbitrarily relative to this taxonomy.

---

## Duplicate handling

Conservative deterministic detection only:

1. Trim
2. Collapse internal whitespace to a single space
3. Lowercase
4. Exact equality of the normalized form

First occurrence (in canonical order) wins for narrative assembly. Later exact
duplicates are omitted from `narrative` but **remain** in `sections[]` with full
provenance.

Similar-but-not-identical text (e.g. “I was scared.” vs “I felt afraid.”) is
**not** treated as duplicate — both are preserved.

No semantic embeddings or speculative similarity.

### Multiple source responses

SB.9 typically maps one catalog prompt → one response per role. When a section
already joins multiple response texts, SB.10 preserves that joined content
verbatim and does not select among sources. Selection among competing Hero
answers is deferred unless a future proposal model defines it explicitly.

---

## Lifecycle

```text
shaped proposal → readyForReview
```

Rules:

* Input `draft` / `readyForReview` / `accepted` / `rejected` → output
  `readyForReview`
* Shaping never leaves the proposal in `accepted`
* Full Hero accept/reject workflow remains deferred

### Identity

SB.10 preserves the existing `StoryProposalId` (shaped revision of the same
proposal record). No separate versioning system is introduced. `createdAt` is
preserved; `updatedAt` reflects shaping time.

---

## Persistence

```text
load proposal → shape → save shaped proposal
```

Uses existing `StoryProposalRepository` + `StoryProposalSnapshotMapper`.
All SB.9 fields round-trip, including:

* proposal / session IDs
* title, narrative, intent
* sections (role, order, content, sourceResponseIds, skipped, contentOrigin)
* provenance (including updated `processingVersion`)
* lifecycle, timestamps, derivedSummary

---

## Application / UI

* Port: `StoryShaperPort`
* Implementation: `DeterministicStoryShaper`
* Use case: `ShapeStoryProposalUseCase` + `ShapeStoryProposalRequest`
* Providers: `storyShaperPortProvider`, `shapeStoryProposalUseCaseProvider`

UX (product language, not implementation jargon):

```text
Completed
    → Build Story Proposal
    → Deterministic shaping (automatic)
    → Review your story
```

Disclaimer:

> Shaping organizes your story using the material you provided. It does not add
> facts to your story.

Review UI shows presented (contentful) sections only. Skipped/empty slots remain
in the persisted model.

---

## AI boundary

> SB.10 does not use AI and does not require network connectivity.

* No OpenAI / Anthropic / provider SDKs in the shaper
* No AI proxy calls
* No credits
* Works offline when network / AI proxy / credits are unavailable

---

## Architectural invariants

| Invariant | Result |
|-----------|--------|
| Hero material remains canonical in `StoryBuilderSession` | Yes |
| `StoryProposal` remains derived | Yes |
| Shaper is not a new source of truth | Yes |
| AI-independent / offline | Yes |
| No `Story` created | Yes |
| Provenance survives | Yes — sessionId + sourceResponseIds + contentOrigin |
| No unsupported facts introduced | Yes |

---

## Deferred work

* AI Story Authoring / `AiStoryShaper` (SB.11)
* Richer prose transformation
* Hero editing on the proposal
* Approval workflow (product accept/reject)
* Story materialization from an accepted proposal
* Publishing / catalog integration
* AI credits
* Discovery `NarrativeThemeId` mapping
* `StoryShaperStrategyResolver` (optional with SB.11)
* Proposal versioning beyond overwrite-in-place shaping

---

## Files changed (summary)

### Domain
* `StoryShaperPort`
* `DeterministicStoryShaper`
* `StoryProposal.shapedProcessingVersion`

### Application
* `ShapeStoryProposalUseCase` + request DTO
* providers

### Presentation
* Build → shape → review on Story Builder screen
* Shaping disclaimer + content-only presentation

### Tests
* `sb10_deterministic_story_shaping_test.dart`
* `deterministic_story_shaper_ai_independence_test.dart`

### Docs
* this report

---

## Test results

| Suite | Result |
|-------|--------|
| Focused SB.10 (`sb10_deterministic_story_shaping_test` + AI independence) | **27/27 passed** |
| Full `flutter test` | **985/985 passed** (baseline 958 + 27 SB.10) |
| `dart analyze` (SB.10 surfaces) | **0 issues** |
