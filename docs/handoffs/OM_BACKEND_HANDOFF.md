# OM_BACKEND_HANDOFF.md — Pashu Wani Go Backend MVP (`backend/` & `deploy/`)

**Author:** Om (Backend, Database, Mobile & DevOps Lead)  
**Branch:** `feature/om-go-backend`  
**Contract Version:** `API_CONTRACTS.md` v1.0 & `DATABASE_SCHEMA.md` v1.0 (Frozen)  
**Status:** Complete, Tested, and Verified End-to-End

---

## 1. Architecture & Directory Structure

The Pashu Wani backend is implemented in **Go (Gin + pgx/v5)** backed by **PostgreSQL 16 + PostGIS 3** with JWT RBAC authentication, Ed25519 QR health-record signing, multipart image magic-byte validation, and transactional outbreak clustering.

```
backend/
  cmd/
    server/
      main.go                 # HTTP server entrypoint, graceful shutdown, auto-migration
  internal/
    config/
      config.go               # Environment-driven configuration loader
    database/
      database.go             # PostgreSQL 16 + PostGIS pool & SQL migration runner
    handlers/
      health_handler.go       # GET /health, GET /healthz, GET /api/v1/healthz
      reference_handler.go    # Public locations, species, breeds, diseases, symptoms
      auth_handler.go         # Register, login, refresh, logout, /me
      animal_handler.go       # Animals CRUD, clinical records, vaccinations, treatments, QR
      report_handler.go       # Disease reports, multipart image upload & streaming
      vet_handler.go          # Vet claim, clinical verification, PostGIS nearby vets
      dashboard_handler.go    # Summary, timeseries, GeoJSON confirmed map, outbreaks, alerts
    middleware/
      middleware.go           # X-Request-Id, structured slog JSON logger, recovery, CORS
      auth.go                 # Bearer JWT validation & role/verified-vet RBAC guard
    models/
      models.go               # Canonical wire DTOs (Flutter + React Dashboard compatible)
    repositories/
      store.go                # Store interface & Haversine helper
      postgres_store.go       # PostgreSQL 16 + PostGIS implementation (pgx/v5)
      memory_store.go         # Deterministic seeded in-memory store for fast unit tests
    routes/
      routes.go               # Gin router registration
      routes_test.go          # End-to-end integration test suite
    services/
      auth_service.go         # bcrypt (cost 10), HS256 JWT, SHA-256 refresh tokens
    validators/
      validators.go           # E.164 phone normalization, UUID, WGS84 bounds, MIME magic bytes
  migrations/
    000001_init_schema.up.sql
    000001_init_schema.down.sql
    000002_seed_reference_and_demo.up.sql
    000002_seed_reference_and_demo.down.sql
  pkg/
    response/
      response.go             # Canonical JSON envelopes & error structures
  Dockerfile
  .env.example
  go.mod
  go.sum
deploy/
  docker-compose.yml          # PostgreSQL 16 + PostGIS 3.4 + Go Backend service stack
  .env.example
```

---

## 2. Implemented API Endpoints

### 2.1 Health & Public Reference Catalogs
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/health`, `/healthz`, `/api/v1/healthz` | Public | Application, PostgreSQL, and PostGIS health status |
| `GET` | `/api/v1/reference/locations` | Public | Hierarchical locations (`?level=state\|district\|taluka\|village&parent_id=...`) |
| `GET` | `/api/v1/reference/species` | Public | Livestock species catalog (`cattle`, `buffalo`, `goat`) |
| `GET` | `/api/v1/reference/breeds` | Public | Livestock breeds (`?species_code=cattle`) |
| `GET` | `/api/v1/reference/diseases` | Public | Surveillance & non-surveillance diseases with Marathi/Hindi/English precautions |
| `GET` | `/api/v1/reference/symptoms` | Public | Clinical symptom catalog |
| `GET` | `/api/v1/veterinarians/nearby` | Public / Auth | PostGIS `ST_DWithin` / `ST_Distance` query (`?lat=...&lng=...&radius_km=50`) returning **only verified active veterinarians** sorted by distance |

### 2.2 Authentication & Profile (`API_CONTRACTS.md` §3)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Public | Farmer self-registration (creates `users` + `farmers` in transaction; never creates vet/officer accounts) |
| `POST` | `/api/v1/auth/login` | Public | Authenticates by phone or email + password; returns `user`, `access_token`, `refresh_token`, `expires_in` |
| `POST` | `/api/v1/auth/refresh` | Public | Rotates single-use SHA-256 hashed refresh token |
| `POST` | `/api/v1/auth/logout` | Bearer JWT | Revokes refresh token (`204 No Content`) |
| `GET` | `/api/v1/me` (alias `/api/v1/auth/me`) | Bearer JWT | Returns authenticated user profile & role-specific sub-profile (`farmer`, `vet`, `officer`) |
| `PATCH` | `/api/v1/me` | Bearer JWT | Updates `full_name`, `preferred_language`, `village_id`, `consent_alerts` |

### 2.3 Animals & Clinical Records (`API_CONTRACTS.md` §5)
| Method | Endpoint | Roles | Description |
|---|---|---|---|
| `POST` | `/api/v1/animals` | `farmer` | Idempotent animal registration by client UUID (`201 Created` on first insert, `200 OK` on retry) |
| `GET` | `/api/v1/animals` | `farmer` | Paginated list of the authenticated farmer's active animals |
| `GET` | `/api/v1/animals/{id}` | `farmer`, `vet`, `officer`, `admin` | Single animal details (ownership enforced for farmers) |
| `PATCH` | `/api/v1/animals/{id}` | `farmer` | Updates animal name, tag number, markings, or active status |
| `GET` | `/api/v1/animals/{id}/record` | `farmer`, `vet`, `officer`, `admin` | Complete longitudinal clinical history (`animal`, `health_records`, `vaccinations`, `treatments`, `recent_reports`) |
| `GET` | `/api/v1/animals/{id}/qr-payload` | `farmer`, `vet`, `admin` | Ed25519-signed offline QR health snapshot |
| `POST` | `/api/v1/animals/{id}/health-records` | `farmer`, `vet`, `admin` | Adds clinical observation / checkup record |
| `POST` | `/api/v1/animals/{id}/vaccinations` | `farmer`, `vet`, `admin` | Logs vaccination dose and `next_due_on` date |
| `POST` | `/api/v1/animals/{id}/treatments` | `vet` (verified), `admin` | Prescribes clinical treatment linked to animal and optional report |

### 2.4 Disease Reports, Image Uploads & Veterinary Verification (`API_CONTRACTS.md` §6)
| Method | Endpoint | Roles | Description |
|---|---|---|---|
| `POST` | `/api/v1/reports` | `farmer` | Submits disease report (idempotent on UUID). Stores on-device MobileNetV3 screening with mandatory `"disclaimer": "preliminary_screening_not_a_diagnosis"` and always sets `status = "submitted"` |
| `POST` | `/api/v1/reports/{id}/images` | `farmer` | Multipart upload (`file`, optional `id`, `sha256_hex`). Enforces `<= 5 MB` and magic-byte validation (`image/jpeg`, `image/png`, `image/webp`) |
| `GET` | `/api/v1/reports` | `farmer`, `vet`, `officer`, `admin` | Role-scoped paginated report list (`?status=...&taluka_id=...&district_id=...&disease_code=...`) |
| `GET` | `/api/v1/reports/{id}` | `farmer`, `vet`, `officer`, `admin` | Full report details with embedded `animal`, `farmer`, `screening`, `images`, and current `verification` |
| `GET` | `/api/v1/reports/{id}/images/{image_id}` | `farmer`, `vet`, `officer`, `admin` | Streams stored report image with validated `Content-Type` |
| `POST` | `/api/v1/reports/{id}/claim` | `vet` (verified), `admin` | Claims report (`status = "under_review"`) within the vet's assigned district |
| `POST` | `/api/v1/reports/{id}/verifications` | `vet` (verified), `admin` | Transactional verification (`confirmed`, `rejected`, `flagged`). Updates `vet_verifications` (`is_current = TRUE`), `disease_reports.status`, `audit_logs`, farmer `notifications`, and runs PostGIS outbreak cluster check |

### 2.5 Government Surveillance Dashboard, Map, Outbreaks & Alerts (`API_CONTRACTS.md` §7–§8)
| Method | Endpoint | Roles | Description |
|---|---|---|---|
| `GET` | `/api/v1/dashboard/summary` (alias `/dashboard/stats`) | `vet`, `officer`, `admin` | Aggregated counts by status, confirmed cases by disease/taluka, and experimental district risk estimate (`"disclaimer": "Experimental estimate. Not a confirmed forecast."`) |
| `GET` | `/api/v1/dashboard/timeseries` | `vet`, `officer`, `admin` | Daily confirmed vs reported case counts |
| `GET` | `/api/v1/map/cases` | `farmer`, `vet`, `officer`, `admin` | **GeoJSON `FeatureCollection`** of **veterinarian-confirmed cases only** (`[lng, lat]`) |
| `GET` | `/api/v1/dashboard/map-data` | `vet`, `officer`, `admin` | Flat array of confirmed case pins for the React Government Dashboard |
| `GET` | `/api/v1/outbreaks` (alias `/dashboard/clusters`) | `farmer`, `vet`, `officer`, `admin` | Active/monitoring/resolved outbreak clusters derived solely from confirmed cases |
| `GET` | `/api/v1/outbreaks/{id}` | `farmer`, `vet`, `officer`, `admin` | Outbreak cluster detail with constituent confirmed report IDs |
| `PATCH` | `/api/v1/outbreaks/{id}` | `officer`, `admin` | Updates outbreak status (`active`, `monitoring`, `resolved`) |
| `POST` | `/api/v1/outbreaks/recompute` | `officer`, `admin` | Recomputes active outbreak clusters |
| `GET` | `/api/v1/alerts` | `farmer`, `vet`, `officer`, `admin` | Lists officer-approved regional alerts |
| `POST` | `/api/v1/alerts` | `officer`, `admin` | Creates an alert linked to an outbreak cluster |
| `POST` | `/api/v1/alerts/{id}/send` | `officer`, `admin` | Sends alert and fans out notifications via PostGIS `ST_DWithin` to consenting farmers |
| `GET` | `/api/v1/notifications` | All authenticated | Lists user notifications |
| `POST` | `/api/v1/notifications/{id}/read` | All authenticated | Marks a notification as read (`204 No Content`) |

---

## 3. Seeded Synthetic Demo Accounts (`000002_seed_reference_and_demo.up.sql`)

All seeded accounts are clearly marked as synthetic demonstration data and use password **`Pashu@2026`**:

| Role | Name | Phone | Email | Status / Scope |
|---|---|---|---|---|
| **Farmer** | Ramesh Jadhav (SYNTHETIC DEMO) | `+919876543210` | `ramesh.jadhav@demo.pashuvani.in` | Active — Phaltan Rural, Satara |
| **Farmer** | Anil Shinde (SYNTHETIC DEMO) | `+919822334455` | `anil.shinde@demo.pashuvani.in` | Active — Barad, Phaltan, Satara |
| **Farmer** | Suresh Bhosale (SYNTHETIC DEMO) | `+919833445566` | `suresh.bhosale@demo.pashuvani.in` | Active — Tadawale, Phaltan, Satara |
| **Verified Vet** | Dr. Rajesh Kulkarni | `+919890112233` | `dr.kulkarni@mahavet.gov.in` | `is_verified = true` — Satara District (`SVC-MH-2019-4482`) |
| **Verified Vet** | Dr. Snehal Deshmukh | `+919890223344` | `dr.deshmukh@mahavet.gov.in` | `is_verified = true` — Satara District (`SVC-MH-2021-5190`) |
| **Unverified Vet** | Dr. Vikram Pawar | `+919890334455` | `dr.pawar@mahavet.gov.in` | `is_verified = false` (`pending_verification`) — Blocked from verifying reports (`403 VET_NOT_VERIFIED`) |
| **District Officer** | Dr. Mahesh Patil | `+919890445566` | `dahdo.satara@maharashtra.gov.in` | Satara District Surveillance Officer |
| **State Admin** | State Surveillance Admin | `+919890556677` | `admin@pashuvani.gov.in` | Statewide Admin |

### Seeded Location UUIDs (for Registration & Filtering)
- **State (Maharashtra):** `11111111-1111-4111-8111-111111111101`
- **District (Satara):** `11111111-1111-4111-8111-111111111201`
- **Taluka (Phaltan):** `11111111-1111-4111-8111-111111111301`
- **Villages (Phaltan):**
  - Phaltan Rural: `11111111-1111-4111-8111-111111111401`
  - Barad: `11111111-1111-4111-8111-111111111402`
  - Tadawale: `11111111-1111-4111-8111-111111111403`

---

## 4. Running the Backend & PostgreSQL/PostGIS

### Option A: Docker Compose (Recommended Full Stack)
```bash
cd deploy
cp .env.example .env
docker compose up --build -d
```
- PostgreSQL 16 + PostGIS 3.4 listens on `localhost:5432`.
- Go Backend listens on `http://localhost:8080` and automatically applies `000001_init_schema.up.sql` and `000002_seed_reference_and_demo.up.sql` on startup.

### Option B: Local Go Execution
```bash
cd backend
cp .env.example .env
go run ./cmd/server
```
- Connects to PostgreSQL at `DB_HOST:DB_PORT` when running; in `ENV=development`, if PostgreSQL is not running locally, it automatically boots with the seeded in-memory spatial store so Flutter and Dashboard integration never block.

### Flutter & React Dashboard Connection
- **Android Emulator (`mobile/`):** Automatically uses `http://10.0.2.2:8080/api/v1`.
- **Physical Android Device over USB:** Run `adb reverse tcp:8080 tcp:8080` and pass `--dart-define=API_BASE_URL=http://localhost:8080/api/v1`.
- **React Government Dashboard (`dashboard/`):** Uses `VITE_API_BASE_URL=http://localhost:8080/api/v1` (CORS is pre-configured for `http://localhost:5173` and `http://localhost:3000`).
