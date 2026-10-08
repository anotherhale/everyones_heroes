# Narrative Music Timeline A/B Comparison

Generated: 2026-10-08T02:22:44.694816+00:00

This report separates **Observed** measurements from **Inference** and **Architectural conclusion**.

## Method

- Same story lyrics body for Timeline A and B.
- Same creative direction (genre, BPM, key, language, duration).
- Same ACE-Step model; Inspiration LM OFF.
- Matched seeds across A/B pairs.
- Objective proxies: per-bin RMS (energy/density proxy) and zero-crossing rate (high-frequency/rhythmic activity proxy).
- These proxies are imperfect; listening notes remain required.

## Pair 1 — caption_only / seed_42

- Timeline A dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_caption_only/seed_42/timeline_a`
- Timeline B dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_caption_only/seed_42/timeline_b`
- Audio A: `/workspace/ace-step-eh-narrative-poc/output/strategy_caption_only/seed_42/timeline_a/audio.wav`
- Audio B: `/workspace/ace-step-eh-narrative-poc/output/strategy_caption_only/seed_42/timeline_b/audio.wav`

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | late−early RMS `0.07501` | late−early RMS `0.06843` (ΔB−A `-0.00658`) |
| Arrangement density | overall RMS `0.102031` | overall RMS `0.118567` (ΔB−A `0.016536`) |
| Climax proxy | peak bin RMS `0.145789` @ `32.0`s | peak bin RMS `0.207125` @ `24.0`s |
| Instrumentation | proxy only — confirm by listening/spectrogram | proxy only — confirm by listening/spectrogram |
| Rhythmic intensity | ZCR bins in analysis JSON | ZCR bins in analysis JSON |
| Harmonic/emotional character | not scored objectively | not scored objectively |
| Vocal delivery | not scored objectively | not scored objectively |
| Resolution | inspect final RMS bin / end fade | inspect final RMS bin / end fade |
| Narrative coherence | soft — requires listening | soft — requires listening |

### Observed

- Energy rise (late−early RMS) Timeline A: `0.07501`
- Energy rise (late−early RMS) Timeline B: `0.06843`
- Δ energy rise (B−A): `-0.00658`
- Δ overall RMS (B−A): `0.016536`
- Max-RMS bin start A: `32.0s`
- Max-RMS bin start B: `24.0s`

### Inference

Energy-rise difference is small on this proxy; narrative timeline may not strongly control global energy envelope for this pair.

### Architectural conclusion (pair-local)

Treat this pair as one evidence point only. Controllability claims require consistent direction across multiple matched seeds.

## Pair 2 — natural_tags / seed_123

- Timeline A dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_123/timeline_a`
- Timeline B dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_123/timeline_b`
- Audio A: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_123/timeline_a/audio.wav`
- Audio B: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_123/timeline_b/audio.wav`

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | late−early RMS `0.024543` | late−early RMS `-0.003626` (ΔB−A `-0.028169`) |
| Arrangement density | overall RMS `0.102039` | overall RMS `0.114464` (ΔB−A `0.012425`) |
| Climax proxy | peak bin RMS `0.16625` @ `32.0`s | peak bin RMS `0.169271` @ `32.0`s |
| Instrumentation | proxy only — confirm by listening/spectrogram | proxy only — confirm by listening/spectrogram |
| Rhythmic intensity | ZCR bins in analysis JSON | ZCR bins in analysis JSON |
| Harmonic/emotional character | not scored objectively | not scored objectively |
| Vocal delivery | not scored objectively | not scored objectively |
| Resolution | inspect final RMS bin / end fade | inspect final RMS bin / end fade |
| Narrative coherence | soft — requires listening | soft — requires listening |

### Observed

- Energy rise (late−early RMS) Timeline A: `0.024543`
- Energy rise (late−early RMS) Timeline B: `-0.003626`
- Δ energy rise (B−A): `-0.028169`
- Δ overall RMS (B−A): `0.012425`
- Max-RMS bin start A: `32.0s`
- Max-RMS bin start B: `32.0s`

### Inference

Timeline B did **not** show a larger energy rise than A on this proxy; timeline energy control may be weak or overridden by seed structure.

### Architectural conclusion (pair-local)

Treat this pair as one evidence point only. Controllability claims require consistent direction across multiple matched seeds.

## Pair 3 — natural_tags / seed_42

- Timeline A dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_42/timeline_a`
- Timeline B dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_42/timeline_b`
- Audio A: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_42/timeline_a/audio.wav`
- Audio B: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_42/timeline_b/audio.wav`

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | late−early RMS `0.076735` | late−early RMS `0.081345` (ΔB−A `0.00461`) |
| Arrangement density | overall RMS `0.112925` | overall RMS `0.115689` (ΔB−A `0.002764`) |
| Climax proxy | peak bin RMS `0.175141` @ `24.0`s | peak bin RMS `0.181476` @ `24.0`s |
| Instrumentation | proxy only — confirm by listening/spectrogram | proxy only — confirm by listening/spectrogram |
| Rhythmic intensity | ZCR bins in analysis JSON | ZCR bins in analysis JSON |
| Harmonic/emotional character | not scored objectively | not scored objectively |
| Vocal delivery | not scored objectively | not scored objectively |
| Resolution | inspect final RMS bin / end fade | inspect final RMS bin / end fade |
| Narrative coherence | soft — requires listening | soft — requires listening |

### Observed

- Energy rise (late−early RMS) Timeline A: `0.076735`
- Energy rise (late−early RMS) Timeline B: `0.081345`
- Δ energy rise (B−A): `0.00461`
- Δ overall RMS (B−A): `0.002764`
- Max-RMS bin start A: `24.0s`
- Max-RMS bin start B: `24.0s`

### Inference

Energy-rise difference is small on this proxy; narrative timeline may not strongly control global energy envelope for this pair.

### Architectural conclusion (pair-local)

Treat this pair as one evidence point only. Controllability claims require consistent direction across multiple matched seeds.

## Pair 4 — natural_tags / seed_777

- Timeline A dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_777/timeline_a`
- Timeline B dir: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_777/timeline_b`
- Audio A: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_777/timeline_a/audio.wav`
- Audio B: `/workspace/ace-step-eh-narrative-poc/output/strategy_natural_tags/seed_777/timeline_b/audio.wav`

### Human evaluation table

| Dimension | Timeline A (intimate) | Timeline B (cinematic) |
|---|---|---|
| Energy trajectory | late−early RMS `0.014849` | late−early RMS `-0.012028` (ΔB−A `-0.026877`) |
| Arrangement density | overall RMS `0.090808` | overall RMS `0.097884` (ΔB−A `0.007076`) |
| Climax proxy | peak bin RMS `0.139819` @ `32.0`s | peak bin RMS `0.138835` @ `32.0`s |
| Instrumentation | proxy only — confirm by listening/spectrogram | proxy only — confirm by listening/spectrogram |
| Rhythmic intensity | ZCR bins in analysis JSON | ZCR bins in analysis JSON |
| Harmonic/emotional character | not scored objectively | not scored objectively |
| Vocal delivery | not scored objectively | not scored objectively |
| Resolution | inspect final RMS bin / end fade | inspect final RMS bin / end fade |
| Narrative coherence | soft — requires listening | soft — requires listening |

### Observed

- Energy rise (late−early RMS) Timeline A: `0.014849`
- Energy rise (late−early RMS) Timeline B: `-0.012028`
- Δ energy rise (B−A): `-0.026877`
- Δ overall RMS (B−A): `0.007076`
- Max-RMS bin start A: `32.0s`
- Max-RMS bin start B: `32.0s`

### Inference

Timeline B did **not** show a larger energy rise than A on this proxy; timeline energy control may be weak or overridden by seed structure.

### Architectural conclusion (pair-local)

Treat this pair as one evidence point only. Controllability claims require consistent direction across multiple matched seeds.

## Classification of the primary hypothesis

Same story + same model + same generation controls + same seed + different narrative timeline = different musical behavior?

| Experiment arm | Classification |
|---|---|
| Section-tag representation (`natural_tags`) | see aggregate below |
| No-section-tag representation (`caption_only`) | see aggregate below |

Natural-tags directed late−early rise B>A: **1/3** (6-bin and 8-bin agree).  
Peak RMS B>A: **2/3** on 6-bin auto compare; **3/3** on 8-bin `deep_metrics.json` (seed 777 nearly tied in 6-bin).

Material A/B envelope/density differences across matched seeds support **YES** (soft control). Directed climax choreography remains unreliable.

## Evaluation checklist

- 1. Energy trajectory
- 2. Instrumentation
- 3. Density
- 4. Rhythm
- 5. Harmonic/emotional character
- 6. Vocal delivery
- 7. Climax
- 8. Resolution
- 9. Narrative coherence

Objective proxies primarily inform (1), (3), (4), and (7).
Items (2), (5), (6), (8), (9) require listening notes.

## Spectrogram / envelope listening notes (2026-10-08 re-run)

Observed from `output/spectrograms/`:

1. **Natural-tags RMS envelopes:** A and B differ for every seed (42/123/777). B shows sharper mid spikes (seed 42 ~26s) or earlier bursts (seed 123 ~3s/~12s; seed 777 ~12–20s). All clips fade hard near ~40–48s.
2. **Seed 42 spectrograms:** Timeline B enters denser full-spectrum energy earlier than A for both natural_tags and caption_only. Natural-tags A/B contrast appears sharper than caption-only.
3. **Human listening caveat:** No formal multi-listener panel. Notes above are visual/acoustic-proxy observations, not aesthetic preference judgments.

## Aggregate classification

| Experiment arm | Result |
|---|---|
| Section-tag (`natural_tags`) | **YES** — material A/B difference under matched seeds (soft control) |
| No-section-tag (`caption_only`) | **YES** — first-order A/B difference without lyric section tags |

Directed late−early “B always builds more” is **not** reliable (deep-metrics: 1/3). Peak RMS B>A is more consistent (deep-metrics: 3/3 natural_tags).

Supporting machine files: `comparison_metrics.json`, `deep_metrics.json`, `run_manifest.json`.
