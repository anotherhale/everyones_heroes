# SB.11 — AI Story Authoring

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/sb-11-ai-story-authoring-ef1a`  
**Baseline:** SB.10 Deterministic Story Shaping on `main`  
**Report path:** `docs/analysis/SB-11-ai-story-authoring.md`

---

## Purpose

SB.11 introduces an AI-powered story authoring/shaping strategy that takes an
existing `StoryProposal` and produces an improved, reviewable narrative
proposal.

The AI is an **authoring assistant**, not the source of truth.

> AI may help express the Hero's story more clearly and compellingly, but it
> must not decide, invent, or fabricate what happened to the Hero.

The resulting artifact remains a `StoryProposal`.

SB.11 does **not** create a `Story`, approve a Story, or publish a Story.

---

## Relationship to previous slices

```text
SB.7  = AI interviewer (next question)
SB.8  = Story Understanding (interpretation)
SB.9  = Story Proposal foundation
SB.10 = deterministic shaping
SB.11 = AI authoring / shaping
```

```text
                           StoryProposal
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
       DeterministicStoryShaper        AiStoryShaper
                    │                       │
                  SB.10                   SB.11
                    │                       │
                    └───────────┬───────────┘
                                ▼
                         StoryProposal
                                │
                                ▼
                         Hero Review
```

Do not create a second proposal model. Do not create a second Story model.

---

## Architecture

```text
StoryShaperPort
    ├── DeterministicStoryShaper   (SB.10, offline)
    └── AiStoryShaper              (SB.11)
            │
            ▼
    StoryAuthoringTransport        (subordinate transport — not a parallel
            │                       product shaping port)
            ▼
    ProxyStoryShaperAdapter
            │
            ▼
    POST /story-authoring          (EH AI proxy)
```

`StoryShaperMode` (`deterministic` | `ai`) is resolved by
`StoryShaperStrategyResolver` and is **independent** of `StoryBuilderMode`
(guided / AI interview).

`StoryAuthoringTransport` exists only so `AiStoryShaper` can call the proxy
without importing HTTP. Application code selects shaping via `StoryShaperPort`.

---

## AI contract

### Request (`StoryAuthoringRequest`)

```text
purpose, themes, themesUnsure
title, summary
understandingSummary          ← DERIVED UNDERSTANDING (guidance only)
sections[]:
  role, content, sourceResponseIds, contentOrigin, wasSkipped
```

### Response (`StoryAuthoringResponse`)

```text
title, summary
sections[]: role, content, sourceResponseIds
warnings[]
providerLabel / promptOrTemplateVersion (observability)
```

Proxy endpoint: `POST /story-authoring`  
Processing version: `sb11.ai.v1`

---

## Source-of-truth rules

```text
StoryBuilderSession
    = canonical Hero-authored source
```

```text
StoryBuilderUnderstanding / derivedSummary
    = derived interpretation (guidance, not fact)
```

The authoring prompt distinguishes **SOURCE MATERIAL** from
**DERIVED UNDERSTANDING**. If they conflict, source material wins.

AI authoring never mutates:

* StoryBuilderSession
* StoryBuilderResponse
* StoryBuilderPrompt
* Hero profile
* Story
* Story catalog

---

## Provenance

Every AI section must cite `sourceResponseIds` that appear in the request.

Validation:

```text
AI sourceResponseId ∈ supplied sourceResponseIds
```

Unknown IDs → typed `StoryShaperException` / use-case `Failure`.  
Original proposal is not persisted over. Session unchanged.

---

## Content origin

| Origin | Meaning |
|--------|---------|
| `heroAuthored` | Verbatim Hero Builder response text |
| `derived` | Application- or AI-produced wording |

AI-produced prose is **always** marked `derived` by the application —
never by trusting an AI `contentOrigin` field.

---

## Failure behavior

Failures (network, auth, timeout, invalid JSON, unknown role, unknown
source ID, provider errors) map to typed failures.

UX recovery:

* Retry
* Continue with current proposal
* Exit

Original proposal remains intact. No empty replacement.

---

## Lifecycle

After AI shaping, lifecycle is always:

```text
readyForReview
```

AI cannot return `accepted` or otherwise control lifecycle.

---

## Persistence

Snapshot mapper persists proposal identity, session linkage, sections,
`contentOrigin`, provenance (`derivationKind: aiShaped`,
`processingVersion: sb11.ai.v1`), lifecycle, timestamps, and derived summary.

After reload, the UI can still recognize an AI-derived proposal.

---

## Security / privacy

Request payload is minimized to authoring needs only.

Not sent: credentials, filesystem paths, unrelated Hero profile fields,
unrelated stories, internal persistence metadata the model does not need.

The EH AI proxy remains the controlled boundary for external AI access.
Server-side system instructions live in
`services/ai_proxy/lib/src/story_authoring_instructions.dart`.

---

## UI

From proposal review:

```text
Review your story (deterministic)
        │
        └── Improve with AI  →  AI processing  →  AI-assisted story proposal
```

AI is never invoked automatically on open. Disclosure labels AI-assisted
wording. A lightweight compare toggle retains access to the original proposal.

---

## Deferred work

* Hero editing of proposal prose
* Hero approval / Story materialization
* Publishing / catalog integration
* AI credits
* Advanced revision / versioning
* Multimedia / voice / video generation
* Discovery integration

---

## Architectural verification

| Check | Result |
|-------|--------|
| Hero-authored session remains canonical | Yes |
| AI cannot mutate session | Yes |
| Provenance validated; unknown IDs rejected | Yes |
| AI output marked `derived` | Yes |
| Processing version `sb11.ai.v1` | Yes |
| Lifecycle `readyForReview` | Yes |
| Original proposal preserved on failure | Yes |
| Deterministic SB.10 path remains available | Yes |
| No Story created | Yes |
| Hero approval still required | Yes |
