# HS.4 — Story Understanding / AI Plan

**Phase:** HS.4 — Story Understanding / AI  
**Status:** Planning complete (no production code)  
**Date:** 2026-09-12  
**Constraint:** Planning only. Do not implement production code, AI providers, transcription adapters, SDKs, dependencies, or speculative infrastructure in this phase’s planning deliverable.  
**Predecessor:** HS.3 Story Capture Foundation — **COMPLETE**  
**Successor (out of scope):** HS.5 Authoring / Translation  

---

## A. Executive Summary

HS.4 establishes the architecture for **AI-assisted Story Understanding** after HS.3’s capture foundation. The pipeline becomes:

```text
Hero's lived experience
        ↓
Captured representation (HS.3)
        ↓
Canonical Story (draft / provisional narrative)
        ↓
HS.4 Understanding (this plan)
        ↓
HS.5 Authoring / Translation
        ↓
Published Story representations
```

**Core recommendation:** Introduce a new Hero & Story aggregate, **`StoryUnderstanding`**, that holds AI-derived **proposals** (candidate catalog dimensions, observations, provenance, review state). Keep the canonical **`Story`** aggregate authoritative for classification, suitability, spirituality, narrative, and representations. Apply approved catalog proposals only through existing authoritative mutators (`Story.classify`, suitability/spirituality updates, `approveRepresentation`).

**Transcription** is in scope as a **derived `StoryRepresentation`** (format `transcript`, origin `derived`, `isAiGenerated: true`) attached via existing `Story.addRepresentation` + provenance — not a new Story, not a second narrative.

**AI boundary:** Two replaceable ports — `StoryTranscriptionPort` and `StoryUnderstandingPort` — with deterministic in-memory/mock adapters. No production providers. Do not expand legacy `StoryCapturePort`.

**Prime rule:** AI may help understand the story. AI does not own the story. AI output never silently becomes canonical truth, Hero identity, or personalization decisions.

**Planning readiness:** **READY FOR IMPLEMENTATION** (architecture decisions recorded as proposed ADRs HS-ADR-022…HS-ADR-031; no HS.3 redesign required).

---

## B. Planning Status

| Item | Status |
|------|--------|
| Repository inspection (Hero & Story HS.1–HS.3) | Complete |
| Source-of-truth hierarchy applied | Complete |
| HS.3 baseline accepted | Complete — no redesign required |
| Aggregate boundary decision | Recommended: separate `StoryUnderstanding` aggregate |
| AI port architecture | Recommended: transcription + understanding ports |
| Proposal vs canonical truth | Designed |
| Consent / privacy for AI gate | Designed |
| HS.5 boundary | Explicitly preserved |
| Production code | **Not implemented** (planning only) |
| Dependencies / AI SDKs | **Not added** |

---

## C. Source Documents Reviewed

| Document | Role |
|----------|------|
| `AGENTS.md` | Implementation contract; Hero & Story / AI ownership / events |
| `docs/architecture/architecture-decisions.md` | Binding ADRs through **HS-ADR-021** |
| `docs/architecture/HS.3-Story-Capture-Foundation-Plan.md` | Capture design; §Z.2 HS.4 boundary |
| `docs/architecture/HS.3-Story-Capture-Foundation-Implementation-Report.md` | HS.3 accepted complete; handoff to HS.4 |
| `docs/architecture/HS.2-Story-Catalog-Foundation-Plan.md` | Option B / closed enums / AI → HS.4 |
| `docs/architecture/HS.2-Implementation-Report.md` | Catalog implementation baseline |
| `docs/architecture/HS.2-Final-Architectural-Cleanup-Report.md` | Closed-enum / Option B confirmation |
| `docs/architecture/Everyone"s Heroes - Hero and Story Platform Foundation.md` | HS.1 foundation (partially superseded) |
| `docs/architecture/aggregate-map.md` | Stale (no Hero/Story) |
| `docs/architecture/bounded-contexts.md` | Partially updated |
| `docs/architecture/event-flow.md` | Stale (Life Journey only) |
| `docs/architecture/use-case-map.md` | Stale |
| `docs/architecture/repository-map.md` | Stale |
| `docs/architecture/architecture-drift.md` | Stale for Hero & Story |
| `docs/architecture/technical-debt.md` | TD-007 Clock relevant |
| `docs/architecture/testing-strategy.md` | Domain-first principles |
| `docs/architecture/domain-glossary.md` | Incomplete for Hero & Story |
| `docs/architecture/codebase-analysis.md` | Pre-HS.1 — inventory not authoritative |
| Current `lib/features/hero_story/**` | **Source of truth for implemented model** |
| Current `test/features/hero_story/**` | HS.1–HS.3 validation patterns |
| Life Journey analysis pipeline (`InsightExtractionService`, BehavioralEvidence) | Analogy for proposal ≠ pattern ≠ guidance |
| Discovery `NarrativeTheme` ownership | Cross-context ID-only boundary |

**Note:** No standalone Mission Statement file exists. Product North Star / Anchor Statement from architecture docs apply. No separate HS.1 plan file; HS.1 is the Foundation document.

---

## D. Source-of-Truth Analysis

### D.1 Hierarchy applied

1. **Accepted HS-ADRs (through 021)** — binding.
2. **Current Hero & Story implementation** — intentional for HS.1–HS.3.
3. **HS.3 plan + implementation report** — current phase handoff.
4. **HS.2 plan/reports** — binding for catalog Option B / closed enums.
5. **HS.1 Foundation** — principles binding; some roadmap items superseded.
6. **Maps / glossary / codebase-analysis** — often stale; do not drive HS.4 design alone.

### D.2 Intentional implementation vs drift

| Finding | Classification | HS.4 action |
|---------|----------------|-------------|
| `StoryConsent` AI gate present but unused | Intentional HS.3 deferral | Enforce in HS.4 orchestration |
| `StoryCapturePort.requestTranscription` unsupported | Intentional (HS-ADR-020) | Prefer new `StoryTranscriptionPort`; leave stub or mark deprecated |
| Provisional narrative + `createFromCapture` | Intentional HS-ADR-017 | Do not treat provisional text as understanding source |
| Authoritative `ClassifyStoryUseCase` only | Intentional HS-ADR-015 / Option B | Keep; proposals live off-Story |
| Maps/glossary omit Hero & Story | Documentation drift | Report; do not rewrite unless implementation needs clarity |
| `AGENTS.md` still authorizes “HS.1 next” | Documentation drift | Report; not an HS.4 code blocker |
| `DateTime.now()` fallbacks in Story/consent | Technical debt (TD-007 class) | Prefer optional `at` / request timestamps; Clock injection optional, not required to start HS.4 |
| HS.1 “transcript in HS.3” wording | Superseded by HS.3 plan | Transcript belongs to HS.4 |

### D.3 Conflict protocol outcome

No HS.3 architectural defect blocks HS.4. **Do not redesign capture, consent VO shape, MediaReference opacity, or representation provenance model.**

---

## E. HS.3 Baseline

Treat HS.3 as **COMPLETE**.

### E.1 Delivered capabilities (code)

- `StoryConsent` with independent gates: recorded / processing / publication / **AI**
- `StoryNarrative.provisional()` + approve/publish guards
- `Story.createFromCapture()`
- `StoryMediaStoragePort` + `InMemoryStoryMediaStorageAdapter`
- Opaque `MediaReference`
- `CompleteStoryCaptureUseCase` (no AI)
- `UpdateStoryConsentUseCase`, `CancelStoryCaptureUseCase`
- Application `CaptureCompletionStore` for session idempotency
- Reuse of lifecycle, visibility, provenance, `StoryRepresentationAdded`
- **No** `StorySource`, **no** CaptureSession aggregate, **no** AI, **no** translation, **no** cloud SDKs

### E.2 Validation (reported at HS.3 closure)

- `flutter analyze`: clean  
- Focused Hero & Story: 58/58  
- Full suite: 580/580  
- ADRs: HS-ADR-017 … HS-ADR-021  

### E.3 HS.3 → HS.4 handoff (explicit)

From HS.3 plan §Z.2 and implementation report:

- AI transcription adapters  
- Story understanding  
- AI classification proposals → human review → authoritative catalog  
- Extraction / semantic analysis / AI metadata  
- Enforcement of AI consent on real AI pipeline calls  

---

## F. Current Hero & Story Architecture

### F.1 Bounded context

`lib/features/hero_story/` — Hexagonal layers:

```text
presentation/   (not yet for Hero & Story)
application/    use cases, DTOs, CaptureCompletionStore, providers
domain/         aggregates, entities, VOs, events, repository ports, service ports
infrastructure/ in-memory repos, media, search, unsupported capture stub
```

### F.2 Story aggregate (canonical)

`Story` owns:

- Title, narrative (including provisional)
- Original language
- Lifecycle + visibility
- Authoritative `StoryClassification`
- `ContentSuitability`, `SpiritualityClassification`
- `StoryProvenance` + representations
- `StoryConsent`

Key invariants for HS.4:

- Derived/translated representations require existing source representation id
- AI representations non-authoritative until `approveRepresentation` (HS-ADR-006)
- `classify` raises `StoryClassified` (authoritative only — HS-ADR-015)
- AI consent field exists; **not enforced** on aggregate methods today

### F.3 Representation model (must preserve)

```text
StoryRepresentation
├── language, format, origin
├── mediaReference? | textContent?
├── sourceRepresentationId? (required for derived/translated at Story)
├── duration?
├── isAiGenerated
└── isApproved → isAuthoritative
```

Formats include `transcript`. Transformation types include `transcription`.

### F.4 Catalog model (must preserve)

Closed enums + Discovery theme ids (HS-ADR-007/014/003):

```text
StoryClassification
├── subjects: StorySubject[]
├── challenges: StoryChallenge[]
├── narrativeThemeIds: NarrativeThemeId[]   // Discovery-owned themes
├── outcomes: StoryOutcome[]
├── emotionalCharacters: EmotionalCharacter[]
├── audience: StoryAudience?
└── geography: StoryGeography?

ContentSuitability          // sibling
SpiritualityClassification  // sibling; NOT Hero religion
```

### F.5 Existing events

Hero: `HeroCreated`, `HeroProfileUpdated`  
Story: `StoryCreated`, `StorySubmitted`, `StoryApproved`, `StoryPublished`, `StoryArchived`, `StoryClassified`, `StoryRepresentationAdded`

### F.6 Existing ports

| Port | Role |
|------|------|
| `StoryMediaStoragePort` | Opaque bytes |
| `StorySearchPort` / `HeroSearchPort` | Catalog filter only |
| `StoryCapturePort` | Legacy stub; transcription unsupported |

### F.7 Analogous Life Journey pattern

```text
Reflection → InsightExtractionService → Insights
           → BehavioralEvidenceAnalyzer → BehavioralEvidence
           → PatternDetector → BehaviorPattern
```

Evidence ≠ pattern ≠ guidance. HS.4 parallel:

```text
Source representation → AI understanding proposal ≠ approved catalog ≠ personalization
```

---

## G. Current Implementation Findings

1. **No understanding model exists** — no `StoryUnderstanding`, analysis, or proposal types.
2. **No AI ports** beyond stub transcription on legacy capture port.
3. **Classification write path is authoritative-only** — correct per HS-ADR-015.
4. **Transcript semantics already exist** at enum/format level; unused by capture.
5. **Provenance is representation-centric** (`ProvenanceStep.producedRepresentationId`) — good for transcripts; insufficient alone for understanding provenance (needs analysis-level provenance).
6. **Consent AI gate is ready to enforce** at application orchestration.
7. **Idempotency pattern exists** (`CaptureCompletionStore`) — reusable shape for understanding/transcription jobs.
8. **Ports live under `domain/services/`** — match this convention for new AI ports.
9. **Domain services in Life Journey** (`InsightExtractionService`) sit in domain and are implemented by rule-based/fake adapters — AI understanding port should similarly be provider-agnostic; **prefer not** to pass full `Story` aggregate into provider adapters (send validated content DTOs to reduce leakage).
10. **`AggregateType`** currently has `hero` and `story` only — new understanding aggregate requires extending this enum.
11. **No HS.4 plan file existed** prior to this document.

---

## H. HS.4 Scope

### H.1 In scope

| Area | HS.4 responsibility |
|------|---------------------|
| Transcription architecture | Port + attach derived transcript representation; in-memory/mock adapter |
| Story understanding model | `StoryUnderstanding` aggregate + proposal payload |
| AI understanding port | Structured, validated analysis results |
| Candidate catalog proposals | Subjects, challenges, outcomes, emotional character, audience, geography, NarrativeThemeId candidates, suitability signals, spirituality **content** signals |
| Human review contracts | Accept / modify / reject / partial apply |
| Apply to canonical Story | Via existing authoritative use cases only |
| Provenance of AI analysis | Minimal understanding provenance VO |
| Consent enforcement | Require AI gate before transcription/understanding calls |
| Versioning / reprocessing | Immutable understanding versions; supersession |
| Failure / retry / idempotency | Application orchestration |
| Multilingual policy | Understand in original language; no HS.5 translation |
| Tests | Domain + application + adapter contract + architecture boundary |
| ADRs | HS-ADR-022+ recorded at implementation kickoff |

### H.2 Explicitly slimmed (investigated, not all required)

| Candidate | Decision |
|-----------|----------|
| Full segmentation / span model | **Minimal optional** source span refs; not a full media timeline platform |
| Numeric cross-provider confidence | **Do not** treat as domain truth |
| Auto-apply classification | **Forbidden** |
| Embeddings / vector search | **Out** |
| Production transcription/AI providers | **Out** (mock/in-memory only) |
| Automatic Hero identity updates | **Forbidden** |
| Personalization / feed / recommendations | **Out** |
| Story authoring / translation / scripts | **HS.5** |
| Full privacy/compliance platform | **Out** (consent + retention rules only) |

---

## I. Explicit Non-Goals

HS.4 must **not**:

- Implement production OpenAI/Anthropic/Gemini/Bedrock/Azure adapters
- Add AI SDK dependencies
- Implement production cloud transcription
- Auto-write `Story.classify` from AI without human/application approval path
- Infer Hero religion, mental health, political beliefs, sexual orientation, diagnoses, or protected characteristics
- Become Discovery relevance scoring
- Become personalization / experience selection / feed ranking
- Implement translation, script generation, narrated audio, alternate authored forms (HS.5)
- Create `StorySource` or CaptureSession aggregate
- Duplicate `NarrativeTheme` ownership
- Create a generic AI framework, generic metadata framework, or generic audit platform
- Modify unrelated Life Journey debt
- Build review UI / presentation layer (contracts only)
- Silently redesign HS.3 capture

---

## J. Core Architectural Principles

1. **Hero lived experience is source of truth.**
2. **AI assists; AI does not own.**
3. **Proposal ≠ canonical Story state.**
4. **Representations remain representations** (HS-ADR-002/006).
5. **Authoritative classification remains explicit** (HS-ADR-015).
6. **AI behind replaceable ports** (AD-009 / HS-ADR-012/020 pattern).
7. **Deterministic application around nondeterministic AI.**
8. **Consent gates are independent** — AI never implied (HS-ADR-021).
9. **Catalog ≠ Discovery ≠ Personalization** (HS-ADR-010).
10. **Story content ≠ Hero identity** (HS-ADR-009).
11. **Prefer evidence/observations over conclusions.**
12. **Minimum useful provenance**, not a giant audit framework.
13. **Incremental vertical slices** with tests each step.

---

## K. Story Understanding Model

### K.1 Chosen concept

**Single primary concept:** `StoryUnderstanding` (aggregate).

Do **not** introduce overlapping parallel nouns (`StoryInsight`, `StoryAnalysis`, `UnderstandingArtifact`, `UnderstandingResult`) as separate first-class persisted models.

Supporting value objects / enums (not aggregates):

| Type | Role |
|------|------|
| `StoryUnderstandingId` | Aggregate id |
| `UnderstandingStatus` | `proposed`, `partiallyReviewed`, `approved`, `rejected`, `superseded` |
| `UnderstandingProvenance` | Provider-agnostic analysis lineage |
| `CandidateStoryClassification` | Proposed catalog dimensions (same shape family as `StoryClassification`, but **non-authoritative**) |
| `CandidateContentSuitability` | Proposed suitability signals |
| `CandidateSpiritualityClassification` | Proposed **story content** spirituality signals |
| `StoryObservation` | Optional free-form / structured observational notes with kind + optional source span |
| `ObservationKind` | Closed enum: e.g. `languageSignal`, `contentMention`, `uncertainty`, `other` — **not** identity claims |
| `AnalysisSupportLevel` | `unknown`, `weak`, `moderate`, `strong` — categorical, optional |
| `SourceSpanReference` | Optional opaque start/end or timestamp range against a representation |

### K.2 What `StoryUnderstanding` represents

A versioned, reviewable **AI-assisted interpretation** of one Story’s source material at a point in time.

| Question | Answer |
|----------|--------|
| Canonical? | **No** — never replaces Story narrative/classification by existing |
| Derived? | **Yes** — derived from representations / media |
| Requires approval? | **Yes** before affecting authoritative Story catalog metadata |
| Owned by? | Hero & Story bounded context |
| Relates to Story? | References `StoryId`; does not embed Story |
| Relates to Discovery? | May propose `NarrativeThemeId`s only; never owns themes |
| Relates to Personalization? | **Produces inputs others may use later**; does not personalize |

### K.3 Conceptual contents

```text
StoryUnderstanding
├── StoryUnderstandingId
├── StoryId
├── status
├── sourceRepresentationIds[]          // usually transcript and/or audio
├── analysisLanguage: LanguageCode     // language of analyzed text
├── detectedLanguage?: LanguageCode    // observation, not Story.originalLanguage mutation
├── candidateClassification?
├── candidateContentSuitability?
├── candidateSpirituality?
├── observations: StoryObservation[]
├── provenance: UnderstandingProvenance
├── processingVersion                  // EH understanding schema/workflow version
├── createdAt / reviewedAt?
├── supersedesUnderstandingId?
└── review: UnderstandingReview?       // decisions per section / notes
```

### K.4 Forbidden payload content

Understanding must not contain:

- Hero identity assertions (“Hero is Christian”, “Hero has PTSD”)
- Fabricated quotations presented as Hero speech without source span
- Personalization scores / rank / “show to user X”
- Raw provider SDK types
- Unvalidated free-form taxonomy strings that bypass closed enums

Unknown AI categories → dropped or recorded as `ObservationKind.uncertainty`, never auto-mapped into closed enums.

---

## L. Canonical Truth vs AI Proposal

### L.1 Separation table

| Kind | Example | Storage | Becomes canonical how? |
|------|---------|---------|------------------------|
| Source material | Original audio representation | Story representation | Already canonical capture |
| Derived transcript | AI transcript text | Story representation (`isAiGenerated`) | Authoritative as transcript only after `approveRepresentation` if product requires; may remain usable as understanding **input** while unapproved if AI consent granted — **must not** replace Story narrative |
| Observation | “Recording discusses military service” | `StoryObservation` on Understanding | Informational; may support subject proposal |
| Candidate classification | `StorySubject.military` proposed | `CandidateStoryClassification` | Human accept → `ClassifyStoryUseCase` |
| Inference | “Hero values sacrifice” | **Avoid as fact**; if present, mark as uncertain observation, never Hero attribute | Never auto-apply |
| Identity claim | “Hero is religious” | **Forbidden pipeline** | Spirituality VO is **story content**, not Hero |

### L.2 Automatic vs approval-required

| Output | Auto-persist as proposal? | Auto-apply to Story? |
|--------|---------------------------|----------------------|
| Transcript representation | Yes (as AI representation) | No (authority via HS-ADR-006) |
| Candidate catalog dimensions | Yes (on Understanding) | **Never** |
| Suitability / spirituality candidates | Yes (on Understanding) | **Never** without review use case |
| Detected language observation | Yes | Does **not** overwrite `Story.originalLanguage` automatically |
| Fabricated narrative rewrite | **Out of HS.4** (HS.5) | — |

### L.3 Sensitive inference policy (hard)

HS.4 must **not** infer or store as approved fact:

- Personal religion / tradition of the Hero
- Mental health diagnoses
- Political beliefs
- Sexual orientation
- Other protected characteristics
- Personality disorders

Story-level spirituality classification remains **content about the story**, never Hero identity (HS-ADR-009).

---

## M. Aggregate Boundary

### M.1 Decision

**`StoryUnderstanding` is a separate aggregate root** in Hero & Story.

### M.2 Why not inside Story

HS-ADR-015 explicitly deferred proposal lifecycle **to avoid expanding Story**. Understanding has:

- Independent versioning / supersession
- Independent review concurrency
- Failure modes that must not corrupt Story
- Multiple historical analyses per Story
- Different consistency boundary than Story lifecycle/publish

Embedding proposals in Story would recreate the exact risk HS.2 avoided.

### M.3 Why not application-only ephemeral results

Review, reprocessing, provenance, and consent revocation semantics require persistence. Ephemeral results cannot support “why was this approved?” or stale/superseded handling.

### M.4 Why not many aggregates

Do **not** split “ClassificationProposal”, “SuitabilityProposal”, etc. into separate aggregates. One understanding version is one consistency unit for review.

### M.5 Consistency rules

- Generating understanding **never** mutates `Story.classification` / suitability / spirituality / narrative.
- Applying approved candidates **is a separate application transaction** that loads Story and calls authoritative mutators.
- Transcript attachment mutates Story representations only (existing path).
- Understanding references representation ids; if source representation missing, generation fails (no silent invent).

### M.6 AggregateType

Add `AggregateType.storyUnderstanding` when implementing events for this aggregate (requires ADR).

---

## N. Transcription Boundary

### N.1 Decision

Transcription **belongs in HS.4** because understanding typically needs textual material from HS.3 audio.

Transcription is:

- A **derived `StoryRepresentation`** with `format: transcript`, `origin: derived`, `sourceRepresentationId: <audio>`, `isAiGenerated: true`
- Produced via **`StoryTranscriptionPort`**
- Attached with `StoryTransformationType.transcription` and existing `StoryRepresentationAdded`
- **Not** a separate aggregate
- **Not** canonical Story narrative
- **Not** HS.5 translation

### N.2 Transcript kinds

| Kind | Model |
|------|-------|
| Machine-generated transcript | AI representation as above |
| Edited transcript | Later representation (often HS.5 authoring) derived from machine transcript; out of core HS.4 unless needed for tests as manual `AddStoryRepresentationUseCase` |
| Manual Hero-provided transcript | Non-AI representation (`isAiGenerated: false`) allowed via existing add-representation path |

### N.3 Fields already covered by representation + provenance

Language, text content, source id, AI flag, approval, transformation type, occurredAt.

Additional transcription-specific confidence stays in **port result metadata** mapped into `UnderstandingProvenance` when used as understanding input, or optional note on provenance step — avoid new parallel transcript entity.

### N.4 Legacy `StoryCapturePort`

Do **not** implement real transcription on `StoryCapturePort`. Prefer dedicated `StoryTranscriptionPort` (HS.3 preferred migration). Keep unsupported stub for compatibility or deprecate clearly in ADR.

---

## O. AI Port Architecture

### O.1 Ports (minimal)

| Port | Layer location | Purpose |
|------|----------------|---------|
| `StoryTranscriptionPort` | `domain/services/` | Audio/media → transcript text (+ optional language/confidence metadata) |
| `StoryUnderstandingPort` | `domain/services/` | Validated textual/source content → structured understanding draft DTO |

### O.2 Why two ports

Transcription and understanding often use different providers, failure modes, billing, and retry policies. Combining into `AIService` obscures contracts and encourages provider leakage.

### O.3 Why not domain “AIService”

Too generic; violates project preference for purpose-specific ports (`StoryMediaStoragePort`, `StorySearchPort`).

### O.4 Port input/output principles

- Inputs: StoryId, MediaReference / text, LanguageCode, processingVersion, optional idempotency key — **not** provider SDKs
- Outputs: plain Dart result types / validated candidate structures
- Errors: typed port exceptions mapped to `Failure` in use cases
- Adapters perform schema validation **before** returning to application

### O.5 Suggested signatures (planning shape)

```text
StoryTranscriptionPort.transcribe(TranscribeStoryMediaRequest)
  → StoryTranscriptionResult
      { text, language, sourceMediaReference, providerLabel?, supportLevel?, rawConfidenceOpaque? }

StoryUnderstandingPort.analyze(AnalyzeStoryContentRequest)
  → StoryUnderstandingDraft
      { candidateClassification?, candidateSuitability?, candidateSpirituality?,
        observations[], detectedLanguage?, supportLevel?, providerLabel?, modelLabel?,
        promptOrTemplateVersion?, uncertainties[] }
```

Domain/application maps `StoryUnderstandingDraft` → `StoryUnderstanding.createProposed(...)`.

### O.6 Layering

```text
UseCase (consent, load Story, idempotency, persistence, events)
    ↓
StoryTranscriptionPort / StoryUnderstandingPort
    ↓
Infrastructure adapter (mock / in-memory / future provider)
    ↓
External AI (future only)
```

Application may depend on port interfaces. Domain remains free of provider types. Infrastructure contains provider-specific code only.

---

## P. Infrastructure Adapter Architecture

### P.1 HS.4 adapters (required)

| Adapter | Behavior |
|---------|----------|
| `InMemoryStoryTranscriptionAdapter` | Deterministic fake transcript from fixture/hash; no network |
| `InMemoryStoryUnderstandingAdapter` | Deterministic candidate output from keywords/fixtures; validates enums |
| Optional `Failing*` test doubles | Timeout / malformed / unavailable scenarios |

### P.2 Explicitly deferred adapters

Production OpenAI/Anthropic/Gemini/Bedrock/Azure/Google STT — **not in HS.4 implementation**.

### P.3 Validation boundary

Adapters (or a pure validator used by adapters) must:

- Map only known closed enum values
- Drop/unknown → uncertainty observations
- Reject empty transcript text
- Bound list sizes
- Strip provider-only fields before returning draft

Malformed AI output **never** reaches `Story.classify`.

---

## Q. Provenance

### Q.1 Two provenance layers

| Layer | Existing / new | Covers |
|-------|----------------|--------|
| Story representation provenance | Existing `StoryProvenance` / `ProvenanceStep` | Transcript attachment lineage |
| Understanding provenance | **New** `UnderstandingProvenance` VO | Analysis run lineage |

### Q.2 Minimal `UnderstandingProvenance`

```text
UnderstandingProvenance
├── sourceRepresentationIds[]
├── analyzedAt
├── providerLabel          // opaque string, e.g. "in_memory", "provider_a"
├── modelLabel?            // opaque
├── promptOrTemplateVersion?
├── processingVersion      // EH schema/workflow version
├── supportLevel?          // categorical
├── opaqueProviderConfidence?  // string/number optional; NOT domain truth
└── notes?
```

Do **not** store raw prompts containing full Hero media by default in domain objects. If needed for debug, keep behind infrastructure logging controls (see Security).

### Q.3 Approval provenance

On review:

```text
UnderstandingReview
├── reviewerActorId?   // opaque string until Identity context matures
├── decidedAt
├── decision notes
├── accepted sections / modified candidate snapshot
└── appliedToStoryAt?
```

---

## R. Explainability

### R.1 Target chain

```text
AI observation / candidate
  → StoryUnderstanding id + provenance
  → sourceRepresentationId
  → optional SourceSpanReference
  → original media MediaReference (opaque)
```

### R.2 Graceful degradation

If provider cannot supply spans:

- Still record representation id + timestamp + processing version
- Mark observation support as `unknown`/`weak`
- UI later shows “derived from transcript representation X” without fake timestamps

Never fabricate source spans.

---

## S. Confidence / Uncertainty

### S.1 Decision

**Do not** introduce a cross-provider numeric confidence score as a domain invariant or auto-approval threshold.

### S.2 Useful concept

Optional categorical **`AnalysisSupportLevel`**: `unknown | weak | moderate | strong`.

Semantics:

- Advisory for human review UX
- Not comparable as precise probability across providers
- Must not auto-approve
- May be omitted

Opaque provider confidence may be stored on provenance for audit display only.

### S.3 Uncertainty representation

- Explicit `StoryObservation` with `ObservationKind.uncertainty`
- Empty candidate sections when unsupported
- Partial understanding allowed (some dimensions null)

---

## T. Human Review / Approval

### T.1 Workflow

```text
AI proposal (StoryUnderstanding.proposed)
        ↓
Human review
        ↓
Accept / Modify / Reject (partial allowed)
        ↓
Optionally Apply to Story via authoritative use cases
```

### T.2 Who can approve

Until Identity ownership is fully modeled: application accepts an opaque `reviewerActorId` string (Hero owner / trusted reviewer). **Do not** invent a full RBAC platform in HS.4. Document assumption: caller is authorized by future Identity/UI layer.

### T.3 What approval means

| Action | Meaning |
|--------|---------|
| Accept candidates | Understanding marked approved/partiallyReviewed; **Story unchanged** until apply |
| Modify | Store reviewed candidate snapshot (edited classification etc.) on understanding |
| Reject | Status `rejected`; no Story catalog mutation |
| Apply | Application loads Story + approved candidates → `classify` / suitability / spirituality use cases |

Partial approval: accept subjects/challenges; reject spirituality; leave outcomes undecided.

### T.4 Reversibility

- Applied Story classification can later be overwritten by another authoritative classify (existing behavior)
- Understanding versions are not deleted on reject; remain for audit
- Re-approval after reprocessing uses new understanding id (old superseded)

### T.5 Transcript approval

Use existing `Story.approveRepresentation` when product requires authoritative transcript. Understanding may proceed from unapproved AI transcript **only if** AI consent is present and product policy allows “working transcript” — document as default **allowed for private processing**, still non-authoritative for publication-facing narrative claims.

---

## U. Versioning / Reprocessing

### U.1 Decision

Understanding records are **immutable after create** regarding AI payload. Review updates status/review fields. Reprocessing creates a **new** `StoryUnderstanding` that **supersedes** the previous.

### U.2 Rules

- Append-only versions per Story (history retained)
- `supersedesUnderstandingId` links chain
- Prior `proposed`/`approved` versions become `superseded` when a newer successful analysis is committed (application policy: supersede on successful generate; do not supersede on failed attempts)
- Reproducibility: store processingVersion + provider/model/template labels; exact bit-identical AI output is **not** guaranteed
- Deterministic adapters in tests **are** bit-stable

### U.3 Stale results

If source transcript representation changes (new transcript version), existing understandings referencing old representation ids are considered stale; UI/contracts should surface staleness; reprocessing recommended. Do not auto-delete.

---

## V. Idempotency

### V.1 Pattern reuse

Mirror HS.3 `CaptureCompletionStore` with application-level stores:

| Store | Key | Value |
|-------|-----|-------|
| `TranscriptionCompletionStore` | `transcriptionRequestId` / session key | response with representation id |
| `UnderstandingCompletionStore` | `understandingRequestId` | response with understanding id |

Not domain repositories. Not a generic infra framework.

### V.2 Semantics

- Same request id → return prior success without re-calling AI port / without duplicate representation
- Failed attempts do not poison idempotency key unless explicitly saved as failure policy (prefer: only save successes, like capture)

---

## W. Failure / Retry / Recovery

| Failure | Behavior |
|---------|----------|
| Media missing | Fail use case; no Story mutation |
| Transcript missing for understand | Fail or optionally chain transcribe first (explicit orchestration flag) |
| Transcription failure | No representation added; return Failure |
| AI timeout / unavailable | Failure; retry allowed with same idempotency key if prior not saved |
| Malformed AI output | Adapter validation fails; no Understanding persisted; no Story classify |
| Unsupported language | Failure or understanding with uncertainty-only observations (choose Failure for v1 unless adapter can still propose safely) |
| Partial analysis | Allowed if validator marks partial; still `proposed` |
| Cancellation | Application-level cancel store entry; do not leave half-applied classification |
| Approval after source change | Allow apply only with explicit acknowledgeStale flag or block if source representation superseded |
| Consent missing/revoked | Hard fail before port call |

**Invariant:** AI failures never destroy original audio or overwrite narrative/classification.

---

## X. Consent / Privacy

### X.1 Enforcement points

Before calling `StoryTranscriptionPort` or `StoryUnderstandingPort`:

1. Load Story  
2. Require `story.consent.isAiTransformationApproved`  
3. Prefer also requiring processing consent if transcription is considered processing (recommended: **require both processing + AI** for HS.4 AI pipeline)

Publication consent is **not** required for private AI understanding.

### X.2 Revocation

| Question | HS.4 policy |
|----------|-------------|
| Future AI calls after revoke? | **Prohibited** |
| Existing Understanding records? | **Retained** by default (audit); optional delete use case deferred unless legally required later |
| Existing AI transcript representations? | **Retained** by default; deletion is explicit future operation |
| Reprocessing? | Blocked without AI consent |

Do not assume AI consent is permanent.

### X.3 Private content

AI processing of private/unpublished stories is allowed **with AI (+ processing) consent**. Visibility ≠ AI permission.

---

## Y. Security

### Y.1 Risks

Sending Hero audio/transcripts to external AI can leak sensitive personal content.

### Y.2 HS.4 enforceable boundaries

| Control | Where |
|---------|-------|
| Consent gate | Application use cases |
| No provider SDK in domain/application | Architecture tests / review |
| Redact/minimize logs | Infrastructure adapters (no full transcript in logs by default) |
| Opaque MediaReference | Domain |
| No automatic public exposure of AI outputs | Visibility remains Story’s |
| Prompt leakage prevention | Adapter responsibility; don’t persist full prompts on Understanding by default |

### Y.3 Non-claims

Do not claim provider non-training / zero-retention guarantees in domain. Document that production adapters must configure provider data-use settings explicitly when introduced (post-HS.4).

---

## Z. Multilingual Architecture

### Z.1 Decision

```text
Original language capture
        ↓
Transcript in source/original language (HS.4)
        ↓
Understanding in analysis language (= transcript/original) (HS.4)
        ↓
Translation / multilingual authored forms (HS.5)
```

**Do not** require translation before understanding.

### Z.2 Rules

- Prefer analyzing original-language transcript
- `detectedLanguage` is an observation; does not silently change `Story.originalLanguage`
- Understanding stores `analysisLanguage`
- Future translated representations are HS.5 inputs; HS.4 may note “translation recommended” as uncertainty observation only if needed — optional, not required

---

## AA. Story Classification Integration

### AA.1 Workflow

```text
Captured Story
      ↓
Transcript (optional but typical)
      ↓
StoryUnderstanding (candidates)
      ↓
Human review (accept/modify/reject)
      ↓
ClassifyStoryUseCase / suitability / spirituality use cases
      ↓
Authoritative StoryClassification (+ siblings)
      ↓
StoryClassified (existing event)
```

### AA.2 Preserve dimension separation

Never collapse into one AI metadata blob:

- `StoryClassification`
- `ContentSuitability`
- `SpiritualityClassification`
- `NarrativeThemeId`
- `StoryGeography`
- Language
- Representation format

### AA.3 Closed enums

Unknown AI labels are not invented into enums. Resilience remains a Discovery theme id, never `StoryChallenge`.

---

## AB. Discovery Boundary

- Narrative themes owned by Discovery
- Understanding may include **candidate `NarrativeThemeId` values** only
- Optional future validation against `NarrativeThemeRepository.findById` in application before apply (recommended when applying)
- Do **not** create Hero & Story theme taxonomy
- Do **not** resolve Influence → Theme inside HS.4

---

## AC. Personalization Boundary

HS.4 outputs understanding that **downstream** Discovery/Personalization **may** later consume.

HS.4 must not decide:

- What user sees next
- Feed ranking
- Recommendations
- Missions / growth opportunities
- Experience selection

No ranking scores on `StoryUnderstanding`.

---

## AD. Hero Identity Boundary

Hard separation:

| Story signal | Must not imply |
|--------------|----------------|
| Religious content in story | Hero is religious |
| Trauma discussion | Clinical diagnosis |
| Military subject | Full Hero identity profile rewrite |

HS.4 must not pipeline understanding into sensitive `HeroProfile` fields. No `UpdateHeroProfileFromUnderstanding` use case.

---

## AE. Event Model

### AE.1 Minimum event set

| Event | When | AggregateType |
|-------|------|---------------|
| `StoryRepresentationAdded` | Transcript attached (reuse) | `story` |
| `StoryUnderstandingProposed` | New understanding persisted | `storyUnderstanding` |
| `StoryUnderstandingSuperseded` | Prior version superseded | `storyUnderstanding` |
| `StoryUnderstandingReviewed` | Accept/modify/reject decision recorded | `storyUnderstanding` |
| `StoryClassified` | Authoritative apply (reuse) | `story` |

### AE.2 Not required initially

| Event | Reason |
|-------|--------|
| `StoryTranscribed` | Redundant with `StoryRepresentationAdded` + provenance type `transcription`; add later only if a consumer needs a distinct fact |
| `StoryUnderstandingApproved` | Covered by `StoryUnderstandingReviewed` with decision payload/status |
| `StoryUnderstandingRejected` | Same |
| Per-dimension events | Noise |

### AE.3 Payload guidance

Prefer ids (`storyId`, `understandingId`, `representationId`) over large candidate payloads in events.

---

## AF. Repository Model

### AF.1 New repository

**Yes — `StoryUnderstandingRepository`**

Justification:

- Separate aggregate with independent persistence/lifecycle
- Query by StoryId (latest, history)
- Not derivable solely from Story aggregate state

Methods (minimal):

```text
save(StoryUnderstanding)
findById(StoryUnderstandingId)
findByStoryId(StoryId) → list (ordered)
findLatestByStoryId(StoryId) → optional
```

### AF.2 Not created

- `StoryAnalysisRepository` (duplicate concept)
- `UnderstandingProposalRepository` (duplicate)
- BehaviorPattern-style secondary repos for candidates

### AF.3 Existing repositories

`StoryRepository` / `HeroRepository` unchanged in responsibility. Story gains transcript representations only through existing save path.

---

## AG. Application Use Cases

| Use case | Responsibility |
|----------|----------------|
| `TranscribeStoryRepresentationUseCase` | Consent → media retrieve → transcription port → addRepresentation → events; idempotent |
| `GenerateStoryUnderstandingUseCase` | Consent → load source text/reps → understanding port → persist proposed Understanding → supersede prior → events |
| `ReviewStoryUnderstandingUseCase` | Accept/modify/reject; update status/review; event |
| `ApplyStoryUnderstandingUseCase` | Map approved candidates → classify/suitability/spirituality authoritative use cases or direct aggregate mutators + save Story; mark applied |
| `GetStoryUnderstandingUseCase` / query helpers | Latest + history for future UI (optional but useful) |

Optional orchestration:

- `TranscribeAndUnderstandStoryUseCase` — thin composer; keep also as separate steps for retries

Reuse:

- `UpdateStoryConsentUseCase`
- `ClassifyStoryUseCase`
- `UpdateStoryContentSuitabilityUseCase`
- `UpdateStorySpiritualityUseCase`
- `AddStoryRepresentationUseCase` (manual paths)

---

## AH. DTOs / Requests / Results

Follow existing immutable `final class` request pattern.

Examples:

- `TranscribeStoryRequest` — storyId, sourceRepresentationId, requestId, occurredAt?
- `GenerateStoryUnderstandingRequest` — storyId, sourceRepresentationIds, requestId, processingVersion?, occurredAt?
- `ReviewStoryUnderstandingRequest` — understandingId, decision, modified candidates?, reviewerActorId?, notes?, at?
- `ApplyStoryUnderstandingRequest` — understandingId, applyClassification?, applySuitability?, applySpirituality?, acknowledgeStale?

Responses:

- Include ids + aggregate snapshots as needed (`TranscribeStoryResponse`, `GenerateStoryUnderstandingResponse`)
- Idempotent replay flags like capture

---

## AI. Validation

### AI.1 Layers

| Layer | Validates |
|-------|-----------|
| Infrastructure adapter | Schema, enums, bounds, required fields |
| Domain Understanding factory | Invariants (story id required, status transitions, immutability of payload) |
| Application | Consent, story exists, source reps exist, idempotency, stale apply rules |
| Authoritative Story mutators | Existing classification/lifecycle invariants |

### AI.2 Hallucination handling

- Closed-enum allowlist only
- No auto-create NarrativeTheme
- No identity claims mapping
- Quotations without spans → drop or uncertainty

---

## AJ. Testing Strategy

### AJ.1 Domain

- Understanding status transitions
- Immutability of proposed payload
- Supersession rules
- Review accept/modify/reject/partial
- Provenance equality basics
- Observation/candidate invariants
- Forbidden identity claim helpers (if any factory guards)

### AJ.2 Application

- AI consent enforced (and processing consent)
- Transcription happy path + idempotency
- Understanding generation + supersession
- Malformed adapter output → Failure, Story unchanged
- Retry behavior
- Apply path calls authoritative classify only after review
- Reject does not classify
- Revoked consent blocks ports
- Stale apply behavior
- Provider replacement via alternate adapter

### AJ.3 Infrastructure

- In-memory transcription adapter contract
- In-memory understanding adapter enum safety
- Failure mapping

### AJ.4 Architecture

- No AI SDK imports under `domain/` or `application/`
- Ports replaceable with in-memory adapters
- `StoryUnderstanding` does not import Discovery theme entities

### AJ.5 Non-goals for HS.4 tests

No UI tests; no production provider integration tests.

---

## AK. File-Level Implementation Plan

Paths relative to repo root. **New** unless marked **Modified**.

### AK.1 Shared kernel / ids

| Path | Layer | Purpose |
|------|-------|---------|
| `lib/core/ids/story_understanding_id.dart` | shared | New aggregate id |
| `lib/core/eventing/aggregate_type.dart` | shared | **Modified** — add `storyUnderstanding` |

### AK.2 Domain — understanding model

| Path | Purpose |
|------|---------|
| `lib/features/hero_story/domain/aggregates/story_understanding.dart` | Aggregate root |
| `lib/features/hero_story/domain/enums/understanding_status.dart` | Status enum |
| `lib/features/hero_story/domain/enums/analysis_support_level.dart` | Categorical support |
| `lib/features/hero_story/domain/enums/observation_kind.dart` | Observation kinds |
| `lib/features/hero_story/domain/value_objects/understanding_provenance.dart` | Analysis provenance |
| `lib/features/hero_story/domain/value_objects/story_observation.dart` | Observation VO |
| `lib/features/hero_story/domain/value_objects/source_span_reference.dart` | Optional span |
| `lib/features/hero_story/domain/value_objects/candidate_story_classification.dart` | Non-authoritative classification proposal |
| `lib/features/hero_story/domain/value_objects/candidate_content_suitability.dart` | Suitability proposal |
| `lib/features/hero_story/domain/value_objects/candidate_spirituality_classification.dart` | Spirituality content proposal |
| `lib/features/hero_story/domain/value_objects/understanding_review.dart` | Review decision VO |
| `lib/features/hero_story/domain/repositories/story_understanding_repository.dart` | Persistence port |
| `lib/features/hero_story/domain/domain.dart` | **Modified** — exports |

### AK.3 Domain — ports

| Path | Purpose |
|------|---------|
| `lib/features/hero_story/domain/services/story_transcription_port.dart` | Transcription port + request/result types |
| `lib/features/hero_story/domain/services/story_understanding_port.dart` | Understanding port + draft types |
| `lib/features/hero_story/domain/services/story_capture_port.dart` | **Modified** — clarify deprecated/unsupported relative to new port |

### AK.4 Domain — events

| Path | Purpose |
|------|---------|
| `lib/features/hero_story/domain/events/story_understanding_proposed.dart` | Proposed event |
| `lib/features/hero_story/domain/events/story_understanding_reviewed.dart` | Reviewed event |
| `lib/features/hero_story/domain/events/story_understanding_superseded.dart` | Superseded event |

### AK.5 Application

| Path | Purpose |
|------|---------|
| `lib/features/hero_story/application/understanding/transcription_completion_store.dart` | Idempotency store |
| `lib/features/hero_story/application/understanding/understanding_completion_store.dart` | Idempotency store |
| `lib/features/hero_story/application/dto/requests/transcribe_story_request.dart` | DTO |
| `lib/features/hero_story/application/dto/requests/generate_story_understanding_request.dart` | DTO |
| `lib/features/hero_story/application/dto/requests/review_story_understanding_request.dart` | DTO |
| `lib/features/hero_story/application/dto/requests/apply_story_understanding_request.dart` | DTO |
| `lib/features/hero_story/application/dto/responses/transcribe_story_response.dart` | DTO |
| `lib/features/hero_story/application/dto/responses/generate_story_understanding_response.dart` | DTO |
| `lib/features/hero_story/application/use_cases/transcribe_story_representation_use_case.dart` | Orchestration |
| `lib/features/hero_story/application/use_cases/generate_story_understanding_use_case.dart` | Orchestration |
| `lib/features/hero_story/application/use_cases/review_story_understanding_use_case.dart` | Review |
| `lib/features/hero_story/application/use_cases/apply_story_understanding_use_case.dart` | Apply to Story |
| `lib/features/hero_story/application/providers/repositories/story_understanding_repository_provider.dart` | Provider |

### AK.6 Infrastructure

| Path | Purpose |
|------|---------|
| `lib/features/hero_story/infrastructure/repositories/in_memory_story_understanding_repository.dart` | In-memory repo |
| `lib/features/hero_story/infrastructure/ai/in_memory_story_transcription_adapter.dart` | Fake transcription |
| `lib/features/hero_story/infrastructure/ai/in_memory_story_understanding_adapter.dart` | Fake understanding + validation |

### AK.7 Documentation (implementation kickoff)

| Path | Purpose |
|------|---------|
| `docs/architecture/architecture-decisions.md` | **Modified** — add HS-ADR-022…031 |
| `docs/architecture/HS.4-Story-Understanding-AI-Plan.md` | This plan (repo copy) |

### AK.8 Tests (representative)

| Path | Purpose |
|------|---------|
| `test/features/hero_story/domain/aggregates/story_understanding_test.dart` | Domain invariants |
| `test/features/hero_story/application/use_cases/transcribe_story_representation_use_case_test.dart` | Transcription + consent + idempotency |
| `test/features/hero_story/application/use_cases/generate_story_understanding_use_case_test.dart` | Generation + supersession |
| `test/features/hero_story/application/use_cases/review_and_apply_story_understanding_test.dart` | Review/apply boundaries |
| `test/features/hero_story/infrastructure/ai/in_memory_story_understanding_adapter_test.dart` | Adapter validation |
| `test/features/hero_story/architecture/ai_boundary_test.dart` | No SDK leakage (if project has arch test style; else review checklist) |

### AK.9 Intentionally not added

- Production provider adapters
- UI / presentation models
- CaptureSession / StorySource
- Generic `AIService`
- Vector/embedding stores

---

## AL. Implementation Sequence

Incremental vertical slices aligned to this codebase:

### Slice 0 — ADRs

Record HS-ADR-022…031 in `architecture-decisions.md`.  
**Prereq:** none. **Tests:** none.

### Slice 1 — Understanding domain model

Ids, enums, VOs, `StoryUnderstanding` aggregate, repository port, unit tests.  
**No AI calls yet.**

### Slice 2 — Ports + in-memory adapters

`StoryTranscriptionPort`, `StoryUnderstandingPort`, deterministic adapters, adapter tests.

### Slice 3 — Transcription use case

Consent enforcement, media retrieve, add derived transcript representation, idempotency store, events (`StoryRepresentationAdded`).

### Slice 4 — Generate understanding use case

Load transcript/source text, call understanding port, persist proposed understanding, supersession, `StoryUnderstandingProposed` (+ superseded event).

### Slice 5 — Review use case

Accept/modify/reject/partial; `StoryUnderstandingReviewed`.

### Slice 6 — Apply use case

Apply approved candidates through authoritative Story mutators/use cases; ensure StoryClassified only on classify; never on generate.

### Slice 7 — Failure / consent / architecture tests

Malformed output, revoked consent, retries, provider swap, boundary tests.

### Slice 8 — Documentation sync (minimal)

Only if needed for implementers: brief HS.4 implementation report after coding (separate from this plan). Avoid broad map rewrites unless authorized.

---

## AM. Architectural Decisions / ADRs

**Next number:** **HS-ADR-022** (after HS-ADR-021).

Proposed decisions to record at implementation kickoff (do not invent numbers beyond sequence):

| ID | Decision | Why required |
|----|----------|--------------|
| **HS-ADR-022** | `StoryUnderstanding` is a separate aggregate for AI proposals | Preserve HS-ADR-015; independent versioning/review |
| **HS-ADR-023** | AI proposals never auto-apply to authoritative Story catalog | Canonical vs proposal separation |
| **HS-ADR-024** | Introduce `StoryTranscriptionPort` and `StoryUnderstandingPort`; do not expand `StoryCapturePort` for real AI | Replaceability; HS-ADR-020 continuity |
| **HS-ADR-025** | Machine transcripts are derived AI `StoryRepresentation`s | Preserve representation model |
| **HS-ADR-026** | Understanding provenance is a dedicated VO (minimum useful fields) | Trust/explainability without audit platform |
| **HS-ADR-027** | Categorical support level only; no cross-provider numeric confidence as truth | Avoid false precision |
| **HS-ADR-028** | Human review required before applying catalog candidates; partial apply allowed | Human authority |
| **HS-ADR-029** | Understandings are versioned via immutable supersession | Reprocessing/model drift |
| **HS-ADR-030** | AI (+ processing) consent required before transcription/understanding port calls; revoke blocks future calls | Enforce HS-ADR-021 |
| **HS-ADR-031** | Understanding operates on original-language material; translation remains HS.5 | Multilingual boundary |

Optional note ADR if needed during impl:

- Event set confirmation (`Proposed` / `Reviewed` / `Superseded`) — may fold into HS-ADR-022

---

## AN. Architectural Drift / Technical Debt

| Finding | Class | HS.4 handling |
|---------|-------|---------------|
| Maps/glossary omit Hero & Story | Documentation drift | Report; defer broad rewrite |
| `AGENTS.md` still says HS.1 next | Documentation drift | Report; update only if authorized |
| `bounded-contexts.md` HS.1 status | Documentation drift | Report |
| Legacy `StoryCapturePort` stub | Technical debt / intentional | Replace transcription path with new port |
| `DateTime.now()` in Story/Hero | Technical debt (TD-007) | Prefer request `at`; Clock optional |
| AI consent unused | Intentional until HS.4 | **Required correction in HS.4** — enforce |
| Media orphan GC / prod storage ACL | Deferred | Out of HS.4 |
| HS.1 Foundation transcript-in-HS.3 wording | Superseded | Already corrected by HS.3 docs |
| No HS.4 blockers in HS.3 capture design | — | None found |

**HS.4 blocker list:** none identified.

**HS.4 required corrections:** enforce AI consent; keep authoritative classify path; add understanding persistence boundary.

---

## AO. Deferred Work

| Item | Owner |
|------|-------|
| Production AI providers | Post-HS.4 |
| Production transcription services | Post-HS.4 |
| Edited transcript authoring UX | HS.5 / UI |
| Translation / scripts / narration | **HS.5** |
| Embeddings / semantic search | Later |
| Personalization / recommendations / feed | Later |
| Discovery consumption of understanding | Later Discovery phase |
| Hero identity enrichment from stories | Not planned (policy forbid sensitive auto-inference) |
| Full privacy/compliance platform | Later |
| Moderation platform | Later |
| Marketplace / monetization | Later |
| Production cloud media ACLs | Later |
| Review UI | Later UI phase |
| `StoryTranscribed` event | Only if consumer appears |
| Automatic deletion on AI consent revoke | Later privacy policy |
| Clock port adoption across Hero & Story | Debt cleanup |

---

## AP. Definition of Done

### AP.1 Planning DoD (this document)

- [x] Architecture decisions identified (HS-ADR-022…031 proposed)
- [x] AI boundary established (two ports)
- [x] AI provider decoupled (mock/in-memory only in plan)
- [x] Story understanding model established (`StoryUnderstanding` aggregate)
- [x] Canonical-vs-proposal distinction preserved
- [x] Provenance established (representation + understanding)
- [x] Human review boundary established
- [x] Consent enforcement defined
- [x] Versioning/reprocessing defined
- [x] Failure/retry behavior defined
- [x] Multilingual behavior defined
- [x] Discovery boundary preserved
- [x] Personalization boundary preserved
- [x] HS.5 boundary preserved
- [x] Test strategy defined
- [x] File-level implementation plan complete
- [x] No production code implemented during planning

### AP.2 Future implementation DoD (for coding agents)

- [ ] HS-ADR-022…031 recorded in `architecture-decisions.md`
- [ ] `StoryUnderstanding` + repository + tests
- [ ] Transcription + understanding ports + in-memory adapters
- [ ] Consent-gated use cases
- [ ] Review + apply without silent classify-on-generate
- [ ] Idempotency stores
- [ ] Events minimal set
- [ ] `dart analyze` clean
- [ ] Focused Hero & Story tests pass
- [ ] Full suite pass
- [ ] No production AI SDKs
- [ ] Implementation report written

---

## AQ. Final Architectural Recommendation

Adopt this pipeline:

```text
Hero lived experience
  → HS.3 captured original audio representation
  → HS.4 StoryTranscriptionPort → derived transcript representation
  → HS.4 StoryUnderstandingPort → StoryUnderstanding (proposed)
  → Human review (accept / modify / reject / partial)
  → Authoritative Story mutators (classify / suitability / spirituality)
  → HS.5 authoring / translation / published representations
  → Discovery / Personalization (later; separate)
```

**Key structural choice:** `StoryUnderstanding` as a **separate aggregate** with its own repository, referencing `StoryId`, never silently mutating canonical Story metadata.

**Key ethical choice:** treat AI output as proposal/observation with provenance; forbid sensitive identity inference; keep Discovery theme ownership intact; keep personalization out.

---

## AR. Implementation Readiness

### Verdict

# READY FOR IMPLEMENTATION

### Why ready

- HS.3 baseline is complete and coherent
- No HS.3 defect requires redesign
- Aggregate/port/consent/event/repository boundaries are decidable from code + ADRs
- Closed catalog model and representation model provide clear attachment points
- Risks (auto-canonization, identity inference, provider coupling) have explicit mitigations

### Remaining non-blockers (do not delay start)

- Stale architecture maps/glossary/`AGENTS.md` phase status
- Production provider selection (intentionally deferred)
- Identity-rich reviewer authorization (opaque actor id acceptable for HS.4)
- Optional `StoryTranscribed` event

### Start here

1. Record HS-ADR-022…031  
2. Implement Slice 1 domain model + tests  
3. Proceed through slices 2–7 without adding production AI SDKs  

---

*End of HS.4 Story Understanding / AI Plan.*
