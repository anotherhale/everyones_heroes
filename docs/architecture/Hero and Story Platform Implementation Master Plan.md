# Hero & Story Platform — Implementation Master Plan

**Status:** Living execution plan (updated after HS architecture checkpoint)  
**Companion:** `docs/architecture/Hero and Story Platform Roadmap.md`  
**Primary bounded context:** Hero & Story  
**Current checkpoint:** SB.13 complete; Phase B architecture checkpoint complete; HS.FG.1 complete; HS.FG.2 complete; Post-FG integration checkpoint complete; HS.FG.3 complete  
**Next slice:** Theme-aware catalog composition / owner→seeker handoff (as needed)

**Related reports:**
- `docs/analysis/SB-13-story-materialization.md`
- `docs/analysis/HS-architecture-checkpoint.md`
- `docs/analysis/HS-FG-1-owner-publish-path-plan.md`
- `docs/analysis/HS-FG-1-owner-publish-path.md`
- `docs/analysis/HS-FG-2-theme-discovery-bridge.md`
- `docs/analysis/HS-post-FG-integration-checkpoint.md`
- `docs/analysis/HS-FG-3-owner-hero-discoverability.md`

---

## 1. Purpose

Executable technical plan for the Hero & Story Platform without violating Everyone's Heroes architectural boundaries.

North star:

> Everyone's Heroes is an adaptive human growth platform that continuously learns how to inspire each individual.

Hero & Story supplies experiences:

```text
Hero → Story → Catalog → Discovery → Candidate Inspiration → Personalization → Experience
```

It must **not** absorb behavioral understanding or personalization.

Core architectural requirements:

- Human stories remain authoritative human artifacts
- AI assists without becoming source of truth
- Provenance survives transformation
- Multilingual representations are foundational
- Catalog ≠ personalization
- Story interaction ≠ behavioral evidence
- Discovery ≠ cataloging

---

## 2. Relationship to the Roadmap

```text
Hero & Story Platform Roadmap
              ↓
       Capability Goals
              ↓
Implementation Master Plan  (this document)
              ↓
     Codebase Discovery
              ↓
       Architecture ADRs / Checkpoint
              ↓
       Vertical Slices
              ↓
      Implementation → Tests → Report → Next Slice
```

**Core rule:** Do not implement the roadmap left-to-right. Implement from the codebase outward.

---

## 3. Status Model

| Status | Meaning |
|--------|---------|
| Implemented | Exists and verified |
| Partially Implemented | Meaningful portion exists; incomplete |
| Planned | Desired; not started |
| Discovery Required | Inspect before defining |
| Validation Required | May exist; must verify |
| Deferred | Intentionally out of slice |

---

## 4. Verified Implementation Checkpoint (2026-09-22)

| Item | Status |
|------|--------|
| Story Builder SB.0–SB.12 | Implemented |
| SB.13 Story Materialization | **Implemented** |
| Phase B Architecture Checkpoint | **Complete** — `docs/analysis/HS-architecture-checkpoint.md` |
| Phase C Foundation Gap Closure | **In progress** (HS.FG.1 ✓; HS.FG.2 ✓; Post-FG checkpoint ✓; HS.FG.3 ✓; next theme-aware catalog / owner→seeker handoff) |

Historical HS.1→HS.8 numbering must **not** be read as “start from scratch.” Substantial capability already exists via HS.* and SB.* work. Audit first; implement only gaps.

---

## 5. Story Builder → Canonical Story Pipeline

```text
StoryBuilderSession
        ↓
StoryProposal
        ↓
Hero Review / Approval
        ↓
Accepted StoryProposal
        ↓
MaterializeStoryProposalUseCase   (SB.13 ✓)
        ↓
Canonical Story (draft)
        ↓
Owner lifecycle (submit/approve/publish)   (HS.FG.1 ✓)
        ↓
Discoverable catalog entry
```

Materialization is **not** publication.

---

## 6. HS Capability Map — Verified

| Capability | Verified status | Notes |
|------------|-----------------|-------|
| **HS.1 Foundation** | Implemented | Hero, Story, lifecycle, visibility, provenance, representations, language, classification, suitability, spirituality, repos, events |
| **HS.2 Catalog** | Implemented (domain + browse) | Multidimensional classification; browse use case; theme ID refs only |
| **HS.3 Capture** | Implemented | Device recording, media storage, capture completion |
| **HS.4 Understanding** | Partially Implemented | SB.8 Builder path wired; HS.4 StoryUnderstanding generate/review/apply unwired; no file understanding repo |
| **HS.5 Authoring / Approval** | Partially Implemented | SB.9–13 + FG.1 owner publish composed; script/translate weak composition; Hero visibility owner composition missing |
| **HS.6 Discovery** | Implemented (deterministic) | Search/Discover/Browse; in-memory adapters; catalog UI unfiltered |
| **HS.7 Hero Experience** | Partially Implemented | Experience DTOs + consume; seeker playback incomplete |
| **HS.8 Adaptive Discovery** | Partially Implemented | UI.3 seam + Story candidates; FG.2 maps Builder themes → NarrativeThemeId (theme UI still unwired) |

Full evidence: `docs/analysis/HS-architecture-checkpoint.md`.

---

## 7. Aggregate & Repository Strategy (current truth)

### Aggregates / roots in practice

- `Hero`, `Story`, `StoryBuilderSession`, `StoryUnderstanding`
- `StoryProposal` — persisted VO with identity (intentional)

### Repositories

- `HeroRepository`, `StoryRepository`, `StoryBuilderSessionRepository`, `StoryProposalRepository`, `StoryUnderstandingRepository` (in-memory only today)

Do **not** invent Theme / Language / Classification / Media repositories merely because nouns exist.

### Narrative Themes

Owned by Discovery. Hero & Story stores `NarrativeThemeId` only.

---

## 8. Dependency & AI Rules

```text
Presentation → Application contracts → Domain
Infrastructure → Domain / Application ports
```

Domain must not depend on Flutter, Riverpod, AI SDKs, HTTP, search vendors, or media vendors.

AI pattern:

```text
Port → Deterministic strategy and/or AI adapter → Infrastructure
```

AI may propose/transform. AI must not silently own Story truth, invent provenance, change ownership, or publish.

---

## 9. Provenance Distinctions

Keep separate:

| Concept | Meaning |
|---------|---------|
| Authorship | Who originally created content |
| Transformation | How content was generated/modified |
| Approval | Who approved the artifact |
| Publication | Whether authorized for publication |

Hero approval of a proposal does **not** convert `contentOrigin = derived` into hero-authored.

---

## 10. Implementation Sequence (revised)

```text
SB.13 ✓
  ↓
Phase B Architecture Checkpoint ✓
  ↓
HS.FG.1 Owner Publish Path Composition    ✓
  ↓
HS.FG.2 Builder Theme → NarrativeThemeId Bridge    ✓
  ↓
Post-FG Integration Checkpoint    ✓
  ↓
HS.FG.3 Owner Hero Discoverability Composition    ✓
  ↓
Theme-aware catalog composition / owner→seeker handoff (as needed)    ← NEXT
  ↓
Durable Story Understanding + apply wiring
  ↓
Presentation boundary cleanup (Story Builder)
  ↓
HS.5 composition (script/translate) as needed
  ↓
Experience polish (seeker playback)
  ↓
Reassess adaptive discovery quality
```

This intentionally differs from historical HS.1→HS.8 greenfield order.

**HS.FG.3:** Owner can explicitly set Hero visibility (`ChangeHeroVisibilityUseCase` + My Stories UI). Reuses `Hero.changeVisibility` / `HeroDiscoverabilityPolicy`. Publishing a Story does not change Hero visibility. See `docs/analysis/HS-FG-3-owner-hero-discoverability.md`.

**Post-FG checkpoint revision:** former “next = Durable Story Understanding” was superseded by verified code. Default local Hero is `private`, so published Stories never appear in Discover\* until Hero discoverability is composed. See `docs/analysis/HS-post-FG-integration-checkpoint.md`.

---

## 11. Vertical Slice Rules

Every slice must specify: objective, reuse, inspect-first, domain/app/infra/UI changes, tests, non-goals, definition of done.

Every slice produces `docs/analysis/<slice>.md`.

Protocol: **Inspect before implementing. Extend before inventing.**

Do not create without evidence: duplicate aggregates/repos, competing NarrativeTheme models, second Story source of truth, new lifecycle states without need, vendor-coupled domain types.

---

## 12. Testing & Definition of Done

Per slice:

```text
Implementation + Focused tests + Analyzer + Architecture checks
+ Persistence verification where relevant + Report
```

Prefer domain/application tests. Full Flutter suite before claiming completion.

---

## 13. Cross-Context Boundaries (unchanged)

```text
Published Story → Discovery candidate   (not personalization inside Story)
Story → Interaction → Reflection/Action → BehavioralEvidence → Pattern
Catalog → Candidates → Discovery → Personalization
```

Never: `Story → BehaviorPattern` directly.

---

## 14. Immediate Execution State

| Step | State |
|------|-------|
| 1. SB.13 Story Materialization | Complete |
| 2. Hero & Story architecture checkpoint | Complete |
| 3. `docs/analysis/HS-architecture-checkpoint.md` | Complete |
| 4. Compare vs HS.1 / boundaries / provenance / catalog | Complete (in checkpoint) |
| 5. Identify smallest missing foundational capability | Complete — owner publish composition |
| 6. Next vertical plan | `docs/analysis/HS-FG-1-owner-publish-path-plan.md` |
| 7–11. Implement / test / report HS.FG.1 | Complete — `docs/analysis/HS-FG-1-owner-publish-path.md` |
| 12. Update this master plan after HS.FG.1 | Complete |
| HS.FG.2 Theme Bridge | Complete — `docs/analysis/HS-FG-2-theme-discovery-bridge.md` |
| Post-FG Integration Checkpoint | Complete — `docs/analysis/HS-post-FG-integration-checkpoint.md` |
| HS.FG.3 Owner Hero Discoverability | Complete — `docs/analysis/HS-FG-3-owner-hero-discoverability.md` |
| Next | Theme-aware catalog composition / owner→seeker handoff (as needed) |

---

## 15. Long-Term End State (unchanged)

Hero & Story contributes:

```text
Hero → Story → Representation → Catalog → Discovery Candidate
```

It does not own the entire adaptive loop. Personalization and behavioral understanding remain outside Story.
