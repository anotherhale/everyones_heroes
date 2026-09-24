# Post-J.2 Architecture Reassessment

- **Document type:** Architecture reassessment + next-slice plan (planning only)
- **Status:** Complete — no implementation authorized by this document
- **Baseline (code):** `main` @ `4b84f0a` — Implement J.2 Slice 4 live Story candidate discovery (#62)
- **Date:** 2026-09-24
- **Constraint:** Documentation and discovery only. Do not treat this file as authorization to implement the recommended slice.

---

## 1. Executive Summary

J.2 completed the **platform Discovery vocabulary and Story-candidate seams** that sit between Journey understanding and Today’s Experience. The adaptive loop is now architecturally real on EH Platform:

```text
Reflection → Behavioral Evidence → Behavior Patterns
        ↓
AdaptiveDiscoverySignals (catalog-aligned themes ∪ patterns)
        ↓
DiscoverableStoryCandidatePort ← Postgres discoverable_story_candidates
        ↓
AdaptiveExperienceComposer
        ↓
Today's Experience (adaptive-story-* | reflection fallback)
```

What is **not** yet real in production is the **ingest path** that keeps that candidate projection populated from Flutter’s authoritative Hero & Story aggregates. Slice 4 built eligibility, projection schema, ranking, and a transitional upsert use case — but **no reactor or Flutter publish path** writes candidates after `StoryPublished`.

**Verdict:** The architecture is coherent enough to continue feature development. The highest-leverage next slice is **not** Growth Opportunity Detection, a Personalization Engine, or full D.1 DiscoveryProfile productization. It is closing the **owner Story → discoverable candidate → Today** vertical so the seams J.2 created produce a user-visible adaptive result from real authored stories.

---

## 2. Current Architecture Snapshot

### 2.1 Git starting point (verified)

| Fact | Value |
|------|-------|
| Branch evaluated | `main` (synced with `origin/main`) |
| HEAD | `4b84f0a` — Implement J.2 Slice 4 live Story candidate discovery (#62) |
| Immediate predecessors | `db1225d` (Slice 4 plan), `5a0a279` (J.2 Slices 1–3), `56db481` (D.1 plan), `a8d92ad` (J.1) |
| Earlier HS/SB landmark | HS.FG.3 (`1f59d30` merge), SB.13 materialization, HS architecture checkpoint after SB.13 |

Do **not** treat older phase docs (including `AGENTS.md` “HS.1 authorized next”) as describing current authorization. Code + recent phase reports win.

### 2.2 Runtime topology

```text
/workspace (Flutter app: everyonesheroes)
  lib/features/
    discovery/      — DiscoveryProfile, Influence, NarrativeTheme (Flutter foundation)
    life_journey/   — Journey, Quest, Reflection, H.2, UI.3/HS.8 client path
    hero_story/     — Hero, Story, StoryBuilderSession, StoryUnderstanding, SB.1–13
  services/
    eh_platform/    — modular monolith (Identity lite, LJ/H.2, Discovery catalog,
                      Experience Today, HS candidate projection)
    ai_proxy/       — OpenAI credential boundary for Story Builder / HS AI ports
```

There is **no** Melos `packages/` layout. Dual-stack (Flutter domain + EH Platform) is intentional transitional architecture (PF.2 / PF.3).

### 2.3 Authority today (when `EH_PLATFORM_URL` / platform mode is on)

| Concern | Authority |
|---------|-----------|
| Journey / Reflection / evidence / patterns | **EH Platform** (Postgres) |
| Experience Selection / `GET /v1/experiences/today` | **EH Platform** Experience |
| NarrativeTheme reference catalog + signal resolution | **EH Platform** Discovery (+ Flutter mirror) |
| Discoverable Story candidates (read) | **EH Platform** Postgres projection |
| Hero / Story / Story Builder / media / publish | **Flutter** Hero & Story (file / in-memory) |
| DiscoveryProfile / Influence product UX | **Flutter only**, unwired to Experience |
| AI secrets / OpenAI | **`ai_proxy`** (Flutter adapters call ports → proxy) |

### 2.4 Behavioral-understanding pipeline status

| Boundary | Status |
|----------|--------|
| Reflection (multi-modal responses) | **Implemented** |
| Behavioral Evidence | **Implemented** (H.2) |
| Behavior Patterns on Journey | **Implemented** (H.2; rule-based) |
| Growth Opportunities | **Intentionally deferred** — no types; not earned |
| Discovery Profile (person inspiration aggregate) | **Partially implemented** (Flutter domain); platform **planned** (D.1) |
| Personalization Engine | **Intentionally deferred** — Experience Selection is deterministic composition, not a general engine |
| Adaptive Experience / Today | **Implemented** (UI.3 → HS.8 → J.1 → J.2) |

---

## 3. Documentation vs Implementation Reconciliation

| Area | Intended Architecture | Current Implementation | Status | Concern |
|------|----------------------|------------------------|--------|---------|
| Bounded contexts | Identity, Discovery, HS, Life Journey, Contribution | LJ + HS rich; Discovery foundation; Identity lite on platform; Contribution = ID only; Experience = **application module** (not BC) | Working / evolved | Docs still say Discovery “Planned”; Experience sometimes misread as BC |
| Aggregate ownership | Journey owns patterns; Reflection owns evidence/themes; Discovery owns NarrativeTheme; HS owns Story/Hero | Matches | Working as intended | — |
| Entities / VOs | Multi-modal ReflectionResponse; StoryClassification multidimensional | Matches | Working as intended | `StoryProposal` is VO + repository (aggregate-shaped) |
| Repositories | Aggregate repos; no BehaviorPatternRepository | Matches; platform Journey/Reflection Postgres; HS file/memory; Discovery in-memory | Working / transitional | HS file persistence temporary until Phase 7 |
| Application use cases | Orchestration in application layer | ~15 LJ, ~69 HS, 2 Discovery Flutter UCs; platform Experience + LJ + projection UC | Working | use-case-map.md understates HS/platform |
| Domain services | PatternDetector, InsightExtraction, analyzers behind ports | Implemented both stacks | Working | Duplicate `BasePatternRule`; incomplete Recovery rule |
| Ports | AI / search / capture / coach behind ports | HS ports rich; platform `AiOrchestrationPort` stub; Experience candidate/signal ports | Working | Platform AI unused by J.2 (correct) |
| Infrastructure adapters | Replaceable | Postgres LJ + candidates; file HS; in-memory Discovery; ai_proxy adapters | Working / transitional | Dual Flutter↔platform domain copies |
| Domain events | Past-tense facts; reactors for cross-aggregate | H.2 reactors wired; HS events raised; **no Story→candidate reactor** | Partial | Projection sync gap |
| Event reactors | EventBus → reactors → use cases | `ReflectionSubmittedReactor`, `BehavioralEvidenceDetectedReactor` (both stacks) | Working | Candidate projection not event-driven yet |
| Riverpod / composition | Presentation composition, not domain engine | Flutter providers; platform `PlatformComposition` modules | Working | — |
| Presentation / application | UI consumes application contracts | Mostly respected; Home Today via use cases | Working | DiscoverScreen still prototype cards |
| Persistence | Platform Postgres for LJ; HS → Phase 7 | As designed transitional | Evolved | Projection table ahead of Story tables |
| AI boundaries | Domain ⟂ AI; ports → adapters → proxy | Intact for HS/SB; platform stub | Working as intended | Do not let AI own Story truth |
| Hero & Story context | Separate BC; catalog ≠ personalization | Preserved; Discover* + eligibility policies | Working | Flutter authority vs platform projection |
| Story Builder | Capability inside HS | SB.1–13 in `hero_story/` | Working / clean enough | StoryProposal modeling debt |
| Adaptive experience | Understanding → selection → Today → action → reflection → update | Realized on platform + Flutter fallback | Working | Empty candidates → always reflection on platform until sync |
| Behavioral evidence | Observational; precedes patterns | Implemented | Working | — |
| Behavior patterns | Journey-owned; deterministic rules | Implemented | Working | Enum values without rules |
| Discovery | Themes + Influence → inspiration | Catalog + signals on platform; Profile Flutter-only | Partial | D.1 not authorized |
| Current Journey | Controllable context | Flutter `CurrentJourneyContext`; platform `findCurrentByUserId` | Evolved | Two definitions of “current” |
| Media / transcription | Ports + HS.9 capture | Implemented Flutter + ai_proxy | Working | Web durability deferred (PF.2) |
| Testing boundaries | Domain/application first | Platform j2/j1/h2 tests; Flutter suite large | Working | Legacy duplicate LJ test tree |

### Explicit classifications

1. **Working as intended:** Hexagonal dependency direction; NarrativeTheme Discovery ownership; H.2 evidence→patterns; Experience fail-closed to reflection; AI behind ports; HS catalog ≠ personalization; Story Builder inside HS.
2. **Evolved beyond original docs:** Dual-stack platform; Experience application module; discoverable_story_candidates projection before Story Postgres; AdaptiveDiscoverySignals as transitional personalization input; AD-008 “pattern detection is future” obsolete in fact.
3. **Stale documentation:** `AGENTS.md` HS.1-next; `technical-debt.md` TD-001; `aggregate-map` / `event-flow` / `use-case-map` / `repository-map` understate HS/platform; `bounded-contexts.md` Discovery Planned; CLAUDE.md AD-008 wording; HS Roadmap sequence vs PF/J path.
4. **Actual architecture drift:** Orphan `PatternsDetected`; duplicate `BasePatternRule` / unused `BehavioralEvidence` twin; Flutter signal resolver lacks `NarrativeThemeAlignment`; StoryProposal VO+repo; empty open section in `architecture-drift.md` despite new drifts.
5. **Technical debt that matters now:** Candidate projection sync gap; dual current-Journey semantics; incomplete theme classification (always `discovery`); dual-stack catalog mirrors.
6. **Architectural debt before more features:** Productize candidate ingest **or** accept empty adaptive-story path; document Experience as application capability; close TD-001 as resolved.
7. **Premature / unjustified abstractions:** GrowthOpportunity aggregate; Narrative Guidance Engine; public Discovery REST; general Personalization Engine; Kafka/outbox.
8. **Duplicated concepts to unify later:** Flutter↔platform LJ domain copies; NarrativeTheme catalogs; Discover* vs projection adapters; `PatternsDetected` vs `BehaviorPatternsDetected`.
9. **Missing boundaries now obvious:** Event/application path from Flutter Story authority → platform candidate projection; optional Identity↔Hero link beyond lite auth; content-aware theme resolution port (still deterministic/stub).

---

## 4. What J.2 Changed Architecturally

### 4.1 Capabilities made real

J.2 is not “another feature.” It established **reusable platform seams**:

| Seam | Owner | Role |
|------|-------|------|
| `NarrativeThemeReferenceCatalog` + `NarrativeThemeReferenceIds` | Discovery | Shared vocabulary (14 themes) |
| `NarrativeThemeAlignment` | Discovery | Legacy / unknown ID hygiene |
| `CatalogAlignedNarrativeThemeResolver` | Discovery → LJ Analyze | Catalog-valid Reflection themes |
| `CatalogAlignedAdaptiveDiscoverySignalResolver` | Discovery → Experience port | Derives signals at read time |
| `DiscoverableStoryCandidatePort` | Experience | Consumption boundary |
| `StoryCandidateSource` + Postgres projection | Hero & Story (platform) | Candidate supply without Story aggregate |
| `AdaptiveStoryCandidateEligibilityPolicy` | Hero & Story | HS.6 discoverability rules on projection facts |
| `DeterministicStoryRelevanceRanker` | Hero & Story / Experience path | Theme overlap → pattern boost → recency |
| `AdaptiveExperienceComposer` (unchanged contract) | Experience | Story-or-reflection composition |

### 4.2 End-to-end flow (platform authority)

```text
User opens Home
  → todayExperienceProvider
  → PlatformGetTodayExperienceUseCase
  → GET /v1/experiences/today
  → ExperienceApplicationService
       → JourneyRepository.findCurrentByUserId
       → AdaptiveDiscoverySignalPort.resolve
            (Reflection.narrativeThemes → NarrativeThemeAlignment
             ∪ Journey.behaviorPatterns)
       → DiscoverableStoryCandidatePort.findRelevant
            → PostgresStoryCandidateSource
            → DeterministicStoryRelevanceRanker
       → AdaptiveExperienceComposer
  → TodayExperienceDto → AdaptiveExperience → UI

Parallel understanding update:
User ReflectScreen → SubmitReflection (platform)
  → ReflectionSubmitted → AnalyzeReflection
  → BehavioralEvidenceDetected → DetectPattern
  → Journey.behaviorPatterns + Reflection.narrativeThemes persisted
  → next Today GET sees updated signals
```

### 4.3 Where J.2 forced evolution beyond older docs

1. **Hero & Story on platform without Story aggregate** — projection DTO + eligibility facts instead of premature Phase 7 migration.
2. **Experience consumes Discovery vocabulary without owning it** — hard dependency-direction tests.
3. **Seed → live projection retirement** — architectural seed demoted to test fixture only.
4. **Transitional sync use case** — `ProjectDiscoverableStoryCandidateUseCase` acknowledged as Phase-7-replaceable, not permanent event architecture.
5. **D.1 deliberately not pulled into J.2** — DiscoveryProfile remains planning-only despite older “Discovery next” narratives.

### 4.4 Platform capability vs phase-specific scaffold

**Reusable:** theme catalog, alignment, signal port, candidate port, ranker, composer, eligibility policy, projection schema.

**Still phase-specific / incomplete:** manual/test upsert of candidates; dual Flutter Discover* path without platform sync; always-`discovery` analyzer theme emission.

---

## 5. Current Bounded Context Map

```text
Identity (lite)
     │
     ├──────────────┐
     │              │
     ▼              ▼
Discovery      Hero & Story
     │              │
     │              │  (candidate projection on platform)
     └──────┬───────┘
            ▼
     Life Journey
            │
            ▼
     Contribution (not implemented)

Experience Selection = application capability spanning LJ + Discovery + HS ports
                       (not a sixth bounded context)
```

| Context | Responsibility | Aggregate roots | Owned data | Inbound | Outbound | Published events | Consumed | Application APIs |
|---------|----------------|-----------------|------------|---------|----------|------------------|----------|------------------|
| **Identity** | Who is the person / session | `User` (lite) | Auth principal, Postgres identity | Clients | Auth to other modules | (session issuance) | — | Dev session / bearer |
| **Discovery** | What inspires; theme vocabulary | `DiscoveryProfile` (Flutter); catalog entities on platform | Themes, Influences (Flutter), preferences | LJ theme evidence (read) | Theme IDs to HS/Experience | InfluenceAdded/Removed, NarrativeThemesResolved (Flutter) | — | AddInfluence, ResolveThemes; platform signal resolver |
| **Life Journey** | How the person grows | Journey, Quest, Reflection | Quests/Missions, evidence, patterns | Identity user | Patterns/themes to Experience | ReflectionSubmitted, BehavioralEvidenceDetected, BehaviorPatternsDetected, … | — | Submit/Analyze reflection, DetectPattern, Journey CRUD |
| **Hero & Story** | Human stories & heroes | Hero, Story, StoryBuilderSession, StoryUnderstanding | Catalog, suitability, SB sessions/proposals | Discovery theme IDs | Candidates to Experience; Story→Reflection start | StoryPublished, HeroCreated, SB session events, … | — | Authoring, Discover*, Builder, publish |
| **Contribution** | Helping others grow | — | `ContributionId` only | — | — | — | — | — |
| **Experience** *(app)* | Select Today’s Experience | — | DTOs only | Signals + candidates + Journey | Today DTO | — | — | `GET /v1/experiences/today` |

### Ambiguous ownership (flagged)

| Concept | Ambiguity | Recommendation |
|---------|-----------|----------------|
| `StoryProposal` | VO + identity + lifecycle + repo | Normalize to aggregate **when** next SB/persistence slice touches it — not as a standalone cleanup |
| `AdaptiveDiscoverySignals` | Discovery produces; Experience consumes DTO | Keep; do not promote to DiscoveryProfile prematurely |
| `discoverable_story_candidates` | HS owns projection; Experience owns port | Correct; document as derived read model |
| Current Journey | Session context vs latest-updated | Explicit product rule in next Journey slice |
| Experience | Sometimes spoken of as BC | Keep as application module (PF.1/PF.2) |

---

## 6. Current Aggregate Map

| Root | Owned entities / VOs | Repository | Lifecycle ops | Key invariants | Emitted events | External refs |
|------|----------------------|------------|---------------|----------------|----------------|---------------|
| **Journey** | Vision/chapter fields; `behaviorPatterns[]` | JourneyRepository | create, advance chapter, update patterns | Vision; patterns replaced via domain method | JourneyCreated, ChapterAdvanced, BehaviorPatternsDetected | UserId |
| **Quest** | Mission[] | QuestRepository | create, complete missions | Missions under quest | QuestCreated, QuestCompleted, Mission* | JourneyId |
| **Reflection** | ReflectionResponse[], Insight[], BehavioralEvidence[], NarrativeThemeId[] | ReflectionRepository | create, add responses, submit, add insights/evidence/themes | Responses immutable after submit | ReflectionSubmitted, InsightsGenerated, BehavioralEvidenceDetected, NarrativeThemesAdded | JourneyId?, QuestId?, MissionId? |
| **DiscoveryProfile** | Influence, UserDiscovery, preferences; theme resolution | DiscoveryProfileRepository (+ Influence/NarrativeTheme repos) | add/remove influence, resolve themes | Profile consistency | InfluenceAdded/Removed, NarrativeThemesResolved | UserId, NarrativeThemeId |
| **Hero** | HeroProfile VO | HeroRepository | create, update profile, visibility, archive | Discoverability via visibility+status | HeroCreated, HeroProfileUpdated | UserId? |
| **Story** | StoryRepresentation[], classification, suitability, spirituality, provenance, consent, visibility, lifecycle | StoryRepository | capture→submit→approve→publish→archive; classify; representations | Consent gates; publish constraints; catalog dims | StoryCreated/Submitted/Approved/Published/… | HeroId, NarrativeThemeId[] |
| **StoryBuilderSession** | Prompts/responses/progress/intent/mode | StoryBuilderSessionRepository | create, answer, pause, resume, complete, abandon | Mode guided|ai | SessionCreated/Completed | HeroId, StoryId? |
| **StoryUnderstanding** | Proposed catalog understanding | StoryUnderstandingRepository | propose, review, supersede | Non-authoritative until reviewed | Proposed/Reviewed/Superseded | StoryId |
| **StoryProposal** *(not typed as aggregate)* | Sections, review, provenance | StoryProposalRepository | build, shape, approve/reject, materialize | Review before materialization | (via use cases / session) | SessionId → StoryId on materialize |

### Aggregate health notes

- **Story** is large but coherent (lifecycle + representations + classification). Watch for further growth.
- **Journey** correctly owns patterns; do not move patterns to DiscoveryProfile.
- **No LifeJourney root** yet (docs’ future hierarchy) — acceptable.
- Application code generally mutates via aggregate methods + use cases; projection upsert is application-level by design.

---

## 7. Current Event Flow

### 7.1 Active H.2 pipeline

```text
Reflection.submit
  → ReflectionSubmitted
  → ReflectionSubmittedReactor
  → AnalyzeReflectionUseCase
  → InsightsGenerated, BehavioralEvidenceDetected, NarrativeThemesAdded
  → BehavioralEvidenceDetectedReactor
  → DetectPatternUseCase / DefaultDetectPatternUseCase
  → Journey.updateBehaviorPatterns
  → BehaviorPatternsDetected
```

### 7.2 Hero & Story (raised; limited reactors)

```text
Hero.create → HeroCreated
Story.publish → StoryPublished
StoryBuilderSession … → StoryBuilderSessionCreated / Completed
StoryUnderstanding … → Proposed / Reviewed / Superseded
```

**No production reactors** currently project `StoryPublished` into `discoverable_story_candidates`.

### 7.3 Event architecture findings

| Finding | Detail |
|---------|--------|
| Orphaned | Flutter `PatternsDetected` (unused) |
| Missing handlers | StoryPublished / Archived / visibility → candidate projection |
| Handlers doing too much | H.2 reactors are appropriately thin (delegate to use cases) |
| Direct orchestration OK | Experience Today path is synchronous read composition (correct — not event theater) |
| Duplicate naming | Docs mention DetectBehaviorPatterns*; code uses DetectPattern* |
| Unnecessary events | Do not add events for Today selection |
| Doc says event-driven, code direct | Experience Selection is intentionally direct application orchestration |

---

## 8. Current Application Use-Case Flow

### Today (platform)

```text
ExperienceApplicationService.getTodayExperience
  → load Journey
  → resolve AdaptiveDiscoverySignals
  → findRelevant Story candidates
  → AdaptiveExperienceComposer.compose
  → TodayExperienceDto
```

### Today (Flutter local / offline)

```text
DefaultGetTodayExperienceUseCase
  → CurrentJourneyContext + JourneyRepository
  → DefaultResolveAdaptiveDiscoverySignalsUseCase  // no NarrativeThemeAlignment
  → DiscoverStoriesCandidateAdapter → DiscoverStoriesUseCase
  → AdaptiveExperienceComposer
```

### Story Builder → Story

```text
Intent → Guided/AI prompts → Understanding → Proposal
  → Shape (deterministic|AI) → Hero review → MaterializeStoryProposal
  → draft Story (+ ClassifyStory with theme bridge)
  → Submit → Approve → Publish (owner path)
```

### Discovery (Flutter only today)

```text
AddInfluenceUseCase → ResolveNarrativeThemesUseCase
  // not wired into Experience Selection
```

---

## 9. AI Boundary Assessment

```text
Domain aggregates / use cases
        ✕  AI SDK / OpenAI
Application
        ↓
Domain ports (StoryBuilderCoachPort, StoryShaperPort, StoryUnderstandingPort, …)
        ↓
Adapters (Proxy* / InMemory*)
        ↓
services/ai_proxy  → OpenAI
```

| Question | Assessment |
|----------|------------|
| Domain free of AI SDKs? | **Yes** |
| Platform AI? | `AiOrchestrationPort` + `StubAiProviderAdapter` only; **not** used by J.2 |
| Too generic? | Platform port is intentionally thin; HS ports are domain-specific — good |
| Duplicated? | Multiple HS ports by concern (coach / authoring / transcription) — justified |
| Provider leak inward? | Contained in ai_proxy + adapters |
| AI as canonical truth? | SB materialization + HS.4 understanding require review/approval — **preserved** |
| J.2 ranking AI? | **Correctly absent** (deterministic) |

**Principle holds:** AI may assist Story Builder and understanding; it must not silently author behavioral truth or publish lived experience.

---

## 10. Hero & Story Assessment

Separation **preserved**:

```text
Hero & Story (catalog / lifecycle / builder)
        ↓  DiscoverableStoryCandidate (projection / Discover*)
Discovery (themes / future profile)
        ↓  AdaptiveDiscoverySignals
Experience Selection
        ↓
Today's Experience
```

- Catalog taxonomy remains on Story (`StoryClassification`), not personalization.
- Theme bridge (`StoryBuilderThemeNarrativeThemeBridge`) maps Builder themes → Discovery IDs without importing Discovery aggregates.
- Story interaction → Reflection path exists; listening does not auto-create BehavioralEvidence.
- Platform HS module is **candidate projection only** until PF.2 Phase 7 — intentional.

**Risk:** Until projection sync exists, platform Today cannot consume Flutter-authored published stories. That is an integration gap, not a boundary violation.

---

## 11. Story Builder Assessment

| Slice | Status | Architectural note |
|-------|--------|--------------------|
| SB.1–5 | Complete | Session aggregate + file persistence |
| SB.6 | Complete | Guided vs AI mode |
| SB.7 | Complete | Coach port + proxy; strategy replaceable |
| SB.8–11 | Complete | Understanding + proposal + shaping |
| SB.12–13 | Complete | Review + materialize to **draft** Story |

**Ownership:** Story Builder is a **capability inside Hero & Story**, not a new BC. Code confirms this; some docs speak of SB as a program — nomenclature only.

**Clean enough to continue**, with known debt:

1. `StoryProposal` should eventually be an aggregate (or explicitly documented application artifact).
2. Two “understanding” models (`StoryBuilderUnderstanding` vs `StoryUnderstanding`) — related but distinct; keep names clear.
3. AI coach must remain non-authoritative relative to Hero-approved narrative.

**Normalize before continuing?** Only if the next slice edits proposal persistence/lifecycle. Do not open a cleanup-only phase.

---

## 12. Adaptive Experience Assessment

UI.3 seam:

```text
Current Understanding
        ↓
Experience Selection
        ↓
Today's Experience
        ↓
Action
        ↓
Reflection
        ↓
Updated Understanding
        ↓
Next Experience
```

**Does current code realize this loop?** **Yes**, with qualifications:

| Step | Realization |
|------|-------------|
| Understanding | Journey.behaviorPatterns + Reflection.narrativeThemes (+ catalog alignment on platform) |
| Selection | `AdaptiveExperienceComposer` + deterministic fallback |
| Today | Home + `GET /v1/experiences/today` |
| Action | Begin experience / reflect / story consume |
| Reflection → update | H.2 reactors update patterns/themes |
| Next Experience | Subsequent Today GET recomposes |

**Reusable architecture that now exists:** signal port, candidate port, composer, fail-closed reflection fallback, platform Today API, Flutter platform client + cache.

**What is missing for a full product demo on platform:** non-empty live candidates from real publish; richer theme signals than always-`discovery`; optional DiscoveryProfile inputs (D.1).

**Do not** invent a recommendation engine — deterministic theme-overlap selection is sufficient and matches AD-007.

---

## 13. Architecture Drift Reassessment

`architecture-drift.md` currently lists **only CLOSED** historical items (DRIFT-003…009) and an empty open summary. That is itself drift: new discrepancies are not recorded.

| Proposed ID | Item | Exists on main? | Priority now | Action |
|-------------|------|-----------------|--------------|--------|
| DRIFT-010 | TD/docs claim “no pattern detection” while H.2 exists | Yes (doc) | High (doc) | Close TD-001; update AD-008 note |
| DRIFT-011 | Flutter AdaptiveDiscoverySignals skip `NarrativeThemeAlignment` | Yes | Medium | Fix in parity slice or with projection sync |
| DRIFT-012 | StoryPublished ↛ candidate projection | Yes | **High (product)** | Next recommended slice |
| DRIFT-013 | Orphan `PatternsDetected` + duplicate BasePatternRule / BehavioralEvidence twin | Yes | Low | Hygiene when touching LJ |
| DRIFT-014 | `StoryProposal` VO+Repository | Yes | Medium | Normalize when SB persistence next touched |
| DRIFT-015 | Aggregate/event/use-case/repository maps stale vs HS+platform | Yes | Medium | Doc update pass |
| DRIFT-016 | `AGENTS.md` HS.1-next / known-issues partially outdated | Yes | Medium | Refresh AGENTS authorization section |
| — | FakeNarrativeThemeResolver production wiring | **Resolved** (delegates / catalog-aligned) | — | Keep deprecated aliases or remove later |
| — | DRIFT-005 DiscoveryProfile missing | **Closed** for Flutter aggregate existence; platform productization still open as **debt**, not same drift | — | Track under D.1 |

---

## 14. Technical Debt Reassessment

| ID | Doc status | Reality on `4b84f0a` | Recommendation |
|----|------------|----------------------|----------------|
| **TD-001** Pattern Detection | Open High | **Implemented** (H.2) | **CLOSE** — replace with residual rule-coverage debt |
| **TD-002** Growth Opportunity | Open High | Missing | Keep Open; **deprioritize** — not next |
| **TD-003** Narrative Guidance | Open High | Missing | Keep Open; deferred |
| **TD-005** Contribution | Open Medium | ID only | Keep; frozen |
| **TD-006** Event Pipeline | Open Medium | H.2 wired; GO unwired; Story→candidate unwired | **Rewrite** — partial; track projection sync separately |
| **TD-007** Clock Injection | Open Low | Still `DateTime.now()` in Reflection etc. | Keep Low |
| **TD-008** Reflection Query | Open Medium | `findByJourneyId` exists | **CLOSE** primary; optional quest/mission queries remain nice-to-have |
| **TD-004** DiscoveryProfile | CLOSED | Flutter yes; platform no | Leave closed; D.1 tracks platform |
| **TD-H2-001** Iterable | Deferred | Still `List<>` | Keep Deferred |
| **NEW TD-J2-001** Candidate projection sync | — | Transitional UC only | **Open High** — blocks adaptive-story demo on platform |
| **NEW TD-J2-002** Analyzer always emits `discovery` | — | Intentional J.2 limit | Open Medium — understanding quality |
| **NEW TD-J2-003** Dual current-Journey definitions | — | Context vs updated_at | Open Medium |

---

## 15. Architectural Seams Created by Recent Work

| Seam | Problem solved | Why now | Owner | Depends on it | Must NOT own | Stable? |
|------|----------------|---------|-------|---------------|--------------|---------|
| Adaptive Experience Selection | Deterministic Today choice | UI.3→J.1 | Experience app | Home UI, platform API | Taxonomy, Story persistence | **Yes** |
| AdaptiveDiscoverySignals | Read-time understanding DTO | HS.8→J.2 | Discovery resolves; Experience consumes | Composer | Profile storage, ranking ML | **Yes** (transitional vs Profile) |
| DiscoverableStoryCandidatePort | Decouple Experience from HS storage | HS.8→J.2 | Experience | Composer | Eligibility policy internals | **Yes** |
| Story candidate Postgres projection | Live candidates without Story aggregate | J.2.4 | Hero & Story platform | Candidate source | Authoring, media | **Yes** as read model; sync transitional |
| NarrativeTheme catalog + alignment | Shared vocabulary | J.2.1–2 | Discovery | LJ analyze, HS bridge, signals | Personalization rules | **Yes** |
| AI proxy + SB coach ports | Credential & provider isolation | SB.7+ | Infrastructure / HS ports | Builder AI mode | Canonical Story text | **Yes** |
| Theme bridge | Builder themes → Discovery IDs | HS.FG.2 | HS application | Materialization/classify | Discovery entities | **Yes** |
| CurrentJourneyContext | UI session Journey | UI.2/UI.3 | LJ application | Flutter Today local | Platform current definition | Partial — dual model |
| H.2 reactors | Evidence→patterns without UI orchestration | H.2 | LJ application | Journey patterns | Experience selection | **Yes** |
| Owner publish composition | Submit→Approve→Publish | HS.FG.1 | HS application | Discoverability | Auto Hero visibility | **Yes** |

---

## 16. Open Architectural Questions

1. **How should Flutter Story authority update platform candidates before Phase 7?** (HTTP command vs shared DB vs event bridge)
2. **What is the product definition of “current Journey”** across Flutter session and platform `updated_at`?
3. **When does DiscoveryProfile earn platform productization** relative to Influence UX?
4. **Should content-aware theme resolution be deterministic rules first, or a port with AI later?**
5. **Is Experience ever a bounded context**, or permanently an application capability?
6. **StoryProposal aggregate promotion** — now or on next SB persistence change?
7. **Phase 7 timing** vs continuing dual-stack with projection sync?
8. **GrowthOpportunity** — introduce only after patterns demonstrably under-serve Experience Selection?

---

## 17. Candidate Next Slices

| Candidate | User Value | Architectural Value | Dependencies | Risk | Scope |
|-----------|------------|---------------------|--------------|------|-------|
| **A. Candidate projection productization** — publish/archive/visibility → eligibility → Postgres → Today adaptive-story | Owner’s published story can appear on seeker’s Today when themes overlap | Closes J.2’s intentional gap; validates HS→Experience seam with real data | J.2.4 projection, HS.FG publish, eligibility policy | Dual-stack sync design; avoid Phase 7 creep | Small–medium vertical |
| **B. Deterministic content-aware theme resolution** | Reflections produce meaningful theme variety beyond `discovery` | Improves signal quality feeding selection | Catalog, AnalyzeReflection | Overfitting themes; AI temptation | Small domain+tests |
| **C. Flutter/platform signal parity** (`NarrativeThemeAlignment` on Flutter) | Consistent Today offline vs platform | Removes DRIFT-011 | J.2 alignment service | Low user visibility | Small |
| **D. D.1 thin DiscoveryProfile → Experience** | Influence-based inspiration affects Today | Advances PF Phase 6 vision | D.1 authorization, Influence UX | Premature without product surface; large | Medium–large |
| **E. HS theme-aware catalog / owner→seeker handoff** | Better Flutter Discover* after publish | Completes Master Plan “NEXT” | HS.FG.3 | Doesn’t fix platform Today empty candidates | Medium Flutter |

### Tradeoffs / assumptions validated

- **A** validates: projection as durable read model; eligibility in production; fail-closed still holds; Experience stays ignorant of Story aggregates.
- **B** validates: catalog vocabulary can be applied to reflection content without AI; AD-014 derive-vs-store.
- **C** validates: dual-stack can converge without new abstractions.
- **D** validates: PF-ADR-014 Option C (prefer profile when populated) — but assumes Influence product value exists.
- **E** validates: Flutter discoverability composition — orthogonal to platform adaptive loop.

**Growth Opportunity Detection** intentionally excluded — patterns already drive Experience Selection; a new aggregate would be speculative.

---

## 18. Recommended Next Slice

### Recommendation: **Candidate A — Live Story Candidate Projection Productization** (working name: **J.2.5** or **HS→Experience Candidate Sync**)

**Why this, not the Master Plan “theme-aware catalog” or D.1:**

1. J.2 Slice 4 **explicitly left** sync transitional; continuing without it leaves the newest platform seam inert in real use.
2. It is the **smallest vertical** that turns existing architecture into a demonstrable product loop with real human stories.
3. It increases the platform’s ability to **act on understanding** (theme∩pattern → story experience) without a Personalization Engine or GrowthOpportunity layer.
4. D.1 remains valuable but **unauthorized** and larger; Influence UX is still thin.
5. Master Plan catalog handoff improves Flutter Discover*; it does **not** feed `GET /v1/experiences/today` on platform.

**Architectural assumptions this slice validates:**

- Derived projections can bridge Flutter HS authority and platform Experience without migrating Story aggregates.
- Eligibility policy is sufficient gate for adaptive candidates.
- Event/application orchestration (not Experience domain logic) owns sync.

---

## 19. Proposed Implementation Plan

### Purpose

Establish a **production ingest path** so eligible published Stories appear in `discoverable_story_candidates` and can surface as `adaptive-story-{id}` on Today when AdaptiveDiscoverySignals overlap.

### Architectural question

Can Hero & Story remain Flutter-authoritative while Experience on EH Platform consumes a **live, eligibility-gated projection** — without Phase 7 Story migration and without putting personalization inside Story?

### Domain changes

- Prefer **no new aggregates**.
- Reuse `StoryCandidateEligibilityFacts`, `AdaptiveStoryCandidateEligibilityPolicy`, `StoryCandidateRecord`.
- Possibly add a small application DTO/mapper from Flutter Story+Hero → eligibility facts (no second Story model).

### Application changes

- Wire post-publish / archive / visibility / classification-theme changes to invoke projection upsert/invalidate.
- Options (choose smallest that works in current deploy topology):
  1. **Platform HTTP command** called from Flutter after successful Publish/Archive/visibility (explicit application sync), or
  2. **Platform reactor** once Story events are platform-visible.
- Prefer (1) if Story events remain Flutter-local — honest about dual-stack.
- Expose `ProjectDiscoverableStoryCandidateUseCase` via a narrow API only if needed; do not widen Experience port.

### Infrastructure changes

- Reuse migration `003_j2_discoverable_story_candidates.sql`.
- Add API route **only if** required for Flutter→platform sync (e.g. `PUT/DELETE /v1/hero-story/candidates/{storyId}` with auth).
- No new AI. No ML ranking changes.

### Presentation changes

- Minimal: ensure owner publish success path triggers sync.
- Optional demo: Home Today shows adaptive story after publish + matching reflection themes — integration test and/or manual script.
- No new Discover screens.

### Events

- Prefer **application orchestration after existing `StoryPublished` / archive / visibility use cases** on Flutter.
- Add platform domain events **only if** sync moves fully onto platform Story authority (out of scope).
- Do **not** invent `StoryCandidateProjected` unless another consumer needs it.

### Persistence

- Upsert/delete rows in `discoverable_story_candidates` only.
- No Flutter file-repo redesign.

### Tests

| Level | Coverage |
|-------|----------|
| Unit | Eligibility facts mapping from Story+Hero snapshots |
| Application | Publish eligible → projection upsert; archive → remove; private → remove; theme-less → not projected |
| Integration | Postgres projection → Today returns `adaptive-story-*` when signals overlap |
| UI | Optional smoke: publish then Today card id/title (platform mode) |
| Architecture | Experience still does not import Story aggregate; HS still does not own Experience selection |

### Documentation

Update after implementation (not in this reassessment PR beyond recording intent):

- `J.2-Discovery-Platform-Foundation.md` / Slice 4 plan — mark sync productized
- `architecture-drift.md` — open DRIFT-012 → closed when done
- `technical-debt.md` — add/close TD-J2-001
- `event-flow.md` / `repository-map.md` — projection sync path
- `AGENTS.md` — current phase authorization
- HS Master Plan — note platform adaptive ingest vs Flutter catalog handoff

### Definition of Done

See §20.

### Explicit non-goals

See §21.

---

## 20. Definition of Done

Concrete, verifiable criteria for the recommended slice:

1. Publishing an eligible Story (HS.6/J.2 eligibility) results in a corresponding `discoverable_story_candidates` row when platform is configured.
2. Archiving or making a Story non-discoverable removes or invalidates that row.
3. `GET /v1/experiences/today` can return `adaptive-story-{storyId}` for overlapping catalog themes without using the architectural seed catalog.
4. Empty/ineligible cases still fail closed to default reflection.
5. No Story aggregate / media / authoring migrated to platform.
6. No GrowthOpportunity, Personalization Engine, or public Discovery REST.
7. `dart analyze` clean on touched packages; focused j2 + publish sync tests pass; relevant platform suite green.
8. Short analysis note records sync mechanism choice and Phase 7 replacement path.

---

## 21. Explicit Non-Goals

Do **not** build yet:

- Growth Opportunity Detection / Narrative Guidance Engine
- Generalized Personalization Engine or ML ranking
- Full D.1 DiscoveryProfile platform productization (until authorized)
- Public Discovery REST / Influence marketplace UX
- PF.2 Phase 7 full Hero & Story platform authority migration
- Contribution context
- AI theme classification as default
- Rewriting ADRs to match accidental drift
- Broad hygiene (orphan events, duplicate BasePatternRule) unless blocking
- Mission as Experience Selection output
- Kafka / transactional outbox
- Second Story source of truth

---

## 22. Documentation Updates Required

| Document | Update needed | Urgency |
|----------|---------------|---------|
| `technical-debt.md` | Close TD-001, TD-008 (primary); add TD-J2-001/002/003; rewrite TD-006 | High |
| `architecture-drift.md` | Record open drifts DRIFT-010+; stop empty “open” summary | High |
| `AGENTS.md` | Replace HS.1-next with post-J.2 authorization; refresh known issues | High |
| `bounded-contexts.md` | Discovery status; Experience as app capability; Identity lite | Medium |
| `aggregate-map.md` / `event-flow.md` / `use-case-map.md` / `repository-map.md` | HS + platform + projection | Medium |
| `architecture-decisions.md` AD-008 | Annotate pattern layer now implemented; future = higher-order patterns | Medium |
| HS Master Plan / Roadmap | Cross-link platform J.2.5 vs Flutter catalog handoff | Medium |
| `D.1-…Plan.md` | Note J.2.4 complete; baseline commit; still awaiting auth | Low |
| `CLAUDE.md` | Known stale; do not expand — point to AGENTS/ADRs | Low |
| This document | Living reference until next reassessment | — |

**Smallest correction policy:** Prefer updating inventories and debt/drift trackers over rewriting completed-phase narratives. Do not silently change code to match stale maps.

---

## Architecture Verdict

1. **Is the current architecture coherent enough to continue feature development?**  
   **Yes.** Hexagonal boundaries, H.2 pipeline, Experience Selection, Discovery vocabulary ownership, and HS/Story Builder separation are coherent. Dual-stack is intentional transitional architecture, not accidental chaos.

2. **Are there architectural problems that should be fixed before the next feature?**  
   **One product-blocking gap:** live candidate projection sync (Story authority → Postgres candidates). Secondary: document/debt staleness (TD-001) and Flutter signal alignment parity. No need to halt for GrowthOpportunity, Personalization Engine, or Phase 7.

3. **What is the smallest meaningful next vertical slice?**  
   **Candidate projection productization (J.2.5):** eligible owner publish/archive → `discoverable_story_candidates` → Today `adaptive-story-*` when themes overlap — reusing J.2.4 seams without new frameworks.

4. **What should explicitly NOT be built yet?**  
   Growth Opportunities, Narrative Guidance Engine, generalized Personalization, D.1 without authorization, public Discovery API, full HS platform migration, Contribution, AI-owned behavioral or story truth.

5. **What architecture documentation is now stale and needs updating?**  
   `AGENTS.md` phase authorization; `technical-debt.md` TD-001 (and related); empty open `architecture-drift.md`; Life Journey–centric maps (`aggregate-map`, `event-flow`, `use-case-map`, `repository-map`, `bounded-contexts` Discovery status); AD-008 “future pattern layer” wording; HS Roadmap sequence relative to PF/J.2 path.

---

*End of reassessment. No implementation is authorized by this document.*
