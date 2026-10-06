# ACE-Step EH Narrative Music Adapter — Out-of-Repo POC

**Status:** Spike / proof of compile path  
**Architecture:** Option B (EH Narrative Music Model → ACE-Step Adapter → ACE-Step audio engine)  
**Parent evaluation:** `docs/architecture/ACE-Step-1.5-EH-Narrative-Music-Evaluation.md`

This directory is **not** EH domain code. It does not import Flutter, Riverpod, or ACE-Step. It exists to prove the adapter-first bet before any `MusicGenerationPort` wiring.

## Goal

Same story, two timelines, inspiration LM **off** → prove the compiled ACE-Step plan changes because the **narrative timeline** changed.

```text
EH Story → Creative Director → Narrative Music Timeline
    → ACE-Step Adapter (compile caption/lyrics/metas/duration/repaint windows)
    → ACE-Step audio model (unchanged)
```

## Layout

```text
spikes/ace-step-eh-adapter/
├── fixtures/           # shared story + Timeline A / Timeline B
├── src/ace_step_eh_adapter/
│   ├── models.py       # NarrativeMusicTimeline (spike-only)
│   ├── compiler.py     # → ACE GenerationParams-shaped request
│   └── fixtures_io.py
├── scripts/compile_poc.py
├── tests/
└── out/                # gitignored compiled JSON (generated)
```

## Quick start

```bash
cd spikes/ace-step-eh-adapter
python -m pytest -q
python scripts/compile_poc.py
python scripts/compile_poc.py --mode conventional
```

Expected invariant summary:

- `same_story_id: true`
- `inspiration_lm_off: true`
- `caption_differs: true`
- `lyrics_differ: true`
- `phase_windows_differ: true`

## What is / is not proven

| Proven by this spike | Not proven yet (needs GPU + ACE-Step runtime) |
|---|---|
| Timeline → caption/lyrics/metas compile is deterministic | Audible sectional energy follows the timeline |
| Inspiration LM flags forced off | Blind listener ordering of sections |
| Phase → `repainting_start/end` mapping | Repaint seam quality |
| EH tags vs conventional tags as compiler backends | Which tag vocabulary is more reliable |

## Boundary rules

- Do **not** put ACE-Step types in the EH domain.
- Future EH boundary remains `MusicGenerationPort` (provider-agnostic).
- Conventional `[Verse]` / `[Chorus]` may be used only as an optional **compiler backend**, never as EH ontology.
- Do not download ACE-Step weights from this spike by default.

## Next (when a GPU host is available)

1. Take `out/timeline-a-*.json` / `out/timeline-b-*.json` `params` objects.
2. Call ACE-Step `/release_task` (or Gradio) with **inspiration / CoT rewrite disabled**, fixed seed/model.
3. Compare RMS / onset density / listener ratings in phase windows from `phase_windows`.
4. Optional second spike: repaint only Breakthrough using `example_repaint_breakthrough`.
