# ACE-Step 1.5 — Everyone’s Heroes Narrative Music Evaluation

**Status:** Investigation / architecture recommendation  
**Date:** 2026-10-06  
**Scope:** Source-level evaluation only. No EH code changes. No ACE-Step modifications. No training. No model-weight downloads beyond source inspection.

**Primary question:**

> Can ACE-Step 1.5 be specialized so its planning and conditioning understand an EH Story Timeline / Narrative Arc, while retaining its underlying audio-generation capabilities?

**Verdict (short):**

**Yes — with an adapter-first architecture (Option B), not by forcing EH stories into conventional song forms.**

`[Verse]` / `[Chorus]` / `[Bridge]` are **textual conventions inside the lyrics string**, not DiT vocabulary tokens, not constrained-decoding fields, and not a required runtime schema. The audio model consumes free-form caption + lyrics + metadata (+ optional codes / reference audio / time-window masks). EH can therefore own narrative phases in EH/application space and compile them into ACE-Step’s flat generation contract — optionally keeping conventional tags only as a soft compiler target when useful.

This does **not** mean arbitrary narrative phase names will automatically produce reliable musical semantics without specialization. Effectiveness of novel tags is distribution-dependent; planner/prompt specialization and later LoRA/SFT may be needed for consistent EH arcs.

---

## 1. Executive summary

ACE-Step 1.5 is a hybrid music system:

```text
User / API intent
    ↓
Planner layer (5Hz LM and/or external LLM and/or user-provided caption+lyrics)
    ↓
Flat generation contract: caption, lyrics, metas, optional codes, optional audio
    ↓
DiT diffusion + VAE decode
    ↓
Audio
```

Key source findings:

| Finding | Evidence strength | Implication for EH |
|---|---|---|
| Structure tags live in lyrics text | Strong (code + training docs) | Narrative phases can be represented as free-form tags / prose |
| Runtime has no `sections[]` object | Strong (`AudioSample`, `GenerationParams`) | Timeline must live in EH or adapter, not native ACE-Step schema |
| Constrained decoding covers BPM/caption/duration/key/language/timesig — not section names | Strong (`MetadataConstrainedLogitsProcessor`) | Section vocabulary is not schema-locked |
| Muse training `sections[]` is flattened to `[Type]\\ntext` before training | Strong (SFT guide) | Changing section vocabulary does not require DiT architecture change; may require data/fine-tune for reliability |
| Absolute timestamps exist for **repaint windows**, not for phase planning | Strong (`repainting_start/end`) | Phase replace → region regenerate is feasible via adapter |
| Personalization via LoRA / reference audio / caption is real; motif/profile objects are not | Strong | EH musical identity is mostly adapter + LoRA later |
| Apple Silicon MLX support exists | Strong (`models/mlx`, macOS launchers) | Local/dev path is plausible |

**Recommended direction:** Option B — EH Narrative Music Model → ACE-Step Adapter → ACE-Step audio engine.

Do **not** introduce ACE-Step types into the EH domain. Future EH boundary should remain something like `MusicGenerationPort` / creative direction artifacts already discussed in `AI-Experience-Provider-Laboratory-Plan.md`.

---

## 2. Repository / version / commit examined

| Item | Value |
|---|---|
| Repository URL | https://github.com/ACE-Step/ACE-Step-1.5 |
| Branch | `main` |
| Commit SHA | `ca1e85fe9430179831e6bc6be790c332190a3866` |
| Commit subject | `fix(jetson): remove GPL video codecs, fix ffmpeg/examples/healthcheck (#1190)` |
| Commit date | 2026-08-29 |
| Package version | `1.5.0` (`pyproject.toml`) |
| License | MIT (`LICENSE`) |
| Python | `>=3.11,<3.13` (docs: 3.11–3.12 recommended) |
| Primary runtime | PyTorch 2.7+/2.9+/2.10+ depending on platform; Gradio 6.2; transformers; diffusers; peft; lightning |
| Hardware | CUDA recommended; also MPS / ROCm / Intel XPU / CPU; Apple Silicon via MLX |
| VRAM (docs) | ≥4GB DiT-only; ≥6GB LLM+DiT; XL DiT ≥12GB with offload / ≥20GB without |
| Relevant model family | DiT: `acestep-v15-{base,sft,turbo}` and XL 4B variants; LM: `acestep-5Hz-lm-{0.6B,1.7B,4B}`; VAE; `Qwen3-Embedding-0.6B` |
| Inspection method | Shallow clone to `/tmp/ACE-Step-1.5`; source + docs inspected; **weights not downloaded** |

### Supported hardware (source-backed)

- **NVIDIA CUDA:** primary path (`pyproject.toml` CUDA 12.8/13.0 wheels).
- **Apple Silicon:** MLX backend (`acestep/models/mlx/*`, `start_gradio_ui_macos.sh`, `mlx` / `mlx-lm` deps).
- **AMD ROCm:** dedicated requirements/launchers.
- **Intel XPU:** documented; soundfile fallback for audio I/O.
- **CPU:** supported for low-VRAM / offline paths; slower.

### Model sizes (from INSTALL / constants)

| Component | Sizes |
|---|---|
| 5Hz LM planner | 0.6B / 1.7B / 4B (`LM_MODEL_NAMES`, memory ~3 / 8 / 12 GB) |
| DiT | ~2B-class turbo/base/sft; XL ~4B (`acestep-v15-xl-*`) |
| Embedding | Qwen3-Embedding-0.6B |
| VAE | shared AutoencoderOobleck-style codec path |

### Licensing note

Source is MIT. Upstream model weights on Hugging Face / ModelScope may carry separate terms; EH must verify weight licenses before production use. This evaluation covers **code architecture**, not commercial redistribution of weights.

---

## 3. Architecture diagram

```text
┌──────────────────────────────────────────────────────────────────────┐
│ Entry surfaces                                                        │
│  Gradio UI  |  REST /release_task  |  OpenRouter chat façade  |  CLI │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Application orchestration                                             │
│  api/job_*  →  prepare_llm_generation_inputs                          │
│  GenerationParams + GenerationConfig  (acestep/inference.py)          │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
          ┌─────────────────────┴─────────────────────┐
          ▼                                           ▼
┌──────────────────────────┐             ┌────────────────────────────┐
│ Planner / LM (optional)  │             │ Direct user/API conditioning│
│ LLMHandler               │             │ caption + lyrics + metas    │
│  create_sample_from_query│             └──────────────┬─────────────┘
│  format_sample_from_input│                            │
│  generate_with_stop_...  │                            │
│  MetadataConstrained...  │                            │
│ External AI JSON planner │                            │
└────────────┬─────────────┘                            │
             │ CoT metas + optional lyrics/codes         │
             └────────────────────┬─────────────────────┘
                                  ▼
┌──────────────────────────────────────────────────────────────────────┐
│ AceStepHandler (DiT path)                                             │
│  PromptMixin / ConditioningText / ConditioningEmbed                   │
│  ConditioningMask (repaint windows)                                   │
│  AceStepConditionEncoder → AceStepDiTModel (diffusion)                │
│  VAE encode/decode (48 kHz, hop 1920 ≈ 25 Hz latents)                 │
│  LoRA manager (optional)                                              │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
                                ▼
                     AudioSaver → wav/mp3/flac/...
```

### Representation layers

| Layer | Examples | Level |
|---|---|---|
| UI / API formatting | Gradio fields, OpenRouter messages, multipart `/release_task` | UI/API |
| Planning domain (ACE-Step-native) | caption, lyrics, bpm, duration, keyscale, timesignature, language | Domain-ish (music-product) |
| Model conditioning | `SFT_GEN_PROMPT`, lyric `# Languages/# Lyric` wrap, embeddings, masks | Model-level |
| Low-level audio | VAE latents, diffusion timesteps, waveform splice | Model/audio |

EH narrative timeline concepts do **not** currently exist in ACE-Step. They would be introduced above or beside the planner, then compiled into the flat contract.

---

## 4. Generation pipeline

Traced path from request to audio.

| # | Stage | Source | Symbol | Input | Output | Representation level |
|---|---|---|---|---|---|---|
| 1 | User input | Gradio / `api/http/release_task_*` / OpenRouter | request models | prompt, lyrics, metas, audio, task flags | typed request | UI/API |
| 2 | LLM/planner prep | `acestep/api/llm_generation_inputs.py` | `prepare_llm_generation_inputs` | sample/format/thinking flags | caption/lyrics/metas plan | domain planning |
| 3 | Metadata generation | `acestep/llm_inference.py`, `constrained_logits_processor.py` | `LLMHandler`, `MetadataConstrainedLogitsProcessor` | caption/lyrics/query | CoT fields: bpm, caption, duration, keyscale, language, timesignature (+ optional genres) | planner |
| 4 | Lyrics generation | same + external AI | `create_sample_from_query`, `format_sample_from_input`, `build_planning_messages` | user intent | lyrics string (often with `[Verse]`… tags) | planner / text |
| 5 | Section/structure representation | lyrics text + caption prose | free-form strings | tags inside lyrics | **no first-class sections object** | text convention |
| 6 | Conditioning representation | `GenerationParams` → handler conditioning | caption, lyrics, metas, codes, ref/src audio | packed encoder states + masks | model-level |
| 7 | Tokenization | text tokenizer + lyric embed path | `PromptMixin`, `ConditioningEmbedMixin` | strings | token IDs / embeddings | model-level |
| 8 | Audio model | `acestep/models/*/modeling_acestep_v15_*.py` | `AceStepConditionEncoder`, `AceStepDiTModel` | cond + latents | denoised latents | model |
| 9 | Diffusion/generation | `core/generation/handler/diffusion.py`, `service_generate*.py` | diffusion loop / ODE-SDE | noise + cond | latents | model |
| 10 | Post-processing | decode + `audio_utils` | VAE decode, normalize, fade, LRC optional | latents/waveform | files / scores | model + UI |
| 11 | Audio output | `AudioSaver` | paths | tensors | wav/mp3/flac… | UI/API |

### Critical conditioning fact

DiT does **not** receive a structured song-form graph. It receives:

1. **Text branch:** instruction + caption + metas (`SFT_GEN_PROMPT` in `acestep/constants.py`)
2. **Lyric branch:** `# Languages` + `# Lyric` + free-form lyrics (`PromptMixin._format_lyrics`)
3. **Optional:** reference/source audio latents, 5Hz semantic codes, repaint masks

Therefore conventional song structure enters as **conditioning text**, not as a separate structural tensor type.

---

## 5. Training representation

### Runtime / training sample schema

`AudioSample` in `acestep/training/dataset_builder_modules/models.py`:

| Field | Mandatory? | Consumed by | Influences generation? | Notes |
|---|---|---|---|---|
| `audio_path` | yes for training | VAE | yes | target audio |
| `caption` | soft (warned if missing) | DiT text | yes | style/arrangement description |
| `lyrics` | defaults to `[Instrumental]` | DiT lyrics | yes | free text; may contain structure tags |
| `genre` | optional | prompt swap via `genre_ratio` | yes | can replace caption |
| `bpm` / `keyscale` / `timesignature` / `duration` / `language` | optional | metas string | yes | textual metas |
| `custom_tag` | optional | caption/genre mutate | yes | LoRA-style trigger tags |
| `raw_lyrics` / `formatted_lyrics` | optional | labeling/UI | planning only until written to `lyrics` | |
| `sections[]` | **absent** | — | N/A | not a runtime field |

Sidecars commonly used:

- `{base}.caption.txt`
- `{base}.lyrics.txt` or `{base}.txt`
- `{base}.json` optional metas

### Muse / large-scale SFT `sections[]`

Offline conversion (documented in `docs/en/Large_Scale_SFT_Training_Guide.md`) flattens:

```text
sections[].section + sections[].text
        ↓
"[Verse]\n....\n[Chorus]\n...."
        ↓
.lyrics.txt
```

After conversion, **only the flattened lyrics string remains**. Section objects are not retained in the training sample dataclass.

### What the LLM vs audio model consume

| Artifact | 5Hz / external LLM | DiT audio model | Ignored after planning? |
|---|---|---|---|
| caption | generates/rewrites | text encoder | no |
| lyrics (+ tags) | generates | lyric embeddings | no |
| bpm/key/duration/lang/timesig | CoT / constrained | metas in prompt | no |
| genres | optional CoT | often skipped (`skip_genres=True`) | often yes for DiT metas path |
| `<\|audio_code_N\|>` | generates | latent/code hints | no if used |
| muse `sections[]` | conversion-time only | never as objects | yes after flatten |

### Can EH change section semantic vocabulary without retraining the audio model?

**Accept without architecture change: yes.**  
Tags are ordinary text. `[Opening]`, `[Turning Point]`, `[Breakthrough]` will tokenize and condition.

**Reliably map novel semantics to desired musical behavior without specialization: not guaranteed.**  
Training distribution heavily uses conventional pop/EDM tags. Novel EH vocabulary is soft prompting unless reinforced by:

1. caption prose describing the arc,
2. prompt/planner specialization,
3. LoRA / SFT on narrative-labeled examples.

**Conclusion:** changing vocabulary does **not** require changing DiT/VAE architecture. It may require adapter strategy and later data specialization for quality.

---

## 6. Planner analysis

### What models are used?

| Planner | Location | Notes |
|---|---|---|
| Built-in 5Hz LM | `acestep/llm_inference.py` `LLMHandler` | `acestep-5Hz-lm-{0.6B,1.7B,4B}`; backends `vllm` / `pt` / `mlx` |
| External LLM planner | `acestep/text_tasks/external_ai_request_helpers.py` | OpenAI / Anthropic / ZAI-style JSON planning |
| User-supplied plan | API/UI fields | bypass inspiration; still may use CoT metas |

### Prompts

Constants in `acestep/constants.py`:

- `DEFAULT_LM_INSTRUCTION`
- `DEFAULT_LM_UNDERSTAND_INSTRUCTION`
- `DEFAULT_LM_INSPIRED_INSTRUCTION`
- `DEFAULT_LM_REWRITE_INSTRUCTION`
- DiT `TASK_INSTRUCTIONS[...]`

External planner system prompt (`build_planning_messages`) requests JSON keys:

`caption, lyrics, bpm, duration, key_scale, time_signature, vocal_language, instrumental`

and explicitly asks for a **linear narrative production brief** covering arrangement progression and energy evolution. Guidance currently mentions conventional progression (“intro to verse to chorus or drop to outro”) — **prompt convention**, not model schema.

### Structured output?

| Path | Structure |
|---|---|
| 5Hz LM | Not JSON. CoT `<think>…</think>` line fields, then lyrics and/or `<\|audio_code_N\|>` stream. Optionally **schema-constrained** by FSM (`MetadataConstrainedLogitsProcessor`). |
| External AI | Prompted JSON; optional `response_format: json_object` for some providers. Not ACE-specific grammar. |

### Where things are generated

| Concern | Where |
|---|---|
| Section names | Inside generated/user lyrics text; not a dedicated field |
| Lyrics | LM inspiration/format, external planner, or user |
| Musical descriptions | `caption` |
| Tempo / key / instrumentation / style | metas + caption prose; instrumentation mainly caption |
| Arbitrary semantic phases | Only as free text in caption/lyrics |
| Timeline object | **Not supported** |
| Emotional trajectories | Only as prose |
| Transitions between phases | Soft, via caption narrative / lyric tags / musical continuity — no transition graph |

### Can the planner produce EH-like phases today?

**Syntactically yes** (free text).  
**As a first-class timeline with durations/energy curves: no.**

EH should not rely on ACE-Step’s built-in planner to invent the narrative arc. Prefer: EH Creative Director owns the arc; ACE-Step planner optionally fills musical metas/lyrics under EH control, or is bypassed.

---

## 7. Section / structure analysis

### Search results summary

Occurrences of `[Verse]` / `[Chorus]` / etc. are concentrated in:

- examples (`examples/text2music/*.json`)
- tutorials / musicians guides
- Muse → lyrics conversion docs
- OpenRouter lyrics heuristics (`_looks_like_lyrics`)
- LRC cleanup (strip structural tags for display)

### A or B?

**B — conventions imposed by planner / prompt / training representation.**

Not A — not required by the underlying DiT vocabulary or constrained metadata schema.

Proof points:

1. Constrained fields: bpm, caption, duration, genres?, keyscale, language, timesignature — **no section enum**.
2. Lyrics formatting wraps arbitrary text.
3. Training docs: structural tags help but are optional.
4. Runtime `AudioSample` / `GenerationParams` have no `sections[]`.
5. OpenRouter marker list is a heuristic for detecting lyrics, not an allowlist for generation.

### Compiler-target question

Yes — conventional labels **can** be compiler targets:

```text
EH Narrative Timeline
    ↓
EH Music Creative Plan
    ↓
ACE-Step Adapter
    ↓
caption + lyrics(+optional [Verse]/[Chorus] or EH tags) + metas + duration
    ↓
Audio model
```

Two viable compilation strategies:

1. **Preserve native soft tags:** map EH phases → conventional `[Intro]/[Verse]/[Chorus]/[Bridge]/[Outro]` when musical usefulness is high.
2. **EH semantic tags:** map phases → `[Opening]`, `[Challenge]`, … plus caption arc prose.

Evidence favors trying (2) for product fidelity, with (1) as a fallback/control in POC A/B tests. Neither requires DiT architecture surgery.

---

## 8. Timeline analysis

Desired EH timeline example (investigation only — not proposed as EH domain schema):

```text
00:00 ──────────────── 04:00
Opening       0:00–0:30
Challenge     0:30–1:00
Struggle      1:00–1:45
Turning Point 1:45–2:15
Breakthrough  2:15–3:20
Resolution    3:20–4:00
```

### What ACE-Step understands today

| Concept | Supported? | Where |
|---|---|---|
| Absolute timestamps as generation structure | No (except repaint) | — |
| Global duration | Yes | `GenerationParams.duration` (10–600s) |
| Relative / section duration | No first-class | imply via lyric length / caption |
| Transitions | Soft only | caption prose / musical continuity |
| Musical events / energy curves | Soft only | caption / tags like `[Build]`, `[Drop]` |
| BPM changes mid-piece | No structured channel | caption narrative only |
| Instrumentation changes over time | Soft only | caption |
| Vocal delivery changes | Soft only | lyric tags e.g. `[whispered]` |
| Repaint region in absolute seconds | Yes | `repainting_start` / `repainting_end` |
| Coarse code timeline | Partial | 5 codes ≈ 1 second |
| Latent timeline | Yes (internal) | `sec * sample_rate // 1920` |
| Post-hoc lyric timestamps | Yes (analysis) | LRC / attention alignment — not generation control |

### Where timing could be introduced (smallest first)

1. **Adapter-owned timeline** → set `duration = sum(phase.durations)`.
2. Encode phase windows into caption (“Opening 0–30s sparse piano; Breakthrough 2:15–3:20 full triumphant ensemble”).
3. Put phase labels into lyrics at approximate textual proportions.
4. For edits: map phase → `(repainting_start, repainting_end)` and regenerate.
5. Later research: train planner/DiT on timestamped narrative sections — only if soft methods fail.

Absolute phase timing is **not** currently a hard control except through global duration + soft text + repaint windows.

---

## 9. Editing / regeneration analysis

EH need: “The breakthrough section isn’t powerful enough” → regenerate only that region.

| Capability | Status | Notes |
|---|---|---|
| Repaint | **Yes** | `task_type=repaint`, start/end seconds, modes conservative/balanced/aggressive, latent + optional waveform crossfade |
| Inpaint (region) | Effectively via repaint masks | preserve surrounding via mask / splice |
| Partial regeneration | Yes | same |
| Continuation | Yes | repaint from `t→end` or complete tasks |
| Section replacement by name | **No native** | adapter must map phase→seconds |
| Audio-to-audio | Yes | cover / cover-nofsq / repaint / lego / extract / complete |
| Reference audio | Yes | style/timbre conditioning |
| Preserve surrounding audio | Yes | repaint |
| Preserve vocals / change accompaniment | Partial / compositional | stem `extract` + `lego` / complete; not one-flag “keep vocals” |
| Change accompaniment / preserve vocals | Same | possible via stem workflow, not trivial single call |
| Flow-edit morph | Yes | morph caption/lyrics over cover path |
| Retake variation | Yes | `retake_variance` / `retake_seed` |

### Feasibility of Story Timeline → replace(phase)

**Architecturally feasible** at the adapter layer:

```text
Generated Experience (src_audio)
    + phase.turning_point → (1:45, 2:15)
    + rewritten caption/lyrics for that phase (higher energy)
    → task_type=repaint
    → new mix with surrounding preserved
```

Limitations:

- Phase boundaries must be known in adapter state (EH stores them; ACE-Step does not).
- Musical seam quality depends on crossfade settings and prompt consistency.
- No native guarantee that only “energy” changes while melody/identity remain fixed — use reference/cover strength and careful prompting.
- Stem-faithful “keep vocals” requires multi-step stem ops, not single repaint.

---

## 10. Personalization analysis

| Mechanism | Actually supported? | Fit for EH |
|---|---|---|
| LoRA / LyCORIS on DiT | Yes (`LoraManagerMixin`, training_v2, Gradio training) | Strong candidate for hero/user musical identity later |
| Voice LoRA naming path | Yes (`add_voice_lora`-style adapter naming in LoRA stack) | Possible vocal identity experiment; not Story ownership |
| Style conditioning via caption | Yes | Immediate |
| Reference audio / music | Yes | Immediate for “sounds like this” |
| Cover strength controls | Yes | Style transfer intensity |
| Genre preferences | Request-scoped text only | Adapter can inject from EH preferences |
| Instrumentation preferences | Caption / track tasks | Adapter |
| Recurring motifs | **No object** | Would be EH-side motif library → prompt/LoRA |
| Persistent user musical profile inside ACE-Step | **No** | Belongs in EH personalization, not ACE-Step |
| Voice identity cloning beyond LoRA/ref | No dedicated cloning model in this stack | Separate from music engine; EH already has voice workstreams |

Do **not** assume EH should use all of these. Prefer caption + reference + later LoRA only when needed.

---

## 11. EH compatibility analysis

### Desired eventual architecture

```text
EH Personalization
    ↓
EH Creative Director
    ↓
StoryExperiencePlan / Music Creative Direction
    ↓
EH Narrative Music Plan (application / lab artifact — not ACE types in domain)
    ↓
ACE-Step Adapter (infrastructure)
    ↓
ACE-Step planner/model (optionally planner bypassed)
    ↓
Audio
```

### Where ACE-Step conflicts

| Conflict | Severity | Mitigation |
|---|---|---|
| Flat plan vs EH timeline | High product | Adapter compiles timeline → flat params |
| Conventional song-structure bias in prompts/examples | Medium | Custom planner prompts; avoid ACE inspiration defaults |
| No phase energy curve channel | Medium | Caption + tags + optional multi-pass / repaint |
| Planner may rewrite caption/lyrics away from EH intent | High if left on | Set `thinking`/CoT flags carefully; prefer EH-owned caption/lyrics |
| Stem-level narrative control immature | Medium | Start single-bed; use repaint for phase edits |
| Training prior favors pop song forms | Medium | Narrative datasets / LoRA later |

### Smallest modification to accept EH-oriented representation

**Adapter only (no DiT/VAE change):**

1. Accept EH Narrative Music Plan (phases, emotional states, energy, durations, optional lyric intents).
2. Emit `GenerationParams`:
   - `caption` = arc production brief
   - `lyrics` = phase-tagged lyric or `[Instrumental]` with phase tags
   - `duration` = timeline sum
   - optional `bpm` / `keyscale` / `vocal_language`
3. Disable or tightly gate ACE inspiration rewrite when EH already planned.
4. Store phase→time map beside the rendering for later `repaint`.

This matches EH’s existing lab direction (`MusicGenerationPort` in `AI-Experience-Provider-Laboratory-Plan.md`) and HS-ADR guidance that music direction on `StoryExperiencePlan` remains descriptive, not provider-specific.

### Boundary reminder

Do **not** create in EH domain:

- `AceStepMusicPlan`
- `AceStepStory`
- `AceStepTimeline`
- `AceStepSection`

ACE-Step remains infrastructure behind a port.

---

## 12. Proposed adaptation architecture

```text
EH Story (+ Understanding / Experience Plan)
    ↓
Narrative Understanding (EH — already evolving)
    ↓
EH Music Creative Director (application)
    ↓
Narrative Music Timeline (application / lab artifact)
    ↓
ACE-Step EH Adapter (infrastructure)
    ├─ compile caption
    ├─ compile lyrics / phase tags
    ├─ compile metas + duration
    ├─ optional reference / LoRA selection
    └─ optional phase→repaint mapping
    ↓
ACE-Step Planner (optional; often bypassed)
    ↓
ACE-Step Audio Model (DiT + VAE)  ← keep intact
    ↓
Personalized Music rendering
```

### Module change classification

| ACE-Step area | Change class | Recommendation |
|---|---|---|
| VAE / codec | no change | Do not touch |
| DiT architecture | no change | Do not touch |
| Diffusion / sampling / DCW kernels | no change | Do not touch unless proven necessary |
| Lyric/text encoders | no change | Soft conditioning already flexible |
| `GenerationParams` API | configuration / adapter | Consume as-is |
| Built-in inspiration prompts | prompt modification (optional fork) | Replace with EH narrative prompts if using ACE planner |
| External planning messages | prompt modification | Easy EH specialization |
| Constrained metas FSM | no change initially | Already enough for bpm/duration/key |
| Runtime schema for sections | schema modification (optional later) | Prefer adapter-side timeline over forking ACE schema |
| Training data | training-data modification (later) | Narrative-labeled examples |
| LoRA | LoRA (later) | Hero/user identity |
| Full audio SFT | model fine-tuning (last resort) | Only if soft+LoRA fail |
| DiT architecture change | model architecture change | Avoid |

### What should NOT be changed (if possible)

- Audio codec / VAE
- Diffusion transformer architecture
- Sampling / ODE-SDE / DCW internals
- Low-level latent hop contract (`1920` @ 48 kHz)
- GPU kernels / MLX convert paths (except bugs)
- 5Hz audio-code vocabulary machinery (unless EH explicitly adopts codes)

Change semantic planning/conditioning first.

---

## 13. Training strategy

Target data shape (conceptual):

```text
Story / Narrative Role / Emotional Arc / Timeline / Lyrics / Music Description / Audio
```

### Can existing pipeline consume this?

**Partially yes**, after compilation:

| EH concept | Compile to ACE sample field |
|---|---|
| Music description | `caption` |
| Lyrics | `lyrics` |
| Timeline phase names | tags inside `lyrics` and/or caption timestamps |
| Emotional arc | caption prose |
| Audio | `audio_path` |
| BPM/key/duration | metas |

Existing pipeline cannot natively store a rich phase graph; flatten first (same pattern Muse already uses).

### Ranked feasibility

| Rank | Strategy | Feasibility | Notes |
|---|---|---|---|
| 1 | Prompt-only specialization | Highest | EH adapter + caption/lyrics; zero training |
| 2 | Planner prompt / external planner SFT-lite | High | Change planning messages; keep DiT frozen |
| 3 | LoRA on DiT with narrative-tagged set | High–medium | Uses existing LoRA training path; few songs possible for style, more needed for arc reliability |
| 4 | Planner/LM fine-tuning (5Hz LM) | Medium | Better structured lyrics/metas for EH; still no hard timeline |
| 5 | Audio-model SFT | Lower | Expensive; only if LoRA insufficient |
| 6 | Full model training | Lowest | Unnecessary for first proof |

**Initial recommendation:** fine-tune **nothing**. Prove with adapter + prompt specialization. If arcs are inconsistent, LoRA on narrative-labeled shorts before touching full SFT.

---

## 14. POC proposal

### Goal

Prove that music progression changes because the **narrative timeline** changed — not because a human rewrote unrelated prompts.

### Smallest experiment

**Inputs (fixed story text; two timelines):**

Shared story seed: short EH-style arc (challenge → struggle → breakthrough → resolution).

- Timeline A: standard EH phases with low→high→settle energy curve.
- Timeline B: same phases reordered or with breakthrough energy suppressed / moved earlier.

Adapter compiles each timeline deterministically to caption+lyrics+duration (no manual artistic rewriting beyond the compiler).

**Expected planner/adapter output:** structured timeline JSON (EH/adapter-side) + compiled ACE `GenerationParams`.

**Expected audio artifact:** 2–4 minute piece.

**Success criteria:**

1. Blind listeners can order sections by energy matching Timeline A more often than chance.
2. Timeline B yields measurably different sectional energy profile (RMS / onset density / human rating) in corresponding windows.
3. Holding seed/model fixed, only timeline compiler inputs differ.
4. Optional: repaint only “breakthrough” window and show local change with surrounding similarity.

**Controls:**

- Same seed, model (`turbo` or `sft`), duration, bpm/key if set.
- One arm using conventional `[Verse]/[Chorus]` compilation; one arm using EH phase tags — compare reliability.
- ACE inspiration LM **off** for the primary arm so EH owns planning.

**Out of scope for POC:** EH domain types, production proxy, LoRA, weight training, UI polish.

---

## 15. Option A vs Option B

### Option A — EH adapts to ACE-Step

```text
EH → ACE-compatible song structure → ACE-Step
```

### Option B — ACE-Step adapts to EH

```text
EH Narrative Music Model → ACE-Step adaptation layer → ACE-Step audio engine
```

| Criterion | Option A | Option B |
|---|---|---|
| Maintainability | Couples EH product language to pop-song forms; breaks when provider changes | EH language stable; adapters swappable |
| Expressive power | Weak for non-song narrative experiences | Stronger; phases/energy/roles preserved |
| Personalization | Limited to prompt hacks in song form | Aligns with EH personalization → creative director |
| Future AI models | Rework EH each time | Replace adapter/provider |
| Provider replacement | Poor (EH encodes ACE idioms) | Good (port + adapter) |
| Training complexity | Lower short-term | Slightly higher later if specializing ACE |
| Non-musical narrative concepts | Forced into Verse/Chorus metaphors | Kept as narrative until compile |
| Story-following music | Accidental | Intentional compilation target |
| Compatibility with EH architecture | Conflicts with “domain expresses what; infra renders how” | Matches hexagonal / port direction |

**Conclusion after source inspection:** Option B is the better long-term architecture. Option A is only acceptable as a temporary compiler backend strategy *inside* an Option B adapter (i.e., optionally emit Verse/Chorus as one rendering choice), not as EH’s conceptual model.

---

## 16. Risks

1. **Distribution shift:** EH phase tags may be weakly understood vs `[Chorus]`.
2. **Soft timing:** absolute phase timing is not hard-controlled; music may drift relative to intended windows.
3. **Planner rewrite drift:** ACE CoT/inspiration can mutate EH intent if left enabled.
4. **Repaint seam artifacts:** phase replace may audible-glitch without careful crossfade / prompt continuity.
5. **Stem fidelity gap:** “keep vocals, change bed” is non-trivial.
6. **License/ops:** MIT code ≠ automatic rights to all weights / hosted APIs.
7. **Compute:** local generation needs GPU; XL quality needs more VRAM.
8. **Product confusion:** risk of treating ACE song metaphysics as EH domain — must keep adapter boundary.
9. **Evaluation difficulty:** “follows the story” is partly subjective; POC needs measurable proxies.
10. **Over-training temptation:** jumping to full SFT before adapter proof wastes effort.

---

## 17. Open questions

1. Should EH experiences be primarily **instrumental narrative beds** or lyric songs for M1/HS demos?
2. Is approximate soft timing enough for Hero Story playback sync, or do we need hard bar/beat alignment later?
3. Prefer EH semantic tags, conventional tags, or hybrid compiler modes?
4. Should ACE’s 5Hz LM be used for lyrics only, metas only, or fully bypassed?
5. Where do phase→time maps live — lab `MusicRendering` / render manifest only?
6. How much LoRA identity is desirable vs Discovery-driven style captions?
7. Do we need multi-clip section stitching (generate phases separately) if single-pass arc control is weak?
8. Weight licensing and deployment topology (local GPU service vs hosted)?
9. How to evaluate narrative adherence objectively beyond listener studies?
10. Interaction with existing EH voice timeline — music follows speech pauses or independent musical arc?

---

## 18. Recommended next step

1. **Do not integrate ACE-Step into EH yet.**
2. Stand up an **out-of-repo / infra spike**: ACE-Step EH Adapter that compiles a hand-authored Narrative Music Timeline → `GenerationParams`.
3. Run the **POC** in §14 with inspiration LM off; compare EH tags vs Verse/Chorus compiler backends.
4. If soft single-pass arcs are insufficient, add **phase-targeted repaint** as the second spike (still no EH domain types).
5. Only then consider wiring through a future `MusicGenerationPort` behind the AI Experience lab — keeping ACE-Step concepts out of the EH domain.
6. Defer LoRA / planner SFT until POC metrics show clear failure modes that training would fix.

### Answer to the most important question

**Yes — ACE-Step can become an EH-oriented narrative music engine while retaining its powerful underlying generation stack**, provided EH specializes the **planning/conditioning/adapter layer** and treats `[Verse]/[Chorus]` as optional compiler vocabulary rather than EH ontology. The underlying DiT/VAE need not change for the first architecture bet; evidence does not show they fundamentally require conventional song sections.

---

## Appendix A — Key source map

| Concern | Path |
|---|---|
| Package version / deps | `pyproject.toml` |
| License | `LICENSE` |
| Generation params | `acestep/inference.py` (`GenerationParams`) |
| Planner LM | `acestep/llm_inference.py` (`LLMHandler`) |
| Constrained metas | `acestep/constrained_logits_processor.py` |
| Constants / prompts | `acestep/constants.py` |
| Handler composition | `acestep/handler.py` |
| Lyric formatting | `acestep/core/generation/handler/prompt_utils.py` |
| Repaint masks | `acestep/core/generation/handler/conditioning_masks.py` |
| External planner | `acestep/text_tasks/external_ai_request_helpers.py` |
| Training sample schema | `acestep/training/dataset_builder_modules/models.py` |
| LoRA | `acestep/core/generation/handler/lora/` |
| MLX | `acestep/models/mlx/` |
| Structure-tag guidance | `docs/en/Tutorial.md`, `docs/en/LoRA_Training_Tutorial.md` |
| Muse sections flatten | `docs/en/Large_Scale_SFT_Training_Guide.md` |
| Install / hardware | `docs/en/INSTALL.md` |

## Appendix B — Relation to current EH docs

This evaluation is consistent with:

- `docs/architecture/AI-Experience-Provider-Laboratory-Plan.md` — `MusicGenerationPort`, lab artifacts, no provider types in domain.
- HS-ADR direction that `StoryExperiencePlan` music guidance stays descriptive.
- Hexagonal rule: EH expresses **what experience**, infrastructure decides **how to render**.

It intentionally does **not** propose EH domain aggregates for ACE-Step concepts.
