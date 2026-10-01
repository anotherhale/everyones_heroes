# HS.12.10 — Voice Cloning Authorization Scope & Boundary

**Status:** Implemented (authorization architecture — **no production cloning**)  
**Date:** 2026-10-01  
**Phase:** HS.12.10  
**ADR:** HS-ADR-078 (addendum — cloning authorization scope)  
**Baseline preserved:** HS.12.6 / HS.12.7 / HS.12.8 / HS.12.9  
**Related:** HS-ADR-076, HS-ADR-077, HS-ADR-078,  
`Voice-Synthesis-Voice-Cloning-Implementation-Plan.md`,  
`HS.12.8-Voice-Identity-and-Cloning-Architecture-Spike.md`,  
`HS.12.9-Voice-Profile-Foundation.md`

---

## 1. Objective

Establish a configurable **voice-cloning authorization scope** so Heroes can
govern cloning authorization at either:

- the **Story** level (default, most restrictive), or
- the **VoiceProfile** level (explicit opt-in convenience)

without implementing production voice cloning or locking EH to a provider.

---

## 2. Problem

HS.12.9 introduced profile-level cloning authorization
(`VoiceProfileAuthorization.cloningAuthorizedAt`) as one of four independent
gates. Without an explicit scope:

- A newly authorized VoiceProfile could be read as blank-authorizing every
  Story belonging to the Hero.
- Story-level cloning grant vs profile-level grant precedence was undefined.
- Explicit Story denial was not modeled.

HS.12.10 closes that gap with a small, deterministic authorization model.

---

## 3. Decision Summary

| Concern | Decision |
|---------|----------|
| Scope location | On `VoiceProfile` as `cloningAuthorizationScope` |
| Default | `perStory` |
| Opt-in convenience | `perProfile` (explicit) |
| Scope ≠ authorization | Scope governs *where*; cloning stamps answer *whether* |
| Story representation | Extend existing `StoryConsent` (no parallel system) |
| Explicit denial | `voiceCloningDeniedAt` — always wins |
| Effective evaluation | Centralized `VoiceCloningAuthorizationPolicy` |
| Domain events | None for auth/scope changes (preserve HS.12.9) |
| `StoryVoiceRendering.voiceProfileId` | Still deferred |
| Production cloning | Not implemented |

---

## 4. perStory Default

```text
VoiceProfile
  cloningAuthorizationScope = perStory   ← default on create
Story
  voiceCloningAuthorizedAt = null
```

Effective cloning for that Story: **denied**.

A newly created VoiceProfile must **not** implicitly authorize cloning of every
Story belonging to the Hero.

Profile-level `cloningAuthorizedAt` alone must **not** bypass the Story
requirement under `perStory`.

---

## 5. perProfile Opt-In

```text
VoiceProfile
  cloningAuthorizationScope = perProfile
  cloningAuthorizedAt = <set>
```

Stories associated with that VoiceProfile may then use profile-level cloning
authorization, **subject to all other independent gates**.

This is **not** a blanket bypass for:

- story-use authorization
- publication authorization
- enrollment
- VoiceProfile lifecycle (revoked / deleted)
- explicit Story denial

---

## 6. Authorization Semantics

### Scope

```text
enum VoiceCloningAuthorizationScope {
  perStory,    // default
  perProfile,  // explicit opt-in
}
```

Answers: **Where is cloning authorization governed?**

### Authorization stamps

| Gate | Location | Meaning |
|------|----------|---------|
| Profile cloning | `VoiceProfileAuthorization.cloningAuthorizedAt` | Profile-level cloning grant |
| Story cloning grant | `StoryConsent.voiceCloningAuthorizedAt` | Story-level cloning grant |
| Story cloning denial | `StoryConsent.voiceCloningDeniedAt` | Explicit Story denial |

Answers: **Has cloning been authorized / denied at that scope?**

These remain separate from enrollment, story-use, publication, and synthetic
narration (`voiceRenderingApprovedAt`).

---

## 7. Precedence

```text
Deleted / revoked VoiceProfile
        ↓
always deny

Explicit Story denial (voiceCloningDeniedAt)
        ↓
always wins (including under perProfile)

Ownership mismatch (profile.ownerHeroId ≠ story.heroId)
        ↓
deny

Story-use authorization missing
        ↓
deny

Scope = perStory
        ↓
require Story voiceCloningAuthorizedAt
        (profile cloning alone is insufficient)

Scope = perProfile
        ↓
require profile cloningAuthorizedAt
        (subject to denial / other gates above)
```

### Limitation / extensibility note

HS.12.9 timestamp gates distinguished only “granted” vs “absent.” HS.12.10
adds the smallest extensible denial model for Story cloning:

- `authorized` — `voiceCloningAuthorizedAt != null && deniedAt == null`
- `denied` — `voiceCloningDeniedAt != null`
- `notGranted` — both null

Grant clears denial; deny clears grant; revoke clears both back to notGranted.
No full legal consent workflow is introduced.

---

## 8. Independent Authorization Gates

Unchanged independence rules (HS-ADR-078):

```text
Enrollment authorization
        ≠
Cloning authorization
        ≠
Story-use synthesis authorization
        ≠
Publication authorization
        ≠
Synthetic narration (voiceRenderingApprovedAt)
```

Cloning authorization must never imply enrollment, story-use, or publication.
Synthetic narration continues to work without VoiceProfile cloning
authorization.

---

## 9. Story Relationship

Story cloning authorization lives on existing `StoryConsent`:

```text
StoryConsent
 ├── … existing gates …
 ├── voiceCloningAuthorizedAt?
 └── voiceCloningDeniedAt?
```

- No provider IDs, enrollment IDs, API keys, or SDK types on Story
- Persistence: snapshot mapper extended with optional keys (backward-compatible)
- Application: dedicated Story cloning use cases + flags on
  `UpdateStoryConsentUseCase`

---

## 10. VoiceProfile Relationship

```text
VoiceProfile
 ├── cloningAuthorizationScope   (perStory | perProfile)
 └── VoiceProfileAuthorization
       ├── enrollment
       ├── cloning
       ├── storyUse
       └── publication
```

Application operations:

- `SetVoiceCloningAuthorizationScopeUseCase`
- `AuthorizeVoiceCloningUseCase` (existing)
- `RevokeVoiceCloningUseCase` (new)
- `AuthorizeStoryVoiceCloningUseCase`
- `DenyStoryVoiceCloningUseCase`
- `RevokeStoryVoiceCloningUseCase`

Changing scope does **not** mutate or erase existing authorization stamps.
Switching back to `perStory` restores the Story-level requirement at
evaluation time.

---

## 11. Lifecycle Restrictions

| Lifecycle | Cloning effective result |
|-----------|--------------------------|
| `revoked` | Always denied |
| `deleted` | Always denied |
| `enrolled` + gates satisfied | May be allowed |
| not enrolled | Denied (`profileNotEnrolled`) |

---

## 12. Effective Authorization Policy

```text
VoiceProfile + Story + authorization state
        ↓
VoiceCloningAuthorizationPolicy.evaluate(...)
        ↓
EffectiveVoiceCloningAuthorization (allowed | denied + reason)
```

Centralized in domain. Presentation must not calculate effective cloning
authorization. Use cases must not duplicate the policy.

---

## 13. Domain Events

**None added** for scope / cloning authorization changes.

Preserves HS.12.9 decision: cloning / story-use / publication authorization
stamps do not raise events until a reactor needs them.

---

## 14. StoryVoiceRendering Impact

**Still deferred:** optional `voiceProfileId` on `StoryVoiceRendering`.

Rationale unchanged from HS.12.9:

1. `voiceClone` remains rejected in `RenderStoryVoiceUseCase`
2. Authorization architecture does not require the field yet
3. Avoid persistence migration for a value that would always be null

---

## 15. Persistence Impact

| Artifact | Change |
|----------|--------|
| `VoiceProfile` | In-memory only (no durable schema); scope field on aggregate |
| `StoryConsent` | Snapshot mapper adds optional cloning keys |
| Provider bindings | Still infrastructure-only; not introduced |

Future durable VoiceProfile persistence must include
`cloningAuthorizationScope` (default `perStory` for legacy rows).

---

## 16. Provider Boundary

Unchanged:

```text
EH VoiceProfile
      ↓
VoiceProfilePort
      ↓
EH AI Proxy
      ↓
future provider
```

No ElevenLabs / Qwen3 cloning / CosyVoice / OpenAI cloning integration,
provider SDKs, credentials, or provider voice IDs in domain objects.

`VoiceRenderingPort` remains the synthetic narration contract and is unchanged.
`VoiceProfilePort` semantics remain intact.

---

## 17. Deferred Cloning Implementation

Explicit non-goals (unchanged):

- production voice cloning
- provider selection / credentials
- reference-audio encryption / retention jobs
- consent UI / legal workflow
- VoiceProfile screens / marketplace
- enabling `VoiceRenderingMode.voiceClone`
- M4 cloning benchmark

---

## 18. Recommended Next Milestone

**HS.12.11 (candidate)** — only with explicit approval:

- First cloning provider spike behind `VoiceProfilePort` (still no user UI), or
- Reference-audio storage purpose tags + retention policy decision, or
- Optional `voiceProfileId` on `StoryVoiceRendering` when cloning path is next

Do **not** auto-start production cloning from this milestone.
