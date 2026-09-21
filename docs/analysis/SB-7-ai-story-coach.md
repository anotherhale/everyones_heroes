# SB.7 — AI Story Coach

**Status:** IMPLEMENTATION COMPLETE  
**Date:** 2026-09-21  
**Branch:** `cursor/sb-7-ai-story-coach-34b6`  
**Baseline:** SB.1–SB.6 on `main`  
**Report path:** `docs/analysis/SB-7-ai-story-coach.md`

---

## 1. Objective

SB.7 replaces `UnsupportedAiStoryBuilderQuestionStrategy` with a real adaptive
**AI Story Coach** that asks one useful next question at a time.

Core principle preserved:

> **The Hero remains the author. AI is the interviewer/coach.**

SB.7 does **not** implement Story Understanding, Story Authoring, credits, or
automatic Story creation.

---

## 2. Existing AI Architecture

Before SB.7:

| Piece | Status |
|-------|--------|
| `services/ai_proxy` | STT-only (`POST /story-transcriptions`) |
| Flutter `ProxyStoryTranscriptionAdapter` | Calls EH proxy; no OpenAI key in app |
| Config | `EH_AI_PROXY_URL`, `EH_AI_PROXY_AUTH_TOKEN`, `EH_TRANSCRIPTION_MODE` |
| Understanding / Authoring / Translation ports | In-memory deterministic adapters |
| AI credits / Identity consume | **Not present** in Dart |

Verdict: the existing proxy was **STT-only** and required a narrowly scoped
LLM extension for coaching. SB.7 did not invent a second Flutter→provider stack.

---

## 3. AI Boundary

```text
StoryBuilderMode.ai
        ↓
StoryBuilderQuestionStrategyResolver
        ↓
AiStoryBuilderQuestionStrategy  (domain; AI-agnostic session)
        ↓
StoryBuilderCoachPort           (domain port)
        ↓
InMemoryStoryBuilderCoachAdapter | ProxyStoryBuilderCoachAdapter
        ↓
EH AI proxy POST /story-builder-questions
        ↓
OpenAI chat completions (server-side only)
```

`StoryBuilderSession` remains free of HTTP clients, API keys, model names, and
JSON parsing.

---

## 4. AI Proxy

Extended `services/ai_proxy`:

* New `POST /story-builder-questions`
* Reuses `OPENAI_API_KEY`, optional Bearer `EH_AI_PROXY_AUTH_TOKEN`
* New optional `OPENAI_CHAT_MODEL` (default `gpt-4o-mini`)
* Same host/port as transcription (`EH_AI_PROXY_HOST` / `EH_AI_PROXY_PORT`)

Flutter still uses a single proxy base URL: `EH_AI_PROXY_URL`.

Optional coach mode: `EH_STORY_BUILDER_COACH_MODE=proxy|development`
(defaults to proxy when `EH_AI_PROXY_URL` is set, otherwise in-memory).

---

## 5. Request Model

`StoryBuilderCoachRequest` is minimized from the durable session:

* `purpose`
* `themes` / `themesUnsure`
* `turns[]` — prompt text, ordinal, narrative role, response text, skipped
* `presentedNarrativeRoles`

Not sent: filesystem paths, auth tokens, unrelated Hero profile fields,
provider conversation IDs.

Hero response text is treated as **untrusted user content** and is placed only
inside a delimited context block on the proxy (never interpolated into the
system prompt).

---

## 6. Response Model

EH-owned structured suggestion:

```json
{
  "question": "...",
  "narrativeRole": "turningPoint",
  "reason": "...",
  "readyToComplete": false
}
```

Persisted on the session:

* question text → `StoryBuilderPrompt.text`
* narrative role → existing `StoryBuilderNarrativeRole`
* prompt id → application-generated `StoryBuilderPromptId`
* provenance → `StoryBuilderPromptSource.aiCoach`

`reason` stays application/infrastructure metadata (not shown to the Hero).

---

## 7. Prompt Design

Server-side `StoryBuilderCoachInstructions.systemPrompt` establishes:

* Role: interviewer/coach; one question at a time
* Cover SB.3 narrative roles when useful (not mandatory all 11)
* Restrictions: no invention, no rewriting Hero words, no polished story,
  no diagnoses / sensitive identity inference
* Completion: `readyToComplete` may be true when enough material exists

---

## 8. Persistence

AI sessions resume from `StoryBuilderSession` only:

```text
persisted prompts + responses + intent + mode
        ↓
AiStoryBuilderQuestionStrategy.buildCoachRequest
        ↓
next coach suggestion
```

No provider thread/conversation ID is canonical. Snapshot mapper persists
optional `source` (`catalog` | `aiCoach`); missing source defaults to `catalog`
for SB.5 compatibility.

Hero answers are saved via `AnswerStoryBuilderPromptUseCase` **before**
`AdvanceStoryBuilderUseCase` requests the next AI question.

---

## 9. Failure Handling

| Failure | Behavior |
|---------|----------|
| Timeout / network / proxy / auth / rate limit / malformed JSON | `Failure` from Advance; mode stays `ai` |
| UI | `coachUnavailable` with Retry / Continue with Guided / Save and exit |
| Guided switch | Only via explicit `SetStoryBuilderModeUseCase` (Hero decision) |
| Prior answers | Remain in repository |

Silent `mode = guided` on failure is forbidden and covered by tests.

---

## 10. Credits / Identity

Re-inspected: **AI credits still do not exist** in the codebase.

SB.7 uses the available AI access boundary (proxy / in-memory coach). The
coach port is the natural future integration point for Identity credit checks.
Guided Builder continues to work with zero AI dependency.

---

## 11. Security / Privacy

* No OpenAI (or other provider) keys in Flutter
* Data minimization on coach requests
* System instructions separated from Hero material
* Prompt-injection guidance in system prompt
* No consequential psychological / identity inference instructions

---

## 12. Testing

### Focused

* Flutter: `sb7_ai_story_coach_test.dart` + related SB.6 resolver/UI/architecture/advance tests — **pass**
* AI proxy: `services/ai_proxy` — **8/8 pass**

### Analyzer

`dart analyze` (workspace): **no errors**. One pre-existing warning in
`browse_stories_by_catalog_use_case.dart` (unrelated). Remaining issues are
pre-existing / style `info` lints.

### Full suite

`flutter test`: **926/926 passed**.

`services/ai_proxy` `dart test`: **8/8 passed**.

---

## 13. Architectural Decisions

1. **Reuse EH AI proxy** — extend with coaching route; do not call providers from Flutter.
2. **Domain coach port** — mirrors transcription/understanding ports.
3. **Same prompt/response model** — add smallest provenance enum; no parallel AI prompt hierarchy.
4. **Application owns prompt IDs** — LLM cannot invent domain identities.
5. **Hero-driven completion** — Finish action + optional coach `readyToComplete`; soft max of 20 presented prompts.
6. **Explicit Guided recovery** — `SetStoryBuilderModeUseCase` only on Hero choice.
7. **Default resolver stub** — `UnsupportedAi…` remains injectable for tests; production provider wires `AiStoryBuilderQuestionStrategy`.

---

## 14. Deferred Work

* Identity AI credits / consume / quota UX
* Production personalization beyond deterministic+coach questions
* HS.4 Story Understanding / SB.8 extensions
* HS.5 / story authoring from Builder material
* Hero Approval, Moments, compilations
* Automatic Story materialization from completed Builder sessions
* Silent credit-exhaustion policies (requires Identity)

---

## Definition of Done Checklist

* [x] AI mode → real AI strategy
* [x] Guided deterministic unchanged
* [x] Adaptive questions from session context
* [x] One question at a time; no story authoring
* [x] Hero responses canonical / unrewritten
* [x] Application-controlled prompt IDs
* [x] Resume without provider conversation state
* [x] Failures preserve answers; no silent mode switch
* [x] No invented credit system; no Flutter API keys
* [x] No Story Understanding / Authoring / Story auto-create
* [x] Report at `docs/analysis/SB-7-ai-story-coach.md`
