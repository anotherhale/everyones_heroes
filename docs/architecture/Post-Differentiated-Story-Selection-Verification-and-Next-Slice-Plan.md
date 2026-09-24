# Post–Differentiated Story Selection Verification and Next Slice Plan

- **Document type:** Verification + next-slice assessment (planning only)
- **Status:** Complete — **does not authorize implementation**
- **Baseline (code):** `main` @ `bcaf308` — Implement Differentiated Story Selection (Slice B) (#70)
- **Predecessor plans:** `Post-Slice-A-Verification-and-Next-Slice-Plan.md` (PR #69), `Story-Discovery-Experience-Plan.md` (PR #67), `Post-J2-Slice5-Verification.md` (PR #66)
- **Constraint:** Planning only. Do not modify application code under this document. Do not implement the next slice. Do not create a generalized Personalization Engine. Do not reopen J.2.

---

## 1. Executive Summary

**PR #70 is architecturally and behaviorally complete for Slice B.**

It closes the Post–Slice A adaptive gap: production theme resolution is no longer always-`discovery`, so an explicit Reflection can deterministically change which `adaptive-story-*` Story Today selects — through the **existing** H.2 → AdaptiveDiscoverySignals → Discover*/ranker → composer path.

Verification against current `main` confirms:

| Concern | Verdict |
|---------|---------|
| Reflection → H.2 understanding | **Complete** — `AnalyzeReflectionUseCase` still drives themes + evidence |
| Understanding → Theme | **Complete** — `CatalogAlignedNarrativeThemeResolver` remains the sole production `NarrativeThemeResolver` |
| Theme → Story selection | **Complete** — no new ranking subsystem; existing HS.8/J.2 path consumes diversified themes |
| Story identity differentiation | **Proven** — integration test: Story A → Reflection → Story B (`storyTargetId` / `adaptive-story-*` change) |
| Evidence boundary | **Preserved** — consume ≠ evidence; explicit Reflection → evidence path |
| Architecture drift from #70 | **None material** — intentional signal-quality fix behind an existing port |

**Remaining product gap:** themes diversify only when reflection text contains **exact catalog theme names** (whole-phrase). Realistic natural-language Reflections usually fall back to `discovery`, so the adaptive Story loop is proven in controlled fixtures but still thin for ordinary user writing.

**Recommended next slice (planning only):** richer **deterministic catalog phrase alignment** behind the same `NarrativeThemeResolver` — not a Personalization Engine, not ML ranking, not new experience-type infrastructure.

---

## 2. PR #70 Verification

### 2.1 Implementation (files touched)

PR #70 changed **six** paths only:

| File | Role |
|------|------|
| `lib/features/discovery/application/services/catalog_aligned_narrative_theme_resolver.dart` | Flutter content-aware catalog-name matching |
| `services/eh_platform/.../catalog_aligned_narrative_theme_resolver.dart` | Platform parity |
| `services/eh_platform/.../seeded_story_candidate_catalog.dart` | Comment-only (seed themes unchanged) |
| `test/features/discovery/.../catalog_aligned_narrative_theme_resolver_test.dart` | Expanded unit coverage |
| `test/integration/differentiated_story_selection_pipeline_test.dart` | **New** DoD integration proof |
| `services/eh_platform/test/j2_adaptive_discovery_signals_test.dart` | Content-aware contract updates |

**Confirmed absent from PR #70:** composer, ranker, Discover* adapter, Today use case, Story Experience UI, domain aggregates, H.2 reactors, AI adapters, J.2 projection schema, Candidate aggregate.

### 2.2 Tests

| Suite / test | Proves |
|--------------|--------|
| `catalog_aligned_narrative_theme_resolver_test.dart` | Name match (`courage`, `service`); multi-match catalog order; substring non-match (`discourage`); prompt/choice text; empty/unrecognized → `discovery`; determinism; catalog-only IDs |
| `differentiated_story_selection_pipeline_test.dart` | Production resolver → analyze → Today `adaptive-story-{A}` then `adaptive-story-{B}` |
| Platform `j2_adaptive_discovery_signals_test.dart` | Content-aware themes feed signals / Today seam |
| Reported full Flutter suite at merge | **1150/1150** (PR #70 body; not re-run by this planning task) |

### 2.3 Adaptive loop (Reflection → Understanding)

```text
Explicit Reflection (submitted)
  → AnalyzeReflectionUseCase
       insightExtractionService.extractInsights
       behavioralEvidenceAnalysisOrchestrator.analyze
       narrativeThemeResolver.resolveThemes(reflection)   ← CatalogAligned…
       reflection.addNarrativeThemes(themes)
       → BehavioralEvidenceDetected (when evidence present)
  → (reactors) DetectPatternUseCase → Journey.behaviorPatterns
```

Provider wiring unchanged: `narrativeThemeResolverProvider` → `const CatalogAlignedNarrativeThemeResolver()` → `analyzeReflectionUseCaseProvider`.

Slice B did **not** bypass H.2. Themes are still written onto the Reflection aggregate during analysis and later unioned by `DefaultResolveAdaptiveDiscoverySignalsUseCase`.

### 2.4 Understanding → Theme (`CatalogAlignedNarrativeThemeResolver`)

| Aspect | Current behavior (code) |
|--------|-------------------------|
| **Boundary** | Implements existing domain port `NarrativeThemeResolver.resolveThemes(Reflection)` |
| **Inputs** | Reflection responses: `JournalResponse` (prompt + response), `PromptResponse`, `ChoiceResponse` (question + selectedOption). Other response types contribute no text |
| **Outputs** | `List<NarrativeThemeId>` — only IDs from `NarrativeThemeReferenceCatalog` / `NarrativeThemeReferenceIds` |
| **Matching rules** | Case-insensitive **whole-phrase** match of catalog theme **`name`** against joined response text (`\b…\b` so `"courage"` does not match `"discourage"`) |
| **Multi-match** | All matching catalog themes preserved in **catalog order** |
| **Determinism** | Identical reflection text → identical ID list (unit-tested) |
| **Fallback** | Empty text or no name match → `[NarrativeThemeReferenceIds.discovery]` |
| **AI** | None |
| **Second abstraction?** | **No** — still one production resolver; deprecated `FakeNarrativeThemeResolver` delegates to it |

### 2.5 Theme → Story selection

```text
GetTodayExperienceUseCase
  → ResolveAdaptiveDiscoverySignalsUseCase
       themes = ∪ Reflection.narrativeThemes (sorted)
       patterns = Journey.behaviorPatterns
  → DiscoverableStoryCandidatePort.findRelevant(signals)
       DiscoverStoriesCandidateAdapter
         if !signals.hasThemes → []
         DiscoverStoriesUseCase → DeterministicStoryRelevanceRanker
  → AdaptiveExperienceComposer
       themeOverlapCount > 0 → adaptive-story-{storyId}
       else → DeterministicExperienceSelectionService (reflection)
```

**No new ranking engine.** Ranker scoring remains: theme overlap desc → uniform `patternBoost` → `updatedAt` desc → `storyId` asc. Composer still takes `.first` among overlap > 0.

### 2.6 Story identity differentiation

Integration test `differentiated_story_selection_pipeline_test.dart`:

1. Seed Story A (`courage`) and Story B (`service`) with distinct `createdAt` / publish times.
2. Journal: `"Today I found courage when I spoke up."` → analyze with **production** resolver → Today id `adaptive-story-${storyA.id}` and `StoryExperienceTarget(storyId: storyA.id)`.
3. Journal: `"I want to grow through service to others."` → analyze → Today id `adaptive-story-${storyB.id}` and target Story B.
4. Assert `second.id` ≠ `first.id`.

This is **Story identity** differentiation (`storyTargetId` / adaptive experience id), not merely an internal theme-list assertion.

**Nuance (documented, not a defect):** after both analyses, theme **union** may contain both `courage` and `service`. With equal overlap, ranker tie-break (`updatedAt`) selects among eligible Stories. The first step is theme-gated (only A matches); the second step proves a different Story id under diversified signals. See §5.

### 2.7 Evidence boundary

Still true on current `main`:

```text
Story viewing / begin / consume / complete
        ≠ Behavioral Evidence

Explicit Reflection submit (+ analysis)
        → Behavioral Evidence (+ Narrative Themes)
        → Pattern detection
```

Evidence:

* `ConsumeStoryExperienceUseCase` documents: does not create BehavioralEvidence or BehaviorPatterns (HS.7 D9 / HS-ADR-011).
* Slice A test `'viewing and completing a Story does not create evidence'` — empty reflection repo; no `ReflectionSubmitted`; no `BehavioralEvidenceDetected`.
* Differentiated selection is driven by **analyzed Reflection content** → themes on Reflection → signals — not by consume/complete.

PR #70 did not weaken this boundary.

---

## 3. Architecture Assessment

### 3.1 Bounded-context impact

| Context | Impact of #70 |
|---------|----------------|
| Discovery | Application resolver behavior only; catalog ownership unchanged |
| Life Journey | Consumes themes via existing analysis + signals; no aggregate schema change |
| Hero & Story | Unchanged (Stories already carry classification theme IDs) |
| Identity / Contribution | Untouched |

Cross-context coupling remains identifier-based (`NarrativeThemeId`). Hero & Story is **not** improperly coupled to behavioral understanding: selection still goes Reflection themes ∪ Journey patterns → Discover* → composer.

### 3.2 Aggregate impact

**No new aggregates.** No changes to Reflection/Journey/Story/Hero invariants required by #70. Themes continue to live on Reflection; patterns on Journey.

### 3.3 Application boundary

Changed: Discovery application `CatalogAlignedNarrativeThemeResolver` (Flutter + platform).

Unchanged: `AnalyzeReflectionUseCase`, `ResolveAdaptiveDiscoverySignalsUseCase`, `GetTodayExperienceUseCase`, `DeterministicStoryRelevanceRanker`, `AdaptiveExperienceComposer`, Discover* ports/adapters.

### 3.4 Infrastructure boundary

No new persistence, AI SDKs, or vendor coupling. Seeded catalog comment only.

### 3.5 Presentation / Riverpod boundary

No UI changes. Providers still compose; Riverpod does not embed theme-matching rules.

### 3.6 Architecture drift

| Check | Result |
|-------|--------|
| Second theme-resolution port/abstraction | **None** |
| New ranking / Personalization Engine | **None** |
| Business logic moved into presentation | **None** |
| AI dependency introduced | **None** |
| Improper HS ↔ H.2 coupling | **None** |
| New aggregate | **None** |

**Stale documentation note (documentation drift, not code drift):** older docs (`Post-J2-Slice5-Verification.md`, Post–Slice A plan pre-#70 sections) still describe always-`discovery` analyzer output. Code on `main` @ `bcaf308` supersedes those sentences. Do not reopen them as active defects.

**Proposed-but-unfiled items remain unfiled** (not introduced by #70): Flutter `NarrativeThemeAlignment` parity (DRIFT-011 proposed), TD-J2-002 formally in `technical-debt.md` (conceptually addressed by Slice B for always-`discovery`).

### 3.7 Technical debt

PR #70 does **not** create new technical debt. Residual limitations below are **intentional slice boundaries** or **future product opportunities**, not defects (§5).

Known hygiene items listed in `AGENTS.md` §29 remain out of scope unless they block a future authorized slice.

---

## 4. Current Adaptive Loop

```text
Explicit Reflection (multi-modal responses)
  ↓ submit
ReflectionSubmitted
  ↓ AnalyzeReflectionUseCase
H.2 Understanding
  ├── Insights
  ├── BehavioralEvidence → BehavioralEvidenceDetected → patterns on Journey
  └── NarrativeThemeIds (CatalogAlignedNarrativeThemeResolver)
  ↓
ResolveAdaptiveDiscoverySignalsUseCase
  ├── narrativeThemeIds = ∪ reflection themes
  └── behaviorPatterns = Journey.behaviorPatterns
  ↓
DiscoverableStoryCandidatePort / DiscoverStoriesCandidateAdapter
  ↓ DeterministicStoryRelevanceRanker (theme overlap primary)
  ↓
AdaptiveExperienceComposer
  ├── adaptive-story-{StoryId} when themeOverlapCount > 0
  └── else UI.3 reflection Today
  ↓
Today card → Story Detail → text-first Story Experience (Slice A)
  ↓ optional explicit Reflect
  └── loop
```

**Product capability now demonstrable:**

> Yes — EH can use **explicit user Reflection** to select a **meaningfully different Story** through the existing adaptive experience pipeline, when reflection text contains catalog theme **names** that diversify overlap against seeded/classified Stories.

---

## 5. Current Limitations

### 5.1 Intentional deterministic boundaries

* Catalog-bounded theme IDs only (no invented themes).
* Whole-phrase name matching (deterministic; no AI/ML).
* Unrecognized / empty content → `discovery` fallback.
* Themes required for Story relevance (`hasThemes` / overlap > 0); patterns alone do not invent Story matches.
* `patternBoost` applied uniformly per signal set (patterns strengthen score/rationale, not relative Story order).
* Composer takes top ranked candidate; no multi-card feed.
* Story consume remains non-evidential (HS-ADR-011).

### 5.2 Known limitations (current-slice, not defects)

| Limitation | Effect |
|------------|--------|
| Catalog-**name** whole-phrase matching only | Natural language without exact names → `discovery` |
| No description / synonym / semantic matching | Catalog `description` fields unused by resolver |
| Theme **union** across reflections | Older themes remain in signals; selection among multi-overlap Stories leans on overlap count then `updatedAt` |
| Uniform `patternBoost` | Cannot reorder Stories relative to each other by pattern type |
| Dual-stack Story **content** still Flutter-local | Multi-device seeker Story body read not in scope |
| Flutter local signals lack platform `NarrativeThemeAlignment` filter | Proposed DRIFT-011; non-blocking while IDs stay catalog-valid |

### 5.3 Actual technical debt

None newly introduced by PR #70. Closed/related:

* TD-J2-001 (candidate projection sync) — previously closed.
* Always-`discovery` production resolver — **resolved by Slice B** (informal TD-J2-002 concept).

Do not classify name-only matching or uniform `patternBoost` as defects; they are explicit Slice B non-goals.

### 5.4 Deferred capabilities

Carry forward (§9): Growth Opportunity Detection; Personalization Engine; ML/AI ranking; D.1 Discovery Profile productization; Candidate aggregate; multi-device Story content API; platform-wide Story sync redesign; Phase 7; social/community; marketplace; subscriptions; pattern–Story affinity; structured `explanationSources` UI beyond rationale string; J.2 reopen.

---

## 6. Remaining Product Gap

**What PR #70 proved:** the adaptive Story selection **mechanism** works end-to-end when themes diversify.

**What is still thin:** the **signal realism** of theme resolution for ordinary Reflections.

```text
Fixture journal containing the word "courage"
        → differentiated Story   ✅ proven

Natural reflection: "I spoke up even though I was terrified"
        → no catalog name match → discovery fallback
        → Story identity often unchanged   ❌ product gap
```

Secondary gap (after themes are realistic): when many themes accumulate via union, relative Story ranking among equal-overlap candidates is weak (updatedAt). That matters **after** realistic themes exist; it is not the binding first missing capability.

Improving H.2 evidence richness alone does not change Story identity under current ranker rules. Adding new experience types does not close the Story-path realism gap.

---

## 7. Candidate Next Slices

Evaluate tradeoffs. Do **not** treat this as a best/worst ranking table of technical taste — each is assessed against the adaptive product loop and smallest-slice rule.

### A. Better semantic theme understanding

**Idea:** Move beyond catalog-**name** whole-phrase matching toward richer **deterministic** content/theme alignment (e.g. catalog description phrases and/or explicit catalog aliases), still catalog-bounded, still no AI.

| | |
|--|--|
| **Advances** | Makes the proven Reflection → Story path work for realistic writing |
| **Reuses** | Same `NarrativeThemeResolver` port, dual-stack resolvers, signals, ranker, composer, Slice A experience |
| **Dependencies** | Catalog already has `name` + `description`; optional small catalog alias data if needed |
| **Risks** | Over-broad matching; false-positive themes; temptation to jump to AI/embeddings |
| **Scope discipline** | Stay deterministic and catalog-owned; dual-stack parity; tests for false positives |

### B. Stronger differentiated ranking

**Idea:** Use theme/pattern strength or recency so ranking is not primarily equal-overlap + `updatedAt`.

| | |
|--|--|
| **Advances** | Better discrimination once many themes/candidates compete |
| **Reuses** | Ranker/composer seams |
| **Dependencies** | Either invent pattern↔Story affinity (new semantics) or introduce theme-recency weighting in signals |
| **Risks** | Quietly becoming a Personalization Engine; designing affinity without product evidence |
| **Scope discipline** | Premature while most natural Reflections still collapse to `discovery` |

### C. Additional adaptive experience types

**Idea:** Prove understanding → selection for something other than Story (e.g. Mission / other Today types).

| | |
|--|--|
| **Advances** | Broadens adaptive surface beyond Stories |
| **Reuses** | UI.3 reflection path already differentiates some reflection experiences |
| **Dependencies** | Mission (or other) candidate ports/projection largely absent for adaptive Today |
| **Risks** | Large infrastructure before Story-path realism is usable |
| **Scope discipline** | Reflection-type adaptation already partially proven; Story realism is the open Story gap |

### D. Stronger behavioral understanding

**Idea:** Enrich H.2 evidence/patterns before further selection sophistication.

| | |
|--|--|
| **Advances** | Better person understanding long-term |
| **Reuses** | H.2 pipeline |
| **Dependencies** | Downstream selection still ignores per-candidate pattern differences |
| **Risks** | Investment that does not change observable Story identity under current ranker |
| **Scope discipline** | Valuable later; not the smallest Story-loop increment now |

### E. Repository-supported alternatives

| Alternative | Assessment |
|-------------|------------|
| Flutter `NarrativeThemeAlignment` parity | Hygiene / dual-stack consistency; low product visibility if IDs stay catalog-valid |
| Multi-device Story content API | Explicitly deferred; large; not required to deepen same-device adaptive proof |
| Post-Story Reflect uptake UX | Improves optional Reflect rate; does not improve selection intelligence |
| D.1 / Growth Opportunities / Personalization Engine | Explicitly rejected by smallest-slice rule and prior plans |
| Pattern–Story affinity | Subset of B; larger design than A |

**No repository document currently authorizes** Personalization Engine, Phase 7, or social/marketplace as the immediate next dependency after Slice B.

---

## 8. Recommended Next Slice

### Name

**Slice C — Deterministic Catalog Phrase Alignment**  
(working title; authorization separate)

### Intent

Prove:

```text
Explicit Reflection with natural language
  (no literal catalog theme name required)
  ↓
CatalogAlignedNarrativeThemeResolver
  (deterministic name + description/alias phrase alignment)
  ↓
AdaptiveDiscoverySignals diversify beyond discovery-only
  ↓
Existing ranker / composer
  ↓
adaptive-story-{B} ≠ prior Story A
  ↓
Existing Slice A Story Experience path
```

### Why this is the next logical increment

1. **Smallest vertical change** — continue improving the same port Slice B already owns; no new aggregates, rankers, or experience types.
2. **Existing architecture** — catalog entities already expose `description`; dual-stack resolver mirrors already exist.
3. **Product value** — closes the realism gap that still prevents ordinary Reflections from driving differentiated Stories.
4. **Testable** — unit tests for phrase rules + one integration DoD test with natural language (no planted theme IDs).
5. **Boundary-preserving** — no AI, no Personalization Engine, no evidence-from-consume, no J.2 reopen.

### Why not B/C/D first

* **B** needs either new affinity semantics or assumes themes already vary realistically — A unlocks that variance first.
* **C** needs candidate infrastructure the Story path does not need.
* **D** does not change Story identity under uniform `patternBoost`.

### Explicitly out of scope for Slice C

* Embeddings / LLM theme classification
* ML ranking / Personalization Engine
* Changing composer/ranker contracts (unless a tiny dual-stack bug blocks DoD)
* Pattern–Story affinity
* Story Experience UI redesign
* Multi-device Story content API
* Growth Opportunities / D.1

---

## 9. Explicitly Deferred Work

Carry forward from Post–Slice A / Post–J.2 / HS plans:

* Growth Opportunity Detection / Narrative Guidance Engine
* Generalized Discovery Profile synthesis / D.1 productization
* Personalization Engine
* ML ranking / recommendation framework
* AI personalization / semantic AI theme inference
* Generalized adaptive-experience framework sprawl
* Candidate aggregate
* Multi-device Story content API / platform Story narrative read
* Platform-wide Story synchronization redesign
* Phase 7
* Contribution / social / community
* Marketplace / subscriptions
* Reopening J.2 eligibility/projection
* Pattern–Story affinity / non-uniform `patternBoost` redesign (Candidate B follow-on)
* Structured `explanationSources` UI beyond existing rationale string
* Flutter `NarrativeThemeAlignment` parity (unless Slice C DoD somehow emits non-catalog IDs — it must not)
* Stronger post-Story reflection prompt UX (uptake), separate from selection intelligence

---

## 10. Acceptance Criteria

Observable tests for the **recommended** next slice (when separately authorized):

### 10.1 Resolver unit tests

1. Given reflection text that **does not** contain a catalog theme **name** but **does** align with a catalog **description** (or approved alias phrase), emit the corresponding catalog `NarrativeThemeId`.
2. Given unrecognized text, still fall back to `discovery`.
3. Never emit non-catalog IDs.
4. Deterministic: identical input → identical output.
5. False-positive guard: substring/accidental matches must not invent themes (document and test chosen phrase rules).
6. Flutter and platform resolvers share the same rules.

### 10.2 Integration DoD test

1. Seed Story A and Story B with distinct catalog themes (as in Slice B).
2. Analyze a Reflection whose content **does not** include the literal theme name string used for Story B’s classification, but **does** deterministically resolve to Story B’s theme via phrase alignment.
3. `GetTodayExperienceUseCase` returns `adaptive-story-{B}` with `StoryExperienceTarget` for Story B after a prior Story A selection (or after reflection-only Today).
4. Assert Story **identity** change (`adaptive-story-*` / target storyId), not only internal theme membership.

### 10.3 Regression

* Slice B name-matching cases still pass.
* `differentiated_story_selection_pipeline_test.dart` still passes.
* Slice A continuity + consume ≠ evidence still pass.
* HS.8 / composer / ranker / UI.3 reflection Today suites still pass.
* No AI ports introduced; no Personalization Engine types; no J.2 schema changes.

### 10.4 Definition of Done (Slice C)

Not complete merely because matching “feels smarter.”

Complete when:

1. Natural-language Reflection content can diversify catalog themes without requiring literal theme names.
2. Today can select a different `adaptive-story-*` solely because of that diversified understanding.
3. Evidence boundary and Slice A experience path remain unchanged.
4. Architecture stays behind `NarrativeThemeResolver` with dual-stack parity.
5. Analyzer clean on touched files; focused + relevant suites green.

---

## 11. Final Readiness Verdict

1. **Is PR #70 complete?** **Yes** — architecturally and behaviorally for Differentiated Story Selection (Slice B).
2. **Architecture verdict?** **No material drift**; intentional content-aware mapping behind the existing theme port.
3. **Current adaptive-loop capability?** Explicit Reflection → H.2 themes → existing discovery/ranking/composer → different Story identity — **proven** when catalog names appear in reflection text.
4. **Remaining product gap?** Realistic Reflections rarely contain exact catalog names; name-only matching keeps most natural content on `discovery`.
5. **Recommended next slice?** **Deterministic Catalog Phrase Alignment** (Candidate A), bounded to the existing resolver.
6. **Why bounded?** Same port, catalog-owned phrases, existing selection path, clear tests; explicitly rejects Personalization/ML/AI/GO/D.1/J.2 reopen.
7. **Deferred?** See §9 — unchanged deferred set plus ranking affinity and multi-device content remain deferred.
8. **This document authorizes implementation?** **No.**

---

*Verification baseline: `main` @ `bcaf308` (PR #70). Planning only. No application code modified.*
