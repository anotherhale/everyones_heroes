-- H.2 Platform Migration — foundational persistence
-- PostgreSQL is authoritative for Journey behavioral state and Reflections.

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS journeys (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  vision TEXT NOT NULL,
  current_chapter TEXT NOT NULL,
  active_quest_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  behavior_patterns JSONB NOT NULL DEFAULT '[]'::jsonb,
  version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journeys_user_id ON journeys(user_id);

CREATE TABLE IF NOT EXISTS reflections (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  journey_id TEXT NOT NULL REFERENCES journeys(id),
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

CREATE INDEX IF NOT EXISTS idx_reflections_journey_id ON reflections(journey_id);
CREATE INDEX IF NOT EXISTS idx_reflections_user_id ON reflections(user_id);

CREATE TABLE IF NOT EXISTS command_idempotency (
  idempotency_key TEXT NOT NULL,
  user_id TEXT NOT NULL,
  command_name TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_status INT NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (idempotency_key, user_id)
);

CREATE TABLE IF NOT EXISTS domain_event_log (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  aggregate_type TEXT NOT NULL,
  aggregate_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  correlation_id TEXT,
  causation_id TEXT,
  occurred_at TIMESTAMPTZ NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
