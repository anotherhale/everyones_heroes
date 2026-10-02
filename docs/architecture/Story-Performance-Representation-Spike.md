# Story Performance Representation Spike

**Status:** ARCHITECTURE SPIKE  
**Date:** 2026-10-02  
**ADR:** HS-ADR-079  
**Implementation:** none  

This spike answers one question:

> What is the canonical EH representation of how a Story should be performed before any TTS provider renders it?

**Answer:** Experience-level spoken **delivery guidance** on the derived `StoryExperiencePlan`, in the same family as `StoryExperienceMusicDirection`. It is not implemented. Until that guidance exists, `VoiceRenderingPort` has no performance intent: it receives the full transcript text and `VoiceRenderingMode.syntheticNarration`.

---

## 1. Status

```text
ARCHITECTURE SPIKE
```

No Story Performance Editor, no production voice cloning, no new domain type, no second voice port, and no schema change.

---

## 2. Problem

`Voice-Cloning-and-Story-Performance-Architecture.md` separated voice identity, performance, and audio production, and left the canonical home of performance intent open. `VoiceGenerationPort` in that note was a conceptual name. The code already has `VoiceRenderingPort`, `StoryExperiencePlan`, and `VoiceProfile`.

This spike chooses the smallest provider-neutral representation that fits those types. It does not add the representation to the code.

---

## 3. Existing architecture

Inspected in code, not only in documents.

### Story

`Story` (`lib/features/hero_story/domain/aggregates/story.dart`) is the canonical lived narrative for one Hero.

| Concern | Current representation |
|---------|------------------------|
| Words of the Story | `StoryNarrative` — one string, max 100000 characters. Capture drafts use a provisional placeholder (HS-ADR-017). |
| Ordered narrative sections | Not on `Story`. `StoryProposalSection` exists only on a `StoryProposal` during Story Builder authoring (`StoryBuilderNarrativeRole`: beginning, challenge, turning point, and so on). Materialization collapses sections into narrative text. |
| Paragraphs / sentences | Not modeled. |
| Derived format/language forms | `StoryRepresentation` — `audio`, `video`, `written`, `transcript`, `script`, `shortForm`, `longForm`, each with optional `textContent` and/or `MediaReference`. |
| Catalog interpretation | `StoryUnderstanding` — separate aggregate of AI proposals. Not presentation and not voice. |
| Grounded reading | `CapturedStoryReading` — movement, themes, challenge, turning point, outcome. No delivery fields. |

There is no `StorySegment`. Introducing one would invent a hierarchy the aggregate does not use.

### VoiceProfile

`VoiceProfile` is the implemented voice-identity aggregate (HS.12.9 / HS-ADR-078).

It owns: `VoiceProfileId`, immutable `ownerHeroId`, lifecycle, `VoiceProfileAuthorization`, `List<MediaReference>` for reference audio, `LanguageCode`, optional `displayName`.

It does not own generated audio, a reference transcript field, provider voice ids, or any performance direction.

Consumption today is the profile use cases only: create, authorize, enroll, revoke, delete. `EnrollVoiceProfileUseCase` calls `VoiceProfilePort` with an in-memory synthetic adapter. `RenderStoryVoiceUseCase` does not load a `VoiceProfile`. `voiceClone` remains rejected.

### StoryExperiencePlan

`StoryExperiencePlan` is a derived value object (HS-ADR-073), persisted off the Story, latest plan per `StoryId`.

Current fields:

| Field | Responsibility |
|-------|----------------|
| `intention` | Closed purpose: inspire, encourage, connect, remember, reflect |
| `coreMessage` | Short presentation statement |
| `emotionalArc` | Closed story-structure arc: challenge, perseverance, transformation, service, discovery, connection, remembrance |
| `keyMoments` | Transcript-grounded spans (`SourceSpanReference`) plus a description. Highlights, not a partition of the narrative |
| `musicDirection` | Descriptive music guidance only: `mood`, `energy`, `style`, `rationale`. Not audio |
| `reflectionPrompt` | One prompt |
| `sequence` | Ordered steps: `story`, `keyMoment`, `reflection`, `music`. Steps carry a type and optional reference id, not text and not vocal delivery |
| provenance | `storyId`, transcript representation id, `providerLabel`, `processingVersion`, `createdAt` |

Consumers:

- `GenerateStoryExperiencePlanUseCase` — creates or, on `forceRegenerate`, replaces the latest plan. Explicit regenerate deletes the previous plan file.
- `RenderStoryVoiceUseCase` — requires a plan, then renders the **entire** transcript `textContent`. It does not read intention, arc, music direction, or key moments when building `VoiceRenderingRequest`.
- HS.12.5 player — `StoryExperienceTimelineBuilder` derives a timeline from the plan plus the original recording. Stems and silence stay in the player (HS-ADR-075). Playback does not call TTS.
- Experience lab — keeps the plan as creative intent and puts physical render details in lab artifacts, not on the plan.

The plan already means: what this experience should feel like, as typed presentation guidance between a grounded reading and playback. Music direction is the existing pattern for “how a layer should feel” without storing audio or vendor parameters.

The plan does not mean: how a voice should speak. Nothing on it is vocal delivery. `musicDirection.energy` is music energy. `emotionalArc` is narrative shape. `intention` is why the experience exists. Reusing those fields as voice performance would collapse separate concerns.

Putting BPM, stem ids, or TTS parameters on the plan is already rejected (HS-ADR-073, HS-ADR-075, and the laboratory plan’s rejection of expanding the plan with physical render data). Descriptive guidance is the part the plan is allowed to hold.

### VoiceRenderingPort

```text
VoiceRenderingPort.render(VoiceRenderingRequest) → VoiceRenderingDraft
```

`VoiceRenderingRequest` carries: `storyId`, `experiencePlanId`, plan processing version, `sourceRepresentationId`, `sourceText`, `language`, `renderingMode`, optional processing version, optional opaque `providerHint` / `modelHint`.

`VoiceRenderingDraft` carries audio bytes, content type, language, mode, and opaque provider/model labels.

Responsibilities:

- Provider-neutral synthesis of one text into one audio artifact.
- Adapters talk to the EH proxy or an in-memory fake. Domain and application do not import TTS vendors.

Limitations:

- No voice identity (`VoiceProfileId` is absent).
- No delivery, pace, emotion, energy, emphasis, or pause.
- One `sourceText` blob. No segments.
- `voiceClone` and `heroVoiceTransformation` are rejected by the use case.
- Idempotency is latest rendering per story, matched on plan id, plan version, mode, and language. A delivery change could not be distinguished today.

The persisted result is `StoryVoiceRendering`: media reference plus provenance. Playback uses stored bytes. The bytes are not the performance specification.

### What does not exist

No `StoryPerformance`, `PerformanceIntent`, `StorySegment`, or `VoiceGenerationPort` type in Dart. `StoryPerformance` in the glossary and the voice-cloning note is terminology only.

---

## 4. Options considered

### Option A — Performance on `StoryExperiencePlan`

Add spoken delivery guidance beside `musicDirection`.

Fits: the plan is already the derived answer to how an experience should feel; music direction proves the shape (descriptive, provider-neutral, rationale required, no bytes); `VoiceRenderingPort` already takes `experiencePlanId`; no new aggregate; no new bounded context.

Cost: HS-ADR-073’s field list grows when the field is implemented. `forceRegenerate` replaces the whole plan, so a Hero-edited delivery would be replaced with the planner output unless an explicit copy-forward rule is added later. The current render path ignores plan guidance, so the field would do nothing until `VoiceRenderingRequest` carries it.

### Option B — Separate `StoryPerformanceSpecification`

A new object keyed by story and optionally by plan.

Rejected as the canonical model. The plan’s job is already creative direction for one derived experience. A second specification repeats that job. The laboratory plan already rejected a twin aggregate (`ExperienceComposition`). Repositories store the latest plan and the latest rendering per story; a new collection is not required to keep voice identity separate from delivery. `VoiceProfile` must not own the specification.

### Option C — Performance on Story / narrative segments

Attach delivery to `StoryNarrative`, `StoryRepresentation`, or a new segment tree.

Rejected. `StoryNarrative` is one string: the words, not the delivery (HS-ADR-002, HS-ADR-035). Representations are format/language artifacts. Builder sections are authoring structure and are collapsed before the Story is canonical. Sentence-level generation in the Qwen experiment is an adapter technique. It does not justify a domain sentence or `StorySegment` type. HS-ADR-073 already rejected storing the experience plan on `Story`.

### Option D — An existing model already is the performance record

Candidates:

| Model | Why it is not the performance specification |
|-------|-----------------------------------------------|
| `StoryExperienceIntention` / `StoryExperienceArc` | Purpose and narrative shape, not vocal delivery |
| `StoryExperienceMusicDirection` | Music only |
| `StoryExperienceMoment` | Grounded highlights, not a full reading script and not delivery |
| `StoryVoiceRendering` | Generated audio artifact |
| `VoiceProfile` | Speaker identity |
| `CapturedStoryReading` / `StoryUnderstanding` | Grounded reading and catalog proposals |
| Player timeline / silence | HS-ADR-075 presentation runtime |

None of these is “how the voice should deliver this story.”

**Selected: Option A**, as a future optional value object. Not implemented in this spike. Option D explains why no current field is silently reused.

---

## 5. Decision

HS-ADR-079:

1. The canonical pre-render representation is **experience-level spoken delivery guidance on `StoryExperiencePlan`**.
2. When implemented, the minimum value object follows `StoryExperienceMusicDirection`: a non-empty `delivery` string and a non-empty `rationale` grounded in the story or plan. Length limits should match that music value object. No vendor parameters.
3. Do not add domain fields for emotion, energy, pace, emphasis, or pause in that first type.
4. `StoryPerformance` stays a conceptual capability. It is not an aggregate, entity, or separate value object.
5. `PerformanceIntent` stays the name of that guidance. It is not a separate type beside the plan’s voice-direction value object.
6. `VoiceRenderingPort` remains the only voice-generation boundary. A future request may carry the plan’s `delivery` string. Do not add `VoiceGenerationPort`.
7. Generated audio remains `StoryVoiceRendering`. Mixes, silence, and sentence WAV files remain production artifacts.
8. `VoiceProfile` stays identity. The same profile can be used with different plans, because delivery is not stored on the profile.

No Dart type is added until a use case reads or writes the guidance.

---

## 6. Rationale

The current narration path is:

```text
Story.narrative / transcript representation   what is said
        │
        ▼
StoryExperiencePlan                           how the experience should feel
        │   (intention, arc, music guidance, moments, sequence)
        │
        ▼
VoiceRenderingPort                            one sourceText → audio bytes
        │
        ▼
StoryVoiceRendering                          derived audio
```

The missing concept is vocal delivery, parallel to music guidance, not a new consistency boundary.

Experience-level scope matches the port: one `sourceText`, one rendering per story. Key moments are not a complete segmentation, and the renderer does not consult them. Segment-level domain performance would be a model without a consumer.

Multiple performances of one voice do not require a new aggregate. Delivery is absent from `VoiceProfile`, so nothing forces one style onto the identity. The repositories still keep one latest plan and one latest rendering per story. Side-by-side saved performances are a later product choice, not the current canonical shape.

Evidence stays upstream. Delivery words are creative output. They are not Behavioral Evidence and not facts about the Hero. The same prohibition HS-ADR-073 places on psychological fields applies to this guidance.

---

## 7. Domain boundaries

```text
Story                  canonical narrative and representations
Voice Identity         VoiceProfile
Performance Intent     future delivery guidance on StoryExperiencePlan
                       (not implemented; not a separate type today)
Voice Rendering        VoiceRenderingPort → StoryVoiceRendering
Generated Audio        media bytes behind StoryMediaStoragePort
Audio Production       player timeline, silence, future mixes
                       not the performance specification
```

| Dimension | Needed now? | Why | Where it belongs |
|-----------|-------------|-----|------------------|
| Delivery | Yes, as the future plan field. Not coded in this spike. | It is the spoken analogue of music `style` / `mood`. No existing field says how the voice should speak. | Domain value object on `StoryExperiencePlan`, when implemented |
| Emotion | No | `emotionalArc` is narrative shape. A vocal-emotion field overlaps delivery and invites the psychological schema HS-ADR-073 forbids. | Do not add. “Hopeful” or “calm” can be delivery language |
| Energy | No | `musicDirection.energy` is music. Copying it onto the voice collapses the two layers. Intention already distinguishes inspire from reflect at experience scope. | Stay on music direction |
| Pace | No | Nothing in the domain or the port consumes pace. A single delivery string can say “measured” until a provider-neutral pace value has a reader. | Adapter or a later field, not now |
| Emphasis | No | `StoryExperienceMoment` already marks grounded highlights. The voice renderer does not use them. A second emphasis model would duplicate moments. | Keep key moments |
| Pause | No | Between-sentence silence in the Qwen experiment is production. HS-ADR-075 already treats intentional silence as a player gap, not Story media and not plan data. There are no domain segments to pause between. | Player / audio production |

---

## 8. Provider boundary

```text
EH model
    StoryExperiencePlan.delivery   (future; absent today)
        ↓
VoiceRenderingPort
    VoiceRenderingRequest
        sourceText + language + mode
        + future optional delivery string
        ↓
Provider adapter
        ↓
Provider capability mapping
        ↓
Qwen / OpenAI / ElevenLabs / other providers
```

Provider capabilities differ. One system may expose emotion, pace, and style. Another may expose only a voice name and sampling controls. The inspected Qwen Base/ICL path uses reference audio, reference transcript, and sampling controls, and does not apply `instruct` or `speed`. The adapter approximates or reports that a requested delivery cannot be expressed. Domain and application code do not contain:

```text
temperature  top_p  top_k  repetition_penalty
Qwen  QwenSpeaker  MLX  Whisper
ref_audio  ref_text
provider voice ids  provider SDK types
```

`VoiceGenerationPort` in the earlier architecture diagram is this port. It is not a second abstraction.

---

## 9. Future Story Performance Editor

Not implemented. When it exists, it reads and writes the plan’s delivery guidance and previews through `VoiceRenderingPort`. It does not own a parallel domain model.

| Operation | State |
|-----------|--------|
| Preview performance | Transient application/presentation call. May discard bytes. |
| Adjust performance | Future write of `delivery` / `rationale` on the plan. No TTS call required to save intent. |
| Regenerate segment | Not a domain operation. There is no segment. Whole-story re-render already exists (`forceRegenerate`) and stores a new `StoryVoiceRendering`. Sentence files, if an adapter makes them, are intermediate production assets. |
| Compare performance | Presentation over two renderings or two previews. Latest-per-story storage does not keep both unless a later repository change says so. |
| Save performance | Persist plan guidance. Do not treat the WAV/MP3 as the saved performance. |
| Assemble audio | Player / production. HS-ADR-075 already assembles a timeline without storing the mix as the Story. |

The editor’s durable domain input is one experience-level delivery, not a sentence tree.

---

## 10. Persistence implications

Not implemented here.

| Data | Survives as | Notes |
|------|-------------|--------|
| Voice identity | `VoiceProfile` | Implemented in memory. Reference transcript is still VC-5 direction, not a field. |
| Reference audio | `MediaReference` on the profile | Bytes outside the aggregate. |
| Canonical narrative | `Story.narrative` and representations | Unchanged. |
| Performance intent | Future fields on the plan snapshot | Same repository as the plan. Replaced when the plan is force-regenerated, same as music direction, unless a later use-case rule copies a Hero-set delivery forward. |
| Generated audio | `StoryVoiceRendering` + media storage | Not the canonical performance. Latest per story. |
| Sentence WAVs, silence, mixes | Production artifacts | Not Story, not the plan, not voice identity. |

---

## 11. Open questions

- When the delivery field exists, should an explicit plan regeneration replace it (same rule as music direction) or copy a Hero-edited delivery onto the new plan? Default until a product decision: replace, because HS-ADR-073 replaces the derived plan.
- Does a later product need more than one saved delivery per story at the same time? Current repositories do not. If yes, add further plan-scoped guidance values. Do not put them on `VoiceProfile` and do not open a new bounded context.
- When, if ever, should a `StoryExperienceMoment` carry its own delivery override? Not justified while rendering sends one transcript string.

Resolved by this spike and therefore removed from the open list in the voice-cloning note: where performance intent lives, whether `VoiceGenerationPort` is a second port, whether the domain should model sentences, and which of delivery / emotion / energy / pace / emphasis / pause belong in the first domain vocabulary.
