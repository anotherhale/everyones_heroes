# HS.8 — Adaptive Hero Discovery Planning Report

**Phase:** HS.8 — Adaptive Hero Discovery  
**Document type:** Planning investigation report  
**Status:** COMPLETE (planning only)  
**Date:** 2026-09-13  
**Branch:** `cursor/hs8-adaptive-hero-discovery-plan-ae3f`  
**Authoritative plan:** `docs/architecture/HS.8-Adaptive-Hero-Discovery-Implementation-Plan.md`

---

## 1. Mission

Produce an implementation-ready architectural plan for HS.8 — Adaptive Hero Discovery — grounded in the current repository and completed HS.1–HS.7 / UI.3 / H.2 architecture.

**No production implementation was performed.**

---

## 2. Repository Investigation

### 2.1 Base state

- Working tree inspected on `main` @ docs including HS.6 complete and HS.7 plan/lock merged (`#17`).
- HS.7 **implementation** inspected on `origin/cursor/hs7-hero-experience-31d3` (complete; ADRs 048–053; 696 tests claimed in report).
- Confirmed: `main` lacks `hero_story/presentation/` and HS.7 experience use cases.

### 2.2 Code areas inspected

| Area | Findings |
|------|----------|
| UI.3 | `ExperienceSelectionService`, `DeterministicExperienceSelectionService` (consistency → reflection only), `GetTodayExperienceUseCase`, `AdaptiveExperience`, `BeginExperienceUseCase` (always Reflection), Riverpod providers, Home/Experience screens |
| HS.6 | `DiscoverStoriesUseCase`, `DiscoverHeroesUseCase`, policies, Search* vs Discover*, no DiscoveryProfile loading |
| HS.7 (branch) | Get/Begin/Consume Story Experience, Get Hero Experience, ListHeroStories→Discover*, playable selector, Heroes tab UI |
| Discovery BC | `DiscoveryProfile` aggregate exists; no DI providers; no `findByUserId`; incomplete event TODOs; not usable as synthesized personalization input |
| H.2 | Journey owns `behaviorPatterns`; Reflection has `narrativeThemes`; `ReflectionRepository.findByJourneyId` exists |

---

## 3. Documents Inspected

Required anchors reviewed:

- Hero & Story Platform Foundation (incl. §72 HS.8)
- UI.3 Adaptive Experience Foundation
- Architecture Decisions (main through HS-ADR-047; HS.7 branch 048–053)
- Architecture Drift
- Bounded Contexts, Aggregate Map, Event Flow, Repository Map, Use Case Map
- Codebase Analysis, Technical Debt, Testing Strategy, Domain Glossary
- Adaptive Discovery & Evidence Engine
- Phase H.2 / H.2 Updated architecture
- HS.5 plans/reports; HS.6 plan/report; HS.7 plan, decision lock, implementation report (branch)
- AGENTS.md / CLAUDE.md

---

## 4. Architecture Findings

### 4.1 What HS.8 must add

HS.6 answers findability. HS.7 answers experienceability. UI.3 answers adaptive experience selection but only for reflections from pattern presence. **HS.8 adds relevance:** which discoverable Hero/Story matches current understanding, with grounded rationale, fed through the UI.3 seam.

### 4.2 Discovery Profile

**Option B recommended:** `AdaptiveDiscoverySignals` application context.  
Full synthesis (Option A) rejected. Existing profile is not production-consumable (Option C false). Seam for future profile feed retained.

Primary MVP signals available today without new domain invention:

1. `Journey.behaviorPatterns`
2. Union of `Reflection.narrativeThemes` via `findByJourneyId`
3. Optional later: `DiscoveryProfile.narrativeThemeIds`

### 4.3 Personalization Engine

Do **not** introduce `PersonalizationEngine` in HS.8.  
Extend UI.3 `ExperienceSelectionService` / `GetTodayExperienceUseCase` composition.  
Future engine replaces the implementation behind the same seam.

### 4.4 HS.6 / privacy

Adaptive paths must use Discover* only. Private/unlisted remain non-discoverable even for personalized/known-id flows (align with HS.7 fail-closed).

### 4.5 HS.7

Reuse experience/consume APIs; do not duplicate. HS-ADR-052 deferred UI.3 story wiring — **HS.8 is the phase to wire it**. Merge HS.7 before implementation.

### 4.6 Events

No justified domain events for “AdaptiveHeroSelected” / “HeroDiscovered” in MVP. Selection is application read-time. Consumption remains non-evidence (HS-ADR-051).

---

## 5. Decisions (Planning)

| ID | Decision |
|----|----------|
| D1 | HS.8 = adaptive relevance over discoverable catalog via UI.3, not full Personalization Engine |
| D2 | Discovery Profile strategy = Option B (`AdaptiveDiscoverySignals`) |
| D3 | Primary thematic signal = Reflection NarrativeThemeIds (+ Journey patterns) |
| D4 | Candidate generation = Discover* + deterministic overlap ranking |
| D5 | Story begin = HS.7 paths; never `BeginExperienceUseCase` |
| D6 | Rationale = grounded strings (structured rationale optional later) |
| D7 | Serendipity = optional late deterministic slice only |
| D8 | No new aggregates; application ports/services/DTOs only |
| D9 | Proposed ADRs start at HS-ADR-054 after HS.7’s 053 |
| D10 | Implementation blocked on HS.7 merge |

---

## 6. Proposed Slices (summary)

0. Prerequisite — merge HS.7  
1. AdaptiveDiscoverySignals  
2. Discover*-backed relevance + privacy tests  
3. UI.3 composition (`ExperienceType.story` + target + rationale)  
4. Presentation routing to HS.7 consume  
5. Integration proof (understanding → changed story)  
6. Optional serendipity  
7. Optional Heroes-tab relevance  

---

## 7. Risks

- Empty theme/catalog fixtures → no adaptive stories  
- Theme ID mismatch across reflections and classifications  
- Async selection migration vs existing UI.3 tests  
- Accidental Search* / privacy leakage  
- Scope creep into Personalization Engine  
- Implementing on `main` without HS.7  

---

## 8. Open Questions

1. Pattern gate required for story selection, or themes alone? *(Rec: themes alone)*  
2. Typed `ExperienceTarget` vs string-encoded id? *(Rec: typed target)*  
3. Load DiscoveryProfile in MVP demos? *(Rec: defer)*  
4. Heroes-tab relevance in MVP? *(Rec: optional)*  
5. Product confirmation to end HS-ADR-052 deferral in HS.8  

---

## 9. Recommendation

Approve the plan in:

`docs/architecture/HS.8-Adaptive-Hero-Discovery-Implementation-Plan.md`

Implement the **minimum valuable HS.8**: deterministic, explainable Story relevance into Today’s Experience through UI.3, over HS.6 Discover*, consuming HS.7 experience APIs — after HS.7 is merged.

Defer full Discovery Profile synthesis, Personalization Engine, AI/ML ranking, and serendipity-as-product until later phases.

---

## 10. Confirmation — No Implementation

Verified for this planning task:

- [x] No production Dart files modified  
- [x] No tests modified  
- [x] No pubspec dependency changes  
- [x] No migrations  
- [x] No UI feature implementation  
- [x] No recommendation engine implementation  
- [x] No Discovery Profile synthesis implementation  
- [x] No AI / networking / persistence added  
- [x] Only documentation deliverables created under `docs/architecture/`  

Deliverables:

1. `docs/architecture/HS.8-Adaptive-Hero-Discovery-Implementation-Plan.md`  
2. `docs/architecture/HS.8-Adaptive-Hero-Discovery-Planning-Report.md`  

---

*End of HS.8 Planning Report*
