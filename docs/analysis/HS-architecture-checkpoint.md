# HS Architecture Checkpoint — Hero & Story Platform

**Status:** COMPLETE  
**Date:** 2026-09-22  
**Branch:** `cursor/hs-architecture-checkpoint-3306`  
**Baseline:** `main` @ `ff328bc` (SB.13 merged; Hero & Story Platform Roadmap added)  
**Companion docs:**
- `docs/architecture/Hero and Story Platform Roadmap.md`
- `docs/architecture/Hero and Story Platform Implementation Master Plan.md`
- `docs/analysis/SB-13-story-materialization.md`

---

## 1. Objective

Phase B of the Implementation Master Plan: stop feature implementation after SB.13 and audit the actual Hero & Story codebase against HS foundation expectations, bounded-context rules, and the Story Builder → canonical Story pipeline.

This checkpoint answers:

1. What HS capabilities already exist?
2. Do they fit the architecture?
3. What is the smallest missing foundational capability?
4. What should the next vertical slice be?

---

## 2. Method

Inspected (code is source of truth):

| Layer | Path |
|-------|------|
| Domain | `lib/features/hero_story/domain/` |
| Application | `lib/features/hero_story/application/` |
| Infrastructure | `lib/features/hero_story/infrastructure/` |
| Presentation | `lib/features/hero_story/presentation/` |
| Discovery themes | `lib/features/discovery/domain/` |
| UI.3 / adaptive seam | Life Journey experience selection + Hero Story candidate adapter |
| Prior reports | `docs/analysis/SB-*.md`, `docs/architecture/HS.*.md` |

Status vocabulary matches the Master Plan: **Implemented / Partially Implemented / Planned / Validation Required / Deferred**.

---

## 3. Executive Verdict

```text
SB.13 Story Materialization     → Implemented (verified)
HS.1 Foundation concepts        → Implemented (substantially exceeded)
HS.2–HS.8 capability surface    → Largely Implemented in code
Composition / wiring gaps       → Partially Implemented (highest risk)
Theme bridge Builder→Discovery  → Missing
Presentation boundary purity    → Partial (Story Builder leaks)
```

**Do not restart HS.1 from scratch.**  
The codebase already contains Hero, Story, lifecycle, visibility, provenance, representations, multilingual language codes, multidimensional classification, suitability, spirituality, repositories, capture, understanding (dual path), authoring ports, discovery/search contracts, Hero experience, and adaptive Story candidates.

The remaining work is **gap closure and composition**, not greenfield foundation.

---

## 4. Capability Map — Verified Status

| Capability | Master Plan status (pre-audit) | Verified status | Evidence |
|------------|--------------------------------|-----------------|----------|
| HS.1 Hero & Story Foundation | Validation Required | **Implemented** | Hero + Story aggregates, 5 repos, lifecycle/visibility/provenance/classification/suitability/spirituality/representations |
| SB.13 Story Materialization | Immediate checkpoint | **Implemented** | `MaterializeStoryProposalUseCase`, mapper, provenance fields, idempotency, tests, report |
| HS.2 Story Catalog | Planned / Validation Required | **Implemented** (domain + browse) | `StoryClassification`, catalog browse use case, not unstructured tags |
| HS.3 Story Capture | Validation Required | **Implemented** | Device recording ports, capture completion, media storage |
| HS.4 Story Understanding | Partially Implemented | **Partially Implemented** | Dual path: SB.8 Builder understanding (wired); HS.4 StoryUnderstanding generate/review/apply exist but **unwired** + no file repo |
| HS.5 Authoring & Approval | Substantially via SB.9–12 | **Partially Implemented** | Proposal review/approval + materialization done; script/translate ports weak composition; Story publish path unwired |
| HS.6 Discovery | Planned / Validation Required | **Implemented** (deterministic) | Search/Discover/Browse use cases + in-memory search adapters |
| HS.7 Hero Experience | Planned / Validation Required | **Implemented** (partial playback) | Experience DTOs, consume/begin; seeker audio playback incomplete |
| HS.8 Adaptive Hero Discovery | Planned | **Partially Implemented** | UI.3 seam + DiscoverStories candidate adapter; Builder-born Stories lack theme IDs → weak relevance |

---

## 5. Domain Audit

### 5.1 Aggregates — Implemented

| Aggregate | Path | Notes |
|-----------|------|-------|
| `Hero` | `domain/aggregates/hero.dart` | create, profile, visibility, archive/reactivate; events: Created, ProfileUpdated |
| `Story` | `domain/aggregates/story.dart` | create, createFromCapture, lifecycle ops, classify, representations, consent |
| `StoryBuilderSession` | `domain/aggregates/story_builder_session.dart` | Pre-Story authoring session (SB.*) |
| `StoryUnderstanding` | `domain/aggregates/story_understanding.dart` | HS.4 proposed catalog understanding (≠ Builder understanding) |

`StoryProposal` is a persisted **value object with identity + repository** (intentional SB.9/12/13 design; not `AggregateRoot`).

### 5.2 Lifecycle & Visibility — Implemented (ops Partial)

`StoryLifecycleStatus`:  
`draft | processing | review | approved | published | archived | rejected | suspended | removed`

Materialization creates **`draft` only** (correct for SB.13).

Gaps:

- Enum includes `suspended` / `removed` without `suspend()` / `remove()` methods
- Some mutations are silent (no domain event): Story `reject`, Hero visibility/archive, consent/suitability updates

`StoryVisibility`: `private | draft | unlisted | community | public`  
Discoverability requires **`published` + `{public, community}`** (`StoryDiscoverabilityPolicy`).

### 5.3 Provenance — Implemented

`StoryProvenance` includes SB.13 fields:

- `materializedFromProposalId`
- `sourceSessionId`
- `proposalDerivationKind`
- `proposalContainedDerivedContent`

Hero approval does **not** rewrite proposal `contentOrigin` (derived remains derived). Verified in materialization mapper + SB.13 tests.

### 5.4 Representation & Language — Implemented

`StoryRepresentation` formats: audio, video, written, transcript, script, shortForm, longForm.  
Origins: original | translated | derived.  
`LanguageCode` (shared kernel) + `originalLanguage` + languages derived from representations.

### 5.5 Classification / Suitability / Spirituality — Implemented

Multidimensional `StoryClassification` (subjects, challenges, `NarrativeThemeId[]`, outcomes, emotional character, audience, geography).  
`ContentSuitability` (5 dimensions × levels).  
`SpiritualityClassification` (nonSpiritual / spiritual / religious + optional tradition).

Narrative Themes referenced by **ID only** — Discovery owns `NarrativeTheme`.

### 5.6 Domain events — Implemented (selective)

15 events defined and raised (including StoryCreated, Submitted, Approved, Published, Classified, RepresentationAdded/Approved, Builder session events, Understanding Proposed/Reviewed/Superseded).

AGENTS.md candidate events not present (`StoryProcessingStarted`, `StoryTranscribed`, etc.) — acceptable per “do not invent events without consumers.”

### 5.7 Dependency hygiene — Clean

Hero & Story **domain** does not import Flutter, Riverpod, HTTP, or AI SDKs.  
AI sits behind ports in `domain/services/*_port.dart`.

### 5.8 Known mild drift

- `StoryProposal` behaves like an aggregate (identity + repo) without AggregateRoot/events — intentional for SB authoring.
- Widespread optional `DateTime.now()` fallbacks (known hygiene issue; many APIs accept `at` / `createdAt`).

---

## 6. Application Audit

~68 use cases under `application/use_cases/`.

### Present and wired (representative)

- Story Builder session loop (start → prompts → complete)
- Build / shape / edit / approve / reject / revise proposals
- **MaterializeStoryProposalUseCase** (SB.13)
- CreateStory / CreateHero
- Capture completion + consent
- Discover/Search/Browse Stories & Heroes
- GetStoryExperience / GetHeroExperience / Begin / Consume
- List owned stories / owned detail
- Transcription ownership path

### Present but unwired (composition gap)

| Use case | Impact |
|----------|--------|
| `SubmitStoryUseCase` | Provider exists in places; no full owner publish UX |
| `ApproveStoryUseCase` | No Riverpod provider found |
| `PublishStoryUseCase` | No Riverpod provider found |
| `ClassifyStoryUseCase` | Used via Apply Understanding; not owner-facing alone |
| `GenerateStoryUnderstandingUseCase` | No providers |
| `ReviewStoryUnderstandingUseCase` | No providers |
| `ApplyStoryUnderstandingUseCase` | No providers |
| `GenerateStoryScriptUseCase` | No providers |
| `TranslateStoryRepresentationUseCase` | No providers |

**Architectural consequence:** SB.13 correctly stops at draft Story. Without a composed Submit → Approve → Publish path, Builder-materialized Stories **cannot enter Discover\*** (policy requires published + public/community).

### Materialization boundary — Correct

`MaterializeStoryProposalUseCase` / `StoryMaterializationMapper`:

- Requires `accepted` proposal only
- Creates draft Story via `CreateStoryUseCase`
- Idempotent (deterministic StoryId + `findByStoryProposalId` + `materializedStoryId`)
- Does not publish, classify, discover, or personalize
- Maps narrative/title/provenance only — **no classification / NarrativeThemeIds**

---

## 7. Infrastructure Audit

| Concern | Status | Notes |
|---------|--------|-------|
| Hero / Story / Session / Proposal file repos | Implemented | `HeroStoryDurablePersistence` |
| StoryUnderstanding file repo | **Missing** | In-memory only; lost across durable restarts |
| Snapshot mappers | Implemented | Hero, Story, Session, Proposal |
| Recording adapters | Implemented | Device + fake + unavailable |
| Media storage | Implemented | In-memory + local file |
| Search adapters | Implemented (local) | Deterministic in-memory; replaceable ports |
| AI: Builder coach / understanding / shaper / transcription | Implemented | Proxy + deterministic paths |
| AI: HS.4 StoryUnderstanding / HS.5 authoring / translation | Partial | Ports + in-memory; weak/no composition providers |

Replaceability of capture/transcription/Builder AI is good. Understanding durability and authoring/translation composition are the weak spots.

---

## 8. Presentation Audit

Screens cover Story Builder, Tell Your Story, My Stories, owned detail, catalog, consume, Hero profile.

| Finding | Status |
|---------|--------|
| Experience/owned flows generally use use-case providers | Good |
| Story Builder controller reads `storyRepository` / `storyProposalRepository` directly | **Boundary violation** |
| Story Builder holds domain `Story` / `StoryProposal` in UI state | Domain leakage |
| Approve proposal → auto-materialize; UI states not published | Correct SB.13 UX |
| Seeker consume loads media bytes but does not play audio | Partial |
| Owner playback via `just_audio` | Present |

---

## 9. Cross-Context Audit

### Discovery / Narrative Themes — Correct ownership

- `NarrativeTheme` entity + repository live in Discovery
- Hero & Story stores `NarrativeThemeId` only
- `StoryBuilderTheme` is an explicit **session-local vocabulary**, documented as distinct

**Gap:** No mapper from `StoryBuilderTheme` / Builder understanding → Discovery `NarrativeThemeId`.  
Materialized Stories therefore typically have **empty** `classification.narrativeThemeIds`, weakening HS.8 adaptive matching.

### Story → Behavioral Evidence — Healthy

Begin/Consume/Load media explicitly do **not** create BehavioralEvidence.  
Only optional `StartStoryReflectionUseCase` bridges to Life Journey reflection creation.

### UI.3 Adaptive seam — Present

```text
DiscoverStoriesCandidateAdapter
        ↓
AdaptiveExperienceComposer
        ↓
TodayExperienceViewModel.storyTargetId (string)
        ↓
Experience routing → StoryDetailScreen
```

Home does not import Story aggregates. Good seam.

### Hero & Story → Personalization

Story domain does not personalize. Catalog/Discover supply candidates; Life Journey composer selects. Correct.

---

## 10. Comparison to Master Plan Phases

| Phase | Intent | Checkpoint result |
|-------|--------|-------------------|
| A — SB.13 | Accepted proposal → canonical Story | **Done** on main |
| B — Architecture checkpoint | This report | **Done** |
| C — Foundation gap closure | Only audit-driven gaps | **Next** — see §12 |
| D — Catalog foundation | Structured catalog queries | Domain/browse largely exist; composition + theme bridge remaining |
| E–H | Understanding / Discovery / Experience / Adaptive | Much already in code; treat as validation + gap closure, not greenfield |

---

## 11. Architecture Validation Checklist

| Rule | Result |
|------|--------|
| Story domain AI-independent | Pass |
| Story domain UI-independent | Pass |
| NarrativeTheme ownership in Discovery | Pass |
| Story interaction ≠ BehavioralEvidence | Pass |
| Materialization ≠ publication | Pass |
| Provenance survives Hero approval | Pass |
| No duplicate Story / Hero aggregates | Pass |
| Presentation thin / no direct repos | **Fail** (Story Builder controller) |
| All lifecycle use cases composition-complete | **Fail** (publish/approve/understanding) |
| Builder themes → catalog theme IDs | **Fail** (missing bridge) |

---

## 12. Smallest Missing Foundational Capabilities

Ordered by architectural leverage (not product flash):

1. **Owner Story lifecycle composition (Submit → Approve → Publish)**  
   Use cases exist; Discover\* eligibility depends on published + discoverable visibility. Blocks Builder-born Stories from catalog.

2. **`StoryBuilderTheme` / Understanding → `NarrativeThemeId` bridge**  
   Without this, adaptive relevance cannot see Builder-born catalog themes. Must not create a second NarrativeTheme entity.

3. **Durable `StoryUnderstandingRepository` + HS.4 generate/review/apply providers**  
   Authoritative catalog write path for classification/suitability/spirituality; currently ephemeral in durable apps.

4. **Close Story Builder presentation boundary leaks**  
   Replace direct repository access with use cases / presentation models.

5. **HS.5 script/translation composition**  
   Match transcription replaceability.

6. **Seeker media playback**  
   Port already proven on owner path.

7. **Suspend/remove lifecycle ops + selective events**  
   Enum completeness vs operational completeness.

8. **Identity BC replacing local Hero bootstrap**  
   Correctly deferred (HS-ADR-065) but required for multi-user ownership.

---

## 13. Recommended Next Vertical Slice

### HS.FG.1 — Owner Publish Path Composition

**Objective:** Compose the existing Submit → Approve → Publish (and visibility) use cases so a materialized draft Story can become discoverable through existing Discover\* policies — without inventing new domain concepts, catalogs, or personalization.

**Reuse:**

- `SubmitStoryUseCase`, `ApproveStoryUseCase`, `PublishStoryUseCase`
- `UpdateStoryConsentUseCase` (publication consent gate)
- `StoryDiscoverabilityPolicy`
- Owned story UI (`My Stories` / owned detail)

**Inspect first (before coding):**

- Exact publish preconditions on `Story.publish`
- Existing owned-story providers and screens
- Consent requirements
- Whether a thin orchestration use case is needed vs wiring existing ones

**Must not include:**

- New discovery algorithms
- Personalization
- Theme mapping (defer to HS.FG.2)
- Media generation
- Moderation systems
- Changing SB.13 materialization defaults to auto-publish

**Definition of Done:**

```text
Accepted Proposal
     ↓
Materialize → draft Story
     ↓
Owner Submit → Approve → Publish (+ discoverable visibility + consent)
     ↓
DiscoverStories / Browse catalog can return the Story
     ↓
Tests + analyzer + implementation report
```

**Follow-on slice (HS.FG.2):** Builder theme → `NarrativeThemeId` mapping via explicit application contract (optionally through Apply Understanding / ClassifyStory).

Full slice plan: `docs/analysis/HS-FG-1-owner-publish-path-plan.md`.

---

## 14. Deferred / Out of Scope

- Social/community systems
- Production semantic search
- Marketplace
- Engagement optimization
- Full personalization engine
- Inventing reactors for Story events without a concrete consumer
- Broad cleanup of known naming hygiene from AGENTS.md §29

---

## 15. Documentation Drift Noted

| Item | Classification |
|------|----------------|
| Master Plan / historical HS order assumed greenfield HS.1 | Documentation drift — code is ahead |
| Some HS-ADR text may predate HS.8 adaptive Story selection | Documentation drift — treat later ADRs + code as current |
| Legacy CLAUDE.md GrowthSignal language | Known stale; AGENTS.md + code win |
| `StoryCapturePort` stub vs DeviceRecordingPort | Intentional supersession |

No broad documentation rewrite performed in this checkpoint beyond this report, the Master Plan status update, and the next-slice plan.

---

## 16. Conclusion

The Hero & Story platform foundation is **real and substantial**. SB.13 correctly established the first controlled proposal → Story transition.

The architecture checkpoint finds the next risk is not missing aggregates — it is **incomplete composition** of already-designed lifecycle and catalog paths, plus a missing **Builder → Discovery theme bridge**.

Proceed with **HS.FG.1 Owner Publish Path Composition**, then **HS.FG.2 Theme Bridge**, then reassess durable Story Understanding wiring.
