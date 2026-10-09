# Repaint experiment notes

## Intent

Target Timeline B **breakthrough** window via ACE-Step `task_type=repaint` while preserving surrounding material from a Timeline A base take.

## API contract (confirmed)

Compiled example fields:

- `task_type: repaint`
- `src_audio: <base wav>`
- `repainting_start` / `repainting_end` (seconds)
- `repaint_mode: balanced`
- `repaint_strength: 0.5`
- Inspiration LM flags forced off

For 48 s Phase 2 Timeline B, breakthrough window = **28.0–36.0 s**.

## Runtime on this host

| Attempt | Result |
|---|---|
| 48 s base + repaint | OOM killed during `src_audio` encode (~15 GiB anon-rss) |
| 24 s base + repaint (`repaint_24s/`) | OOM killed at same stage |

Base text2music takes **did** generate successfully. Failure is specifically the repaint path’s source-audio encode while DiT remains resident on CPU.

## Classification

Repaint effectiveness: **INCONCLUSIVE** (API yes; audio validation blocked by memory).

Re-run on a GPU host (≥16–24 GB recommended headroom) before architectural reliance.
