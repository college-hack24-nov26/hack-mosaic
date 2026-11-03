-- 000001_init_schema.up.sql
-- PashuVani PostgreSQL 16 + PostGIS 3 Schema (DATABASE_SCHEMA.md v1.0)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Enums
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('farmer', 'vet', 'officer', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE language_code AS ENUM ('en', 'hi', 'mr');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE location_level AS ENUM ('state', 'district', 'taluka', 'village');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE officer_level AS ENUM ('taluka', 'district', 'state');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE animal_sex AS ENUM ('male', 'female', 'unknown');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE report_status AS ENUM ('submitted', 'under_review', 'confirmed', 'rejected', 'flagged');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE verification_decision AS ENUM ('confirmed', 'rejected', 'flagged');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE location_source AS ENUM ('gps', 'village_centroid', 'manual');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE health_record_type AS ENUM ('checkup', 'illness', 'recovery', 'note');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE outbreak_status AS ENUM ('active', 'monitoring', 'resolved');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE alert_status AS ENUM ('draft', 'sent', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE notification_type AS ENUM ('report_verified', 'outbreak_alert', 'vaccination_due', 'system');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE risk_band AS ENUM ('low', 'medium', 'high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3.1 users
CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone               VARCHAR(20) NOT NULL UNIQUE,
    email               VARCHAR(255) UNIQUE,
    password_hash       TEXT NOT NULL,
    full_name           VARCHAR(120) NOT NULL,
    role                user_role NOT NULL,
    preferred_language  language_code NOT NULL DEFAULT 'mr',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    account_status      VARCHAR(32) NOT NULL DEFAULT 'active',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 locations
CREATE TABLE IF NOT EXISTS locations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES locations(id),
    level       location_level NOT NULL,
    code        VARCHAR(32) NOT NULL UNIQUE,
    name_en     VARCHAR(120) NOT NULL,
    name_hi     VARCHAR(120),
    name_mr     VARCHAR(120) NOT NULL,
    centroid    GEOGRAPHY(Point, 4326),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_locations_parent ON locations(parent_id);
CREATE INDEX IF NOT EXISTS idx_locations_level ON locations(level);
CREATE INDEX IF NOT EXISTS idx_locations_centroid ON locations USING GIST(centroid);

-- 3.3 farmers
CREATE TABLE IF NOT EXISTS farmers (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    village_id          UUID REFERENCES locations(id),
    taluka_id           UUID NOT NULL REFERENCES locations(id),
    district_id         UUID NOT NULL REFERENCES locations(id),
    home_location       GEOGRAPHY(Point, 4326),
    consent_alerts      BOOLEAN NOT NULL DEFAULT TRUE,
    consent_given_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farmers_taluka ON farmers(taluka_id);
CREATE INDEX IF NOT EXISTS idx_farmers_district ON farmers(district_id);
CREATE INDEX IF NOT EXISTS idx_farmers_home_location ON farmers USING GIST(home_location);

-- 3.4 veterinarians
CREATE TABLE IF NOT EXISTS veterinarians (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    registration_no     VARCHAR(64) NOT NULL UNIQUE,
    qualification       VARCHAR(120) NOT NULL DEFAULT 'B.V.Sc & A.H.',
    clinic_name         VARCHAR(160),
    address             TEXT,
    working_hours       VARCHAR(120) NOT NULL DEFAULT '9:00 AM – 5:00 PM',
    is_para_vet         BOOLEAN NOT NULL DEFAULT FALSE,
    district_id         UUID NOT NULL REFERENCES locations(id),
    taluka_id           UUID REFERENCES locations(id),
    clinic_location     GEOGRAPHY(Point, 4326),
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_veterinarians_district ON veterinarians(district_id);
CREATE INDEX IF NOT EXISTS idx_veterinarians_clinic_loc ON veterinarians USING GIST(clinic_location);

-- 3.5 officers
CREATE TABLE IF NOT EXISTS officers (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    designation         VARCHAR(120) NOT NULL,
    level               officer_level NOT NULL,
    scope_location_id   UUID NOT NULL REFERENCES locations(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.6 species & breeds
CREATE TABLE IF NOT EXISTS species (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(32) NOT NULL UNIQUE,
    name_en     VARCHAR(64) NOT NULL,
    name_hi     VARCHAR(64),
    name_mr     VARCHAR(64) NOT NULL
);

CREATE TABLE IF NOT EXISTS breeds (
    id          SERIAL PRIMARY KEY,
    species_id  SMALLINT NOT NULL REFERENCES species(id),
    code        VARCHAR(64) NOT NULL UNIQUE,
    name_en     VARCHAR(80) NOT NULL,
    name_hi     VARCHAR(80),
    name_mr     VARCHAR(80) NOT NULL
);

-- 3.7 animals
CREATE TABLE IF NOT EXISTS animals (
    id                  UUID PRIMARY KEY,
    farmer_user_id      UUID NOT NULL REFERENCES farmers(user_id),
    species_id          SMALLINT NOT NULL REFERENCES species(id),
    breed_id            INTEGER REFERENCES breeds(id),
    tag_number          VARCHAR(64),
    name                VARCHAR(80),
    sex                 animal_sex NOT NULL DEFAULT 'unknown',
    birth_date          DATE,
    approx_age_months   SMALLINT,
    photo_storage_key   TEXT,
    markings            TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    client_created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (farmer_user_id, tag_number)
);

CREATE INDEX IF NOT EXISTS idx_animals_farmer ON animals(farmer_user_id) WHERE is_active = TRUE;

-- 3.8 diseases & symptoms
CREATE TABLE IF NOT EXISTS diseases (
    id                      SMALLSERIAL PRIMARY KEY,
    code                    VARCHAR(48) NOT NULL UNIQUE,
    name_en                 VARCHAR(120) NOT NULL,
    name_hi                 VARCHAR(120),
    name_mr                 VARCHAR(120) NOT NULL,
    is_notifiable           BOOLEAN NOT NULL DEFAULT FALSE,
    is_outbreak_tracked     BOOLEAN NOT NULL DEFAULT FALSE,
    cluster_min_cases       SMALLINT NOT NULL DEFAULT 3,
    cluster_radius_m        INTEGER NOT NULL DEFAULT 5000,
    cluster_window_days     SMALLINT NOT NULL DEFAULT 14,
    precautions_en          TEXT,
    precautions_hi          TEXT,
    precautions_mr          TEXT
);

CREATE TABLE IF NOT EXISTS symptoms (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(48) NOT NULL UNIQUE,
    name_en     VARCHAR(120) NOT NULL,
    name_hi     VARCHAR(120),
    name_mr     VARCHAR(120) NOT NULL,
    category    VARCHAR(48) NOT NULL
);

-- 3.9 disease_reports
CREATE TABLE IF NOT EXISTS disease_reports (
    id                          UUID PRIMARY KEY,
    animal_id                   UUID NOT NULL REFERENCES animals(id),
    reporter_user_id            UUID NOT NULL REFERENCES farmers(user_id),
    reported_at                 TIMESTAMPTZ NOT NULL,
    received_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description                 TEXT,
    description_language        language_code NOT NULL DEFAULT 'mr',
    location                    GEOGRAPHY(Point, 4326) NOT NULL,
    location_source             location_source NOT NULL,
    location_accuracy_m         REAL,
    village_id                  UUID REFERENCES locations(id),
    taluka_id                   UUID NOT NULL REFERENCES locations(id),
    district_id                 UUID NOT NULL REFERENCES locations(id),
    screening_model_version     VARCHAR(48),
    screening_top_label         VARCHAR(48),
    screening_top_confidence    REAL CHECK (screening_top_confidence IS NULL OR (screening_top_confidence >= 0 AND screening_top_confidence <= 1)),
    screening_inconclusive      BOOLEAN,
    screening_scores            JSONB,
    screening_ran_at            TIMESTAMPTZ,
    status                      report_status NOT NULL DEFAULT 'submitted',
    claimed_by_vet_id           UUID REFERENCES veterinarians(user_id),
    claimed_at                  TIMESTAMPTZ,
    confirmed_disease_id        SMALLINT REFERENCES diseases(id),
    confirmed_at                TIMESTAMPTZ,
    expected_image_count        SMALLINT NOT NULL DEFAULT 0,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_status_district ON disease_reports(status, district_id, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_taluka_status ON disease_reports(taluka_id, status, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_animal ON disease_reports(animal_id, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON disease_reports(reporter_user_id, reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_confirmed_geo ON disease_reports USING GIST(location) WHERE status = 'confirmed';
CREATE INDEX IF NOT EXISTS idx_reports_confirmed_disease_time ON disease_reports(confirmed_disease_id, confirmed_at DESC) WHERE status = 'confirmed';

-- 3.10 report_symptoms & report_images
CREATE TABLE IF NOT EXISTS report_symptoms (
    report_id   UUID NOT NULL REFERENCES disease_reports(id) ON DELETE CASCADE,
    symptom_id  SMALLINT NOT NULL REFERENCES symptoms(id),
    PRIMARY KEY (report_id, symptom_id)
);

CREATE TABLE IF NOT EXISTS report_images (
    id              UUID PRIMARY KEY,
    report_id       UUID NOT NULL REFERENCES disease_reports(id) ON DELETE CASCADE,
    storage_key     TEXT NOT NULL UNIQUE,
    mime_type       VARCHAR(32) NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
    byte_size       INTEGER NOT NULL CHECK (byte_size > 0 AND byte_size <= 5242880),
    width_px        INTEGER,
    height_px       INTEGER,
    sha256_hex      CHAR(64) NOT NULL,
    captured_at     TIMESTAMPTZ,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_images_report ON report_images(report_id);

-- 3.11 vet_verifications
CREATE TABLE IF NOT EXISTS vet_verifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id       UUID NOT NULL REFERENCES disease_reports(id) ON DELETE CASCADE,
    vet_user_id     UUID NOT NULL REFERENCES veterinarians(user_id),
    decision        verification_decision NOT NULL,
    disease_id      SMALLINT REFERENCES diseases(id),
    notes           TEXT,
    visit_required  BOOLEAN NOT NULL DEFAULT FALSE,
    is_current      BOOLEAN NOT NULL DEFAULT TRUE,
    verified_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_confirmed_requires_disease
        CHECK (decision != 'confirmed' OR disease_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_vet_verifications_current
    ON vet_verifications(report_id) WHERE is_current = TRUE;
CREATE INDEX IF NOT EXISTS idx_vet_verifications_vet ON vet_verifications(vet_user_id, verified_at DESC);

-- 3.12 health_records, vaccination_records, treatments
CREATE TABLE IF NOT EXISTS health_records (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id           UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    recorded_by_user_id UUID NOT NULL REFERENCES users(id),
    source_report_id    UUID REFERENCES disease_reports(id),
    record_type         health_record_type NOT NULL,
    summary             TEXT NOT NULL,
    weight_kg           NUMERIC(6,2),
    temperature_c       NUMERIC(4,1),
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_records_animal ON health_records(animal_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS vaccination_records (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id               UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    disease_id              SMALLINT REFERENCES diseases(id),
    vaccine_name            VARCHAR(120) NOT NULL,
    batch_number            VARCHAR(64),
    dose_number             SMALLINT NOT NULL DEFAULT 1,
    administered_on         DATE NOT NULL,
    next_due_on             DATE,
    administered_by_user_id UUID REFERENCES users(id),
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vaccinations_animal ON vaccination_records(animal_id, administered_on DESC);
CREATE INDEX IF NOT EXISTS idx_vaccinations_due ON vaccination_records(next_due_on) WHERE next_due_on IS NOT NULL;

CREATE TABLE IF NOT EXISTS treatments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    animal_id               UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    report_id               UUID REFERENCES disease_reports(id),
    prescribed_by_vet_id    UUID NOT NULL REFERENCES veterinarians(user_id),
    medication_name         VARCHAR(120) NOT NULL,
    dosage                  VARCHAR(80) NOT NULL,
    duration_days           SMALLINT,
    instructions            TEXT,
    started_on              DATE NOT NULL,
    ended_on                DATE,
    outcome_notes           TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_treatments_animal ON treatments(animal_id, started_on DESC);

-- 3.13 outbreaks & outbreak_cases
CREATE TABLE IF NOT EXISTS outbreaks (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    disease_id          SMALLINT NOT NULL REFERENCES diseases(id),
    district_id         UUID NOT NULL REFERENCES locations(id),
    taluka_id           UUID REFERENCES locations(id),
    centroid            GEOGRAPHY(Point, 4326) NOT NULL,
    radius_m            INTEGER NOT NULL,
    confirmed_case_count INTEGER NOT NULL CHECK (confirmed_case_count >= 1),
    first_case_at       TIMESTAMPTZ NOT NULL,
    last_case_at        TIMESTAMPTZ NOT NULL,
    status              outbreak_status NOT NULL DEFAULT 'active',
    resolved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outbreaks_status_district ON outbreaks(status, district_id);
CREATE INDEX IF NOT EXISTS idx_outbreaks_centroid ON outbreaks USING GIST(centroid) WHERE status = 'active';

CREATE TABLE IF NOT EXISTS outbreak_cases (
    outbreak_id UUID NOT NULL REFERENCES outbreaks(id) ON DELETE CASCADE,
    report_id   UUID NOT NULL REFERENCES disease_reports(id) ON DELETE CASCADE,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (outbreak_id, report_id)
);

-- 3.14 alerts & notifications
CREATE TABLE IF NOT EXISTS alerts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outbreak_id         UUID NOT NULL REFERENCES outbreaks(id),
    approved_by_user_id UUID NOT NULL REFERENCES users(id),
    radius_m            INTEGER NOT NULL,
    title_en            VARCHAR(160) NOT NULL,
    title_hi            VARCHAR(160),
    title_mr            VARCHAR(160) NOT NULL,
    body_en             TEXT NOT NULL,
    body_hi             TEXT,
    body_mr             TEXT NOT NULL,
    status              alert_status NOT NULL DEFAULT 'draft',
    recipient_count     INTEGER NOT NULL DEFAULT 0,
    sent_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        notification_type NOT NULL,
    alert_id    UUID REFERENCES alerts(id),
    report_id   UUID REFERENCES disease_reports(id),
    title       VARCHAR(160) NOT NULL,
    body        TEXT NOT NULL,
    language    language_code NOT NULL,
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON notifications(user_id, created_at DESC) WHERE read_at IS NULL;

-- 3.15 risk_predictions
CREATE TABLE IF NOT EXISTS risk_predictions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id         UUID NOT NULL REFERENCES locations(id),
    disease_id          SMALLINT NOT NULL REFERENCES diseases(id),
    horizon_days        SMALLINT NOT NULL DEFAULT 14,
    risk_score          REAL NOT NULL CHECK (risk_score >= 0 AND risk_score <= 1),
    risk_band           risk_band NOT NULL,
    top_factors         JSONB NOT NULL,
    model_version       VARCHAR(48) NOT NULL,
    is_experimental     BOOLEAN NOT NULL DEFAULT TRUE CHECK (is_experimental = TRUE),
    computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_risk_predictions_lookup
    ON risk_predictions(district_id, disease_id, computed_at DESC);

-- 3.16 refresh_tokens & audit_logs
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  CHAR(64) NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id) WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    actor_user_id   UUID REFERENCES users(id),
    action          VARCHAR(64) NOT NULL,
    entity_type     VARCHAR(48) NOT NULL,
    entity_id       UUID,
    metadata        JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id, created_at DESC);

