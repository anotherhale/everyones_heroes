# SB.3 — Deterministic Story Builder

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-3-deterministic-story-builder-1684`  
**Baseline:** SB.1 + SB.2; suite was **851/851**  
**Inspected main:** `89bf30e` (SB.2 merged)

---

## 1. Executive summary

SB.3 delivers the **first complete Guided Story Builder**: a deterministic 11-prompt catalog, strategy implementation, advance/answer/skip/edit/resume orchestration, minimal UI, and AI-independence guarantees.

A Hero can collect meaningful story material with **zero AI credits, network, proxy, or API key**. No `Story` is created on completion (SB.0/SB.1 deferral preserved).

---

## 2. Deterministic strategy

Implements SB.1 port `StoryBuilderQuestionStrategy`:

| Type | Path |
|------|------|
| Catalog | `DeterministicStoryBuilderCatalog` |
| Strategy | `DeterministicStoryBuilderQuestionStrategy` |
| Advance | `AdvanceStoryBuilderUseCase` |
| Default provider | `storyBuilderQuestionStrategyProvider` → deterministic |

```text
StoryBuilderQuestionStrategy
        │
        ├── DeterministicStoryBuilderQuestionStrategy  (SB.3)
        └── (future) AI strategy                       (SB.7)
```

`nextPrompt` returns the first catalog prompt lacking a response.  
`isQuestioningComplete` when all 11 have answered or skipped responses.  
Advance presents the next prompt or completes the session — **never creates a Story**.

---

## 3. Question catalog

| Stable ID | Ordinal | Role | Prompt text |
|-----------|---------|------|-------------|
| `sb.q.beginning` | 0 | beginning | What was happening in your life when this story began? |
| `sb.q.challenge` | 1 | challenge | What were you facing? |
| `sb.q.importance` | 2 | importance | Why was this difficult or important to you? |
| `sb.q.struggle` | 3 | struggle | What was the hardest part? |
| `sb.q.stakes` | 4 | stakes | What might you have lost, or what was at stake? |
| `sb.q.turningPoint` | 5 | turningPoint | Was there a moment when something changed? |
| `sb.q.decision` | 6 | decision | What did you decide to do? |
| `sb.q.action` | 7 | action | What happened next? |
| `sb.q.outcome` | 8 | outcome | How did things turn out? |
| `sb.q.reflection` | 9 | reflection | What did this experience teach you? |
| `sb.q.message` | 10 | message | If someone else were going through something similar, what would you want them to hear? |

All prompts are **optional** (skippable). IDs are stable string keys (not UUIDs).  
`StoryBuilderPrompt` gained `narrativeRole` + `isOptional` for SB.4 structure mapping.

---

## 4. User flow

```text
Heroes → Build My Story
   → start guided session
   → advance → present Qn
   → answer | skip | back | edit
   → pause (save + leave)
   → resume → first unanswered
   → after Q11 → session.completed (no Story)
```

Operations use existing SB.1 use cases plus `AdvanceStoryBuilderUseCase`.  
Back/forward viewing cursor is presentation-layer; domain responses remain intact.

---

## 5. Intent integration

SB.2 purpose/themes are stored on the session and editable, but **do not branch** the SB.3 catalog.

Rationale: product branching rules are not defined; inventing per-purpose catalogs would be speculative. Documented for later deterministic optional prompts if needed.

---

## 6. Persistence

Still **in-memory** (SB.5 for File). Verified: answer → pause → reload → resume position reconstructable via unanswered catalog prompts; responses preserved exactly.

---

## 7. AI independence

Confirmed by architecture test scanning catalog, strategy, advance use case, controller, and screen for OpenAI/Anthropic/HTTP imports.

Default strategy provider is deterministic. No credit checks. No proxy.

---

## 8. Story pipeline handoff

```text
Completed StoryBuilderSession
  ├── Intent (purpose/themes)
  ├── Prompts (stable IDs + narrative roles)
  └── Responses (exact Hero text / skips)
        │
        ▼ (later)
  SB.4 structure → Understanding → Authoring → Story representation
```

SB.3 only collects material.

---

## 9. UI

| Surface | Notes |
|---------|-------|
| `StoryBuilderScreen` | Single guided screen; progress “Question N of 11”; Back / Skip / Continue / Pause |
| Heroes catalog | Outlined **Build My Story** entry (alongside Tell Your Story) |
| Theme | Existing Material 3 + gold seed |

No AI chat chrome, credits, or provider settings.

---

## 10. Tests

| Suite | Result |
|-------|--------|
| Focused SB.3 (strategy, advance, AI independence, UI, prior strategy test) | **9/9 passed** |
| Analyzer (SB.3 surfaces) | **No issues** |
| Full `flutter test` | **859/859 passed** (baseline was 851/851) |

---

## 11. Deferred work

| Slice | Item |
|-------|------|
| SB.4 | Formal story structure from narrative roles |
| SB.5 | File persistence + durable resume list UI |
| SB.6 | Mode selection (Guided vs AI) framing |
| SB.7 | AI Story Coach strategy |
| — | Purpose/theme prompt branching |
| — | Story creation on complete |
| — | NarrativeTheme mapping |
| — | Intent selection UI before questions |

---

## 12. Open questions

| Question | Notes |
|----------|-------|
| Should intent be collected before Q1 in UX? | Deferred; session can hold intent anytime |
| Resume entry from My Stories | Needs file persistence (SB.5) |
| Empty Continue = Skip | Current UX choice; adjustable |

No blockers for SB.4.

---

## 13. Recommended next slice

**SB.4 — Deterministic Story Structure**
