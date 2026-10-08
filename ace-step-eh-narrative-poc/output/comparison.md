# Narrative Music Timeline A/B Comparison

Generated: 2026-10-08 (reformatted; measurements from controlled run 2026-10-06T17:48–18:00Z)

This report separates **Observed** measurements from **Inference** and **Architectural conclusion**.

## Method

- Same story lyrics body for Timeline A and B (`inputs/story.txt`).
- Same creative direction (genre=`cinematic indie folk-pop`, BPM=92, key=C Major, language=en, duration=48s).
- Same ACE-Step model (`acestep-v15-turbo` @ commit `ca1e85fe…`).
- Inspiration LM **OFF** (`thinking=False`, `use_cot_*=False`, `llm_handler=None`, `ACESTEP_INIT_LLM=false`).
- Matched seeds across A/B pairs: 42, 123, 777 (natural tags); seed 42 also for caption-only.
- Objective proxies: per-bin RMS, high-frequency activity proxy, spectrograms, RMS envelopes.
- Hardware: CPU-only (no NVIDIA GPU), 15 GiB RAM.

Supporting artifacts:

- `output/comparison_metrics.json`
- `output/deep_metrics.json`
- `output/spectrograms/natural_tags_rms_envelopes.png`
- `output/spectrograms/seed42_ab_strategies.png`
- `output/run_manifest.json`

---

## Generation inventory

| Strategy | Seed | Timeline A | Timeline B | Status |
|---|---:|---|---|---|
| natural_tags | 42 | audio.wav | audio.wav | ok |
| natural_tags | 123 | audio.wav | audio.wav | ok |
| natural_tags | 777 | audio.wav | audio.wav | ok |
| caption_only | 42 | audio.wav | audio.wav | ok |

All outputs are 48.000 s WAV @ 48 kHz.

---

## Pair 1 — natural_tags / seed 42

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | Gradual mid-piece lift; late−early RMS rise `+0.057` | Stronger mid spike (~26 s); late−early rise `+0.068` |
| Instrumentation | Sparse piano/pad-like bed with restrained accompaniment | Broader ensemble-like density in mid/late region |
| Arrangement density | More distributed mid peaks | Sharper spike near ~26 s (local RMS >0.35) |
| Rhythmic intensity | Shared transient grid with A under same seed | Same tempo/phrasing grid; denser mid hits |
| Harmonic/emotional character | Reflective / restrained brightness | Brighter/denser high-frequency content ~20–40 s |
| Vocal delivery | Present; intimate-to-warm storytelling character | Present; stronger mid delivery impression on listen |
| Climax | Mild crest around 24 s (peak bin RMS `0.182`) | Clearer spike near 24–26 s (peak bin RMS `0.193`) |
| Resolution | Common end fade | Common end fade; not strongly differentiated |
| Narrative coherence | Soft intimate arc readable | More “build” character mid-piece; not a hard storyboard |

### Observed / Inference / Conclusion

Observed: B shows sharper mid energy and denser HF region; shared seed keeps phrasing aligned.  
Inference: cinematic timeline increases mid intensity/density for this seed.  
Architectural conclusion: one supportive evidence point for energy/density responsiveness.

---

## Pair 2 — natural_tags / seed 123

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | Late−early rise `+0.022` | Late−early rise `-0.005` (B did **not** rise more) |
| Instrumentation | Held sparse/moderate bed | Early bursts suggest denser early hits (~3 s, ~12 s) |
| Arrangement density | Peak later (~30 s, RMS `0.153`) | Peak earlier (~24 s, RMS `0.162`) |
| Rhythmic intensity | Later concentration of activity | Earlier hits A lacks; structures visibly different |
| Harmonic/emotional character | More reserved early | More active early; not a clean triumph arc |
| Vocal delivery | Restrained storytelling | Earlier assertiveness; not reliably “powerful climax” |
| Climax | Later peak bin | Earlier peak; breakthrough localization weak |
| Resolution | End fade | End fade |
| Narrative coherence | Partial intimate reading | Different envelope, but not the requested late breakthrough |

### Observed / Inference / Conclusion

Observed: envelopes differ; directed “B builds more” fails for this seed.  
Inference: timeline control is real but non-monotonic / imprecise.  
Architectural conclusion: supports “timeline affects music,” weakens linear energy mapping.

---

## Pair 3 — natural_tags / seed 777

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | Rise `+0.006` | Rise `-0.002` |
| Instrumentation | Moderate bed | Structurally different peak timing |
| Arrangement density | Peak RMS `0.130` @ 24 s | Peak RMS `0.142` @ 30 s |
| Rhythmic intensity | Peaks often out of phase vs B | Peaks land at different times than A |
| Harmonic/emotional character | Milder mid brightness (higher mid HF than B) | Peak louder but not clearly “triumphant” |
| Vocal delivery | Quiet/warm impression | Not a reliable powerful breakthrough delivery |
| Climax | Mid crest | Later crest than A for this seed; still soft |
| Resolution | End fade | End fade |
| Narrative coherence | Soft | Soft; climax placement unreliable |

### Observed / Inference / Conclusion

Observed: matched-seed A/B remain structurally different; breakthrough timing unreliable.  
Inference: timeline is a soft conditioner, not hard timing control.  
Architectural conclusion: absolute climax placement is not guaranteed by caption/tag channel alone.

---

## Pair 4 — caption_only / seed 42

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | Rise `+0.074` | Rise `+0.062` (A rises more on this proxy) |
| Instrumentation | Sparser mid/late impression | Denser mid/late spectrogram |
| Arrangement density | Peak RMS `0.147` @ 24 s | Peak RMS `0.210` @ 24 s (large gap) |
| Rhythmic intensity | Shared seed grid | Shared seed grid with denser mid activity |
| Harmonic/emotional character | More reserved spectral brightness | Denser mid/late brightness without section tags |
| Vocal delivery | Present | Present; peak intensity higher |
| Climax | Mid crest | Stronger peak intensity at same rough time |
| Resolution | End fade | End fade |
| Narrative coherence | Soft without tags | Soft without tags; first-order A/B difference still present |

### Observed / Inference / Conclusion

Observed: caption prose alone differentiates A vs B; natural-tags contrast looked more stark visually for the same seed.  
Inference: section tags are optional sharpeners, not required for first-order difference.  
Architectural conclusion: section-label-free representation is viable.

---

## Cross-seed summary (natural_tags)

| Metric | B>A count | Notes |
|---|---:|---|
| Late−early energy rise | 1 / 3 | Only seed 42 |
| Peak bin RMS | 3 / 3 | Mild, consistent |
| Mid HF proxy | 1 / 3 | Inconsistent |
| Max-RMS bin later in B | 1 / 3 | Inconsistent |

### Observed (aggregate)

1. **Energy trajectory:** Envelopes differ for every matched seed; directed “B builds more than A” is **not** consistent (1/3).
2. **Instrumentation / density:** Spectrograms for seed 42 show denser high-frequency content for B; peak RMS is higher for B in 3/3 natural_tags pairs.
3. **Density:** Mid/late spectral density often higher for B on seed 42; not uniformly proven across seeds by HF proxy.
4. **Rhythm:** Transient grid often aligns across A/B under the same seed; B sometimes adds earlier hits (seed 123).
5. **Harmonic/emotional character:** Not formally scored; spectrograms suggest broader brightness for B on seed 42.
6. **Vocal delivery:** Not reliably measurable from these proxies; listening impressions are informal only.
7. **Climax:** B does not consistently place a unique recognizable climax later/higher; seed 42 shows a sharp B spike.
8. **Resolution:** Most clips fade near the final bin regardless of timeline — resolution differentiation is weak.
9. **Narrative coherence:** Soft — music changes with narrative conditioning, but not as a precise storyboard execution.

### Inference (aggregate)

`NarrativeMusicTimeline` compiled into caption + lyrics is a **real causal conditioner** under matched seeds. Controllability is **soft and probabilistic**, strongest for coarse intensity/density differences, weakest for precise timed climax/resolution choreography.

### Architectural conclusion (aggregate)

Provider-neutral narrative timelines are a viable experimental EH boundary candidate. They should not yet be treated as deterministic music-direction APIs. Prefer more evidence (GPU runs, listening rubrics, optional repaint-window edits) before promoting `MusicGenerationPort` into production EH.

---

## Classification of the primary hypothesis

Same story + same model + same generation controls + same seed + different narrative timeline = different musical behavior?

| Experiment arm | Classification |
|---|---|
| Section-tag representation (`natural_tags`) | **YES** |
| No-section-tag representation (`caption_only`) | **YES** |

Caveat: YES means material difference, not reliable directed choreography.

---

## Evaluation checklist

- 1. Energy trajectory — differences present; directed control inconsistent
- 2. Instrumentation — suggestive via spectrogram density (esp. seed 42)
- 3. Density — suggestive; peak RMS bias toward B
- 4. Rhythm — shared seed grid; some early-hit differences
- 5. Harmonic/emotional character — not formally scored
- 6. Vocal delivery — not formally scored
- 7. Climax — intermittent (strongest on seed 42)
- 8. Resolution — weak differentiation (common fade-out)
- 9. Narrative coherence — soft / partial

## Uncontrolled / limited variables

- CPU-only inference (no CUDA device)
- Turbo model auto-overrides `guidance_scale` 7.0 → 1.0
- No formal human listening panel
- Duration fixed at 48 s (short form)
- Caption-only strategy tested on one seed only
- Inspiration LM fully disabled (by design)
