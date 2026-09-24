-- J.2 Slice 4: thin discoverable Story candidate projection.
--
-- Derived data only — NOT an authoritative Story or Hero model.
-- Authoritative Story/Hero remains Flutter-side until Phase 7.
--
-- Ownership: Hero & Story module (platform).
-- Consumers: StoryCandidateSource → DiscoverableStoryCandidatePort → Experience.
-- Experience must never write this table.

CREATE TABLE IF NOT EXISTS discoverable_story_candidates (
  story_id TEXT PRIMARY KEY,
  hero_id TEXT NOT NULL,
  title TEXT NOT NULL,
  theme_ids JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  -- Optional denormalized eligibility facts for diagnostics / invalidation.
  -- These are NOT authoritative Story/Hero state.
  story_visibility TEXT,
  hero_visibility TEXT,
  projected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_discoverable_story_candidates_updated_at
  ON discoverable_story_candidates (updated_at DESC);

-- GIN index for future theme-prefilter queries (optional for Slice 4 load-all).
CREATE INDEX IF NOT EXISTS idx_discoverable_story_candidates_theme_ids
  ON discoverable_story_candidates USING GIN (theme_ids);
