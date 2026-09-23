# D.1 — Discovery Profile Platform Foundation

- **Document type:** Architecture + Implementation Plan (planning only)
- **Status:** Proposed — awaiting implementation authorization
- **Phase:** D.1 / PF.2 Phase 6 — Discovery product wiring on EH Platform
- **Baseline (code):** `a8d92ad` — J.1 Journey & Experience Platform Migration (#58)
- **Related:** `PF.2-Platform-Architecture-Decisions.md` (PF-ADR-014), `J.1-Journey-Experience-Platform-Migration.md`, `Adaptive-Discovery-and-Evidence-Engine.md`, `phase-h-2.md`, `AGENTS.md`
- **Date:** 2026-09-23

---

## 0. North-star flow (this phase)

D.1 closes the middle of the EH Platform adaptive loop:

```text
                    EH PLATFORM

Reflection ──→ Behavioral Evidence
                    │
                    ▼
              Behavior Patterns
                    │
                    ├──────────────┐
                    ▼              ▼
             Discovery Data   Journey Understanding
                    │              │
                    └──────┬───────┘
                           ▼
                  Discovery Profile
                           │
                           ▼
                  Experience Selection
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          Mission       Reflection    Hero Story
```

### How to read the diagram (ownership)

| Node | Bounded context / owner | Role in D.1 |
|------|-------------------------|-------------|
| Reflection → Behavioral Evidence → Behavior Patterns | **Life Journey** (H.2; already on platform) | Unchanged authority |
| Discovery Data | **Discovery** | Influences, preferences, user discoveries, resolved `NarrativeThemeId`s |
| Journey Understanding | **Life Journey** (read model) | Behavior patterns on current Journey — **not copied into Discovery** |
| Discovery Profile | **Discovery** | Holistic person-inspiration aggregate; **does not own** Behavior Patterns |
| Experience Selection | **Experience** (J.1) | Dual-read: prefer Discovery Profile when populated; else transitional signals |
| Mission / Reflection / Hero Story | Experience outputs | Reflection remains primary; Hero Story seam already exists; Mission selection **deferred** |

**Critical invariant (existing AD / phase-h-2):**

> Behavior Patterns are owned by the Journey aggregate. Discovery Profile consumes Journey understanding at read/composition time. It must not become a second pattern store.

---

## 1. Executive summary

### Settled baseline (after J.1)

| Concern | Owner |
|---------|-------|
| Reflection → evidence → pattern detection | **EH Platform** Life Journey |
| Journey `behaviorPatterns` persistence | **EH Platform** Postgres |
| Experience Selection / `GET /v1/experiences/today` | **EH Platform** Experience |
| AdaptiveDiscoverySignals (patterns ± empty themes) | **Platform Experience** (transitional; themes not yet from Discovery) |
| HS.8 story candidate port | Platform seam; default empty candidates |
| DiscoveryProfile / Influence / NarrativeTheme | **Flutter Discovery only** (in-memory; unwired to Experience) |
| Platform `DiscoveryModule` | **Stub boundary** |

### Gap relative to the north-star diagram

```text
TODAY (J.1)
  Behavior Patterns ──→ Experience Selection ──→ Reflection (± Story seam)

TARGET (D.1)
  Behavior Patterns ──┐
                      ├──→ Discovery Profile inputs ──→ Experience Selection
  Discovery Data ─────┘         (prefer when populated)
```

### D.1 goal

1. Make **Discovery Profile** authoritative on EH Platform (persist + commands/queries).
2. Wire **Discovery Data** (influences → themes) into the profile.
3. Keep **Journey Understanding** as a Life Journey read input to Experience Selection (patterns stay on Journey).
4. Update Experience Selection per **PF-ADR-014 Option C**: prefer Discovery Profile when populated; fall back to AdaptiveDiscoverySignals.
5. Preserve explainability sources (`behavior_pattern`, `narrative_theme`, `discovery_influence`, …).

### Explicit non-goals (D.1)

| Out of scope | Why |
|--------------|-----|
| Mission as Experience Selection output | Product surface still Flutter-centric; Phase 4 Mission/Quest APIs not required |
| Full Hero & Story platform authority | PF.2 Phase 7 |
| Production semantic search / ML ranking | Premature vs HS catalog |
| Growth Opportunities aggregate | Deferred post Phase 5–6 (PF.2) |
| Copying Behavior Patterns onto DiscoveryProfile | Violates Journey ownership |
| LLM-based profile inference | AI remains ports; evidence-first |
| Removing Flutter local Discovery domain entirely | Phase 9 simplification |
| Kafka / microservices | Modular monolith |

---

## 2. Current architecture (verified)

### 2.1 Platform Experience path (J.1)

```text
GET /v1/experiences/today
  → ExperienceApplicationService
  → current Journey (findCurrentByUserId)
  → AdaptiveDiscoverySignals(behaviorPatterns: journey.behaviorPatterns)
  → DiscoverableStoryCandidatePort (default empty)
  → AdaptiveExperienceComposer
       ├── story candidate with themeOverlapCount > 0 → Hero Story
       └── else DeterministicExperienceSelectionService → Reflection
```

Themes are **not** loaded from DiscoveryProfile today. Platform signals effectively carry **patterns only**.

### 2.2 Flutter Discovery (exists, unwired)

| Artifact | Status |
|----------|--------|
| `DiscoveryProfile` aggregate | Implemented (influences, themes, discoveries, preferences) |
| `Influence` / `NarrativeTheme` entities | Implemented |
| `InMemoryDiscoveryProfileRepository` | Implemented |
| `AddInfluenceUseCase` / `ResolveNarrativeThemesUseCase` | Implemented |
| Riverpod / UI product wiring | Missing |
| Platform persistence / API | Missing |

### 2.3 AdaptiveDiscoverySignals (transitional)

```text
AdaptiveDiscoverySignals
  ├── narrativeThemeIds[]   ← Reflection themes (Flutter HS.8) / empty on platform Today
  └── behaviorPatterns[]    ← Journey understanding
```

HS.8 Flutter path still resolves reflection themes ∪ patterns. Platform Today does not yet mirror reflection-theme resolution.

---

## 3. Target architecture (D.1)

### 3.1 Module boundaries

```text
EH Platform
  ├── LifeJourneyModule     (unchanged H.2 authority)
  ├── DiscoveryModule       (NEW product wiring)
  │     ├── DiscoveryProfile aggregate
  │     ├── Influence + NarrativeTheme reference data
  │     ├── Repositories (Postgres)
  │     └── DiscoveryApplicationService
  ├── ExperienceModule      (UPDATED dual-read selection)
  │     ├── reads DiscoveryProfile via DiscoveryProfileQueryPort
  │     ├── reads Journey patterns via existing JourneyRepository
  │     └── composes Today’s Experience
  └── HeroStoryModule       (unchanged stub / empty candidate port unless later Phase 7)
```

Dependency direction:

```text
Experience ──reads──► Discovery (query port)
Experience ──reads──► LifeJourney (Journey patterns)
Discovery  ──does not mutate──► LifeJourney
LifeJourney ──does not own──► DiscoveryProfile
```

Cross-context communication for writes that affect profile from LJ facts (optional slice):

```text
BehaviorPatternsDetected / ReflectionSubmitted
  → (optional) reactor may propose theme merges
  → Discovery use case updates DiscoveryProfile themes
```

Default D.1 stance: **profile updates from explicit Discovery commands (influences)** first; **optional theme-merge from reflection themes** as a bounded follow-on within D.1 only if design below is accepted.

### 3.2 Diagram node → code mapping

| Diagram node | D.1 representation |
|--------------|-------------------|
| Discovery Data | Influences + preferences + user discoveries + themes resolved from influences |
| Journey Understanding | `Journey.behaviorPatterns` (query; not stored on profile) |
| Discovery Profile | `DiscoveryProfile` aggregate + Postgres |
| Experience Selection | `ExperienceApplicationService` + composer + deterministic selector |
| Reflection | Existing UI.3 catalog ids / begin-reflection path |
| Hero Story | Existing composer + `DiscoverableStoryCandidatePort` (still fail-closed until HS candidates wired) |
| Mission | **Not selected in D.1** — leave experience type reserved; no Mission API |

---

## 4. PF-ADR-014 design lock (profile update rules)

PF-ADR-014 strategy is accepted (Option C). This section supplies the **missing design** for profile update rules.

### 4.1 What DiscoveryProfile stores

| Field | Source of truth | Update rule |
|-------|-----------------|-------------|
| `userId` | Identity | Set at create; immutable |
| `influenceIds` | Explicit user Discovery actions | `AddInfluence` / `RemoveInfluence` |
| `narrativeThemeIds` | Derived from Influences via `InfluenceThemeResolver` (+ optional reflection theme merge) | Recompute on influence change; never invent themes without a source |
| `discoveries` | Explicit discovery activities | Add/remove only via Discovery use cases |
| `preferences` | Explicit preference commands | Upsert by preference type |

**Not stored on DiscoveryProfile:**

* Behavior Patterns
* Behavioral Evidence
* Growth scores / XP
* Story interaction → inferred inspiration

### 4.2 “Populated” definition (Experience Selection gate)

A profile is **populated** when **any** of:

1. `influenceIds.isNotEmpty`, or
2. `narrativeThemeIds.isNotEmpty`, or
3. `preferences.isNotEmpty`

Otherwise Experience Selection uses **transitional AdaptiveDiscoverySignals** (J.1 behavior: Journey patterns ± empty/reflection themes).

### 4.3 Dual-read personalization inputs

```text
inputs =
  Journey.behaviorPatterns                            // always from LJ
  ∪
  if profile.populated:
      profile.narrativeThemeIds                       // Discovery authority
  else:
      transitional reflection themes (if any)         // HS.8 / J.1 fallback
```

Explainability must cite actual sources used (`discovery_profile`, `behavior_pattern`, `narrative_theme`, `fallback_signals`).

### 4.4 Optional reflection → profile theme merge (design choice)

**Recommendation for D.1.v1:** **Do not** auto-merge Reflection `NarrativeThemeId`s into DiscoveryProfile.

Rationale:

* Reflection themes are evidence attached to a Reflection, not Discovery ownership.
* Auto-merge would blur Catalog/Discovery/Evidence boundaries.
* Influences already resolve themes intentionally.

**D.1.v2 (optional, same phase if product insists):** After `ReflectionSubmitted`, a Discovery reactor may **union** submitted themes into the profile **only when** themes were already catalog-known `NarrativeThemeId`s — never invent themes. Document as explicit ADR amendment if enabled.

### 4.5 Journey understanding → profile

**Never persist patterns on the profile.**

Experience Selection always loads patterns from the current Journey at read time. The diagram’s “Journey Understanding → Discovery Profile” arrow is an **input edge to composition**, not a write into the aggregate.

```text
Composition-time view (not a stored aggregate):

DiscoveryProfileView
  ├── profile themes / influences / preferences
  └── journeyPatterns (from LJ read port)
```

---

## 5. Persistence

New migration `003_d1_discovery.sql` (illustrative):

```text
discovery_profiles
  id TEXT PK
  user_id TEXT UNIQUE NOT NULL REFERENCES identity_users(id)
  influence_ids JSONB NOT NULL DEFAULT '[]'
  narrative_theme_ids JSONB NOT NULL DEFAULT '[]'
  discoveries JSONB NOT NULL DEFAULT '[]'
  preferences JSONB NOT NULL DEFAULT '[]'
  version INT NOT NULL
  created_at / updated_at

influences (reference catalog)
  id, canonical_name, category, description, image_reference,
  aliases JSONB, narrative_theme_ids JSONB, …

narrative_themes (reference catalog)
  id, name, description, …
```

Notes:

* One profile per user for v1 (`user_id` unique).
* Catalog seed may ship a small deterministic set (Courage, Discipline, Perseverance, …) for tests/demo.
* No experience/selection tables (remain on-read, same as J.1).

---

## 6. API surface (proposed)

### Commands

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/v1/discovery/profiles` | Create profile for authenticated user (idempotent if exists) |
| `POST` | `/v1/discovery/profiles/current/influences` | Add influence |
| `DELETE` | `/v1/discovery/profiles/current/influences/{influenceId}` | Remove influence |
| `POST` | `/v1/discovery/profiles/current:resolve-themes` | Resolve themes from influences |

### Queries

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/v1/discovery/profiles/current` | Current profile DTO |
| `GET` | `/v1/discovery/influences` | Influence catalog (read) |
| `GET` | `/v1/discovery/narrative-themes` | Theme catalog (read) |

Auth: existing PF.3 Bearer principal. No public “mutate themes without influence/source” command.

### Experience API

`GET /v1/experiences/today` **unchanged path**; selection internals gain Discovery dual-read. Explanation payload may gain discovery sources.

---

## 7. Experience Selection changes

### 7.1 Application flow

```text
Authenticated principal
  → current Journey
  → load DiscoveryProfile by userId (nullable)
  → build AdaptiveDiscoverySignals:
        patterns = journey.behaviorPatterns
        themes   = profile.populated ? profile.themes : transitionalThemes
  → story candidates via port
  → composer → TodayExperienceDto
```

### 7.2 Deterministic reflection rules

Preserve J.1 mapping:

| Condition | Experience |
|-----------|------------|
| consistency pattern present | `consistency-next-step` |
| otherwise | `default-reflection` |

Discovery themes primarily affect **Hero Story candidate relevance** (overlap), not the UI.3 reflection id table — unless a future ADR adds theme-conditioned reflection catalogs.

### 7.3 Hero Story / Mission outputs

| Output | D.1 |
|--------|-----|
| Reflection | Supported (primary) |
| Hero Story | Supported when candidate port returns overlap > 0 (same as J.1 seam) |
| Mission | **Not implemented** — diagram aspirational; requires Mission experience catalog + Phase 4 APIs |

---

## 8. Flutter changes

| Mode | Behavior |
|------|----------|
| Platform authority on | Call Discovery APIs for profile/influences; Today remains platform DTO only |
| Local / no URL | Retain in-memory Discovery + existing HS.8 Flutter composer |
| Platform Discovery fetch fails | Today selection still works via Journey-only fallback; profile UI shows unavailable — **do not invent profile** |

Ensure `getTodayExperience` in platform mode does **not** re-run local Discovery overrides (same J.1 rule).

---

## 9. Events

Create only when another component needs them:

| Event | When | Consumer |
|-------|------|----------|
| `DiscoveryProfileCreated` | Profile created | Optional analytics / ensure-once |
| `InfluenceAdded` / `InfluenceRemoved` | Influence mutation | Theme resolve use case / projections |
| `NarrativeThemesResolved` | After resolve | Experience cache invalidation (if any) |

Do **not** invent `DiscoveryProfileUpdatedFromPatterns` — patterns are not written to the profile.

---

## 10. Implementation slices

### Slice 1 — Platform Discovery domain + persistence

* Port Flutter Discovery aggregates/VOs/repos patterns into `services/eh_platform/.../discovery`
* Migration `003_d1_discovery.sql`
* In-memory + Postgres repositories
* Focused domain tests

### Slice 2 — Discovery application + API

* Create profile / add influence / resolve themes / get current
* Catalog read endpoints
* OpenAPI update
* API/integration tests

### Slice 3 — Experience dual-read (PF-ADR-014)

* `DiscoveryProfileQueryPort` for Experience module
* Update `ExperienceApplicationService` signal composition
* Explanation source coverage
* Preserve consistency → reflection behavior
* Story seam tests with injected themes from profile

### Slice 4 — Flutter platform client wiring

* Discovery DTOs + client methods
* Optional thin Discover UI hook **only if** needed to demonstrate profile population (keep minimal)
* Platform-mode Today remains authoritative

### Slice 5 — Verification

* `dart analyze` (platform + Flutter)
* Focused + full relevant suites
* Architecture boundary tests: Experience does not import Discovery aggregate internals beyond ports/DTOs; Discovery does not import Journey aggregates for mutation

---

## 11. Acceptance criteria

- [ ] Platform owns DiscoveryProfile persistence and commands/queries
- [ ] Influences resolve into `NarrativeThemeId`s without duplicating NarrativeTheme ownership elsewhere
- [ ] Behavior Patterns remain Journey-owned; not persisted on DiscoveryProfile
- [ ] `GET /v1/experiences/today` prefers profile themes when profile populated; else J.1 fallback
- [ ] Explainability cites real sources only
- [ ] Hero Story seam still fail-closed without candidates; improves when themes + candidates present
- [ ] Mission experience selection not claimed as done
- [ ] Analyzer clean; focused + broader tests green
- [ ] Docs: this plan marked implemented only after code lands; PF-ADR-014 status updated

---

## 12. Architectural risks

| Risk | Mitigation |
|------|------------|
| Empty profiles regress Today | Dual-read fallback (PF-ADR-014 C) |
| Accidental pattern ownership drift | Explicit non-storage rule + tests |
| Theme inflation from reflections | Default: no auto-merge in D.1.v1 |
| Experience → Discovery tight coupling | Query port / DTO only |
| Scope creep into HS platform authority | Keep empty candidate port until Phase 7 |
| Mission appearing “done” in UI | Do not add Mission experience type paths in D.1 |

---

## 13. Open decisions (require product/architecture confirmation before coding)

1. **Authorize D.1 implementation?** This document is planning only.
2. **Enable reflection theme auto-merge (D.1.v2)?** Default recommendation: **No**.
3. **Minimal Discover UI in D.1?** Recommended: API + tests first; optional one-screen influence picker only if needed for demo.
4. **Catalog seed size?** Small fixed seed vs empty + fixtures-only.
5. **Profile create policy:** auto-create on first authenticated Discovery call vs explicit `POST`.

Until (1) is authorized, agents must not implement D.1 slices.

---

## 14. Relationship to completed phases

```text
H.1  Reflection analysis → Behavioral Evidence
H.2  Behavioral Evidence → Behavior Patterns (Journey)
PF.3 Platform foundation + Identity
J.1  Experience Selection authority on platform
D.1  Discovery Profile + dual-read personalization   ← this plan
P7   Hero & Story platform authority (later)
```

D.1 is the phase that makes the EH PLATFORM diagram’s **Discovery Profile** node real in the live selection path without collapsing evidence, patterns, catalog, or personalization into one blob.
