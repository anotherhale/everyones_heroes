# Deterministic Theme-Recency Story Ranking — Implementation Report

- **Document type:** Focused implementation note (Slice D)
- **Status:** Complete
- **Predecessor:** `Post-Slice-C-Verification-and-Next-Slice-Plan.md` (PR #73)
- **Baseline:** `main` after PR #73

---

## 1. What Theme-Recency Ranking Means

After Slice C, Reflections can diversify Narrative Themes through catalog phrase
alignment. Candidate Stories with equal theme overlap were still ordered by
Story `updatedAt` / `storyId`, so historical theme **union** plus Story
publish-time ties could defeat the person’s most recently expressed theme.

**Theme-Recency Ranking** extends the existing
`DeterministicStoryRelevanceRanker` so a Story aligned with a more recently
expressed Reflection theme ranks above a Story that only matches older union
themes — even when the older-theme Story has a newer `updatedAt`.

This is not a Personalization Engine, ML ranker, or new selection path.

---

## 2. How Recent Theme Information Enters Ranking

```text
Reflection.submittedAt (else createdAt)
  + Reflection.narrativeThemes
        ↓
ResolveAdaptiveDiscoverySignals /
CatalogAlignedAdaptiveDiscoverySignalResolver
        ↓
AdaptiveDiscoverySignals
  ├── narrativeThemeIds          (historical union, sorted)
  ├── themeLastExpressedAt       (theme value → latest expression time)
  └── behaviorPatterns
        ↓
DeterministicStoryRelevanceRanker
```

`themeLastExpressedAt` is an explicit map on the existing signals DTO. Recency
is not inferred from list iteration order or candidate seed order.

Platform alignment: non-catalog theme IDs are dropped; legacy
`self-discovery` maps to `discovery` before recency timestamps are recorded.

---

## 3. Ranking Precedence

```text
1. themeOverlapCount DESC
2. max matched themeLastExpressedAt DESC   ← new
3. patternBoost DESC (uniform; non-differentiating today)
4. Story updatedAt DESC
5. storyId ASC
```

Invariant: a Story matching the most recently expressed theme must not lose
solely because another candidate has a newer Story `updatedAt`.

When `themeLastExpressedAt` is empty, step 2 is a no-op (all candidates share
epoch) and existing deterministic ordering is preserved.

---

## 4. Deterministic Tie Behavior

Identical overlap + identical recent-theme timestamps + identical pattern boost
+ identical Story `updatedAt` still resolve by `storyId` ascending — the
existing HS.6 / HS.8 final tie-break. No new arbitrary tie-breaker was added.

---

## 5. Why Story updatedAt No Longer Defeats Recent-Theme Match

Previously, equal overlap collapsed to Story timestamp. Now recent-theme
alignment is evaluated **before** Story `updatedAt`. Adverse fixtures where the
stale-theme Story is newer still select the recent-theme Story.

Historical themes remain in `narrativeThemeIds` (AC: accumulated understanding
is preserved). Recency only reorders among overlapping candidates.

---

## 6. Intentionally Deferred

- Pattern–Story affinity / non-uniform behavioral boost
- Semantic / AI theme interpretation
- Personalization Engine / recommendation framework
- Multi-type experience chooser (Mission / Coaching / …)
- Structured explanation UI citing recency provenance
- J.2 schema changes / Candidate aggregate

---

## 7. Dual-Stack Parity

| Concern | Flutter | Platform |
|---------|---------|----------|
| Signals DTO | `adaptive_discovery_signals.dart` | same path under `eh_platform` |
| Resolver | `DefaultResolveAdaptiveDiscoverySignalsUseCase` | `CatalogAlignedAdaptiveDiscoverySignalResolver` |
| Ranker | `DeterministicStoryRelevanceRanker` | platform twin |

Semantics agree on representation, scoring order, ties, and empty-recency
fallback.

---

## 8. Related ADR

See **HS-ADR-071** in `architecture-decisions.md`.
