# Everyone's Heroes — Voice Cloning & Story Performance Architecture

**Status:** Architectural direction. Local Qwen3-TTS Base/ICL work is an experiment. Story Performance is not implemented.  
**Version:** 0.1  
**Date:** 2026-10-02  
**Scope:** Document the current local voice-cloning investigation, the separation of voice identity, voice performance, and audio production, and the provider-neutral direction required before any Story Performance capability is built.  
**Related phases:** HS.12.6 (synthetic voice rendering), HS.12.7 (TTS provider benchmark), HS.12.8 / HS-ADR-078 (voice identity boundary), HS.12.9 (VoiceProfile foundation), AI Experience Provider Laboratory (creative-direction plan).  
**Related architecture documents:**

- `docs/architecture/HS-ADR-078-Voice-Identity-and-Cloning-Boundary.md`
- `docs/architecture/HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md`
- `docs/architecture/HS.12.9-Voice-Profile-Foundation.md`
- `docs/architecture/HS.12.6-Voice-Rendering-Implementation-Report.md`
- `docs/architecture/HS.12.7-TTS-Provider-Benchmark.md`
- `docs/architecture/Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`
- `docs/architecture/AI-Experience-Provider-Laboratory-Plan.md`
- `docs/architecture/architecture-decisions.md` (HS-ADR-076, HS-ADR-077, HS-ADR-078, HS-ADR-079)
- `docs/architecture/Story-Performance-Representation-Spike.md`

**Decisions:** Directional decisions VC-1 through VC-5 in §18. They do not supersede HS-ADR-076, HS-ADR-077, or HS-ADR-078, and they are not implemented. HS-ADR-079 (`Story-Performance-Representation-Spike.md`) decides the canonical pre-render representation: future experience-level delivery guidance on `StoryExperiencePlan`. `VoiceRenderingPort` stays the generation boundary. No domain type was added.  
**Non-goals:** Production voice cloning, a Story Performance Editor, Qwen types in the EH domain, a new Voice bounded context, Dart performance classes, provider selection, and legal/consent wording.

---

## 1. Why this document exists

Everyone's Heroes can already render a Story as synthetic narration. That path is provider-neutral at the domain boundary and is ordinary text-to-speech. It is not voice cloning, and it is not a performance model.

A separate local experiment has been exploring Qwen3-TTS Base/ICL voice cloning on Apple Silicon. That experiment produced useful architectural lessons:

- a cloned voice is an identity, not a performance;
- how words are delivered is a different concern from who is speaking;
- how the final audio is assembled is a third concern;
- a single TTS call collapses those concerns and hides provider limits.

This document records those lessons and the direction they imply. It does not move the experiment into the EH domain model.

---

## 2. Current status

| Capability | Status |
|------------|--------|
| Qwen3-TTS local voice-cloning experiment | **EXPERIMENTAL** |
| Reference voice enrollment | **PROTOTYPE** |
| Sentence-level generation | **PROTOTYPE** |
| Sentence pause insertion | **PROTOTYPE** |
| Final audio assembly | **PROTOTYPE / UNDER VALIDATION** |
| Story Performance Editor | **PLANNED** |
| Provider-neutral EH voice generation architecture for performance | **PLANNED / ARCHITECTURAL DIRECTION** |
| EH synthetic narration (`VoiceRenderingPort`, HS.12.6 / HS.12.7) | **IMPLEMENTED** — synthetic only |
| EH `VoiceProfile` identity foundation (HS.12.9) | **IMPLEMENTED** — no production cloning |
| Production voice cloning | **NOT IMPLEMENTED** |

Do not describe production voice cloning, the Story Performance Editor, or a performance-aware generation port as existing product behavior.

The HS.12.7 benchmark and this experiment are different investigations:

| | HS.12.7 benchmark | This document's experiment |
|--|-------------------|----------------------------|
| Host | Linux CPU spike, plus published M4 context | Mac mini, Apple Silicon M4, 16 GB RAM |
| Model | `Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice` | `mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit` |
| Purpose | Synthetic narration behind the EH proxy | Local cloning / in-context learning reference |
| EH wiring | `services/ai_proxy` `TtsProvider` | Outside this repository |

HS.12.7 CustomVoice findings do not describe Base/ICL behavior.

---

## 3. Relationship to the existing EH voice model

EH already has accepted boundaries. This document extends the vocabulary. It does not replace those boundaries.

| Existing concept | Role | This document's name |
|------------------|------|----------------------|
| `VoiceProfile` | Provider-independent voice identity, Hero-scoped (HS-ADR-078, HS.12.9) | Voice Identity |
| `StoryVoiceRendering` | Derived audio artifact for a Story (HS-ADR-076) | One possible audio result, not the performance specification |
| `VoiceRenderingPort` | Provider-neutral synthesis boundary for story narration (HS-ADR-077) | The current generation seam |
| `VoiceProfilePort` | Enrollment / revoke / delete boundary | Enrollment seam; production cloning adapters are not implemented |
| `StoryExperiencePlan` | Derived creative presentation guidance (HS-ADR-073) | Existing creative-direction artifact; not a TTS parameter bag |

**Voice Identity is `VoiceProfile`.** Do not introduce a second aggregate named `VoiceIdentity`, and do not introduce `QwenSpeaker`. A Qwen CustomVoice speaker label, an OpenAI voice name, and a cloned reference voice are provider bindings. The EH identity remains `VoiceProfileId`.

**Voice generation stays behind a port.** Today that port is `VoiceRenderingPort`, and `voiceClone` is still rejected. A future performance-aware request may extend that boundary. Whether the request type grows on `VoiceRenderingPort` or a sibling generation contract is introduced is an open implementation question (§20). Domain and application code must not gain a second product path that talks to a vendor SDK.

**Story remains the canonical narrative.** Generated audio, sentence WAVs, mixes, and performance directions are derived. They are not Story identity. HS-ADR-002 and HS-ADR-076 still apply.

---

## 4. Architectural model

These are different concerns. EH must not collapse them into a single TTS API.

```text
                    STORY
                      │
                      ▼
              Story Performance
                      │
          ┌───────────┼───────────┐
          │           │           │
        Voice       Delivery     Timing
       Identity     / Emotion    / Pauses
          │           │           │
          └───────────┼───────────┘
                      ▼
                Audio Production
                      │
                      ▼
              Final Audio Experience
```

### Story

What the person is saying.

Examples:

- story text
- motivational message
- coaching message
- reflection
- hero story
- personalized narrative

The Story (or another textual experience source) owns the words. Changing how those words sound does not change the canonical narrative.

### Voice Identity

Who sounds like the speaker.

Examples:

- user's cloned voice
- narrator voice
- hero voice
- synthetic voice
- provider-defined voice

The same identity can deliver many performances. Changing pace or emotion does not create a new person.

### Performance

How the words are delivered.

Examples:

- calm
- reflective
- vulnerable
- energetic
- hopeful
- passionate
- authoritative
- intimate
- urgent
- conversational

Also:

- pace
- emphasis
- pauses
- sentence-level delivery
- paragraph-level delivery
- emotional arc

Performance is a direction applied to content. It is not a voice identity and it is not a mix.

### Production

How the final experience is assembled.

Examples:

- music
- sound effects
- silence
- normalization
- mixing
- mastering
- transitions
- background ambience

Production consumes generated voice segments and other audio elements. It does not decide who is speaking or what the Story says.

---

## 5. Qwen3-TTS investigation

The current local implementation is an **experimental / reference implementation**. It is not EH architecture, and it is not wired into `lib/features/hero_story` or `services/ai_proxy`.

### 5.1 Current development environment

```text
Mac mini
Apple Silicon M4
16 GB RAM

Repository:
qwen3-tts-apple-silicon

Local path:
~/dev/ai/qwen3-tts

Python:
3.13

Virtual environment:
.venv

Model:
Qwen3-TTS-12Hz-1.7B-Base-8bit

Model source:
mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit
```

These details describe the current development machine and checkpoint. They are not a permanent EH runtime, model pin, or deployment requirement.

### 5.2 Model families investigated

Three conceptual Qwen families were considered:

```text
Base
    Voice cloning from reference audio

CustomVoice
    Predefined speaker identities plus style/instruction

VoiceDesign
    Synthetic voice generated from a textual voice description
```

HS.12.7 exercised CustomVoice (`0.6B-CustomVoice`) for synthetic narration. This experiment exercises Base/ICL cloning. VoiceDesign was identified as a family; this document does not claim a completed VoiceDesign quality evaluation.

### 5.3 Architectural conclusion

A cloned user voice from the Base model is not directly interchangeable with a CustomVoice predefined speaker identity.

EH therefore models:

```text
VoiceIdentity   →   existing aggregate name: VoiceProfile
```

rather than:

```text
QwenSpeaker
```

Provider adapters may store an opaque binding (checkpoint family, speaker label, reference handle). That binding is infrastructure. It is not the domain identity.

---

## 6. Reference voice enrollment

The current experimental enrollment model is a **prototype**. A saved voice currently consists conceptually of:

```text
Voice
├── name
├── reference audio
└── reference transcript
```

Example layout in the experiment, not an EH storage schema:

```text
voices/
    andy-voice-ref.wav
    andy-voice-ref.txt
```

The reference transcript matters for Qwen Base/ICL generation. The inspected Base/ICL path uses `ref_audio` together with `ref_text`.

Preferred lifecycle:

```text
Record reference audio
        ↓
Normalize audio
        ↓
Transcribe reference
        ↓
Review/correct transcript
        ↓
Store Voice Identity
        ↓
Use reference audio + reference transcript
        ↓
Generate speech
```

Transcription belongs to enrollment (or to an explicit re-enrollment), not to every generation.

A reference transcript is durable metadata associated with the enrolled voice. Load it once and reuse it for every segment generated from that enrollment.

EH alignment, when this is implemented later:

- identity remains `VoiceProfile` (HS.12.9);
- reference audio remains `MediaReference` plus bytes behind a storage port — not aggregate bytes (HS-ADR-078);
- the reference transcript is additional durable enrollment metadata, not Story canonical text and not behavioral evidence;
- consent stays on the existing independent gates (enrollment, cloning, story use, publication). This document does not define legal wording.

HS.12.9 does **not** yet persist a reference transcript field. That field is architectural direction (VC-5), not current aggregate state.

---

## 7. Qwen Base/ICL performance findings

The installed Qwen3-TTS Base/ICL implementation was inspected directly in the local experiment. This repository does not contain that Python model package. The findings below are the recorded inspection result. Do not generalize them to every Qwen checkpoint.

The relevant `Model.generate()` signature includes concepts such as:

```text
text
voice
instruct
temperature
speed
lang_code
ref_audio
ref_text
top_k
top_p
repetition_penalty
```

The Base/ICL cloning path does not currently use all of those parameters.

```text
Base / ICL cloning
    uses:
        ref_audio
        ref_text
        temperature
        top_k
        top_p
        repetition_penalty

    does not currently apply:
        instruct
        speed
```

Changing `speed` or `instruct` must not be assumed to change Base/ICL voice-cloning generation. Future developers who only read the `generate()` signature will get this wrong unless this distinction stays documented.

Family summary, limited to what was verified or identified:

```text
CustomVoice
    supports voice + instruction semantics
    (HS.12.7 exercised 0.6B CustomVoice synthetic narration)

VoiceDesign
    supports textual voice description
    (family identified; not a completed EH evaluation)

Base / ICL
    uses reference audio + reference transcript
    and sampling controls
    does not currently apply instruct or speed
```

No additional Base/ICL controls are claimed here.

The capability matrix in `Voice-Synthesis-Voice-Cloning-Implementation-Plan.md` distinguishes Qwen families. CustomVoice and VoiceDesign are the instruct / textual-description paths. The inspected Base/ICL path is annotated there as not applying `instruct` or `speed`.

---

## 8. Sentence-level generation experiment

The current experiment splits text into sentences:

```text
Long story
    ↓
Sentence segmentation
    ↓
Sentence 1
Sentence 2
Sentence 3
...
Sentence N
```

Each sentence is generated independently.

Architectural advantage:

> A story can eventually be edited at the sentence or paragraph performance level without regenerating the entire story.

Individual sentence audio files are intermediate production assets. They are not the final experience, and they are not the canonical Story. HS-ADR-079: this segment tree is an adapter/production shape. The domain representation of performance, when implemented, is experience-level delivery guidance on `StoryExperiencePlan`, not a `StorySegment` type.

Conceptual shape, not an implemented aggregate:

```text
StoryPerformance
    ├── Segment 1
    │     ├── text
    │     ├── delivery
    │     └── audio
    │
    ├── Segment 2
    │     ├── text
    │     ├── delivery
    │     └── audio
    │
    └── Segment N
          ├── text
          ├── delivery
          └── audio
```

Segment granularity in the experiment is the sentence. A future model may also use paragraphs. The decision (VC-3) is independent generation of segments, not a requirement that the only legal segment is a sentence.

---

## 9. Sentence pauses

The experiment inserts configurable silence between sentence segments.

Initial options used by the prototype:

```text
Short       300 ms
Natural     500 ms
Dramatic    800 ms
Custom
```

Pauses are a Story Performance concern. They are not a property of voice identity. The same enrolled voice can be performed with short, natural, or dramatic pauses.

Future EH should represent pauses semantically where appropriate, rather than hard-coding milliseconds throughout the domain. For example:

```text
PauseStyle.short
PauseStyle.natural
PauseStyle.dramatic
```

could eventually map to provider-specific timing inside an adapter.

Those names are architectural direction. This task does not create Dart classes. Millisecond values above are prototype settings, not domain constants.

---

## 10. Known issues in the current experiment

### Issue 1 — Reference transcript repeated transcription

The sentence-generation experiment was observed repeatedly printing:

```text
Ref_text not found. Transcribing ref_audio...
```

for every sentence.

The reference transcript had already been obtained successfully. The implementation was not consistently carrying the enrolled reference transcript through the sentence-generation loop.

Desired architecture:

```text
Voice enrollment
       ↓
Reference transcript persisted
       ↓
Load once
       ↓
Generate all segments using same ref_text
```

Do not repeatedly invoke speech-to-text during sentence generation. Repeated transcription adds latency, cost, and nondeterminism, and it can drift from the reviewed transcript.

### Issue 2 — Final sentence assembly

The experiment generated the sentence WAV files. The final log did not clearly demonstrate successful assembly into one final WAV.

Desired pipeline:

```text
Sentence WAVs
      +
Silence segments
      ↓
FFmpeg / audio assembler
      ↓
Single final WAV
```

The final output must be explicitly verified. Intermediate sentence assets should remain available after final assembly so a single segment can be regenerated without discarding the others.

Status of this step: **PROTOTYPE / UNDER VALIDATION**.

---

## 11. "Slow and emotionless" observation

The current cloned-voice output was described as:

- slow
- emotionless
- insufficiently expressive

This is a current experimental observation about that run and that checkpoint. It does not establish a defect in Qwen, and it does not generalize to voice cloning as a technique.

EH should keep raw TTS parameters inside provider adapters.

EH should eventually provide a higher-level performance model. For example:

```text
Performance:
    tone: hopeful
    energy: medium-high
    pace: conversational
    emotion: encouraging
    emphasis: selective
    pause_style: natural
```

Provider adapters translate that intent into whatever controls a particular TTS provider actually supports. For the inspected Base/ICL path, `instruct` and `speed` are not currently available levers. An adapter must say so, or achieve the intent through segment text, pauses, sampling controls that do apply, a different model family, or a different provider. It must not pretend that setting `speed` changed the clone.

---

## 12. Story Performance Editor

**Status: PLANNED.** This capability does not exist in the product.

Working name: **Story Performance Editor**.

> A user should be able to direct how their story sounds without needing to understand TTS parameters.

The user should be able to select or adjust concepts such as:

```text
Pace
Energy
Emotion
Emphasis
Pause
Delivery
```

A story could contain performance directions at the sentence or paragraph level.

Example:

```text
Paragraph 1
    Delivery: reflective
    Pace: calm
    Energy: low
    Pause after: natural

Paragraph 2
    Delivery: vulnerable
    Pace: conversational
    Energy: medium

Paragraph 3
    Delivery: determined
    Pace: increasing
    Energy: high

Paragraph 4
    Delivery: hopeful
    Pace: measured
    Energy: medium-high
```

The UI communicates human concepts. Sampling parameters stay in infrastructure:

```text
temperature=1.0
top_p=0.95
repetition_penalty=1.5
```

The editor, when built, is presentation. It calls application use cases. It does not call Qwen, FFmpeg, or a vendor SDK.

Relationship to `StoryExperiencePlan`: HS-ADR-079 decides that spoken performance intent, when implemented, is experience-level delivery guidance on this plan, beside music direction. It is not a second specification object and not a sentence tree. The field is not implemented. The editor remains planned.

---

## 13. Provider-neutral architecture

Desired shape:

```text
Story
   ↓
Story Performance Specification
   ↓
Voice Generation Port
   ↓
Provider Adapter
   ├── Qwen
   ├── ElevenLabs
   ├── OpenAI
   ├── Cartesia
   └── Future providers
```

The EH domain and application layers must not depend on:

```text
Qwen
OpenAI TTS
ElevenLabs
MLX
Whisper
provider-specific voice IDs
provider-specific parameters
```

Provider-specific translation belongs in infrastructure.

```text
VoicePerformanceIntent
        ↓
VoiceGenerationPort
        ↓
QwenVoiceGenerationAdapter
        ↓
Qwen-specific parameters
```

The same EH performance specification could be translated for another provider. Adapters are allowed to degrade explicitly when a provider cannot express a dimension. They are not allowed to leak that provider's parameter names upward.

**Current code.** The implemented narration seam is `VoiceRenderingPort` → `ProxyVoiceRenderingAdapter` → `POST /story-voice-renderings` → proxy `TtsProvider`. HS-ADR-079 resolves the diagram's `VoiceGenerationPort` as this port. Do not add a second voice-generation port. A future request may carry the plan's delivery string. Today `VoiceRenderingRequest` has no performance field.

HS-ADR-077 already places provider selection in `services/ai_proxy`. That rule still holds for any future cloning or performance adapter.

---

## 14. Voice identity, performance, and generation

Conceptual model. Fields are vocabulary, not a schema to implement now.

```text
VoiceIdentity
    │
    ├── display name
    ├── owner
    ├── reference audio
    ├── reference transcript
    ├── language
    └── provenance / consent metadata

VoicePerformance
    │
    ├── delivery
    ├── emotion
    ├── pace
    ├── energy
    ├── emphasis
    └── pauses

VoiceGeneration
    │
    ├── VoiceIdentity
    ├── StoryPerformance
    └── provider
```

Mapping onto current EH types:

| Conceptual field | Current EH home | Notes |
|------------------|-----------------|-------|
| Voice identity id | `VoiceProfileId` | Implemented |
| Owner | `VoiceProfile.ownerHeroId` | Hero-scoped; non-Hero ownership is still open |
| Display name | `VoiceProfile.displayName` | Optional |
| Reference audio | `List<MediaReference>` | Bytes outside the aggregate |
| Reference transcript | Not on the aggregate yet | VC-5 direction |
| Language | `LanguageCode` | Implemented on the profile |
| Consent / provenance | `VoiceProfileAuthorization` gates | Legal wording deferred |
| Performance dimensions | Not modeled | Planned |
| Provider | Infrastructure binding | Not domain |

---

## 15. Creative Director

This capability connects to the existing EH AI philosophy.

The AI should eventually act as a **Creative Director** rather than an authority on who the user is.

The existing laboratory plan already uses that role name for `StoryExperiencePlannerPort` producing a `StoryExperiencePlan`. Story performance direction is a future creative output in the same family: proposed presentation, grounded in understanding the platform already recorded.

```text
Discovery
    ↓
Behavioral Evidence
    ↓
Behavior Patterns
    ↓
Discovery Profile
    ↓
Personalization
    ↓
Creative Direction
    ↓
Story / Music / Voice / Performance
    ↓
Personalized Experience
```

AI can propose:

- story structure
- performance direction
- emotional arc
- pacing
- emphasis
- music direction
- narration style

The underlying user understanding remains grounded in EH's evidence-first architecture.

Evidence is observed. Patterns are derived. Personalization chooses or shapes an opportunity from that understanding. Creative direction proposes how the opportunity might be experienced. None of those steps may invent Hero facts, lessons, beliefs, or quotations (HS-ADR-006 and the story-ownership rule).

Listening to generated audio is not behavioral evidence. A performance preference is not a growth conclusion. Story interaction still does not automatically constitute evidence (HS-ADR-011).

> The user experiences transformation; the architecture records understanding.

---

## 16. Personalized audio vision

Personalized audio can eventually combine:

```text
Narration
Voice
Story
Music
Lyrics
Pacing
Emotional Arc
Sound Design
Call to Action
```

That aligns with the existing vision that a personalized motivational experience can be uniquely composed for an individual. Possible future experiences include:

```text
Personalized Hero Stories
Personalized Motivational Talks
Personalized Voice Coaching
Personalized Music
Personalized Lyrics
Personalized Audio Journeys
```

The personalization engine can determine not only:

```text
What should be said?
```

but eventually:

```text
How should it be experienced?
```

The audio system is one possible experience-generation layer. It does not replace evidence, patterns, or discovery. Current product personalization is deterministic experience selection (UI.3 / HS.8). This section is future vision, not a description of that selector.

---

## 17. Architectural boundaries

### Domain

Owns concepts such as:

- Story
- Story Segment (when a segment is part of the domain model)
- Voice Identity (`VoiceProfile` today)
- Performance Intent
- Delivery
- Experience

Introduce concrete domain types only when an implementation phase begins. Do not add `PauseStyle`, `VoicePerformance`, or `StoryPerformance` classes as part of documentation work.

Hero & Story remains the bounded context. HS-ADR-078 rejected a separate Voice bounded context. Performance direction, when implemented, belongs with Hero & Story presentation capabilities unless a future ADR says otherwise. It does not belong to Life Journey, and it is not Behavioral Evidence.

### Application

Coordinates, when the capability is built:

```text
Generate Story Performance
Generate Voice Segment
Regenerate Segment
Assemble Story Audio
Preview Performance
Save Performance
```

These use cases are **planned**. They are not implemented. Enrollment use cases that do exist today (`Create` / authorize / enroll / revoke / delete VoiceProfile) perform in-memory synthetic enrollment only. They do not clone a voice.

### Infrastructure

Owns:

- Qwen
- MLX
- FFmpeg
- Whisper
- provider SDKs
- audio codecs
- filesystem
- local model management

The local experiment's Python environment, MLX weights, and FFmpeg assembly stay outside the domain. The EH proxy remains the place provider selection lives for any path that enters the product.

### Presentation

Owns, when built:

- Story Performance Editor
- timeline
- segment controls
- preview
- regeneration
- pause controls
- voice selection

Presentation consumes application results. It does not assemble domain rules from `temperature` and `top_p`.

---

## 18. Architecture decisions

These are directional. Status for each: **architectural direction — not implemented**. They do not replace HS-ADR-076, HS-ADR-077, or HS-ADR-078.

### VC-1 — Voice providers are infrastructure

**Decision:** EH domain and application code must remain provider-neutral.

**Reason:** Voice providers will evolve and may have different capabilities. Qwen Base/ICL, Qwen CustomVoice, OpenAI TTS, ElevenLabs, and future providers do not share one parameter set.

**Consequence:** Qwen, MLX, Whisper, FFmpeg, and vendor voice ids stay in infrastructure adapters. The domain names `VoiceProfile`, performance intent, and Story. It does not name a vendor.

### VC-2 — Voice identity and performance are separate

**Decision:** A person's cloned voice is not the same concept as how that voice performs a story.

**Reason:** The same voice should support many performance styles. Collapsing them forces a new enrollment every time delivery changes, and it makes CustomVoice speaker labels look like identities.

**Consequence:** `VoiceProfile` remains identity. Performance intent is a separate specification applied at generation time. Historical `StoryVoiceRendering` artifacts stay immutable when a later performance is requested.

### VC-3 — Segment-level generation

**Decision:** Stories should eventually be representable as independently generated segments.

**Reason:** This enables editing and regeneration without rebuilding the entire story.

**Consequence:** Sentence (or later paragraph) audio is an intermediate production asset. Final assembly is a separate production step. Intermediate assets remain available after the mix exists.

**Refined by HS-ADR-079:** that segment split is an adapter technique. The domain does not gain `StorySegment`. The canonical performance intent is experience-level delivery guidance on `StoryExperiencePlan`, because current rendering sends one transcript string and the Story has no segment model.

### VC-4 — Performance intent is provider-neutral

**Decision:** EH should represent human-level performance intent rather than raw TTS parameters.

**Reason:** `temperature`, `top_p`, `speed`, and `instruct` do not represent the user's conceptual intent. Some of them do not even apply on the current Base/ICL path.

**Consequence:** The Story Performance Editor, if built, speaks in pace, energy, emotion, emphasis, pause, and delivery. Adapters translate. Unsupported dimensions are explicit adapter limits, not hidden no-ops presented as user controls.

### VC-5 — Reference transcripts are durable voice metadata

**Decision:** An enrolled reference voice should persist its reference transcript.

**Reason:** Repeated speech-to-text during generation is unnecessary and introduces latency, cost, and nondeterminism. The Base/ICL experiment showed that cost directly (`Ref_text not found` on every sentence).

**Consequence:** Enrollment reviews and stores the transcript once. Generation loads that transcript with the reference audio. Re-transcription is an explicit enrollment action, not a side effect of rendering a sentence.

---

## 19. Proposed module placement

**Not created by this document. Not a new bounded context.**

Current code already places voice identity inside Hero & Story:

```text
lib/features/hero_story/
    domain/            # VoiceProfile aggregate, VoiceRenderingPort, VoiceProfilePort
    application/       # render / profile use cases
    infrastructure/    # proxy adapters, in-memory adapters
    presentation/
```

A packaging sketch that sometimes appears in design discussion:

```text
features/
    voice/
        domain/
        application/
        infrastructure/
        presentation/

features/
    story/
        domain/
        application/
        infrastructure/
        presentation/
```

That sketch is only a possible future folder layout. HS-ADR-078 already decided voice identity is a Hero & Story capability, not its own bounded context. If a `voice/` package is ever extracted, it remains inside that context and keeps the same ports. Do not create these directories as part of documentation work, and do not move Story out of `hero_story` to match the sketch.

There is no `BehaviorPattern`-style repository for performance, and none should be added merely because the noun exists. Persistence decisions wait for an implementation phase.

---

## 20. Open questions

These are undecided. This document does not answer them.

- Which production TTS provider(s) will EH support?
- Should voice cloning be local, cloud, or both?
- What consent and provenance requirements apply to cloned voices? (Technical gates exist on `VoiceProfileAuthorization`; product and legal wording do not.)
- How long should reference audio be?
- How should voice identities be stored beyond the current in-memory `VoiceProfileRepository`?
- How should voice cloning work for Heroes other than the current user?
- Which performance dimensions belong in the domain model? **Resolved by HS-ADR-079:** delivery plus a grounded rationale, when implemented. Emotion, energy, pace, emphasis, and pause are not first domain fields.
- How should performance intent map to providers with different capabilities? **Resolved as an adapter concern:** the domain stores delivery language; the adapter approximates or reports that the provider cannot express it. No mapping table is implemented.
- Should performance directions be generated by AI automatically?
- How much user editing should be supported?
- How should music and narration be mixed?
- What audio format should be canonical?
- How should generated audio be cached?
- How should regenerated segments invalidate previous final mixes?
- What accessibility controls are required?
- Should a future performance-aware request extend `VoiceRenderingPort` or add a sibling generation contract? **Resolved by HS-ADR-079:** extend `VoiceRenderingRequest` later with the plan's delivery string. Do not add `VoiceGenerationPort`.

---

## 21. Architecture diagram

```text
                  EH UNDERSTANDING
                         │
                         ▼
                Personalization
                         │
                         ▼
                 Creative Direction
                         │
              ┌──────────┴──────────┐
              │                     │
           Story                 Performance
              │                     │
              └──────────┬──────────┘
                         ▼
                 Voice Generation
                         │
                VoiceGenerationPort
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
        Qwen        Other TTS       Future TTS
          │
          ▼
     Voice Segments
          │
          ▼
    Audio Production
          │
          ▼
 Personalized Audio Experience
```

`VoiceGenerationPort` in this diagram is the conceptual name for `VoiceRenderingPort` (HS-ADR-079). Do not add a second port. Qwen in the product proxy today is the HS.12.7 CustomVoice synthetic adapter, not the Base/ICL cloning experiment. Performance intent, when implemented, is delivery guidance on `StoryExperiencePlan`, not a sentence tree in the domain.

Understanding above the line remains evidence-first. Creative direction and audio generation do not write behavioral truth back into the user.

---

## 22. What remains unchanged

- No application code, domain types, ports, or directories were added for Story Performance.
- `voiceClone` stays rejected on the current rendering use case.
- `VoiceProfile` stays the identity aggregate.
- Synthetic narration remains valid without a VoiceProfile.
- AI remains behind ports and does not own the Story.
- Cataloging a Story is still not personalization, and personalization is still not a hidden catalog taxonomy.
