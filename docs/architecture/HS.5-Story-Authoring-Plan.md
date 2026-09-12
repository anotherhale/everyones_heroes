# HS.5 — Story Authoring Plan

**Phase:** HS.5 — Story Authoring  
**Status:** Planning complete (no production code)  
**Date:** 2026-09-12  
**Constraint:** Planning only. Do not implement production code, AI providers, authoring adapters, SDKs, dependencies, UI, or speculative infrastructure in this phase’s planning deliverable.  
**Predecessor:** HS.4 Story Understanding / AI — **COMPLETE** (merged PR #9)  
**Successor (out of scope):** HS.6 Hero & Story Discovery  

**Document path note:** Repository convention for phase plans is `docs/architecture/HS.N-*-Plan.md` (see HS.2–HS.4). This file follows that convention rather than a longer `Everyones-Heroes-…` prefix.

---

## 1. Executive Summary

HS.5 establishes how a Hero intentionally turns a **canonical Story** plus **approved Story Understanding** into high-quality human-readable **Story representations** — without corrupting the canonical Story and without allowing AI-generated content to become authoritative without Hero review.

Intended flow:

```text
Canonical Story
      +
Approved Story Understanding (optional, non-canonical)
      ↓
Story Authoring (ports + use cases)
      ↓
Proposed / unapproved StoryRepresentation (AI-derived or Hero-edited)
      ↓
Hero Review / Editing
      ↓
Approval (Story.approveRepresentation)
      ↓
Authoritative Story Representation
```

This is **not**:

```text
AI → overwrite Story.narrative / Story.classification
```

**Core recommendation:** Do **not** introduce a parallel `StoryAuthoringProposal` aggregate in HS.5. Reuse the proven HS.4 transcription pattern and HS-ADR-006:

* AI-authored artifacts attach as `StoryRepresentation` with `isAiGenerated: true`, `isApproved: false`
* Hero review is `ApproveStoryRepresentationUseCase` → `Story.approveRepresentation`
* Provenance continues through existing `StoryProvenance` / `ProvenanceStep`
* Consent reuses HS-ADR-030 (processing + AI transformation)
* Idempotency reuses the completion-store pattern

**Why not a new proposal aggregate?**  
`StoryUnderstanding` needed a separate aggregate because catalog proposals are multi-dimensional, partially applicable, and must not live as Story catalog state. Authored scripts/short-forms **are** representations. Creating a second proposal aggregate would duplicate review/supersession machinery already carried by unapproved representations + provenance.

**Separate from Understanding:** Understanding answers “what can we understand?” Authoring answers “how do we present it?” Do not merge into one aggregate or port.

**AI boundary:** Introduce replaceable authoring ports (script / alternate format; translation as Slice B). Ship deterministic in-memory adapters only. No production AI SDKs.

**Canonical integrity:** Hero-authored narrative updates go through an explicit `UpdateStoryNarrativeUseCase`. AI scripts never silently become `Story.narrative`. Promoting an approved representation into canonical narrative, if ever needed, is a **separate, explicit** operation (deferred unless product requires it in HS.5).

**Planning readiness:** **READY FOR IMPLEMENTATION** after human approval of the major decisions in §26 (especially aggregate choice, translation slice, narrative promotion, rejection model).

---

## 2. Current HS.4 Architecture Findings

### 2.1 Source-of-truth hierarchy applied

1. **Accepted HS-ADRs through HS-ADR-031** — binding.
2. **Merged HS.4 implementation** (`lib/features/hero_story/**`) — authoritative for understanding/transcription.
3. **HS.4 Implementation Report** — accepted complete.
4. **HS.4 Plan** — design intent; AP.2 checkboxes are planning-era (doc drift vs report).
5. **HS.1–HS.3 plans/reports + ADRs** — binding for Story/representation/consent/catalog.
6. **Architecture maps / AGENTS.md “HS.1 next” wording** — documentation drift; reported, not rewritten here.

### 2.2 What HS.4 actually implemented

| Concern | Actual implementation |
|---------|----------------------|
| Non-canonical AI proposals | `StoryUnderstanding` aggregate (`domain/aggregates/story_understanding.dart`) |
| Proposal statuses | `UnderstandingStatus`: proposed → partiallyReviewed / approved / rejected / superseded |
| Review | `UnderstandingReview` + `UnderstandingReviewDecision` (accept / modify / reject / partial) |
| Supersession | Immutable payload; new id; `supersedesUnderstandingId`; `markSupersededBy`; failed gens do not supersede |
| Provenance (analysis) | `UnderstandingProvenance` (dedicated; HS-ADR-026) |
| Provenance (representations) | Existing `StoryProvenance` + `ProvenanceStep` |
| Transcription | `StoryTranscriptionPort` → derived `StoryRepresentation` (`format: transcript`, `origin: derived`, `isAiGenerated: true`) |
| Understanding | `StoryUnderstandingPort` → `StoryUnderstanding.createProposed` (no Story catalog mutation) |
| Apply | `ApplyStoryUnderstandingUseCase` → authoritative use cases only after review |
| Consent | Processing + AI transformation required before AI ports (HS-ADR-030) |
| Idempotency | `TranscriptionCompletionStore`, `UnderstandingCompletionStore` keyed by `requestId` |
| Events | `StoryUnderstandingProposed`, `StoryUnderstandingReviewed`, `StoryUnderstandingSuperseded`; transcription reuses `StoryRepresentationAdded` |
| Adapters | `InMemoryStoryTranscriptionAdapter`, `InMemoryStoryUnderstandingAdapter` |
| ADRs | HS-ADR-022…031 accepted |

### 2.3 Story representation model (pre-HS.5)

`StoryRepresentation` entity fields:

* `id`, `language`, `format`, `origin`
* `mediaReference?`, `textContent?`
* `sourceRepresentationId?`, `duration?`
* `isAiGenerated`, `isApproved`
* `isAuthoritative => !isAiGenerated || isApproved`
* `approve()` → copy with `isApproved: true`

Formats already defined: `audio`, `video`, `written`, `transcript`, `script`, `shortForm`, `longForm`.

Origins: `original`, `translated`, `derived`.

Transformation types already defined (HS.5 surface highlighted): `recording`, `transcription`, **`editing`**, **`translation`**, `summarization`, **`scriptGeneration`**, **`narration`**, `formatConversion`, `other`.

`Story` mutators already present:

* `addRepresentation` — uniqueness, source existence for derived/translated, original-language match, provenance step, `StoryRepresentationAdded`
* `approveRepresentation` — marks AI rep approved; **no event today**
* `updateNarrative` — Hero authorship of canonical narrative; blocks provisional downgrade; blocked when published/archived/removed/suspended

**Gaps for authoring:** no script/translate ports; no `UpdateStoryNarrativeUseCase`; no `ApproveStoryRepresentationUseCase`; no representation supersession/replace beyond additive `addRepresentation`; no authoring idempotency stores; no representation review notes.

### 2.4 Proposal / review / supersession pattern (HS.4)

```text
Generate (port) → persist proposed aggregate → (optional supersede prior)
        ↓
Review (accept/modify/reject/partial) → status + UnderstandingReview
        ↓
Apply (explicit) → authoritative Story mutators for accepted dimensions only
```

For **transcripts**, HS.4 intentionally skipped a proposal aggregate:

```text
Transcribe (port) → Story.addRepresentation(AI, unapproved) → Hero may approveRepresentation later
```

HS.5 authoring of scripts/formats aligns with the **transcript** pattern, not the **understanding** pattern, because the artifact *is* the representation.

### 2.5 Consent gates (reuse, do not duplicate)

`StoryConsent` independent stages:

| Gate | Applies to |
|------|------------|
| `recorded` | Capture recorded |
| `processingApproved` | Submit + AI pipelines |
| `publicationApproved` | Publish Story |
| `aiTransformationApproved` | Any AI port call |

HS.5 AI authoring (script/alternate format/translation generation) must require **processing + AI** (same as HS-ADR-030). Human-only narrative editing and human-only representation attach do **not** require AI consent. Publication of Story still requires publication consent + non-provisional narrative (existing). Approving a representation does **not** by itself publish the Story.

### 2.6 Idempotency (reuse pattern)

Application-level completion stores keyed by `requestId`, success-only, replay skips side effects. HS.5 should add `AuthoringCompletionStore` (or format-specific stores) for AI generation use cases only — not for pure Hero edits.

### 2.7 Events (HS.4 minimalism)

HS.4 added three understanding events and reused `StoryRepresentationAdded` for transcripts. HS.5 should stay minimal (see §20).

### 2.8 Documentation discrepancies (report; do not silently choose)

| Discrepancy | Classification | HS.5 action |
|-------------|----------------|-------------|
| HS.4 Plan AP.2 still unchecked vs Implementation Report COMPLETE | Documentation drift | Trust report + code |
| `AGENTS.md` still says HS.1 is next authorized phase | Documentation drift | Report; optional later AGENTS update out of HS.5 plan scope |
| Maps (`aggregate-map`, `event-flow`, `use-case-map`, `repository-map`) omit Hero & Story / HS.4 | Documentation drift | Report; update only if implementation needs clarity |
| HS.1 Foundation lists HS.5 as “editing / script / formats / review” without HS.4 proposal/representation split | Superseded by HS.4 | Derive HS.5 from code + ADRs, not Foundation alone |
| HS-ADR-031 places translation in HS.5 | Binding | Address in this plan (Slice B recommendation) |

---

## 3. HS.5 Architectural Objective

Answer:

> How can a Hero intentionally turn their canonical Story and approved understanding into high-quality human-readable Story representations without corrupting the canonical Story or allowing AI-generated content to become authoritative without review?

Objectives:

1. **Story editing** — replace provisional / refine authored `Story.narrative` intentionally.
2. **Script generation** — application-facing port → unapproved script representation.
3. **Alternate formats** — minimal extensible seam (`script`, `shortForm`; optionally `longForm`).
4. **Hero review/approval** — approve/reject authored AI representations without mutating catalog Understanding or silently rewriting narrative.
5. **Preserve** Understanding ≠ Authoring, AI ≠ authority, Story ≠ representation.

Non-objectives: listed in §25.

---

## 4. Domain Boundary

| Layer | Owns in HS.5 |
|-------|----------------|
| **Domain** | Representation invariants; narrative editability; AI non-authority until approval; provenance steps; optional minimal supersession fields/methods on Story; ports as interfaces + plain request/result types; no SDKs |
| **Application** | Orchestration use cases; consent checks; building representations from port results; idempotency stores; event publication via pullDomainEvents; DTOs |
| **Infrastructure** | Deterministic in-memory authoring adapters; in-memory repos unchanged unless new aggregate (none recommended) |
| **Presentation** | **Out of scope** — no widgets, no Riverpod authoring UI |
| **Future AI infra** | Production LLM/TTS/translation providers behind the same ports |

Dependency direction unchanged:

```text
Presentation → Application → Domain ← Infrastructure
```

Domain must not import Flutter, Riverpod, OpenAI, HTTP clients, cloud storage SDKs, or TTS/translation vendors.

---

## 5. Aggregate Analysis

### 5.1 Candidates considered

| Concept | Recommendation | Rationale |
|---------|----------------|-----------|
| `Story` | **Keep** as canonical aggregate | Owns narrative, representations, consent, lifecycle, provenance (HS-ADR-002) |
| `StoryUnderstanding` | **Keep separate**; do not extend for authoring | Understanding ≠ presentation (HS-ADR-022/031) |
| `StoryRepresentation` | **Keep as entity on Story** | Already the derived presentation model; scripts/formats belong here |
| `StoryAuthoringProposal` aggregate | **Do not introduce in HS.5** | Would duplicate unapproved-representation + HS-ADR-006; aggregate bloat without new invariants that Story cannot protect |
| `StoryScript` as separate aggregate | **No** | Script is a `format: script` representation |
| `AuthoringRevision` aggregate | **No** | Use additive representations + provenance; optional soft supersession flag if needed |
| `Hero` | Unchanged | Approver identity may be recorded at application/DTO level if needed; not a new Hero capability in HS.5 |

### 5.2 Why representations stay on Story (not a new aggregate)

Invariants already enforced on `Story`:

* Unique representation ids
* Derived/translated require existing source on same Story
* Original language match for original origin
* Provenance append on every add
* AI authority gated by `approveRepresentation`

Moving representations off Story would break HS-ADR-002 and HS.1–HS.4 consistency. Mutation frequency of drafts is manageable via **additive** new representations rather than in-place mutation of approved content.

### 5.3 Aggregate growth risk mitigation

* Do not fold authoring review state machines into `StoryUnderstanding`
* Do not add CMS-like folders/collections
* Prefer additive representations over editing approved ones
* Limit new `Story` methods to the smallest set: e.g. `replaceUnapprovedRepresentationText` **or** supersede-via-add only (decision in §26)

---

## 6. Entity / Value-Object Analysis

### 6.1 Reuse as-is

| Type | Role in HS.5 |
|------|----------------|
| `StoryRepresentation` | Authored artifact (script/shortForm/…) |
| `StoryNarrative` / `StoryTitle` | Canonical narrative editing |
| `StoryConsent` | Gates |
| `StoryProvenance` / `ProvenanceStep` | Lineage |
| `StoryRepresentationFormat` | Extensible format enum (already has script/shortForm/longForm) |
| `RepresentationOrigin` | `derived` for AI scripts; `translated` for translations; `original` only for true originals |
| `StoryTransformationType` | `scriptGeneration`, `editing`, `translation`, `summarization`, `formatConversion`, `narration` |
| `LanguageCode` | Representation + story languages |
| `MediaReference` | Only if authored form has media (out of core slice) |
| `UnderstandingProvenance` | **Not** for authoring representations — keep analysis-only |

### 6.2 Smallest extensions (if needed)

| Extension | When | Notes |
|-----------|------|-------|
| Optional `supersededByRepresentationId` on `StoryRepresentation` **or** lookup via provenance | If product needs explicit “this draft replaced that draft” | Prefer provenance-first; add field only if queries require it |
| Optional `rejectRepresentation` / `isRejected` | Only if “leave unapproved” is insufficient | Prefer deferral (see §13) |
| Authoring port result VOs (plain Dart) | Required | Mirror `StoryTranscriptionResult` / `StoryUnderstandingDraft` — not domain aggregates |
| Reviewer notes on approve | Optional DTO field; do not invent UnderstandingReview clone on Story | Persist note on `ProvenanceStep.note` if useful |

### 6.3 Do not invent

* Generic `ContentVersion` CMS
* `StoryScript` entity duplicate
* Second provenance subsystem
* Parallel consent “authoring gate”
* Embedding authoring payloads into `StoryUnderstanding.observations`

---

## 7. Application Contracts

Application-facing contracts (use cases + DTOs + ports), not widgets.

Naming follows existing `{Verb}{Noun}UseCase` / `{Verb}{Noun}Request` conventions.

| Contract | Purpose |
|----------|---------|
| `UpdateStoryNarrativeUseCase` | Hero authors/refines canonical narrative (provisional → authored) |
| `GenerateStoryScriptUseCase` | Story (+ optional understanding context) → unapproved script representation |
| `GenerateAlternateStoryRepresentationUseCase` | Same port family; `shortForm` (and optionally `longForm`) |
| `ApproveStoryRepresentationUseCase` | Hero approves AI representation → `approveRepresentation` |
| `RejectStoryRepresentationUseCase` | **Optional** — see §13; may be deferred |
| `EditUnapprovedStoryRepresentationUseCase` **or** regenerate+supersede | Hero edits draft AI text before approval |
| Existing `AddStoryRepresentationUseCase` | Manual Hero-authored attach without AI |
| Existing Story lifecycle use cases | Unchanged; still gate on non-provisional narrative for approve/publish |

Optional later (not required for vertical slice):

* `PromoteRepresentationToNarrativeUseCase` — explicit only; human approval decision
* `TranslateStoryRepresentationUseCase` — Slice B
* Combined “generate + return for review” read models

---

## 8. Proposed Ports

### 8.1 Primary: `StoryAuthoringPort` (recommended)

Single purpose-specific port for generating authored **text** forms from validated inputs (not Story aggregates):

```text
StoryAuthoringPort
  generate(GenerateStoryAuthoringRequest) → StoryAuthoringDraft
```

Request (plain Dart): `storyId`, source representation ids, source texts, optional approved understanding summary fields (IDs + already-authoritative catalog snapshot — **not** raw unreviewed candidates), target `StoryRepresentationFormat`, target `LanguageCode`, `processingVersion`, `requestId?`.

Draft result: `textContent`, `format`, `language`, `providerLabel?`, `modelLabel?`, `supportLevel?`, `notes/uncertainties`, opaque confidence for display only.

**Do not** expand `StoryUnderstandingPort` or `StoryCapturePort`.  
**Do not** create a generic `AIService`.

### 8.2 Alternate: separate `StoryScriptGenerationPort`

Acceptable if implementation prefers narrower ports (mirrors HS.4 transcription vs understanding split). Prefer one authoring port with format parameter to avoid port sprawl for script vs shortForm.

### 8.3 Translation: `StoryTranslationPort` (Slice B)

```text
StoryTranslationPort
  translate(TranslateStoryRepresentationRequest) → StoryTranslationDraft
```

Preserves source/target language, source representation id, provider labels. Adapter deterministic in-memory only.

### 8.4 Adapters

* `InMemoryStoryAuthoringAdapter` — deterministic templates from story id + format + source text digest
* `InMemoryStoryTranslationAdapter` — deterministic prefixed text / language tag (Slice B)
* Failure hooks for tests (mirror HS.4 adapters)
* No production SDKs

---

## 9. Existing Abstractions That Should Be Reused

1. `Story` / `StoryRepresentation` / `addRepresentation` / `approveRepresentation`
2. `StoryProvenance` / `ProvenanceStep` / `StoryTransformationType`
3. `StoryConsent` + HS-ADR-030 gates for AI ports
4. `AddStoryRepresentationUseCase` for non-AI attach
5. Completion-store idempotency pattern
6. EventBus + `pullDomainEvents` publishing pattern
7. `StoryRepository` / `InMemoryStoryRepository`
8. `StoryUnderstandingRepository.findLatestByStoryId` for optional context loading (read-only; must verify approved/applicable status)
9. Format/origin enums already containing HS.5 values
10. Architecture tests pattern (`ai_boundary_test.dart`) — extend for no production authoring SDKs
11. HS-ADR-006 authority rule
12. HS-ADR-002 canonical Story vs derivatives

---

## 10. New Abstractions That Are Actually Necessary

| New | Why existing cannot cover |
|-----|---------------------------|
| `StoryAuthoringPort` (+ in-memory adapter) | No generation seam for scripts/formats |
| `GenerateStoryScriptUseCase` (+ DTO/response) | Orchestration, consent, attach, idempotency |
| `GenerateAlternateStoryRepresentationUseCase` **or** parameterized single generate use case | Alternate format seam |
| `UpdateStoryNarrativeUseCase` | Domain method exists; application entry missing |
| `ApproveStoryRepresentationUseCase` | Domain method exists; application entry + event decision missing |
| `AuthoringCompletionStore` | Idempotency for AI authoring requests |
| Proposed ADRs HS-ADR-032… (see §26) | Record decisions before coding |
| Optional `StoryTranslationPort` + use case | Only if Slice B accepted |

**Not necessary:** new repositories, `StoryAuthoringProposal` aggregate, new consent VO, new provenance subsystem, production AI.

---

## 11. Story Representation Strategy

### 11.1 What `StoryRepresentation` is today

A language/format **presentation** of a Story. Derived/translated forms point at sources. AI forms are non-authoritative until approved. Lifecycle is flag-based (`isAiGenerated` / `isApproved`), not a full CMS status machine.

### 11.2 HS.5 strategy

| Authored form | format | origin | isAiGenerated | transformation |
|---------------|--------|--------|---------------|----------------|
| AI script | `script` | `derived` | true | `scriptGeneration` |
| AI short form | `shortForm` | `derived` | true | `summarization` or `formatConversion` |
| AI long form (optional) | `longForm` | `derived` | true | `formatConversion` |
| Hero-edited draft of AI text | same as source format | `derived` | true (still AI-sourced) **or** false if fully human rewrite policy chosen | `editing` |
| Human-written attach | `written` / `script` / … | `original` or `derived` | false | `editing` / `other` |
| Translation (Slice B) | same as source or `written` | `translated` | true if AI | `translation` |

### 11.3 Canonical narrative vs written representation

* `Story.narrative` = canonical narrative (approve/publish gate)
* `format: written` representation = optional published presentation form
* Do **not** auto-sync them
* Capture provisional narrative replacement is Hero authorship via `UpdateStoryNarrativeUseCase`, not AI script generation

### 11.4 Language

* Generated representation language defaults to source/analysis language unless translation Slice B
* Must not silently mutate `Story.originalLanguage` (HS-ADR-031)
* Translated origin requires `sourceRepresentationId` (existing invariant)

### 11.5 Duration / media / origin

* Text scripts: `textContent` required; media optional
* Narration/TTS audio: **deferred** (would need media storage + narration pipeline; out of HS.5 MVP)
* Origin `derived` for AI scripts from transcript/narrative sources

---

## 12. Authoring Lifecycle

```text
[Sources]
  Canonical Story (narrative may still be provisional)
  + approved/applicable StoryUnderstanding (optional context)
  + source/approved transcript or other text representations
        ↓
Generate via StoryAuthoringPort (consent + idempotency)
        ↓
Attach StoryRepresentation (AI, unapproved) + ProvenanceStep
        ↓
Hero reviews text
        ↓
  ┌─ Edit draft (new additive representation OR replace unapproved text)
  ├─ Approve → authoritative representation
  └─ Decline → leave unapproved (optional explicit reject)
        ↓
(Optional later) Publish Story (existing lifecycle; publication consent)
```

Rules:

* Generation does **not** advance Story lifecycle automatically
* Generation does **not** classify/suitability/spirituality
* Generation does **not** call Understanding apply
* Multiple drafts may exist; prefer supersession/additive clarity over silent overwrite of approved reps

---

## 13. Approval Lifecycle

### 13.1 Representation approval (HS.5 core)

```text
Unapproved AI representation
      ↓
ApproveStoryRepresentationUseCase
      ↓
Story.approveRepresentation
      ↓
isAuthoritative == true
```

Authorized actor: Hero (or Hero-delegated reviewer in future). HS.5 records optional `reviewerActorId` on DTO/provenance note only — no Identity context build-out.

### 13.2 Rejection

**Recommendation:** Model rejection as **non-approval** for MVP (leave `isApproved: false`). Do not delete by default (audit/provenance). Explicit `RejectStoryRepresentationUseCase` / `isRejected` is **optional** and should be deferred unless product requires a distinct “dismissed” state for UI.

If deferred: document that unapproved AI representations are queryable as drafts; clients must not treat them as authoritative (`isAuthoritative`).

### 13.3 Relation to Story approve/publish

| Action | Effect on Story lifecycle |
|--------|---------------------------|
| Approve representation | None |
| Update narrative (non-provisional) | Enables Story.approve / publish eligibility |
| Story.approve / publish | Existing rules; publication consent; visibility |

### 13.4 Understanding approval ≠ authoring approval

Approved Understanding does not approve scripts. Approved scripts do not apply catalog candidates.

---

## 14. Provenance Strategy

Reuse `StoryProvenance` / `ProvenanceStep` for all authored representations:

* `transformationType` (scriptGeneration / editing / translation / …)
* `producedRepresentationId`
* `sourceRepresentationId`
* `occurredAt`
* `isAiAssisted`
* optional `note` (provider label, processing version, reviewer note)

Do **not** use `UnderstandingProvenance` for scripts.

Answerability:

* “Where did this content come from?” → provenance steps + sourceRepresentationId chain + original audio/transcript
* “What happened before publish?” → representation adds/approvals + Story lifecycle events + understanding events (separate)

AI transformation must never erase original capture representation.

---

## 15. Supersession / Versioning Strategy

### 15.1 Reuse HS.4 supersession? Partially, by analogy — not by type

`StoryUnderstanding` supersession is aggregate-level (new id, mark prior superseded). Representations today are **append-only**.

### 15.2 HS.5 recommendation

**Additive versioning:**

```text
script v1 (unapproved)
   ↓ Hero requests edit / regenerate
script v2 (unapproved, sourceRepresentationId → prior text source or same transcript)
   ↓ approve v2
v2 authoritative; v1 remains unapproved historical artifact
```

Optional enhancement (smallest):

* On successful regenerate for same format+language, mark prior unapproved AI representation superseded via:
  * provenance note, **or**
  * optional `supersededByRepresentationId` field

**Do not** mutate approved representation text in place.  
**Do not** introduce semver.  
**Do not** delete history on supersession.

Failed AI generation must not mark prior drafts superseded (mirror HS-ADR-029).

---

## 16. AI Boundary

AI may assist with:

* script generation
* short/long form generation
* editing suggestions (via regenerate; not silent rewrite of approved content)
* translation (Slice B)
* narrative restructuring suggestions as **draft representations only**

AI must **not** silently invent or authorize:

* experiences, facts, achievements, quotations, beliefs, motivations, lessons, events
* Hero identity/religion/medical/political claims (extend adapter guards analogous to `StoryObservation` where text is generative)
* catalog classification changes
* canonical narrative overwrite
* publication

Pattern (mandatory):

```text
Port → Deterministic Adapter → Unapproved Representation → Review → Approve
```

Production AI out of scope. Vendor coupling forbidden in domain/application.

---

## 17. Translation Implications

HS-ADR-031 explicitly places translation in HS.5.

**Recommendation:** Include translation as **Slice B** (after script vertical slice), not in the primary proof slice.

If included:

```text
Approved source representation (e.g. script or written)
      ↓
StoryTranslationPort
      ↓
Unapproved translated StoryRepresentation (origin: translated)
      ↓
Hero review / approve
```

Preserve: source language, target language, source representation id, provenance transformation `translation`, approval state. Translated content must never appear as `origin: original` or mutate `Story.originalLanguage`.

If product prioritizes scripts only, translation may be deferred to HS.5.1 — but that requires explicit human decision because it partially reopens HS-ADR-031’s placement.

---

## 18. Application Use Cases

### 18.1 Minimum required (MVP / Slice A)

| Use case | Notes |
|----------|-------|
| `UpdateStoryNarrativeUseCase` | Human authorship; no AI port |
| `GenerateStoryScriptUseCase` | AI port + attach script representation |
| `ApproveStoryRepresentationUseCase` | Application wrapper for domain approve |
| Existing capture/understanding/lifecycle use cases | Preconditions remain |

### 18.2 Strongly recommended in same phase

| Use case | Notes |
|----------|-------|
| `GenerateAlternateStoryRepresentationUseCase` | `shortForm` minimum |
| Edit path: `ReplaceUnapprovedStoryRepresentationUseCase` **or** regenerate-only | Pick one in implementation ADR |

### 18.3 Slice B / optional

| Use case | Notes |
|----------|-------|
| `TranslateStoryRepresentationUseCase` | Translation port |
| `RejectStoryRepresentationUseCase` | Only if explicit reject approved |
| `PromoteRepresentationToNarrativeUseCase` | Only if product requires |

### 18.4 Do not create

* Duplicate classify/apply understanding use cases
* UI-driven use cases that bypass consent
* `GenerateStoryUnderstandingUseCase` variants for scripts

---

## 19. Repository Requirements

| Repository | HS.5 need |
|------------|-----------|
| `StoryRepository` | **Reuse** — owns representations and narrative |
| `StoryUnderstandingRepository` | **Reuse read-only** for optional context |
| `HeroRepository` | Unchanged |
| `StoryRepresentationRepository` | **Do not create** — representations not an independent consistency boundary |
| `StoryAuthoringRepository` | **Do not create** — no authoring aggregate |

Idempotency stores are application services, not domain repositories (same as HS.3/HS.4).

---

## 20. Event Strategy

Follow HS.4 event-minimalism.

| Event | Recommendation |
|-------|----------------|
| `StoryRepresentationAdded` | **Reuse** for AI script/shortForm/translation attach |
| `StoryRepresentationApproved` | **Add** — approval is a meaningful fact; domain method currently silent; useful for audit and future HS.6 |
| `StoryNarrativeUpdated` | **Optional** — add only if consumers need it; otherwise skip for MVP |
| `StoryRepresentationRejected` | Defer with reject feature |
| `StoryRepresentationSuperseded` | Defer unless supersession field/events are approved |
| `StoryRepresentationPublished` | **Do not add** — publishing is Story-level (`StoryPublished`) |
| Script-specific events | **Do not add** — format is payload of representation, not a new fact type |

Understanding events remain understanding-only.

---

## 21. Testing Strategy

### Domain

* Narrative update invariants (provisional replacement, published lock)
* AI representation non-authority until approve
* `addRepresentation` for script/shortForm/translated lineages
* Supersession/replace rules if introduced
* Provenance step creation for scriptGeneration/editing/translation
* Canonical narrative unchanged by script generation (integration with application tests)

### Application

* Generate script: consent, idempotency, attach, events, failure isolation
* Approve representation: success, missing id, non-AI no-op
* Update narrative: provisional → authored; reject provisional downgrade
* Optional understanding context: only approved/applicable; never auto-apply understanding
* Original Story narrative/classification unchanged after AI authoring

### Infrastructure

* In-memory authoring adapter determinism, empty/malformed guards, failure hooks
* Translation adapter (Slice B)

### Integration (primary proof)

```text
Canonical Story + transcript (+ approved understanding)
  → GenerateStoryScriptUseCase
  → unapproved script representation
  → ApproveStoryRepresentationUseCase
  → authoritative script
  → assert Story.narrative unchanged
  → assert provenance chain intact
```

### Regression

* All HS.1–HS.4 hero_story tests green
* `dart analyze` clean
* Full `flutter test` green
* Extend `ai_boundary_test.dart` for authoring ports/adapters (no SDK imports)

---

## 22. Vertical Slices

### Slice A — Primary architectural proof (required)

```text
Existing Canonical Story (from HS.3 capture + HS.4 transcript)
        ↓
Optional: approved StoryUnderstanding (context only)
        ↓
GenerateStoryScriptUseCase → unapproved script representation
        ↓
Hero ApproveStoryRepresentationUseCase
        ↓
Authoritative script representation
        ↓
Provenance preserved; original Story narrative unchanged
```

Also deliver in Slice A:

* `UpdateStoryNarrativeUseCase` (capture provisional → authored)
* ADRs HS-ADR-032…
* In-memory authoring adapter + tests

### Slice B — Alternate format + translation foundation

* `shortForm` generation via same port
* `StoryTranslationPort` + translate use case + approve path
* Explicit language provenance tests

### Slice C — Hardening

* Idempotency/failure/consent revoke parity with HS.4
* Optional reject/supersede polish
* Architecture boundary tests
* Implementation report

Narration/TTS, video, podcast-specific formats, review UI: **deferred**.

---

## 23. Architecture Risks

| # | Risk | Mitigation |
|---|------|------------|
| 1 | Canonical Story overwritten by authoring | Forbid AI ports from calling `updateNarrative`; only `UpdateStoryNarrativeUseCase` for humans; tests assert unchanged narrative after script gen |
| 2 | Duplicate proposal/review architecture | Do not create `StoryAuthoringProposal`; reuse unapproved representation + approve |
| 3 | Duplicate provenance | Reuse `StoryProvenance` only for representations |
| 4 | Duplicate supersession | Analogy only; additive reps; don’t copy UnderstandingStatus machine onto Story |
| 5 | Story aggregate too large | Limit new methods; no CMS features |
| 6 | Representation as inappropriate child | Keep on Story per HS-ADR-002; don’t extract repo |
| 7 | AI treated as authoritative | HS-ADR-006 + approve use case + `isAuthoritative` checks in tests |
| 8 | Translation loses source provenance | `origin: translated` + required source id + provenance step |
| 9 | Vendor coupling | Port + in-memory adapter only |
| 10 | Authoring logic in widgets | No UI in HS.5 |
| 11 | Orchestration in domain | Ports return drafts; use cases attach |
| 12 | Event proliferation | Only add `StoryRepresentationApproved` by default |
| 13 | Unnecessary repositories | None new |
| 14 | Mixing Understanding + Authoring | Separate ports/use cases; no aggregate merge |
| 15 | Generated representation as new Story | Always attach to existing StoryId |
| 16 | Editing canonical when derived safer | Default AI output → representation; narrative update is explicit human op |
| 17 | Publish without approval | Existing publication consent + non-provisional narrative; representation approve ≠ publish |
| 18 | Losing revision history | Append-only representations; no delete-on-supersede |
| 19 | Premature CMS | Explicit non-goal; formats enum is enough |

---

## 24. Definition of Done

### Product

* [ ] Hero can intentionally author/replace provisional canonical narrative via application use case
* [ ] Script can be generated through application-facing port/use case
* [ ] At least one alternate format seam exists (`shortForm`) **or** explicitly deferred with ADR
* [ ] Authoring results attach as reviewable (unapproved) representations
* [ ] Hero can approve representation; approved reps are identifiable (`isAuthoritative`)
* [ ] Rejection policy documented (explicit or “leave unapproved”)
* [ ] Original Story narrative/catalog unchanged by AI authoring
* [ ] Provenance visible via `Story.provenance`
* [ ] Supersession/history policy implemented as approved (additive minimum)

### Architecture

* [ ] Understanding and Authoring remain separate
* [ ] Canonical Story remains authoritative
* [ ] AI remains non-authoritative until approval
* [ ] No production AI dependencies / SDKs
* [ ] No vendor coupling in domain/application
* [ ] No presentation-layer domain logic
* [ ] No `StoryAuthoringProposal` aggregate (unless human overrides §26)
* [ ] No unnecessary repositories
* [ ] HS.4 consent/provenance/approval patterns reused
* [ ] HS-ADR-032… recorded as Accepted

### Testing

* [ ] Domain tests pass
* [ ] Application tests pass
* [ ] Adapter tests pass
* [ ] Integration vertical slice passes
* [ ] HS.1–HS.4 regression (`test/features/hero_story`) passes
* [ ] `dart analyze` clean (no errors)
* [ ] Full Flutter test suite passes
* [ ] AI boundary tests extended

---

## 25. Explicitly Deferred Work

* Production AI / OpenAI / LLM SDKs
* Production translation APIs, TTS, media generation
* Narration audio generation / podcast pipelines
* Review UI / Hero Experience UI (HS.7)
* Personalization, recommendation, discovery (HS.6/HS.8)
* Social features, marketplace, monetization, moderation backends
* Authentication / Identity bounded context build-out
* Auto-delete AI artifacts on consent revoke (still deferred from HS.4)
* Clock injection cleanup (TD-007)
* Rewriting stale architecture maps / AGENTS.md phase wording (report only unless required)
* `PromoteRepresentationToNarrativeUseCase` unless approved
* Full CMS versioning, branched drafts, collaborative editing
* Embedding search / semantic authoring memory
* Expanding closed catalog enums via authoring

---

## 26. Recommended Implementation Sequence

### Step 0 — Human decisions (blocking)

Resolve §27 major decisions; record ADRs.

### Step 1 — ADRs

Add HS-ADR-032… to `architecture-decisions.md` (proposed → accepted at implementation start).

### Step 2 — Domain deltas (minimal)

* Any supersede/replace helpers on `Story` / `StoryRepresentation`
* Raise `StoryRepresentationApproved` from `approveRepresentation` if ADR accepts
* Export updates in `domain.dart`

### Step 3 — Ports + in-memory adapters + adapter tests

### Step 4 — `UpdateStoryNarrativeUseCase` + tests

### Step 5 — `GenerateStoryScriptUseCase` + completion store + tests

### Step 6 — `ApproveStoryRepresentationUseCase` + tests

### Step 7 — Alternate format (`shortForm`) via same port

### Step 8 — Slice B translation (if approved)

### Step 9 — Hardening (consent revoke, failures, boundary tests)

### Step 10 — Implementation report (`HS.5-Story-Authoring-Implementation-Report.md`)

No UI. No production providers. No HS.6 discovery work.

---

## 27. Major Decisions Requiring Human Approval

| ID | Decision | Plan recommendation | Alternatives |
|----|----------|---------------------|--------------|
| D1 | Authoring proposal aggregate vs representation-as-proposal | **No new aggregate**; unapproved `StoryRepresentation` + approve | Introduce `StoryAuthoringProposal` mirroring Understanding |
| D2 | Translation in HS.5 MVP? | **Slice B** after scripts | Defer entirely to HS.5.1 (conflicts with HS-ADR-031 wording — would need ADR amendment) |
| D3 | May approved representation auto-update `Story.narrative`? | **Never automatic**; optional explicit promote use case deferred | Allow promote in HS.5 |
| D4 | Explicit representation reject state? | **Defer**; leave unapproved | Add `isRejected` / reject use case now |
| D5 | Edit unapproved AI text in place vs additive regenerate? | Prefer **additive regenerate**; optional in-place replace for unapproved only | In-place edit of unapproved text as primary |
| D6 | Add `StoryRepresentationApproved` event? | **Yes** | Stay silent like current domain method |
| D7 | One `StoryAuthoringPort` vs separate script/shortForm ports | **One port** with format | Separate ports |
| D8 | Must generation require approved Understanding? | **No** — optional context; Story + text sources sufficient | Hard-require approved understanding |

---

## 28. Proposed ADRs (for implementation phase)

These are **proposed** here; accept during HS.5 implementation Step 1:

| ID | Title (proposed) |
|----|------------------|
| HS-ADR-032 | Story Authoring Produces Unapproved StoryRepresentations; No AuthoringProposal Aggregate |
| HS-ADR-033 | Introduce StoryAuthoringPort With Deterministic In-Memory Adapter Only |
| HS-ADR-034 | AI-Authored Representations Remain Non-Authoritative Until approveRepresentation (reinforce HS-ADR-006) |
| HS-ADR-035 | Canonical Narrative Authorship Is Explicit UpdateStoryNarrative; AI Scripts Do Not Mute Narrative |
| HS-ADR-036 | Representation Revision Is Additive; Failed Generations Do Not Supersede |
| HS-ADR-037 | Translation Uses origin translated + StoryTranslationPort (Slice B) |
| HS-ADR-038 | Authoring AI Ports Require Processing + AI Consent (reuse HS-ADR-030) |
| HS-ADR-039 | Event Minimalism: Reuse StoryRepresentationAdded; Add StoryRepresentationApproved |
| HS-ADR-040 | Initial Authored Formats: script + shortForm; narration/TTS deferred |

---

## 29. Capability Evaluation (A–D)

### A. Story Editing

* Canonical Story narrative is edited **only** via explicit human `UpdateStoryNarrativeUseCase`
* Authored representations are edited via regenerate/replace-unapproved — not by overwriting approved reps
* Drafts = unapproved representations (and/or pre-approve narrative edits on Story while editable)
* Revisions retained additively
* Supersession via additive lineage (optional explicit marker)

### B. Script Generation

* `StoryAuthoringPort` / `GenerateStoryScriptUseCase`
* Inputs: Story text sources + optional approved understanding context
* Output: proposal as unapproved script representation
* Deterministic in-memory adapter first

### C. Alternate Formats

* Establish seam with `script` + `shortForm`
* `longForm` optional same seam
* Podcast/motivational/presentation-specific subtypes: **defer** (avoid enum explosion; use notes or future format values when needed)

### D. Hero Review

* Draft (unapproved) → review → edit → approve
* Rejection: defer explicit model
* Approver: Hero; consent already on Story
* Do not reuse UnderstandingReview VO for representation text

---

## 30. Planning Status Checklist

| Item | Status |
|------|--------|
| Inspect hero_story HS.1–HS.4 code | Complete |
| Inspect HS-ADR-022…031 | Complete |
| Inspect representation/provenance/consent | Complete |
| Inspect use cases/ports/repos/tests | Complete |
| Aggregate recommendation | Complete — no authoring proposal aggregate |
| Ports / use cases / events / repos | Designed |
| Vertical slice | Defined |
| Production code | **Not implemented** |
| Dependencies / AI SDKs | **Not added** |

---

## 31. Final Principle

> AI may help present the story. AI does not own the story.  
> Understanding interprets. Authoring presents.  
> Representations derive. The canonical Story remains authoritative.

HS.5 is **READY FOR IMPLEMENTATION** after human confirmation of decisions D1–D8.

---

*End of HS.5 Story Authoring Plan — planning deliverable only.*
