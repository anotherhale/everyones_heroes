# SB.9 — Story Proposal Foundation

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/sb-9-story-proposal-foundation-df8e`  
**Baseline:** SB.1–SB.8 on `main` @ `226a0d6`  
**Report path:** `docs/analysis/SB-9-story-proposal-foundation.md`

---

## Purpose

`StoryProposal` is a **derived, reviewable representation of a potential Story**
produced from a completed `StoryBuilderSession`.

It exists so later deterministic and AI shaping strategies can both target the
same proposal model without collapsing:

```text
StoryBuilderSession          = canonical Hero-authored Story Builder state
StoryBuilderUnderstanding    = derived interpretation of that state
StoryProposal                = derived candidate Story structure/content for review
Story                        = eventual canonical Story domain aggregate
```

SB.9 establishes the foundation only. It does **not** create or mutate a
`Story`, does **not** introduce AI authoring, and does **not** introduce credits.

---

## Boundary

```text
Hero-authored material
        ↓
StoryBuilderSession          (canonical; durable — SB.5)
        ↓
DeterministicStoryStructure  (derived — SB.4)
        ↓
StoryBuilderUnderstanding    (derived — SB.8)
        ↓
StoryProposal                ← SB.9
        ↓
Hero review / shaping        ← deferred
        ↓
Story materialization        ← deferred
        ↓
Story
```

### Hard rules

* `StoryProposal ≠ Story`
* `StoryProposal ≠ StoryBuilderSession`
* `StoryProposal ≠ StoryBuilderUnderstanding`
* Proposal generation never creates, saves, publishes, or catalogs a `Story`
* Proposal generation never mutates the canonical session

---

## Domain model

```text
StoryProposal
├── id                         (StoryProposalId — own identity)
├── sessionId                  (StoryBuilderSessionId provenance)
├── title?                     (StoryTitle; null when absent)
├── narrative?                 (assembled Hero-authored section text)
├── sections[]                 (StoryProposalSection)
├── intent                     (StoryBuilderIntent snapshot)
├── provenance                 (StoryProposalProvenance)
├── lifecycle                  (StoryProposalLifecycleStatus)
├── createdAt / updatedAt
└── derivedSummary?            (Understanding metadata only — not Hero text)

StoryProposalSection
├── id                         (StoryProposalSectionId)
├── narrativeRole              (StoryBuilderNarrativeRole — SB.3/SB.4)
├── order
├── content?                   (verbatim Hero response text when answered)
├── sourceResponseIds[]
├── wasSkipped
└── contentOrigin              (heroAuthored | derived)
```

### Identity semantics

| Event | Identity |
|-------|----------|
| Same persisted proposal reloaded | Stable `StoryProposalId` |
| New proposal generation (use case invoke) | **New** `StoryProposalId` |
| Content equivalence across regenerations | Compared via `isContentEquivalentTo` (excludes ids/timestamps) |

`StoryProposalId` is never equal to `StoryBuilderSessionId`, `StoryId`,
`StoryBuilderResponseId`, or `StoryBuilderPromptId`.

### Lifecycle

```text
draft | readyForReview | accepted | rejected
```

Deterministic SB.9 builds default to **`readyForReview`**. Full Hero
accept/reject workflow is deferred.

Distinct from `StoryLifecycleStatus`.

### Title behavior

There is **no** Story Builder title field today.

Deterministic SB.9 therefore uses **explicit absence** (`title: null`) rather
than inventing a title from AI or polished prose. Future Hero review may supply
a title.

### Narrative

Candidate narrative is assembled by joining answered section contents (Hero
response text only). Null when no answered material produced content.

---

## Deterministic derivation

```text
SB.4 DeterministicStoryStructureSection
        ↓
StoryProposalSection (same narrativeRole + order)
        ↓
content ← StoryBuilderResponse.text when hasSourceMaterial
```

| Structure state | Proposal section |
|-----------------|------------------|
| Answered | `content` = Hero text; `sourceResponseIds` retained; `wasSkipped: false` |
| Skipped | `content: null`; skip response IDs retained; `wasSkipped: true` |
| Empty / unanswered | `content: null`; empty source IDs; not skipped |

Skipped and missing slots are never filled with fabricated prose.

Service: `DeterministicStoryProposalBuilder`  
Use case: `BuildStoryProposalUseCase`

Flow:

1. Load `StoryBuilderSession`
2. Validate exists / not abandoned / has answered material
3. Build SB.4 structure
4. Build **deterministic** SB.8 Understanding (no AI port)
5. Build proposal
6. Persist proposal
7. Return proposal — session unchanged; no Story created

---

## Provenance

```text
StoryProposal.provenance.sessionId
  → StoryBuilderSession
    → StoryBuilderResponse (via section.sourceResponseIds)
```

* Prefer `sourceResponseIds` over copied anonymous text identity.
* Section `contentOrigin: heroAuthored` marks verbatim Hero text.
* Optional `derivedSummary` from Understanding is proposal-level metadata and
  is **not** treated as Hero-authored narrative.
* Do not use a vague `isAiGenerated` flag; use `StoryProposalContentOrigin`.

HS.1 `StoryProvenance` / `ProvenanceStep` remain Story-representation lineage
and are not duplicated here. Session linkage is the appropriate Builder
provenance boundary for SB.9.

---

## AI boundary

SB.9 is offline and deterministic:

* No OpenAI / Anthropic / provider SDK in domain proposal code
* No AI proxy calls
* No credits
* No provider conversation IDs
* Works when network / AI proxy / credits are unavailable

Future `AiStoryShaper` should converge on the same `StoryProposal` model.
SB.9 implements only the deterministic foundation.

---

## Persistence decision

**Implemented** — durable `StoryProposalRepository`:

| Adapter | Path |
|---------|------|
| `FileStoryProposalRepository` | `{root}/story_proposals/{id}.json` |
| `InMemoryStoryProposalRepository` | tests / default provider |
| `StoryProposalSnapshotMapper` | JSON ↔ domain |

Rationale:

* Proposals are **reviewable artifacts** that future Hero review will reopen.
* Session remains the durable Hero-authored source; proposals store references
  and section content snapshots with response IDs — **not** a second session DB.
* Mirrors SB.5 file conventions (enum `.name`, ISO-8601, ID `.value`, flush write).

Understanding remains recomputed (SB.8 non-persistence preserved).

---

## Application / UI

* `BuildStoryProposalUseCase` + `BuildStoryProposalRequest`
* Riverpod: `buildStoryProposalUseCaseProvider`, `storyProposalRepositoryProvider`
* Wired into `HeroStoryDurablePersistence` / `AppCompositionRoot`

Minimal UI on Story Builder completion:

```text
Completed → Build Story Proposal → Proposal preview
```

Disclaimer: *“This is a proposed Story. Your original answers remain yours.”*

No full Hero approval/editing workflow.

---

## Error behavior

| Case | Result |
|------|--------|
| Session missing | `Failure('… not found.')` |
| Abandoned session | `Failure` |
| No answered material | `Failure` |
| Construction / validation error | `Failure('Failed to build Story Proposal: …')` |

No provider-specific failures — SB.9 is offline.

---

## Deferred work

* AI story authoring / sophisticated prose shaping
* Hero editing workflow on the proposal
* Hero approval (`accepted` / `rejected` transitions in product UI)
* Story materialization from an accepted proposal
* Story publishing / catalog integration
* Credits
* Moments / Quotes
* Discovery `NarrativeThemeId` mapping
* Proposal title authoring UX

---

## Files changed (summary)

### Domain
* `StoryProposal*` VOs, enums, IDs
* `DeterministicStoryProposalBuilder`
* `StoryProposalRepository`

### Application
* `BuildStoryProposalUseCase` + request DTO
* providers + durable persistence wiring

### Infrastructure
* file + in-memory repositories, snapshot mapper

### Presentation
* completed → build proposal → preview on Story Builder screen

### Tests
* `sb9_story_proposal_test.dart`
* `deterministic_story_proposal_ai_independence_test.dart`

### Docs
* this report

---

## Architectural verification

| Check | Result |
|-------|--------|
| Story not created | Yes — use case asserts story count unchanged |
| Session remains canonical | Yes — mutation guard + tests |
| AI-independent | Yes — deterministic path only; architecture tests |
| Offline deterministic path | Yes — no network/AI port |
| Provenance preserved | Yes — sessionId + sourceResponseIds + contentOrigin |
| Understanding ≠ Hero text | Yes — derivedSummary separate from section content |
