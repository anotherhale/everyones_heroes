# SB.12 — Hero Review & Approval

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/sb12-hero-review-approval-4817`  
**Baseline:** SB.11 AI Story Authoring on `main`  
**Report path:** `docs/analysis/SB-12-hero-review-approval.md`

---

## Purpose

Hero review and approval is the explicit human decision boundary before Story
materialization.

> **AI can propose. Hero decides. Only an explicit Hero action can approve a
> StoryProposal.**

SB.12 does **not** create a `Story`, publish, catalog, or discover.

---

## Architecture

```text
StoryBuilderSession
        ↓
Story Understanding
        ↓
StoryProposal
        ↓
Deterministic / AI Shaping
        ↓
        SB.12
Hero Review & Approval
        ↓
Accepted StoryProposal
        ↓
        SB.13
Story Materialization
        ↓
Story
```

```text
                    STORY BUILDER
                          │
                          ▼
                StoryBuilderSession
                          │
                          ▼
                Story Understanding
                          │
                          ▼
                    StoryProposal
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
     Deterministic Shaper       AI Story Shaper
              │                       │
              └───────────┬───────────┘
                          ▼
                    StoryProposal
                          │
                          ▼
                 ┌─────────────────┐
                 │  HERO REVIEW    │
                 │  Edit / Reject  │
                 │  Approve        │
                 └────────┬────────┘
                          │
                    explicit approval
                          │
                          ▼
                 accepted StoryProposal
```

---

## Provenance

Two distinct concepts:

| Concept | Meaning | Field |
|---------|---------|-------|
| **Content origin** | Where did this material originate? | `StoryProposalSection.contentOrigin` (`heroAuthored` \| `derived`) |
| **Hero review/edit action** | What did the Hero subsequently do? | `heroEdited`, `contentBeforeHeroEdit`, `StoryProposalReview` |

Example:

```text
AI generates paragraph
        ↓
contentOrigin = derived
        ↓
Hero edits paragraph
        ↓
contentOrigin remains derived
        +
heroEdited = true
contentBeforeHeroEdit = <AI wording>
        ↓
Hero approves
```

Do **not** flip `derived → heroAuthored` on edit — that destroys useful provenance.

---

## Lifecycle

Retained from SB.9:

```text
draft
   ↓
readyForReview
   ↓
accepted

readyForReview
   ↓
rejected
```

Rules:

* Only `StoryProposal.approve()` may transition `readyForReview → accepted`.
* Only `StoryProposal.reject()` may transition `readyForReview → rejected`.
* Hero content edits leave (or return) the proposal to `readyForReview`.
* Editing an **accepted** proposal invalidates approval (`readyForReview` +
  `editedAfterDecision`).
* `beginHeroRevision()` explicitly reopens accepted/rejected proposals for edit.
* Shaping / generation / opening the review screen / saving edits **never**
  approve.

Review metadata (`StoryProposalReview`):

* `decision` / `reviewedAt`
* `revision` (increments on Hero content edit)
* `editedAfterDecision` / `lastEditedAt`
* title/summary Hero-edit baselines

---

## Domain operations

```text
StoryProposal.editHeroContent(...)
StoryProposal.approve(...)
StoryProposal.reject(...)
StoryProposal.beginHeroRevision(...)
```

Editable by Hero: title, summary (`derivedSummary`), section content.

System-managed (not editable via Hero edit): ids, session id, contentOrigin,
sourceResponseIds, provenance, processing version, lifecycle (except via
approve/reject/revision).

---

## Application use cases

| Use case | Responsibility |
|----------|----------------|
| `EditStoryProposalUseCase` | load → edit → save |
| `ApproveStoryProposalUseCase` | load → approve → save |
| `RejectStoryProposalUseCase` | load → reject → save |
| `BeginStoryProposalRevisionUseCase` | load → beginHeroRevision → save |

Save failure returns `Failure` — UI must not claim approval success.

---

## Persistence

`StoryProposalSnapshotMapper` extended with:

* `review` object
* section `heroEdited` / `heroEditedAt` / `contentBeforeHeroEdit`

Older snapshots without these keys remain loadable (defaults applied).

---

## UI

Story Builder proposal preview replaced with Hero review:

* Editable title / summary / sections
* Hero-authored vs AI-assisted labels
* Save Changes / Reject / Approve Story
* Approval confirmation dialog
* Post-approval: “Story Approved” + next step is Story creation (SB.13)
* Resume completed session with existing proposal restores review state

---

## Non-goals

* No Story creation
* No publishing
* No catalog insertion
* No discovery
* No new AI provider
* No second canonical story model
* No general audit framework
* No cross-context approval domain events (SB.13 may consume accepted proposals)

---

## Implementation notes

* `StoryProposal` remains a value object; operations return new instances.
* `StoryBuilderSession` is never mutated by review/edit/approve/reject.
* Deterministic shaping still works; AI shaping still works.
* Domain remains AI-vendor independent.

---

## Deferred to SB.13

* Materialize `Story` from an accepted `StoryProposal`
* Publishing / catalog / discovery
* Any event that Story consumers must react to after materialization
