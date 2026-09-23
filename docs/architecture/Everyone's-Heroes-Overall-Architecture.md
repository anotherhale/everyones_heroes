# Everyone's Heroes — Overall Architecture

**Document type:** Platform Foundation Planning (PF.1)  
**Status:** Authoritative high-level architecture & migration plan  
**Date:** 2026-09-23  
**Scope:** Planning only — no application implementation authorized by this document  
**Baseline inspected:** `main` @ `1f59d30` (post HS.FG.3)

---

## 1. Purpose

This document is the authoritative high-level architecture and platform-migration plan for Everyone’s Heroes (EH).

It answers:

1. What architecture exists in the **current codebase** (source of truth)?
2. Where documentation and code disagree?
3. What a future **EH Platform** (server-owned domain + Flutter client) should look like?
4. How to migrate incrementally without destroying working capabilities?
5. Which architectural decisions must be made **before** implementation?

### Constraints of this phase (PF.1)

This document is a **planning artifact**.

It does **not** authorize:

* application source changes
* Rust implementation
* server scaffolding beyond what already exists (`services/ai_proxy`)
* Dart → platform migration
* Flutter architecture rewrites
* dependency / API / schema changes

Next implementation phases require separate authorization after review.

### Source-of-truth hierarchy used in this evaluation

1. Current Architectural Decision Records (ADRs) when they reflect intentional decisions.
2. Current implementation when an architectural decision has clearly been implemented.
3. Current active phase documentation (`AGENTS.md`, recent HS analysis).
4. Architecture maps / inventories.
5. Completed-phase / historical documentation.
6. Legacy agent instructions (`CLAUDE.md`).

When code and docs disagree, discrepancies are classified explicitly rather than silently reconciled.

---

## 2. Architectural North Star

Everyone’s Heroes is an adaptive **human growth platform**.

Core product loop:

```text
Experience → Action → Reflection → Understanding → Personalization → Growth → New Experience
```

Architectural principle:

> The user experiences transformation; the architecture records understanding.

Long-term moat (not AI providers):

* Discovery Engine
* Influence Catalog
* Narrative Themes
* Personal Hero Journey
* Adaptive Narrative Guidance
* Hero & Story catalog of lived experience

AI may assist; it must not own human stories, fabricate lived experience, or collapse evidence into hidden conclusions.

Evidence → Patterns → Guidance is preferred over Evidence → Guidance shortcuts.

---

## 3. Current System Architecture

### 3.1 Repository shape (actual)

```text
everyones_heroes/                    Flutter application (primary runtime)
├── lib/
│   ├── app/                         Composition root, shell, theme
│   ├── bootstrap/                   Event reactor registration
│   ├── core/                        Shared kernel + in-process eventing
│   └── features/
│       ├── life_journey/            Growth / reflection / patterns / experience
│       ├── discovery/               Influence / NarrativeTheme / DiscoveryProfile
│       └── hero_story/              Hero, Story, capture, builder, AI ports, UI
├── services/
│   └── ai_proxy/                    Separate Dart Shelf process (OpenAI boundary)
├── test/                            Mirrors lib/ + integration + legacy trees
└── docs/architecture|analysis|ui/   Planning, ADRs, phase reports
```

Approximate scale (baseline):

| Area | Approx. Dart files |
|------|--------------------|
| `lib/features/hero_story` | ~389 |
| `lib/features/life_journey` | ~134 |
| `lib/core` | ~67 |
| `lib/features/discovery` | ~22 |
| `test/` | ~200 test files |
| `services/ai_proxy` | thin OpenAI proxy |

### 3.2 Dependency structure (actual where present)

Intended and largely realized **per feature**:

```text
Presentation (Flutter / Riverpod)
        ↓
Application (use cases, reactors, ports, DTOs)
        ↓
Domain (aggregates, VOs, domain ports)
        ↑
Infrastructure (adapters, in-memory / file / proxy)
```

`lib/core` provides shared kernel (`AggregateRoot`, `Entity`, `ValueObject`, IDs, `Result`) and in-process eventing (`EventBus` → `EventStore` → `EventDispatcher` → reactors).

### 3.3 Runtime topology (actual)

```text
┌─────────────────────────────────────────────────────────────┐
│ Flutter Client (single process)                             │
│  • Domain + Application + Infrastructure for LJ / HS / Disc │
│  • Riverpod composition                                     │
│  • Device recording / local media                           │
│  • In-memory EventBus / EventStore                          │
│  • In-memory LJ + Discovery persistence                     │
│  • File persistence for Hero & Story (native only)          │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP (optional dart-defines)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ services/ai_proxy (Dart Shelf)                              │
│  • Transcription, Story Coach, Understanding, Authoring     │
│  • Holds OpenAI credentials                                 │
│  • Not an EH domain platform                                │
└─────────────────────────────────────────────────────────────┘
```

There is **no** EH application server today. Domain authority lives inside the Flutter process. The AI proxy is a credential/orchestration boundary only.

### 3.4 Technology stack (actual)

| Concern | Current choice |
|---------|----------------|
| Client UI | Flutter + Riverpod |
| Domain language | Dart (same process as UI) |
| Persistence (LJ / Discovery / events) | In-memory Maps |
| Persistence (Hero & Story) | Local JSON files on native; in-memory on web |
| Media | Local filesystem / web object URLs |
| Recording | `record` package + platform adapters |
| AI | Ports in domain/application; OpenAI only via `ai_proxy` |
| Auth / multi-user Identity | Not implemented (local Hero bootstrap) |

---

## 4. Current Bounded Contexts

### Context map (intended + code reality)

```text
Identity          — PLANNED (IDs + local Hero bootstrap only)
    │
    ├──────────────┐
    ▼              ▼
Discovery      Hero & Story
PARTIALLY      IMPLEMENTED (large surface)
IMPLEMENTED
    │              │
    └──────┬───────┘
           ▼
      Life Journey — IMPLEMENTED (H.2 + UI.3 + HS.8 seam)
           │
           ▼
      Contribution — PLANNED (ContributionId only)
```

| Context | Status | Evidence |
|---------|--------|----------|
| **Life Journey** | **IMPLEMENTED** | Aggregates Journey/Quest/Reflection; H.2 reactors; UI.3 experience; Home/Reflect screens; extensive tests |
| **Hero & Story** | **IMPLEMENTED** (beyond HS.1) | Hero/Story/StoryBuilderSession/StoryUnderstanding; ~68 use cases; durable persistence; capture; AI ports; UI catalog/builder |
| **Discovery** | **PARTIALLY IMPLEMENTED** | Domain + in-memory repos + 2 use cases + tests; **not** wired into Riverpod/app shell; Discover tab is unrelated placeholder |
| **Identity** | **PLANNED** | `UserId` etc. exist; `ensureActiveLocalHeroProvider` substitutes until Identity BC (HS-ADR-065) |
| **Contribution** | **PLANNED** | `ContributionId` only |

### Cross-context integration that exists today

| Seam | Mechanism | Status |
|------|-----------|--------|
| LJ → HS story candidates | `DiscoverableStoryCandidatePort` ← `DiscoverStoriesCandidateAdapter` | **IMPLEMENTED** (HS.8) |
| HS → LJ reflection | `StartStoryReflectionUseCase` → `CreateReflectionUseCase` | **IMPLEMENTED** |
| Narrative themes | Shared-kernel `NarrativeThemeId`; Discovery owns `NarrativeTheme` entity | **IMPLEMENTED** as ID references |
| Builder themes → Discovery themes | `StoryBuilderThemeNarrativeThemeBridge` at materialization | **IMPLEMENTED** (post FG.2; older checkpoint “Missing” is stale) |
| Story consume → BehavioralEvidence | Explicitly **does not** create evidence | **IMPLEMENTED** (correct boundary) |

### Naming collision (documentation risk)

“Discovery” appears in three places:

1. **Discovery BC** — `lib/features/discovery` (influences / themes / profile)
2. **Hero & Story discovery** — discover/search published stories & heroes
3. **Life Journey Discover tab** — static UI placeholder

These must not be conflated in planning or APIs.

---

## 5. Current Domain Model

### 5.1 Life Journey

| Concept | Layer | Authoritative? | Notes |
|---------|-------|----------------|-------|
| `Journey` | Domain aggregate | Yes | Owns vision, chapter, quest IDs, **behavior patterns** |
| `Quest` | Domain aggregate | Yes | Owns missions; less UI-wired |
| `Mission` | Domain entity (under Quest) | Yes | |
| `Reflection` | Domain aggregate | Yes | Multi-modal responses; post-submit insights/evidence/themes |
| `ReflectionResponse` hierarchy | Domain entities | Yes | Journal/Prompt/Emoji/Scale/Choice/Voice/Photo |
| `BehavioralEvidence` | Domain VO on Reflection | Yes | Canonical VO in `behavioral_evidence.dart` |
| `BehaviorPattern` | Domain type owned by Journey | Yes | No separate repository |
| `Insight` | Domain VO | Yes | Via `InsightExtractionService` (rule-based stub) |
| `LifeJourney` aggregate | — | **Missing** | Only `LifeJourneyId` in shared kernel; docs still mention root |
| `AdaptiveExperience` | Application model | Yes (app-facing) | Not a domain aggregate |
| GrowthSignal | — | **LEGACY / removed from code** | Docs retain history; no `lib/` usages |

**Persistence:** In-memory Journey/Quest/Reflection repositories only.  
**Events:** JourneyCreated, ChapterAdvanced, BehaviorPatternsDetected, Quest/Mission lifecycle, ReflectionSubmitted, InsightsGenerated, BehavioralEvidenceDetected, NarrativeThemesAdded; orphan `PatternsDetected` unused.  
**Consumers:** Reactors for ReflectionSubmitted and BehavioralEvidenceDetected; UI via use cases.  
**Tests:** `test/features/life_journey/**`, integration pipeline tests, legacy `test/life_journey/**`.

### 5.2 Discovery

| Concept | Layer | Authoritative? | Notes |
|---------|-------|----------------|-------|
| `DiscoveryProfile` | Domain aggregate | Domain-yes; product-no | Not wired to app providers |
| `Influence` | Domain entity | Yes (foundation) | |
| `NarrativeTheme` | Domain entity + catalog | Yes | Ownership correct per AD-002 |
| `UserDiscovery` | Domain entity | Yes (foundation) | |
| `DiscoveryPreference` | Domain VO | Yes (foundation) | |

**Persistence:** In-memory only.  
**Use cases:** `AddInfluenceUseCase`, `ResolveNarrativeThemesUseCase`.  
**Events:** InfluenceAdded/Removed, NarrativeThemesResolved.  
**Consumers:** Tests primarily; production experience path does **not** read DiscoveryProfile.  
**Tests:** `test/features/discovery/**`.

### 5.3 Hero & Story

| Concept | Layer | Authoritative? | Notes |
|---------|-------|----------------|-------|
| `Hero` | Domain aggregate | Yes | Profile, visibility, status |
| `Story` | Domain aggregate | Yes | Canonical narrative; lifecycle ≠ visibility |
| `StoryRepresentation` | Domain entity | Yes | Multi-format / multi-language |
| `StoryUnderstanding` | Domain aggregate | Partial | Dual path; HS.4 path weakly composed; in-memory repo only |
| `StoryBuilderSession` | Domain aggregate | Yes | Guided/freeform interview |
| `StoryProposal` | Persisted VO with identity | Yes (intentional) | Not AggregateRoot; SB.9/12/13 design |
| MediaReference / media storage | VO + port | Yes | Device-local adapters |
| Story Coach | Application port + proxy | Yes (AI assist) | Behind `StoryBuilderCoachPort` |
| Catalog taxonomy | Domain VOs | Yes | Multidimensional classification |
| Content suitability / spirituality | Domain VOs | Yes | Content classification ≠ Hero identity |

**Separation from LJ behavioral model:** Hero & Story domain does **not** own BehavioralEvidence or BehaviorPattern. Experience consume does not invent growth. Reflection after story is an explicit LJ handoff.

**Persistence:** File JSON repos (Hero, Story, BuilderSession, Proposal) + local media on native; in-memory on web / tests. StoryUnderstanding lacks file repo.

**Tests:** Large `test/features/hero_story/**` including architecture boundary tests.

### 5.4 Concept status summary (requested inventory)

| Concept | Status | Where |
|---------|--------|-------|
| Journey | **IMPLEMENTED** | LJ domain aggregate |
| Mission | **IMPLEMENTED** | LJ entity under Quest |
| Quest | **IMPLEMENTED** | LJ domain aggregate |
| Reflection | **IMPLEMENTED** | LJ domain aggregate |
| Behavioral Evidence | **IMPLEMENTED** | LJ VO + analysis pipeline |
| Behavior Pattern | **IMPLEMENTED** | LJ pattern types on Journey |
| Discovery | **PARTIAL** | Domain foundation; not product-wired |
| Discovery Profile | **PARTIAL** | Aggregate exists; unused by experience/UI |
| Experience | **IMPLEMENTED** (application) | AdaptiveExperience + Today’s Experience |
| Hero | **IMPLEMENTED** | HS domain |
| Story | **IMPLEMENTED** | HS domain |
| Story Representation | **IMPLEMENTED** | HS entity |
| Story Builder | **IMPLEMENTED** | Session aggregate + UI |
| Story Coach | **IMPLEMENTED** | Port + ai_proxy + in-memory fallback |

---

## 6. Current Application Architecture

### 6.1 Use-case orchestration pattern

```text
UI / Reactor
  → UseCase.execute(request)
  → load aggregate(s) via repository ports
  → mutate domain
  → repository.save
  → pullDomainEvents → EventBus.publish
```

`UseCase<Request, Response>` returning `Result<T>` is the shared application contract in Life Journey and Hero & Story.

### 6.2 Life Journey application surface (selected)

| Concern | Types |
|---------|-------|
| Journey/Quest/Mission | CreateJourney, CreateQuest, CreateMission, CompleteMission |
| Reflection | Create / AddResponse / Submit / Analyze |
| Patterns | DetectPatternUseCase |
| Experience | GetTodayExperience, BeginExperience |
| Adaptive HS.8 | ResolveAdaptiveDiscoverySignals |
| Reactors | ReflectionSubmittedReactor, BehavioralEvidenceDetectedReactor |
| Selection | DeterministicExperienceSelectionService, AdaptiveExperienceComposer |

### 6.3 Hero & Story application surface

~68 use cases covering create → capture → transcribe → understand → classify → author/propose → approve → materialize → publish → discover → experience → builder session flows, plus owned-story paths.

Composition is concentrated in:

* `lib/app/app_composition_root.dart`
* `lib/features/hero_story/application/providers/**`
* Durable override via `HeroStoryDurablePersistence`

### 6.4 Discovery application surface

Minimal: add influence; resolve narrative themes. **No Riverpod providers** in app composition.

### 6.5 Bootstrap

```text
main → AppCompositionRoot.initialize
     → ApplicationBootstrap.initialize
     → ReactorRegistration.register (2 LJ reactors only)
     → DemoRunner (ensures a Journey exists)
     → EveryonesHeroesApp / AppShell
```

No Hero & Story domain-event reactors are registered.

---

## 7. Current Event Architecture

### 7.1 In-process pipeline (IMPLEMENTED)

```text
Aggregate.raise(...)
  ↓
UseCase.pullDomainEvents()
  ↓
EventBus.publish(...)
  ↓
EventStore.append(EventEnvelope)
  ↓
EventDispatcher.dispatch(...)
  ↓
DomainEventReactor.react(...)
```

Implementations: `InMemoryEventBus`, `InMemoryEventStore`, `InMemoryEventDispatcher`.

### 7.2 Registered reactors (actual)

| Event | Reactor | Effect |
|-------|---------|--------|
| `ReflectionSubmitted` | `ReflectionSubmittedReactor` | `AnalyzeReflectionUseCase` |
| `BehavioralEvidenceDetected` | `BehavioralEvidenceDetectedReactor` | `DetectPatternUseCase` |

### 7.3 Documentation drift (events)

| Claim | Reality |
|-------|---------|
| `event-flow.md`: automatic ReflectionSubmitted → Analyze not wired | **LEGACY** — wired via `ReactorRegistration` |
| H.2 docs name `DetectBehaviorPatternsUseCase` / `BehaviorPatternDetector` | Code: `DetectPatternUseCase` / `PatternDetector` |
| Orphan `PatternsDetected` | Defined; **never raised** |
| HS events largely unused for cross-context reactions | Events exist on aggregates; no HS reactors in bootstrap |

### 7.4 Implications for platform design

Current eventing is **synchronous, in-process, non-durable**. A server platform will need an explicit decision (PF-ADR backlog) on whether domain events become:

* internal modular-monolith in-process events,
* durable outbox / message bus,
* or API-side effects without a distributed bus initially.

---

## 8. Current Flutter Architecture

### 8.1 Shell navigation (actual)

| Tab | Screen | Domain-backed? |
|-----|--------|----------------|
| Home | `home_screen.dart` | **Yes** — Today’s Experience |
| Journey | `journey_screen.dart` | **No** — static prototype |
| Discover | `discover_screen.dart` | **No** — static cards (not Discovery BC) |
| Heroes | `hero_catalog_screen.dart` | **Yes** — Hero & Story |
| Reflect | `reflect_screen.dart` | **Yes** — emoji reflection submit |

Pushed flows: Experience screen, Story detail/consume, Story Builder, Tell Your Story, owned stories, etc.

`UnderstandingScreen` exists as static prototype and is **not** in the shell.

### 8.2 UI.3 adaptive experience (IMPLEMENTED)

```text
HomeScreen
  → todayExperienceProvider
  → GetTodayExperienceUseCase
  → ResolveAdaptiveDiscoverySignalsUseCase (optional path)
  → DiscoverableStoryCandidatePort (HS adapter)
  → AdaptiveExperienceComposer
       ├─ story candidate → story experience
       └─ else DeterministicExperienceSelectionService → reflection
  → ExperienceScreen
       ├─ story → StoryDetailScreen
       └─ reflection → BeginExperienceUseCase → ReflectScreen
  → submit reflection → invalidate todayExperienceProvider
```

This is deterministic foundation personalization, **not** a full personalization engine.

### 8.3 Hexagonal boundary health (UI)

| Check | Assessment |
|-------|------------|
| LJ UI invokes detectors / EventBus / mutates aggregates | Mostly clean |
| Experience selection in UI | **No** — stays in application |
| ReflectScreen constructs domain `EmojiResponse` | **Soft leak** |
| Story Builder controller reads repositories | **Partial violation** (known) |
| Journey / Discover / Understanding screens | Prototype UI; architectural dead weight for product truth |
| FakeNarrativeThemeResolver in production provider | Application composition debt |

### 8.4 UI.2 / UI.3 verdict

| Area | Status |
|------|--------|
| Application-backed Home experience | **IMPLEMENTED** |
| Reflect → H.2 → refreshed experience | **IMPLEMENTED** (integration-tested) |
| Journey / Understanding product screens | **PARTIAL / prototype** |
| Discover tab = Discovery BC | **LEGACY naming / MISSING integration** |
| Strict presentation purity | **PARTIAL** |

---

## 9. Current AI Architecture

### 9.1 Principles already encoded

* Domain does not import OpenAI / HTTP AI SDKs.
* AI sits behind ports (`StoryTranscriptionPort`, `StoryBuilderCoachPort`, `StoryBuilderUnderstandingPort`, `StoryAuthoringPort` / shapers, LJ `InsightExtractionService`, etc.).
* Production secrets must not ship in the Flutter binary (HS-ADR-067/068).
* AI must not invent Hero facts; provenance and approval gates exist for derived content.

### 9.2 AI proxy (`services/ai_proxy`) — IMPLEMENTED (narrow)

| Endpoint | Purpose |
|----------|---------|
| `POST /story-transcriptions` | Speech-to-text |
| `POST /story-builder-questions` | Story Coach next question |
| `POST /story-understanding` | Builder understanding (structured observations) |
| `POST /story-authoring` | Proposal authoring assistance |
| `GET /health` | Liveness |

Flutter selects proxy vs in-memory via dart-defines (`EH_AI_PROXY_URL`, `EH_*_MODE=proxy`).

### 9.3 What still lives in Flutter

| Responsibility | Location | Platform-ready? |
|----------------|----------|-----------------|
| Port interfaces & deterministic fallbacks | Flutter domain/application/infra | Ports migrate; fallbacks may stay client or server |
| Prompt minimization & request DTOs | Proxy + Flutter adapters | Should become platform contracts |
| Reflection insight / evidence analysis | Flutter LJ (rule-based / emoji) | Should become platform domain |
| Pattern detection | Flutter LJ | Should become platform domain |
| Experience selection | Flutter LJ application | Should become platform domain |
| Recording / mic / local files | Flutter | **Remain client** |
| OpenAI credentials | ai_proxy only (when proxy mode) | Remain server |

### 9.4 Reflection AI vs Story AI

Story AI paths are further advanced (proxy + contracts). Reflection analysis is largely **deterministic / stub** (`RuleBasedInsightExtractionService`, `EmojiBehavioralEvidenceAnalyzer`, `FakeNarrativeThemeResolver`). Do not assume production LLM reflection analysis exists.

---

## 10. Current Hero & Story Architecture

### 10.1 Capability map (code-verified)

| Capability | Status |
|------------|--------|
| Hero aggregate & profile | **IMPLEMENTED** |
| Story aggregate, lifecycle, visibility | **IMPLEMENTED** |
| Representations & languages | **IMPLEMENTED** |
| Multidimensional catalog | **IMPLEMENTED** |
| Suitability / spirituality | **IMPLEMENTED** |
| Capture / recording | **IMPLEMENTED** (platform-specific gaps on web) |
| Transcription | **IMPLEMENTED** (proxy or in-memory) |
| Story Builder + Coach | **IMPLEMENTED** |
| Understanding (Builder path) | **IMPLEMENTED** |
| Understanding (HS.4 StoryUnderstanding aggregate) | **PARTIAL** (exists; weaker composition / no file repo) |
| Authoring / proposal / review / materialize | **IMPLEMENTED** (FG integration progressed) |
| Publish / owned discoverability | **IMPLEMENTED** (FG.1 / FG.3) |
| Story / Hero discovery & search | **IMPLEMENTED** (deterministic) |
| Story experience consume | **IMPLEMENTED** (playback completeness partial) |
| Adaptive relevance into Today’s Experience | **PARTIAL / IMPLEMENTED seam** (HS.8) |

### 10.2 Ownership boundaries (actual)

Hero & Story **does own:** Heroes, Stories, representations, media references, capture artifacts, catalog classification, suitability, spirituality-as-content, provenance, builder sessions, proposals.

Hero & Story **does not own:** BehavioralEvidence, BehaviorPatterns, DiscoveryProfile, Life Journey progression, Identity authentication.

Mild coupling watch-items (not hard domain violations):

* Application/UI sometimes returns LJ `Reflection` types across the seam.
* Relevance ranker imports LJ adaptive signal models into HS application.
* Identity absence forces local Hero bootstrap inside HS composition.

### 10.3 Relative maturity

Hero & Story is the **largest and most durable** vertical in the repo. Any “HS.1 greenfield” framing is **LEGACY** relative to code. Prefer gap-closure and platform extraction over restarting foundation.

---

## 11. Architectural Drift and Gaps

### 11.1 Adaptive growth loop classification

Intended loop vs code:

| Stage | Classification | Evidence |
|-------|----------------|----------|
| Discovery (inspirations / profile) | **Partial** | Domain exists; not driving product loop |
| Experience | **Implemented** | Today’s Experience + Story experience |
| Action | **Partial** | Mission complete exists; Home path centers reflect/story begin |
| Reflection | **Implemented** | Multi-modal aggregate + Reflect UI (emoji path primary) |
| Behavioral Evidence | **Implemented** | Analysis orchestrator + emoji analyzer |
| Behavior Patterns | **Implemented** | DetectPatternUseCase + Journey ownership |
| Discovery Profile update from growth | **Missing** | No reactor/use case feeding DiscoveryProfile from LJ |
| Personalization | **Partial** | Deterministic selection + theme overlap; not full engine |
| Adaptive Experience | **Implemented** (foundation) | UI.3 + HS.8 composer |
| Growth (person-level growth profile) | **Planned / Missing** | No GrowthProfile aggregate; Journey holds patterns |

### 11.2 Documentation vs code (selected)

| Artifact | Drift class | Notes |
|----------|-------------|-------|
| `event-flow.md` “reactors not wired” | **LEGACY / DRIFTED** | Reactors registered |
| `use-case-map.md` / `repository-map.md` / `aggregate-map.md` | **DRIFTED** | Omit or understate Hero & Story; stale DetectPatterns status |
| `bounded-contexts.md` Discovery “Planned” | **DRIFTED** | Foundation implemented |
| `codebase-analysis.md` | **LEGACY** | Describes mid-refactor / empty Discovery files / `lib/contexts` |
| H.2 naming (`DetectBehaviorPatternsUseCase`) | **DRIFTED** | Code uses `DetectPatternUseCase` |
| `HS-architecture-checkpoint.md` theme bridge Missing | **PARTIALLY STALE** | Bridge now exists post FG.2 |
| `AGENTS.md` + HS ADRs | **MOST CURRENT** among docs | Still lists hygiene issues accurately |
| `CLAUDE.md` | **MIXED / LEGACY** | Useful philosophy; some M1 framing superseded |

### 11.3 Known hygiene issues (from AGENTS.md §29 — still present)

* DetectPattern naming mismatches vs older H.2 docs
* Orphan `PatternsDetected`
* Duplicate `BasePatternRule` / unused BehavioralEvidence variant
* `DateTime.now()` in aggregates / EventBase
* FakeNarrativeThemeResolver in production provider
* Incomplete RecoveryPatternRule; BehaviorPatternType values without rules
* Legacy duplicate `test/life_journey/` tree
* Stale architecture maps

These are **not** PF.1 cleanup mandates unless they block a future authorized phase.

### 11.4 Structural gaps relevant to platform migration

1. **No multi-user Identity** — single local Hero bootstrap.
2. **Asymmetric persistence** — HS durable locally; LJ/Discovery/events ephemeral.
3. **Domain authority in client** — cannot share growth state across devices/users.
4. **AI proxy ≠ platform** — no EH domain API.
5. **Discovery BC unwired** — personalization uses Reflection themes + Journey patterns, not DiscoveryProfile.
6. **Quest/Mission under-exposed** in UI/providers relative to domain richness.
7. **Event store non-durable** — cannot rebuild projections across restarts.

---

## 12. Target Platform Architecture

### 12.1 Planning-level target

```text
┌──────────────────────────────┐
│ Flutter Client               │
│  presentation, navigation    │
│  local interaction state     │
│  recording / AV / device     │
│  local drafts / cache        │
│  API client                  │
└──────────────┬───────────────┘
               │ versioned API + auth
               ▼
┌──────────────────────────────┐
│ EH Platform (Modular Monolith│
│  recommended initially)      │
│                              │
│  ├── Application use cases   │
│  ├── Domain (bounded ctx)    │
│  ├── Domain events (internal)│
│  ├── Persistence             │
│  ├── AI orchestration        │
│  └── External integrations   │
└──────────────────────────────┘
```

### 12.2 Architectural requirement vs implementation technology

| Concern | Architectural requirement | Implementation technology |
|---------|---------------------------|---------------------------|
| Authoritative domain | Single owner for each capability | Language TBD (PF-ADR-003) |
| Client | Flutter presentation + device | Flutter (current) |
| AI credentials | Never in client binary | Server-side orchestration (ai_proxy evolution or platform module) |
| API | Stable contracts between client & platform | REST/JSON or equivalent (PF-ADR-005) |
| Events | Past-tense facts; cross-module reactions | In-process first; bus later if needed |
| Persistence | Durable, multi-user, authorized | DB TBD (PF-ADR-007) |

**Rust is an evaluation candidate, not a requirement.** See §19.

### 12.3 Why a platform is justified by the current codebase

* Domain logic is already hexagonal and test-rich — extractable conceptually.
* Hero & Story already hit a process boundary for AI (proxy).
* Growth/understanding must become multi-device and multi-user to fulfill product loop.
* Keeping LJ domain only on-device permanently blocks shared Discovery/Personalization.
* Local file persistence for Stories does not scale to catalog/community visibility.

---

## 13. Target Bounded Contexts

Retain the intended map; assign **platform ownership** for authoritative state:

| Context | Target owner | Client residual |
|---------|--------------|-----------------|
| Identity | Platform | Auth session, local profile cache |
| Discovery | Platform | Preference UI, local draft answers |
| Hero & Story | Platform (catalog, lifecycle, understanding, authoring orchestration) | Recording, playback, offline drafts, media upload |
| Life Journey | Platform | Experience presentation, reflection input UI |
| Contribution | Platform (future) | Contribution UX when authorized |

Cross-context rules remain:

* NarrativeTheme ownership in Discovery; others store IDs.
* Story interaction ≠ automatic BehavioralEvidence.
* Catalog ≠ Discovery ≠ Personalization.
* AI assists; human approval owns story truth.

---

## 14. Client / Platform Responsibilities

### 14.1 Flutter Client (keep / strengthen)

* Presentation & navigation
* Local interaction / form state
* Device recording, permissions, audio/video playback
* Offline/local drafts and upload queues
* Media capture buffers before durable platform storage
* API client + auth token handling
* Optimistic UI against server contracts
* Deterministic offline fallbacks **only** where product requires offline and contracts allow

### 14.2 EH Platform (migrate / establish)

* Authoritative aggregates and invariants
* Application use cases
* Behavioral understanding (H.2)
* Journey / Quest / Mission / Reflection authority
* DiscoveryProfile & Influence catalog authority
* Experience selection / personalization policies
* Hero & Story lifecycle, publish, discoverability
* AI orchestration (transcription, coach, understanding, authoring, future reflection analysis)
* Durable persistence & authorization
* Domain events and reactors
* Media object storage references (not necessarily binary hosting initially)

### 14.3 Remain carefully split

| Capability | Split |
|------------|-------|
| Story recording | Client captures → Platform stores metadata + media refs |
| Story Coach | Platform owns prompts/providers; Client displays Q&A |
| Pattern detection | Platform only (no competing client detector long-term) |
| Today’s Experience | Platform decides; Client renders |
| EventBus | Platform internal; Client consumes API/read models / push later |

---

## 15. API and Contract Strategy

### Principles

1. **Contracts over shared implementation** — do not share Dart domain packages with a Rust/other server as the long-term model.
2. **Application-facing DTOs** — APIs expose commands/queries/read models, not raw aggregate internals.
3. **Provenance-preserving AI contracts** — continue EH-owned request/response shapes (as ai_proxy already does).
4. **Version explicitly** — especially events and AI prompt/template versions.
5. **Explainability fields** — “why this experience?” must cite real sources (themes, patterns, preferences, interactions).

### Initial API families (planning)

| Family | Examples |
|--------|----------|
| Identity | register/login, profile |
| Journey | create journey, get journey understanding |
| Reflection | create, add response, submit |
| Experience | get today’s experience, begin experience |
| Discovery | add influence, get discovery profile |
| Hero | CRUD profile, visibility |
| Story | capture complete, classify, publish, get, discover |
| Builder | session lifecycle, coach turn, proposal review |
| Media | upload URL / complete upload |
| AI jobs | transcription status (async) |

Exact style (REST vs RPC) is **PF-ADR-005**.

---

## 16. Event Strategy

### Near-term platform recommendation

Keep **modular-monolith in-process events** matching today’s mental model:

```text
UseCase → Domain Events → Internal Dispatcher → Reactors → UseCases
```

Add durability via:

* aggregate persistence first,
* optional event outbox when cross-process consumers appear.

### Do not require initially

* Microservices event mesh
* Client-published domain events
* Dual EventBuses (client + server) for the same facts

### Migration note

Today’s Flutter EventBus reactions (H.2) must move with Reflection/Journey authority. Client should call `SubmitReflection`; server runs analysis + pattern detection.

---

## 17. Persistence Strategy

### Current → target

| Data | Current | Target |
|------|---------|--------|
| Journey / Reflection / Patterns | In-memory | Platform DB |
| DiscoveryProfile / Influences / Themes | In-memory | Platform DB (+ theme reference data) |
| Hero / Story / Proposal / BuilderSession | Local JSON files (native) | Platform DB |
| StoryUnderstanding | In-memory | Platform DB |
| Media binaries | Local files | Object storage + MediaReference |
| Domain EventStore | In-memory | Optional durable outbox later |
| Client cache | N/A / local files | Explicit cache keyed by user |

### Principles

* One authoritative store per aggregate family.
* Local files may remain as **offline draft / upload staging**, not second source of truth.
* Avoid premature CQRS complexity; start with aggregate repos + read DTOs.

---

## 18. AI Platform Strategy

### Evolve `services/ai_proxy` into platform AI orchestration

Short term, ai_proxy is the correct **credential boundary**. Medium term, AI orchestration should live beside EH domain use cases so that:

* approval/lifecycle gates remain authoritative,
* prompts cannot bypass domain invariants,
* reflection analysis and story AI share policy/telemetry/auth.

### Platform AI responsibilities

* Provider adapters (OpenAI today; replaceable)
* Job execution (transcription, long authoring)
* Prompt/template versioning
* Safety filters / identity-claim rejection (already started in domain VOs)
* Rate limits / entitlements (Identity future)

### Client AI responsibilities

* None for secrets
* Display streaming/status
* Capture media for upload
* Optional on-device features only if explicitly productized later

### Do not

* Embed provider SDKs in Flutter domain
* Let AI silently publish Stories
* Treat StoryUnderstanding as canonical Story narrative

---

## 19. Rust Evaluation

### Question

Should EH Platform be implemented in Rust?

### Assessment (planning only)

| Dimension | Fit | Notes |
|-----------|-----|-------|
| Domain-model translation | Good with discipline | Aggregates/VOs/enums map cleanly; Dart nullability → Rust `Option`/`Result` |
| Type system | Strong | Invariants and ID newtypes fit Rust well |
| Async / events | Good | Tokio + in-process dispatcher; avoid distributed complexity early |
| Repository abstractions | Good | Traits ≈ Dart abstract interfaces |
| API implementation | Good | Multiple mature HTTP frameworks |
| Persistence | Good | SQL/SQLx or equivalent; JSON document also possible |
| AI integration | Good | HTTP clients to providers; keep ports |
| Testing | Good | Unit tests for domain; contract tests for API |
| Maintainability | Conditional | Team fluency matters more than language purity |
| Interop with Flutter | Via API only | No shared domain binary |

### What would **not** translate directly

* Riverpod providers / Flutter widgets
* `dart:io` file repos and path_provider layouts
* In-memory Maps-as-DB demo assumptions
* Sync in-process EventBus semantics without redesigning async boundaries
* Package-internal imports across features (would become modules/crates)
* Soft Dart patterns (`DateTime.now()` defaults) — Rust would force clearer clock injection

### Recommendation

```text
Architectural requirement: authoritative server-side EH Platform
Implementation technology: DECISION REQUIRED (PF-ADR-003)
Rust: viable candidate, not mandatory
```

Also viable: continue Dart on server (expand beyond ai_proxy), or another server language the team can operate. Choosing Rust solely for prestige is a risk (§24).

---

## 20. Modular Monolith vs Microservices

### Recommendation for initial EH Platform

**Modular Monolith.**

### Why (given current maturity)

* Bounded contexts exist conceptually, but several are partial (Identity, Contribution, Discovery wiring).
* Current event reactors are few and in-process.
* Team is still consolidating a single product loop.
* Operational overhead of microservices would dominate value.
* Hexagonal modules inside one deployable unit preserve future extraction options.

### When to reconsider services

* Independent scaling/auth needs for media/AI jobs
* Separate release cadence with clear contracts
* Team ownership boundaries that justify isolation

### Explicit non-goal

Do **not** introduce microservices merely because multiple bounded contexts exist.

---

## 21. Migration Strategy

The phase list in the task brief is a useful starting point but must be adjusted to **code reality**:

* Hero & Story is more mature than Discovery product wiring.
* AI proxy already exists as a thin server foothold.
* H.2 is complete enough to migrate as a vertical after platform foundation.
* Client simplification comes last.

### Adjusted phases

```text
Phase 0  Current Architecture Baseline (this document)          ✅ PF.1
Phase 1  Platform Foundation Architecture decisions (PF-ADRs)
Phase 2  Server Foundation (modular monolith skeleton + Identity lite + persistence)
Phase 3  Migrate Reflection / H.2 (authoritative understanding pipeline)
Phase 4  Journey / Understanding read models + Quest/Mission API
Phase 5  Experience Selection / Personalization (move UI.3/HS.8 decisioning)
Phase 6  Discovery BC product wiring on platform (profile as authority)
Phase 7  Hero & Story authority migration (catalog/lifecycle first; capture remains hybrid)
Phase 8  AI Platform consolidation (absorb/expand ai_proxy)
Phase 9  Client Simplification (remove competing domain implementations)
```

### Rationale for reordering vs the brief

| Brief phase | Adjustment |
|-------------|------------|
| Discovery before Personalization | Keep Discovery **domain** early as reference data, but **product wiring** of DiscoveryProfile can follow experience migration so Today’s Experience does not regress |
| Hero & Story before AI | HS AI already partial via proxy; migrate authoritative Story state before expanding AI surface |
| Migrate H.2 early | Correct — smallest complete adaptive loop vertical with strong tests |

### Phase exit criteria (high level)

Each phase ends when:

* one authoritative owner exists for the migrated capability,
* Flutter consumes contracts rather than owning invariants,
* focused + relevant regression tests pass,
* no permanent dual-write without a removal plan.

---

## 22. Current → Target Mapping

| Current Component | Current Owner | Target Owner | Migration Strategy | Status |
|-------------------|---------------|--------------|--------------------|--------|
| Journey aggregate | Flutter LJ | Platform | Migrate vertical with API | Implemented client-side |
| Quest / Mission | Flutter LJ | Platform | Migrate with Journey | Implemented; UI partial |
| Reflection | Flutter LJ | Platform | Migrate with H.2 | Implemented |
| Behavioral Evidence | Flutter LJ | Platform | Migrate with H.2 | Implemented |
| Behavior Patterns | Flutter LJ (on Journey) | Platform | Migrate with H.2 | Implemented |
| Pattern Detector / rules | Flutter LJ | Platform | Migrate; keep deterministic rules first | Implemented |
| Experience selection | Flutter LJ application | Platform | Migrate after H.2 | Implemented foundation |
| DiscoveryProfile | Flutter Discovery (unwired) | Platform | Implement/wire on platform | Partial |
| Influence / NarrativeTheme | Flutter Discovery | Platform | Migrate reference + profile | Partial |
| Hero | Flutter HS (+ local files) | Platform | Migrate authority; keep UI | Implemented |
| Story | Flutter HS (+ local files) | Platform | Migrate authority | Implemented |
| Story Representation / media refs | Flutter HS | Platform + object storage | Redesign storage boundary | Implemented local |
| Story Recording | Flutter device | Flutter | Keep | Implemented |
| Story Builder session UI | Flutter | Flutter + Platform session API | Hybrid then platform authority | Implemented |
| Story Coach | Flutter adapters + ai_proxy | Platform AI | Migrate/absorb proxy | Implemented |
| Transcription | Flutter adapters + ai_proxy | Platform AI | Migrate/absorb proxy | Implemented |
| Story Understanding / Authoring | Flutter + ai_proxy | Platform | Migrate | Partial / Implemented paths |
| AI Proxy | Separate Dart service | Platform module | Redesign/absorb | Implemented narrow |
| EventBus / reactors | Flutter in-process | Platform internal | Migrate with domain | Implemented |
| Identity / Auth | Missing (local Hero) | Platform | New build | Planned |
| Contribution | Missing | Platform (future) | Defer | Planned |
| Journey/Discover/Understanding prototype UI | Flutter | Flutter rewrite against APIs | Replace placeholders | Prototype |

---

## 23. Architectural Decision Backlog

Decisions required **before** (or at the start of) platform implementation. Only relevant items listed.

| ID | Decision | Why it matters now |
|----|----------|--------------------|
| **PF-ADR-001** | Platform ownership — which capabilities are server-authoritative in v1 | Prevents dual domain forever |
| **PF-ADR-002** | Bounded context module boundaries inside the monolith | Package/crate map; dependency direction |
| **PF-ADR-003** | Server language/runtime (Rust vs Dart vs other) | Tooling, hiring, reuse of ai_proxy |
| **PF-ADR-004** | Modular monolith vs microservices | Ops model; confirmed recommendation: monolith |
| **PF-ADR-005** | API style & versioning (REST/JSON, RPC, error model) | Flutter client contract |
| **PF-ADR-006** | Event architecture (in-process only vs durable outbox) | H.2 reactors on server |
| **PF-ADR-007** | Persistence technology & multi-tenant data model | Replace in-memory/files |
| **PF-ADR-008** | Authentication/authorization & Identity BC minimal slice | Replace local Hero bootstrap |
| **PF-ADR-009** | Media storage (local staging → object storage) | Capture/transcription pipeline |
| **PF-ADR-010** | AI orchestration home (evolve ai_proxy vs platform module) | Secrets, jobs, approvals |
| **PF-ADR-011** | Contract strategy (OpenAPI/JSON Schema; no shared domain code) | Dart↔server interop |
| **PF-ADR-012** | Offline / client caching / draft sync | Especially Story Builder & capture |
| **PF-ADR-013** | Experience decision location & explainability payload | UI.3/HS.8 migration |
| **PF-ADR-014** | DiscoveryProfile vs Reflection themes as personalization inputs | Avoid competing “understanding” sources |
| **PF-ADR-015** | Web vs native parity for durable features | Current intentional web in-memory mode |

---

## 24. Architectural Risks

Ranked by architectural significance (highest first):

1. **Duplicated domain logic (client + server)** — highest long-term risk if migration stalls mid-flight.
2. **Flutter/server divergence** — rules change in one place only; tests disagree.
3. **Identity absence** — blocks true multi-user catalog, authz, and Contribution.
4. **Asymmetric persistence** — users believe Stories are “saved” while Journey understanding resets.
5. **Premature microservices** — operational cost before product loop is platform-stable.
6. **Over-engineering personalization/AI** — before authoritative Discovery + H.2 ownership on server.
7. **API/domain leakage** — exposing aggregates or requiring clients to enforce invariants.
8. **Event-versioning / dual EventBus confusion** — client continuing to emit “domain events.”
9. **Media-storage complexity** — recording, web permissions, transcription jobs, rights/consent.
10. **Privacy / security** — reflections, audio, stories are sensitive; proxy auth is optional today.
11. **Loss of offline capabilities** — if platform migration ignores draft/capture staging.
12. **Insufficient contract tests** — current suite is rich for in-process Dart, thin for HTTP.
13. **Documentation drift continuing** — agents implement against stale maps.
14. **Language rewrite risk (e.g., Rust)** — if chosen without team readiness, slows PF phases.

---

## 25. Migration Principles

### One authoritative owner

A capability must not permanently exist as competing client and server implementations.

### Contracts over shared implementation

Prefer API/event contracts rather than sharing domain implementation code between Dart and Rust (or any server language).

### Vertical migration

Migrate complete capabilities (e.g., SubmitReflection → evidence → patterns) rather than moving random classes.

### Preserve behavior

Existing functionality and tests should continue to work throughout migration. Prefer strangler expansion over big-bang rewrite.

### Domain before optimization

Establish authoritative domain ownership before sophisticated personalization or broad AI expansion.

### Avoid premature distribution

Do not introduce distributed infrastructure solely because bounded contexts exist.

### Evidence before conclusions

Keep BehavioralEvidence distinct from BehaviorPattern distinct from Experience selection.

### AI assists; humans own stories

Preserve approval, provenance, and non-fabrication rules across the platform boundary.

### Documentation honesty

When implementation changes architecture, update ADRs/maps in the same authorized phase — do not let PF planning rot like older inventories.

---

## 26. PF.1 Acceptance Criteria

| Criterion | Met? |
|-----------|------|
| Current architecture inspected against repository | **Yes** |
| Actual implementation mapped (contexts, layers, AI, persistence) | **Yes** |
| Documentation/code discrepancies identified | **Yes** (§11) |
| Current bounded contexts documented | **Yes** (§4) |
| Target platform architecture documented | **Yes** (§12–18) |
| Flutter/server responsibilities documented | **Yes** (§14) |
| Migration strategy documented (adjusted to codebase) | **Yes** (§21–22) |
| Architectural decision backlog exists | **Yes** (§23) |
| Risks documented | **Yes** (§24) |
| Rust evaluated without being mandated | **Yes** (§19) |
| No application implementation changed | **Yes** (planning doc only) |

---

## 27. Open Questions

1. **Server language:** Rust, expanded Dart, or other — what constraint dominates (team, ops, reuse of ai_proxy)?
2. **Identity v1 scope:** Auth only, or profile/preferences/entitlements in first slice?
3. **DiscoveryProfile authority timing:** Wire before or after experience selection migrates?
4. **Offline story capture:** How long may local drafts remain authoritative before sync?
5. **Web durability:** Persist HS on web, or keep web as ephemeral demo until platform exists?
6. **Quest/Mission product surface:** First-class in v1 experience loop, or continue reflection/story-centric path?
7. **Event durability:** Required in Phase 2, or only when a second consumer process appears?
8. **Read-model strategy:** API returns aggregates’ DTOs vs dedicated experience/understanding projections?
9. **Contribution:** Any near-term need, or explicitly freeze until post-platform H.2/HS authority?
10. **Documentation cleanup:** Authorize a docs-only reconciliation pass for stale maps after PF.1 review?

---

## Appendix A — Primary evidence paths

| Concern | Paths |
|---------|-------|
| Composition | `lib/app/app_composition_root.dart`, `lib/bootstrap/*` |
| Eventing | `lib/core/eventing/*` |
| Life Journey domain | `lib/features/life_journey/domain/*` |
| H.2 reactors | `lib/features/life_journey/application/reactors/*` |
| UI.3 / HS.8 experience | `lib/features/life_journey/application/use_cases/get_today_experience_use_case.dart` |
| Discovery | `lib/features/discovery/**` |
| Hero & Story | `lib/features/hero_story/**` |
| AI proxy | `services/ai_proxy/**` |
| Agent contract | `AGENTS.md` |
| Recent HS audit | `docs/analysis/HS-architecture-checkpoint.md` (note FG follow-ups may supersede gaps) |

## Appendix B — Status vocabulary

| Term | Meaning |
|------|---------|
| **IMPLEMENTED** | Exists in code and participates in a real path |
| **PARTIALLY IMPLEMENTED** | Present but incomplete, unwired, or divergent |
| **PLANNED** | Documented intent only |
| **LEGACY / DRIFTED** | Docs or code remnants no longer authoritative |
| **MISSING** | Required for loop; not found |
| **UNKNOWN** | Insufficient evidence (unused in this document where avoidable) |

---

*End of PF.1 Overall Architecture document.*
