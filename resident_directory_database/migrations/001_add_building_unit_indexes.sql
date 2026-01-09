-- Idempotent patch: add building/unit columns and helpful indexes.
-- Safe to run multiple times on container start.
--
-- Notes:
-- - Uses IF NOT EXISTS guards for columns and indexes.
-- - Trigram index is created only if pg_trgm extension is available (or can be created).
-- - Does NOT modify existing data.

BEGIN;

-- ---------------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS residents
  ADD COLUMN IF NOT EXISTS building TEXT;

ALTER TABLE IF EXISTS residents
  ADD COLUMN IF NOT EXISTS unit TEXT;

-- ---------------------------------------------------------------------------
-- Basic btree indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_residents_building
  ON residents (building);

CREATE INDEX IF NOT EXISTS idx_residents_unit
  ON residents (unit);

-- ---------------------------------------------------------------------------
-- Optional: case-insensitive email lookups
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_residents_email_lower
  ON residents (lower(email));

-- ---------------------------------------------------------------------------
-- Optional: trigram index for faster ILIKE searches on full_name
-- - Try to create pg_trgm if possible.
-- - If extension isn't available (e.g., restricted env), skip gracefully.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  -- Create extension if it doesn't exist (safe/idempotent).
  -- If user lacks permission or extension isn't installed, catch and continue.
  BEGIN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS pg_trgm';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping pg_trgm extension creation due to insufficient privileges.';
    WHEN undefined_file THEN
      RAISE NOTICE 'Skipping pg_trgm extension creation because it is not available on this server.';
    WHEN OTHERS THEN
      RAISE NOTICE 'Skipping pg_trgm extension creation due to error: %', SQLERRM;
  END;

  -- Create trigram index only if the extension is now present.
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_residents_full_name_trgm ON residents USING gin (full_name gin_trgm_ops)';
  ELSE
    RAISE NOTICE 'pg_trgm not installed; skipping trigram index creation.';
  END IF;
END
$$;

COMMIT;
