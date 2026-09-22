# HS.FG.1 — Inspection Notes (pre-implementation)

**Date:** 2026-09-22  
**Branch:** `cursor/hs-fg-1-owner-publish-path-47ee`

## Inspection findings

```text
SB.13 materialization entry point:
  MaterializeStoryProposalUseCase
  (story_builder_controller.approveProposal → materializeApprovedProposal)
  → CreateStoryUseCase → Story.lifecycleStatus == draft
  UI: StoryBuilderUiPhase.storyCreated (“Not yet published”); Done pops only

Story lifecycle use cases:
  SubmitStoryUseCase  → draft → processing (requires processing consent)
  ApproveStoryUseCase → processing→review→approved (no separate reviewer role)
  PublishStoryUseCase → approved → published (optional visibility; requires publication consent + non-draft/private visibility)
  UpdateStoryConsentUseCase (wired)

Story repository:
  StoryRepository + InMemoryStoryRepository + FileStoryRepository
  (lifecycle/visibility/consent via StorySnapshotMapper)

Owner authorization mechanism:
  Owned reads: GetOwnedStoryDetailUseCase checks story.heroId == ownerHeroId
  Lifecycle mutations: storyId only — no owner/role check (existing model)
  Approve: owner may self-approve (no moderator role in code)

Visibility mechanism:
  StoryVisibility: private | draft | unlisted | community | public
  StoryDiscoverabilityPolicy: published + {public, community} + !provisional
  Materialize sets StoryVisibility.draft; publish does not auto-set visibility

Current owner-facing Story UI:
  MyStoriesScreen → OwnedStoryDetailScreen
  Actions today: archive (+ playback/transcription)
  No Submit / Approve / Publish / consent / visibility actions

Discovery query:
  DiscoverStoriesUseCase (+ HeroDiscoverabilityPolicy for Hero)

Current composition gap:
  Missing approveStoryUseCaseProvider / publishStoryUseCaseProvider
  Missing owned-detail publication actions
  Missing post-materialize navigation into owned publish path
  Consent + discoverable visibility required before publish succeeds
```

## Domain lifecycle note

Product copy may say “submitted”; domain status after Submit is `processing` (`StorySubmitted` event). Owner UI will label `processing` as **Submitted** without renaming the enum.
