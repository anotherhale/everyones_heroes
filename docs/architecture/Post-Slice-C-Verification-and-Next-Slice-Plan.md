# Post–Slice C Verification and Next Slice Plan

- **Document type:** Verification + next-slice assessment (planning only)
- **Status:** Complete — **does not authorize implementation**
- **Baseline (code):** `main` @ `86e1dcb` — Implement deterministic catalog phrase alignment for theme resolution (#72)
- **Predecessor plans:** `Post-Differentiated-Story-Selection-Verification-and-Next-Slice-Plan.md` (PR #71), `Post-Slice-A-Verification-and-Next-Slice-Plan.md` (PR #69), `Story-Discovery-Experience-Plan.md` (PR #67)
- **Constraint:** Planning only. Do not modify application code under this document. Do not implement the next slice. Do not create a generalized Personalization Engine. Do not reopen J.2.

---

## 1. Executive Summary

**PR #72 is architecturally and behaviorally complete for Slice C.**

It closes the realism gap left after Slice B: production theme resolution now matches catalog **name**, **description**, and **alias** whole phrases (with punctuation/whitespace normalization), so natural-language Reflections can diversify themes without literally naming the catalog theme.

Verification against current `main` confirms:

| Concern | Verdict |
|---------|---------|
| Reflection → theme resolution | **Complete** — `CatalogAlignedNarrativeThemeResolver` remains the sole production `NarrativeThemeResolver` |
| Phrase alignment (Slice C) | **Proven** — description/alias phrases → catalog IDs without theme names |
| Theme → Story selection | **Complete** — no new ranking subsystem; existing HS.8/J.2 path consumes diversified themes |
| Story identity differentiation | **Proven** — natural-language journals → different `adaptive-story-*` / `storyTargetId` |
| Evidence boundary | **Preserved** — consume ≠ evidence; explicit Reflection remains the gateway |
| Architecture drift from #72 | **None material** — intentional phrase alignment behind an existing port |

**What Slice C is *not*:** semantic understanding, personalization, or behavioral Story ranking. It is **deterministic catalog phrase alignment** feeding the existing selection path.

**Remaining product gap (binding):** once themes diversify, candidate Stories with equal theme overlap are ordered by **Story `updatedAt` / `storyId`**, not by how recently the user’s understanding changed. Theme **union** across reflections + uniform `patternBoost` means “updated understanding → different Story” is only reliable when Stories differ by theme *and* fixture timestamps cooperate. H.2 patterns reach signals but **do not reorder Stories relative to each other**.

**Recommended next slice (planning only):** **Deterministic Theme-Recency Story Ranking** — strengthen the existing ranker/signals so recent Reflection themes prefer matching Stories over historical union + Story publish-time ties — not a Personalization Engine, not ML, not a new experience-type framework.

---

## 2. Current Adaptive Loop

```text
Explicit Reflection (multi-modal responses)
  ↓ submit
ReflectionSubmitted
  ↓ AnalyzeReflectionUseCase
H.2 Understanding
  ├── Insights
  ├── BehavioralEvidence → BehavioralEvidenceDetected → Journey.behaviorPatterns
  └── NarrativeThemeIds
        CatalogAlignedNarrativeThemeResolver
          name → description → alias (whole-phrase, catalog order)
          fallback → discovery
  ↓
ResolveAdaptiveDiscoverySignalsUseCase / CatalogAlignedAdaptiveDiscoverySignalResolver
  ├── narrativeThemeIds = ∪ Reflection.narrativeThemes (sorted by id value)
  └── behaviorPatterns = Journey.behaviorPatterns
  ↓
DiscoverableStoryCandidatePort
  ├── Flutter: DiscoverStoriesCandidateAdapter → DiscoverStoriesUseCase
  └── Platform: DiscoverableStoryCandidateAdapter → StoryCandidateSource
  ↓ DeterministicStoryRelevanceRanker
       themeOverlap DESC → patternBoost (uniform) DESC → updatedAt DESC → storyId ASC
  ↓
AdaptiveExperienceComposer
  ├── adaptive-story-{StoryId} when themeOverlapCount > 0
  └── else UI.3 DeterministicExperienceSelectionService (reflection)
  ↓
Today card → Story Detail → Slice A Story Experience
  ↓ optional explicit Reflect
  └── loop
```

**Single selection path.** Slice C did not introduce a competing ranker, composer, or Personalization Engine.

---

## 3. Verified Behavior

### 3.1 Implementation (PR #72)

| Area | Files (representative) |
|------|------------------------|
| Resolver (Flutter + platform) | `catalog_aligned_narrative_theme_resolver.dart` |
| Catalog aliases | `narrative_theme_reference_catalog.dart` (+ entity `aliases`) |
| Tests | Resolver unit tests; catalog/entity tests; platform `j2_adaptive_discovery_signals_test.dart`; integration `differentiated_story_selection_pipeline_test.dart` |

**Confirmed absent from PR #72:** composer, ranker, Discover* adapter, Today use case, Story Experience UI, domain aggregate invariants, H.2 reactors, AI adapters, J.2 projection schema, Candidate aggregate.

### 3.2 Deterministic resolver rules (Slice C)

| Rule | Behavior |
|------|----------|
| Text sources | `JournalResponse`, `PromptResponse`, `ChoiceResponse` only |
| Normalize | lowercase; punctuation → space; collapse whitespace; keep `'` |
| Per-theme match order | **name** → **description** → **aliases** |
| Phrase match | whole-phrase `\b…\b` after normalize |
| Multi-match | catalog iteration order preserved |
| Fallback | empty / no match → `[discovery]` |
| Out of scope | no AI; no Story selection; catalog IDs only |

### 3.3 Test evidence

| Suite | Proves |
|-------|--------|
| `catalog_aligned_narrative_theme_resolver_test.dart` | Name, description, alias; catalog order; false positives (`discourage` / `serviced`); fallback; determinism |
| `differentiated_story_selection_pipeline_test.dart` | Slice B name-based + Slice C natural-language DoD → different `adaptive-story-*` / `storyTargetId` |
| Platform `j2_adaptive_discovery_signals_test.dart` | Phrase cases feed signals / Today seam |
| Ranker / composer / HS.8 / UI.3 / H.2 suites | Unchanged contracts still covered (regression surface) |

### 3.4 Answers to verification questions

#### A. Does Reflection now influence Story identity?

**Yes.** Exact path:

```text
Reflection.submit
  → AnalyzeReflectionUseCase
       → CatalogAlignedNarrativeThemeResolver.resolveThemes
       → reflection.addNarrativeThemes(...)
  → GetTodayExperienceUseCase
       → ResolveAdaptiveDiscoverySignals (union themes + Journey patterns)
       → DiscoverableStoryCandidatePort.findRelevant
       → DeterministicStoryRelevanceRanker
       → AdaptiveExperienceComposer → adaptive-story-{id}
```

Themes are stored on the Reflection during analysis; Today **does not** re-run the resolver at selection time.

#### B. Is the influence deterministic?

**Yes.** Identical reflection text → identical theme ID list. Ranking is fully deterministic given signals + candidate set. No randomness; no AI.

#### C. Is the influence explainable?

**Partially.**

| Available today | Missing |
|-----------------|---------|
| `AdaptiveExperience.rationale` string (themes-only vs themes+patterns) | Structured `explanationSources` |
| Candidate `matchedThemeIds` / `themeOverlapCount` in ranking DTOs | User-facing “matched phrase / catalog field” provenance |
| Pattern label preference in composer rationale | Why *this* Story beat another equal-overlap Story (often just `updatedAt`) |

Explanation is grounded (HS.8) but thin: it does not yet say *which* reflection phrase or *which* ranking key selected Story A over Story B.

#### D. Still using existing selection architecture?

**Yes.** One path: signals → Discover* → existing ranker → existing composer → UI.3 reflection fallback. No competing selection subsystem.

#### E. Genuine adaptation or content/theme routing?

**Content/theme routing with observable Story identity change** — not behavioral personalization, not semantic understanding.

Precise characterization:

| Layer | Status after Slice C |
|-------|----------------------|
| Catalog phrase → theme | **Adaptive input quality** (deterministic alignment) |
| Theme → Story identity | **Adaptive Story routing** when themes diversify against classified Stories |
| Behavioral understanding → Story identity | **Not differentiating** (uniform `patternBoost`) |
| Personalization engine | **Absent** (by design) |

Do **not** oversell phrase matching as semantic understanding. `"I spoke up even though I was terrified"` still falls back to `discovery` unless it contains an approved catalog phrase.

---

## 4. What Is Now Adaptive

Keep these distinct:

| Concept | Current state |
|---------|---------------|
| **Content/theme alignment** | Deterministic catalog name/description/alias phrases on Reflection analysis |
| **Story selection** | Theme-overlap gating + ranking; composer takes `.first` |
| **Behavioral understanding (H.2)** | Evidence → patterns on Journey; copied into signals |
| **Personalization** | Not implemented as a product; HS.8 adaptive relevance only |

Slice C advances **theme alignment realism**. It does not advance behavioral Story differentiation or multi-type experience selection.

---

## 5. Remaining Gaps

### 5.1 Theme resolution depth

Matching **stops** at exact catalog phrases (name / description / alias) after normalization.

| Matches | Does not match |
|---------|----------------|
| `"acting despite fear"` → courage | `"I was terrified but spoke up"` |
| `"helping others through lived experience"` → service | Paraphrases outside the catalog phrase set |
| `"courage"` → courage | Synonyms / embeddings / LLM inference |

Further phrase expansion is catalog maintenance (diminishing returns), not architecture. Broader meaning requires a replaceable semantic port — premature while ranking among known themes remains weak (see §5.2).

### 5.2 Story differentiation after theme resolve (binding gap)

```text
Reflection → courage
  → Candidate A (courage)
  → Candidate B (courage)
  → Candidate C (courage)
  → ?
```

Current ranker:

1. Drop zero overlap.
2. Sort: `themeOverlapCount` DESC → **uniform** `patternBoost` DESC → **Story `updatedAt`** DESC → `storyId` ASC.

Consequences:

* Multiple Stories sharing one theme → differentiation is **publish/update time**, not understanding.
* Theme **union** (sorted by id value) loses **recency of understanding**. After courage then service Reflections, both themes compete equally; equal overlap often resolves by Story timestamp.
* Slice B/C integration fixtures carefully seed Story B newer than Story A so the second selection “works.” That is a **fixture artifact**, not proof that updated understanding drives ranking when Story timestamps disagree.

`patternBoost` is computed once per signal set and applied identically to every candidate — it **cannot** reorder Stories relative to each other.

### 5.3 Behavioral understanding → Story selection

H.2 **is wired**:

```text
Reflection → evidence → BehavioralEvidenceDetected
  → DetectPatternUseCase → Journey.updateBehaviorPatterns
  → AdaptiveDiscoverySignals.behaviorPatterns
```

But under current ranker/composer rules:

* Patterns alone never create Story relevance (`hasThemes` required).
* Patterns strengthen score/rationale uniformly.
* Patterns meaningfully change Today mainly on the **reflection fallback** path (UI.3 consistency variant).

**Existence of Behavioral Evidence ≠ adaptive Story selection by behavior.**

### 5.4 Selection explanation

Rationale strings exist; structured sources and tie-break provenance do not. Secondary to ranking correctness.

### 5.5 Experience diversity

`ExperienceType` enum includes `mission`, `reflection`, `story`, `coaching`, `discovery`.

**Runtime emissions today:** `story` (composer) and `reflection` (UI.3 fallback). No production path emits mission/coaching/discovery. Adaptive pipeline currently proves **different Stories** (and two reflection variants), not a multi-type experience chooser.

### 5.6 Technical debt vs next slice

| Item | Constrains next slice? |
|------|------------------------|
| **TD-003** Narrative Guidance Engine | No — do not implement as next slice |
| **TD-005** Contribution | No |
| **TD-006** Event Pipeline Wiring | Doc partially stale — H.2 core reactors **are** wired; unused GO reactors do not block ranking |
| **TD-007** Clock Injection | Hygiene only; use controllable time if ranking uses Reflection `submittedAt` |
| **TD-008** Reflection Query Support | Doc stale — `findByJourneyId` exists and powers signals |
| **TD-001** Pattern Detection | Doc stale — H.2 pattern layer exists |
| DRIFT-011 Flutter `NarrativeThemeAlignment` | Hygiene; non-blocking while IDs stay catalog-valid |

None of TD-003…008 **blocks** a theme-recency ranking slice. TD-007 is the only hygiene item to respect if timestamps enter scoring.

---

## 6. Candidate Next Slices

### Candidate A — Stronger deterministic Story ranking

**Idea:** Once themes resolve, differentiate candidates using existing deterministic signals — especially **theme recency from Reflections** — inside the current ranker/composer path.

Potential shape:

```text
Reflection
  ↓ Theme (Slice C)
Candidate Stories
  ↓ Existing Discover* + ranker (extended scoring)
Differentiated ranking preferring recent understanding
  ↓
Story
```

| Dimension | Assessment |
|-----------|------------|
| **Capability gained** | Updated understanding prefers matching Stories even when historical themes remain in the union and Story timestamps disagree |
| **Architectural impact** | Small — extend `AdaptiveDiscoverySignals` and/or `DeterministicStoryRelevanceRanker` (+ dual-stack parity); no new aggregate |
| **Product impact** | High for the proven Story loop — makes “Reflection changed Today’s Story” attributable to understanding, not fixture `updatedAt` |
| **Implementation size** | Small–medium vertical slice (signals + ranker + tests + dual-stack) |
| **Risk** | Over-weighting recency; quietly inventing affinity semantics; expanding into a Personalization Engine |
| **Reuse** | Ranker, composer, Discover*, Today UC, Slice A experience, Reflection `submittedAt` |
| **New abstraction?** | Prefer none. Optional: recency weights on existing signals DTO — not a new port family |

**Ready now.** This was the secondary gap named after Slice B; Slice C made it binding.

---

### Candidate B — Richer H.2 behavioral understanding into selection

**Idea:** Expose pattern signals so they change Story identity (not only uniform boost / rationale).

| Dimension | Assessment |
|-----------|------------|
| **Capability gained** | Behavior patterns influence which Story wins |
| **Architectural impact** | Medium — needs pattern↔theme or pattern↔Story affinity semantics not present today |
| **Product impact** | High long-term; low immediate without affinity design |
| **Implementation size** | Medium+ (domain meaning + ranker + dual-stack + tests) |
| **Risk** | Inventing affinity without product evidence; collapsing evidence into guidance |
| **Reuse** | H.2 pipeline, signals field already present |
| **New abstraction?** | Likely affinity rules or weighted boosters — design decision required |
| **Ready?** | **Not yet** — wired but non-differentiating; affinity is a larger decision than theme-recency |

Defer until ranking can express *relative* candidate preference for known signals.

---

### Candidate C — Second adaptive experience type

**Idea:** Prove understanding can choose Mission / Coaching / etc., not only Stories.

| Dimension | Assessment |
|-----------|------------|
| **Capability gained** | Multi-type adaptive Today |
| **Architectural impact** | Large — candidate ports/projections for non-Story types largely absent; HS-ADR-059 intentionally limited typed targets |
| **Product impact** | Broadens surface; does not deepen Story-path ranking honesty |
| **Implementation size** | Large relative to ranking |
| **Risk** | Premature generalized experience engine |
| **Reuse** | UI.3 reflection variants already prove limited type adaptation |
| **New abstraction?** | Likely new candidate ports / targets |
| **Ready?** | Application boundary *could* grow, but infrastructure is not ready for a small slice |

Defer. Reflection-type adaptation is already partially proven; Story ranking honesty is the open Story gap.

---

### Candidate D — Bounded semantic understanding

**Idea:** Replaceable port for paraphrase → catalog theme, non-authoritative.

| Dimension | Assessment |
|-----------|------------|
| **Capability gained** | Themes from ordinary paraphrases beyond catalog phrases |
| **Architectural impact** | Medium — new port behind `NarrativeThemeResolver` or adjacent; dual-stack adapters |
| **Product impact** | High for realism *if* ranking already prefers recent themes |
| **Implementation size** | Medium (port + fake deterministic adapter + optional later AI adapter) |
| **Risk** | Premature AI authority; false themes; catalog bypass temptation |
| **Reuse** | Existing resolver port as façade |
| **New abstraction?** | Yes — semantic interpretation port (must stay non-authoritative) |
| **Ready?** | **Premature as next slice** — exhaust deterministic ranking on known themes first; phrase catalog can expand incrementally without AI |

---

## 7. Recommended Next Slice

### Name

**Slice D — Deterministic Theme-Recency Story Ranking**  
(working title; authorization separate)

### Intent

Prove:

```text
Current capability
  Slice C phrase → theme → Story routing (when themes differ)

Smallest missing capability
  Recent Reflection themes outweigh historical union + Story.updatedAt ties
  inside the existing DeterministicStoryRelevanceRanker

Observable adaptive behavior
  Reflection A → understanding/signals → Story X
  Reflection B → updated understanding/signals → Story Y
  X ≠ Y
  attributable to theme-recency ranking — not Story publish-time fixtures
```

### Why this is the next logical increment

1. **Binding gap after Slice C** — themes can diversify; relative Story choice among equal-overlap candidates is still timestamp-driven.
2. **Smallest vertical change** — reuse Discover*, ranker, composer, Today UC; no new aggregates, experience types, or AI.
3. **Architecture already sufficient** — HS-ADR-054…057 lock adaptive relevance over Discover* via UI.3; extend scoring, do not invent a Personalization Engine.
4. **Testable** — end-to-end DoD with intentionally adverse Story timestamps (older Story matches recent theme; newer Story matches stale theme) proving recent understanding wins.
5. **Product feel** — Today’s Story tracks what the person *just* reflected on, which is the clearest “adaptive” sensation without claiming semantic intelligence.

### Why not B / C / D (user candidates) first

* **B (H.2 into selection)** — needs affinity semantics; patterns are already present but non-differentiating.
* **C (second experience type)** — missing candidate infrastructure; expands surface before Story ranking is honest.
* **D (bounded semantic)** — valuable later; does not fix equal-overlap / union-recency ranking; risks AI authority prematurely.

### Explicitly out of scope for Slice D

* ML / AI ranking or embeddings
* Personalization Engine product
* Pattern–Story affinity redesign (Candidate B follow-on)
* Growth Opportunities / Narrative Guidance (TD-002/003)
* Mission/Coaching experience-type selection
* Candidate aggregate
* Multi-device Story content API
* J.2 reopen / projection schema changes
* Structured explanation UI beyond what ranking needs for tests
* Expanding catalog aliases as the primary DoD (optional hygiene only)

---

## 8. Explicitly Deferred Work

Carry forward:

* Generalized Personalization Engine
* ML / AI ranking / recommendation framework
* Broad semantic user modeling / embeddings as authoritative truth
* Growth Opportunity Detection / Narrative Guidance Engine (TD-002/003)
* D.1 Discovery Profile productization
* Candidate aggregate
* Multi-device Story content API / platform Story narrative read
* Platform-wide Story synchronization redesign
* Phase 7
* Contribution / social / community / marketplace / subscriptions
* Generalized experience recommendation / multi-type chooser
* Pattern–Story affinity / non-uniform behavioral boost redesign
* Reopening J.2 eligibility/projection
* Flutter `NarrativeThemeAlignment` parity (unless DoD emits non-catalog IDs — it must not)
* Post-Story Reflect uptake UX (separate from selection intelligence)

---

## 9. Proposed Next-Slice Acceptance Criteria

### 9.1 Ranker / signals unit tests

1. Given equal `themeOverlapCount`, a candidate matching a **more recently submitted** Reflection theme ranks above a candidate matching only older union themes — **even when** the older-theme Story has a newer `updatedAt`.
2. Themes-only cold path still works; patterns alone still do not invent Story relevance.
3. Deterministic: identical signals + candidates → identical order.
4. Flutter and platform rankers share the same rules.

### 9.2 Integration DoD test

```text
Seed Story X classified courage (updatedAt = NEW)
Seed Story Y classified service (updatedAt = OLD)

Reflection A (courage phrase) → Today adaptive-story-X
Reflection B (service phrase) → Today adaptive-story-Y

Assert:
  storyTargetId Y ≠ storyTargetId X
  Y wins despite older Story.updatedAt
  attributable to theme-recency (document assertion strategy)
```

Prefer production `CatalogAlignedNarrativeThemeResolver` (Slice C phrases), not planted theme IDs.

### 9.3 Regression

* Slice B/C differentiated pipeline tests still pass.
* Slice A continuity + consume ≠ evidence still pass.
* HS.8 / composer / UI.3 reflection Today suites still pass.
* H.2 pattern detection suites still pass (may remain non-differentiating for Stories).
* No AI ports; no Personalization Engine types; no J.2 schema changes; no Candidate aggregate.

### 9.4 Definition of Done

Not complete merely because scores “look smarter.”

Complete when:

1. Recent Reflection themes deterministically prefer matching Stories over historical union + Story timestamp ties.
2. End-to-end Today Story identity change is attributable to that ranking rule under adverse timestamps.
3. Evidence boundary and Slice A experience path remain unchanged.
4. Dual-stack parity on ranking/signals rules.
5. Analyzer clean on touched files; focused + relevant suites green.

---

## 10. Architecture Decision

**Verdict:** Current architecture is **sufficient** for the recommended slice.

| Boundary | Decision |
|----------|----------|
| Domain | No new aggregate; Reflection `submittedAt` / themes already exist; patterns stay on Journey |
| Application | Prefer extending `AdaptiveDiscoverySignals` + `DeterministicStoryRelevanceRanker` (+ composer only if rationale must cite recency) |
| Ports | Keep `DiscoverableStoryCandidatePort` / Discover*; do not add a second selection path |
| Infrastructure | Dual-stack parity only; no AI SDK |
| Presentation | No UI redesign required for DoD |
| ADRs | Remains inside HS-ADR-054…057; do not invent Personalization Engine |

Do **not** invent abstractions for future Mission/Coaching choosers or semantic engines in this slice.

If implementation discovers that signals must carry ordered/weighted theme entries, that is a **DTO evolution**, not a new bounded context.

---

## 11. Architecture Principles Checklist

| Principle | Post–Slice C status |
|-----------|---------------------|
| DDD boundaries intact | Yes |
| Domain free of Flutter/Riverpod/UI/HTTP/AI SDKs | Yes |
| Application orchestrates workflows | Yes (`GetTodayExperienceUseCase`) |
| Infrastructure implements ports | Yes (Discover* / projection adapters) |
| Story domain authoritative for Story content | Yes |
| No unnecessary Candidate aggregate | Yes |
| No generalized Personalization Engine | Yes |
| No ML/AI ranking | Yes |
| Reflection gateway to behavioral understanding | Yes |
| Story consumption ≠ Behavioral Evidence | Yes |
| J.2 discovery infrastructure reusable | Yes |
| Flutter/platform dual-stack parity (resolver/ranker/composer) | Yes (signals alignment filter still Flutter-partial — DRIFT-011) |
| Existing ranker/composer remain the selection path | Yes |
| New Slice C behavior deterministic and testable | Yes |
| No material architecture drift from #72 | Yes |

---

## 12. Final Readiness Verdict

1. **Is PR #72 complete?** **Yes** — for Deterministic Catalog Phrase Alignment (Slice C).
2. **What does Slice C prove?** Natural-language catalog phrases can diversify themes and change Story identity through the existing pipeline — without semantic AI.
3. **What remains thin?** Ranking honesty under theme union and equal overlap; H.2 non-differentiating for Stories; no multi-type experience chooser.
4. **Recommended next slice?** **Deterministic Theme-Recency Story Ranking** (Candidate A).
5. **Why?** Smallest capability that makes updated understanding — not Story publish time — drive Story identity.
6. **Architecture sufficient?** **Yes** — evolve signals/ranker scoring; no new engine.
7. **This document authorizes implementation?** **No.**

---

## 13. Validation Baseline (this planning task)

| Check | Result |
|-------|--------|
| `dart analyze` (Flutter app) | No errors/warnings; 65 pre-existing **info**-level lints only |
| Focused Slice C / ranking / HS.8 / UI.3 / signals | **57/57** passed |
| Slice A continuity + H.2 authority | **14/14** passed |
| Platform `j2_adaptive_discovery_signals` + catalog + H.2 | **24/24** passed |
| Full Flutter suite | **1160/1160** passed |

No production behavior was modified to obtain these results.

---

*Verification baseline: `main` @ `86e1dcb` (PR #72). Planning only. No application code modified.*
