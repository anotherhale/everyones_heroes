# HS.7 — Hero Experience Implementation Report

**Phase:** HS.7 — Hero Experience  
**Status:** COMPLETE  
**Date:** 2026-09-13  
**Branch:** `cursor/hs7-hero-experience-31d3`  
**Predecessor:** HS.6 Hero & Story Discovery — COMPLETE  
**Plan:** `docs/architecture/HS.7-Hero-Experience-Plan.md`

---

## Implementation Summary

HS.7 implements the approved Hero Experience path over HS.6-discoverable
Heroes and Stories:

```text
HS.6 Discover*
      ↓
discoverability gate
      ↓
GetHeroExperience / GetStoryExperience (safe DTOs)
      ↓
Hero Profile → Hero's Stories → Story Experience → Consume
      ↓
optional explicit Reflect (H.2 CreateReflectionUseCase)
```

No new aggregates. No consumption domain events. No HS.8 personalization.
No social/collections. No HeroJourney aggregate. No UI.3 redesign.

---

## Vertical Slices

| Slice | Status | Notes |
|-------|--------|-------|
| Slice 1 — Story Experience | **Complete** | DiscoverStories → GetStoryExperience → narrative + authoritative playables → consume UI |
| Slice 2 — Hero Experience | **Complete** | DiscoverHeroes → GetHeroExperience → ListHeroStories (Discover*) → Story Experience |
| Slice 3 — Story Begin / Consume | **Complete** | `BeginStoryExperienceUseCase` / `ConsumeStoryExperienceUseCase` independent of reflection-producing `BeginExperienceUseCase` |
| Slice 4 — Optional Explicit Reflection | **Complete** | `StartStoryReflectionUseCase` → H.2 `CreateReflectionUseCase`; never automatic |

---

## Architecture

```text
Presentation (hero_story)
  HeroCatalogScreen / HeroProfileScreen
  StoryCatalogScreen / StoryDetailScreen / StoryConsumeScreen
        ↓ Riverpod providers (DTOs / view models only)
Application
  Discover* (HS.6 reuse)
  GetHeroExperience / GetStoryExperience
  ListHeroStories → DiscoverStories
  ResolvePlayableRepresentation (D3 selector)
  LoadStoryMedia → StoryMediaStoragePort
  BeginStoryExperience / ConsumeStoryExperience
  StartStoryReflection → CreateReflectionUseCase
        ↓
Domain (unchanged aggregates)
  Hero / Story / StoryRepresentation
  StoryDiscoverabilityPolicy / HeroDiscoverabilityPolicy
        ↑
Infrastructure
  In-memory repos, search adapters, media storage
```

App shell adds a dedicated **Heroes** tab. Life Journey **Discover** remains
unchanged.

---

## Files Changed

### Production

- `lib/app/presentation/app_shell.dart`
- `lib/features/hero_story/application/experience/playable_representation_selector.dart`
- `lib/features/hero_story/application/experience/story_experience_mapper.dart`
- `lib/features/hero_story/application/experience/hero_experience_mapper.dart`
- `lib/features/hero_story/application/dto/requests/get_story_experience_request.dart`
- `lib/features/hero_story/application/dto/requests/get_hero_experience_request.dart`
- `lib/features/hero_story/application/dto/requests/list_hero_stories_request.dart`
- `lib/features/hero_story/application/dto/requests/resolve_playable_representation_request.dart`
- `lib/features/hero_story/application/dto/requests/load_story_media_request.dart`
- `lib/features/hero_story/application/dto/requests/begin_story_experience_request.dart`
- `lib/features/hero_story/application/dto/requests/consume_story_experience_request.dart`
- `lib/features/hero_story/application/dto/requests/start_story_reflection_request.dart`
- `lib/features/hero_story/application/dto/responses/story_experience_detail.dart`
- `lib/features/hero_story/application/dto/responses/hero_experience_detail.dart`
- `lib/features/hero_story/application/dto/responses/playable_representation.dart`
- `lib/features/hero_story/application/dto/responses/story_consumption_session.dart`
- `lib/features/hero_story/application/dto/responses/story_media_bytes.dart`
- `lib/features/hero_story/application/use_cases/get_story_experience_use_case.dart`
- `lib/features/hero_story/application/use_cases/get_hero_experience_use_case.dart`
- `lib/features/hero_story/application/use_cases/list_hero_stories_use_case.dart`
- `lib/features/hero_story/application/use_cases/resolve_playable_representation_use_case.dart`
- `lib/features/hero_story/application/use_cases/load_story_media_use_case.dart`
- `lib/features/hero_story/application/use_cases/begin_story_experience_use_case.dart`
- `lib/features/hero_story/application/use_cases/consume_story_experience_use_case.dart`
- `lib/features/hero_story/application/use_cases/start_story_reflection_use_case.dart`
- `lib/features/hero_story/application/providers/media/story_media_storage_port_provider.dart`
- `lib/features/hero_story/application/providers/use_cases/experience_use_case_providers.dart`
- `lib/features/hero_story/presentation/models/hero_experience_view_model.dart`
- `lib/features/hero_story/presentation/models/story_experience_view_model.dart`
- `lib/features/hero_story/presentation/providers/hero_experience_providers.dart`
- `lib/features/hero_story/presentation/screens/hero_catalog_screen.dart`
- `lib/features/hero_story/presentation/screens/hero_profile_screen.dart`
- `lib/features/hero_story/presentation/screens/story_catalog_screen.dart`
- `lib/features/hero_story/presentation/screens/story_detail_screen.dart`
- `lib/features/hero_story/presentation/screens/story_consume_screen.dart`

### Tests

- `test/features/hero_story/application/use_cases/hs7_hero_experience_test.dart`
- `test/features/hero_story/presentation/hs7_hero_experience_ui_test.dart`
- `test/app/presentation/app_shell_test.dart` (Heroes tab)

### Documentation

- `docs/architecture/HS.7-Hero-Experience-Plan.md` (from approved plan branch)
- `docs/architecture/HS.7-Hero-Experience-Implementation-Report.md` (this file)
- `docs/architecture/architecture-decisions.md` (HS-ADR-048…053)

---

## Decisions (D1–D16)

| Decision | Implemented |
|----------|-------------|
| D1 Story Experience DTOs | Yes — `StoryExperienceDetail` |
| D2 Narrative exposure from authoritative/approved path | Yes — narrative on discoverable Stories; playables authoritative only |
| D3 Deterministic language/format selection | Yes — `PlayableRepresentationSelector` |
| D4 Discoverability; no unlisted known-id bypass | Yes — Get*Experience fails closed |
| D5 Reuse HS.6 Discover* | Yes — lists + ListHeroStories |
| D6 Hero Experience UI | Yes — Heroes tab + profile + stories |
| D7 Hero Journey deferred | Yes — stories list only |
| D8 Playback via media port; no persistence | Yes |
| D9 Consumption ≠ Behavioral Evidence | Yes — tested |
| D10 UI.3 optional | Deferred — not required |
| D11 Reflection optional + explicit | Yes — StartStoryReflection |
| D12 Collections deferred | Yes |
| D13 Social out of scope | Yes |
| D14 HS.8 out of scope | Yes |
| D15 No new aggregates | Yes |
| D16 No consumption domain events | Yes |

---

## Discoverability

Seeker paths reuse:

- `DiscoverStoriesUseCase`
- `DiscoverHeroesUseCase`
- `BrowseStoriesByCatalogUseCase` (available via existing providers)
- `StoryDiscoverabilityPolicy` / `HeroDiscoverabilityPolicy`

Known-id experience (`GetStoryExperience` / `GetHeroExperience`) re-checks the
same policies and fails closed for private/unlisted/unpublished content.
`ListHeroStoriesUseCase` delegates exclusively to `DiscoverStories(heroId:)`.

---

## Representation Selection

**Language priority (D3):**

1. Explicitly requested/preferred language (when supplied)
2. Canonical Story `originalLanguage`
3. Otherwise highest-priority authoritative representation

**Format priority (deterministic):**

`audio` → `video` → `written` → `script` → `shortForm` → `longForm` → `transcript`

Ties broken by representation id ascending. No personalization, embeddings, or
device-locale inference.

---

## Consumption Boundary

```text
Story Consumption
       X
       ↓
Behavioral Evidence
```

`BeginStoryExperience` / `ConsumeStoryExperience` / `LoadStoryMedia` do not
raise domain events, create Reflections, create BehavioralEvidence, update
BehaviorPatterns, or alter Mission / Life Journey progress.

---

## Begin Path

Life Journey `BeginExperienceUseCase` always creates a Reflection today.
HS.7 therefore uses a separate Story begin path:

- `BeginStoryExperienceUseCase` — establishes ephemeral `StoryConsumptionSession`
- does **not** call `BeginExperienceUseCase`
- does **not** create Reflection automatically

---

## UI.3

**Intentionally deferred.** Primary entry is Hero Experience UI. Today’s
Experience selection was not modified. `ExperienceType.story` enum remains
untouched for a future optional seam.

---

## Today’s Experience

Deterministic Story selection for Today’s Experience was **not** added.

---

## Deferred Work

- HS.8 personalized / semantic / embedding discovery
- Collections (saves, bookmarks, likes, follows)
- Social features (comments, followers, feeds)
- Hero Journey aggregate / structured acts
- Playback persistence / production streaming
- UI.3 Story integration / Today’s Experience story candidates
- Reflection `sourceStoryId` foreign key on Reflection aggregate

---

## Tests

### Focused HS.7

Command:

```bash
flutter test \
  test/features/hero_story/application/use_cases/hs7_hero_experience_test.dart \
  test/features/hero_story/presentation/hs7_hero_experience_ui_test.dart \
  test/app/presentation/app_shell_test.dart
```

**Result: 28/28 passed**

Coverage includes discoverability, authoritative representations, language/format
priority, DTO safety, Hero stories via Discover*, begin/consume without
Reflection/evidence, explicit reflection bridge, and Heroes navigation.

### Full suite

```bash
flutter test
```

**Result: 696/696 passed**

### Pre-existing failures

None observed in the full suite.

---

## Analyzer

```bash
dart analyze
```

**Result:** No errors. Remaining issues are pre-existing warnings/infos outside
HS.7 scope (e.g. `browse_stories_by_catalog_use_case.dart` unawaited return,
`story_understanding` prefer_initializing_formals).

HS.7 production and test code introduced **no analyzer errors**.

---

## Architectural Deviations

**None**

---

## ADRs Accepted

- HS-ADR-048 — HS.7 Is Experience Over Discoverable Catalog, Not Personalization
- HS-ADR-049 — Experience Detail DTOs Are Discoverability-Gated Read Models
- HS-ADR-050 — Playback Is Representation Consumption via Media Port, Not a Playback Aggregate
- HS-ADR-051 — Story Interaction Remains Non-Evidence; Reflection Is Optional Bridge
- HS-ADR-052 — UI.3 Story Integration Is Optional and Deferred for HS.7 MVP
- HS-ADR-053 — Hero Journey Structure and Collections Deferred

---

*End of HS.7 — Hero Experience Implementation Report.*
