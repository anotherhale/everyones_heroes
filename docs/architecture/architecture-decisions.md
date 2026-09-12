# Architecture Decisions

This document records significant architectural decisions for Everyone's Heroes.

Architecture Decision Records (ADRs) describe intentional choices that guide future development.

When implementation and documentation disagree:

1. Review the ADRs.
2. Determine whether implementation or documentation should change.
3. Update the ADR if the architecture direction has evolved.

ADRs should change rarely.

---

# AD-001 Reflections Are Multi-Modal

Status: Accepted

Date: 2026

Original Design:

Reflection
├── ReflectionContent

Current Design:

Reflection
├── ReflectionResponse[]

Supported Response Types:

* JournalResponse
* PromptResponse
* EmojiResponse
* ScaleResponse
* ChoiceResponse
* VoiceResponse
* PhotoResponse

Rationale:

Different people process growth differently.

Some users prefer journaling.

Some users prefer structured prompts.

Some users prefer lightweight emotional check-ins.

The domain should support multiple reflection styles without changing the Reflection aggregate.

---

# AD-002 Narrative Themes Belong To Discovery

Status: Accepted

Date: 2026

Decision:

NarrativeTheme ownership belongs to the Discovery bounded context.

Life Journey should reference:

NarrativeThemeId

instead of:

NarrativeTheme

Rationale:

Narrative Themes connect:

* Influences
* Reflections
* Stories
* Music
* Missions
* Recommendations

Because Narrative Themes span multiple contexts, Discovery owns them.

---

# AD-003 Influence Is A First-Class Concept

Status: Accepted

Date: 2026

Decision:

Influences are not metadata.

Influences are recommendation primitives.

Examples:

* Michael Jordan
* Rocky Balboa
* Aragorn
* Atomic Habits

Influences should resolve into one or more Narrative Themes.

Recommendation flow:

Influence
↓
Narrative Theme
↓
Recommendation

Rationale:

The long-term personalization engine should be grounded in explicit inspiration sources rather than opaque AI inference.

---

# AD-004 Reflections Generate Evidence

Status: Accepted

Date: 2026

Decision:

Reflections generate observations.

They do not directly generate growth.

Current Flow:

Reflection
↓
Insights
↓
Behavioral Evidence

Behavioral Evidence may represent:

* Strengths
* Weaknesses
* Avoidance
* Fear
* Courage
* Discipline
* Consistency

Rationale:

Growth should be inferred from observations over time.

The system should avoid making immediate conclusions from a single reflection.

---

# AD-005 Growth Signals Are Being Deprecated

Status: Accepted

Date: 2026

Decision:

The architecture is evolving away from:

* GrowthSignal
* GrowthSignalEvidence
* GrowthSignalGenerated

Toward:

* BehavioralEvidence
* BehavioralEvidenceDetected
* Evidence Source

BehavioralSignal entity removed.

Rationale:

GrowthSignal implied positive progress.

Behavioral Evidence is observational and neutral.

Observations may represent:

* Strengths
* Weaknesses
* Avoidance
* Opportunities

Future implementations should prefer Behavioral Evidence terminology.

---

# AD-006 Growth Does Not Automatically Transfer Between Journeys

Status: Accepted

Date: 2026

Decision:

Growth demonstrated in one journey should not automatically improve measurements in another journey.

Example:

Strong discipline in Health
≠
Strong discipline in Relationships

Rationale:

Behavior is contextual.

People often demonstrate strengths in one area while struggling in another.

The system should not assume direct trait transfer.

---

# AD-007 Theme Overlap Is More Important Than Trait Transfer

Status: Accepted

Date: 2026

Decision:

The platform should detect:

Theme Overlap

rather than:

Trait Transfer

Example:

Health Journey
↓
Commitment
↓
Persistence

Relationship Journey
↓
Commitment

This overlap may create:

* Encouragement
* Reflection Prompts
* Recommendations
* Coaching Opportunities

Rationale:

Narrative connections create insight without requiring artificial score transfers.

---

# AD-008 Pattern Detection Is A Future Layer

Status: Accepted

Date: 2026

Decision:

Future architecture should evolve toward:

BehavioralEvidence
↓
Pattern Detection
↓
Guidance

Potential Pattern Types:

* StrengthPattern
* AvoidancePattern
* EmergingGrowthPattern
* GrowthOpportunityPattern

Rationale:

Patterns emerge from multiple observations.

Patterns should not be manually stored.

Patterns should be derived.

---

# AD-009 AI Is An Implementation Detail

Status: Accepted

Date: 2026

Decision:

AI providers must remain outside the domain.

Allowed:

Domain Service Interfaces

Examples:

* InsightExtractionService
* BehavioralEvidenceAnalyzer
* NarrativeThemeResolver

Not Allowed:

* OpenAI references in aggregates
* Anthropic references in entities
* AI SDK dependencies in value objects

Rationale:

The domain should remain independent from AI vendors.

Providers should be replaceable.

---

# AD-010 Domain First

Status: Accepted

Date: 2026

Decision:

The domain model is the product.

Preferred Development Order:

Aggregate
↓
Tests
↓
Use Cases
↓
Infrastructure
↓
UI

Rationale:

Business rules should exist before implementation details.

This supports long-term architectural stability.

---

# AD-011 Event Driven By Default

Status: Accepted

Date: 2026

Decision:

Cross-context communication should occur through domain events.

Preferred:

ReflectionSubmitted
↓
Handler
↓
Use Case

Avoid:

ReflectionUseCase
↓
Directly Calling
↓
JourneyUseCase

Rationale:

Events reduce coupling between bounded contexts.

Events support future extensibility.

---

# AD-012 The Long-Term Moat

Status: Accepted

Date: 2026

Decision:

The long-term value of Everyone's Heroes is not AI.

The moat is:

* Discovery Engine
* Influence Catalog
* Narrative Themes
* Personal Hero Journey
* Adaptive Narrative Guidance

Rationale:

AI models will continue to evolve and commoditize.

The unique value comes from the domain model and accumulated user understanding.

---

# AD-013 Evidence Before Guidance

Status: Accepted

Date: 2026

Decision:

The platform should preserve observations before generating conclusions.

Preferred Flow:

BehavioralEvidence
↓
Pattern Detection
↓
Growth Opportunity
↓
Narrative Guidance

Avoid:

BehavioralEvidence
↓
Narrative Guidance

Rationale:

Guidance should be explainable.

Recommendations should be traceable.

The system should be able to answer:

"Why did I receive this recommendation?"

using observable evidence.

Benefits:

* Explainability
* Transparency
* Better coaching quality
* Reduced AI hallucination risk
* Stronger domain model

Implications:

Behavioral Evidence should be stored.

Patterns should be derived.

Guidance should be generated.

Avoid skipping intermediate layers simply because AI makes it possible.

---

# AD-014 Store Observations, Derive Interpretations

Status: Accepted

Date: 2026

Decision:

Prefer storing raw observations over storing conclusions.

Store:

* Reflection Responses
* Behavioral Evidence
* Narrative Themes
* Influences

Derive:

* Patterns
* Opportunities
* Recommendations
* Guidance

Avoid:

* Arbitrary scores
* Opaque growth ratings
* AI-generated conclusions without evidence

Rationale:

Stored observations retain long-term value.

Interpretations may evolve as the platform becomes more sophisticated.

The platform should preserve the facts and allow future systems to derive better insights from them.

---

# ADR-15 — Behavioral Evidence Is Atomic

Status: Accepted

Date: 2026-06

## Context

The original Life Journey design introduced the concept of a Growth Signal. As the domain evolved, it became clear that growth-oriented signals represented only one subset of observable human behavior.

Reflections may reveal strengths, growth, weaknesses, avoidance patterns, fears, blind spots, emerging capabilities, or other behavioral characteristics. A model focused solely on growth signals imposed an unintended positive bias and limited future analysis capabilities.

The architecture requires a neutral, evidence-based representation of observed behavior that can support future pattern detection, growth opportunity identification, and narrative guidance.

## Decision

Behavioral Evidence is the atomic behavioral observation within the domain.

A BehavioralEvidence instance represents a classified observation derived from a source of evidence.

BehavioralEvidence consists of:

* BehavioralEvidenceType
* EvidenceSource
* Strength

BehavioralEvidence does not represent interpretation across time, behavioral trends, or growth opportunities.

BehavioralEvidence is intentionally small and context-independent.

Example:

```text
BehavioralEvidence
    Type: Discipline
    Source: Reflection #123
    Strength: 0.85
```

## Evidence Sources

BehavioralEvidence must reference an EvidenceSource.

Current EvidenceSource implementations:

* ReflectionEvidenceSource
* MissionEvidenceSource

Future sources may include:

* ContributionEvidenceSource
* MentorshipEvidenceSource
* DiscoveryEvidenceSource
* ExternalAssessmentEvidenceSource

## Event Model

Reflections publish:

```text
BehavioralEvidenceDetected
```

when behavioral evidence is identified.

BehavioralEvidenceDetected contains one or more BehavioralEvidence instances.

The event represents newly detected evidence, not long-term conclusions.

## Consequences

### Positive

* Supports both strengths and weaknesses.
* Eliminates positive bias inherent in Growth Signal terminology.
* Enables future pattern detection across multiple observations.
* Provides a stable foundation for AI-assisted analysis.
* Supports multiple evidence sources.
* Aligns with event sourcing and event-driven architecture.

### Negative

* Additional layers are required to derive meaning from evidence.
* BehavioralEvidence alone cannot determine growth opportunities.
* Future pattern detection infrastructure is required.

## Future Architecture

BehavioralEvidence is the foundation for future adaptive narrative systems.

Expected progression:

```text
BehavioralEvidence
        ↓
Pattern Detection
        ↓
DetectedPattern
        ↓
Growth Opportunity Detection
        ↓
GrowthOpportunity
        ↓
Narrative Guidance Engine
        ↓
Narrative Guidance
```

BehavioralEvidence remains the atomic observation throughout this pipeline.

## Deprecated Concepts

The following concepts are deprecated and should not be used in new development:

* GrowthSignal
* GrowthSignalGenerated
* GrowthSignalObserved

Existing references should be migrated to:

* BehavioralEvidence
* BehavioralEvidenceDetected

## Related ADRs

* AD-001 Hexagonal Architecture
* AD-010 Domain First
* AD-011 Behavioral Signals Become Behavioral Evidence

---

# Architectural North Star

Everyone's Heroes exists to help people:

Challenge
↓
Action
↓
Reflection
↓
Behavioral Evidence
↓
Pattern Detection
↓
Growth Opportunities
↓
Narrative Guidance
↓
Contribution

Every major architectural decision should support this progression.

---

# HS-ADR-001 Hero & Story Is a Dedicated Bounded Context

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

Hero & Story is a dedicated bounded context under `lib/features/hero_story/`.

It owns Heroes, Stories, representations, media references, catalog classification,
content suitability, spirituality/religion classification, provenance, and
Hero/Story relationships.

It does not own Behavioral Evidence, Behavior Patterns, Growth Opportunities,
Discovery Profiles, personalization decisions, or Life Journey progression.

Rationale:

Separating cataloged human stories from Discovery (what inspires a person) and
Life Journey (how a person grows) preserves content vs personalization boundaries.

---

# HS-ADR-002 Story Is the Canonical Narrative; Media Are Derivatives

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`Story` is the canonical domain aggregate representing a lived narrative.

Audio, transcript, translation, script, video, and related artifacts are
`StoryRepresentation` entities belonging to the Story. They do not replace the Story.

Rationale:

One Story may exist across many formats and languages without duplicating the
conceptual narrative.

---

# HS-ADR-003 Narrative Themes Remain Owned by Discovery

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

Hero & Story references themes via `NarrativeThemeId` only.

Hero & Story must not define or own `NarrativeTheme` entities.

Rationale:

Preserves AD-002 and keeps thematic vocabulary consistent across Influences,
Stories, Reflections, Missions, and Recommendations.

---

# HS-ADR-004 Multilingual Representation Is Fundamental to Story

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`LanguageCode` is a shared value object.

Every Story has an explicit `originalLanguage`.

Representations declare their language, origin (original/translated/derived),
and optional source representation.

Rationale:

Language support must not be bolted on later.

---

# HS-ADR-005 Story Provenance Must Be Preserved Through Transformation

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

Stories retain `StoryProvenance` with ordered `ProvenanceStep` records for each
representation transformation.

Rationale:

Trust, correction, attribution, and future AI processing require lineage.

---

# HS-ADR-006 AI-Generated Story Artifacts Are Non-Authoritative Until Approved

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`StoryRepresentation.isAiGenerated` representations are not authoritative until
explicitly approved via `Story.approveRepresentation`.

AI may assist with transcription, translation, and formatting. AI must not
silently manufacture experiences, facts, achievements, beliefs, quotations, or
motivations.

Rationale:

The Hero remains the authority over what they intended to communicate.

---

# HS-ADR-007 Story Cataloging Is Multidimensional

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

Stories are classified with `StoryClassification` containing controlled
dimensions (subject, challenge, narrative theme ids, outcome, emotional
character, audience, geography) rather than an unstructured tags collection.

Rationale:

Enables meaningful multidimensional discovery queries.

---

# HS-ADR-008 Content Suitability Is Independent From Story Classification

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`ContentSuitability` is a separate value object with per-dimension levels
(profanity, violence, sexual content, substance use, disturbing content).

It is not collapsed into subject/theme classification or personalization.

Rationale:

Classification answers what a story is about; suitability answers what it
contains for filtering/appropriateness.

---

# HS-ADR-009 Spirituality and Religion Are Separate Story Classifications

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`SpiritualityClassification` models non-spiritual / spiritual / religious story
content. Optional `ReligiousTradition` applies only when religious.

Story religious content must not be inferred as the Hero's personal religious
identity.

Rationale:

Protects sensitive identity boundaries while allowing content filtering.

---

# HS-ADR-010 Content Classification Does Not Determine Personalization

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

Hero & Story provides available cataloged content.

Discovery determines what inspires a person.

Personalization (future) determines what a person should experience next.

Search ports in Hero & Story perform catalog filtering only.

Rationale:

Prevents the catalog from becoming a hidden personalization engine.

---

# HS-ADR-011 Story Interaction Does Not Automatically Constitute Behavioral Evidence

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

HS.1 does not model Story interactions as Behavioral Evidence.

Future interaction → reflection/action → evidence flows must remain evidence-first
and owned by Life Journey.

Rationale:

Listening to a story is not proof of inspiration or growth.

---

# HS-ADR-012 Search and Discovery Implementations Are Replaceable

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`StorySearchPort`, `HeroSearchPort`, and `StoryCapturePort` are replaceable
domain/application contracts.

HS.1 ships deterministic in-memory adapters and an unsupported capture stub.
Production search, media, and AI pipelines remain future work.

Rationale:

Domain must not couple to a particular search engine, media store, or AI vendor.

---

# HS-ADR-013 AggregateType Distinguishes Hero and Story

Status: Accepted

Date: 2026-09-10

Phase: HS.1

Decision:

`AggregateType.heroStory` placeholder is replaced with separate `hero` and
`story` values matching the two aggregate roots.

Rationale:

Domain events must identify the owning aggregate accurately.

---

# HS-ADR-014 Local Story Catalog Taxonomies Are Closed Enums

Status: Accepted

Date: 2026-09-11

Phase: HS.2

Decision:

Local Story Catalog dimensions remain closed Dart enums for HS.2:

* `StorySubject`
* `StoryChallenge`
* `StoryOutcome`
* `EmotionalCharacter`
* `StoryAudience`
* representation format/origin enums
* suitability/spirituality enums

Hero & Story must not introduce taxonomy repositories, taxonomy aggregates,
runtime taxonomy IDs, or taxonomy database infrastructure in HS.2.

Narrative themes remain Discovery-owned and are referenced only by
`NarrativeThemeId`.

Rationale:

HS.1 already established closed enums as the working model. Extensible
taxonomies are deferred until product requirements justify them.

---

# HS-ADR-015 AI Classification Is Deferred To HS.4

Status: Accepted

Date: 2026-09-11

Phase: HS.2

Decision:

HS.2 does not implement classification proposals, pending classification state,
AI classification approval workflows, classification history, or AI adapters.

`ClassifyStoryUseCase` / `Story.classify` remain the authoritative classification
path. `StoryClassified` means authoritative classification was applied.

AI-assisted classification proposal → human approval → authoritative catalog
state belongs to HS.4 Story Understanding.

Rationale:

Preserves the architectural boundary without prematurely expanding the Story
aggregate with proposal lifecycle.

---

# HS-ADR-016 Duration Queries Match Any Eligible Representation

Status: Accepted

Date: 2026-09-11

Phase: HS.2

Decision:

Duration is owned by `StoryRepresentation` and is not duplicated on `Story`.

`StorySearchQuery.minDuration` / `maxDuration` match a Story when ANY
representation with a non-null duration satisfies the constraint.

When both minimum and maximum are provided, the same representation must
satisfy the full window.

A representation with null duration does not satisfy duration constraints.

Rationale:

Stories may have multiple language/format representations of different lengths.
Catalog filtering should discover a Story if any available representation fits
the listener's duration constraint.

---

# HS-ADR-017 Provisional Narrative For Capture Drafts

Status: Accepted

Date: 2026-09-12

Phase: HS.3

Decision:

Capture-created Stories may use a provisional `StoryNarrative` marked via
`StoryNarrative.provisional()` until the Hero authors the canonical narrative.

Provisional narrative is not AI-authored content and is not an audio substitute
for Story. Approve and publish require a non-provisional narrative.

Rationale:

Preserves HS-ADR-002 (Story remains the canonical narrative aggregate) while
allowing capture-first workflows before authoring (HS.5) or understanding (HS.4).

---

# HS-ADR-018 CaptureSession Is Application Workflow Only

Status: Accepted

Date: 2026-09-12

Phase: HS.3

Decision:

`CaptureSession` is not a domain aggregate, entity, value object, or repository
concept. Capture orchestration is an application workflow. A `sessionId` may be
used for idempotency only.

Rationale:

Device/recording process state does not protect Story narrative invariants and
must not create a second consistency boundary.

---

# HS-ADR-019 StorySource Is Not Introduced

Status: Accepted

Date: 2026-09-12

Phase: HS.3

Decision:

Do not introduce a `StorySource` type. Original captured audio is modeled as an
original `StoryRepresentation` (`format=audio`, `origin=original`) with
`StoryTransformationType.recording` provenance.

Rationale:

Avoids duplicating representation/provenance semantics and preserves the
HS.1/HS.2 Story model.

---

# HS-ADR-020 StoryMediaStoragePort Is The Replaceable Media Boundary

Status: Accepted

Date: 2026-09-12

Phase: HS.3

Decision:

Introduce `StoryMediaStoragePort` for storing/retrieving/deleting opaque media
bytes. Domain state retains only `MediaReference`. HS.3 ships a deterministic
in-memory adapter. Production cloud adapters are out of scope.

`StoryCapturePort` remains a legacy HS.1 stub (transcription unsupported). Capture
orchestration is performed by `CompleteStoryCaptureUseCase`, not by expanding
`StoryCapturePort` into a storage API.

This updates the replaceability intent of HS-ADR-012 for media storage.

Rationale:

Keeps hexagon boundaries clean and prevents provider coupling in domain code.

---

# HS-ADR-021 Minimal StoryConsent With Independent Gates

Status: Accepted

Date: 2026-09-12

Phase: HS.3

Decision:

Stories own a minimal `StoryConsent` value object with independent timestamps:

* recorded
* processing approved
* publication approved
* AI transformation approved

`submit` requires processing consent. `publish` requires publication consent.
AI consent is recorded for future HS.4 gates and is never implied by other
stages. Consent stages are independent: recorded ≠ processing ≠ publication ≠ AI.

Rationale:

Raw captures are sensitive. Explicit independent gates prevent accidental
processing, publication, or future AI transformation without Hero approval.


---

# HS-ADR-022 StoryUnderstanding Is A Separate Aggregate For AI Proposals

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Introduce `StoryUnderstanding` as a separate aggregate root in the Hero & Story
bounded context. It holds AI-derived proposals (candidate catalog dimensions,
observations, provenance, and review state) associated with a `StoryId`.

`StoryUnderstanding` does not embed or replace the `Story` aggregate. Canonical
narrative, classification, suitability, spirituality, representations,
lifecycle, visibility, and consent remain owned by `Story`.

Rationale:

Preserves HS-ADR-015 (authoritative classification stays explicit) and avoids
expanding Story with proposal lifecycle, independent versioning, review
concurrency, and historical analyses that must not corrupt Story state.

---

# HS-ADR-023 AI Proposals Never Auto-Apply To Authoritative Story Catalog

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

AI output persisted on `StoryUnderstanding` is non-canonical. Generating
understanding must never call `Story.classify`, update suitability/spirituality,
or mutate Hero identity.

Approved catalog candidates are applied only through an explicit application
workflow (`ApplyStoryUnderstandingUseCase`) that invokes existing authoritative
Story mutators/use cases after human review.

Rationale:

Enforces "AI may help understand the story; AI does not own the story." Silent
auto-apply would collapse proposal into canonical truth.

---

# HS-ADR-024 Introduce StoryTranscriptionPort And StoryUnderstandingPort

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Introduce two provider-independent ports under `domain/services/`:

* `StoryTranscriptionPort` — media/audio → transcript text result
* `StoryUnderstandingPort` — validated source content → structured understanding draft

Do not expand legacy `StoryCapturePort` into real AI transcription. Keep its
transcription stub unsupported/deprecated relative to the dedicated port.

HS.4 ships deterministic in-memory adapters only. No production AI SDKs or
cloud providers.

Rationale:

Purpose-specific ports preserve replaceability (HS-ADR-012/020 pattern) and
avoid a generic `AIService` that leaks providers into domain/application.

---

# HS-ADR-025 Machine Transcripts Are Derived AI StoryRepresentations

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Machine transcripts are attached as derived `StoryRepresentation`s with
`format: transcript`, `origin: derived`, `sourceRepresentationId` pointing at
the source audio representation, and `isAiGenerated: true`, using existing
`Story.addRepresentation` and provenance (`StoryTransformationType.transcription`).

A transcript is not a separate aggregate and is not automatically the canonical
Story narrative.

Rationale:

Preserves the HS.1/HS.2 representation model and HS-ADR-006 approval semantics
for AI representations.

---

# HS-ADR-026 Understanding Provenance Is A Dedicated Value Object

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Introduce `UnderstandingProvenance` as a minimal analysis-lineage value object
(source representation ids, analyzed timestamp, provider/model labels,
processing/template version, optional categorical support level, optional opaque
provider confidence, optional notes).

Continue using existing `StoryProvenance` / `ProvenanceStep` for representation
lineage. Do not build a generic audit platform. Do not persist complete prompts
containing Hero media on the understanding aggregate by default.

Rationale:

Trust and explainability require analysis-level lineage beyond representation
provenance, without inventing a compliance framework.

---

# HS-ADR-027 Categorical Support Level; No Cross-Provider Numeric Confidence As Truth

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Use optional categorical `AnalysisSupportLevel` (`unknown`, `weak`, `moderate`,
`strong`) as advisory metadata for human review. Do not introduce a normalized
cross-provider numeric confidence field as a domain invariant or auto-approval
threshold.

Opaque provider-specific confidence may remain on provenance for display/audit
only.

Rationale:

Numeric cross-provider confidence creates false precision and risks silent
auto-approval policies.

---

# HS-ADR-028 Human Review Required Before Applying Catalog Candidates; Partial Apply Allowed

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Human review (`accept` / `modify` / `reject` / partial) must be recorded on
`StoryUnderstanding` before catalog candidates may be applied to Story.
Partial review and partial application of independent dimensions
(classification, suitability, spirituality) are allowed.

Rejected understanding must never be applied. Approval of understanding status
alone does not mutate Story until the explicit apply workflow runs.

Rationale:

Keeps human authority over catalog truth while allowing incremental acceptance
of independent dimensions.

---

# HS-ADR-029 Understandings Are Versioned Via Immutable Supersession

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

AI proposal payloads on `StoryUnderstanding` are immutable after creation.
Review may change status/review fields. Reprocessing creates a new
`StoryUnderstandingId` linked via `supersedesUnderstandingId`.

On successful generation, prior successful (non-superseded) understandings for
the Story may become `superseded`. Failed attempts must not supersede prior
versions. History is retained; superseded records are not deleted merely because
they are superseded.

Rationale:

Supports reprocessing, model/schema drift, and auditability without mutating
historical AI payloads.

---

# HS-ADR-030 AI And Processing Consent Required Before AI Port Calls

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

Before calling `StoryTranscriptionPort` or `StoryUnderstandingPort`, application
use cases must load the Story and require both
`consent.isAiTransformationApproved` and `consent.isProcessingApproved`.

Publication consent is not required for private AI understanding. Recording
consent alone is insufficient. If AI consent is revoked, future AI port calls
are prohibited until consent is granted again. Existing understanding records
and AI transcript representations are retained by default.

Rationale:

Enforces the independent AI gate from HS-ADR-021 on the real HS.4 pipeline.

---

# HS-ADR-031 Understanding Operates On Original-Language Material; Translation Remains HS.5

Status: Accepted

Date: 2026-09-12

Phase: HS.4

Decision:

HS.4 transcribes and understands material in the source/original analysis
language. Store `analysisLanguage` and optionally `detectedLanguage` as an
observation. Detected language must not silently mutate `Story.originalLanguage`.

Translation, authored scripts, narration, and alternate authored forms remain
HS.5.

Rationale:

Preserves multilingual provenance and avoids collapsing HS.4 into HS.5
authoring/translation scope.

---

# HS-ADR-032 Story Authoring Produces Unapproved StoryRepresentations; No AuthoringProposal Aggregate

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

HS.5 does not introduce a `StoryAuthoringProposal` aggregate. AI authoring attaches
unapproved `StoryRepresentation` values on the existing Story aggregate (same
pattern as HS.4 transcription). Hero review uses `approveRepresentation`.

Rationale:

Avoids aggregate creep and reuses the proven HS.4 proposal-via-representation model.

---

# HS-ADR-033 Introduce StoryAuthoringPort With Deterministic In-Memory Adapter Only

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Introduce `StoryAuthoringPort` for intentional authored text forms. Ship only a
deterministic in-memory adapter in HS.5. No production AI SDKs, network clients,
or vendor dependencies.

Rationale:

Keeps authoring vendor-independent and testable while preserving replaceability.

---

# HS-ADR-034 AI-Authored Representations Remain Non-Authoritative Until approveRepresentation

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Reinforce HS-ADR-006: AI-authored representations are `isAiGenerated: true` and
`isApproved: false` until `Story.approveRepresentation` / `ApproveStoryRepresentationUseCase`.

Rationale:

AI may help present the story. AI does not own the story.

---

# HS-ADR-035 Canonical Narrative Authorship Is Explicit UpdateStoryNarrative; AI Scripts Do Not Mutate Narrative

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Canonical `Story.narrative` changes only through explicit human
`UpdateStoryNarrativeUseCase` → `Story.updateNarrative`. Generating or approving
a representation must never auto-promote content into the canonical narrative.
Optional promote-from-representation is deferred.

Rationale:

Protects canonical Story authority and prevents AI from becoming an implicit source of truth.

---

# HS-ADR-036 Representation Revision Is Additive For Regeneration; Human Edits May Update Unapproved Text In Place

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Human editing of an unapproved representation updates that representation through
`Story.replaceUnapprovedRepresentationText` (authoritative path) and records an
editing provenance step. Regeneration creates a new derived representation via
the authoring port, preserving provenance. Approved representations cannot be
edited in place. Failed generations do not supersede prior drafts.

Rationale:

Clearly distinguishes human authorship from another AI transformation while
preserving lineage.

---

# HS-ADR-037 Translation Uses origin translated + StoryTranslationPort (Slice B)

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Translation is included as HS.5 Slice B after the script vertical slice. Use
`StoryTranslationPort` + deterministic in-memory adapter. Translated
representations use `RepresentationOrigin.translated`, require a source representation
id, remain unapproved until Hero approval, and must not mutate
`Story.originalLanguage` or canonical narrative.

Rationale:

Honors HS-ADR-031 placement while proving multilingual provenance without
blocking the script architecture proof.

---

# HS-ADR-038 Authoring AI Ports Require Processing + AI Consent (reuse HS-ADR-030)

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

AI authoring and translation ports require processing consent and AI
transformation consent. Human narrative updates and human-only representation
edits do not require AI consent. No parallel StoryAuthoringConsent model.

Rationale:

Reuse HS.4 consent gates; do not invent a second consent subsystem.

---

# HS-ADR-039 Event Minimalism: Reuse StoryRepresentationAdded; Add StoryRepresentationApproved

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

Reuse `StoryRepresentationAdded` for authoring/translation attach. Add
`StoryRepresentationApproved` raised from `Story.approveRepresentation`. Do not
add script-generated, edited, rejected, or published representation events in HS.5.

Rationale:

Approval is a meaningful domain fact; event taxonomy stays minimal.

---

# HS-ADR-040 Initial Authored Formats: script + shortForm; narration/TTS deferred

Status: Accepted

Date: 2026-09-12

Phase: HS.5

Decision:

HS.5 authored formats are `script` and `shortForm` (with `longForm` supported by
the same seam). Narration/TTS, podcast packaging, and production media synthesis
are deferred.

Rationale:

Proves multi-format authoring without expanding into media synthesis scope.
