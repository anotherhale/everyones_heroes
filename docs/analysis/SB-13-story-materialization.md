# SB.13 — Story Materialization

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/sb-13-story-materialization-c378`  
**Baseline:** SB.12 Hero Review & Approval on `main`  
**Report path:** `docs/analysis/SB-13-story-materialization.md`

---

## Purpose

SB.13 establishes the first controlled transition from an explicitly accepted
`StoryProposal` to the canonical Hero & Story `Story` aggregate.

```text
StoryBuilderSession
        ↓
Story Understanding
        ↓
StoryProposal
        ↓
Deterministic / AI Shaping
        ↓
Hero Review / Editing
        ↓
Explicit Hero Approval
        ↓
      SB.13
        ↓
      Story
```

The proposal remains an intermediate authoring artifact.
The Story becomes the canonical domain artifact.

SB.13 does **not** publish, discover, catalog, or personalize.

---

## Boundary

```text
accepted StoryProposal → Story
```

Only:

```text
StoryProposal.lifecycle == accepted
```

is sufficient. These states fail materialization:

* `draft`
* `readyForReview`
* `rejected`

Implicit paths that never materialize:

* session completion
* shaping / AI generation
* Hero editing
* resume / save

This preserves the SB.12 invariant:

```text
generation ≠ approval
editing ≠ approval
resume ≠ approval
completion ≠ approval
```

---

## Materialization mapping

| Proposal | Story |
|----------|-------|
| `title` (or fallback `Untitled Story`) | `Story.title` |
| `narrative` (required) | `Story.narrative` |
| session → `HeroId` | `Story.heroId` |
| Hero profile language (else `en`) | `Story.originalLanguage` |
| — | `lifecycle = draft` |
| — | `visibility = draft` |

Mapping lives in `StoryMaterializationMapper` (application layer).
Creation reuses existing `CreateStoryUseCase` / `Story.create`.

---

## Lifecycle / visibility

Materialization creates a **draft** Story with **draft** visibility.

```text
materialized ≠ published
```

SB.13 does **not** call `SubmitStory`, `ApproveStory`, or `PublishStory`.

Existing Story lifecycle (implementation-authoritative):

```text
draft → processing → review → approved → published
```

Conceptual HS.1 stages map as: materialization ≡ create draft only.

---

## Provenance

Story provenance answers: *Where did this Story come from?*

```text
Canonical Story
      ↓
StoryProvenance.materializedFromProposalId
      ↓
StoryProvenance.sourceSessionId
      ↓
Hero-authored session responses (via proposal sections)
```

Also recorded:

* `proposalDerivationKind` (`deterministic` / `aiShaped`)
* `proposalContainedDerivedContent` (any section had `derived` origin)
* descriptive `originalSourceDescription`

### Content origin vs approval

Section-level `contentOrigin` (`heroAuthored` | `derived`) remains on the
`StoryProposal`. Approval does **not** rewrite AI-derived content as
`heroAuthored`.

```text
content origin  ≠  Hero review / approval
```

---

## Idempotency

Selected strategy (combined Option A + B + deterministic identity):

1. **Option B** — `StoryProposal.materializedStoryId` after successful create.
2. **Option A** — `StoryRepository.findByStoryProposalId` via provenance.
3. **Deterministic StoryId** — `materialized-from-proposal-{proposalId}` upsert safety.

Repeated materialization of the same accepted proposal returns the same Story.

Ordering:

```text
persist Story
        ↓
record proposal.materializedStoryId
```

If the link write fails, the next call recovers via provenance / deterministic id.

Persistence failure leaves the proposal **accepted** for retry.

---

## Failure recovery

```text
Story persistence fails
        ↓
proposal remains accepted
        ↓
UI offers Retry Create Story
```

No transition:

```text
accepted → rejected | draft | readyForReview
```

because materialization failed.

---

## Hero ownership

Authoritative source: `StoryBuilderSession.heroId` resolved through
`proposal.sessionId` / `proposal.provenance.sessionId`.

Hero identity is **not** inferred from narrative text.

Invariant:

```text
Story.heroId == session.heroId for the approved proposal
```

---

## Domain events

`Story.create` raises existing `StoryCreated` via `CreateStoryUseCase`.

SB.13 does **not** emit `StoryPublished`, `StoryApproved`, or discovery events.

---

## UI

```text
Review → Approve → Materialize → Story Created
```

Success:

* “Your story has been created.”
* “Story created. Not yet published.”

Failure:

* proposal stays accepted
* retry available

Resume of an already-materialized proposal restores the Story Created state.

---

## Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| Reuse existing `Story` aggregate + `CreateStoryUseCase` | No parallel Story model |
| Extend `StoryProvenance` with proposal/session ids | Prefer existing provenance; do not invent a second system |
| Store `materializedStoryId` on proposal | Small Option B relationship for UI/resume |
| Deterministic StoryId | Local upsert idempotency without distributed locks |
| Draft lifecycle + draft visibility | Matches existing create defaults; not published |
| Application mapper (not UI) | Preserve hexagonal dependency direction |
| Content origin stays on proposal | Story does not model section-level authorship |

### Implementation vs conceptual HS.1

HS.1 conceptual lifecycle includes richer publication consent stages.
Current Story lifecycle uses `draft` / `processing` / `review` / `approved` /
`published`. SB.13 maps materialization to **create draft only**.

---

## Deferred Work

Explicitly deferred beyond SB.13:

* publication
* discovery
* cataloging / search
* moderation
* media generation / audio publishing
* transcription
* translations / additional representations
* personalization / recommendations
* Story playback / sharing
* Story feed integration
* rematerialization UX for post-publication revisions

---

## Validation

| Check | Result |
|-------|--------|
| Focused SB.13 tests | See agent report |
| Full `flutter test` | See agent report |
| `dart analyze` / `flutter analyze` | See agent report |
