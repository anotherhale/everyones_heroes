-- H.2 Life Journey persistence on the PF.3 foundation.
-- Journeys and Reflections are owned by identity_users (no parallel users table).
-- Domain events flow through the PF.3 in-process EventStore (no separate event log).

CREATE TABLE IF NOT EXISTS journeys (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES identity_users (id),
  vision TEXT NOT NULL,
  current_chapter TEXT NOT NULL,
  active_quest_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  behavior_patterns JSONB NOT NULL DEFAULT '[]'::jsonb,
  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journeys_user_id ON journeys (user_id);

CREATE TABLE IF NOT EXISTS reflections (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES identity_users (id),
  journey_id TEXT NOT NULL REFERENCES journeys (id),
  quest_id TEXT,
  mission_id TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  submitted_at TIMESTAMPTZ,
  responses JSONB NOT NULL DEFAULT '[]'::jsonb,
  insights JSONB NOT NULL DEFAULT '[]'::jsonb,
  behavioral_evidence JSONB NOT NULL DEFAULT '[]'::jsonb,
  narrative_themes JSONB NOT NULL DEFAULT '[]'::jsonb,
  version INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reflections_journey_id ON reflections (journey_id);
CREATE INDEX IF NOT EXISTS idx_reflections_user_id ON reflections (user_id);
