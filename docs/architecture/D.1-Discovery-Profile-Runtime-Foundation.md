# D.1 — Discovery Profile Runtime Foundation

- **Document type:** Implementation Report + Architectural Decisions
- **Status:** Implemented (Flutter local adaptive path)
- **Phase:** D.1 Runtime Foundation (vertical slice)
- **Baseline:** `main` @ HP.1/HP.2 (`6d290e3` / PR #86); branch cut from later `main`
- **Related:** `D.1-Discovery-Profile-Platform-Plan.md` (broader platform persistence — still deferred), HS.8 adaptive path, J.2 catalog-aligned signals
- **Date:** 2026-09-26

---

## 0. Objective delivered

Connect the existing DiscoveryProfile to the existing adaptive experience path:

```text
DiscoveryProfile.narrativeThemeIds
  ∪ Reflection.narrativeThemes
  ∪ Journey.behaviorPatterns
        ↓
AdaptiveDiscoverySignals
        ↓
DiscoverStoriesUseCase / DeterministicStoryRelevanceRanker
        ↓
Today's Experience
```

No Discovery redesign. No Hero social graph. No GrowthOpportunity. No PersonalizationEngine. No AI. No Discover screen redesign.

---

## 1. Runtime path

```text
LocalUserIdentity.current (EH_PLATFORM_USER_ID / default `dev-user`)
        ↓
DiscoveryProfileRepository.findByUserId
        ↓
RepositoryDiscoveryProfileThemeSource
        ↓
DefaultResolveAdaptiveDiscoverySignalsUseCase
        ↓
DefaultGetTodayExperienceUseCase (local / offline authority)
```

Platform authority (`EH_PLATFORM_URL`) continues to use `PlatformGetTodayExperienceUseCase` → platform Experience API. This slice does **not** add platform DiscoveryProfile persistence; that remains the separate platform D.1 plan.

---

## 2. AD-D1-001 — Temporary local user identity

**Decision:** Use `LocalUserIdentity` / `currentLocalUserIdProvider`, reading the existing `EH_PLATFORM_USER_ID` dart-define (default `dev-user`).

**Why:** DiscoveryProfile is keyed by `UserId`. Flutter has no Identity aggregate. The platform client already uses the same define as an auth-token fallback. Aligning local Discovery with that value is the smallest coherent mechanism.

**Not:** authentication, multi-user accounts, or Identity BC binding.

**Future:** Replace with Identity BC principal when available.

---

## 3. AD-D1-002 — Persistence deferred (intentional)

**Decision:** Keep DiscoveryProfile on the shared in-memory Riverpod repository for the Flutter local/offline session. Do **not** invent a new file/Postgres store in this slice.

**Why:**

- Local Journey and Reflection repositories are also in-memory for the transitional offline path.
- Durable DiscoveryProfile + Identity authority is specified in `D.1-Discovery-Profile-Platform-Plan.md` and must not be half-implemented as a parallel local file format.
- Process-lifetime wiring via providers attaches DiscoveryProfile to the application lifecycle (ensure-on-demand + shared repo), so the profile is no longer silently disconnected from adaptive composition.

**Lifecycle attachment:**

- `ensureCurrentDiscoveryProfileUseCaseProvider` / `currentDiscoveryProfileProvider` create an empty profile for the current user when missing.
- Influences → themes still use existing `AddInfluenceUseCase` + `ResolveNarrativeThemesUseCase`.

---

## 4. AD-D1-003 — Cross-context theme port

**Decision:** Life Journey consumes Discovery themes through `DiscoveryProfileThemeSource` (application port). Discovery implements `RepositoryDiscoveryProfileThemeSource`.

**Why:** Preserve bounded-context separation. Experience selection must not import Discovery aggregates; Discovery must not own Experience selection.

---

## 5. Signal composition rules

Deterministic sorted union:

```text
adaptiveThemes =
    reflectionThemes
    ∪ discoveryProfileThemes
```

Patterns remain Journey-owned (`behaviorPatterns`).

`themeLastExpressedAt` continues to track Reflection submission times only. DiscoveryProfile-only themes appear in `narrativeThemeIds` without a recency entry (ranker treats missing recency as oldest).

---

## 6. Files introduced / changed (summary)

| Area | Change |
|------|--------|
| `DiscoveryProfileRepository` | `findByUserId` |
| `LocalUserIdentity` | Temporary current-user id |
| `DiscoveryProfileThemeSource` | Life Journey port |
| `RepositoryDiscoveryProfileThemeSource` | Discovery adapter |
| `EnsureCurrentDiscoveryProfileUseCase` | Session attach |
| Discovery Riverpod providers | Repos, use cases, theme source |
| `DefaultResolveAdaptiveDiscoverySignalsUseCase` | Union Discovery themes |
| Tests | Repository, ensure, theme source, signals, Today Experience |

---

## 7. Explicit non-goals (still deferred)

- Platform DiscoveryProfile Postgres / public Discovery API
- Durable Flutter file repository for DiscoveryProfile
- Auto-merge Reflection themes into DiscoveryProfile
- Influence UI / Discover screen redesign
- Copying BehaviorPatterns onto DiscoveryProfile

---

## 8. Validation

Focused tests covering:

- `findByUserId`
- Ensure current profile
- Theme source
- Signal union (Reflection ∪ DiscoveryProfile)
- Today Experience story selection from DiscoveryProfile themes alone
