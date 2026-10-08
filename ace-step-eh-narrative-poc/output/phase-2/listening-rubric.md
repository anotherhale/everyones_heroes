# Phase 2 Listening Rubric

**Purpose:** Repeatable human evaluation of narrative musical control.  
**Scale:** 1–5 integers (or `N/A` where judgment is impossible).  
**Rule:** Do not invent scores. Prefer `N/A` over guessing.

## Independent track scoring

Score each generated track against **its own intended timeline** before comparative scoring.

| Dimension | 1 | 3 | 5 |
|---|---|---|---|
| Energy trajectory | Essentially flat | Partial rise/fall | Clearly follows intended rise/fall |
| Narrative phase transitions | Phases indistinguishable | Some sectional change | Transitions strongly match timeline phases |
| Instrumentation evolution | Arrangement unchanged | Mild evolution | Clear instrumentation evolution |
| Rhythmic evolution | Rhythm static | Mild development | Rhythm clearly develops with narrative |
| Emotional trajectory | Emotion static | Mild shift | Follows intended emotional progression |
| Climax placement | No meaningful climax | Climax exists; timing weak | Climax in intended narrative phase |
| Resolution | No distinct resolution | Soft settle / fade | Clear appropriate resolution |
| Vocal delivery | Delivery does not reflect intent | Partial match | Strongly reflects intent |

If vocals are absent or delivery cannot be reliably judged, record **`N/A`** for Vocal delivery.

## Comparative A/B questions

For each matched seed / adapter strategy pair, answer Yes / No / Unclear:

1. Does A feel intimate / restrained throughout?
2. Does B actually build over time?
3. Does B become more rhythmically active than A?
4. Does B become musically larger / denser than A?
5. Does B’s strongest section occur near the intended breakthrough/climax window?
6. Does the music resolve after the climax (B)?
7. Does A avoid the same climax magnitude as B?
8. Can a listener distinguish the intended arcs without being told which file is which?

## Blind listening protocol

1. Copy matched A/B WAVs into `output/phase-2/blind/` with neutral names (`sample-01.wav`, `sample-02.wav`).
2. Record the mapping in `blind/mapping.json` (evaluator should not open this before scoring).
3. Score samples independently, then reveal mapping.
4. Complete the comparative questions after reveal.

## Overall pair score (optional)

After dimension scores, assign an overall narrative-control impression:

| Overall | Meaning |
|---|---|
| 1 | Differences are negligible or stochastic |
| 3 | Music differs, but phase timing is unreliable |
| 5 | Structure and phase timing clearly follow the timeline |

## Evidence hygiene

- Separate Observed (what was heard/measured) from Inference.
- Do not score “better sounding” — score narrative control fidelity.
- Document GPU/CPU environment next to scores (quality confounds).
