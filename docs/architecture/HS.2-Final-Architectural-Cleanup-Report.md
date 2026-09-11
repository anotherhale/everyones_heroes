# HS.2 — Final Architectural Cleanup Report

**Date:** 2026-09-11  
**Related plan:** [`docs/architecture/HS.2-Story-Catalog-Foundation-Plan.md`](./HS.2-Story-Catalog-Foundation-Plan.md)  
**Scope:** Planning/documentation only — no `lib/` or test implementation in this cleanup  

---

## A. Changes Made

Substantive planning changes in the HS.2 plan document:

- Rewrote the plan as an **implementation-ready** document with the six decisions authoritative (no open ★ questions for those items).
- Removed obsolete alternatives:
  - extensible/ID-based local taxonomies
  - AI classification proposal model
  - ISO geography infrastructure
  - speculative suitability/spirituality/proposal events
  - Challenge-based Resilience
- Clarified mandatory separation:
  - **Story** = authoritative catalog state
  - **StorySearchPort** = explicit catalog query
  - **Discovery** = relevance/meaning
  - **Personalization** = what next (future; not HS.2)
- Finalized `StorySearchQuery` contract, including:
  - subjects, challenges, narrative themes, outcomes, emotional characters, audience
  - geography contains filters
  - spirituality category / religious tradition
  - content suitability maximums (all dimensions)
  - formats
  - `minDuration` / `maxDuration`
  - `originalLanguage` vs `availableLanguage`
  - `publishedOnly` default `true`
- Locked duration semantics to **ANY matching representation**, including:
  - null-duration does not satisfy duration bounds
  - when both min and max are set, the same representation must fall in the window
- Kept events minimal: retain `StoryClassified` only for catalog classification
- Expanded testing strategy, proposed file tree, implementation sequence, and deferred scope to match Option B / catalog-only HS.2
- Reduced remaining questions to fixture/DI wiring only

---

## B. Final Architectural Decisions

| ID | Decision |
|----|----------|
| **1. Closed taxonomies** | Use closed enums for `StorySubject`, `StoryChallenge`, `StoryOutcome`, `EmotionalCharacter`, `StoryAudience`, and Format where applicable. No taxonomy repositories, taxonomy aggregates, or extensible taxonomy IDs in HS.2. |
| **2. AI classification (Option B)** | Do not introduce `ClassificationProposal`, proposed-vs-authoritative state, AI approval workflow, or proposal persistence. `StoryClassified` means authoritative classification only. AI proposal → human approval → authoritative is deferred to **HS.4**. |
| **3. Geography** | Keep free-form `StoryGeography`. No geography repositories, ISO hierarchy, geography aggregates, or geographic taxonomy infrastructure. |
| **4. Duration** | Duration is a `StoryRepresentation` property. `minDuration` / `maxDuration` match if **ANY** representation satisfies the constraint. Do not use shortest-only, longest-only, or single canonical representation matching. Do not duplicate duration as Story-level state. |
| **5. Events** | Minimal event model. Retain `StoryClassified`. Do not add `StoryContentSuitabilityUpdated`, `StorySpiritualityUpdated`, or `StoryClassificationProposed` in HS.2. |
| **6. Resilience** | Resilience is a Discovery-owned `NarrativeTheme` referenced via `NarrativeThemeId`. Do not add Resilience to `StoryChallenge`. |

---

## C. Remaining Questions

Only items that cannot be fully resolved from current architecture/product direction:

1. **Resilience fixture strategy** — For tests/demos, should Discovery seed a stable `NarrativeTheme` named “Resilience”, or may tests use an opaque generated `NarrativeThemeId` without requiring a persisted theme entity?
2. **Application provider wiring** — Should HS.2 add Riverpod providers for the new suitability/spirituality use cases, or keep constructor injection only (matching current classify/search wiring in HS.1)?

These do **not** change the domain model, aggregate boundaries, search semantics, or event model.

---

## D. Implementation Readiness

**HS.2 READY FOR IMPLEMENTATION**

Blockers: none for the Story Catalog foundation scope defined in the plan.

Remaining questions above affect test fixtures and DI wiring only.

---

## Download / References

- Full plan: `docs/architecture/HS.2-Story-Catalog-Foundation-Plan.md`
- This report: `docs/architecture/HS.2-Final-Architectural-Cleanup-Report.md`
