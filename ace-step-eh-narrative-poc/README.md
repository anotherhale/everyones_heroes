# ACE-Step EH Narrative Music Adapter POC

Isolated proof of concept. **Not** part of the Everyone’s Heroes production domain.

## 1. Purpose

Test whether the same story, rendered through two different `NarrativeMusicTimeline`s, produces materially different music when ACE-Step model and other controls are held constant.

Causal variable under test: **NarrativeMusicTimeline**

Hypothesis under test:

```text
EH narrative intent
    ↓
NarrativeMusicTimeline
    ↓
provider adapter
    ↓
ACE-Step
    ↓
meaningfully different music
```

## 2. Architecture

```text
EH Story (inputs/story.txt)
    ↓
MusicCreativeDirection (inputs/creative_direction.json)
    ↓
NarrativeMusicTimeline A | B
    ↓
ACE-Step Adapter (src/ace_step_adapter.py)
    ↓
caption + lyrics + metas + duration
    ↓
ACE-Step 1.5 (external install; not vendored)
    ↓
Audio
```

Provider-neutral POC types live in `src/narrative_music.py`.  
ACE-Step-specific compilation stops at `src/ace_step_adapter.py`.

## 3. Installation

```bash
# 1) Install ACE-Step 1.5 at the pinned commit (outside EH production code)
git clone https://github.com/ACE-Step/ACE-Step-1.5.git /home/ubuntu/ai-poc/ACE-Step-1.5
cd /home/ubuntu/ai-poc/ACE-Step-1.5
git checkout ca1e85fe9430179831e6bc6be790c332190a3866
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync

# 2) Download DiT-capable main checkpoints
export ACESTEP_PROJECT_ROOT=/home/ubuntu/ai-poc/ACE-Step-1.5
export ACESTEP_CHECKPOINTS_DIR=$ACESTEP_PROJECT_ROOT/checkpoints
export ACESTEP_INIT_LLM=false
uv run python -c "from pathlib import Path; from acestep.model_downloader import download_main_model; print(download_main_model(Path('$ACESTEP_CHECKPOINTS_DIR')))"

# 3) POC Python deps for tests/report helpers (in ACE-Step venv or system)
uv pip install pytest
```

See also `docs/ACE_STEP_INSTALL.md`.

## 4. ACE-Step version

| Item | Value |
|---|---|
| Repository | https://github.com/ACE-Step/ACE-Step-1.5 |
| Commit | `ca1e85fe9430179831e6bc6be790c332190a3866` |
| Package version | `1.5.0` |

## 5. Model

- DiT: `acestep-v15-turbo`
- VAE + `Qwen3-Embedding-0.6B` (required conditioning path)
- Inspiration / 5Hz LM: **not used** for generation

## 6. How to run

```bash
cd ace-step-eh-narrative-poc
export ACESTEP_ROOT=/home/ubuntu/ai-poc/ACE-Step-1.5
export ACESTEP_PROJECT_ROOT=$ACESTEP_ROOT
export ACESTEP_CHECKPOINTS_DIR=$ACESTEP_ROOT/checkpoints
export ACESTEP_INIT_LLM=false

# Adapter unit tests (no audio)
./scripts/run_experiment.sh --dry-run   # compile-only path via experiment args
# or:
"$ACESTEP_ROOT/.venv/bin/python" -m pytest tests/ -q

# Full A/B generation + comparison
./scripts/run_experiment.sh
```

One-command reproducibility target: `./scripts/run_experiment.sh`

## 7. How inspiration LM is disabled

Mandatory for the controlled experiment:

1. `GenerationParams.thinking = False`
2. `use_cot_metas = use_cot_caption = use_cot_lyrics = use_cot_language = False`
3. `llm_handler = None` (never initialized)
4. Environment: `ACESTEP_INIT_LLM=false`

Desired pipeline:

```text
NarrativeMusicTimeline → deterministic adapter → ACE-Step
```

Not:

```text
NarrativeMusicTimeline → LLM reinterpretation → ACE-Step
```

## 8. Experiment design

Two adapter representations:

| Strategy | Description |
|---|---|
| `natural_tags` | Lyrics include narrative tags such as `[Opening]`, `[Struggle]`, `[Breakthrough]`, `[Resolution]` — **not** forced `[Verse]`/`[Chorus]`/`[Bridge]` |
| `caption_only` | No explicit section tags; arc encoded in caption prose |

Timelines:

- **A** intimate / reflective (sparse, restrained, peaceful ending)
- **B** cinematic / transformational (build → breakthrough → resolution)

Matched seeds: `42`, `123`, `777` (natural tags); caption-only uses seed `42` in the default script.

## 9. Controlled variables

Held constant across each A/B pair:

- story / lyrics body
- genre / broad musical style
- model + version
- duration, BPM, key, language
- sampling parameters (`inference_steps`, guidance path)
- seed
- Inspiration LM state (**OFF**)
- hardware/runtime configuration where practical

Independent variable: **NarrativeMusicTimeline**

Documented forced deviation: turbo path may override `guidance_scale` 7.0 → 1.0.

## 10. Timeline A

`inputs/timeline_a.json` — `intimate_reflective`

Trajectory: vulnerability → uncertainty → quiet struggle → introspection → gentle hope → peaceful resolution.

## 11. Timeline B

`inputs/timeline_b.json` — `cinematic_transformational`

Trajectory: vulnerability → challenge → tension → determination → breakthrough → triumph → resolution.

## 12. Output locations

```text
output/
├── strategy_natural_tags/seed_*/timeline_{a,b}/
│   ├── input.json
│   ├── compiled.json
│   ├── generation-metadata.json
│   └── audio.wav          # gitignored binary
├── strategy_caption_only/seed_*/...
├── spectrograms/
├── comparison.md
├── architecture-conclusion.md
├── comparison_metrics.json
├── deep_metrics.json
└── run_manifest.json
```

## 13. Results

| Item | Result |
|---|---|
| Section-tag experiment | **YES** — timeline materially affects music (soft) |
| No-section-tag experiment | **YES** — first-order A/B difference without tags |
| Narrative timeline materially affected music | **YES** (soft control) |
| Adapter boundary | **YES** |
| Inspiration LM required | **NO** |
| Production `MusicGenerationPort` | **NOT YET** |

Details: `output/comparison.md`, `output/architecture-conclusion.md`.

## 14. Limitations

- CPU-only inference in the cloud agent environment (no NVIDIA GPU)
- Short form (48 s), turbo DiT only
- Caption-only arm tested on one seed by default
- No formal multi-listener listening panel
- Soft timing: climax/resolution choreography is unreliable
- WAV binaries gitignored (metadata + spectrograms committed)

## 15. Next step

1. Keep this POC isolated from EH production.
2. Complete Phase 2 structural-control experiments (below).
3. Only after reliable phase timing evidence: draft an EH `MusicGenerationPort` ADR.

## Phase 2 — structural control

Phase 1 baseline is frozen under `output/phase-1/`.

Phase 2 asks whether the narrative timeline can control **where** musical changes occur.

```bash
./scripts/run_phase2.sh
# then (optional / separate):
"$ACESTEP_ROOT/.venv/bin/python" src/phase2_repaint.py --seed 42
"$ACESTEP_ROOT/.venv/bin/python" src/phase2_analyze.py
```

Adapter strategies (provider-specific; not EH ontology):

| Strategy | Lyrics structure |
|---|---|
| `narrative_tags` | `[Opening]`, `[Build]`, `[Breakthrough]`, … |
| `song_tags` | `[Intro]`, `[Verse]`, `[Pre-Chorus]`, `[Chorus]`, `[Outro]` |
| `caption_only` | no lyric section tags |

Outputs: `output/phase-2/` (results, plots, listening rubric, architecture conclusion).

GPU validation in the cloud agent environment: **UNAVAILABLE** (CPU-only).

## Non-goals (honored)

Do **not** promote these into EH production yet:

- `MusicCreativeDirection`
- `NarrativeMusicTimeline`
- `NarrativeMusicSegment`
- `MusicGenerationPort`
- ACE-Step adapter / dependency in Flutter or `services/ai_proxy`
