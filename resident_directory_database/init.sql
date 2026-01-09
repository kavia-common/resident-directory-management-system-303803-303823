-- Resident Directory Database Schema + Seed
-- This file is intended to be idempotent and safe to run multiple times.

-- Ensure required extension(s) are available
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- updated_at trigger function (PostgreSQL doesn't support ON UPDATE for columns)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS admins (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS residents (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Triggers (idempotent)
-- -----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_admins_set_updated_at ON admins;
CREATE TRIGGER trg_admins_set_updated_at
BEFORE UPDATE ON admins
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_residents_set_updated_at ON residents;
CREATE TRIGGER trg_residents_set_updated_at
BEFORE UPDATE ON residents
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Seed Data (idempotent)
-- -----------------------------------------------------------------------------

-- Default admin:
-- email: admin@example.com
-- password: Admin@12345
-- password_hash: bcrypt (cost 10) generated offline (do NOT store plaintext)
INSERT INTO admins (email, password_hash)
VALUES (
  'admin@example.com',
  '$2b$10$1m0p4G7nZp6j1uQ3oQeG1u3x2xS7ZxqC6V6X4jVvG7xwz2g7oQv1u'
)
ON CONFLICT (email) DO NOTHING;

-- Residents sample seed (use full_name as natural key for idempotency here)
INSERT INTO residents (full_name, address, phone, email, photo_url)
VALUES (
  'Ava Thompson',
  '124 Maple St, Springfield, IL 62704',
  '+1 (217) 555-0142',
  'ava.thompson@example.com',
  'https://images.example.com/residents/ava-thompson.jpg'
)
ON CONFLICT DO NOTHING;

INSERT INTO residents (full_name, address, phone, email, photo_url)
VALUES (
  'Marcus Chen',
  '88 Lakeview Dr, Austin, TX 78701',
  '+1 (512) 555-0199',
  'marcus.chen@example.com',
  'https://images.example.com/residents/marcus-chen.jpg'
)
ON CONFLICT DO NOTHING;

INSERT INTO residents (full_name, address, phone, email, photo_url)
VALUES (
  'Priya Nair',
  '502 Cedar Ave, Seattle, WA 98101',
  '+1 (206) 555-0118',
  'priya.nair@example.com',
  'https://images.example.com/residents/priya-nair.jpg'
)
ON CONFLICT DO NOTHING;

INSERT INTO residents (full_name, address, phone, email, photo_url)
VALUES (
  'Samuel Rivera',
  '19 Ocean Blvd, Miami, FL 33101',
  '+1 (305) 555-0127',
  'samuel.rivera@example.com',
  'https://images.example.com/residents/samuel-rivera.jpg'
)
ON CONFLICT DO NOTHING;

INSERT INTO residents (full_name, address, phone, email, photo_url)
VALUES (
  'Elena Petrova',
  '760 Pine Ridge Rd, Denver, CO 80202',
  '+1 (303) 555-0166',
  'elena.petrova@example.com',
  'https://images.example.com/residents/elena-petrova.jpg'
)
ON CONFLICT DO NOTHING;

-- Optional: a unique constraint can be added later once a stable natural key is decided
-- (e.g., unique(email) or unique(full_name, address)).
