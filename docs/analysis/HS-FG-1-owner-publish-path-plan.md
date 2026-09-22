# HS.FG.1 — Owner Publish Path Composition

**Status:** PLANNED (ready for implementation)  
**Date:** 2026-09-22  
**Parent:** Phase C — Foundation Gap Closure  
**Prerequisite:** SB.13 complete; `docs/analysis/HS-architecture-checkpoint.md`  
**Branch naming:** `cursor/hs-fg-1-owner-publish-path-<id>`

---

## 1. Objective

Compose the existing Story lifecycle use cases so an owner can take a **materialized draft Story** through Submit → Approve → Publish (with required consent and discoverable visibility) and have that Story appear in existing Discover\* / catalog browse results.

```text
Accepted StoryProposal
        ↓
Materialize (SB.13) → draft Story
        ↓
Owner grants publication consent (if needed)
        ↓
Submit → Approve → Publish (+ public|community visibility)
        ↓
StoryDiscoverabilityPolicy.isDiscoverable == true
        ↓
DiscoverStories / BrowseStoriesByCatalog can return it
```

This closes the largest post–SB.13 composition hole identified in the architecture checkpoint.

---

## 2. Existing Infrastructure to Reuse

| Component | Path / note |
|-----------|-------------|
| `SubmitStoryUseCase` | Already exists |
| `ApproveStoryUseCase` | Exists; needs provider wiring |
| `PublishStoryUseCase` | Exists; needs provider wiring |
| `UpdateStoryConsentUseCase` | Wired in capture; reuse for publication consent |
| `Story.publish` / `submit` / `approve` | Domain methods + events |
| `StoryDiscoverabilityPolicy` | Requires published + `{public, community}` |
| Owned story UI | My Stories / Owned Story Detail |
| `ListHeroOwnedStoriesUseCase` / `GetOwnedStoryDetailUseCase` | Owner reads |
| `CreateStoryUseCase` / materialize path | Leave as draft; do **not** auto-publish |

Do **not** create a second Story lifecycle model or a parallel “release” aggregate.

---

## 3. Inspect First

Before writing code, Cursor must verify:

1. Exact preconditions in `Story.submit`, `Story.approve`, `Story.publish` (consent, provisional narrative, visibility)
2. `PublishStoryRequest` fields (visibility override?)
3. Which owned-detail providers/screens exist and how archive is already wired
4. Whether a single orchestration use case (e.g. `PublishOwnedStoryUseCase`) is clearer than three sequential UI calls — prefer smallest coherent application API without collapsing domain transitions
5. Existing tests for submit/approve/publish domain behavior
6. That Discover\* tests can assert eligibility after publish

---

## 4. Domain Changes

**Expected:** none, or minimal (only if a publish precondition is incorrectly blocking owner publish of non-provisional narratives).

Do **not** add `suspended`/`removed` in this slice unless required to unblock publish.

Do **not** change SB.13 materialization to publish automatically.

---

## 5. Application Changes

Expected:

- Riverpod providers for `ApproveStoryUseCase` and `PublishStoryUseCase` (and Submit if missing from owned composition)
- Optional thin owner orchestration use case **only if** UI would otherwise embed multi-step domain rules
- Presentation/application DTOs for owned lifecycle actions (avoid returning raw aggregates to widgets if a view model already exists — extend it)

Must invoke existing use cases; must publish domain events already raised by Story methods via the existing EventBus pattern used by CreateStory.

---

## 6. Infrastructure Changes

**Expected:** none (file Story repository already persists lifecycle/visibility/consent).

---

## 7. UI Changes

Owned Story Detail (and/or My Stories):

- Show current lifecycle + visibility
- Actions: Submit / Approve / Publish (gated by current state and consent)
- Clear copy that materialization ≠ publication (consistent with SB.13 messaging)
- After publish with discoverable visibility, owner can understand the Story is catalog-eligible

Do **not** put Discover\* algorithms or repository access in widgets.

---

## 8. Tests

| Level | Cases |
|-------|-------|
| Application | Submit→Approve→Publish happy path; missing consent fails; provisional narrative cannot publish; idempotent/guarded illegal transitions |
| Integration | Materialize accepted proposal → publish path → `DiscoverStories` returns story (with public/community visibility) |
| UI (focused) | Owned detail shows actions; publish updates presented state |
| Architecture | Presentation still does not call StoryRepository for publish (use case only) |

Also run analyzer + relevant broader suite.

---

## 9. Non-Goals

- Auto-publish on materialization
- Catalog taxonomy changes
- `StoryBuilderTheme` → `NarrativeThemeId` mapping (HS.FG.2)
- Story Understanding generate/review/apply UI (HS.FG.3)
- Moderation / community review workflows
- Semantic search
- Personalization / HS.8 rule changes
- Seeker audio player polish
- Identity BC replacement

---

## 10. Definition of Done

```text
Materialized draft Story
        ↓
Owner publish path (consent + submit + approve + publish + discoverable visibility)
        ↓
Persist + reload → same published state
        ↓
DiscoverStories / browse eligibility true
        ↓
Focused tests pass
        ↓
Analyzer clean
        ↓
docs/analysis/HS-FG-1-owner-publish-path.md implementation report
        ↓
Update Implementation Master Plan status
```

---

## 11. Recommended Follow-On

**HS.FG.2 — Builder Theme → NarrativeThemeId Bridge**

Map `StoryBuilderTheme` / Builder understanding into Discovery-owned `NarrativeThemeId` via an explicit application contract (classify / apply understanding) — never by duplicating NarrativeTheme in Hero & Story.

---

## 12. Architectural Risks

| Risk | Mitigation |
|------|------------|
| UI embeds lifecycle rules | Keep transitions in domain/use cases; UI only sends intent |
| Collapsing submit/approve/publish into one domain method | Preserve distinct facts/events unless product explicitly requires a single operation — orchestration may call three use cases |
| Publishing private Stories into Discover\* | Enforce DiscoverabilityPolicy; tests must use public/community |
| Breaking SB.13 “not published” invariant | Materialize remains draft-only |

---

## 13. Cursor Protocol Reminder

> Inspect before implementing. Extend existing architecture before introducing parallel architecture.
