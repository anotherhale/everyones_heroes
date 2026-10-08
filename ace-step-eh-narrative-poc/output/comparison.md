# Narrative Music Timeline A/B Comparison

Generated: 2026-10-06T18:05:00+00:00

This report separates **Observed** measurements from **Inference** and **Architectural conclusion**.

## Method

- Same story lyrics body for Timeline A and B.
- Same creative direction (genre, BPM=92, key=C Major, language=en, duration=48s).
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

### Observed

- Energy rise (late−early RMS) A: `0.05718`; B: `0.06795`; Δ(B−A): `+0.01077`
- Peak bin RMS A: `0.182` @ 24 s; B: `0.193` @ 24 s
- RMS envelope: B shows a sharper spike near ~26 s (RMS >0.35 local) vs A’s more distributed mid peaks
- Spectrogram: B denser/brighter in ~20–40 s high-frequency region than A
- Both share similar transient timing (lyric/rhythm alignment under same seed)

### Inference

The cinematic timeline may be increasing mid-piece intensity and spectral density for this seed, while preserving tempo/phrasing structure fixed by seed + lyrics.

### Architectural conclusion (pair-local)

One supportive evidence point for energy/density responsiveness. Not sufficient alone.

---

## Pair 2 — natural_tags / seed 123

### Observed

- Energy rise A: `0.02227`; B: `-0.00491`; Δ(B−A): `-0.02718` (B did **not** rise more)
- Peak bin RMS A: `0.153` @ 30 s; B: `0.162` @ 24 s
- Mid-band HF proxy Δ(B−A): `+0.00235`
- RMS envelope: B has earlier bursts (~3 s, ~12 s) that A lacks; both have late peaks; structures are visibly different

### Inference

Timeline B changed the envelope shape and early activity, but not in the simple “B always builds more” direction. Narrative control appears real but **non-monotonic / imprecise**.

### Architectural conclusion (pair-local)

Supports “timeline affects music,” weakens “energy scalar maps linearly to late-piece build.”

---

## Pair 3 — natural_tags / seed 777

### Observed

- Energy rise A: `0.00560`; B: `-0.00191`; Δ(B−A): `-0.00750`
- Peak bin RMS A: `0.130` @ 24 s; B: `0.142` @ 30 s
- Mid HF Δ(B−A): `-0.00661` (A higher)
- RMS envelopes are out of phase: peaks of A and B often land at different times

### Inference

Matched-seed A/B outputs remain structurally different. Requested “breakthrough climax” is not reliably localized by the soft caption/tag channel alone.

### Architectural conclusion (pair-local)

Timeline is a useful soft conditioner; absolute timing of climax is not a hard control in ACE-Step’s flat contract.

---

## Pair 4 — caption_only / seed 42

### Observed

- Energy rise A: `0.07382`; B: `0.06202`; Δ(B−A): `-0.01180`
- Peak bin RMS A: `0.147` @ 24 s; B: `0.210` @ 24 s (large peak gap)
- Mid HF Δ(B−A): `+0.00369`
- Spectrogram: B denser mid/late than A; contrast exists without lyric section tags
- Natural-tags A/B for the same seed showed a more stark spectrogram contrast than caption-only in visual inspection

### Inference

Caption prose alone can differentiate A vs B. Explicit section tags are not strictly required for *some* difference, but may sharpen structural contrast.

### Architectural conclusion (pair-local)

Section tags remain optional soft controls, not a model ontology requirement — consistent with the architecture evaluation.

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
5. **Harmonic/emotional character:** Not objectively scored; spectrograms suggest broader brightness for B on seed 42.
6. **Vocal delivery:** Not reliably measurable from these proxies; requires listening panel (not performed as a formal study).
7. **Climax:** B does not consistently place a unique recognizable climax later/higher; seed 42 shows a sharp B spike.
8. **Resolution:** Most clips fade near the final bin regardless of timeline — resolution differentiation is weak.
9. **Narrative coherence:** Soft — music changes with narrative conditioning, but not as a precise storyboard execution.

### Inference (aggregate)

`NarrativeMusicTimeline` compiled into caption + lyrics is a **real causal conditioner** under matched seeds. Controllability is **soft and probabilistic**, strongest for coarse intensity/density differences, weakest for precise timed climax/resolution choreography.

### Architectural conclusion (aggregate)

Provider-neutral narrative timelines are a viable experimental EH boundary candidate. They should not yet be treated as deterministic music-direction APIs. Prefer more evidence (GPU runs, listening rubrics, optional repaint-window edits) before promoting `MusicGenerationPort` into production EH.

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
