# SB.0 — Story Builder Master Plan (Architecture Discovery)

**Status:** INVESTIGATION COMPLETE — NO IMPLEMENTATION  
**Date:** 2026-09-21  
**Inspected branch:** `main` @ `5a0bd47` (`fix(ui): Reflect navigation dead-end and Begin→Reflect latency (#33)`)  
**Report branch:** `cursor/sb0-story-builder-master-plan-1684`  
**Phase authorization context:** HS.1…HS.11 Hero & Story foundations exist; Story Builder is a new capability series (SB.*)

Legend used throughout:

- **FACT** — observed in repository source / tests / ADRs
- **RECOMMENDATION** — architectural proposal for Story Builder
- **FUTURE** — intentionally deferred beyond the cited slice

Classification tags (required for every proposed concept):

| Tag | Meaning |
|-----|---------|
| **EXISTING — REUSE** | Present and usable as-is |
| **EXISTING — EXTEND** | Present but needs additive change |
| **NEW — JUSTIFIED** | Absent; introduction is warranted |
| **NOT CURRENTLY PRESENT** | Absent; may remain deferred or owned elsewhere |

---

## 1. Executive summary

**FACT:** The Hero & Story platform is substantially implemented under `lib/features/hero_story/` through HS.11. Canonical `Story` / `Hero` aggregates, representations, provenance, consent, capture (Tell Your Story recording), Story Understanding (propose → review → apply), Story Authoring (unapproved representations), local file persistence, EventBus publishing, and an EH AI proxy for **transcription only** all exist.

**FACT:** There is **no** Story Builder code, UI, domain type, or test. A repository-wide search for `StoryBuilder` / guided builder / “Build My Story” returns nothing.

**FACT:** AI credits are **NOT CURRENTLY PRESENT** in code. Identity documentation lists “AI Credits” / “Purchased AI Capabilities” as future Identity ownership only (`docs/architecture/bounded-contexts.md`). No check, consume, quota, or accounting types exist in Dart.

**RECOMMENDATION:** Implement Story Builder as a **first-class guided authoring path** that converges on the existing `Story` + `StoryRepresentation` + `StoryUnderstanding` + consent/provenance pipeline. Do **not** create a second story system. Place the deterministic/AI boundary in the **application layer** as a replaceable question strategy port. Treat durable Q&A material as a **NEW — JUSTIFIED** domain aggregate (working name: `StoryBuilderSession`), distinct from ephemeral CaptureSession (explicitly not a domain aggregate per HS-ADR-018/060).

**Prime product rule (unchanged from master plan):** *Everyone gets a complete Story Builder. AI makes the experience more adaptive, not more legitimate.*

**Planning readiness:** Ready for **SB.1 Foundation** after review of this report and the open product decisions in §16.

---

## 2. Repository state inspected

| Item | Value |
|------|-------|
| Working tree at inspection | clean on `main` |
| Commit | `5a0bd47` |
| Package | single Flutter app `everyonesheroes` |
| Feature module | `lib/features/hero_story/` (domain / application / infrastructure / presentation) |
| Shared kernel / eventing | `lib/core/` |
| Docs | `docs/architecture/` (HS.* + ADRs HS-ADR-001…070), `docs/analysis/` (HS.10/HS.11) |
| Persistence | `path_provider` / JSON files — **no** Drift / sqflite / Hive |
| AI proxy | `services/ai_proxy/` — STT only (`POST /story-transcriptions`) |
| Story Builder symbols | **none** |

---

## 3. Architecture map

### 3.1 Current Hero & Story platform (FACT)

```text
Identity (partial / local hero bootstrap HS-ADR-065)
        │
        ▼
┌─────────────────── Hero & Story ───────────────────┐
│  Hero                                                │
│  Story ──┬── StoryRepresentation[]                   │
│          ├── StoryConsent / StoryProvenance          │
│          ├── StoryClassification / Suitability       │
│          └── StoryNarrative (incl. provisional)      │
│  StoryUnderstanding (separate AI proposal aggregate) │
│  Ports: Capture*, Media, Transcription, Understanding│
│         Authoring, Translation, Search               │
└──────────────────┬──────────────────────────────────┘
                   │
        Tell Your Story (HS.9) = RECORD only
                   │
                   ▼
        Draft Story + original audio representation
                   │
                   ▼
        Owner My Stories / Detail / Transcription (HS.10/11)
```

\*Legacy `StoryCapturePort` exists; production path uses `DeviceRecordingPort` + `CompleteStoryCaptureUseCase` (HS-ADR-061).

### 3.2 Proposed Story Builder placement (RECOMMENDATION)

```text
                         Tell Your Story (redesign SB.13)
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
        Build My Story        Write My Story        Tell My Story
              │                     │                     │
     Story Builder (SB.*)     written material      recording (HS.9)
              │                     │                     │
              └─────────────────────┼─────────────────────┘
                                    ▼
                             Story Material
                                    │
                                    ▼
                         Story Understanding
                                    │
                                    ▼
                            Story Structure
                                    │
                                    ▼
                             Hero Approval
                                    │
                                    ▼
                      Story / StoryRepresentation
```

### 3.3 Deterministic vs AI inside Story Builder (RECOMMENDATION)

```text
                         STORY BUILDER
                              │
                ┌─────────────┴─────────────┐
                │                           │
        Deterministic Builder          AI Story Builder
        (StaticQuestionStrategy)     (AIQuestionStrategy)
                │                           │
                └─────────────┬─────────────┘
                              ▼
                    StoryBuilderSession  (domain, AI-agnostic)
                              │
                              ▼
                       Story Material
                              │
                              ▼
              existing Story / Understanding / Authoring pipeline
```

---

## 4. Answers to mandated discovery questions

### Q1. What existing domain objects can Story Builder reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `Story` | `lib/features/hero_story/domain/aggregates/story.dart` | EXISTING — REUSE | Canonical narrative; `create` / `createFromCapture` |
| `StoryId` | `lib/core/ids/story_id.dart` | EXISTING — REUSE | |
| `Hero` / `HeroId` / `HeroProfile` | `…/aggregates/hero.dart`, `lib/core/ids/hero_id.dart` | EXISTING — REUSE | Local hero bootstrap already used by Tell Your Story |
| `StoryLifecycleStatus` | `…/enums/story_lifecycle_status.dart` | EXISTING — REUSE | draft → … → published |
| `StoryVisibility` | `…/enums/story_visibility.dart` | EXISTING — REUSE | |
| `StoryNarrative` (+ `provisional()`) | `…/value_objects/story_narrative.dart` | EXISTING — REUSE | HS-ADR-017; Builder should not silently author narrative |
| `StoryRepresentation` | `…/entities/story_representation.dart` | EXISTING — REUSE / EXTEND | Written source material likely maps to `written` format |
| `StoryRepresentationFormat` | `…/enums/story_representation_format.dart` | EXISTING — REUSE | `written` exists; no builder-specific format today |
| `RepresentationOrigin` | `…/enums/representation_origin.dart` | EXISTING — REUSE | original / translated / derived |
| `StoryClassification` | `…/value_objects/story_classification.dart` | EXISTING — REUSE | Catalog dimensions ≠ Builder purpose/intent |
| `NarrativeThemeId` | Discovery-owned ID | EXISTING — REUSE | Reference only; do not duplicate NarrativeTheme |
| `ContentSuitability` / `SpiritualityClassification` | value objects | EXISTING — REUSE | Catalog/suitability — not Builder Q&A |
| `MediaReference` | `…/value_objects/media_reference.dart` | EXISTING — REUSE | If Builder later attaches media |
| `LanguageCode` | shared kernel | EXISTING — REUSE | Multilingual foundation |

**Analogous (other BC, pattern only):** Life Journey `Reflection` + `ReflectionResponse[]` (`lib/features/life_journey/domain/aggregates/reflection.dart`) demonstrates durable multi-response collection with submit immutability. Useful as a **modeling analogy** for Builder responses — not a type to import into Hero & Story.

### Q2. What existing Story Capture concepts can it reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `CompleteStoryCaptureUseCase` | `…/use_cases/complete_story_capture_use_case.dart` | EXISTING — REUSE | Pattern: Accept → durable Story + original representation |
| `CancelStoryCaptureUseCase` | same folder | EXISTING — REUSE | Pattern for abandon |
| `DeviceRecordingPort` / `RecordingSessionService` | `…/application/recording/` | EXISTING — REUSE | Remains Tell/Record path; not Builder Q&A |
| `StoryMediaStoragePort` | `…/domain/services/story_media_storage_port.dart` | EXISTING — REUSE | Media durability |
| `CaptureCompletionStore` | `…/application/capture/` | EXISTING — REUSE | Idempotency pattern for completion |
| `Story.createFromCapture` | `story.dart` | EXISTING — EXTEND | May need parallel “create from builder” factory or shared draft factory |
| `StoryCapturePort` | `…/domain/services/story_capture_port.dart` | EXISTING — REUSE | Legacy stub; do not expand (HS-ADR-061) |
| Domain `CaptureSession` | — | NOT CURRENTLY PRESENT (by design) | HS-ADR-018/060 forbid domain CaptureSession |

**RECOMMENDATION:** Do not force Story Builder into CaptureSession. Capture = device recording workflow. Builder = durable guided Q&A. Both eventually produce `Story` + representations.

### Q3. What existing Story Understanding concepts can it reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `StoryUnderstanding` | `…/aggregates/story_understanding.dart` | EXISTING — EXTEND | AI proposals; never auto-apply (HS-ADR-022/023) |
| `StoryUnderstandingPort` | `…/domain/services/story_understanding_port.dart` | EXISTING — EXTEND | `analyze(AnalyzeStoryContentRequest)` → draft |
| Candidate classification / suitability / spirituality VOs | `…/value_objects/candidate_*.dart` | EXISTING — REUSE | Catalog proposals |
| `StoryObservation` / `ObservationKind` | `…/story_observation.dart`, `observation_kind.dart` | EXISTING — EXTEND | Kinds today: `languageSignal`, `contentMention`, `uncertainty`, `other` — not turning points/quotes |
| `UnderstandingProvenance` / `UnderstandingReview` | value objects | EXISTING — REUSE | |
| `GenerateStoryUnderstandingUseCase` | application | EXISTING — REUSE | |
| `ReviewStoryUnderstandingUseCase` | application | EXISTING — REUSE | Propose → review pattern for SB.10 |
| `ApplyStoryUnderstandingUseCase` | application | EXISTING — REUSE | Explicit apply to Story catalog |
| Narrative moments / candidate quotes / structure proposals | — | NOT CURRENTLY PRESENT | SB.8/SB.9 need extension or sibling proposal types |
| File-backed `StoryUnderstandingRepository` | — | NOT CURRENTLY PRESENT | In-memory only today; SB persistence may need File* later |

**RECOMMENDATION:** Reuse the propose/review/apply lifecycle. Extend observations/candidates for themes, narrative moments, and quotes rather than inventing a parallel “understanding” aggregate.

### Q4. What existing Story Authoring concepts can it reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `StoryAuthoringPort` | `…/domain/services/story_authoring_port.dart` | EXISTING — REUSE | Generates unapproved authored drafts |
| `GenerateStoryScriptUseCase` | application | EXISTING — REUSE | Creates AI `StoryRepresentation`; non-authoritative |
| `UpdateStoryNarrativeUseCase` | application | EXISTING — REUSE | Explicit Hero authorship of canonical narrative |
| `EditUnapprovedStoryRepresentationUseCase` | application | EXISTING — REUSE | Human edit before approve |
| `ApproveStoryRepresentationUseCase` | application | EXISTING — REUSE | SB.10/SB.11 approval boundary |
| `TranslateStoryRepresentationUseCase` + `StoryTranslationPort` | application + domain | EXISTING — REUSE | Derived representations |
| `AuthoringProposal` aggregate | — | NOT CURRENTLY PRESENT (by design) | HS-ADR-032 forbids it |

**RECOMMENDATION:** SB.9 shaping and SB.11 representations must attach as unapproved `StoryRepresentation`s (or Understanding proposals), never silent narrative rewrite.

### Q5. What existing consent/provenance concepts can it reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `StoryConsent` | `…/value_objects/story_consent.dart` | EXISTING — REUSE | Independent gates: recorded / processing / publication / AI |
| `UpdateStoryConsentUseCase` | application | EXISTING — REUSE | |
| HS-ADR-021 / HS-ADR-030 / HS-ADR-038 | `architecture-decisions.md` | EXISTING — REUSE | AI ports require processing + AI consent |
| `StoryProvenance` / `ProvenanceStep` | value objects | EXISTING — REUSE | Appended on `Story.addRepresentation` |
| `StoryTransformationType` | enum | EXISTING — EXTEND | May need builder/source-material transformation type |
| Compilation-specific permission matrix (Moments / Discover / etc.) | — | NOT CURRENTLY PRESENT | SB.12; extend consent or add reuse grants later |

**RECOMMENDATION:** Do not invent a second consent model for Builder. Deterministic Builder needs no AI consent. AI Coach / Understanding / Authoring must continue through existing AI + processing gates when touching Story AI ports.

### Q6. What existing persistence/repository mechanisms can it reuse?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `StoryRepository` | `…/domain/repositories/story_repository.dart` | EXISTING — REUSE | save / findById / findByHeroId / … |
| `FileStoryRepository` + `StorySnapshotMapper` | infrastructure | EXISTING — EXTEND | Native durable Story JSON |
| `InMemoryStoryRepository` | infrastructure | EXISTING — REUSE | Tests / web process lifetime |
| `HeroRepository` / `FileHeroRepository` | domain + infrastructure | EXISTING — REUSE | |
| `StoryUnderstandingRepository` | domain | EXISTING — EXTEND | In-memory only; File adapter missing |
| `HeroStoryDurablePersistence` / `AppCompositionRoot` | app composition | EXISTING — EXTEND | Wire new File* adapters when SB.5 lands |
| `StoryBuilderSessionRepository` | — | NEW — JUSTIFIED | If session is its own aggregate |
| Hive / SQLite / cloud sync | — | NOT CURRENTLY PRESENT | Defer; stay local-first JSON |

**RECOMMENDATION:** SB.5 should follow FileStoryRepository conventions (`{docs}/hero_story/…` JSON), not introduce a new database.

### Q7. What existing navigation/state-management patterns should it use?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| App shell `IndexedStack` + Heroes tab | `lib/app/presentation/app_shell.dart` | EXISTING — REUSE | No go_router |
| Imperative `Navigator.push` / `MaterialPageRoute` | presentation screens | EXISTING — REUSE | |
| `TellYourStoryScreen` + step enum | `…/tell_your_story_screen.dart` | EXISTING — EXTEND | Closest multi-step UX pattern |
| `TellYourStoryController` (Riverpod Notifier) | `…/tell_your_story_controller.dart` | EXISTING — EXTEND | Step machine + keepAlive; analog for Builder UI |
| `HeroCatalogScreen` “Tell Your Story” CTA | `…/hero_catalog_screen.dart` | EXISTING — EXTEND | SB.13 hub entry |
| `MyStoriesScreen` / `OwnedStoryDetailScreen` | presentation | EXISTING — EXTEND | Resume / completed Builder stories surface |
| ReflectScreen multi-step wizard | — | NOT CURRENTLY PRESENT | Reflect is single-screen; **not** the primary UX analog |
| Build / Write / Tell hub UI | — | NOT CURRENTLY PRESENT | SB.13 |

**Performance note (RECOMMENDATION):** Avoid Reflect-style navigation latency. Prefer immediate navigation → render → async init (master plan §21). Deterministic path must not await AI proxy/providers.

### Q8. What existing EventBus patterns apply?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| `EventBus` / `InMemoryEventBus` | `lib/core/eventing/` | EXISTING — REUSE | |
| `EventStore` / `EventDispatcher` / `DomainEventReactor` | same | EXISTING — REUSE | |
| Use-case publish pattern | all HS use cases | EXISTING — REUSE | raise → save → `pullDomainEvents()` → `eventBus.publish` |
| Existing Story/Hero events | `…/domain/events/` | EXISTING — REUSE | `StoryCreated`, `StoryRepresentationAdded`, Understanding events, … |
| Hero & Story reactors | — | NOT CURRENTLY PRESENT | Only Life Journey reactors registered today |
| Builder-specific events | — | NEW — JUSTIFIED (when needed) | e.g. session started/completed — create only if another component reacts |

**RECOMMENDATION:** Follow existing publish-after-save. Do not have UI construct or publish domain events. Add reactors only when cross-aggregate orchestration is required.

### Q9. What existing AI proxy infrastructure applies?

| Concept | Path | Classification | Notes |
|---------|------|----------------|-------|
| EH AI Proxy server | `services/ai_proxy/` | EXISTING — REUSE (pattern) | Shelf server; OpenAI key server-side |
| `POST /story-transcriptions` | `story_transcription_handler.dart` | EXISTING — REUSE | STT only today |
| `ProxyStoryTranscriptionAdapter` | `…/infrastructure/ai/` | EXISTING — REUSE | Flutter HTTP client; no OpenAI SDK in app |
| `StoryTranscriptionConfig` (`EH_AI_PROXY_URL`, …) | infrastructure | EXISTING — REUSE | dart-define wiring |
| Development fallback | `InMemoryStoryTranscriptionAdapter` | EXISTING — REUSE | Default without proxy URL |
| Proxy endpoints for coaching / understanding / authoring | — | NOT CURRENTLY PRESENT | Understanding/Authoring/Translation are in-memory adapters |
| Life Journey AI LLM adapters | — | NOT CURRENTLY PRESENT | Rule/fake services only |

**RECOMMENDATION:** SB.7+ AI Coach should introduce a **new port** (question strategy / coaching) with in-memory + future proxy adapters, mirroring transcription. Do not call OpenAI from domain/application. Extend proxy only when production LLM coaching is authorized.

### Q10. Is there already an AI-credit mechanism?

| Finding | Classification |
|---------|----------------|
| Dart credit / quota / billing / consume APIs | **NOT CURRENTLY PRESENT** |
| Identity BC ownership listed in docs | EXISTING documentation aspiration only (`bounded-contexts.md`) |
| Transcription / Understanding / Authoring debit credits | **NOT CURRENTLY PRESENT** |

**RECOMMENDATION:** Do **not** invent a Story-Builder-local credit system. Deterministic Builder must work with zero AI dependency forever. For AI mode until Identity credits exist: keep adapters development/in-memory or proxy-based without billing; product-gate AI mode explicitly; when Identity credits land, consume through that port only.

### Q11. Where should the deterministic/AI boundary live?

**RECOMMENDATION:** Application-layer replaceable **question strategy port** (name TBD to match project conventions; conceptual `StoryBuilderQuestionStrategy`).

```text
Domain StoryBuilderSession  ── AI-agnostic responses / progress / intent
Application use cases       ── orchestrate session + strategy
Question strategy port      ── Deterministic | AI implementations
Infrastructure adapters     ── static catalog | AI proxy / in-memory
```

Domain must not import Flutter, Riverpod, HTTP, or AI SDKs. Session validity must not depend on which strategy produced a prompt.

This mirrors EXISTING ports: `StoryUnderstandingPort`, `StoryAuthoringPort`, `StoryTranscriptionPort`.

**Classification:** Boundary pattern = EXISTING — REUSE; concrete Builder strategy port = NEW — JUSTIFIED.

### Q12. What new concepts are genuinely required?

| Concept (working name) | Classification | Why justified |
|------------------------|----------------|---------------|
| `StoryBuilderSession` (aggregate) | NEW — JUSTIFIED | Durable Q&A, progress, pause/resume, mode metadata; not ephemeral CaptureSession |
| Session / response / prompt / section / progress / mode VOs | NEW — JUSTIFIED | No existing types model guided multi-prompt story drafting |
| Story purpose / intent | NEW — JUSTIFIED | Distinct from authoritative `StoryClassification` catalog |
| Builder theme selections (intent-time, editable) | NEW — JUSTIFIED | May later map to `NarrativeThemeId[]` but selection UX ≠ catalog apply |
| `StoryBuilderSessionRepository` (+ File adapter in SB.5) | NEW — JUSTIFIED | Persistence boundary for session aggregate |
| Question strategy port + deterministic implementation | NEW — JUSTIFIED | Shared session, different question sources |
| AI question strategy adapter | NEW — JUSTIFIED (SB.7) | Optional adaptive coach |
| Deterministic section mapping (response ID → structure) | NEW — JUSTIFIED (SB.4) | No rewrite of Hero text |
| Builder use cases (start/answer/skip/back/resume/complete) | NEW — JUSTIFIED | Follow existing `UseCase<Req,Res>` + `Result` conventions |
| Mode selection + Tell Your Story hub UI | NEW — JUSTIFIED (SB.6/SB.13) | Product surfaces absent today |
| Extended Understanding candidates (moments/quotes/structure) | NEW — JUSTIFIED / EXISTING — EXTEND (SB.8–9) | Prefer extend Understanding over new aggregate |
| Compilation / Hero Moment permissions | NEW — JUSTIFIED (SB.12) | Beyond current consent gates |

### Q13. What concepts should NOT be introduced?

| Anti-concept | Why |
|--------------|-----|
| Second `Story` system / parallel narrative aggregate | Contradicts HS canonical Story model |
| Domain `CaptureSession` | HS-ADR-018/060 |
| `AuthoringProposal` aggregate | HS-ADR-032 |
| Second AI-credit ledger inside Hero & Story | Identity owns credits (when built) |
| Duplicate `NarrativeTheme` entity in Hero & Story | AD-002 / Discovery ownership |
| Auto-apply AI structure to canonical narrative | HS-ADR-023; AI is coach not ghostwriter |
| BehavioralEvidence from Builder answers alone | Evidence requires meaningful reflection/action bridge (HS-ADR-051/066 spirit) |
| XP / scores / gamified Builder progress as product core | Architecture heuristics: prefer patterns over scores |
| Coupling domain session to OpenAI / proxy types | AD-009 / HS AI ports |

### Q14. What are the dependencies between SB.1–SB.13?

```text
SB.0 Master Plan (this document)
       │
       ▼
SB.1 Foundation          ← domain session + use-case skeleton + tests
       │
       ▼
SB.2 Intent / Type       ← purpose + themes on session
       │
       ▼
SB.3 Deterministic Builder ← static sequence; AI credits = 0; first E2E
       │
       ▼
SB.4 Deterministic Structure ← section map by response IDs
       │
       ▼
SB.5 Persistence         ← File repository + resume
       │
       ▼
SB.6 Mode Selection      ← explicit Guided vs AI product choice
       │
       ├─────────────────┐
       ▼                 ▼
SB.7 AI Coach       SB.8 AI Understanding
       │                 │
       └────────┬────────┘
                ▼
             SB.9 AI Story Shaping
                │
                ▼
             SB.10 Hero Approval
                │
                ▼
             SB.11 Story Representations / Authoring glue
                │
                ▼
             SB.12 Moments / Compilations
                │
                ▼
             SB.13 Tell Your Story Integration
```

**Milestone mapping (RECOMMENDATION):**

| Milestone | Slices | Outcome |
|-----------|--------|---------|
| M1 Complete story without AI | SB.1–SB.4 | Guided Builder produces Hero-authored material + structure |
| M2 Leave and resume | SB.5 | Durable session |
| M3 Optional adaptive AI | SB.6–SB.7 | Mode choice + AI coach on same session |
| M4 Understand & organize | SB.8–SB.9 | Proposed themes/moments/structure |
| M5 Hero approval | SB.10 | Accept/modify/reject |
| M6 Reusable representations | SB.11 | Approved derived representations |
| M7 Compilation ecosystem | SB.12–SB.13 | Moments + Tell Your Story hub |

### Q15. What existing functionality could be affected?

| Area | Risk | Mitigation |
|------|------|------------|
| `TellYourStoryScreen` entry / CTA copy | SB.13 redesign | Additive hub; keep record path working |
| `CompleteStoryCaptureUseCase` / recording | Low if Builder is separate until completion glue | Do not regress HS.9 tests |
| `Story.createFromCapture` / provisional narrative | Builder may need similar draft creation | Shared draft rules; do not break capture factory |
| Owned Stories list/detail | Resume incomplete Builder sessions | Clear draft vs completed semantics |
| `StoryUnderstanding` / authoring ports | SB.8–11 extensions | Keep propose/review/apply; non-authoritative AI |
| Consent UX | AI Builder must surface AI gate | Reuse existing consent screens/patterns |
| App composition / providers | New ports/repos | Follow `HeroStoryDurablePersistence` patterns |
| EventBus reactor registration | New events/reactors | Register deliberately; avoid UI side effects |
| Performance of Heroes tab navigation | Extra providers | Immediate nav; lazy AI init (especially after Reflect latency fix) |
| Full test suite size | New domain tests | Prefer focused + regression; never AI-live in CI |

### Q16. What product decisions remain unresolved?

See §16 Open product decisions.

---

## 5. Existing Story lifecycle (FACT)

```text
draft → processing → review → approved → published
         (+ archived | rejected | suspended | removed)
```

Visibility is independent: `private` | `draft` | `unlisted` | `community` | `public`.

Capture path: `Story.createFromCapture` → private draft + provisional narrative + original audio representation → optional consent → owner transcription (HS.11) → narrative authorship required before approve/publish.

**RECOMMENDATION:** Builder-created Stories should enter the same lifecycle. Prefer private draft until Hero completes Builder and optionally authors/approves representations.

---

## 6. Existing integrations summary

### 6.1 Story Capture integration (FACT)

```text
HeroCatalogScreen / MyStories empty CTA
  → TellYourStoryScreen (prepare → record → review → consent → completed)
  → TellYourStoryController
  → RecordingSessionService + DeviceRecordingPort
  → CompleteStoryCaptureUseCase
  → StoryMediaStoragePort + StoryRepository.save
  → EventBus (StoryCreated, StoryRepresentationAdded)
```

Builder should **converge** at Story persistence, not replace mic capture.

### 6.2 Story Understanding integration (FACT)

```text
Source representation text
  → StoryUnderstandingPort.analyze
  → StoryUnderstanding.createProposed
  → ReviewStoryUnderstandingUseCase
  → ApplyStoryUnderstandingUseCase (authoritative catalog fields only when applied)
```

Production UI for full Understanding review/apply remains limited; transcription owner UI is the HS.11 focus.

### 6.3 Story Authoring integration (FACT)

```text
StoryAuthoringPort → GenerateStoryScriptUseCase
  → unapproved StoryRepresentation (script/shortForm/…)
  → EditUnapproved… / ApproveStoryRepresentationUseCase
```

AI scripts do not mutate `StoryNarrative` (explicit `UpdateStoryNarrativeUseCase` for Hero authorship).

---

## 7. Proposed Story Builder model (RECOMMENDATION)

Conceptual objects (names TBD to match conventions during SB.1):

```text
StoryBuilderSession          NEW — JUSTIFIED  (aggregate root)
├── StoryBuilderSessionId
├── HeroId
├── optional StoryId         (link timing = open decision)
├── StoryBuilderMode         guided | ai | (future hybrid)
├── StoryBuilderIntent       purpose + themes + "not sure"
├── StoryBuilderPrompt[]     questions posed (static or AI-sourced)
├── StoryBuilderResponse[]   Hero-authored answers (editable until rules say otherwise)
├── StoryBuilderProgress     position / completion / skips
├── StoryBuilderSectionMap   section → response ID references (SB.4)
├── status                   inProgress | paused | completed | abandoned
└── timestamps / provenance hints
```

**Critical invariants (RECOMMENDATION):**

1. Domain session does not depend on AI types or credits.
2. Responses remain Hero-authored source material; AI may propose structure but not silently rewrite text.
3. Deterministic and AI prompts produce the same response type so mode switching remains possible later.
4. Completion produces Story Material that can feed Understanding / Authoring without requiring AI.

### 7.1 Application boundary (RECOMMENDATION)

Follow existing `UseCase<Request, Result>` style. Conceptual operations (exact names TBD in SB.1):

| Operation | Responsibility |
|-----------|----------------|
| Start | Create session (+ optional draft Story) |
| SetIntent | Purpose/themes (SB.2) |
| Answer / Edit | Upsert response |
| Skip | Mark prompt skipped without forcing content |
| Advance / GoBack | Navigation within session |
| Resume | Load persisted session |
| Complete | Finalize material; link/create Story representations |
| Abandon | Explicit abandon semantics |

Question strategy invoked by application when next prompt is needed — not by the aggregate inventing AI calls.

### 7.2 Deterministic/AI boundary (RECOMMENDATION)

| Mode | Credits | Dependencies | Strategy |
|------|---------|--------------|----------|
| Guided (deterministic) | 0 | none (no proxy, no network, no API key) | Static ordered prompts + section map |
| AI Story Builder | per future Identity policy | AI port + consent + (future) credits | Adaptive follow-ups on same session |

If AI credits exhaust mid-session: preserve work; offer continue with Guided strategy (RECOMMENDATION). Exact UX in SB.6/SB.7.

---

## 8. Slice dependency graph and deliverables

| Slice | Goal | Deliverable doc |
|-------|------|-----------------|
| SB.0 | Architecture discovery | `docs/analysis/SB-0-story-builder-master-plan.md` (this file) |
| SB.1 | Foundation | `docs/analysis/SB-1-story-builder-foundation.md` |
| SB.2 | Purpose / type | `docs/analysis/SB-2-story-intent.md` |
| SB.3 | Deterministic Builder | `docs/analysis/SB-3-deterministic-story-builder.md` |
| SB.4 | Deterministic structure | `docs/analysis/SB-4-deterministic-story-structure.md` |
| SB.5 | Persistence / resume | `docs/analysis/SB-5-story-builder-persistence.md` |
| SB.6 | Mode selection | `docs/analysis/SB-6-story-builder-mode-selection.md` |
| SB.7 | AI Story Coach | `docs/analysis/SB-7-ai-story-coach.md` |
| SB.8 | AI Understanding | `docs/analysis/SB-8-story-understanding.md` |
| SB.9 | AI shaping | `docs/analysis/SB-9-story-shaping.md` |
| SB.10 | Hero approval | `docs/analysis/SB-10-hero-approval.md` |
| SB.11 | Representations / authoring | `docs/analysis/SB-11-story-representations.md` |
| SB.12 | Moments / compilations | `docs/analysis/SB-12-compilation-moments.md` |
| SB.13 | Tell Your Story integration | `docs/analysis/SB-13-tell-your-story-integration.md` |

---

## 9. Testing strategy (RECOMMENDATION)

| Path | Requirements |
|------|--------------|
| Deterministic | Strong unit/domain tests: order, skip, back, edit, progress, completion, structure mapping — **never** require AI |
| AI | Fixtures/mocks for success, malformed, timeout, unavailable, insufficient credits (when credits exist), AI disabled, provenance preservation |
| Regression | Each slice preserves existing hero_story + full suite health |
| Architecture | Extend `test/features/hero_story/architecture/ai_boundary_test.dart` style checks so domain stays AI-free |

---

## 10. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Inventing parallel story pipeline | High | Converge on `Story` + representations |
| Treating CaptureSession as Builder session | High | New durable aggregate; keep Capture ephemeral |
| Building AI Coach before deterministic E2E | High | Enforce SB.1–SB.5 before SB.7 |
| Inventing AI credits in Hero & Story | Medium | Document gap; wait for Identity port |
| Silent AI rewrite of Hero voice | High | Non-authoritative proposals + approval (existing ADRs) |
| Navigation/provider latency regressing Heroes UX | Medium | Immediate nav; lazy AI; measure on device |
| Scope sprawl into Moments/compilations early | Medium | Defer SB.12 until approval + representations exist |
| Understanding File persistence gap | Medium | Address when SB.5/SB.8 need durable proposals |
| Purpose/theme vocabulary colliding with catalog enums | Medium | Keep intent on session until explicit apply |
| Mid-session mode switch complexity in v1 UX | Low | Support in model; may hide in first UI (open decision) |

---

## 11. Documentation drift notes (report only)

| Artifact | Observation | Classification |
|----------|-------------|----------------|
| `AGENTS.md` says HS.1 is “next” | Implementation progressed through HS.11 | Documentation drift — out of SB.0 scope to rewrite |
| Legacy `CLAUDE.md` GrowthSignal language | Superseded by BehavioralEvidence | Documentation drift |
| `bounded-contexts.md` AI Credits under Identity | No implementation | Aspiration vs code — FACT for credits answer |
| Architecture maps may omit Story Builder | Expected; SB series will add when authorized | FUTURE |

No unrelated architecture docs were modified in SB.0.

---

## 12. Affected ADRs (cite, do not rewrite in SB.0)

| ADR | Relevance |
|-----|-----------|
| HS-ADR-017 | Provisional narrative for drafts |
| HS-ADR-018 / 060 | CaptureSession not a domain aggregate |
| HS-ADR-021 / 030 / 038 | Consent gates for AI |
| HS-ADR-022 / 023 / 024 | StoryUnderstanding + ports; no auto-apply |
| HS-ADR-032 | No AuthoringProposal aggregate |
| HS-ADR-061 | Do not expand legacy StoryCapturePort |
| HS-ADR-064 | Transcription/AI non-blocking post-capture |
| HS-ADR-065 | Local hero bootstrap until Identity |
| HS-ADR-067 / 068 | AI proxy + OpenAI behind neutral port |
| HS-ADR-069 / 070 | Explicit transcription initiation; job ≠ lifecycle |

**FUTURE:** SB.1+ may propose new SB-ADR-* entries for StoryBuilderSession ownership and question-strategy boundary after implementation validation.

---

## 13. Recommended implementation sequence

1. **Review this SB.0 report** — resolve or explicitly defer §16 decisions that block SB.1.
2. **SB.1 Foundation** — domain session + response model + use cases + tests; zero UI requirement optional thin harness.
3. **SB.2 Intent** — purpose/themes on session.
4. **SB.3 Deterministic Builder** — static prompts; prove complete path with AI credits = 0.
5. **SB.4 Structure** — section references by response ID.
6. **SB.5 Persistence** — File repository + resume UX hooks.
7. **SB.6 Mode selection** — product framing (Guided as core, AI as enhancement).
8. **SB.7–SB.10** — AI coach, understanding extensions, shaping, approval.
9. **SB.11–SB.13** — representations, moments prep, Tell Your Story hub.

**Recommended next slice:** **SB.1 — Story Builder Foundation**.

---

## 14. Baseline checks performed

| Check | Result |
|-------|--------|
| Repository inspection | Completed (domain, application, infrastructure, presentation, docs, ADRs, AI proxy, analysis docs) |
| Symbol search `StoryBuilder` / guided builder | No matches |
| `dart analyze` / `flutter test` | **Not run** — `dart` / `flutter` binaries are not available on PATH in this cloud agent environment at report time |
| Production code changes | **None** (documentation only) |

---

## 15. Classification index (quick reference)

### EXISTING — REUSE

`Story`, `Hero`, lifecycle/visibility, `StoryNarrative`/`provisional`, `StoryRepresentation` (+ approval), provenance, `StoryConsent`, catalog VOs, `NarrativeThemeId`, media storage, EventBus publish pattern, HS use-case style, Tell Your Story controller pattern (UX analog), transcription proxy pattern, authoring/understanding ports (as-is for current proposal shapes), FileStoryRepository pattern.

### EXISTING — EXTEND

`StoryUnderstanding` / observations for moments/quotes/structure; `Story.createFromCapture` or shared draft factory for Builder; File persistence composition for new session repo; Tell Your Story / Heroes CTA into hub; optional `StoryTransformationType`; Understanding File repository when durability required.

### NEW — JUSTIFIED

`StoryBuilderSession` and related VOs; intent/purpose; question strategy port; Builder use cases; session repository; deterministic prompt catalog; section map; mode selection UI; AI coach adapter (later); extended approval UX for Builder proposals; Moments permission model (later).

### NOT CURRENTLY PRESENT

Story Builder UI/domain; AI credit accounting; Build/Write/Tell hub; Hero Moments/compilations; production LLM adapters for understanding/authoring/coaching; FileStoryUnderstandingRepository; domain CaptureSession (intentionally); AuthoringProposal aggregate (intentionally).

---

## 16. Open product decisions

These do not block writing SB.0, but **should be decided before or during early SB.1/SB.5/SB.6**:

1. **When is `Story` created?** At Builder start (like capture-on-accept timing variant) vs only on Builder completion?
2. **Do Builder responses become `StoryRepresentation(s)` immediately**, or only after Complete?
3. **Is mid-session Guided↔AI switching** exposed in v1 UX, or model-only for later?
4. **Purpose / theme vocabulary ownership** — session-local enums vs mapping to Discovery `NarrativeThemeId` / `StoryChallenge` immediately?
5. **AI mode before Identity credits exist** — hide AI mode, allow unpaid proxy/dev AI, or soft-gate with “AI unavailable” copy?
6. **Multiple concurrent Builder sessions per Hero** — allowed or single in-progress session?
7. **Abandoned vs paused** — auto-abandon policy / retention?
8. **SB.13 hub IA** — replace Tell Your Story button with hub vs nested entry under current CTA?

**SB.0 default recommendations (non-binding until product confirms):**

1. Create private draft `Story` at **Complete** (or explicit “Save story”) for M1 simplicity; allow earlier link in SB.5 if resume-of-owned-draft UX needs it.
2. Keep responses on the session until Complete; then write a `written` original representation referencing/containing Hero text without rewriting voice.
3. Support hybrid in the **model**; ship Guided-only UX until SB.6.
4. Keep purpose/themes on session in SB.2; map to catalog only via Understanding/apply later.
5. Do not invent credits; ship Guided fully; AI mode waits for port + consent (+ credits when Identity ready).
6. Allow multiple sessions unless UX complexity forces single active session later.
7. Explicit abandon + resume in-progress; no aggressive auto-delete in M1.
8. Additive hub under Heroes / Tell Your Story in SB.13 without removing record path.

---

## 17. Concerns / blockers

| Item | Status |
|------|--------|
| Missing Flutter/Dart toolchain in this agent environment | Non-blocking for SB.0 docs; blockers for SB.1 test execution until environment provides SDK |
| AI credits absent | Non-blocking for SB.1–SB.5; blocks production AI credit enforcement until Identity implements |
| No Story Builder ADR yet | Non-blocking; propose after SB.1 validates session aggregate choice |
| Product decisions §16 | Soft blockers for SB.5/SB.6 timing details; SB.1 can proceed with defaults above |

**No hard architecture conflict** blocks SB.1 if the session aggregate recommendation is accepted and CaptureSession is not reintroduced as a domain type.

---

## 18. Final Cursor response checklist

| Item | Value |
|------|-------|
| Summary of findings | HS.1–HS.11 provide Story/Hero/capture/understanding/authoring/consent/provenance/persistence/EventBus/AI-proxy(STT); Story Builder absent; AI credits absent |
| Key architectural decisions (recommended) | Shared AI-agnostic session aggregate; application question strategy boundary; converge on existing Story pipeline; no second credit system; Guided first |
| Unresolved questions | §16 |
| Recommended next slice | **SB.1 Foundation** |
| Exact report path | `docs/analysis/SB-0-story-builder-master-plan.md` |
| Tests/checks performed | Inspection + symbol search; analyzer/tests unavailable in environment |
| Concerns | Toolchain gap for later slices; credits gap for AI mode enforcement |

---

*End of SB.0 architecture discovery report. Do not proceed to SB.1 implementation until this report has been reviewed.*
