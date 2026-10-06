# ACE-Step 1.5 installation notes for this POC
# =============================================
#
# Upstream clone (NOT modified, NOT forked for the experiment):
#   Location: /home/ubuntu/ai-poc/ACE-Step-1.5
#   Repo:     https://github.com/ACE-Step/ACE-Step-1.5
#   Commit:   ca1e85fe9430179831e6bc6be790c332190a3866
#   Version:  1.5.0
#
# Installation method:
#   cd /home/ubuntu/ai-poc/ACE-Step-1.5
#   uv sync
#
# Model download (DiT-only; Inspiration LM intentionally not required):
#   export ACESTEP_PROJECT_ROOT=/home/ubuntu/ai-poc/ACE-Step-1.5
#   export ACESTEP_CHECKPOINTS_DIR=$ACESTEP_PROJECT_ROOT/checkpoints
#   export ACESTEP_INIT_LLM=false
#   uv run python -c "from acestep.model_downloader import download_main_model; download_main_model()"
#   # Or download only needed components if a selective API is available.
#
# Inference entry point used by the POC:
#   acestep.inference.generate_music(dit_handler, llm_handler=None, params, config, save_dir=...)
#   CLI alternative: python cli.py --config config.toml
#
# Relevant generation parameters held constant:
#   bpm, keyscale, timesignature, vocal_language, duration,
#   inference_steps, guidance_scale, seed (matched A/B),
#   dit model = acestep-v15-turbo
#
# Seed support: YES (GenerationParams.seed + GenerationConfig.seeds, use_random_seed=False)
# Duration support: YES (GenerationParams.duration, 10–600s)
# Caption support: YES
# Lyrics support: YES (free-form text; section tags optional convention)
# Metadata support: YES (bpm/keyscale/timesignature/language)
# Repaint/edit support: YES (not used in this first A/B experiment)
#
# Inspiration LM disable method (documented for the POC):
#   1. GenerationParams.thinking = False
#   2. use_cot_metas = use_cot_caption = use_cot_lyrics = use_cot_language = False
#   3. llm_handler = None (never initialized)
#   4. ACESTEP_INIT_LLM=false
#
# Hardware note for this cloud agent environment:
#   CPU-only (no NVIDIA GPU). ACE-Step supports CPU inference but it is slow.
#   Experiment uses short duration (48s) and turbo DiT with thinking=False.
