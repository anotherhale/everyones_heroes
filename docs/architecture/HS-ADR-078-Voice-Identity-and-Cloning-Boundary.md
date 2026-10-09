# HS-ADR-078 Voice Identity and Cloning Boundary

**Status:** Accepted — architectural boundary locked by HS.12.8; **VoiceProfile
domain foundation implemented in HS.12.9** (no production cloning);
**cloning authorization scope modeled in HS.12.10** (no production cloning)  
**Date:** 2026-09-30 (addenda 2026-10-01)  
**Phase:** HS.12.8 — Voice Identity & Cloning Architecture Spike;  
HS.12.9 — Voice Profile Foundation;  
HS.12.10 — Voice Cloning Authorization Scope & Boundary  
**Related:** HS-ADR-076, HS-ADR-077, HS.12.6, HS.12.7, HS.12.8, HS.12.9,
HS.12.10,  
`Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`,  
`HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md`,  
`HS.12.9-Voice-Profile-Foundation.md`,  
`HS.12.10-Voice-Cloning-Authorization-Scope.md`,  
`Voice-Cloning-and-Story-Performance-Architecture.md`

---

## Context

HS.12.6 established provider-neutral **Story voice rendering**:

```text
RenderStoryVoiceUseCase
  → VoiceRenderingPort
  → ProxyVoiceRenderingAdapter | InMemoryVoiceRenderingAdapter
  → POST /story-voice-renderings (services/ai_proxy)
  → TTS adapter
  → StoryVoiceRendering + StoryMediaStoragePort bytes
```

HS.12.7 confined **provider selection** to the AI proxy (`TtsProvider` /
`TtsProviderResolver` / `EH_TTS_PROVIDER`) and demonstrated that Qwen3-TTS
0.6B-CustomVoice is practical enough to investigate further on local hardware.
CustomVoice synthetic speakers are **not** Hero voice cloning.

The product will eventually need a Hero-owned voice identity that can be used
to synthesize many story narrations. That identity must not collapse into:

- the canonical Story
- a StoryRepresentation
- a StoryVoiceRendering audio artifact
- a provider-specific voice id
- synthetic narration consent (`StoryConsent.voiceRenderingApprovedAt`)

HS.12.8 answers the architectural boundary question **before** any enrollment,
cloning adapter, consent UI, or persistence implementation.

---

## Decision

### Architectural rule

> A **VoiceProfile** represents a provider-independent voice identity.  
> A **StoryVoiceRendering** represents a derived audio artifact generated from
> a Story using a voice (synthetic or profile-backed).  
> These concepts must never be collapsed.

### Boundary summary

| Concern | Ownership / placement | Status |
|---------|----------------------|--------|
| Voice identity | `VoiceProfile` aggregate in Hero & Story | **HS.12.9 implemented** |
| Reference audio | `MediaReference` on profile; bytes via storage port | Refs on aggregate; upload/storage deferred |
| Consent / authorization | `VoiceProfileAuthorization` (four independent gates) | **HS.12.9 implemented** (product/legal wording deferred) |
| Provider enrollment | Infrastructure mapping keyed by `VoiceProfileId` | Designed — **not implemented** |
| Voice cloning / enrollment | `VoiceProfilePort` + in-memory synthetic adapter | Port wired; **no production cloning** |
| Story narration / synthesis | Existing `VoiceRenderingPort` | Preserved; cloning modes still rejected |
| Generated audio artifact | Existing `StoryVoiceRendering` | Preserved; optional `voiceProfileId` **deferred** |

### 1. VoiceProfile is a Hero-scoped identity, not a Story identity

**Decision:** A future VoiceProfile is owned by a **Hero** (the subject whose
voice it represents), not by a Story, and not by the platform as a marketplace
voice catalog.

Rationale tied to current code:

- `Hero` is “a person whose lived experience may inspire others.”
- Stories already bind ownership via `Story.heroId`.
- Synthetic narration already checks Hero ownership in
  `RenderStoryVoiceUseCase`.
- A single voice identity must be reusable across many Stories.
- Putting VoiceProfile on Story would duplicate identity per narrative and
  break revocation / reuse semantics.

**Explicit alternatives considered (not selected as the default):**

| Alternative | Consequence |
|-------------|-------------|
| Story-owned VoiceProfile | One profile per story; cannot reuse; revocation fragmented; treats voice as story media rather than person identity |
| EH User-owned VoiceProfile | Identity/User binding is still incomplete (`Hero.identityUserId` optional / future). Premature without Identity context maturity |
| Platform-owned VoiceProfile | Marketplace / celebrity / stock voices — explicitly rejected by HS-ADR-076 |
| Separate Voice bounded context | Over-partitioning; voice identity is Hero & Story presentation capability, same family as `StoryVoiceRendering` |

**Open:** Whether a non-Hero EH User may later own a VoiceProfile for
non-story experiences remains deferred until Identity binding is defined.
Until then, design VoiceProfile against `HeroId`.

### 2. Do not implement production cloning in the foundation milestones

HS.12.8 established the boundary without a production aggregate.

HS.12.9 implements the VoiceProfile aggregate, lifecycle, authorization gates,
repository interface, in-memory adapter, and application use cases.

It still does **not** ship:

- production VoiceProfile durable persistence schema
- production cloning / provider enrollment adapters
- consent UI / legal wording
- `voiceClone` enablement on `RenderStoryVoiceUseCase`

See `HS.12.9-Voice-Profile-Foundation.md`.

### 3. StoryVoiceRendering remains the derived artifact

Preserve HS-ADR-076 / HS-ADR-077:

- Story is not media
- `StoryVoiceRendering` is a derived presentation artifact
- Playback uses persisted bytes; Play never calls AI
- Provider labels on the rendering are opaque provenance strings

**Future relationship (when cloning is authorized):**

```text
VoiceProfile (identity)
      │
      │ referenced by id (and optional snapshot metadata)
      v
StoryVoiceRendering (artifact)
      ├── storyId / experiencePlanId / sourceRepresentationId
      ├── language / renderingMode
      ├── voiceProfileId?          # null for pure syntheticNarration
      ├── providerLabel / modelLabel
      └── mediaReference + bytes
```

Rules:

1. A rendering **may** store `voiceProfileId` when produced via a profile.
2. A rendering **should** snapshot opaque provider/model provenance at
   generation time (already: `providerLabel` / `modelLabel`).
3. A rendering **may exist without** a VoiceProfile — that is today's
   `syntheticNarration` path and must remain valid.
4. Historical renderings remain reproducible as **already-generated audio**.
   They do not automatically re-resolve a mutable live VoiceProfile.
5. Revoking a VoiceProfile **must block future synthesis** with that profile.
   Whether existing published/cached audio is deleted, unlisted, or retained
   is a **policy decision**, not a silent technical assumption (see spike
   report §8).

### 4. Reference audio is media, not domain bytes

Reference / enrollment audio:

- belongs **with** the VoiceProfile as referenced media, not as embedded bytes
- uses existing `MediaReference` + storage-port pattern
  (`StoryMediaStoragePort` or a purpose-scoped equivalent)
- may support **multiple** reference recordings over time
- must **not** be exposed through Story seeker/catalog APIs
- must not be treated as Story canonical media or as behavioral evidence

Raw reference audio retention, encryption, and off-device transfer requirements
are **unresolved product/legal questions**. Architecturally, EH must be able
to delete reference media and revoke provider enrollments independently of
Story lifecycle.

### 5. Consent / authorization is multi-gate and independent

Extend the existing independent-consent pattern established by `StoryConsent`
without overloading `voiceRenderingApprovedAt`.

Minimum future authorization distinctions:

```text
Voice exists
        ≠
Voice may be enrolled / cloned
        ≠
Voice may be used to synthesize this Story
        ≠
Synthesized audio may be published / shared
```

Conceptual gates (technical authorization model — **not** legal wording):

| Gate | Scope | Covers |
|------|-------|--------|
| Enrollment / cloning authorization | VoiceProfile | Create provider enrollment / local clone from reference audio |
| Synthesis-with-profile authorization | VoiceProfile (+ optional Story use grant) | Generate new audio using the profile |
| Story use authorization | Story (or Story↔Profile grant) | Use this profile for this story’s narration |
| Publication / distribution authorization | Story (existing publication consent) + voice-specific share rules | Share generated audio beyond private owner playback |
| Revocation | VoiceProfile / grant | Block future use; trigger cleanup policies |

Hard rules:

- Recording consent ≠ cloning consent
- AI transformation consent ≠ cloning consent
- Synthetic narration consent (`voiceRenderingApprovedAt`) ≠ cloning consent
- Publication consent ≠ cloning consent
- Creating a VoiceProfile must never be a side effect of
  “Create narrated version”

Exact field placement (StoryConsent vs VoiceProfileAuthorization vs both)
remains an **open decision** for the next milestone; HS.12.8 only locks the
independence requirement.

### 6. Cloning enrollment is a separate port from VoiceRenderingPort

**Decision:**

1. **Yes** — cloning / enrollment is a separate port from
   `VoiceRenderingPort`.
2. Enrollment and synthesis are **separate operations**.
3. Provider-specific voice IDs **must not** become domain identity.
4. Provider mapping lives in infrastructure / AI proxy (and optional sidecar).
5. Provider/model provenance for generated audio continues on
   `StoryVoiceRendering` as opaque labels; enrollment provenance lives with
   the VoiceProfile’s infrastructure bindings.
6. Provider failure remains a recoverable application/infrastructure failure
   (no fake/partial artifact), consistent with HS-ADR-076.

Preferred naming:

```text
VoiceProfilePort          # enroll / describe / revoke / delete identity
VoiceRenderingPort        # synthesize story audio (existing)
```

`VoiceCloningPort` as a name is acceptable only as an implementation alias
for enrollment; EH vocabulary should lead with **VoiceProfile** (identity),
not “clone” (one provider mechanism). Some providers are
reference-audio-at-synthesis systems and never mint a durable remote voice id.

Stack:

```text
Domain / Application
        │
        ▼
Provider-neutral ports
  (VoiceProfilePort | VoiceRenderingPort)
        │
        ▼
EH AI Proxy
        │
        ▼
Provider adapter / local sidecar
```

Do **not** introduce `POST /voice-clone` as the primary product route.
Prefer future `POST /voice-profiles` (+ DELETE) for enrollment lifecycle, and
continue narration via `POST /story-voice-renderings` with an optional
`voiceProfileId` when modes are authorized.

### 7. Provider mapping is multi-binding capable

One EH `VoiceProfileId` may eventually map to:

- zero enrollments (draft / revoked)
- one provider enrollment
- multiple provider enrollments (migration / fallback)

Domain identity remains `VoiceProfileId`. Infrastructure stores opaque
`providerKey` + `providerReference` (+ model/version metadata).

Deleting one provider enrollment must not erase EH identity history or
historical `StoryVoiceRendering` provenance. It may disable synthesis for that
provider until re-enrolled.

### 8. Qwen3 and hosted providers fit the same boundary

From HS.12.7 findings:

- Qwen3-TTS **CustomVoice** is a synthetic-speaker path already usable for
  narration experiments — **not** Hero cloning.
- Future Qwen cloning requires **Base** (or equivalent) models + reference
  audio, sidecar lifecycle, and local storage of reference/media handles.
- A later local Base/ICL inspection (not part of HS.12.8) found that the
  inspected `generate` path uses reference audio, reference transcript, and
  sampling controls. It does **not** currently apply `instruct` or `speed`.
  Reference transcripts should be durable enrollment metadata. See
  `Voice-Cloning-and-Story-Performance-Architecture.md`. That finding does
  not change this ADR's identity-versus-artifact boundary.
- Hosted providers (OpenAI today for synthetic; future hosted clone APIs)
  fit the same ports: proxy maps `VoiceProfileId` → provider resource.

EH domain must not know whether the underlying implementation is OpenAI,
Qwen3, CosyVoice, or another provider.

---

## Consequences

### Positive

- Preserves HS.12.6 / HS.12.7 narration architecture without a parallel
  narration abstraction
- Keeps AI providers replaceable behind the EH AI proxy
- Separates identity from artifact, matching Story ≠ Media and
  Story ≠ StoryVoiceRendering
- Makes consent independence enforceable before any cloning code lands
- Supports both durable hosted voice ids and local reference-audio-at-synth
  providers under one EH identity

### Tradeoffs

- VoiceProfile ownership defaults to Hero while Identity binding is still
  incomplete — may need a later Person/User remapping
- Multi-gate consent increases UX complexity (necessary for safety)
- Historical provenance vs live profile mutability requires snapshotting
  and careful revocation policy
- Multi-provider enrollments add infrastructure complexity

### Unresolved decisions (explicit)

1. Final retention period for reference audio
2. Encryption / privacy controls for reference audio at rest and in transit
3. Exact product/legal consent wording (technical authorization model exists)
4. Revocation policy for already-published generated audio
5. Whether selected narrations ever promote to approved `StoryRepresentation`
6. First cloning provider (Qwen Base vs CosyVoice vs hosted)
7. Whether non-Hero users may own VoiceProfiles
8. Streaming / real-time voice conversion (out of scope)

### Future implementation work (post HS.12.10)

- ~~HS.12.9 Voice Profile Foundation~~ → **complete**
- ~~HS.12.10 Voice Cloning Authorization Scope~~ → **complete**
- Reference-audio enrollment + storage purpose tags
- Proxy `/voice-profiles` routes + provider enrollment adapters
- Enable `VoiceRenderingMode.voiceClone` only behind consent + profile + scope
- Optional `voiceProfileId` on `StoryVoiceRendering` (deferred in HS.12.9/10)
- M4 Qwen benchmark remains a separate operational follow-up

---

## Addendum — HS.12.10 Voice Cloning Authorization Scope (2026-10-01)

### Decision

> Voice cloning authorization scope is configurable per VoiceProfile, with
> **perStory as the default**. **perProfile** is an explicit opt-in mode.

### Scope ≠ authorization

| Concept | Answers | Location |
|---------|---------|----------|
| `VoiceCloningAuthorizationScope` | Where is cloning authorization governed? | `VoiceProfile.cloningAuthorizationScope` |
| Cloning authorization stamps | Has cloning been authorized at that scope? | Profile `cloningAuthorizedAt` and/or Story `voiceCloningAuthorizedAt` |

These must never collapse into one boolean.

### Semantics

**perStory (default)**

- Effective cloning requires explicit Story-level cloning authorization.
- Profile-level cloning authorization alone does **not** authorize a Story.
- A newly created VoiceProfile must not blank-authorize every Story for the Hero.

**perProfile (explicit opt-in)**

- Profile-level cloning authorization may authorize cloning for Stories
  associated with that profile.
- Subject to remaining independent gates (enrollment lifecycle, story-use,
  ownership, publication remains independent).

### Explicit Story denial

StoryConsent distinguishes:

- not granted (both stamps null)
- authorized (`voiceCloningAuthorizedAt`)
- denied (`voiceCloningDeniedAt`)

**Story denial always wins**, including under `perProfile` scope. A
profile-level authorization must never silently override an explicit Story
denial.

### Independent gates (unchanged)

Enrollment ≠ cloning ≠ story-use ≠ publication ≠ synthetic narration
(`voiceRenderingApprovedAt`).

### Revocation / lifecycle

- Revoked or deleted VoiceProfiles can never be used for cloning.
- Changing scope does not erase existing authorization stamps.
- Switching back to `perStory` restores the Story-level requirement at
  evaluation time.

### Effective evaluation

Centralized in `VoiceCloningAuthorizationPolicy` →
`EffectiveVoiceCloningAuthorization`. Do not duplicate in use cases or UI.

### Deferred

Production cloning, provider enrollment adapters, consent UI, and
`StoryVoiceRendering.voiceProfileId` remain deferred.

See: `docs/architecture/HS.12.10-Voice-Cloning-Authorization-Scope.md`.

---

## Explicit non-decisions

HS.12.8 does **not** decide:

- final TTS provider
- final cloning provider
- commercial / legal policy
- consent wording
- retention period
- final VoiceProfile UX
- streaming
- real-time voice conversion
- ElevenLabs or any new hosted provider addition
- Qwen cloning implementation
- CosyVoice production adapter

---

## Rejected

- Collapsing VoiceProfile into StoryVoiceRendering
- Treating provider voice ids as domain identity
- Folding enrollment into `POST /story-voice-renderings`
- Creating a second Flutter-facing AI gateway for cloning
- Marketplace / celebrity / non-owner voice catalogs
- Inferring behavioral evidence from voice identity or renderings
- Implementing production cloning in this spike

---

## See also

- `docs/architecture/HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md`
- `docs/architecture/HS.12.9-Voice-Profile-Foundation.md`
- `docs/architecture/HS.12.10-Voice-Cloning-Authorization-Scope.md`
- `docs/architecture/HS.12.6-Voice-Rendering-Implementation-Report.md`
- `docs/architecture/HS.12.7-TTS-Provider-Benchmark.md`
- `docs/architecture/Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`
- `docs/architecture/Voice-Cloning-and-Story-Performance-Architecture.md`
- `docs/architecture/architecture-decisions.md` (HS-ADR-076, HS-ADR-077)
