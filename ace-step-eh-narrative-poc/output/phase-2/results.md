# Phase 2 Results — ACE-Step EH Narrative Music POC

## Environment

| Item | Value |
|---|---|
| CPU | Intel Xeon, 4 cores |
| GPU | **UNAVAILABLE** (`nvidia-smi` missing; `torch.cuda.is_available()=False`) |
| VRAM | N/A |
| CUDA | PyTorch build reports 12.8; no usable device |
| ACE-Step | `1.5.0` @ `ca1e85fe9430179831e6bc6be790c332190a3866` |
| Model | `acestep-v15-turbo` |
| Inspiration LM | **OFF** |
| Python / Torch | 3.12.3 / 2.10.0+cu128 |
| RAM | 15 GiB |

Phase 1 baseline preserved at `output/phase-1/` (untouched by Phase 2 writes).

## Generation configuration

Held constant across matched A/B pairs:

- story: `inputs/story.txt`
- creative direction: genre `cinematic indie folk-pop`, BPM 92, key C Major, timesignature 4, language `en`, duration 48 s
- model / version / inference_steps (8) / seed (matched)
- Inspiration LM disabled (`thinking=False`, all `use_cot_*=False`, `llm_handler=None`, `ACESTEP_INIT_LLM=false`)

Independent variables (separate experiments):

1. Narrative timeline (A intimate vs B transformation)
2. Adapter strategy (`narrative_tags` / `song_tags` / `caption_only`)

## Adapter strategies

| Strategy | EH concept | Adapter compilation |
|---|---|---|
| Narrative tags | `NarrativeMusicSegment.role` | `[Opening]`, `[Vulnerability]`, `[Build]`, `[Breakthrough]`, `[Climax]`, … |
| Song tags | same roles | `[Intro]`, `[Verse]`, `[Pre-Chorus]`, `[Chorus]`, `[Outro]` (**not** EH ontology) |
| No tags | same roles | caption prose only; identical plain lyrics |

## Matched seeds

42, 123, 777 × three strategies × timelines A/B → **18** successful text2music generations.

## Objective results

Source: `objective_summary.json`, `objective_metrics.json`, `plots/`.

### Timeline B intended-energy correlation (higher = better phase alignment)

| Strategy | mean corr(A) | mean corr(B) | corr(B)>0.6 |
|---|---:|---:|---:|
| narrative_tags | 0.720 | **0.772** | 3/3 |
| song_tags | 0.513 | **0.757** | 3/3 |
| caption_only | 0.540 | **0.715** | 2/3 |

### Did musical peaks land at intended locations?

| Strategy | Timeline A peak role | Timeline B peak role |
|---|---|---|
| narrative_tags | `gentle_hope` in **3/3** | `breakthrough` in **3/3** |
| song_tags | `gentle_hope` in **3/3** | `breakthrough`/`climax` in **3/3** |
| caption_only | `gentle_hope` in **3/3** | `breakthrough` in **3/3** |

### Breakthrough intensity (B)

`breakthrough_mean_rms − early(opening+vulnerability)_mean_rms` is **positive for 9/9** pairs.

Mean breakthrough−early:

| Strategy | Mean Δ RMS |
|---|---:|
| narrative_tags | **0.129** |
| song_tags | 0.105 |
| caption_only | 0.091 |

Overall RMS B−A positive in **9/9** pairs.

### Interpretation (objective)

Observed:

- Changing only the narrative timeline produces different envelopes under matched seeds.
- Measured energy peaks for B land in the intended breakthrough/climax region for all strategies/seeds.
- Measured energy peaks for A land in the intended gentle-hope region for all strategies/seeds.

Inferred:

- Phase 2 structural timelines achieved **phase-timing control**, not merely “different music.”
- Narrative tags show the strongest average B alignment and breakthrough lift; song tags are close; caption-only remains viable but weaker on average.

## Listening results

Rubric: `listening-rubric.md`  
Scores: `listening-scores.json`  
Blind copies: `blind/sample-*.wav` + `blind/mapping.json`

Method note: cloud agent has no reliable audio playback device; scores are **plot/envelope/onset-assisted structural listening**. Vocal delivery = **N/A**.

### Pair score table (Timeline B focus / overall pair)

| Pair | Strategy | Energy | Phase Transitions | Instrument Evolution | Rhythm | Climax Timing | Resolution | Overall |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 42 | Narrative tags | 5 | 5 | 4 | 5 | 5 | 4 | 5 |
| 42 | Song tags | 5 | 5 | 4 | 5 | 5 | 4 | 5 |
| 42 | No tags | 5 | 4 | 3 | 4 | 5 | 4 | 4 |
| 123 | Narrative tags | 4 | 4 | 3 | 4 | 4 | 3 | 4 |
| 123 | Song tags | 4 | 4 | 3 | 4 | 4 | 3 | 4 |
| 123 | No tags | 3 | 3 | 3 | 3 | 4 | 3 | 3 |
| 777 | Narrative tags | 5 | 4 | 4 | 4 | 5 | 3 | 4 |
| 777 | Song tags | 4 | 4 | 3 | 4 | 5 | 3 | 3 |
| 777 | No tags | 4 | 3 | 3 | 3 | 4 | 3 | 3 |

## Strongest control model

Operational definitions used here:

- **strong**: intended peak location correct in ≥3/3 seeds AND mean energy-correlation ≥0.75 AND breakthrough−early >0 on all seeds
- **moderate**: intended peak location mostly correct AND mean corr ≥0.60
- **weak**: inconsistent peak location or mean corr <0.60

| Strategy | Classification | Basis |
|---|---|---|
| Narrative tags | **strong** | 3/3 B peaks at breakthrough; mean corr_B 0.772; largest breakthrough lift |
| Song tags | **strong** | 3/3 B peaks at breakthrough/climax; mean corr_B 0.757 |
| No tags | **moderate** | 3/3 B peaks at breakthrough; mean corr_B 0.715; smaller lift; weaker listening consistency |
| Repaint | **inconclusive / blocked on CPU** | API window targeting confirmed; 48 s and 24 s encode both OOM (~15 GiB) |

## Repaint experiment

### API capability

ACE-Step `GenerationParams` supports:

- `task_type="repaint"`
- `src_audio`
- `repainting_start` / `repainting_end` (seconds)
- `repaint_mode` / `repaint_strength`

Compiled breakthrough window for 48 s Timeline B (seed 42): **28.0–36.0 s**.

### Runtime result on this host

- 48 s repaint **OOM-killed** while encoding `src_audio` with DiT resident (~15 GB anon-rss).
- 24 s `--duration 24` path also **OOM-killed** at the same encode stage (base text2music succeeded).
- Therefore: **time-window targeting is supported by the API**, but **phase-repaint audio effectiveness could not be validated on this CPU/15 GiB host**.
- Details: `repaint/README.md`.

## GPU validation

**UNAVAILABLE** — do not claim GPU validation for Phase 2.

## Decision gate (from evidence)

Narrative structure reliably changes musical behavior **and** phase timing (peak locations) under CPU turbo matched seeds.

Recommendation:

> Draft EH `MusicGenerationPort` ADR — with soft-control caveats and adapter-owned song-tag optionality — **after** a GPU confirmation pass if practical; evidence already exceeds Phase 1 “soft difference only.”

Conservative alternative if product requires hard guarantees before any ADR:

> Continue GPU + formal listening panel + completed repaint validation before freezing the port contract.
