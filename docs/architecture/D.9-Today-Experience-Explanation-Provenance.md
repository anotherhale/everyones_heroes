# D.9 — Today Experience Explanation Provenance

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter-local Today Experience rationale)
- **Phase:** D.9 Today Experience Explanation Provenance
- **Baseline:** D.7 Inspiration-Grounded Story Exploration; D.8 assessment
  (explanation provenance required; ranking provenance not)
- **Date:** 2026-09-26

---

## 0. Objective delivered

Make Today's Experience rationale truthful about **which understanding sources
matched the selected Story's narrative themes**, without changing ranking.

D.7 established Inspiration-honest Discover copy (“Connected through {Theme}”).
D.9 brings equivalent honesty to Today:

```text
DiscoveryProfile-only match  ≠  “recently reflected on”
```

---

## 1. Runtime flow

```text
Reflection themes ─────────────┐
                               │
DiscoveryProfile themes ───────┼──→ AdaptiveDiscoverySignals
                               │         (union for ranking
Journey patterns ──────────────┘          + inspirationThemeIds
                                          + themeLastExpressedAt)
                                         ↓
                              Discover* eligibility
                                         ↓
                              DeterministicStoryRelevanceRanker
                                         ↓
                              selected DiscoverableStoryCandidate
                                         ↓
                              NarrativeThemeMatchProvenance
                              (matchedThemeIds ∩ inspiration
                               vs matchedThemeIds ∩ reflection)
                                         ↓
                              AdaptiveExperienceComposer.buildRationale
                                         ↓
                              AdaptiveExperience.rationale (string)
```

Ranking continues to use only `narrativeThemeIds`, `themeLastExpressedAt`, and
`behaviorPatterns`. Provenance is explanation metadata only.

---

## 2. Provenance model

Application-level enum `NarrativeThemeMatchSource`:

| Value | Meaning |
|-------|---------|
| `inspiration` | matched ∩ Inspiration ≠ ∅ and matched ∩ Reflection = ∅ |
| `reflection` | matched ∩ Reflection ≠ ∅ and matched ∩ Inspiration = ∅ |
| `mixed` | both intersections non-empty |
| `unknown` | neither intersection non-empty |

Inputs:

* `candidate.matchedThemeIds` (existing ranking fact)
* `signals.inspirationThemeIds` (DiscoveryProfile themes; ranking-ignored)
* `signals.themeLastExpressedAt` keys (Reflection themes)

Not a domain aggregate. Not persistent. Not part of DiscoveryProfile,
Reflection, or Journey.

---

## 3. Rationale matrix

| Inspiration match | Reflection match | Pattern | Expected theme clause |
|-------------------|------------------|---------|------------------------|
| no | no | no | themes relevant to your journey |
| yes | no | no | themes from your inspirations |
| no | yes | no | themes you've recently reflected on |
| yes | yes | no | themes from your inspirations and reflections |
| yes | no | yes | themes from your inspirations + patterns of … |
| no | yes | yes | themes you've recently reflected on + patterns of … |
| yes | yes | yes | themes from your inspirations and reflections + patterns of … |

Journey behavior patterns remain a **separate** relevance/explanation dimension.

---

## 4. What D.9 deliberately did not change

* Candidate eligibility
* Theme overlap calculation
* Ranking order / Reflection recency tie-break / pattern boost / deterministic ties
* `AdaptiveDiscoverySignals` ranking fields (only added `inspirationThemeIds`
  for explanation)
* D.7 `ExploreStoriesByInspirationUseCase` / Inspiration exploration models
* Platform DiscoveryProfile authority / platform Today provenance API
* PersonalizationEngine, weighting, confidence, DiscoveryHistory, Hero↔Discovery

---

## 5. Deferred (candidates for D.10 assessment)

1. Platform Today Experience provenance parity (platform composer still collapses
   theme sources in rationale wording).
2. Whether Discover and Today should share a richer structured explanation model
   beyond strings (not required for D.9).
3. Influence-level attribution in Today explanations (explicitly out of D.9).
4. Hero ↔ Discovery relationship ADR (still deferred from D.7).
5. Whether ranking ever needs source-aware scoring (D.8 said not yet).

D.10 should **assess** these; it should not automatically implement them.
