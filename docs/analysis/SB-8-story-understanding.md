# SB.8 — Story Understanding

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-8-story-understanding-6d57`  
**Baseline:** SB.1–SB.7 on `main` @ `1ed389a` (926/926 Flutter tests; analyzer clean with 1 pre-existing unrelated warning)  
**Report path:** `docs/analysis/SB-8-story-understanding.md`

---

## 1. Existing HS.4 design discovered

HS.4 / HS.11 already implement a **Story-scoped** understanding pipeline:

| Artifact | Role |
|----------|------|
| `StoryUnderstanding` aggregate | Non-canonical AI proposals for an existing `Story` |
| `StoryUnderstandingPort` | Analyzes **Story representation text** (`storyId` + `sourceRepresentationIds` + `sourceText`) |
| Candidates | Catalog classification / suitability / spirituality |
| Lifecycle | Propose → review → apply to Story catalog |
| Adapter | `InMemoryStoryUnderstandingAdapter` (no production LLM) |
| Persistence | In-memory repository only |

HS.4 answers catalog questions about an **existing Story's representations**. It requires a `Story` and does not consume `StoryBuilderSession`.

---

## 2. Differences: HS.4 planning vs SB.1–SB.7 reality

| Topic | Older HS.4 / SB.0 plan | SB.1–SB.7 + SB.8 reality |
|-------|------------------------|-------------------------|
| Source material | Story representation text | Builder responses on `StoryBuilderSession` |
| Story existence | Understanding assumes Story exists | SB.8 **must not** create Story |
| Coach | Planned separately | SB.7 `StoryBuilderCoachPort` + `POST /story-builder-questions` |
| Structure | Not in HS.4 | SB.4 `DeterministicStoryStructure` (role → response IDs) |
| Theme vocabulary | Catalog / `NarrativeThemeId` | Session-local `StoryBuilderTheme` (mapping deferred) |
| SB.0 recommendation | "Extend `StoryUnderstanding`" | Extending HS.4 would require inventing Story first — **conflicts with SB.8 canonical-source rule** |

**Conflict classification:** Intentional product evolution (SB series). HS.4 remains valid for the capture/transcript path. SB.8 introduces a **Builder-session understanding** model rather than forcing Story materialization.

---

## 3. Existing ports/models reused

* `StoryBuilderSession` / `StoryBuilderResponse` / `StoryBuilderPrompt` / intent themes & purpose
* `StoryBuilderNarrativeRole` (11 SB.3 roles)
* `StoryBuilderTheme` vocabulary (14 themes)
* `DeterministicStoryStructure` + `DeterministicStoryStructureBuilder` (SB.4)
* `Result` / `Success` / `Failure` use-case pattern
* EH AI proxy auth, OpenAI chat client, middleware conventions (SB.7)
* Riverpod provider composition patterns from SB.7 coach wiring
* Flutter `http` client pattern from `ProxyStoryBuilderCoachAdapter`

**Not reused as the SB.8 model:** HS.4 `StoryUnderstanding` aggregate / `StoryUnderstandingPort` (different source, different questions, Story-required).

**Not overloaded:** `StoryBuilderCoachPort` (next question ≠ understanding).

---

## 4. New ports/models introduced and why

| New type | Why |
|----------|-----|
| `StoryBuilderUnderstanding` | Derived interpretive result for a Builder session — not a Story, not HS.4 aggregate |
| `StoryBuilderUnderstandingKind` | Explicit `deterministic` vs `aiEnhanced` |
| `UnderstoodTheme` / `UnderstoodNarrativeElement` / `UnderstoodSignificantEvent` / `UnderstoodClaim` / `UnderstoodKeyStoryElements` | Structured analysis with `sourceResponseIds` provenance |
| `StoryBuilderUnderstandingPort` | Separate AI boundary from coach + HS.4 understanding |
| `DeterministicStoryBuilderUnderstandingBuilder` | Offline Guided path from SB.3/SB.4 |
| `UnderstandStoryBuilderSessionUseCase` | Load session → validate material → derive understanding → leave session unchanged |
| `ProxyStoryBuilderUnderstandingAdapter` + parser/config | SB.7-style proxy client for `POST /story-understanding` |
| `InMemoryStoryBuilderUnderstandingAdapter` | Dev/test deterministic AI stand-in |
| Proxy `StoryUnderstandingHandler` | Dedicated endpoint; does not reuse coach route |

---

## 5. Story Understanding data model

```text
StoryBuilderUnderstanding
├── sessionId
├── kind (deterministic | aiEnhanced)
├── structure (DeterministicStoryStructure — SB.4 reused)
├── intentSnapshot (purpose/themes — not mutated)
├── processingVersion
├── analyzedAt
├── themes[] (UnderstoodTheme + origin + sourceResponseIds)
├── narrativeElements[] (role + sourceResponseIds + optional derivedNote)
├── keyElements (challenge/struggle/stakes/turningPoint/decision/action/outcome/reflection/message)
├── significantEvents[] (label + sourceResponseIds + optional role)
└── derivedSummary? (optional derived analysis only — never canonical Hero text)
```

Canonical source remains Hero responses. Understanding never copies response text into a second canonical store.

---

## 6. Provenance strategy

* Prefer `sourceResponseIds` over copied source text (aligned with SB.4).
* `StoryBuilderUnderstandingProvenance.validateDraft` rejects unknown response IDs against the session.
* Invalid AI provenance → typed `Failure`; session unchanged.
* Session-intent themes use `UnderstoodThemeOrigin.sessionIntent` (may have empty response IDs).
* Derived themes require non-empty `sourceResponseIds`.

---

## 7. Deterministic vs AI understanding

```text
Guided / offline:
  StoryBuilderSession
       ↓
  DeterministicStoryStructure (SB.4)
       ↓
  DeterministicStoryBuilderUnderstandingBuilder
       ↓
  StoryBuilderUnderstanding(kind: deterministic)

AI-enhanced (optional):
  StoryBuilderSession + structure
       ↓
  StoryBuilderUnderstandingPort
       ↓
  adapter → EH proxy POST /story-understanding
       ↓
  validate provenance
       ↓
  StoryBuilderUnderstanding(kind: aiEnhanced)
```

Deterministic understanding **does not** require the understanding port, network, or credentials. AI mode failures return `Failure` and never mutate the session or silently invent Story content.

---

## 8. AI proxy contract

`POST /story-understanding`

* Reuses `OPENAI_API_KEY`, optional Bearer `EH_AI_PROXY_AUTH_TOKEN`, shared chat model.
* Minimized request: purpose, themes, structureSections, responses (with ids).
* Hero text isolated in a delimited user-context block.
* Structured JSON response only — no polished story.
* System instructions prohibit invention, diagnoses, and story writing; require closed theme vocabulary and real response IDs.

Flutter wiring: `EH_STORY_BUILDER_UNDERSTANDING_MODE=proxy|development` (defaults like coach: proxy when `EH_AI_PROXY_URL` set).

---

## 9. Persistence decision

**Do not persist Story Builder Understanding in SB.8.**

Rationale:

* Understanding is derived and inexpensive to recompute from the durable session (same pattern as SB.4 structure).
* Canonical source is `StoryBuilderSession` (already file-persisted in SB.5).
* Avoids stale analysis / schema dual-source risks.
* HS.4 file-backed understanding repository remains a separate gap for Story-scoped proposals.

---

## 10. Error / failure behavior

| Failure | Behavior |
|---------|----------|
| Session missing / abandoned | `Failure` |
| No answered responses | `Failure` |
| AI port missing (aiEnhanced) | `Failure` (deterministic still works) |
| Proxy auth / network / timeout / 5xx | `StoryBuilderUnderstandingException` → use-case `Failure` |
| Malformed JSON / invalid theme / role / empty AI result | Rejected |
| Unknown response IDs | Rejected; session unchanged |
| Successful understanding | Session purpose/themes/responses/status/`storyId` unchanged; no Story created |

---

## 11. Intentionally deferred (SB.9+)

* Story shaping / authoring polished prose
* Automatic `Story` materialization from Builder sessions
* Hero approval UI
* Moments / Quotes / compilations
* Mapping `StoryBuilderTheme` → Discovery `NarrativeThemeId` / catalog apply
* Extending HS.4 propose/review/apply onto Builder material after Story exists
* File persistence of understanding proposals
* AI credits / Identity consume
* Production Understanding UI beyond application use case
* Changing SB.7 coach behavior

---

## 12. Files changed

### Domain
* `story_builder_understanding*.dart`, understood_* VOs, enums
* `story_builder_understanding_port.dart`, provenance, deterministic builder
* `domain.dart` exports

### Application
* `understand_story_builder_session_use_case.dart` + request DTO
* providers for port + use case

### Infrastructure
* in-memory + proxy adapters, config, response parser

### AI proxy
* `story_understanding_handler.dart`, instructions, server route, README, tests

### Tests
* `test/features/hero_story/application/use_cases/sb8_story_understanding_test.dart`
* `services/ai_proxy/test/ai_proxy_test.dart` (understanding cases)

### Docs
* `docs/analysis/SB-8-story-understanding.md` (this report)

---

## 13. Tests added

Focused Flutter (`sb8_story_understanding_test.dart`):

* Deterministic understanding from valid session; non-mutation; no Story
* SB.3 → SB.4 → SB.8 role/provenance mapping
* Skipped / partial sessions
* Empty / abandoned rejection
* AI-enhanced success + unknown ID rejection + empty/failure paths
* Parser validation (malformed / invalid theme / invalid role)
* Proxy adapter auth/server failure mapping
* Guided independence without understanding port

Proxy: understanding handler success + provider failure + instruction invariants.

---

## 14. Test results

| Suite | Result |
|-------|--------|
| Focused Flutter SB.8 | **14/14 passed** |
| AI proxy | **11/11 passed** (was 8/8; +3 understanding) |
| Full `flutter test` | **940/940 passed** (baseline 926 + 14 SB.8) |
| `dart analyze` | **0 errors**; **1 pre-existing warning** in `browse_stories_by_catalog_use_case.dart` (`unawaited_futures`); remaining issues are pre-existing / style `info` lints (including matching SB.7 proxy adapter patterns) |

---

## 15. `dart analyze` result

```text
0 errors
1 warning — browse_stories_by_catalog_use_case.dart (pre-existing, unrelated)
info lints — prefer_initializing_formals / style (pre-existing pattern + SB.8 proxy matching SB.7)
```

Not claiming a fully clean analyzer result: the existing warning remains.

---

## 16. Unresolved architectural questions

1. **When should Builder material become a `Story`?** SB.8 intentionally stops before materialization. SB.9/SB.11 must decide factory/consent timing.
2. **Should future Story-scoped HS.4 understanding ingest Builder-derived claims after materialization, or remain representation-text-only?** Not decided here.
3. **Theme bridge:** When/how `StoryBuilderTheme` maps to Discovery `NarrativeThemeId` without creating a second taxonomy ownership.
4. **Whether AI-enhanced understanding should ever be persisted** once shaping/approval needs a reviewable proposal artifact (likely SB.9–SB.10).

No blocker prevented a clean SB.8 implementation once HS.4 was treated as a sibling path rather than forced reuse without Story.
