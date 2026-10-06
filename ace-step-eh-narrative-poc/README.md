# ACE-Step EH Narrative Music Adapter POC

Isolated proof of concept. **Not** part of the Everyone’s Heroes production domain.

## Purpose

Test whether the same story, rendered through two different `NarrativeMusicTimeline`s, produces materially different music when ACE-Step model and other controls are held constant.

Causal variable under test: **NarrativeMusicTimeline**

Held constant (to the extent ACE-Step allows):

- story / lyrics text
- genre / broad musical style
- model + version
- duration, BPM, key, language
- sampling parameters
- seed (matched A/B pairs)
- Inspiration LM **OFF**

## Architecture (experimental only)

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

## Layout

```text
ace-step-eh-narrative-poc/
├── README.md
├── requirements.txt
├── src/
│   ├── narrative_music.py
│   ├── ace_step_adapter.py
│   ├── experiment.py
│   └── compare.py
├── inputs/
│   ├── story.txt
│   ├── creative_direction.json
│   ├── timeline_a.json
│   └── timeline_b.json
├── output/
├── scripts/
│   └── run_experiment.sh
└── tests/
    └── test_adapter.py
```

## Prerequisites

1. Upstream ACE-Step 1.5 at commit `ca1e85fe9430179831e6bc6be790c332190a3866`
   (default expected path: `/home/ubuntu/ai-poc/ACE-Step-1.5`).
2. DiT-only checkpoints (Inspiration LM disabled):
   - `acestep-v15-turbo`
   - `vae`
   - `Qwen3-Embedding-0.6B`
3. Python 3.11–3.12.

Set environment variables if needed:

```bash
export ACESTEP_ROOT=/home/ubuntu/ai-poc/ACE-Step-1.5
export ACESTEP_CHECKPOINTS_DIR=$ACESTEP_ROOT/checkpoints
export ACESTEP_PROJECT_ROOT=$ACESTEP_ROOT
export ACESTEP_INIT_LLM=false
```

## Run adapter unit tests (no audio)

```bash
cd ace-step-eh-narrative-poc
python -m pytest tests/ -q
```

## Run the experiment

```bash
./scripts/run_experiment.sh
# or dry-run (compile only):
./scripts/run_experiment.sh --dry-run
```

## Section-tag strategies

| Strategy | Description |
|---|---|
| `natural_tags` | Lyrics include `[Opening]`, `[Struggle]`, … narrative tags |
| `caption_only` | No explicit section tags; arc encoded in caption prose |

## Non-goals

Do **not** promote these types into EH production:

- `MusicCreativeDirection`
- `NarrativeMusicTimeline`
- `NarrativeMusicSegment`
- `MusicGenerationPort`
- ACE-Step adapter / dependency

This POC produces evidence only.

## Results (this run)

- ACE-Step: `1.5.0` @ `ca1e85fe9430179831e6bc6be790c332190a3866`
- Model: `acestep-v15-turbo` (DiT-only; Inspiration LM OFF)
- Hardware: CPU-only
- Generations: 3 matched natural_tags seeds (42/123/777) + caption_only seed 42
- Reports:
  - `output/comparison.md`
  - `output/architecture-conclusion.md`
  - `output/spectrograms/`
- Verdict: timeline **materially affects** music (soft control). Production `MusicGenerationPort`: **NOT YET**.

