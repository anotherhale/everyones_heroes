# Architecture Conclusion — ACE-Step EH Narrative Music Adapter POC

**Date:** 2026-10-08 (re-validated; original run 2026-10-06)  
**Status:** Evidence from controlled standalone POC  
**Scope:** Experimental only. No EH production domain changes.

This document answers the ACE-Step 1.5 EH Narrative Music A/B POC questions explicitly.
It separates **Observed**, **Inferred**, and **Architectural conclusion**.

---

## Controlled experiment facts

| Item | Value |
|---|---|
| ACE-Step | `1.5.0` @ `ca1e85fe9430179831e6bc6be790c332190a3866` |
| Model | `acestep-v15-turbo` (DiT-only path) |
| Inspiration LM | **OFF** (`thinking=False`, `use_cot_*=False`, `llm_handler=None`, `ACESTEP_INIT_LLM=false`) |
| Hardware | CPU-only Xeon, 15 GiB RAM (no NVIDIA GPU) |
| Duration / BPM / key / language | 48 s / 92 / C Major / en |
| Seeds | 42, 123, 777 (natural tags); 42 (caption-only) |
| Independent variable | `NarrativeMusicTimeline` (A intimate vs B cinematic) |

---

## A. Does the provider-neutral narrative timeline work?

**YES**

Observed:
- POC types `MusicCreativeDirection`, `NarrativeMusicTimeline`, and `NarrativeMusicSegment` describe arcs without importing ACE-Step types.
- Adapter unit tests keep ACE-Step fields out of provider-neutral objects.
- The adapter compiles the same story + direction + different timelines into valid ACE-Step `caption` / `lyrics` / metas.

Inferred:
- EH can own narrative music intent above a provider adapter.

Architectural conclusion:
- Provider-neutral timeline is a viable experimental boundary. It is not yet a production domain aggregate.

---

## B. Does changing only the narrative timeline materially change the music?

**YES** (soft control)

Observed:
- Matched-seed A/B pairs produce different RMS envelopes for all three natural-tags seeds.
- Peak bin RMS is higher for Timeline B in 3/3 natural-tags pairs.
- Seed 42 spectrograms show denser mid/late high-frequency content for B.
- Directed “B always builds more late-vs-early” is **not** consistent (1/3).

Inferred:
- Timeline conditioning is causally real under matched seeds, but not a deterministic storyboard.

Architectural conclusion:
- Material musical difference is supported; precise choreography is not.

Classification for the most important question:

| Representation | Result |
|---|---|
| Section-tag (`natural_tags`) | **YES** |
| No-section-tag (`caption_only`) | **YES** |
| Overall | **YES** (soft) |

---

## C. Which dimensions appear controllable?

| Dimension | Controllability | Evidence |
|---|---|---|
| Peak intensity / coarse loudness | Partial | B peak RMS > A in 3/3 natural_tags |
| Spectral density / “bigness” | Partial | Seed 42 spectrograms denser for B |
| Envelope shape (timing of hits) | Partial | Distinct A/B envelopes every seed |
| Energy (continuous scalar → late build) | Weak | Directed late−early rise only 1/3 |
| Instrumentation identity | Inconclusive | Proxies cannot name instruments reliably |
| Vocal delivery | Inconclusive | No formal listening panel |
| Climax | Weak | Intermittent (strongest on seed 42) |
| Resolution | Weak | Common end fade |

---

## D. Which dimensions appear unreliable?

- Exact climax timestamp
- Guaranteed late-piece energy rise for “transformational” arcs
- Guaranteed sparse intimate opening across seeds
- Distinct peaceful vs triumphant resolution endings
- Mid-band HF activity as a stable rhythm/intensity proxy (1/3)

Evidence: `output/comparison.md`, `output/deep_metrics.json`.

---

## E. Are custom narrative section labels useful?

**INCONCLUSIVE** (leaning helpful, not required)

Observed:
- Natural-tags seed 42 spectrogram A/B contrast appeared more stark visually than caption-only.
- Natural tags are free-form text conventions, not DiT ontology.

Inferred:
- Tags may sharpen structural contrast as an adapter strategy option.

Architectural conclusion:
- Keep tags as an **adapter strategy**, not an EH domain requirement. Do not force `[Verse]` / `[Chorus]` / `[Bridge]`.

---

## F. Is a section-label-free representation viable?

**YES**

Observed:
- Caption-only seed 42 still produced a large peak-RMS gap (A 0.147 vs B 0.210).
- Spectrogram contrast exists without lyric section tags.

Architectural conclusion:
- Caption prose alone can differentiate A vs B for first-order differences.

---

## G. Does the adapter boundary work cleanly?

**YES**

Observed:
- All ACE-Step-specific compilation lives in `src/ace_step_adapter.py`.
- Provider-neutral types never import ACE-Step.
- Inspiration LM flags are forced off at the adapter/request boundary.
- No EH production code / Flutter / proxy changes were required.

Architectural conclusion:
- Option B (`NarrativeMusicTimeline → adapter → ACE-Step`) is clean for experimental use.

---

## H. Is inspiration LM required?

**NO**

Observed disable method (fully disabled):

1. `GenerationParams.thinking = False`
2. `use_cot_metas = use_cot_caption = use_cot_lyrics = use_cot_language = False`
3. `llm_handler = None`
4. `ACESTEP_INIT_LLM=false`

Differences still appeared from deterministic adapter compilation alone.

Architectural conclusion:
- For controlled EH narrative experiments, Inspiration LM should stay off so EH owns planning.

---

## I. Is the evidence sufficient to begin designing `MusicGenerationPort` in EH?

**NOT YET**

Why:
- Architectural *shape* (EH narrative → adapter → provider) is validated as feasible.
- Controllability is soft: timeline changes music, but not as a deterministic storyboard.
- Sample is small (3 seeds + 1 caption-only seed), CPU turbo only, no formal listening rubric.
- Promoting a production port now would risk freezing a soft conditioner as if it were hard control.

---

## Verdict summary

| Question | Answer |
|---|---|
| A. Provider-neutral timeline works | **YES** |
| B. Timeline materially changes music | **YES** (soft) |
| E. Custom section labels useful | **INCONCLUSIVE** |
| F. Section-label-free viable | **YES** |
| G. Adapter boundary clean | **YES** |
| H. Inspiration LM required | **NO** |
| I. Begin `MusicGenerationPort` | **NOT YET** |
| Evidence strength | **MEDIUM** |

---

## Recommended next architectural step

1. **Keep POC isolated**; do not merge narrative music types into EH domain yet.
2. Re-run the same A/B protocol on **GPU** with the same commit/model and a formal listening rubric (energy, climax, intimacy, resolution).
3. Add a third adapter strategy: conventional `[Verse]`/`[Chorus]` compiler target as control.
4. Test **phase-targeted repaint** (`repainting_start/end`) as a harder timing control once a base take exists.
5. Only after repeated-seed + listening consistency: draft an EH `MusicGenerationPort` ADR with provider-neutral request/result types and adapter ownership rules.

---

## Explicit stop

This phase stops at evidence. No EH production domain, Flutter, ACE-Step dependency, or `MusicGenerationPort` implementation was added to the EH application.
