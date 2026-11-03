# DEVELOPMENT_PLAN.md — Prioritised Hackathon Implementation Roadmap

**Version:** 0.1-draft · **Status:** Pending G0/G1 Approval · **Owner:** Om Rajput (Team Lead)

---

## 1. Hackathon Execution Overview & Priorities

This 24-hour development plan is strictly divided into three tiers:

- **P0 (Golden Thread — Hours 0 to 12):** Must-have core end-to-end functionality.
  `Farmer creates animal` ➔ `Farmer captures photo & symptoms` ➔ `On-device MobileNetV3 screening` ➔ `Sync to Go Backend` ➔ `Vet verifies case in Dashboard` ➔ `Confirmed case displayed on Leaflet Map with Taluka filter`.
- **P1 (Surveillance & Intervention — Hours 12 to 18):** High-value supporting features.
  `PostGIS Outbreak Clustering` ➔ `Officer-approved Alerts` ➔ `In-app farmer notification banner` ➔ `QR animal health record snapshot` ➔ `Vet treatments/vaccinations`.
- **P2 (Exploratory & Advanced — Hours 18 to 22):** Stretch goals if time permits.
  `XGBoost District Risk Service` ➔ `Gemini LLM assistance via Go` ➔ `Marathi voice input` ➔ `FCM Push & Metrics`.
- **Hours 22 to 24:** System Freeze (Gate G3), demo data verification, and rehearsal.

---

## 2. P0 Tasks — Core Golden Thread

### Om (Go Backend, Flutter, Architecture)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **O-01** | Backend Scaffolding & Config | G1 Freeze | `backend/` initialized with Gin, router, config loading from env, logger. | Server starts on `:8080`, responds `200` to `GET /healthz`. | Base for all endpoints. |
| **O-02** | Database Migrations & PostGIS Setup | O-01 | SQL migrations in `backend/migrations/` for P0 tables. | Tables `users`, `locations`, `farmers`, `veterinarians`, `officers`, `species`, `breeds`, `animals`, `diseases`, `symptoms`, `disease_reports`, `report_symptoms`, `report_images`, `vet_verifications`, `refresh_tokens`. | Validated on PostgreSQL 16 + PostGIS. |
| **O-03** | Auth & Identity Endpoints | O-02 | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /me`. | Farmer registration works; JWT issued with 60m expiry; password hashed; role & district scope enforced. | Consumed by Flutter and Dashboard. |
| **O-04** | Reference Data & Seed Fixtures | O-02 | Seed script for Satara district, Phaltan taluka, cattle/buffalo, diseases, symptoms, demo users. | `GET /reference/*` endpoints return seeded catalogs with multilang fields. | Cachable by Flutter & Dashboard. |
| **O-05** | Animals API | O-03, O-04 | `POST /animals`, `GET /animals`, `GET /animals/{id}`. | Supports client UUID generation (idempotent); farmer-scoped; validates breed belongs to species. | Flutter syncs animals here. |
| **O-06** | Disease Reports Submission API | O-05 | `POST /reports`, `GET /reports`, `GET /reports/{id}`. | Accepts report with client UUID; validates symptoms; attaches screening observations; sets status to `submitted`. | Heart of report intake. |
| **O-07** | Image Storage & Upload API | O-06 | `POST /reports/{id}/images`, `GET /reports/{id}/images/{img_id}`. | Saves files to local volume; checks mime type, size ≤ 5MB; returns 201 with access URL. | Safe multipart upload. |
| **O-08** | Vet Verification & Map API | O-06, O-07 | `POST /reports/{id}/verifications`, `GET /map/cases`, `GET /dashboard/summary`. | Vet can submit `confirmed`, `rejected`, or `flagged`. `GET /map/cases` returns ONLY confirmed cases as GeoJSON. | Feeds Soham's Dashboard. |
| **O-09** | Flutter Scaffolding & Multilingual Theme | G1 Freeze | `mobile/` Flutter app with Material 3, provider/bloc state, Marathi & English support. | Clean UI, language switcher between Marathi and English; accessible touch targets. | Base for farmer client. |
| **O-10** | Offline Database & Outbox Engine | O-09 | Drift/SQLite local DB with tables for animals, reports, images, and outbox queue. | Works with zero network; operations queued with retry states (`pending`, `syncing`, `done`, `failed`). | Offline-first invariant. |
| **O-11** | Farmer Animal & Report UI | O-10 | Farmer screens: add animal, list animals, create report with photo capture, symptom checklist, and GPS. | UI guides farmer; works offline; auto-triggers outbox sync when network returns. | Primary user touchpoint. |
| **O-12** | Flutter TFLite Screening Integration | L-04, O-11 | Integrated TFLite interpreter loading model from `mobile/assets/ml/`. | Runs inference in isolate; displays mandatory disclaimer: *"Preliminary check from your phone, not a diagnosis"*. | Tested against golden images. |
| **O-13** | End-to-End P0 Integration Test | O-08, O-12, S-05 | Complete workflow verified from Flutter photo to Dashboard map point. | Report syncs, vet confirms, case appears instantly on Leaflet map. | **Gate G2 Checkpoint**. |

---

### Lokesh (Machine Learning)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **L-01** | Dataset Discovery & Discovery Notes | G1 Freeze | `ml/datasets/DATASETS.md` documenting discovered cattle disease image datasets & licences. | Clear provenance, sample counts per class, licence, no fabricated datasets. | Feasibility checkpoint. |
| **L-02** | MobileNetV3 Training & Validation | L-01 | Python training script in `ml/mobilenet/`, training MobileNetV3-Small. | Stratified split; evaluates precision, recall, F1 per class; logs honest confusion matrix in `EVALUATION.md`. | Target: LSD + baseline classes. |
| **L-03** | TFLite Quantization & Validation | L-02 | Export pipeline producing `model.tflite` (float32 / float16). | TFLite output matches Keras model within tolerance; model size ≤ 10MB; latency measured. | Ensures low mobile footprint. |
| **L-04** | Artifact Bundle & Golden Test Suite | L-03 | `ml/artifacts/mobilenetv3/mnv3s-2026.11.0/` bundle with `model.tflite`, `labels.json`, `manifest.json`, and 5 `golden/` test images. | Golden test predictions recorded in `expected.json`; handoff note drafted to Om. | Handoff to Task O-12. |

---

### Soham (Dashboard & Web UI)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **S-01** | Dashboard Scaffolding & Setup | G1 Freeze | React + TypeScript + Vite + Tailwind CSS dashboard scaffolded. | Clean layout with routing, auth context, responsive design, dark/light theme support. | Base for officer & vet UI. |
| **S-02** | API Client & Auth Integration | S-01, O-03 | Typed API client conforming to `API_CONTRACTS.md`; login page for vets and officers. | Stores JWT; handles token refresh and `401` redirections; role-aware navigation. | Uses shared contract definitions. |
| **S-03** | Vet Verification Inbox | S-02, O-06 | List of submitted reports filtered by vet's assigned district. | Displays farmer description, symptoms, photo gallery, and preliminary screening disclaimer. | Core vet workflow. |
| **S-04** | Vet Decision Actions | S-03, O-08 | Action controls to `confirm`, `reject`, or `flag` with notes and visit requirement. | Calls `POST /reports/{id}/verifications`; updates status immediately; requires notes on rejection. | Core medical decision point. |
| **S-05** | Geographic Case Map (Leaflet) | S-02, O-08 | Interactive Leaflet map displaying GeoJSON confirmed cases. | Filters by District and Taluka; custom markers by disease; cluster groups; no farmer PII leaked. | **Gate G2 Checkpoint**. |

---

## 3. P1 Tasks — Surveillance, Alerts, QR Records & History

### Om (Backend & Mobile)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **O-14** | PostGIS Outbreak Clustering Engine | O-08 | DBSCAN background job in Go executing `ST_ClusterDBSCAN` over confirmed cases. | Flags clusters with ≥ 3 cases within 5km in 14 days; persists to `outbreaks` and `outbreak_cases`. | Feeds officer surveillance. |
| **O-15** | Alert Generation & Notification Logic | O-14 | Endpoints `POST /alerts`, `POST /alerts/{id}/send`, `GET /notifications`. | Spatial query (`ST_DWithin`) finds consenting farmers within radius; generates in-app notifications. | Human-in-the-loop alert delivery. |
| **O-16** | QR Code Animal Record & Verification | O-05 | Ed25519-signed QR payload generator in Go; QR generator and scanner in Flutter. | Farmer shows signed QR; vet reads offline; displays `snapshot_at` date to warn of staleness. | Satisfies PPT R-13, R-26. |
| **O-17** | Animal Health Records & Treatments | O-05 | Endpoints and mobile UI for vaccination records and treatment history. | CRUD for health records, vaccinations, and vet treatments per animal. | Clinical continuity of care. |
| **O-18** | In-App Farmer Notification UI | O-15, O-11 | Notification tray in Flutter showing outbreak warnings and report status updates. | Farmer sees clear warning banner based on confirmed cases nearby with advice. | Alert delivery to farmer. |
| **O-19** | Docker Compose Packaging | O-08, S-05 | Root `docker-compose.yml` orchestrating Postgres, PostGIS, Go API, and static dashboard. | Single command `docker compose up` spins up full stack reliably for demonstration. | Prepares for deployment. |

---

### Soham (Dashboard)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **S-06** | Dashboard Analytics & Trends | S-05, O-08 | Summary stat cards and timeseries charts (`/dashboard/summary`, `/dashboard/timeseries`). | Shows totals (reports, pending, confirmed, active outbreaks); trends over time. | Officer intelligence. |
| **S-07** | Outbreak Surveillance & Cluster View | S-05, O-14 | Dashboard page listing detected outbreak clusters with map visualization. | Officer can inspect member cases of a cluster and promote status from `suspected` to `active`. | Disease monitoring. |
| **S-08** | Officer Alert Dispatch Interface | S-07, O-15 | UI for drafting, customizing radius (0.5 to 25 km), and approving alerts. | Calls `POST /alerts` and `POST /alerts/{id}/send`; shows estimated recipient count. | False-alarm prevention. |
| **S-09** | Multilingual Support (Hindi & Marathi) | S-01 | UI localization toggle supporting English, Marathi, and Hindi for dashboard. | All static UI labels translated; clean font rendering for Devanagari. | Government officer UX. |

---

## 4. P2 Tasks — Exploratory ML, LLM Assistance & Stretch Goals

### Lokesh (ML Exploration)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **L-05** | XGBoost Historical Data Discovery | L-01 | Document `ml/xgboost/FEATURES.md` with district-level livestock/weather/case data. | **Go/No-Go Decision at H+8**: If no valid data source found, stop cleanly and document limitations. | Avoids data fabrication. |
| **L-06** | XGBoost Outbreak Risk Model | L-05 | Training script and model artifacts evaluating district risk estimation. | Strict temporal split; baseline comparison; metrics documented in `EVALUATION.md`. | District-level only. |
| **L-07** | FastAPI Risk Prediction Service | L-06 | Python FastAPI service running in Docker exposing `POST /v1/risk/predict`. | Conforms to `API_CONTRACTS.md` §12; validates via Pydantic; handles missing features. | Go backend client consumes. |

---

### Om & Soham (Stretch Integrations)

| Task ID | Task Name | Dependencies | Expected Output | Acceptance Criteria | Integration Notes |
|---|---|---|---|---|---|
| **O-20** | Go Backend ML Client for Risk | L-07, O-08 | Internal Go HTTP client calling FastAPI service; persists to `risk_predictions`. | 5s timeout; circuit breaker; graceful degradation if ML service is down. | Feeds S-10. |
| **S-10** | Dashboard District Risk Panel | O-20, S-06 | Risk heat panel showing district risk score and band. | Displays prominent disclaimer: *"Experimental estimate. Not a confirmed forecast."* | Consumes `GET /risk/districts`. |
| **O-21** | Gemini LLM Hub Assistant | O-06 | Go integration with Gemini API for symptom text summarization or advice. | Informational only; prompt strictly forbids generating diagnoses; disclaimers added. | Controlled backend proxy. |
| **O-22** | Marathi Voice-to-Text Input | O-11 | Speech-to-text input component in Flutter report flow. | Fallback to text always available; handles audio transcription gracefully. | PPT R-03 fulfillment. |

---

## 5. Timeline Schedule (24-Hour Hackathon Breakdown)

```
HOUR 00:00 — 02:00: Foundation & Gate G1
├── Om, Lokesh, Soham read documentation & conduct G1 Contract Review
├── Om reviews & signs off on reviews in docs/reviews/
└── Gate G1 passed: CODING UNLOCKED

HOUR 02:00 — 08:00: P0 Core Construction
├── Om: Go backend scaffolding, migrations, auth, and report APIs (O-01 to O-07)
├── Om: Flutter offline database and report creation UI (O-09 to O-11)
├── Lokesh: Dataset verification and MobileNetV3 training/eval (L-01 to L-03)
└── Soham: Dashboard setup, auth client, vet review inbox (S-01 to S-04)

HOUR 08:00 — 12:00: P0 Golden Thread Integration & Gate G2
├── Lokesh exports TFLite bundle; Om integrates into Flutter (L-04, O-12)
├── Soham implements Leaflet confirmed case map (S-05)
└── Gate G2 Verification: End-to-end flow verified and signed off

HOUR 12:00 — 18:00: P1 Surveillance & Mobile Completion
├── Om: PostGIS DBSCAN clustering & alert dispatch logic (O-14, O-15)
├── Om: QR health record snapshot generation & verification (O-16, O-17)
├── Soham: Cluster view, alert drafting UI, analytics charts (S-06 to S-08)
└── Lokesh: XGBoost data discovery & go/no-go evaluation (L-05)

HOUR 18:00 — 21:00: P2 Polish & Docker Orchestration
├── Om & Soham: Docker Compose end-to-end packaging (O-19)
├── Lokesh: FastAPI risk service (if go/no-go passed) or eval documentation
└── Stretch items: UI localization polish, safety string verification

HOUR 21:00 — 24:00: Gate G3 Code Freeze & Presentation Prep
├── Complete code freeze: no new features
├── Load synthetic demo fixtures for Satara & Phaltan
├── Rehearse offline-to-online demo script
└── Presentation alignment with project PPT
```

