-- PF.3 platform foundation schema.
-- Minimum persistence to prove PostgreSQL connectivity, migrations,
-- and Identity lite ownership. Domain aggregates migrate in later phases.

CREATE TABLE IF NOT EXISTS identity_users (
  id UUID PRIMARY KEY,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS identity_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES identity_users (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS identity_sessions_user_id_idx
  ON identity_sessions (user_id);

CREATE TABLE IF NOT EXISTS command_idempotency (
  idempotency_key TEXT PRIMARY KEY,
  user_id UUID,
  request_fingerprint TEXT NOT NULL,
  response_status INT NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
