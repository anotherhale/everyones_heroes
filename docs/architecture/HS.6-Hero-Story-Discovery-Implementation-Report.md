# HS.6 — Hero & Story Discovery Implementation Report

**Phase:** HS.6 — Hero & Story Discovery  
**Date:** 2026-09-12  
**Plan:** `docs/architecture/HS.6-Hero-Story-Discovery-Implementation-Plan.md`  
**HS.6 status: Complete**

---

## 1. Status

All acceptance criteria from the authoritative HS.6 plan and the implementation task brief are met:

- Locked decisions D1–D4 and D7 implemented exactly
- Soft gates D5/D6/D8/D9/D10 followed plan recommendations (no material deviations)
- Focused HS.6 tests pass
- Full Flutter suite passes
- `dart analyze` clean on HS.6 code
- HS-ADR-041…047 accepted
- No HS.7 UI, no HS.8 personalization, no production search, no discovery aggregate, no second Story store

---

## 2. What Was Implemented

### Domain

- `StoryDiscoverabilityPolicy` — published + visibility ∈ `{public, community}` + non-provisional narrative
- `HeroDiscoverabilityPolicy` — active + visibility ∈ `{public, community}`
- `DiscoveryMatchReason` — lightweight non-personalized match reason codes (D8)
- `CatalogBrowseDimension` — browse dimension enum
- Extended `StorySearchQuery` with `visibilities` and `authoritativeRepresentationsOnly`
- Extended `HeroSearchQuery` with `visibilities`

### Infrastructure

- `InMemoryStorySearchAdapter` honors visibility + authoritative representation filtering for format / availableLanguage / duration
- `InMemoryHeroSearchAdapter` honors visibility filtering
- Deterministic, in-memory only (D4)

### Application

- `DiscoverStoriesUseCase` — discovery defaults + search + hero eligibility + summary hydration + sort + pagination
- `DiscoverHeroesUseCase` — parallel Hero path
- `BrowseStoriesByCatalogUseCase` — browse by one primary catalog dimension via Discover\*
- `GetStoryDiscoverySummaryUseCase` — known-id summary only if discoverable (blocks unlisted leakage)
- Summary DTOs: `StoryDiscoverySummary`, `HeroDiscoverySummary`, response wrappers
- Request DTOs for Discover/Browse/GetSummary
- Mappers for projection + deterministic ordering + match reasons
- Riverpod providers for search ports and Discover/Browse/Search use cases

### ADRs

- HS-ADR-041…047 appended to `docs/architecture/architecture-decisions.md`

### Tests

- `test/features/hero_story/application/use_cases/hs6_hero_story_discovery_test.dart`
- `test/features/hero_story/domain/services/hs6_discoverability_policy_test.dart`
- Extended `search_adapters_test.dart` for visibility + authoritative flags

---

## 3. Architecture

```text
Discover*/Browse* use cases
        ↓
Story/HeroDiscoverabilityPolicy (pure eligibility)
        ↓
StorySearchPort / HeroSearchPort  (catalog filter substrate)
        ↓
InMemory*SearchAdapter (deterministic MVP)
        ↓
Repository hydrate → Summary DTOs → sort → paginate
```

| Concern | Implementation |
|---------|----------------|
| Search ports | Reused and extended; not replaced |
| Discover/Browse | Application orchestration with seeker defaults |
| DTOs | Derived read models; not canonical |
| Adapters | In-memory only; replaceable later |
| Eligibility | Policy + query fields + post-hydration checks (incl. hero eligibility for stories) |
| Representation rules | `authoritativeRepresentationsOnly: true` on Discover\* |

Discovery queries do **not** mutate aggregates and do **not** publish domain events.

---

## 4. D1–D4 and D7 Compliance

| Decision | Implementation |
|----------|----------------|
| **D1** Reuse search ports; add Discover/Browse | Kept `SearchStoriesUseCase` / `SearchHeroesUseCase`. Added Discover/Browse/GetSummary use cases composing ports + repos. No parallel generic search port. |
| **D2** Visibility = `{public, community}` | Policies + Discover query `visibilities` + post-filter. Private/unlisted excluded from Discover, Browse, and GetSummary. |
| **D3** Authoritative representations only | Discover\* sets `authoritativeRepresentationsOnly: true`. Unapproved AI scripts/translations cannot satisfy format/language/duration filters. Summaries expose only authoritative representation descriptors (no text bodies). |
| **D4** Deterministic in-memory MVP | Only in-memory adapters. No Elastic/OpenSearch/Algolia/vectors/embeddings/LLMs. |
| **D7** UI-agnostic | No Flutter screens, cards, navigation, or UI state. Providers only. |

---

## 5. Soft Gate Decisions

| Gate | Recommendation used | Deviation |
|------|---------------------|-----------|
| **D5** Theme IDs as plain filters | `narrativeThemeIds` accepted on Discover\* without loading DiscoveryProfile | None |
| **D6** Pagination | `limit`/`offset` (default 20, max 100) + `totalCount`/`nextOffset` | None |
| **D8** Match reasons | Optional `DiscoveryMatchReason` codes on summaries | None (lightweight codes only) |
| **D9** Narrative in summaries | Title + catalog metadata only; no narrative body | None |
| **D10** Sort field | Stories: `updatedAt` desc + `storyId` asc; Heroes: `createdAt` desc + `heroId` asc | None |

---

## 6. Privacy / Visibility

Enforced at the application discovery boundary (not UI):

1. Discover\* always queries with `publishedOnly: true` and discoverable visibilities.
2. Adapters filter by visibility when requested.
3. Use cases re-check `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy` after hydration.
4. Stories whose Hero is missing or non-discoverable are excluded (prevents private-hero leakage).
5. `GetStoryDiscoverySummaryUseCase` fails closed for unlisted/private/unpublished.

---

## 7. Representation Authority

- Authoritative = `!isAiGenerated || isApproved` (existing domain getter).
- Discover\* format / availableLanguage / duration filters use authoritative reps only.
- Summary `availableLanguages` and representation descriptors derive from original language + authoritative reps only.
- Unapproved AI text never appears in discovery DTOs.

---

## 8. Tests

| Suite | Result |
|-------|--------|
| Focused HS.6 (`hs6_hero_story_discovery_test` + `hs6_discoverability_policy_test`) | **25/25 passed** |
| Focused HS.6 + search adapter suite (incl. visibility/authoritative extensions) | **39/39 passed** |
| Full `flutter test` | **672/672 passed** |
| `dart analyze` on HS.6 code | **No issues found** |
| `dart analyze lib/features/hero_story` | No errors/warnings; pre-existing `prefer_initializing_formals` infos only (HS.4/HS.5 files, untouched) |

Coverage includes: public/community discoverable; private/unlisted excluded; private-hero story exclusion; unapproved vs approved representation filters; translation language gating; browse eligibility; deterministic ordering/tie-break; pagination; empty catalog; no mutation/events; Riverpod provider wiring.

---

## 9. Deferred

Intentionally left for later milestones:

- Production search engine adapter (Elastic/meilisearch/etc.)
- HS.8 personalization / adaptive ranking / semantic similarity
- HS.7 Hero Experience UI (profiles, playback, catalog screens)
- Persistent discovery projections / indexing from events
- Personalized “Why this story?” explanations
- Narrative body / excerpt in discovery summaries
- TTS / narration; representation → narrative promotion; representation reject lifecycle (HS.5 deferrals)

---

## 10. Architecture Concerns

No material blocking concerns for HS.6.

Reported (pre-existing / out of scope):

- Documentation drift in architecture maps / `AGENTS.md` still framing HS.1 as next (classification C — left alone).
- Known H.2 naming hygiene items remain deferred (AGENTS.md §29).

---

## 11. Files Changed (meaningful)

**Domain:** discoverability policies; search query extensions; browse/match enums; `domain.dart` exports  

**Application:** Discover/Browse/GetSummary use cases; discovery DTOs/mappers; Riverpod search + discovery providers  

**Infrastructure:** in-memory search adapter updates  

**Docs:** HS-ADR-041…047; this report  

**Tests:** HS.6 focused suites; search adapter extensions  

---

## 12. Git / PR Information

| Item | Value |
|------|-------|
| Branch | `cursor/hs6-hero-story-discovery-fd6a` |
| Commit | `16054f9de2cd629da7ac12d0bedba3a778fd82b9` |
| Implementation status | **Complete** |
| Validation status | Analyzer clean (HS.6); focused 25/25; full 672/672 |
| Report path | `docs/architecture/HS.6-Hero-Story-Discovery-Implementation-Report.md` |
| PR | https://github.com/anotherhale/everyones_heroes/pull/15 |

---

*End of HS.6 — Hero & Story Discovery Implementation Report.*
