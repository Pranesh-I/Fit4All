-- ============================================================
-- SAI Sports Talent Assessment - PostgreSQL Schema
-- Government of India / Sports Authority of India
-- 
-- Run with:
--   psql -U postgres -d sai_sports_db -f schema.sql
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search optimization

-- ============================================================
-- TABLE: users
-- Core athlete registration data
-- PRIVACY: face_embedding stores 512-d vector ONLY — no raw images
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name           VARCHAR(255)    NOT NULL,
    date_of_birth       DATE            NOT NULL,
    gender              VARCHAR(20)     NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    mobile_number       VARCHAR(15)     NOT NULL UNIQUE,
    password_hash       TEXT            NOT NULL,
    state               VARCHAR(100)    NOT NULL,
    district            VARCHAR(100)    NOT NULL,
    sport_interest      VARCHAR(100)    NOT NULL,
    height_cm           FLOAT           NOT NULL CHECK (height_cm BETWEEN 50 AND 300),
    weight_kg           FLOAT           NOT NULL CHECK (weight_kg BETWEEN 10 AND 500),
    face_embedding      FLOAT[]         NOT NULL,  -- 512-dimensional FaceNet vector
    is_phone_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Index on mobile_number for fast login lookup
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number);

-- Index for state/sport analytics queries
CREATE INDEX IF NOT EXISTS idx_users_state_sport ON users(state, sport_interest);

-- Constraint: embedding must be exactly 512 dimensions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_embedding_dimension'
          AND conrelid = 'users'::regclass
    ) THEN
        ALTER TABLE users ADD CONSTRAINT chk_embedding_dimension
            CHECK (array_length(face_embedding, 1) = 512);
    END IF;
END
$$;

COMMENT ON TABLE users IS 'Athlete registration records. Face embeddings (512-d) stored instead of images for privacy.';
COMMENT ON COLUMN users.face_embedding IS '512-dimensional FaceNet embedding vector. Raw images are never stored.';


-- ============================================================
-- TABLE: otp_verifications
-- Firebase OTP session tracking
-- ============================================================

CREATE TABLE IF NOT EXISTS otp_verifications (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    mobile_number   VARCHAR(15)     NOT NULL,
    otp_token       TEXT            NOT NULL,   -- Firebase ID token after verification
    verified        BOOLEAN         NOT NULL DEFAULT FALSE,
    purpose         VARCHAR(20)     NOT NULL DEFAULT 'register' 
                        CHECK (purpose IN ('register', 'login')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- TTL cleanup: index for finding expired sessions (older than 10 minutes)
CREATE INDEX IF NOT EXISTS idx_otp_mobile_purpose ON otp_verifications(mobile_number, purpose, verified);
CREATE INDEX IF NOT EXISTS idx_otp_created_at ON otp_verifications(created_at);

COMMENT ON TABLE otp_verifications IS 'Firebase OTP session tracking. Sessions expire after 10 minutes.';


-- ============================================================
-- TABLE: login_sessions
-- Active JWT session tracking per device
-- ============================================================

CREATE TABLE IF NOT EXISTS login_sessions (
    id          UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id   VARCHAR(255)    NOT NULL,
    jwt_token   TEXT            NOT NULL,
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ
);

-- Indexes for session management
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON login_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON login_sessions(user_id, is_active);

COMMENT ON TABLE login_sessions IS 'Active login sessions. One JWT per device per user.';


-- ============================================================
-- TABLE: test_sessions
-- Assessment sessions created by admin
-- ============================================================

CREATE TABLE IF NOT EXISTS test_sessions (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_name    VARCHAR(255)    NOT NULL,
    test_type       VARCHAR(50)     DEFAULT 'squat',
    start_date      DATE            NOT NULL,
    end_date        DATE            NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: squat_test_results
-- Stores squat exercise assessment results (Practice Mode)
-- ============================================================

CREATE TABLE IF NOT EXISTS squat_test_results (
    id                      SERIAL          PRIMARY KEY,
    test_id                 VARCHAR(36)     NOT NULL UNIQUE,
    user_id                 UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_reps              INTEGER         NOT NULL DEFAULT 0,
    correct_reps            INTEGER         NOT NULL DEFAULT 0,
    incorrect_reps          INTEGER         NOT NULL DEFAULT 0,
    accuracy                FLOAT           CHECK (accuracy BETWEEN 0 AND 100),
    duration_seconds        INTEGER         DEFAULT 0,
    pose_confidence_score   FLOAT           DEFAULT 0,
    recorded_at             TIMESTAMPTZ     NOT NULL,
    created_at              TIMESTAMPTZ     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_squat_results_user ON squat_test_results(user_id, recorded_at DESC);

-- ============================================================
-- TABLE: session_squat_results
-- Stores assessment results for specific sessions (Session Mode)
-- CONSTRAINT: One submission per athlete per session
-- ============================================================

CREATE TABLE IF NOT EXISTS session_squat_results (
    id                      SERIAL          PRIMARY KEY,
    session_id              UUID            NOT NULL REFERENCES test_sessions(id) ON DELETE CASCADE,
    test_id                 VARCHAR(36)     NOT NULL UNIQUE,
    user_id                 UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_reps              INTEGER         NOT NULL DEFAULT 0,
    correct_reps            INTEGER         NOT NULL DEFAULT 0,
    incorrect_reps          INTEGER         NOT NULL DEFAULT 0,
    accuracy                FLOAT           NOT NULL CHECK (accuracy BETWEEN 0 AND 100),
    duration_seconds        INTEGER         NOT NULL DEFAULT 0,
    pose_confidence_score   FLOAT           DEFAULT 0,
    recorded_at             TIMESTAMPTZ     NOT NULL,
    created_at              TIMESTAMPTZ     DEFAULT NOW(),
    UNIQUE(user_id, session_id)
);

CREATE INDEX IF NOT EXISTS idx_session_results_user ON session_squat_results(user_id, session_id);
