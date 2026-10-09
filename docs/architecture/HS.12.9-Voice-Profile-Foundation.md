# HS.12.9 — Voice Profile Foundation

**Status:** Implemented (domain foundation — **no production cloning**)  
**Date:** 2026-10-01  
**Phase:** HS.12.9  
**ADR:** HS-ADR-078 (unchanged architectural boundary; this milestone implements
the aggregate foundation it deferred)  
**Baseline preserved:** HS.12.6 voice rendering + HS.12.7 proxy TTS selection +
HS.12.8 identity/cloning boundary  
**Related:** HS-ADR-076, HS-ADR-077, HS-ADR-078,  
`Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`,  
`HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md`,  
`Voice-Cloning-and-Story-Performance-Architecture.md`

---

## 1. Executive Summary

HS.12.9 implements the provider-independent **VoiceProfile** domain foundation
and lifecycle without selecting a cloning provider or shipping production
enrollment adapters.

```text
VoiceProfile          = Hero-scoped voice identity (now a real aggregate)
StoryVoiceRendering   = derived audio artifact (unchanged)
VoiceProfilePort      = enrollment / revoke / delete boundary (wired)
VoiceRenderingPort    = story narration (unchanged; voiceClone still rejected)
```

---

## 2. What Was Implemented

| Area | Status |
|------|--------|
| `VoiceProfile` aggregate | Implemented |
| Hero ownership invariant | Implemented (`ownerHeroId` immutable) |
| Lifecycle | `draft → authorized → enrolled → revoked → deleted` |
| Authorization gates | Four independent timestamps (enrollment / cloning / story-use / publication) |
| Reference media | `List<MediaReference>` (multiple clips; no bytes) |
| `VoiceProfilePort` | Preserved; used by enroll / revoke / delete use cases |
| `InMemoryVoiceProfileAdapter` | Synthetic enrollment only |
| `VoiceProfileRepository` + in-memory impl | Implemented (durable persistence deferred) |
| Application use cases | Create / authorize×4 / enroll / revoke / delete |
| Domain events | Created, EnrollmentAuthorized, Enrolled, Revoked, Deleted |
| Optional `voiceProfileId` on `StoryVoiceRendering` | **Deferred** (see §6) |
| Production cloning / provider enrollment | **Not implemented** |

---

## 3. Aggregate Design

```text
VoiceProfile
 ├── VoiceProfileId          # EH identity (implements AggregateId)
 ├── HeroId ownerHeroId      # exactly one Hero; immutable
 ├── VoiceProfileLifecycleStatus
 ├── VoiceProfileAuthorization
 ├── List<MediaReference>    # reference clips; no Uint8List
 ├── LanguageCode
 ├── displayName?
 └── createdAt / updatedAt
```

Explicitly excluded from the aggregate:

- generated audio / `StoryVoiceRendering`
- provider SDK objects / credentials / `providerVoiceId`
- HTTP / storage implementation / UI state

---

## 4. Lifecycle vs Authorization

Lifecycle tracks enrollment readiness and revocation:

| Status | Meaning |
|--------|---------|
| `draft` | Created; enrollment not authorized |
| `authorized` | Enrollment authorization granted; not enrolled |
| `enrolled` | Domain recorded enrollment completion (active) |
| `revoked` | Future authorized voice use blocked |
| `deleted` | Terminal soft-delete |

Authorization gates are independent of lifecycle (except enrollment gate is
required to enter `enrolled`):

| Gate | Field | Independence |
|------|-------|--------------|
| Enrollment | `enrollmentAuthorizedAt` | Required before `markEnrolled` |
| Cloning | `cloningAuthorizedAt` | Not implied by enrollment |
| Story-use synthesis | `storyUseAuthorizedAt` | Not implied by cloning |
| Publication | `publicationAuthorizedAt` | Not implied by any other gate |

`StoryConsent.voiceRenderingApprovedAt` remains synthetic-narration-only and
must never be read as cloning authorization.

---

## 5. Ports and Adapters

```text
Application use cases
        │
        ├── VoiceProfileRepository (in-memory for HS.12.9)
        └── VoiceProfilePort
                │
                └── InMemoryVoiceProfileAdapter  (synthetic enrollment labels)
```

`InMemoryVoiceProfileAdapter` deliberately does **not** pretend to be a real
provider. It stores opaque synthetic enrollment records keyed by
`VoiceProfileId` for tests and local development.

Production path (future):

```text
VoiceProfilePort → Flutter infra / proxy adapter → EH AI Proxy → provider
```

---

## 6. StoryVoiceRendering Integration Decision

**Deferred:** optional `voiceProfileId` on `StoryVoiceRendering`.

Rationale:

1. `voiceClone` remains rejected in `RenderStoryVoiceUseCase`.
2. Adding the field now forces persistence mapper / snapshot migration for a
   value that would always be null until cloning is enabled.
3. Synthetic narration remains valid without a VoiceProfile (preserved).
4. HS-ADR-078 already documents the future optional relationship.

When cloning is enabled (post-HS.12.9), add nullable `voiceProfileId` and keep
historical synthetic renderings with null.

---

## 7. Persistence Decision

**Deferred durable persistence.**

- Repository interface: `VoiceProfileRepository`
- Runtime for HS.12.9: `InMemoryVoiceProfileRepository`
- No new database / file schema
- Intended future: same snapshot-mapper pattern used by other Hero & Story
  aggregates, without embedding provider bindings in the aggregate

Provider enrollment bindings (`providerKey` + opaque handle + model/version)
remain infrastructure concerns keyed by `VoiceProfileId`.

---

## 8. Domain Events

Emitted for meaningful lifecycle transitions:

- `VoiceProfileCreated`
- `VoiceProfileEnrollmentAuthorized`
- `VoiceProfileEnrolled`
- `VoiceProfileRevoked`
- `VoiceProfileDeleted`

Not emitted for cloning / story-use / publication authorization (mirrors
`StoryConsent` — authorization stamps without events until a reactor needs
them).

---

## 9. Explicit Non-Goals (unchanged)

- Production voice cloning (Qwen / OpenAI / CosyVoice / ElevenLabs)
- Provider enrollment adapters / provider voice IDs in domain
- Reference-audio upload, encryption, retention jobs
- Consent UI / legal workflows
- VoiceProfile screens / marketplace / voice sharing
- Streaming / voice conversion / M4 benchmarking
- Enabling `VoiceRenderingMode.voiceClone`

---

## 10. Recommended Next Milestone

**HS.12.10** — Voice Cloning Authorization Scope → **complete**
(see `HS.12.10-Voice-Cloning-Authorization-Scope.md`).

**HS.12.11 (candidate)** — only with explicit approval:

- Reference-audio storage purpose tags + retention policy decision
- First cloning provider spike behind `VoiceProfilePort` (still no user UI)
- Optional `voiceProfileId` on `StoryVoiceRendering` when cloning path is next

Do **not** auto-start production cloning from this milestone.
