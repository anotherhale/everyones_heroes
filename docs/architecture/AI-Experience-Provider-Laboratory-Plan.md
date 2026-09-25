# AI Experience Provider Laboratory — Implementation Plan

**Status:** Plan only — no implementation in this deliverable  
**Date:** 2026-09-25  
**Phase context:** Post–HS.12 (HS.12.3–HS.12.6 complete)  
**Principle:** The Hero owns the story. AI owns the presentation.

---

## Executive summary

Everyone’s Heroes already has an end-to-end **Hero Story → reading → experience plan → demo playback → synthetic narration** path. What it lacks is **provider-pluggable music generation**, **multi-provider comparison**, **cost/reproducibility telemetry**, and a **composed multimedia experience** that feels substantially different from playing the original recording.

This plan designs an **AI Experience Provider Laboratory**: an additive experiment that can take one real Hero story and compare provider combinations for creative direction, TTS, and music — without mutating canonical Story artifacts and without committing EH to any vendor.

**Primary recommendation:** Treat the laboratory as an application/infrastructure experiment layered on HS.12, not a new bounded context. Keep `StoryExperiencePlan` as the domain creative plan. Do **not** introduce a domain twin named `ExperienceComposition`. Introduce lab-scoped derived artifacts (`ExperienceLabRun`, `MusicRendering`, optional `ExperienceRenderManifest`) and extend the AI proxy with pluggable clients.

---

## 1. Current architecture findings

### 1.1 End-to-end pipeline today (HS.12)

```text
TellYourStory / DeviceRecordingPort
  → CompleteStoryCaptureUseCase
  → Story (draft) + original audio StoryRepresentation + StoryConsent.recordedAt
        ↓ explicit consent (processing + AI)
  StartOwnedStoryTranscriptionUseCase → StoryTranscriptionPort
  → transcript StoryRepresentation (derived, AI, unapproved until reviewed)
        ↓ "Understand my story"
  GenerateCapturedStoryReadingUseCase → CapturedStoryReadingPort
  → CapturedStoryReading (separate repo; not on Story)
        ↓ "Create my experience"
  GenerateStoryExperiencePlanUseCase → StoryExperiencePlannerPort
  → StoryExperiencePlan (separate repo; not on Story)
        ↓ "Play my experience"
  StoryExperienceTimelineBuilder → StoryExperienceTimeline
  → StoryExperiencePlayer (original recording + bundled demo stems + silence)
        ↓ optional separate consent
  RenderStoryVoiceUseCase → VoiceRenderingPort
  → StoryVoiceRendering (+ media bytes)
  → "Play narrated version" (persisted bytes only)
```

**Invariant already enforced:** Failures leave original recording playable. Plan/reading/voice are derived and separately persisted.

### 1.2 Layering that matters

| Concern | Domain | Application | Infrastructure | Presentation |
|---------|--------|-------------|----------------|--------------|
| Canonical Story | Aggregate | capture/publish/consent UCs | repos, media storage | Tell Your Story, Owned Detail, Hero Story |
| Reading / Plan / Voice | VOs + ports + repos (not on Story) | Generate*/Render* UCs | Proxy + parsers + file repos | Controllers + HeroStoryScreen |
| Timeline / stems | — | TimelineBuilder, DemoStem, Player port | just_audio, assets | Experience playback controller |
| AI credentials | — | — | `services/ai_proxy` only | Never |

### 1.3 Architectural decisions already locked

| ADR | Implication for the lab |
|-----|-------------------------|
| HS-ADR-073 | `StoryExperiencePlan` is derived presentation guidance; music direction is descriptive only |
| HS-ADR-075 | Playback renders a persisted plan; stems/purposes live in player layer, not domain schema |
| HS-ADR-076 | Voice is derived; requires independent `voiceRenderingApprovedAt`; no cloning in v1 |
| HS-ADR-067/068 | Credentials stay server-side; Flutter talks EH-owned contracts |

**Doc drift note:** Early sections of `HS.12-AI-Hero-Story-Demo-Plan.md` still mention `voiceStrategy` / `MusicCue` on the plan. **Code + HS-ADR-073/075 supersede that.** Do not revive those fields on the plan for the lab.

### 1.4 Naming collision to preserve

| Term | Meaning |
|------|---------|
| HS.7 Story Experience | Discoverability-gated catalog consumption (`GetStoryExperienceUseCase`) |
| HS.12 Experience Plan / Player | Owner presentation of an owned Hero’s story |

The laboratory extends **HS.12 presentation**, not HS.7 discovery.

---

## 2. Existing components that can be reused

### 2.1 Domain / application (reuse as-is)

- `Story`, `StoryRepresentation`, `StoryConsent`
- `CapturedStoryReading` + `CapturedStoryReadingPort` + repository
- `StoryExperiencePlan` + `StoryExperienceMusicDirection` + planner port/use case
- `StoryExperienceTimelineBuilder` / `StoryExperienceTimeline` (extend, don’t replace)
- `StoryExperiencePlayer` (already accepts optional `presentationVoiceBytes`)
- `StoryVoiceRendering` + `VoiceRenderingPort` + `RenderStoryVoiceUseCase`
- `StoryMediaStoragePort` for generated audio bytes
- Consent gates via `UpdateStoryConsentUseCase`

### 2.2 AI proxy / Flutter adapters (reuse pattern)

- EH-owned routes: `/captured-story-readings`, `/story-experience-plans`, `/story-voice-renderings`, `/story-transcriptions`
- Handler validation (span grounding, closed enums, psychological-key rejection)
- Flutter `Proxy*Adapter` + `InMemory*Adapter` dual mode
- Riverpod `*_port_provider` development/proxy switch
- Fake OpenAI clients in `services/ai_proxy/test/ai_proxy_test.dart`
- Architecture guard: `test/features/hero_story/architecture/ai_boundary_test.dart`

### 2.3 UI surfaces to preserve (additive only)

On `HeroStoryScreen`:

| Action | Must remain |
|--------|-------------|
| Play my recording | Original bytes only |
| Play my experience | Current deterministic demo-stem path |
| Create / Play narrated version | Existing `StoryVoiceRendering` path |
| Understand / Create my experience | Existing reading + plan generation |

### 2.4 What does **not** exist today

- Music generation ports or routes
- Multi-provider selection
- Cost / usage metering (OpenAI `usage` available but unused)
- Lab run / experiment persistence
- Wiring of `presentationVoiceBytes` into “Play my experience”
- Generated music assets in the player (only bundled demo stems)
- MiniMax / Qwen / Mubert / Stable Audio / Suno code or docs

---

## 3. Proposed architecture

### 3.1 Conceptual pipeline (lab)

```text
Hero Story (canonical, immutable by AI)
    ↓
CapturedStoryReading (existing)
    ↓
AI Creative Director → StoryExperiencePlan (existing contract)
    ↓
Experience Lab Orchestrator (application)
    ├── optional VoiceRenderingPort → StoryVoiceRendering
    ├── MusicGenerationPort → MusicRendering(+s)
    ├── ExperienceRenderManifest (application VO)
    └── ProviderUsageRecord[] (infrastructure/reporting)
    ↓
StoryExperiencePlayer (extended)
    ├── voice track (original and/or narrated)
    ├── music track(s)
    ├── timing / silence / intensity cues
    └── transitions
    ↓
Hero Experience (playback)
```

### 3.2 Architectural seam recommendation

#### Options analyzed

| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| **A. Expand `StoryExperiencePlan`** | Put BPM, stems, intensity curves, asset ids on the plan | One artifact | Violates HS-ADR-073/075; couples creative intent to physical render; forces regenerate on every music/TTS retry |
| **B. New domain `ExperienceComposition`** | Parallel domain aggregate for rendered composition | Clean conceptual split | Duplicates plan/player separation already decided; risk of two “truths”; over-models a lab concern |
| **C. Lab artifacts + player extension (recommended)** | Keep plan; add `MusicRendering`, `ExperienceLabRun`, optional `ExperienceRenderManifest` in application (or lab-scoped domain VOs) | Matches existing ADRs; additive; provider-swappable; Story untouched | Slightly more types; lab vocabulary must be named carefully |

#### Recommendation: **Approach C**

Keep the existing distinction:

| Concept | Role |
|---------|------|
| **`StoryExperiencePlan`** | *What the experience should be* — intention, arc, grounded moments, music **guidance**, sequence |
| **`ExperienceRenderManifest` (application)** | *How this lab run is physically rendered* — narration asset ref, music asset refs, cue timing, intensity curve, provider config fingerprint |
| **`StoryExperienceTimeline` + Player** | Deterministic runtime that executes a manifest (or falls back to today’s stem timeline) |

**Do not** introduce a durable domain aggregate named `ExperienceComposition` for the first lab. If a composition type is needed later for production, rename/promote `ExperienceRenderManifest` only after the experiment proves the shape.

### 3.3 Lab ownership boundary

- **Hero & Story** owns Story, reading, plan, voice, music renderings, lab runs as *derived presentation artifacts*.
- **Discovery** is not involved.
- **Life Journey / behavioral evidence** is not involved.
- No psychological inference fields anywhere in lab schemas.

### 3.4 Provider selection location (recommended)

| Layer | Role |
|-------|------|
| **Experiment configuration** (primary) | Explicit `ExperienceLabProviderConfig` on each lab run (creative / voice / music provider+model) |
| **AI proxy** | Resolves config → concrete client; holds credentials |
| **Riverpod** | Wires lab ports (development vs proxy); may pass lab config into use cases — **not** the ranking engine |
| **Domain** | Ports only; no vendor names beyond opaque `providerLabel` / `modelLabel` strings already used |

Avoid hard-coding “the” provider in Riverpod. Avoid a giant generalized AI service. Prefer **capability ports** (`StoryExperiencePlannerPort`, `VoiceRenderingPort`, `MusicGenerationPort`) with lab request metadata.

---

## 4. Proposed ports / interfaces

### 4.1 Existing ports (extend carefully)

```text
StoryExperiencePlannerPort.generate(...)
  → StoryExperiencePlanDraft
  // Lab: optional providerHint / modelHint forwarded as request metadata
  // Contract shape stays EH-owned; provider remains behind proxy

VoiceRenderingPort.render(VoiceRenderingRequest)
  → VoiceRenderingDraft
  // Lab: optional providerHint / modelHint / voiceStyleInstructions
  // Still reject voiceClone / heroVoiceTransformation in lab v1
```

### 4.2 New: `MusicGenerationPort`

Minimum application/domain contract (provider-agnostic):

```text
MusicGenerationRequest
  - storyId
  - experiencePlanId
  - experiencePlanProcessingVersion
  - sections[] OR singleTrack brief
  - prompt / style / mood / energy (from plan.musicDirection + section briefs)
  - targetDuration
  - instrumentalPreferred: true (default for demo)
  - intensityCurve hints (optional)
  - targetBpm? (optional musical BPM — never equated to speech rate)
  - seed? (if provider supports)
  - providerHint / modelHint (lab only)
  - requestId / experimentId

MusicGenerationDraft
  - sections[] { sectionId, media bytes or URI, duration, contentType,
                 providerLabel, modelLabel, generationId?, promptUsed }
  - processingVersion
```

**Out of domain contract:** vendor pricing, raw vendor JSON, voice cloning, lyrics with Hero PII unless explicitly consented for that provider.

### 4.3 New: lab orchestration (application)

```text
RunExperienceLabUseCase / GenerateLabExperienceUseCase
  inputs: storyId, ExperienceLabProviderConfig, consent checks, forceRegenerate flags
  steps:
    1. load Story + reading + plan (require existing; do not auto-create Story)
    2. optionally regenerate plan with creative provider override
    3. generate voice (if configured) via VoiceRenderingPort
    4. generate music via MusicGenerationPort
    5. build ExperienceRenderManifest from plan + assets + timing policy
    6. persist ExperienceLabRun + usage records
    7. return lab run id for playback
```

Generation remains **explicit user action**. Never on Story save.

### 4.4 New: usage / cost port (infrastructure-facing)

```text
ProviderUsageRecorder.record(ProviderUsageEvent)
  - experimentId / labRunId
  - provider, model, operation
  - inputUnits, outputUnits, unitKind
  - latencyMs, requestId, generationId
  - estimatedCostUsd? (computed in infra from config tables — not domain)
```

Domain may store opaque usage facts; **pricing tables live in infrastructure/config**.

---

## 5. Provider adapter strategy

### 5.1 Pattern (matches existing)

```text
Flutter Use Case
  → Domain Port
  → Proxy*Adapter (EH HTTP contract)
  → services/ai_proxy handler
  → Provider Client (OpenAI / MiniMax / Qwen / Stable Audio / Mubert / …)
```

Flutter never holds vendor keys. Proxy normalizes to EH JSON.

### 5.2 Creative direction adapters

| Adapter | Maps to |
|---------|---------|
| Existing OpenAI chat client | Keep for Experiment A/C creative |
| New MiniMax chat/completions client | Experiment B creative (MiniMax-M2.7 / M3) |

Both must emit **the same EH experience-plan JSON schema**. Invalid/ungrounded output is rejected (existing HS.12.4 validation).

### 5.3 Voice adapters

| Adapter | Notes for lab |
|---------|----------------|
| OpenAI TTS (`tts-1` today; evaluate `gpt-4o-mini-tts`) | Steerable instructions on gpt-4o-mini-tts; keep syntheticNarration only |
| MiniMax T2A (`speech-2.8-turbo` / `hd`) | Expressive narration candidate; **do not enable Rapid Voice Cloning** |
| Qwen3-TTS / Alibaba Model Studio | Cost-efficient comparison voice; English quality is an **assumption requiring prototype** |

### 5.4 Music adapters

| Adapter | Lab suitability |
|---------|-----------------|
| Stable Audio 3.0 (Stability API) | **Primary first-demo candidate** — public API, up to ~6 min, ~$0.26/gen |
| Mubert API | Strong BPM/mood controls; subscription licensing; good Plan B |
| MiniMax Music API | **Blocked for new accounts** as of 2026-08-20 (see §11) |
| Suno | **No public self-serve API** — defer; do not use unofficial wrappers |

### 5.5 In-memory fakes

Every new port gets an in-memory adapter returning deterministic bytes/metadata so Flutter tests never need live vendors.

---

## 6. AI proxy changes

### 6.1 Config expansion

Today: single `OPENAI_API_KEY` + models. Lab needs:

| Env / config | Purpose |
|--------------|---------|
| `OPENAI_*` (existing) | Creative + TTS baseline |
| `MINIMAX_API_KEY` / base URL | Creative + TTS (if enabled) |
| `QWEN_*` / Alibaba Model Studio keys | TTS comparison |
| `STABILITY_API_KEY` | Music generation |
| `MUBERT_*` license tokens | Music Plan B |
| Per-capability default provider ids | Server defaults when request omits hint |
| Pricing table JSON/YAML (infra only) | Cost estimation |

### 6.2 New / extended routes

| Route | Change |
|-------|--------|
| `POST /story-experience-plans` | Accept optional `provider` / `model` lab hints; record usage |
| `POST /story-voice-renderings` | Same; multi TTS backends |
| **`POST /story-music-generations`** (new) | EH music contract → music provider client(s) |
| **`POST /experience-lab-runs`** (optional) | Server-side orchestration for latency comparison; **or** keep orchestration in Flutter use case calling existing routes |

**Recommendation for first demo:** Keep orchestration in the Flutter/application use case (mirrors HS.12), add music route, extend existing routes with provider hints + usage headers/fields. Avoid a monolithic “do everything” proxy endpoint.

### 6.3 Response provenance enrichment

Add (non-breaking, optional fields):

- `providerLabel`, `modelLabel` (already partly present)
- `requestId`, `generationId` (when vendor provides)
- `latencyMs`
- `usage { inputUnits, outputUnits, unitKind }`
- **Do not** put USD cost in domain-facing contract as a required field; estimate client-side in lab reporting from infra tables

### 6.4 Auth

Keep `EH_AI_PROXY_AUTH_TOKEN`. Lab keys never ship to the client.

---

## 7. Domain / application changes

### 7.1 Domain (minimal)

- **No mutation** of `Story`, transcript bytes, reading, or plan schema required for Phase 1 music/voice comparison.
- Optional small extensions:
  - Opaque `providerLabel` / `modelLabel` already exist on drafts — keep.
  - New VO: `MusicRendering` (derived artifact, Story-keyed, plan-id provenance) — analogous to `StoryVoiceRendering`.
  - New VO: `ExperienceLabRun` (experiment metadata + references to plan/voice/music/manifest versions).
- **Do not** add psychological fields, speech-BPM=music-BPM fields, or music asset ids onto `StoryExperiencePlan`.

### 7.2 Narrative tempo vs musical tempo

Represent in **render manifest / section briefs**, not as a single BPM on the plan:

```text
NarrativeSectionBrief (application / lab)
  - sectionId / purpose (opening…closing — player vocabulary)
  - durationHint
  - narrativeIntensity (0–1 or closed enum: low|medium|high)
  - speechPacing (calm|measured|urgent) — TTS instruction only
  - musicMood / musicIntensity
  - targetMusicBpm? (optional)
  - transition (cut|fade|dip-to-silence)
```

**Rule:** Speech pacing ≠ musical BPM. They may correlate artistically but must remain separate controls.

Where it lives for v1:

- Briefs derived by deterministic mapper from `StoryExperiencePlan` + reading + recording duration (application), optionally refined by creative provider structured output that is validated and **not** written onto the canonical plan unless a future ADR expands plan schema.
- First demo: derive briefs locally from existing plan purposes; do not require a second AI call.

### 7.3 Application

- `GenerateMusicRenderingUseCase` (consent + ownership + plan required)
- `RunExperienceLabUseCase` (orchestrates comparison run)
- Extend `StoryExperienceTimelineBuilder` **or** add `ExperienceRenderManifestBuilder` that can:

  - attach generated music section cues
  - optionally prefer narrated voice bytes when lab run requests it
  - preserve fallback to demo stems if music missing

- Extend experience playback controller to load lab run manifest without breaking demo-stem path

### 7.4 Music strategy recommendation (first demo)

| Strategy | Verdict |
|----------|---------|
| **A — One generated soundtrack** | **Recommended for first demo** |
| **B — Section-based multi-track** | Defer to Phase 2 after single-track proves value |

**Why A for demo:** Lower latency/cost, simpler sync (duck under speech, rise at silence/turning points), less transition engineering, easier reproducibility. Use plan purposes only to modulate **gain/intensity automation** over one track (and intentional silence), not to stitch six generative clips.

**Why not B yet:** Transition quality is the hard part; multiplies cost/failure modes; needs crossfades and section timing that the first demo can approximate with automation on one bed.

---

## 8. Persistence changes

### 8.1 New repositories (lab-scoped)

| Artifact | Persist | Notes |
|----------|---------|-------|
| `MusicRendering` | Yes | Media via `StoryMediaStoragePort`; metadata via repo |
| `ExperienceLabRun` | Yes | Config fingerprint, asset ids, timestamps, versions |
| `ProviderUsageEvent` | Yes (lab) | Append-only; not on Story |
| `ExperienceRenderManifest` | Yes (with lab run) | Enough to reproduce playback without regenerating |

### 8.2 Must never persist as Story mutations

- Generated narration as “the” story audio
- Generated music as Story canonical media
- Provider rankings / quality scores
- Psychological inferences

### 8.3 Caching / reuse

- Same `(storyId, planVersion, providerConfigHash, promptVersion)` → reuse assets unless `forceRegenerate`
- Play paths load persisted bytes only (same rule as HS.12.6 voice)

### 8.4 Platform note

Web persistence remains fragile (known HS.10/HS.12 issue). Lab demos should prefer **native** or durable storage for stakeholder playback.

---

## 9. UI changes (additive)

On `HeroStoryScreen` (or a clearly labeled Lab section / debug screen behind a flag):

1. **Provider lab panel** (dev/demo flag): choose Experiment A/B/C presets + advanced overrides.
2. **Generate lab experience** (explicit CTA) — shows consent checklist first.
3. **Play lab experience** — distinct from “Play my experience” (demo stems) until a future product decision merges them.
4. **Lab run summary**: latency, estimated cost, providers used, regenerate buttons per capability.
5. Preserve existing CTAs unchanged.

Do **not** replace “Play my experience” semantics in the first phase.

Optional later: when a lab run is marked “preferred,” allow “Play my experience” to use that manifest — **product decision, not Phase 1**.

---

## 10. Audio composition approach

### 10.1 Options

| Approach | Fit |
|----------|-----|
| Client-side mix (just_audio multi-player) | Matches HS.12 player; pause/resume/seek already conceptualized; good for demo |
| Server final mixdown | Better for sharing/export; worse for iteration latency; licensing/storage complexity |
| Hybrid | Server generates assets; client composes — **recommended** |

### 10.2 Recommendation for first demo: **Hybrid**

- Proxy generates narration + music assets.
- Flutter `StoryExperiencePlayer` (or lab subclass) plays:
  - Track A: original recording **or** narrated voice (lab toggle; default keep Hero voice as primary story signal)
  - Track B: generated music with gain automation from timeline cues
  - Silence gaps remain presentation-only (HS-ADR-075)
- No destructive rewrite of original bytes.
- Optional future: export mixed MP3 for sharing (separate consent).

### 10.3 Demo playback defaults

For the compelling demo:

- **Primary story signal:** Hero’s original recording (identity)
- **Optional layer:** short AI narration intros/outros **or** full narrated alternate mode (already exists separately)
- **Music:** one instrumental bed, intensity rises at challenge/turning-point cues, resolves at closing
- Avoid drowning speech; duck music under voice (−12 to −18 dB starting point; tune in lab)

---

## 11. Provider research findings

Evidence classes used below:

- **Verified** — from official docs/pricing pages retrieved for this plan (2026-09-25)
- **Architectural inference** — EH design choice
- **Assumption / needs prototype** — must be validated in lab

### 11.1 OpenAI

| Item | Status |
|------|--------|
| Chat structured JSON for plan/reading | **Verified in-repo** (current proxy) |
| TTS `tts-1` / `tts-1-hd` | **Verified in-repo**; char-based pricing commonly cited ~$15/$30 per 1M chars |
| `gpt-4o-mini-tts` | **Verified** on OpenAI model docs: steerable `instructions`; input $0.60 / audio output $12 per 1M tokens; 2000 input token cap |
| Latency | **Assumption** — measure in lab |
| Data handling | Customer content used per OpenAI API data policies — **must review current policy before sending Hero stories**; do not assume training opt-out without confirmation |

### 11.2 MiniMax

| Item | Status |
|------|--------|
| LLM MiniMax-M2.7 / M3 pricing | **Verified** paygo docs (e.g. M2.7 ~$0.3/$1.2 per M tokens standard) |
| TTS speech-2.8-turbo / hd | **Verified** ~$60 / $100 per M characters; T2A HTTP `/v1/t2a_v2` |
| Music API for **new** users | **Verified blocker:** as of **2026-08-20**, paid Music Generation APIs unavailable to new users; free music APIs discontinued; existing paying users may continue |
| Voice cloning APIs | Exist (**do not use** in EH lab) |
| Geographic/access | **Assumption** — confirm account eligibility from EH operating region |
| Licensing / data handling | **Needs legal review** before production; lab use still requires disclosure |

**Implication:** Experiments that assumed MiniMax Music (A/B as originally sketched) must **swap music provider**. MiniMax remains viable for **creative + TTS**, not for new-account music.

### 11.3 Qwen / Alibaba Cloud Model Studio

| Item | Status |
|------|--------|
| Qwen3-TTS Flash pricing | **Verified** ~$0.10 / 10k characters (International) on Model Studio docs |
| English narration quality | **Assumption / needs prototype** |
| Open-weight Apache 2.0 models | **Verified** for self-host path — out of scope for first cloud-proxy demo |
| Voice cloning features | Present in ecosystem — **explicitly disallowed** in EH lab |
| Data residency / commercial terms | **Needs legal review** |

### 11.4 Mubert

| Item | Status |
|------|--------|
| Public B2B API with BPM/mood/prompt | **Verified** (docs + OpenAPI) |
| Commercial licensing | **Verified** paid tiers; free/non-commercial restrictions on lower tiers |
| Pricing | **Verified** subscription-style from ~$49/mo entry (plan limits apply) — not pure PAYG |
| Fit | Strong for controllable beds; good lab Plan B / continuity music |

### 11.5 Stable Audio (Stability AI)

| Item | Status |
|------|--------|
| API text-to-audio | **Verified** |
| Duration | **Verified** SA 3.0 up to ~6 min; SA 2.5 up to 3 min |
| Pricing | **Verified** 26 credits ($0.26) per SA 3.0 success; 20 credits ($0.20) per 2.5 |
| Licensing | Community vs Enterprise by revenue — **needs EH legal check** before shipping user-facing music |
| Fit | **Best first-demo music provider** among researched options |

### 11.6 Suno

| Item | Status |
|------|--------|
| Public self-serve API | **Verified absent** (mid-2026); partner exploration only |
| Unofficial wrappers | **Rejected** for EH (ToS/reliability) |
| Fit | Watch-list only |

### 11.7 Revised experiment matrix

| Experiment | Creative | TTS | Music |
|------------|----------|-----|-------|
| **A** | OpenAI | OpenAI (`gpt-4o-mini-tts` preferred for steerability) | **Stable Audio 3.0** |
| **B** | MiniMax | MiniMax speech-2.8-turbo | **Stable Audio 3.0** (same music baseline) |
| **C** | OpenAI | Qwen3-TTS | **Stable Audio 3.0** |
| **D (optional)** | OpenAI | OpenAI | **Mubert** (BPM-controlled bed) |
| **E (future)** | *any* | *any* | MiniMax Music **only if** account grandfathered / policy changes |

Keeping music constant across A–C isolates voice+creative differences. Experiment D isolates music provider differences.

---

## 12. Cost model

### 12.1 Principles

- Record **usage facts** at infrastructure boundary.
- Estimate USD via **versioned pricing tables** in proxy/config — never hard-code vendor prices in domain objects.
- Answer: “How much did lab run X cost?” from summed `ProviderUsageEvent` estimates + table version.

### 12.2 Rough demo budget (illustrative, not guarantees)

Assume ~90s story, ~1200–2000 transcript characters, one plan, one TTS pass, one ~90–120s music bed:

| Operation | Order-of-magnitude |
|-----------|--------------------|
| Plan/reading LLM (gpt-4o-mini class) | cents or less |
| OpenAI TTS (short narration) | cents |
| MiniMax TTS | often higher $/char than OpenAI — measure |
| Qwen3-TTS | often lower $/char — measure |
| Stable Audio 3.0 | ~$0.26 per successful generation |
| Mubert | amortized subscription |

**Lab KPI:** cost per successful end-to-end experience; cost per regenerate; failure waste rate.

### 12.3 Instrumentation fields

`provider, model, operation, inputUnits, outputUnits, unitKind, durationMs, latencyMs, requestId, generationId, pricingTableVersion, estimatedCostUsd?`

---

## 13. Security / privacy / consent

### 13.1 Existing consent (preserve)

`StoryConsent`: recorded / processing / publication / AI transformation / **voiceRendering** (independent).

Do **not** let processing or AI transformation consent unlock voice or music generation.

### 13.2 Additional lab disclosures (recommended)

Before any lab generation that sends story content off-device:

1. **External processing disclosure** naming categories of providers (creative / TTS / music) and that content leaves EH infrastructure.
2. **Music generation consent** — new timestamp field *or* reuse a broader `aiPresentationApprovedAt` **only if** ADR explicitly scopes it; prefer **separate** `musicGenerationApprovedAt` to mirror voice independence.
3. Reminder: generated audio is presentation, not the Story.
4. No voice cloning; synthetic voices only.
5. Lab retention policy: how long generated assets/usage logs are kept.

### 13.3 Hard rules

- No unauthorized voice cloning / celebrity voices / impersonation.
- Credentials server-side only.
- No silent auto-send on save/open.
- Provider failures isolated; never delete original recording path.
- Legal review of each vendor’s training/retention terms before non-employee Heroes use the lab.

---

## 14. Testing strategy

### 14.1 Unit

- Manifest builder timing / intensity cues
- Section brief derivation from plan (speech pacing ≠ BPM)
- Music section mapping (single-bed automation)
- Cost estimator given usage + pricing table
- Consent gates for music/lab
- Provider hint parsing (ignore unknown safely)

### 14.2 Contract

- Each proxy handler with fake provider clients (extend `ai_proxy_test.dart`)
- Parser rejects psychological keys / malformed music responses
- Flutter proxy adapters with `MockClient`

### 14.3 Integration

- Proxy → Stable Audio / MiniMax / Qwen **behind feature flags** in CI (optional nightly; secrets required)
- Default CI uses fakes only

### 14.4 Golden / snapshot

- Canonical EH JSON for experience plan (existing)
- Golden JSON for `ExperienceRenderManifest` structure (no audio bytes)

### 14.5 Audio

Validate **metadata**, not brittle waveforms:

- duration within tolerance
- content-type
- non-empty bytes
- cue timestamps monotonic
- ducking gain breakpoints

Optional: hash of synthetic in-memory adapter output only.

### 14.6 Failure

- provider 401/429/5xx
- timeout
- malformed structured output
- music generation failure with voice success (partial lab run)
- TTS failure leaving music-only / stems fallback
- expired credentials
- rate limits
- missing consent
- plan/reading missing

### 14.7 Regression

- HS.12 paths: recording / demo experience / narrated version still pass focused suites
- `dart analyze` clean
- architecture boundary test still forbids SDKs in domain/application

---

## 15. ADRs (recommended)

Create only durable decisions. Suggested new ADRs (numbers illustrative; assign next free HS-ADR ids — note **HS-ADR-074 is currently unused**):

| Proposed ADR | Decision |
|--------------|----------|
| **AI Presentation Artifacts Remain Non-Canonical** (reaffirm/extend 073/076) | Music + lab runs are derived; never mutate Story |
| **Music Rendering Is a Derived Presentation Artifact** | Analogous to voice; separate consent |
| **Experience Lab Runs Are Experiment Records, Not Product Rankings** | No domain winner scores |
| **Provider Selection Is Request/Config Metadata Behind Ports** | Ports stay EH-owned; vendors behind proxy |
| **Narrative Pacing and Musical Tempo Are Distinct Controls** | Do not equate speech BPM to music BPM |
| **External AI Data Handling for Presentation Generation** | Disclosure + consent + retention |

**Do not** ADR: temporary experiment presets, specific Stable Audio vs Mubert winner, UI copy.

Update docs only as needed: pointer from `HS.12-AI-Hero-Story-Demo-Plan.md` to this lab plan; avoid rewriting stale maps unless required for clarity.

---

## 16. Incremental implementation phases

### Phase 0 — Prep (no product UI)

- Confirm Stable Audio + (optional) Mubert account/licensing
- Confirm MiniMax/Qwen account access from EH environment
- Draft consent copy
- Add ADR stubs for music + lab runs

### Phase 1 — Music port + Stable Audio (vertical slice)

- `MusicGenerationPort` + in-memory + proxy adapter
- `POST /story-music-generations`
- `MusicRendering` persistence
- Player: play original + **one** generated bed with simple gain curve from existing timeline purposes
- Keep demo stems path intact
- Tests + analyze

**Validation gate G1:** One story → generate music → play alongside original without breaking HS.12.

### Phase 2 — Lab run + cost instrumentation

- `ExperienceLabRun` + usage recorder + pricing tables
- Provider hints on plan/voice/music routes
- Lab panel UI (flagged)
- Reproducibility fields

**Gate G2:** Same story regenerated with identical config reuses assets; cost estimate visible.

### Phase 3 — Multi TTS providers

- MiniMax + Qwen voice clients behind `VoiceRenderingPort`
- Experiments A/B/C (music fixed to Stable Audio)
- Optional wire `presentationVoiceBytes` into **lab** player only

**Gate G3:** Three voice providers produce playable artifacts; failures isolated.

### Phase 4 — Creative provider comparison

- MiniMax creative client for plan generation
- Same EH schema validation
- Compare controllability/latency/cost (human review checklist — no domain scores)

**Gate G4:** Plan schema parity across OpenAI/MiniMax; grounded spans still enforced.

### Phase 5 — Music provider B (Mubert) + optional section automation polish

- Mubert adapter
- Experiment D
- Improve intensity automation / ducking
- Still single-bed strategy unless data demands sections

**Gate G5:** Music provider swappable without Flutter contract changes.

### Phase 6 — Demo hardening (still pre-production)

- Consent UX finalized
- Caching, partial failure UX
- Native demo script for stakeholders
- Decide whether lab playback graduates into default “Play my experience”

---

## 17. Validation gates (summary)

| Gate | Criteria |
|------|----------|
| G0 | ADRs drafted; vendor accounts feasible; MiniMax music non-dependency acknowledged |
| G1 | Music + original playback works; Story unchanged |
| G2 | Lab run reproducible; cost measurable |
| G3 | Multi-TTS behind one port |
| G4 | Multi-creative behind one plan contract |
| G5 | Multi-music behind one music port |
| G-HS12 | Recording / demo experience / narrated paths still green |

---

## 18. Risks and open questions

### Risks

1. **MiniMax Music unavailable to new users** — original Experiment A/B music assumption invalid.
2. **Vendor data-training policies** — may block real Hero content until legal clears.
3. **English quality variance** (Qwen TTS, MiniMax voices) — must prototype.
4. **Licensing** for Stable Audio / Mubert in a consumer app (enterprise thresholds).
5. **Client-side sync drift** on low-end devices.
6. **Cost blowups** from regenerate loops without cache.
7. **Scope creep** into Discovery/personalization/evidence.
8. **Doc drift** if early HS.12 draft fields are reintroduced onto the plan.

### Open questions (stop / decide before coding if blocking)

1. Should lab playback ever replace demo-stem “Play my experience,” or stay a parallel CTA?
2. New consent field `musicGenerationApprovedAt` vs broader presentation consent?
3. Is Hero-original-voice + music the default demo, or full AI narration + music?
4. Is Stability Enterprise license required for EH’s revenue stage?
5. Should orchestration live only in Flutter use cases or also as a proxy “lab run” route?
6. Retention period for generated assets and usage logs?

---

## 19. Recommended first demo

**Goal:** One real 60–90s Hero story becomes a composed experience that is obviously more than “play recording,” without rewriting the Story.

### Script

1. Hero records 60–90s story (existing capture).
2. Grants processing + AI + **voice (if used)** + **music/lab** consents.
3. Understand my story → transcript + `CapturedStoryReading`.
4. Create my experience → `StoryExperiencePlan` (OpenAI creative for Demo v1).
5. **Generate lab experience (Experiment A):**
   - Creative: existing plan (or regenerate with OpenAI)
   - Music: Stable Audio 3.0 instrumental bed from `musicDirection` + arc
   - Voice: optional short synthetic intro/outro **or** skip and keep Hero voice primary
6. Hero presses **Play lab experience**.
7. Playback: Hero recording + music bed with build at turning point + intentional silence + resolve.
8. Side-by-side: Play my recording / Play my experience (stems) / Play lab experience.

### Success — technical

- Story/transcript/reading/plan bytes unchanged by generation
- Artifacts traceable (`labRunId`, provider/model, asset ids)
- Providers replaceable at proxy without domain rewrite
- Run reproducible from persisted manifest
- Provider failures isolated; HS.12 paths intact
- Cost estimate available for the run
- Sync deterministic for a given manifest
- No psychological fields; no voice cloning; credentials server-side
- Assets cached/reusable

### Success — qualitative (checklist, no numeric provider scores)

- Narration (if used) feels natural
- Music supports rather than competes
- Music intensity changes at meaningful moments
- Experience feels composed
- Hero still recognizes their story
- Presentation adds value without changing the story

---

## 20. Explicitly do **not** implement yet

- Replace OpenAI everywhere
- Commit EH to MiniMax / Mubert / Qwen / Stable Audio as permanent production vendors
- MiniMax Music dependency for new accounts
- Suno (no public API) / unofficial Suno wrappers
- Voice cloning / hero voice marketplace
- Psychological inference / behavioral evidence from story presentation
- Mutating canonical Story / transcript / approved narrative via AI presentation
- Auto-generation on Story save/open
- Sending content to vendors without explicit consent/disclosure
- Removing or rewiring HS.12 demo-stem / narrated / original paths as breaking changes
- Giant generalized “AI service” replacing capability ports
- Production personalization engine / Discovery → Experience Candidate architecture
- Domain `ExperienceComposition` aggregate as a twin of `StoryExperiencePlan`
- Section-stitched multi-clip generative soundtracks (Strategy B) in Phase 1
- Server-side final mix as the only playback path
- Permanent provider “winner” scores in domain
- Broad architecture-map rewrites unrelated to this lab
- Production social feed / community distribution of lab audio

---

## Appendix A — Suggested type sketch (non-normative)

```text
ExperienceLabProviderConfig
  creativeProvider / creativeModel
  voiceProvider / voiceModel / voiceId?
  musicProvider / musicModel
  promptVersions { plan, voice, music }
  pricingTableVersion

ExperienceLabRun
  id, storyId, experimentPresetId?
  config: ExperienceLabProviderConfig
  experiencePlanId + planProcessingVersion
  voiceRenderingId?
  musicRenderingId?
  renderManifestId
  createdAt
  status: succeeded | partial | failed
  errorSummary?

ExperienceRenderManifest
  recordingRole: original | narrated | originalPlusNarrationBeds
  voiceAssetRef?
  musicAssetRefs[]
  cues[] { at, purpose, musicGainDb, silence, transition }
  builtFromPlanVersion
  builderVersion

MusicRendering
  id, storyId, experiencePlanId, planProcessingVersion
  mediaReference, contentType, byteLength, duration
  providerLabel, modelLabel, generationId?
  promptDigest, processingVersion, createdAt
```

## Appendix B — Mapping to requested conceptual pipeline

| Requested concept | EH mapping |
|-------------------|------------|
| CapturedStoryReading | Existing VO/port |
| AI Creative Director | `StoryExperiencePlannerPort` (+ multi-provider proxy) |
| Experience Composition | `ExperienceRenderManifest` + player (not new domain twin) |
| Voice Provider | `VoiceRenderingPort` |
| Music Provider | `MusicGenerationPort` (new) |
| EH Audio Composition / Playback | Extended `StoryExperiencePlayer` (hybrid) |
| Hero Experience | Lab playback CTA → future product playback |

---

## Appendix C — Sources consulted (provider research)

- OpenAI GPT-4o Mini TTS model page (`developers.openai.com`)
- MiniMax Pay as You Go pricing (`platform.minimax.io/docs/guides/pricing-paygo`) — includes Music API new-user discontinuation notice effective 2026-08-20
- Alibaba Cloud Model Studio TTS / qwen3-tts-flash pricing pages
- Stability AI Developer Platform pricing (`platform.stability.ai/pricing`)
- Mubert API docs / commercial plans
- Public reporting on Suno developer API partner exploration (no public self-serve API as of mid-2026)
- In-repo HS-ADR-072/073/075/076 and HS.12 implementation

Pricing and availability change; re-verify at implementation time.

---

**End of plan. No code was modified for implementation.**
