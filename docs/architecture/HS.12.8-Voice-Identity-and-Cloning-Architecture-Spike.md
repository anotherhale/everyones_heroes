# HS.12.8 — Voice Identity & Cloning Architecture Spike

**Status:** Spike complete (architecture / discovery only — **no production cloning**)  
**Date:** 2026-09-30  
**Phase:** HS.12.8  
**ADR:** HS-ADR-078  
**Baseline preserved:** HS.12.6 voice rendering + HS.12.7 proxy `TtsProvider` selection  
**Related:** HS-ADR-076, HS-ADR-077,  
`Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`,  
`HS.12.6-Voice-Rendering-Implementation-Report.md`,  
`HS.12.7-TTS-Provider-Benchmark.md`,  
`Voice-Cloning-and-Story-Performance-Architecture.md` (later Base/ICL experiment; performance direction; not this spike)

---

## 1. Executive Summary

HS.12.8 establishes a provider-neutral architecture for **future** voice
identity and voice cloning without implementing cloning, enrollment, consent
UI, or provider adapters.

Central distinction (locked by HS-ADR-078):

```text
VoiceProfile          = voice identity (provider-independent)
StoryVoiceRendering   = derived audio artifact for a Story
```

A VoiceProfile may later produce many renderings. A rendering remains a
derived artifact with provenance. Synthetic narration without a VoiceProfile
remains valid and is the only path enabled today.

**What this spike delivers**

- HS-ADR-078 Voice Identity and Cloning Boundary
- This architecture report
- Skeletal `VoiceProfileId` + `VoiceProfilePort` (enrollment boundary only)
- Architecture tests locking the identity ≠ artifact ≠ provider boundary

**What this spike does not deliver**

- Actual cloning
- Reference-audio enrollment / persistence
- VoiceProfile aggregate / repository
- Consent database / UI
- Provider cloning adapters (Qwen Base, CosyVoice, ElevenLabs, etc.)
- Streaming / real-time conversion
- Final provider or legal policy selection

---

## 2. Existing HS.12.6 / HS.12.7 Architecture

### 2.1 Inspected artifacts (authoritative)

| Artifact | Role |
|----------|------|
| `VoiceRenderingPort` | Provider-neutral synthesis boundary |
| `StoryVoiceRendering` | Derived presentation VO (not Story identity) |
| `RenderStoryVoiceUseCase` | Ownership + `voiceRenderingApprovedAt` + persist bytes |
| `VoiceRenderingMode` | `syntheticNarration` supported; `voiceClone` / `heroVoiceTransformation` rejected |
| `StoryConsent.voiceRenderingApprovedAt` | Synthetic narration gate only |
| `MediaReference` + `StoryMediaStoragePort` | Opaque media pointers; bytes outside aggregates |
| `ProxyVoiceRenderingAdapter` | Flutter → EH AI proxy only |
| `InMemoryVoiceRenderingAdapter` | Deterministic Flutter tests |
| `services/ai_proxy` `TtsProvider` / resolver | HS.12.7 provider selection (proxy-only) |
| HS-ADR-076 / HS-ADR-077 | Derived artifact + provider-neutral synthetic contract |

### 2.2 Current narration path (preserved)

```text
HeroStoryScreen / lab
  → RenderStoryVoiceUseCase
      (hero ownership + voiceRendering consent + plan + transcript)
  → VoiceRenderingPort
  → ProxyVoiceRenderingAdapter | InMemoryVoiceRenderingAdapter
  → POST /story-voice-renderings
  → TtsProviderResolver (EH_TTS_PROVIDER | opaque hints)
       ├── openai → OpenAiTtsProvider
       └── qwen3  → LocalHttpTtsProvider → Python sidecar
  → StoryVoiceRendering + StoryMediaStoragePort
  → Play narrated version (persisted bytes only)
```

### 2.3 HS.12.7 findings used by this spike

From `HS.12.7-TTS-Provider-Benchmark.md`:

- Provider selection belongs **only** in `services/ai_proxy`
- Flutter / domain continue to depend only on voice-rendering contracts
- Qwen3-TTS **0.6B-CustomVoice** ran successfully for synthetic narration
  experiments (CPU measured; MPS recommended as M4 follow-up)
- CustomVoice speakers ≠ Hero voice cloning
- Future Qwen cloning requires **Base** (or equivalent) + reference audio
- Later Base/ICL inspection (after this spike) also requires a durable
  reference transcript and found that `instruct` and `speed` are **not**
  applied on that path. See
  `Voice-Cloning-and-Story-Performance-Architecture.md`.
- CosyVoice was **not** successfully verified; no production adapter claimed
- Final TTS / cloning provider selection remains deferred

### 2.4 Doc vs code note (still relevant)

Early HS.12 plan sketches that put cloning on `StoryRepresentation` +
proposed ADR-074 were **never accepted**. Current law is HS-ADR-076 + code:
synthetic (and future cloned) story narration persists as
`StoryVoiceRendering` unless a future ADR promotes a selected narration to an
approved representation.

---

## 3. Problem Definition

EH needs to answer:

> How should voice identity be represented and managed separately from
> generated story narration, while remaining provider-neutral?

Without this boundary, future work risks:

1. Treating provider voice ids as domain identity
2. Folding enrollment into story narration requests
3. Overloading `voiceRenderingApprovedAt` as cloning consent
4. Embedding reference audio into Story APIs
5. Making historical renderings silently mutate when a live profile changes
6. Coupling Flutter to cloning SDKs / credentials

---

## 4. VoiceProfile Concept

### 4.1 Proposed identity

**What uniquely identifies a voice profile?**

An EH-owned `VoiceProfileId` (UUID strongly-typed id), independent of:

- Story ids
- StoryVoiceRendering ids
- Provider voice ids / embedding handles
- OpenAI voice names (`alloy`, etc.)
- Qwen CustomVoice speaker labels

### 4.2 Conceptual fields — what belongs where

| Field / concern | Belongs in domain VoiceProfile? | Notes |
|-----------------|----------------------------------|-------|
| `voiceProfileId` | **Yes** | EH identity |
| Display / name metadata | **Yes** (optional) | Human label; not vendor id |
| Owner / subject (`HeroId`) | **Yes** | Default ownership — see §4.3 |
| Language capabilities | **Yes** (as EH language codes / capabilities) | Not vendor locale enums |
| Lifecycle / status | **Yes** | e.g. draft / active / revoked / deleted |
| Consent / authorization timestamps | **Yes** (or sibling authorization VO) | Independent gates |
| Provenance of enrollment source | **Yes** (refs) | `MediaReference` and/or source representation id |
| Provider-independent identity | **Yes** | Core rule |
| Provider key / providerVoiceId / model / version | **Infrastructure mapping** | Opaque bindings keyed by `VoiceProfileId`; not domain identity |
| Raw reference audio bytes | **No** | Storage port only |
| Vendor SDKs / credentials | **No** | Proxy / sidecar only |
| UX copy / legal policy text | **No** | Product / legal |

### 4.3 Ownership alternatives

| Owner | Fit | Architectural consequence |
|-------|-----|---------------------------|
| **Hero (selected default)** | Strong | Matches `Story.heroId` ownership checks; reusable across stories; aligns with “Hero owns the story, AI owns the presentation” for presentation artifacts that still require Hero authorization |
| Story | Weak | One identity per narrative; breaks reuse; confuses identity with artifact |
| EH User | Premature | `Hero.identityUserId` binding incomplete; Identity context not ready as owner of voice |
| Platform | Rejected | Marketplace / celebrity / stock voices contradict HS-ADR-076 |
| New bounded context | Unnecessary | Voice identity is Hero & Story capability, same family as renderings |

**Decision for future implementation:** VoiceProfile is **Hero-scoped**.  
**Open:** remapping when Person/User ↔ Hero identity binding lands.

### 4.4 Aggregate readiness

HS.12.8 does **not** implement the production aggregate. The existing
architecture does not yet require a full aggregate to answer the boundary
question. Skeletal `VoiceProfileId` + `VoiceProfilePort` make the enrollment
seam explicit without inventing persistence.

---

## 5. VoiceProfile vs StoryVoiceRendering

```text
VoiceProfile
     |
     | used to synthesize (future voiceClone mode)
     v
StoryVoiceRendering
     |
     +--> audio artifact (MediaReference + bytes)
     +--> story / plan / source representation refs
     +--> voiceProfileId? (optional)
     +--> provider/model provenance (opaque labels)
```

### Clarifications

| Question | Answer |
|----------|--------|
| Does a rendering store `voiceProfileId`? | **Yes, optionally**, when the rendering was produced using a profile. Null/absent for pure `syntheticNarration`. |
| Does a rendering snapshot voice metadata? | **Yes for provenance that must survive profile change:** providerLabel, modelLabel, language, renderingMode, timestamps, processing versions. Do not rely on live profile mutation for historical meaning. |
| Can a rendering exist without a VoiceProfile? | **Yes.** Required for today’s synthetic path and for any future non-clone narration. |
| How do historical renderings remain reproducible if VoiceProfile changes? | Reproducibility of **playback** = persisted audio bytes. Reproducibility of **regeneration** = may require frozen enrollment snapshot / re-enrollment; live profile changes must not rewrite historical artifacts. |
| Does deleting/revoking a VoiceProfile invalidate existing renderings? | **Future synthesis: yes (blocked).** Existing bytes: policy-dependent (retain / unlist / delete). Architecture must support all three policies without rewriting history silently. |

Do **not** put VoiceProfile fields onto the Story aggregate. Do **not** treat
`StoryVoiceRendering` as the voice identity.

---

## 6. Reference Audio

### Recommendation

| Concern | Recommendation |
|---------|----------------|
| Inside VoiceProfile aggregate? | Store **references**, not bytes |
| Representation | `MediaReference` (+ optional purpose/metadata outside Story catalog) |
| Storage ownership | Existing media storage port pattern (or purpose-scoped twin); adapters own bytes |
| Multiple recordings | **Yes** — support multiple reference clips over lifecycle |
| Story API exposure | **No** — must not appear on seeker Story APIs / catalog |
| Indefinite raw retention | **Do not assume yes** — architecture must support deletion independent of Story lifecycle |
| Encryption / privacy | Required capability area; exact controls unresolved |
| Enrollment implementation | **Out of scope for HS.12.8** |

### Unresolved questions

1. Retention period after revoke / delete
2. Whether reference audio may leave EH hardware for hosted clone APIs
3. Encryption at rest / in transit requirements
4. Whether enrollment may reuse an existing Story original recording vs requiring a dedicated enrollment sample
5. Audit fields for “sample left device / provider category” disclosures

---

## 7. Consent / Authorization

This is a **technical authorization / provenance model**, not a legal consent
system. It can later integrate with product/legal requirements.

### Independence rule (extends StoryConsent pattern)

```text
Voice exists
        ≠
Voice may be enrolled / cloned
        ≠
Voice may be used to synthesize this Story
        ≠
Voice / generated audio may be published / shared
```

Existing gates that must **not** unlock cloning:

- `recordedAt`
- `processingApprovedAt`
- `publicationApprovedAt`
- `aiTransformationApprovedAt`
- `voiceRenderingApprovedAt` (synthetic narration only)
- `musicGenerationApprovedAt`

### Minimum future concepts

| Concept | Needed for |
|---------|------------|
| Enrollment authorization | Creating a VoiceProfile / sending reference audio to a cloning path |
| Cloning / provider-enrollment authorization | Creating provider-side or local cloned representation |
| Synthesis-with-profile authorization | Calling `VoiceRenderingPort` in `voiceClone` mode |
| Story use authorization | Binding a profile to a specific Story narration |
| Publication / distribution authorization | Sharing generated audio beyond private owner playback |
| Revocation | Blocking future use; initiating cleanup workflows |

**Preference (from Voice Synthesis plan, affirmed here):**  
profile-level ownership consent **plus** explicit per-story use authorization  
so one profile can serve many stories without implying marketplace
impersonation.

Exact schema remains open for HS.12.9.

---

## 8. Revocation

HS.12.8 does **not** pick a product/legal policy. It documents technical
consequences of candidate policies.

| Asset / action | Policy A — Soft revoke (block future only) | Policy B — Unlist / hide generated audio | Policy C — Hard delete generated audio + refs | Policy D — Best-effort provider purge |
|----------------|--------------------------------------------|------------------------------------------|-----------------------------------------------|----------------------------------------|
| Future synthesis | Blocked | Blocked | Blocked | Blocked |
| Existing private generated audio | Retained for owner | Hidden from non-owner surfaces; owner policy TBD | Deleted from EH storage | May still exist until EH delete |
| Cached audio | Cache invalidation optional | Invalidate public caches | Delete caches | Same |
| Published audio | Remains unless publication also revoked | Remove from discovery/public | Delete media; update visibility | Same + remote cleanup |
| Derived / localized versions | Same as parent policy | Same | Same | Same |
| Provider-side cloned voice | May remain | May remain | May remain | Attempt delete via provider API / local handle purge |
| Reference recordings | Retain or delete per retention policy | Same | Prefer delete | Prefer delete |

**Architectural requirement:** revoke must be representable as a first-class
VoiceProfile lifecycle transition that use cases consult before synthesis.
Provider cleanup is best-effort infrastructure, never the domain’s only
source of truth.

---

## 9. Provider-Neutral Cloning Boundary

### Answers to the spike questions

| # | Question | Answer |
|---|----------|--------|
| 1 | Separate port from `VoiceRenderingPort`? | **Yes.** Enrollment ≠ narration. |
| 2 | Enrollment and synthesis separate? | **Yes.** |
| 3 | Provider-specific voice IDs in domain? | **No.** Opaque infrastructure bindings only. |
| 4 | Where does provider mapping live? | AI proxy (+ sidecar) / Flutter infrastructure adapters — never domain. |
| 5 | How is provider/model provenance persisted? | Opaque labels on `StoryVoiceRendering`; enrollment metadata on infrastructure bindings for the profile. |
| 6 | How is provider failure represented? | Recoverable failure; no fake/partial artifact; original recording remains playable. |

### Proposed port (skeletal in code)

Prefer EH vocabulary **`VoiceProfilePort`** over `VoiceCloningPort`:

```text
VoiceProfilePort
  enroll(...) → VoiceProfileEnrollmentDraft   # create / refresh enrollment
  revoke(VoiceProfileId)
  delete(VoiceProfileId)
  // optional later: describe / health / capability probe
```

Synthesis continues on existing:

```text
VoiceRenderingPort.render(...)
  // future: renderingMode=voiceClone + voiceProfileId
```

Why not primary name `VoiceCloningPort`?

- “Cloning” is one provider mechanism
- Local reference-audio-at-synthesis providers may never mint a durable clone id
- EH’s durable concept is the **profile identity**

Stack preference (confirmed):

```text
Domain/Application
        │
        v
Provider-neutral port
        │
        v
EH AI Proxy
        │
        v
Provider adapter / sidecar
```

Rejected product route name: `POST /voice-clone` as primary. Prefer future
`POST /voice-profiles` for enrollment lifecycle.

---

## 10. Provider Mapping

```text
EH VoiceProfile
       |
       +-- provider-neutral identity (VoiceProfileId)
       |
       +-- provider-specific enrollments[]   (infrastructure)
              |
              +-- providerKey          # opaque: openai | qwen3 | …
              +-- providerVoiceId      # opaque handle / remote id / local cache key
              +-- model
              +-- version
```

| Capability | Recommendation |
|------------|----------------|
| One provider enrollment | Supported (common case) |
| Multiple provider enrollments | Supported (migration / fallback) |
| Provider fallback | Infrastructure policy; domain asks for synthesis with profile id, not provider |
| Provider migration | Re-enroll under same `VoiceProfileId`; keep historical rendering provenance |
| Delete one enrollment | Disable that provider path; do not erase EH identity or historical artifacts |

Domain must never require a specific provider to exist for a VoiceProfile to
be conceptually valid (draft / revoked states).

---

## 11. Qwen3 Fit

Using **actual HS.12.7 findings** (no new M4 benchmark in this milestone):

| Topic | Implication for future cloning adapter |
|-------|----------------------------------------|
| Reference-audio input | Required for Base/clone paths; CustomVoice used in HS.12.7 is **not** cloning |
| Text / prompt input | Narration text remains VoiceRenderingPort input; clone enrollment is separate |
| Model lifecycle | Sidecar owns load/device/weights; proxy owns EH auth + routing |
| Local storage | Reference media via MediaReference; optional local embedding/cache handles in infra |
| Provider/model metadata | Opaque labels (`qwen3`, checkpoint name) on enrollments / renderings |
| CPU / MPS / GPU | CPU RTF ≈ 2.5–2.9 measured (too slow for snappy UX); MPS recommended M4 follow-up; CUDA happy path upstream |
| Generated voice identity | EH `VoiceProfileId`; Qwen handles remain infrastructure |
| Persistence | EH persists profile + media refs + renderings; not vendor objects as domain state |
| Production readiness | **Not claimed.** Architecture-compatible only. |

M4 Qwen operational benchmark (RTF/RAM/utilization/quality) remains a
**separate** follow-up, not part of HS.12.8.

---

## 12. Hosted Provider Fit

Hosted clone/TTS providers fit the same ports:

```text
VoiceProfilePort.enroll
  → proxy maps VoiceProfileId + reference media
  → hosted provider creates remote voice resource
  → store opaque providerVoiceId binding

VoiceRenderingPort.render(mode: voiceClone, voiceProfileId: …)
  → proxy resolves binding
  → hosted synthesis
  → StoryVoiceRendering provenance labels
```

EH domain must not know whether the implementation is:

- OpenAI (synthetic today; cloning not in EH path)
- Qwen3 (local sidecar)
- CosyVoice (unevaluated for production)
- another hosted provider

No ElevenLabs (or other new hosted) client is added by HS.12.8.

---

## 13. Proposed Future Architecture

Refined from the prompt diagram to match shipped EH seams:

```text
                    ┌───────────────────────┐
                    │         Hero          │
                    │   (subject / owner)   │
                    └───────────┬───────────┘
                                │ owns
                                v
                    ┌───────────────────────┐
                    │     VoiceProfile      │
                    │  VoiceProfileId       │
                    │  provider-independent │
                    └───────────┬───────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              v                 v                 v
       Reference Audio   Consent/Authorization   Lifecycle
       (MediaReference)  (enroll≠use≠publish)    (active/revoked)
              │
              v
       VoiceProfilePort (enroll / revoke / delete)
              │
              v
         EH AI Proxy
              │
              v
      Provider enrollment binding(s)
      (opaque providerKey + providerVoiceId)
              │
              │  later used by
              v
       VoiceRenderingPort  (existing)
              │  renderingMode: syntheticNarration | voiceClone*
              v
       StoryVoiceRendering (existing derived artifact)
              │
              v
         Audio Media (StoryMediaStoragePort)

* voiceClone remains rejected until a post-HS.12.8 implementation milestone
  enables it behind consent + profile.
```

Synthetic narration without a VoiceProfile continues to flow through
`VoiceRenderingPort` unchanged.

---

## 14. Alternatives Considered

| Alternative | Verdict |
|-------------|---------|
| Collapse VoiceProfile into StoryVoiceRendering | **Reject** — identity ≠ artifact |
| Put cloning on StoryRepresentation (old HS.12 §G) | **Reject** unless future ADR + approval lifecycle; current law is HS-ADR-076 |
| Single `VoiceCloningPort` that also synthesizes | **Reject** — mixes enrollment and narration |
| New `StoryNarrationPort` parallel to VoiceRenderingPort | **Reject** — HS-ADR-077 already forbids parallel narration ports |
| Platform voice marketplace | **Reject** — HS-ADR-076 |
| Provider voice id as domain id | **Reject** — replaceability + provenance |
| Implement full aggregate in HS.12.8 | **Reject** — spike only; stopping rule |
| Auto-create profile during “Create narrated version” | **Reject** — consent side-effect hazard |

---

## 15. Open Questions

1. Exact consent field placement (StoryConsent vs VoiceProfileAuthorization vs both)
2. Retention period and encryption for reference audio
3. Revocation policy for already-published generated audio
4. Whether any narration ever promotes to approved `StoryRepresentation`
5. First cloning provider after architecture approval
6. Non-Hero VoiceProfile ownership after Identity binding
7. Whether enrollment may reuse original Story recordings
8. Lab vs production feature-flag matrix for clone mode
9. Legal review of Qwen/CosyVoice/hosted cloning ToS before any user-facing clone
10. M4 MPS performance confirmation (operational, not architectural blocker)

---

## 16. Recommended Next Milestone

**HS.12.9 — Voice Profile Foundation (no production cloning adapter yet)**

Smallest coherent follow-up:

1. Implement VoiceProfile aggregate/VO + lifecycle + Hero ownership invariants
2. Persist profile-level authorization gates (schema only; product copy later)
3. Wire `VoiceProfilePort` in-memory adapter + use cases (enroll stub / revoke)
4. Add optional `voiceProfileId` on `StoryVoiceRendering` (still reject
   `voiceClone` mode in RenderStoryVoiceUseCase until explicitly enabled)
5. Architecture + domain tests for consent independence and revoke-blocks-synthesis
6. ADR addendum only if consent field placement is decided

**Explicitly not HS.12.9 by default:**

- Qwen Base cloning implementation
- CosyVoice adapter
- ElevenLabs / new hosted providers
- Consent UI legal wording
- Streaming
- M4 benchmark (run separately if needed)

---

## 17. Explicit Non-Goals

HS.12.8 does **not**:

- implement actual voice cloning
- enroll reference audio
- persist VoiceProfile aggregates
- add provider cloning adapters
- add consent UI or consent database
- add provider SDK integration to Flutter
- add new Flutter screens
- implement streaming or real-time voice conversion
- select final TTS or cloning provider
- run the M4 Qwen operational benchmark as part of this milestone
- invent legal requirements or commercial policy

---

## 18. Code / Test Artifacts Added by This Spike

| Path | Purpose |
|------|---------|
| `docs/architecture/HS-ADR-078-Voice-Identity-and-Cloning-Boundary.md` | ADR |
| `docs/architecture/HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md` | This report |
| `docs/architecture/architecture-decisions.md` | HS-ADR-078 entry |
| `lib/core/ids/voice_profile_id.dart` | Future domain identity type |
| `lib/features/hero_story/domain/services/voice_profile_port.dart` | Skeletal enrollment port |
| `test/features/hero_story/architecture/hs12_8_voice_identity_boundary_test.dart` | Boundary tests |

No changes to RenderStoryVoiceUseCase behavior, proxy TTS selection, or
supported rendering modes.

---

## 19. Investigation Evidence Trail

Inspected before writing decisions:

- `Story`, `StoryRepresentation`, `StoryVoiceRendering`, `VoiceRenderingPort`
- `RenderStoryVoiceUseCase`, `StoryConsent`, `VoiceRenderingMode`
- `MediaReference`, `StoryMediaStoragePort`, `MusicRendering` (parallel derived artifact)
- `Hero` ownership model (`HeroId`, optional `identityUserId`)
- HS.12.6 report, HS.12.7 benchmark, Voice Synthesis plan, HS-ADR-076/077
- `services/ai_proxy` `TtsProvider`, sidecar README, story voice handler
- Architecture AI boundary tests

No parallel narration abstraction was invented. Existing EH concepts were
extended only where the boundary required an explicit future seam
(`VoiceProfileId`, `VoiceProfilePort`).
