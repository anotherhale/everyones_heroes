# HS.8 — Adaptive Hero Discovery Implementation Report

**Phase:** HS.8 — Adaptive Hero Discovery  
**Document type:** Implementation report  
**Status:** COMPLETE  
**Date:** 2026-09-13  
**Branch:** `cursor/hs8-adaptive-hero-discovery-2b99`  
**Prerequisite:** HS.7 merged to `main` via PR #18 (`d1c4b99`)

---

## 1. Executive Summary

HS.8 adds deterministic, explainable adaptive Story relevance to Today’s Experience
through the existing UI.3 seam, operating strictly over HS.6 Discover* candidates
and routing Story begins through HS.7 experience/consume paths.

The proof loop works:

```text
Journey Behavior Patterns + Reflection NarrativeThemeIds
  → AdaptiveDiscoverySignals
  → DiscoverStories (HS.6)
  → Deterministic relevance + rationale
  → AdaptiveExperience(type: story)
  → HS.7 Story Detail / Consume
```

---

## 2. Implemented Scope

- `AdaptiveDiscoverySignals` + resolver (Reflection themes + Journey patterns)
- Discover*-backed candidate adapter + deterministic relevance ranker
- `AdaptiveExperienceComposer` integrating UI.3 reflection fallback
- Extended `GetTodayExperienceUseCase` orchestration
- Typed `StoryExperienceTarget` on `AdaptiveExperience`
- Presentation routing: Story → HS.7 `StoryDetailScreen` (no `BeginExperienceUseCase`)
- Focused HS.8 tests + ADRs HS-ADR-054…059
- Heroes tab left unchanged

---

## 3. Architectural Decisions

See §13 and `docs/architecture/architecture-decisions.md` (HS-ADR-054…059).

### Locked product questions

**Pattern gate vs themes-alone:**  
Themes are sufficient; patterns strengthen relevance. No hard pattern gate.

**Typed ExperienceTarget:**  
Introduced minimal `ExperienceTarget` / `StoryExperienceTarget` because
`AdaptiveExperience.id` alone was unsafe for Story routing. No speculative hierarchy.

**Heroes-tab adaptive relevance:**  
Not part of HS.8 MVP.

---

## 4. AdaptiveDiscoverySignals

Application model at:

`lib/features/life_journey/application/models/adaptive_discovery_signals.dart`

Resolved by `DefaultResolveAdaptiveDiscoverySignalsUseCase` from:

- `ReflectionRepository.findByJourneyId` → union of `narrativeThemes`
- `Journey.behaviorPatterns`

Not a domain aggregate. Free of Flutter/Riverpod/repository deps on the type itself.

---

## 5. Relevance Algorithm

`DeterministicStoryRelevanceRanker`:

1. Theme overlap count (primary)
2. Max behavior-pattern strength boost when overlap > 0 (0.0–1.0)
3. Tie-break: `updatedAt` desc, then `storyId` asc

Patterns alone never invent Story relevance. Empty themes → empty candidates →
UI.3 reflection fallback.

Participating pattern types: all present Journey patterns (strength used as boost).

---

## 6. UI.3 Integration

`GetTodayExperienceUseCase` remains the single presentation entry.

Flow:

```text
GetTodayExperienceUseCase
  → ResolveAdaptiveDiscoverySignalsUseCase
  → DiscoverableStoryCandidatePort (Discover* adapter)
  → AdaptiveExperienceComposer
       ├─ relevant story → ExperienceType.story + target + rationale
       └─ else DeterministicExperienceSelectionService (UI.3 reflection)
```

No `PersonalizationEngine`. Deterministic selector remains replaceable.
HS-ADR-052 deferral for Story selection into Today’s Experience is ended by
HS-ADR-054.

---

## 7. HS.6 Integration

`DiscoverStoriesCandidateAdapter` calls only `DiscoverStoriesUseCase` with
signal theme IDs. Private/unlisted remain non-discoverable.

---

## 8. HS.7 Integration

Story begin from Today’s Experience navigates to `StoryDetailScreen` and the
existing consume path. `BeginExperienceUseCase` is not used for Story.

---

## 9. Cold-Start Behavior

| Signals | Result |
|---------|--------|
| None | UI.3 default reflection |
| Patterns only | UI.3 reflection (consistency if present) |
| Themes only | Adaptive story when Discover* matches |
| Themes + patterns | Adaptive story with stronger boost/rationale |
| Themes, no matches | UI.3 reflection fallback |

---

## 10. Rationale

Grounded strings only:

- Themes: “This story connects with themes you've recently reflected on.”
- Themes + patterns: “…and patterns of {consistency|…} in your journey.”

No prescriptive coaching claims.

---

## 11. Test Coverage

Focused tests:

- `test/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case_test.dart`
- `test/features/life_journey/application/services/adaptive_experience_composer_test.dart`
- `test/features/life_journey/application/use_cases/hs8_get_today_experience_adaptive_test.dart`
- `test/features/hero_story/application/relevance/deterministic_story_relevance_ranker_test.dart`
- `test/features/hero_story/application/relevance/discover_stories_candidate_adapter_test.dart`
- `test/features/life_journey/presentation/models/today_experience_view_model_test.dart`
- `test/features/life_journey/presentation/screens/hs8_experience_screen_story_routing_test.dart`
- `test/integration/hs8_adaptive_hero_discovery_pipeline_test.dart`

---

## 12. Validation Results

### Focused HS.8 tests

```text
flutter test \
  test/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case_test.dart \
  test/features/life_journey/application/services/adaptive_experience_composer_test.dart \
  test/features/life_journey/application/use_cases/hs8_get_today_experience_adaptive_test.dart \
  test/features/hero_story/application/relevance/deterministic_story_relevance_ranker_test.dart \
  test/features/hero_story/application/relevance/discover_stories_candidate_adapter_test.dart \
  test/features/life_journey/presentation/models/today_experience_view_model_test.dart \
  test/features/life_journey/presentation/screens/hs8_experience_screen_story_routing_test.dart \
  test/integration/hs8_adaptive_hero_discovery_pipeline_test.dart
```

**Result: 33/33 passed**

### dart analyze

```text
dart analyze
```

**Result: no errors.** Remaining messages are pre-existing / style `info`
(`prefer_initializing_formals`); no new errors introduced.

### Full Flutter suite

```text
flutter test
```

**Result: 727/727 passed**

---

## 13. ADRs Added/Updated

- HS-ADR-054 Adaptive relevance via UI.3 (ends HS-ADR-052 deferral for story selection)
- HS-ADR-055 AdaptiveDiscoverySignals
- HS-ADR-056 Themes sufficient; patterns strengthen
- HS-ADR-057 Discover* fail-closed
- HS-ADR-058 Story begin via HS.7
- HS-ADR-059 Typed StoryExperienceTarget

---

## 14. Files Changed

### Application (Life Journey)

- `lib/features/life_journey/application/models/adaptive_discovery_signals.dart`
- `lib/features/life_journey/application/models/discoverable_story_candidate.dart`
- `lib/features/life_journey/application/models/experience_target.dart`
- `lib/features/life_journey/application/models/adaptive_experience.dart` (optional target)
- `lib/features/life_journey/application/ports/discoverable_story_candidate_port.dart`
- `lib/features/life_journey/application/services/adaptive_experience_composer.dart`
- `lib/features/life_journey/application/use_cases/resolve_adaptive_discovery_signals_use_case.dart`
- `lib/features/life_journey/application/use_cases/get_today_experience_use_case.dart`
- Providers for signals, candidate port, and Today’s Experience wiring

### Application (Hero & Story)

- `lib/features/hero_story/application/relevance/deterministic_story_relevance_ranker.dart`
- `lib/features/hero_story/application/relevance/discover_stories_candidate_adapter.dart`

### Presentation

- `today_experience_view_model.dart` (storyTargetId)
- `experience_screen.dart` (Story → HS.7 routing)

### Docs / Tests

- ADRs in `architecture-decisions.md`
- This report
- Focused HS.8 + integration tests listed in §11

---

## 15. Architecture Compliance

- Discover* only for seeker adaptive candidates
- No private/unlisted leakage
- UI.3 seam reused
- HS.7 path reused
- No PersonalizationEngine
- No AI/ML
- No presentation business logic (routing only)
- H.2 remains responsible for behavioral understanding
- Representation selection remains HS.7-authoritative

---

## 16. Deviations From Plan

- Serendipity (Slice 6) deferred
- Heroes-tab relevance (Slice 7) deferred per locked MVP decision
- Optional DiscoveryProfile theme source deferred

---

## 17. Remaining Technical Debt

- Known AGENTS.md hygiene items unchanged
- FakeNarrativeThemeResolver in production providers (fixtures seed explicit theme IDs)
- Architecture maps may still lag HS.8 types

---

## 18. Future Work

- Full Discovery Profile synthesis feeding AdaptiveDiscoverySignals
- Personalization Engine replacing composer/ranker implementations
- Optional Heroes-tab relevance
- Optional deterministic serendipity

---

## 19. Final Status

**COMPLETE**

HS.8 Definition of Done checklist satisfied for the minimum coherent MVP:

- [x] HS.7 merged and available
- [x] UI.3 adaptive-experience seam used
- [x] AdaptiveDiscoverySignals justified and present
- [x] Themes drive adaptive relevance
- [x] Patterns strengthen relevance when available
- [x] No hard pattern gate
- [x] Deterministic + explainable relevance
- [x] Discover* only; private/unlisted never surface
- [x] HS.7 Story Experience reused; BeginExperienceUseCase not used for Story
- [x] Today’s Experience can surface adaptive Story
- [x] Heroes tab unchanged
- [x] No PersonalizationEngine / AI/ML
- [x] Focused HS.8 tests pass
- [x] Full Flutter suite passes (727/727)
- [x] dart analyze: no new errors
- [x] ADRs recorded
- [x] Implementation documentation updated

---

*End of HS.8 Implementation Report*
