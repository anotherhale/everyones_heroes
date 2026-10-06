# Architecture Conclusion — ACE-Step EH Narrative Music Adapter POC

**Date:** 2026-10-06  
**Status:** Evidence from controlled standalone POC  
**Scope:** Experimental only. No EH production domain changes.

---

## Answers

### 1. Can EH describe the musical narrative independently of ACE-Step?

**YES**

Evidence: POC types `MusicCreativeDirection`, `NarrativeMusicTimeline`, and `NarrativeMusicSegment` describe arcs without importing ACE-Step types (`src/narrative_music.py`). Adapter unit tests preserve provider-neutral concepts and keep ACE-Step fields out of those objects.

### 2. Can that narrative be compiled into ACE-Step?

**YES**

Evidence: `AceStepNarrativeAdapter` compiles story + direction + timeline into ACE-Step `caption` / `lyrics` / metas / `duration` / seed. Eight successful generations completed with Inspiration LM off.

### 3. Does changing only the narrative timeline materially affect the generated music?

**YES** (with soft-control caveats)

Evidence:

- Matched-seed A/B pairs produce different RMS envelopes for all three seeds.
- Peak RMS higher for Timeline B in 3/3 natural_tags pairs.
- Seed 42 spectrograms show denser mid/late high-frequency content for B.
- Directed “B always builds more late-vs-early” is **not** consistent (1/3).

So: material effect **yes**; precise choreography **no**.

### 4. Which dimensions are controllable?

Candidates with positive (partial) evidence:

| Dimension | Controllability | Evidence |
|---|---|---|
| Peak intensity / coarse loudness | Partial | B peak RMS > A in 3/3 natural_tags |
| Spectral density / “bigness” | Partial | Seed 42 spectrograms denser for B |
| Envelope shape (timing of hits) | Partial | Distinct A/B envelopes every seed |
| Energy (as a continuous scalar → late build) | Weak | Directed late−early rise only 1/3 |
| Instrumentation identity | Inconclusive | Proxies cannot name instruments reliably |
| Vocal delivery | Inconclusive | No formal listening panel |
| Climax placement | Weak | Intermittent |
| Resolution character | Weak | Common end fade |

### 5. Which dimensions are not reliably controllable?

- Exact climax timestamp
- Guaranteed late-piece energy rise for “transformational” arcs
- Guaranteed sparse intimate opening across seeds
- Distinct peaceful vs triumphant resolution endings
- Mid-band HF activity as a stable rhythm/intensity proxy (1/3)

Evidence: cross-seed tables in `output/comparison.md` and `output/deep_metrics.json`.

### 6. Are explicit section tags necessary?

**NO (not necessary for first-order difference); POSSIBLY HELPFUL for contrast**

Evidence:

- Caption-only seed 42 still produced a large peak-RMS gap (A 0.147 vs B 0.210).
- Natural-tags seed 42 spectrogram A/B contrast appeared more stark visually than caption-only.
- Upstream evaluation already showed tags are textual conventions, not DiT ontology.

Recommendation: keep tags as an **adapter strategy option**, not an EH domain requirement.

### 7. Is an LLM necessary for first-order narrative control?

**NO** (for this experiment)

Inspiration LM was fully disabled:

1. `GenerationParams.thinking = False`
2. `use_cot_metas = use_cot_caption = use_cot_lyrics = use_cot_language = False`
3. `llm_handler = None`
4. `ACESTEP_INIT_LLM=false`

Differences still appeared from deterministic adapter compilation alone.

### 8. What should eventually belong to EH?

Candidates (still experimental; not approved production objects yet):

- Story text / story identity
- Creative musical direction (genre/style/constraints)
- Narrative music timeline / segments (role, intent, energy, instrumentation intent, vocal delivery intent, relative duration)
- Future: `MusicGenerationPort` request/result contracts after stronger evidence

### 9. What must remain inside the ACE-Step adapter?

- Caption string formatting and timing prose
- Lyrics section-tag strategy (`[Opening]`, …) vs caption-only
- ACE-Step metas (`bpm`, `keyscale`, `timesignature`, `vocal_language`, `duration`)
- `GenerationParams` / `GenerationConfig` / seed wiring
- Inspiration LM enable/disable
- Repaint windows / task_type specifics
- Model checkpoint selection and device/offload details

### 10. Is the evidence strong enough to justify `MusicGenerationPort` in EH?

**NOT YET**

Reasoning:

- The architectural *shape* (EH narrative → adapter → provider) is validated as feasible.
- Controllability is soft: timeline changes music, but not as a deterministic storyboard.
- Sample is small (3 seeds + 1 caption-only seed), CPU turbo only, no formal listening rubric.
- Promoting a production port now would risk freezing a soft conditioner as if it were hard control.

---

## Verdict summary

| Question | Answer |
|---|---|
| Independent narrative description | YES |
| Compile into ACE-Step | YES |
| Timeline materially affects music | YES (soft) |
| Section tags required | NO |
| LLM required for first-order control | NO |
| Production `MusicGenerationPort` now | NOT YET |
| Evidence strength | MEDIUM |

---

## Recommended next architectural step

1. **Keep POC isolated**; do not merge narrative music types into EH domain yet.
2. Re-run the same A/B protocol on **GPU** with the same commit/model and a formal listening rubric (energy, climax, intimacy, resolution).
3. Add a third adapter strategy: conventional `[Verse]/[Chorus]` compiler target as control.
4. Test **phase-targeted repaint** (`repainting_start/end`) as a harder timing control once a base take exists.
5. Only after repeated-seed + listening consistency: draft an EH `MusicGenerationPort` ADR with provider-neutral request/result types and adapter ownership rules.

---

## Explicit stop

This phase stops at evidence. No EH production domain, Flutter, ACE-Step dependency, or `MusicGenerationPort` implementation was added to the EH application.
