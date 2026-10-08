# Phase 2 Architecture Conclusion

**Date:** 2026-10-08  
**Scope:** Experimental only — no EH production domain / Flutter / proxy changes.  
**Phase 1 baseline:** preserved at `output/phase-1/`.

---

## Research answers

### 1. Does ACE-Step respond to narrative structure?

**YES**

Observed: matched-seed A/B pairs differ in RMS, onset density, and overall loudness across all three adapter strategies. Timeline A peaks at `gentle_hope` (9/9); Timeline B peaks at `breakthrough`/`climax` (9/9).

### 2. Can narrative structure control where musical changes occur?

**YES** (on this CPU turbo sample; still soft absolute timing)

Observed: intended phase windows correlate with measured mean-RMS per window (Timeline B mean energy-correlation 0.72–0.77 by strategy). Breakthrough−early RMS lift is positive in 9/9 pairs. This is substantially stronger than Phase 1’s “different envelopes, unreliable late-rise” finding.

Caveat: control remains prompt/conditioning soft control, not a hard sequencer. Seed variance remains visible in listening scores.

### 3. Which adapter strategy performs best?

**Narrative tags** (narrowly), with **song tags** nearly tied, and **caption-only** still effective.

| Strategy | Control class | Notes |
|---|---|---|
| Narrative tags | **strong** | Best mean corr_B (0.772) and breakthrough lift (0.129) |
| Song tags | **strong** | Mean corr_B 0.757; peaks in breakthrough/climax 3/3 |
| No tags | **moderate** | Peaks still correct 3/3; weaker average lift/listening consistency |
| Repaint | **inconclusive** | API windowing confirmed; CPU OOM blocked audio validation |

Combination note: caption timing prose + tags appears complementary; tags are not required for first-order phase peaks, but strengthen average alignment.

### 4. Are song-structure tags useful as an adapter implementation?

**YES — as an adapter technique only.**

Evidence: `song_tags` produced strong phase-peak placement and high B energy correlation. Conventional `[Verse]`/`[Chorus]` labels appear to be a useful soft compiler vocabulary for ACE-Step.

### 5. Are song-structure concepts appropriate for EH’s domain?

**NO**

Song labels must remain inside the provider adapter. EH should continue to express:

- `NarrativeMusicTimeline` / `NarrativeMusicSegment` (experimental → future port request types)

not Verse/Chorus/Bridge aggregates. Phase 2 confirms Option B: EH narrative → adapter compile → ACE-Step.

### 6. Does repaint provide useful phase-level control?

**INCONCLUSIVE**

- Window targeting: **YES** at the API/contract level (`repainting_start/end`).
- Audio effectiveness on this host: **not validated** — 48 s and 24 s attempts OOM-killed (~15 GiB) during `src_audio` encode with DiT resident.
- Recommend GPU host re-test before architectural reliance on repaint.

### 7. Is the provider-neutral timeline abstraction becoming stable enough to formalize?

**YES** (experimental contract readiness) / **NOT YET** as production aggregates

The Phase 2 timelines (`role`, `narrative_intent`, `energy`, instrumentation intent, vocal delivery intent, durations) produced measurable phase-aligned behavior without leaking ACE-Step types into the provider-neutral model. That is enough to draft a **port-facing request shape**. It is not enough to freeze EH domain aggregates without an ADR review.

### 8. Is the evidence sufficient to draft an EH MusicGenerationPort ADR?

**YES** — draft ADR, do not implement production code yet.

Why YES for drafting:

- Phase timing (not only “different music”) was demonstrated across 3 strategies × 3 seeds.
- Adapter boundary remains clean.
- Inspiration LM remains unnecessary for this control path.

Why not implement yet:

- CPU-only / turbo / no formal multi-listener panel.
- Repaint path unproven here.
- Product still needs ADR decisions on request/result contracts, explainability, and failure modes.

---

## Decision gate

| Condition | Outcome |
|---|---|
| Narrative structure changes music **and** phase timing | **Met** |
| Recommendation | **Draft EH `MusicGenerationPort` ADR** |
| Implementation | **Still forbidden in this phase** |

Recommended ADR scope:

1. Provider-neutral request: story / creative direction / narrative music timeline.
2. Provider-neutral result: audio artifact refs + render provenance + phase window map.
3. Adapter ownership of caption/lyrics/tag strategy/repaint.
4. Explicit non-goals: Verse/Chorus domain types; ACE-Step types in domain; Inspiration LM required.

Recommended follow-ups before production wiring:

1. GPU confirmation pass with the same seeds/strategies.
2. Formal listening panel using `listening-rubric.md`.
3. Complete repaint breakthrough-window validation on GPU.
4. Optional hybrid strategy: narrative tags default, song tags as adapter fallback.

---

## Explicit stop

No `MusicGenerationPort`, no EH production `NarrativeMusicTimeline`, no Flutter/proxy/ACE-Step production dependency was added.
