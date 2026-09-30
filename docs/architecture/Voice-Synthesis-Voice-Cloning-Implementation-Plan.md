# EH Voice Synthesis & Voice Cloning — Implementation Plan

**Status:** M1 (provider-neutral synthetic narration contract) implemented — see HS-ADR-077; **HS.12.7 TTS provider spike complete** — see `HS.12.7-TTS-Provider-Benchmark.md`; **HS.12.8 Voice Identity & Cloning architecture spike complete** — see HS-ADR-078 / `HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md` (no production cloning)  
**Date:** 2026-09-30  
**Audience:** Andy / architecture review  
**Related:** HS-ADR-076, HS-ADR-077, HS-ADR-078, HS.12.6, HS.12.7, HS.12.8, AI Experience Provider Laboratory Plan, HS.1 Foundation

---

## 1. Executive summary

Everyone’s Heroes already has a **provider-neutral Story voice-rendering boundary**. HS.12.6 shipped:

```text
RenderStoryVoiceUseCase
  → VoiceRenderingPort
  → ProxyVoiceRenderingAdapter
  → POST /story-voice-renderings (services/ai_proxy)
  → OpenAI TTS (server-side)
  → StoryVoiceRendering + StoryMediaStoragePort bytes
```

That path is ordinary **synthetic narration** only. Modes `heroVoiceTransformation` and `voiceClone` exist on `VoiceRenderingMode` but are rejected by use case, adapter, and proxy. There is **no** `VoiceProfile`, no cloning consent gate, and no non-OpenAI TTS client.

**Recommendation:** Do **not** invent a parallel `StoryNarrationPort` / `VoiceSynthesisPort` / `POST /voice-clone` product surface. Extend the existing **`VoiceRenderingPort` + `POST /story-voice-renderings`** capability for narration, and introduce a **separate consent-based Voice Profile capability** (new port + proxy route) only when cloning is authorized.

Conceptual target:

```text
                    Story (canonical narrative)
                      │
                      ▼
             RenderStoryVoiceUseCase
                      │
                      ▼
              VoiceRenderingPort
                      │
          ┌───────────┼────────────┐
          │           │            │
          ▼           ▼            ▼
      OpenAI TTS  ElevenLabs   Qwen3 / CosyVoice
          │           │            │
          └───────────┼────────────┘
                      ▼
            StoryVoiceRendering
                      │
                      ▼
            StoryMediaStoragePort
```

Separately (never as a side effect of narration):

```text
Create Voice Profile (explicit consent)
  → VoiceProfilePort
  → EH AI Proxy
  → Provider clone API / local clone
  → Reusable VoiceProfileId
```

Domain/application must never depend on ElevenLabs, Qwen, CosyVoice, HTTP, OpenAI SDKs, or Python. Vendor selection stays in `services/ai_proxy` (+ optional local inference sidecar).

**First implementation milestone:** provider-pluggable **synthetic narration** behind the existing port/proxy (V1–V4), with a local-model feasibility spike (V2) before committing to production cloning (V5).

---

## 2. Current architecture findings

### 2.1 Repository reality (authoritative)

| Concept | Actual location | Notes |
|---------|-----------------|-------|
| Hero & Story package | `lib/features/hero_story/{domain,application,infrastructure,presentation}/` | ~523 Dart files; hexagonal layers |
| Story aggregate | `domain/aggregates/story.dart` | Owns narrative, lifecycle, visibility, classification, consent, representations |
| StoryRepresentation | `domain/entities/story_representation.dart` | language, format, origin, mediaReference?, textContent?, AI approval |
| Media | `MediaReference` + `StoryMediaStoragePort` | Opaque URI; bytes outside Story |
| Capture (HS.9) | `DeviceRecordingPort` → `CompleteStoryCaptureUseCase` | Original audio as `StoryRepresentation(format: audio)` |
| Persistence/UI (HS.10) | Owned My Stories / detail / playback | Original media via storage port |
| Transcription (HS.11) | `StoryTranscriptionPort` → proxy STT | Derived transcript representation |
| Captured reading (HS.12.3) | `CapturedStoryReading` + port/repo | Separate from Story |
| Experience plan (HS.12.4) | `StoryExperiencePlan` + port/repo | Separate from Story |
| Voice rendering (HS.12.6) | `VoiceRenderingPort`, `StoryVoiceRendering`, `RenderStoryVoiceUseCase` | Separate derived VO; **not** on `Story.representations` |
| AI proxy | `services/ai_proxy` | Shelf Dart; bearer auth; OpenAI + Stability clients |
| Platform | `services/eh_platform` | Future AI absorb; **not** live TTS path |

### 2.2 Story ≠ Media (already enforced)

HS.1 and HS-ADR-002/076 are reflected in code:

- Canonical Story is narrative + lifecycle + consent + classification.
- Original recording is a representation with `MediaReference`.
- AI voice is a **derived presentation artifact** (`StoryVoiceRendering`), not Story identity.
- Playback of narrated audio uses **persisted bytes**; Play never calls AI.

### 2.3 Important contradiction (doc vs code)

| Source | Claim |
|--------|-------|
| Early HS.12 plan §G / proposed ADR-074 | Voice cloning → derived **`StoryRepresentation`** + `voiceCloningApprovedAt` |
| **HS-ADR-076 + shipped HS.12.6** | Synthetic voice → separate **`StoryVoiceRendering`** + `voiceRenderingApprovedAt` |
| ADR numbering | Proposed ADR-074 was **never accepted**; file jumps 073 → 075 → 076 |

**Plan rule:** Treat **HS-ADR-076 + code** as current law. Treat HS.12 §G as historical sketch. Any cloning/Representation decision requires a **new ADR**.

### 2.4 Dependency boundaries (current)

- Domain imports only `core/*` and `hero_story/domain/*`.
- Architecture test `test/features/hero_story/architecture/ai_boundary_test.dart` forbids OpenAI/HTTP in domain/application.
- Flutter adapters talk only to EH-owned proxy JSON contracts.
- Vendor credentials live in proxy env (`OPENAI_API_KEY`, `STABILITY_API_KEY`); Flutter gets `EH_AI_PROXY_URL` + optional bearer via `--dart-define`.

### 2.5 Eventing note

`RenderStoryVoiceUseCase` intentionally does **not** publish domain events. Voice rendering is a presentation artifact, not behavioral evidence. Do not invent `StoryVoiceRendered` unless a future reactor has a real consumer.

### 2.6 Related plan already on disk

`docs/architecture/AI-Experience-Provider-Laboratory-Plan.md` already recommends multi-provider TTS behind `VoiceRenderingPort`, rejects cloning in lab v1, and proposes proxy provider hints. This Voice Synthesis / Cloning plan **aligns with that lab direction** for narration, and **goes further** on consent-based Voice Profiles when cloning is authorized.

---

## 3. Relevant existing code / components

### Domain

| Component | Path |
|-----------|------|
| `VoiceRenderingPort` / Request / Draft | `lib/features/hero_story/domain/services/voice_rendering_port.dart` |
| `StoryVoiceRendering` | `lib/features/hero_story/domain/value_objects/story_voice_rendering.dart` |
| `VoiceRenderingMode` | `lib/features/hero_story/domain/enums/voice_rendering_mode.dart` |
| `StoryConsent` (+ `voiceRenderingApprovedAt`) | `lib/features/hero_story/domain/value_objects/story_consent.dart` |
| `StoryMediaStoragePort` | `lib/features/hero_story/domain/services/story_media_storage_port.dart` |
| `StoryRepresentation` / formats / provenance steps | `domain/entities/`, `domain/enums/` |
| `StoryVoiceRenderingRepository` | `domain/repositories/story_voice_rendering_repository.dart` |
| `StoryTransformationType.narration` | Exists; used for Story provenance steps — **not** currently raised by HS.12.6 voice path |

### Application

| Component | Path |
|-----------|------|
| `RenderStoryVoiceUseCase` | `application/use_cases/render_story_voice_use_case.dart` |
| DTOs | `application/dto/requests|responses/render_story_voice_*` |
| Providers | `application/providers/ai/voice_rendering_port_provider.dart`, use-case + repository providers |
| Capture / playback | `DeviceRecordingPort`, `OriginalRecordingPlayer`, `StoryExperiencePlayer` |

### Infrastructure / proxy

| Component | Path |
|-----------|------|
| `ProxyVoiceRenderingAdapter` | `infrastructure/ai/proxy_voice_rendering_adapter.dart` |
| `InMemoryVoiceRenderingAdapter` | `infrastructure/ai/in_memory_voice_rendering_adapter.dart` |
| File / in-memory voice repos | `infrastructure/persistence/`, `infrastructure/repositories/` |
| `StoryVoiceRenderingHandler` | `services/ai_proxy/lib/src/story_voice_rendering_handler.dart` |
| `OpenAiSpeechClient` | `services/ai_proxy/lib/src/openai_speech_client.dart` |
| `ProxyConfig` | `services/ai_proxy/lib/src/proxy_config.dart` |

### Presentation / tests

| Component | Path |
|-----------|------|
| Voice UI controller / view data | `presentation/providers/hero_story_voice_rendering_controller.dart`, `presentation/models/story_voice_rendering_view_data.dart` |
| Focused tests | `test/features/hero_story/application/use_cases/hs12_6_voice_rendering_use_case_test.dart`, presentation + consent + proxy tests |

---

## 4. Architectural fit

Voice synthesis fits as an **experience-generation / presentation capability** inside Hero & Story:

| Layer question | Answer |
|----------------|--------|
| Is TTS part of Story identity? | **No** — Story is the narrative |
| Is TTS cataloging? | **No** |
| Is TTS discovery? | **No** |
| Is TTS personalization? | **No** — personalization may *choose* to request narration later |
| Is TTS behavioral evidence? | **No** — never |
| Correct ownership | Hero & Story derived presentation (same family as reading / plan / music rendering) |

Fits the existing HS.12 pipeline:

```text
Capture → Transcript → Reading → Experience Plan → (optional) Voice Rendering → Playback of persisted bytes
```

Does **not** belong in Life Journey, Discovery aggregates, or Flutter widgets as business logic.

---

## 5. Recommended bounded-context placement

| Concern | Context | Placement |
|---------|---------|-----------|
| Story, representations, consent, media refs | Hero & Story | Existing |
| `VoiceRenderingPort`, `StoryVoiceRendering` | Hero & Story | Existing — extend |
| Voice Profile (reusable consented voice identity) | Hero & Story | **New** domain concept (when cloning authorized) |
| Provider clients, credentials, model routing | Infrastructure / `services/ai_proxy` | Extend; optional Python sidecar |
| NarrativeTheme ownership | Discovery | Unchanged; voice does not own themes |
| Personalization Engine | Future / outside this work | Consumes narration capability later |
| Behavioral evidence / patterns | Life Journey | Must not consume voice renderings |

Do **not** create a new bounded context for TTS.

---

## 6. Recommended application ports

### 6.1 Primary recommendation: extend `VoiceRenderingPort`

**Do not create** `VoiceSynthesisPort` or a parallel `StoryNarrationPort` for V1–V4.

Reasons:

1. The business capability is already named in EH vocabulary: **voice rendering** of a Story experience (HS-ADR-076).
2. Riverpod, use case, proxy route, persistence, UI, and tests already bind to this seam.
3. Creating a second narration port would duplicate contracts and invite drift (`StoryNarration` vs `VoiceRendering`).
4. The lab plan already chose this extension point.

**Optional rename later:** If product language prefers “narration,” that is a documentation/UI label change — not a new port — unless Andy explicitly wants a rename ADR.

### 6.2 Proposed contract evolution (still EH-owned)

Keep `VoiceRenderingPort.render(VoiceRenderingRequest) → VoiceRenderingDraft`.

Add **optional, provider-agnostic** request fields over time:

| Field | Purpose | Domain-safe? |
|-------|---------|--------------|
| `sourceText` | Script / transcript text (exists) | Yes |
| `renderingMode` | synthetic / hero transform / clone (exists) | Yes |
| `language` | Synthesized language (gap today) | Yes — add |
| `voiceProfileId` | EH voice identity (future) | Yes — opaque id |
| `speakingStyle` / delivery instructions | Style hints | Yes — EH enums/strings, not vendor IDs |
| `audioFormatHint` | e.g. `audio/mpeg` preference | Yes |
| `providerHint` / `modelHint` | Lab / infra selection | **Application/infra metadata only** — never required by domain invariants |

**Forbidden in domain request:**

- ElevenLabs `voice_id`
- OpenAI voice name as domain concept (today it is server env only — keep it that way unless mapped through VoiceProfile)
- Qwen/CosyVoice model checkpoint names as domain types
- Raw vendor JSON

### 6.3 Separate port for cloning: `VoiceProfilePort` (V5)

Cloning is **not** narration. Introduce when cloning is approved:

```text
VoiceProfilePort
  createFromSourceRecording(CreateVoiceProfileRequest) → VoiceProfileDraft
  delete(VoiceProfileId) → void
  // optional: describe / health / capability probe
```

Narration then references `VoiceProfileId` via `VoiceRenderingPort` with `renderingMode: voiceClone` (or a clearer future mode name).

Do **not** fold clone-creation into `POST /story-voice-renderings`.

### 6.4 Why not `GenerateStoryAudioPort`?

Too generic (music also generates audio). Music already has `MusicGenerationPort`. Keep capability-specific ports.

---

## 7. Recommended domain concepts

### 7.1 Keep (no redesign)

- `StoryVoiceRendering` as derived presentation VO
- `VoiceRenderingMode` with distinct modes
- `StoryConsent.voiceRenderingApprovedAt` for synthetic narration
- `StoryMediaStoragePort` for audio bytes
- Separate repositories for derived artifacts

### 7.2 Add only when needed

#### A. Language + provenance gaps on `StoryVoiceRendering` (V4)

Today the VO has **no `language` field** and no `voiceProfileId`. Multilingual HS.1 requires at least:

- `language` (synthesized language)
- optional `sourceRepresentationId` (already present)
- optional `voiceProfileId` (when cloning)
- retain `providerLabel` / `modelLabel` as opaque provenance strings (already present)

#### B. `VoiceProfile` (V5) — minimum viable model

Do **not** over-model V1. When cloning ships, prefer the smallest concept that supports ownership, consent, provenance, and provider remapping:

```text
VoiceProfile
├── VoiceProfileId
├── OwnerHeroId
├── DisplayName?                 # human label, not vendor id
├── LanguageCode                 # primary language of source sample
├── ConsentStatus                # granted / revoked (+ timestamps)
├── Lifecycle                    # draft | active | revoked | deleted
├── SourceRecordingRef           # MediaReference and/or StoryRepresentationId
├── ProviderBindings[]           # infrastructure mapping, not domain vendor logic
│     ├── providerKey            # opaque enum/string: "elevenlabs" | "qwen3" | …
│     └── providerReference      # opaque provider voice id / embedding handle
├── CreatedAt / UpdatedAt
└── Audit trail refs             # who granted, when, what was sent off-device
```

**Domain must treat `providerReference` as opaque.** Application maps `VoiceProfileId` → binding for the configured provider.

#### C. Consent

| Gate | Covers | Status |
|------|--------|--------|
| `voiceRenderingApprovedAt` | Synthetic narration | **Exists** |
| `voiceCloningApprovedAt` (or VoiceProfile-level consent) | Creating/using a cloned voice | **Missing — required before V5** |
| AI transformation consent | Transcription / reading / plan / authoring | Must **not** unlock cloning |
| Recording consent | Capture only | Must **not** unlock cloning |

**Recommendation:** Story-level `voiceCloningApprovedAt` *or* profile-level consent with Story-level “use cloned voice for this story” authorization. Prefer **profile-level ownership consent + explicit per-story use authorization** so one profile can serve many stories without implying marketplace impersonation.

Exact shape is an **open decision** (§22).

#### D. Do **not** put TTS into Story aggregate

Do not add provider fields onto `Story`. Do not auto-`addRepresentation` for every synthetic TTS unless a future ADR promotes selected narrations to approved `StoryRepresentation` (e.g. published localized narrated audio). Default remains `StoryVoiceRendering`.

---

## 8. Infrastructure adapter design

### 8.1 Flutter / app adapters

Continue dual mode:

| Mode | Adapter |
|------|---------|
| development / tests | `InMemoryVoiceRenderingAdapter` |
| proxy | `ProxyVoiceRenderingAdapter` |

Same pattern for future `VoiceProfilePort`.

### 8.2 Proxy provider strategy

Inside `services/ai_proxy`:

```text
StoryVoiceRenderingHandler
  → SpeechSynthesisRouter (new thin selector)
       ├── OpenAiSpeechClient          (exists)
       ├── ElevenLabsSpeechClient      (new)
       ├── LocalTtsClient              (HTTP to local sidecar)
       └── … future clients
```

Selection inputs (server-side precedence):

1. Request `providerHint` / `modelHint` (lab / explicit config) if allowed
2. Else env default (`EH_TTS_PROVIDER=openai|elevenlabs|qwen3|cosyvoice`)
3. Capability check against `renderingMode` (reject clone if provider lacks clone / consent headers missing)

### 8.3 Local / open models

Do **not** run ML inference inside Flutter or inside the Dart proxy process.

Preferred:

```text
ai_proxy (Dart)
  → HTTP to local inference sidecar (Python)
       → Qwen3-TTS and/or CosyVoice 3
```

Sidecar owns Python deps, weights, device selection (MPS/CUDA/CPU). Proxy owns EH auth, EH contracts, logging, and provider selection.

### 8.4 Config / env patterns to extend

Existing:

- Proxy: `OPENAI_*`, `STABILITY_*`, `EH_AI_PROXY_*`
- Flutter: `EH_AI_PROXY_URL`, `EH_AI_PROXY_AUTH_TOKEN`, `EH_TRANSCRIPTION_MODE` (also gates several HS.12 ports)

Proposed additions (proxy only for secrets):

| Variable | Role |
|----------|------|
| `EH_TTS_PROVIDER` | Default narration backend |
| `ELEVENLABS_API_KEY` | Hosted commercial TTS/clone |
| `ELEVENLABS_BASE_URL` | Optional |
| `EH_LOCAL_TTS_URL` | Sidecar base URL |
| `EH_LOCAL_TTS_PROVIDER` | `qwen3` / `cosyvoice` |
| `EH_TTS_ALLOW_PROVIDER_HINTS` | Lab flag |

**Constraint today:** `ProxyConfig.fromEnvironment` **requires** `OPENAI_API_KEY`. Local-only evaluation will need a config relaxation (e.g. require OpenAI only when selected) — open decision / small proxy change in V3.

### 8.5 Auth

Reuse existing bearer middleware (`EH_AI_PROXY_AUTH_TOKEN`). Do not put ElevenLabs/OpenAI keys in Flutter or `--dart-define`.

Known limitation (existing): Flutter Web bundles the proxy bearer token. Voice work should not worsen this; platform auth hardening remains separate debt.

---

## 9. AI proxy integration

### 9.1 Belong in existing `services/ai_proxy`?

**Yes.** Reasons:

- Same security boundary (credentials, consent audit, logging)
- Same Flutter → proxy → vendor pattern already used for STT, reading, plan, voice, music
- Avoids a second AI infrastructure path (explicit drift risk)
- `eh_platform` AI absorb is deferred; do not block on it

### 9.2 Endpoints

| Endpoint | Role |
|----------|------|
| **`POST /story-voice-renderings`** | **Keep** as narration capability (extend for multi-provider + optional `voiceProfileId` / language) |
| **`POST /voice-profiles`** (V5) | Create consented reusable voice identity |
| **`DELETE /voice-profiles/{id}`** (V5) | Revoke/delete + best-effort provider cleanup |
| `POST /voice-clone` | **Do not use** as primary product route — wrong capability name |

Optional lab-only: capability probe `GET /tts-capabilities` returning opaque provider feature flags (clone, stream, languages) — infrastructure only.

### 9.3 Transport

Keep Mode A JSON + base64 audio for V1–V4 (matches current contract). Streaming is deferred (§10).

---

## 10. Streaming vs generated-file architecture

| Mode | Fit for EH today |
|------|------------------|
| **A — Complete audio file** | **Recommended first.** Matches HS.12.6 persist-then-play, caching, offline, experience composition, mobile playback via `just_audio` |
| **B — Stream audio** | Useful later for long-form / low-latency preview; requires player + proxy redesign; not needed for first vertical slice |
| **C — Both** | Target end-state for long motivational talks; implement only after A is multi-provider stable |

**Decision for first slices:** Mode A only.

| Use case | First approach |
|----------|----------------|
| Hero Story narrated version | Complete file → `StoryVoiceRendering` |
| Motivational / personalized talks | Complete file (later composition) |
| Long-form narration | Chunked Mode A generation → concatenate, or later streaming |
| Offline / cache | Mode A required |
| Mobile playback | Persisted bytes via existing players |

---

## 11. Voice profile design

### 11.1 Separation of identities

| Layer | Concept | Example |
|-------|---------|---------|
| EH identity | `VoiceProfileId` | “Andrew’s approved narration voice” |
| Provider binding | `providerKey` + `providerReference` | `elevenlabs` + `abc123` |
| Local open model | May store embedding/handle or re-send reference audio each time | CosyVoice zero-shot often needs reference audio at synth time |

**Critical:** Some local models (Qwen3-TTS Base, CosyVoice zero-shot) are **reference-audio-at-synthesis** systems, not durable hosted voice IDs. VoiceProfile must support:

1. **Hosted durable voice id** (ElevenLabs IVC/PVC)
2. **Local reference-audio binding** (store `MediaReference` to consented sample; sidecar clones per narration or caches embedding)

Do not assume every provider yields a durable remote voice id.

### 11.2 Consent & lifecycle rules

- Creating a profile is an **explicit user action** with dedicated UI copy.
- Source recording provenance required (which media / which story representation).
- Revocation: mark revoked locally; attempt provider delete; **block** further narration with that profile.
- Deletion: remove local sample copies per retention policy; purge provider clone when API allows.
- Audit: record grant/revoke timestamps, owner, whether sample left device, provider key (not secret).
- Never create a profile as a side effect of “Create narrated version.”

### 11.3 Samples leaving the device

| Policy question | Recommendation |
|-----------------|----------------|
| Store samples locally? | Yes, under `StoryMediaStoragePort` with clear purpose tags |
| Send samples to third parties? | Only after cloning consent + disclosure naming the provider category |
| Provider retention? | Prefer providers/APIs with delete; document retention in consent copy; local models preferred when retention must stay on EH hardware |
| Celebrity / non-owner voices? | Out of scope; hard-reject |

---

## 12. Story Representation / media integration

### 12.1 Default (continue HS.12.6)

```text
Story
 └── representations[]          # original audio, transcript, …
StoryVoiceRendering (separate)  # TTS audio + provenance
MusicRendering (lab)            # separate
```

Playback: `OriginalRecordingPlayer` / experience player with optional presentation voice bytes.

### 12.2 When to promote to `StoryRepresentation`

Consider `addRepresentation(format: audio, origin: derived, isAiGenerated: true)` only when:

- Hero explicitly approves a narrated/localized audio as a Story representation, **and**
- A new ADR supersedes HS-ADR-076’s “separate VO only” for that product case (e.g. published multilingual narrated editions)

Until then, keep TTS on `StoryVoiceRendering` to avoid forcing approval lifecycle / catalog semantics onto lab/demo narrations.

### 12.3 Provenance to retain on generated audio

Minimum:

- Generated (always AI for this path)
- `providerLabel`, `modelLabel`
- `VoiceProfileId?`
- `language`
- generation timestamp
- `sourceRepresentationId` (script/transcript)
- `experiencePlanId` + processing versions (when experience-scoped)
- `renderingMode`

Do not embed raw vendor request payloads in the Story aggregate.

### 12.4 Multilingual

Support:

```text
Story.originalLanguage
 └── transcript / script representations per language
      └── StoryVoiceRendering(language: …) per synthesis
```

Cross-lingual cloning (CosyVoice strength) is a **provider capability**, surfaced only when `VoiceProfile` + target language are both authorized. Provenance must link: source sample language ≠ synthesized language when cross-lingual.

---

## 13. Provider capability matrix

Values below are from public docs / model cards as of plan date. Where uncertain, marked **verify**. Capabilities often depend on **model variant and deployment**.

| Capability | ElevenLabs | Qwen3-TTS | CosyVoice 3 (Fun-CosyVoice3) |
|------------|------------|-----------|------------------------------|
| Voice cloning | Yes (IVC/PVC APIs) | Yes (Base 0.6B/1.7B; ref audio + optional ref text; ~3s clone claimed) | Yes (zero-shot; ref audio; ref text optional/recommended) |
| Local inference | No (hosted API) | Yes (official CUDA-oriented; community MLX/MPS) | Yes (CUDA primary; MPS via PR/forks; CPU fallback) |
| Streaming | Yes (HTTP stream / WebSocket APIs) | Yes (dual-track / low-latency designs in tech report) | Yes (streaming inference modes documented) |
| Multilingual | Yes (model-dependent; 29–70+ languages claimed by product tier/model) | Yes (tech report: 10 languages training claim) | Yes (9 languages + many Chinese dialects claimed) |
| Cross-lingual cloning | Product/feature dependent — **verify per API** | Supported in series claims — **verify per checkpoint** | Explicitly documented (omit ref_text for cross-lingual mode) |
| Emotion/style control | Yes (model/settings dependent) | Yes (instruct / voice design variants) | Yes (instruction / fine-grained control tags) |
| Apple Silicon | N/A (cloud) | Feasible via community MLX/MPS; official path CUDA-first; **spike required** | Feasible via MPS PRs/forks; upstream friction possible; **spike required** |
| NVIDIA GPU | N/A (cloud) | Yes (primary) | Yes (primary; TensorRT/vLLM CUDA-only features) |
| CPU fallback | N/A | Possible but slow — **verify** | Documented as possible; slow |
| Commercial licensing | Commercial SaaS (plan-dependent; Free tier limited) | Source + weights released under **Apache 2.0** per GitHub/arxiv statement — **confirm exact checkpoint card before production** | HF card `Fun-CosyVoice3-0.5B-2512`: **Apache-2.0** — still confirm companion resources (e.g. `CosyVoice-ttsfrd`) and legal review |
| Cost per generated minute | Hosted: roughly **~$0.05–$0.10 per 1K chars** API list pricing for Flash vs Multilingual v2/v3 (plan-dependent); ≈ order-of-magnitude **~$0.05–$0.10/min** at ~1K chars/min — **measure** | Local compute (electricity/GPU) or Alibaba Model Studio hosted pricing if used | Local compute |
| API availability | Yes (public SaaS API) | Local Python package + optional cloud; not an EH-native API | Local Python / serving stacks; not an EH-native API |

**Other credible options (do not expand V1):** OpenAI TTS (already integrated), MiniMax T2A (lab plan), gpt-4o-mini-tts (steerable), Kokoro/Chatterbox (smaller open TTS). Prefer not adding them until Qwen/CosyVoice spike + ElevenLabs decision land.

---

## 14. Local-model feasibility (Apple Silicon Mac mini)

### 14.1 Practical assessment

| Concern | Qwen3-TTS | CosyVoice 3 |
|---------|-----------|-------------|
| Official happy path | CUDA + Python 3.12 + `qwen-tts` | CUDA + Python + FunAudioLLM stack |
| Apple Silicon | Community MLX / MPS projects exist; memory guidance ~4–10GB RAM by 0.6B vs 1.7B class | MPS support via upstream PR #1869 / forks; fp16/JIT on MPS; training/TRT not on MPS |
| Docker on Mac | Possible for CPU/MPS-in-VM complexity; GPU passthrough **not** like NVIDIA | Same |
| Install complexity | Non-trivial (weights, audio deps, device quirks) | Non-trivial (ttsfrd optional wheels often Linux-specific) |
| Flutter responsibility | **None** — sidecar only | **None** — sidecar only |

### 14.2 Recommendation for V2 spike

1. Run a **Python sidecar** on the Mac mini (not Docker-first).
2. Spike **both** Qwen3-TTS 0.6B Base and Fun-CosyVoice3-0.5B for:
   - English narration quality
   - clone-from-Hero-sample quality
   - latency for ~1–2 min transcript
   - RAM / thermal behavior on Apple Silicon
3. Prefer the model that actually works stably on the available hardware; do not pre-commit from README claims.
4. If Mac mini is insufficient, evaluate a small NVIDIA host for local inference while keeping the same sidecar HTTP contract.

### 14.3 Inference placement

| Placement | Verdict |
|-----------|---------|
| Flutter on-device ML | **No** for first implementation |
| Dart `ai_proxy` in-process Python | **No** |
| Sidecar next to `ai_proxy` | **Yes** |
| Hosted ElevenLabs / OpenAI | **Yes** for commercial path |

---

## 15. Security / privacy / consent considerations

1. **Independent consents** — synthetic narration ≠ AI transformation ≠ cloning ≠ publication.
2. **Explicit actions** — never auto-TTS on accept/open/play.
3. **Credentials** — server-only; never in app binaries beyond existing proxy bearer limitation.
4. **Disclosure** — UI must name that audio/text may be sent to a third-party or processed by a local model.
5. **Retention** — document whether provider stores clones; prefer delete APIs; local models for stricter control.
6. **Revocation** — block synthesis; delete profile bindings; best-effort remote delete.
7. **No impersonation marketplace** — owner’s voice for owner’s stories / consented uses only.
8. **No behavioral evidence** from TTS success/failure or audio content.
9. **Auditability** — persist consent timestamps, provider key, source media id, generation ids.
10. **Data minimization** — send only required text/reference audio; avoid full Story aggregates to providers.

---

## 16. Licensing considerations

| Provider | Notes | Action before production |
|----------|-------|--------------------------|
| ElevenLabs | Commercial ToS + plan features (cloning tiers) | Legal/product review of cloning ToS + data retention |
| Qwen3-TTS | GitHub/arxiv state Apache 2.0 for released models/tokenizers | Verify **each weight card** used; confirm commercial use for chosen checkpoint |
| CosyVoice 3 | `Fun-CosyVoice3-0.5B-2512` HF card lists Apache-2.0 | Verify companion assets (`CosyVoice-ttsfrd`) licenses; legal review |
| OpenAI TTS | Existing dependency | Already in use for synthetic narration |

**Do not assume** source-repo license automatically covers every weight artifact or third-party tokenizer resource.

---

## 17. Testing strategy

Follow existing HS.12.6 / hero_story conventions: focused phase-prefixed tests + architecture boundary tests + proxy unit tests with fake HTTP clients. **No real TTS model in standard `flutter test`.**

### Domain

- `StoryVoiceRendering` invariants (content type, byte length, processing versions)
- Language / voiceProfileId rules when added
- `VoiceProfile` ownership, consent, lifecycle, revoke/delete
- Mode distinctions: synthetic ≠ clone
- Consent independence tests (extend `story_consent_test.dart`)

### Application

- `RenderStoryVoiceUseCase`: ownership, consent, idempotency, force regenerate, missing transcript, unsupported mode
- Provider-agnostic request mapping (hints ignored by domain invariants)
- Failure: empty audio, bad content type, storage failure → no corrupt artifact
- Language handling / cross-lingual rejection when unsupported
- Future: `CreateVoiceProfileUseCase` consent hard-stop

### Infrastructure

- Proxy handler validation (mode, auth 401, malformed audio 502)
- Router selects provider by env/hint
- Adapter contract parity with in-memory fake
- Timeouts / 429 / malformed JSON
- Parser tests for multi-provider response labels

### Integration (fake providers)

```text
Story + consent + plan + transcript
  → RenderStoryVoiceUseCase
  → InMemory / Fake proxy client
  → StoryVoiceRendering + media bytes
  → Load bytes via StoryMediaStoragePort
```

### Explicitly out of CI

- Live ElevenLabs / Qwen / CosyVoice calls (optional nightly with secrets)
- Subjective voice quality scoring in domain tests

---

## 18. Migration / rollout strategy

1. **Non-breaking contract extension** — additive JSON fields; old clients keep working.
2. **Feature flags** — `EH_TTS_PROVIDER`, `EH_TTS_ALLOW_PROVIDER_HINTS`, cloning flag off by default.
3. **Idempotent regeneration** — keep HS.12.6 behavior (new id on regenerate; optional reuse when plan/mode match).
4. **Fallback** — original recording always playable; provider failure does not mutate Story.
5. **No data migration** required for existing `StoryVoiceRendering` files if new fields are optional with defaults.
6. **Docs** — new ADR(s) before cloning; update HS.12.6 report addendum; do not silently rewrite stale maps unless in scope.
7. **Lab alignment** — coordinate with AI Experience Provider Laboratory multi-TTS phases to avoid duplicate clients.

---

## 19. Vertical implementation phases

| Phase | Scope | Exit gate |
|-------|-------|-----------|
| **V1 — Provider-neutral contract hardening** | Document/extend `VoiceRenderingRequest` for language + optional hints; tests; still in-memory/OpenAI | Contract tests green; no Flutter vendor types |
| **V2 — Local provider spike** | Python sidecar; Qwen3-TTS and/or CosyVoice on Mac mini; quality/latency notes | Written spike report; go/no-go on local models |
| **V3 — AI proxy multi-provider** | Router + ElevenLabs and/or LocalTtsClient; env selection; relax OpenAI-required config when appropriate | Proxy tests with fakes; one non-OpenAI path produces audio |
| **V4 — Story narration productization** | Wire language provenance; optional experience-player use of narrated bytes; keep Mode A | Owned story can narrate via selected provider without code changes in domain |
| **V5 — Voice profile + cloning** | `VoiceProfile` + consent + `VoiceProfilePort` + proxy routes; `voiceClone` mode enabled only with profile | Clone never implicit; revoke works; audit fields present |
| **V6 — Provider selection/configuration** | Stable env/lab config matrix: `openai` / `elevenlabs` / `qwen3` / `cosyvoice` | Swap provider without domain/app model changes |
| **V7 — Personalized experience composition** | Only after narration works: personalization may request script + voice profile + music | Personalization remains separate engine; TTS remains a capability |

**Do not start V7 before V4.** Do not start V5 before consent ADR approval.

---

## 20. Files likely to change (when implementation begins)

### Domain / application

- `voice_rendering_port.dart`
- `story_voice_rendering.dart` (+ id/snapshot mappers)
- `story_consent.dart` (cloning gate — V5)
- New: `voice_profile*.dart`, `voice_profile_port.dart`, use cases (V5)
- `render_story_voice_use_case.dart` + DTOs
- Riverpod providers under `application/providers/ai/` and use_cases

### Infrastructure / Flutter adapters

- `proxy_voice_rendering_adapter.dart` / parser / config
- `in_memory_voice_rendering_adapter.dart`
- Persistence mappers/repos for new fields / VoiceProfile

### Proxy

- `story_voice_rendering_handler.dart`
- `proxy_config.dart`, `bin/server.dart`, `.env.example`, `README.md`
- New clients: ElevenLabs, Local TTS
- New handlers for voice profiles (V5)
- Tests under `services/ai_proxy/test/`

### Optional new service

- `services/local_tts/` (Python sidecar) — new tree for V2/V3

### Presentation (late, thin)

- Consent copy + authorize/create flows
- Provider is **not** chosen in widgets beyond lab tooling

### Docs / ADR

- New ADR for multi-provider TTS
- New ADR for VoiceProfile + cloning consent
- Addendum to HS.12.6 report

---

## 21. Files that should explicitly NOT change

- Life Journey behavioral evidence / pattern detectors
- Discovery NarrativeTheme ownership
- Story canonical narrative mutation paths
- HS.9 capture invariants / `DeviceRecordingPort` semantics (beyond optional sample reuse)
- Making `StoryExperiencePlan` own vendor voice ids or revival of rejected `voiceStrategy` plan fields without ADR
- `eh_platform` AI module absorb (unless Phase 8 is explicitly opened)
- UI.3 personalization selection rules inside voice widgets
- Putting vendor SDKs into `lib/features/hero_story/domain` or `application`
- Creating a second proxy service for TTS alone

---

## 22. Architecture drift analysis (and how this plan avoids it)

| Potential drift | Avoidance |
|-----------------|-----------|
| TTS logic in Flutter widgets | Widgets call use cases/controllers only; no synthesis in UI |
| Provider IDs in domain objects | Opaque `VoiceProfileId` + opaque `providerReference` strings; no ElevenLabs types in domain |
| Story depends on TTS provider | Story unchanged; derived VO + media port |
| AI proxy concepts leak into domain | Domain port stays EH-owned; HTTP/JSON only in infrastructure |
| Duplicate media concepts | Reuse `MediaReference` + `StoryMediaStoragePort` |
| Second AI infrastructure path | Extend `services/ai_proxy` (+ sidecar), not a new Flutter-facing AI service |
| Bypass application ports | All synthesis via `VoiceRenderingPort` / `VoiceProfilePort` |
| Credentials in Flutter app | Server env only |
| Couple app to Python | Sidecar behind proxy; Flutter unaware |
| Generated media as canonical Story | Keep `StoryVoiceRendering`; promote to representation only via future ADR + approval |
| Bypass provenance | Require source representation + provider/model labels + timestamps |
| Bypass voice-consent | Hard-stop in use cases; cloning consent separate |
| Collapse clone into narrate | Separate ports/routes/phases |
| Personalization inside TTS | TTS is capability only; V7 consumes it later |
| Treat story listen as evidence | Explicit non-goal; no evidence reactors |

---

## 23. Architecture risks

1. **Doc trap of HS.12 §G / ADR-074** — engineers may implement cloning as `StoryRepresentation` against current ADR-076.
2. **OpenAI-required proxy config** blocks local-only routing until relaxed.
3. **Reference-audio vs durable voice id** mismatch across providers complicates `VoiceProfile`.
4. **Apple Silicon performance/quality** may fail spike — need NVIDIA fallback host.
5. **Licensing foot-guns** on companion resources / commercial ToS for cloning.
6. **Long transcripts** — OpenAI 4096 char limit already; other providers differ; need chunking strategy.
7. **Lab plan parallel work** — duplicate MiniMax/Qwen clients if not coordinated.
8. **Consent UX complexity** — too many gates vs unsafe overloading of AI consent.
9. **Web bearer token exposure** — existing limitation; cloning heightens sensitivity.
10. **Streaming temptation** — premature Mode B increases scope without product need.

---

## 24. Open decisions requiring Andy’s approval

1. **Artifact model for cloned/published narrations:** remain on `StoryVoiceRendering` vs selective promotion to approved `StoryRepresentation`.
2. **Cloning consent field placement:** StoryConsent extension vs VoiceProfileAuthorization vs both — independence is locked by HS-ADR-078; schema placement remains open for HS.12.9.
3. **First commercial hosted provider after OpenAI:** ElevenLabs now, or defer until local clone spike?
4. **First local cloning model priority:** Qwen3-TTS Base vs CosyVoice 3 vs both — CustomVoice (HS.12.7) is not cloning.
5. **Whether lab multi-TTS (MiniMax/Qwen cloud) and this plan share the same proxy router workstream.**
6. ~~Whether VoiceProfile architecture is in scope before coding~~ → **Resolved by HS.12.8 / HS-ADR-078** (Hero-scoped identity; implement aggregate in HS.12.9).
7. **Data retention policy** for reference samples and third-party clone storage.
8. **Whether production Render deployment must support non-OpenAI TTS** in the first milestone or only local/dev.
9. **Legal sign-off** on Apache-2.0 checkpoints + hosted cloning ToS before any user-facing clone.
10. **Rename question:** keep `VoiceRenderingPort` naming vs public rename to “Story Narration” (label vs type rename).
11. **Revocation policy** for already-published generated audio (HS.12.8 documents options; does not pick one).
12. **Non-Hero VoiceProfile ownership** after Identity binding matures.

---

## 25. Recommended first implementation milestone

**Milestone M0 (this document):** Architecture review / approve open decisions — **done as plan.**

**Milestone M1 (first coding slice) — “Provider-neutral synthetic narration” — IMPLEMENTED (HS-ADR-077):**

1. ADR-077: provider-neutral synthetic TTS behind existing `VoiceRenderingPort` / `POST /story-voice-renderings`.
2. Contract fields: required `language` + optional opaque `providerHint` / `modelHint`.
3. Persistence / use case / proxy / in-memory adapter updated; OpenAI remains the initial real proxy adapter.
4. Flutter tests use `InMemoryVoiceRenderingAdapter` (no external TTS).
5. **Explicitly out of M1:** VoiceProfile, cloning mode enablement, streaming, local sidecar, ElevenLabs client, personalization, StoryRepresentation promotion.

**Still future:**

- ~~V2 local-model spike (Qwen3 / CosyVoice)~~ → **HS.12.7 complete** (Qwen3 CustomVoice measured; CosyVoice not verified; no provider lock)
- ~~Voice identity / cloning architecture~~ → **HS.12.8 complete** (HS-ADR-078; skeletal `VoiceProfilePort`; no production cloning)
- Multi-provider production hardening / provider lock (Andy approval)
- **HS.12.9 Voice Profile Foundation** (aggregate + consent gates; still no production clone adapter by default)
- V5 production cloning adapter enablement (`voiceClone` mode) after consent/product decisions
- M4 Qwen operational benchmark (separate from architecture)

**M1 success criteria met:**

- Domain/application dependency direction preserved
- Original recording remains playable on failure
- Synthetic narration still requires `voiceRenderingApprovedAt`
- `voiceClone` remains rejected

---

## Appendix A — Mapping user conceptual names → EH names

| Conceptual name | EH recommendation |
|-----------------|-------------------|
| StoryNarrationPort | Use existing **`VoiceRenderingPort`** |
| GenerateStoryAudioPort | Too broad — reject |
| VoiceSynthesisPort | Infrastructure concern — reject as domain port |
| POST /story-narrations | Prefer existing **`POST /story-voice-renderings`** |
| POST /voice-clone | Replace with **`POST /voice-profiles`** (create) + narrate via voice-renderings |
| Audio Representation | `StoryVoiceRendering` now; optional future `StoryRepresentation` |
| Story Media | `MediaReference` + `StoryMediaStoragePort` |

## Appendix B — Personalization boundary reminder

```text
Discovery Profile
  → Personalization Engine (future)
    → Experience Composition
         ├── Story
         ├── Script
         ├── Music
         └── Narration request
                → VoiceRenderingPort
```

Voice synthesis is a **building block**, not the personalization engine, not the source of behavioral understanding, and not the owner of Story meaning.

## Appendix C — Sources consulted

### Repository

- HS-ADR-076 / architecture-decisions.md
- HS.12.6 Voice Rendering Implementation Report
- HS.12 AI Hero Story Demo Plan (§G historical)
- AI Experience Provider Laboratory Plan
- HS.1 Hero and Story Platform Foundation
- AGENTS.md / bounded-contexts / domain glossary / testing strategy
- Code: `VoiceRenderingPort`, `RenderStoryVoiceUseCase`, `StoryVoiceRenderingHandler`, `OpenAiSpeechClient`, `ProxyConfig`, capture/transcription/media ports

### External (capability research; verify before production)

- QwenLM/Qwen3-TTS GitHub + arXiv:2601.15621 (Apache 2.0 claims; cloning API shape)
- FunAudioLLM CosyVoice 3 / Fun-CosyVoice3-0.5B-2512 HF card (Apache-2.0; multilingual/cross-lingual)
- CosyVoice MPS PR #1869 / community Apple Silicon notes
- ElevenLabs API pricing / IVC docs (hosted cloning + streaming)
)
