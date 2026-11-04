# TEAM_WORKFLOW.md — Team Ownership, Collaboration & Git Workflow

**Version:** 0.1-draft · **Status:** Pending G0/G1 Approval · **Owner:** Om Rajput (Team Lead)

---

## 1. Module Ownership Matrix

The project is developed as a modular monorepo. Each developer owns their assigned directories. No developer or AI agent may write outside their permitted directories without prior agreement via a Change Request or Handoff note.

| Module | Primary Owner | Secondary / Supporting | Permitted Write Directories |
|---|---|---|---|
| **System Architecture & Governance** | Om | All | `AGENTS.md`, `README.md`, `docs/` |
| **Go Backend API & Data Layer** | Om | Soham (contract input) | `backend/`, `deploy/docker-compose.yml` |
| **Flutter Mobile Application** | Om | Lokesh (TFLite assets) | `mobile/` |
| **API & Database Contracts** | Om | Soham, Lokesh | `docs/architecture/API_CONTRACTS.md`, `docs/architecture/DATABASE_SCHEMA.md` (via G1 / CR) |
| **MobileNetV3 Model & Export** | Lokesh | Om (integration) | `ml/mobilenetv3/`, `ml/image_classifier/`, `ml/datasets/` |
| **XGBoost Risk Model & Data** | Lokesh | — | `ml/xgboost/`, `ml/outbreak_predictor/`, `ml/models/` |
| **FastAPI ML Inference Service** | Lokesh | Om (client integration) | `ml/ml-service/`, `ml/fastapi/`, `deploy/ml.Dockerfile`, `ml/requirements.txt` |
| **React Government Dashboard** | Soham | — | `dashboard/` |
| **Dashboard API Integration** | Soham | Om (API endpoints) | `dashboard/src/api/` |
| **DevOps & Packaging** | Om | Khushi (support if active) | `deploy/`, `deploy/docker-compose.yml`, root scripts |
| **Final System Integration** | Om | All | Coordination across all services |

### 1.1 Strict Boundary Rules
1. **Lokesh** writes model training code, export pipelines, evaluation logs, and the FastAPI inference server in `ml/`. Lokesh outputs the `.tflite` model, labels, and metadata into `ml/models/` and `ml/image_classifier/artifacts/`. Lokesh **never** writes directly into `mobile/`.
2. **Om** integrates the TFLite bundle by copying verified artifacts from `ml/` into `mobile/assets/ml/`.
3. **Soham** writes the React/TypeScript dashboard in `dashboard/`. Soham consumes the Go REST API according to `docs/architecture/API_CONTRACTS.md`. Soham **never** connects directly to PostgreSQL or the ML FastAPI service.
4. **Shared Contracts:** `docs/architecture/API_CONTRACTS.md`, `docs/architecture/DATABASE_SCHEMA.md`, and `docs/ai-ml/ML_INTEGRATION.md` can only be updated through the Change Request (CR) process (§6) and approved by Om + affected consumers.

---

## 2. Monorepo Structure

```
ha022/
├── README.md                   # Main entry point, architecture, setup & status
├── AGENTS.md                   # Global AI agent instructions & current phase
│
├── agents/                     # Agent-specific prompt instructions
│   ├── OM_AGENT.md
│   ├── LOKESH_AGENT.md
│   └── SOHAM_AGENT.md
│
├── docs/                       # Organised technical documentation & assets
│   ├── README.md               # Documentation index
│   ├── architecture/           # System design, API contracts, DB schema, ADRs
│   │   ├── ARCHITECTURE.md
│   │   ├── API_CONTRACTS.md
│   │   ├── DATABASE_SCHEMA.md
│   │   └── DECISIONS.md
│   ├── ai-ml/                  # TFLite & XGBoost integration, datasets, evaluation
│   │   ├── ML_INTEGRATION.md
│   │   ├── DATASETS.md
│   │   └── MODEL_EVALUATION.md
│   ├── development/            # Roadmap, coding standards, testing, workflow
│   │   ├── DEVELOPMENT_PLAN.md
│   │   ├── CODING_STANDARDS.md
│   │   ├── TESTING_STRATEGY.md
│   │   └── TEAM_WORKFLOW.md
│   ├── security/               # Auth, RBAC, PII protection & secret policies
│   │   └── SECURITY.md
│   ├── project/                # Domain context, PPT requirements & traceability
│   │   └── PROJECT_CONTEXT.md
│   ├── assets/                 # Application screenshots, diagrams & demo assets
│   │   ├── screenshots/
│   │   ├── diagrams/
│   │   └── demo/
│   ├── reviews/                # G1 contract & quality reviews
│   ├── handoffs/               # Inter-agent handoff notes
│   └── change-requests/        # Formal contract changes
│
├── backend/                    # Go REST API backend (Om)
│   ├── cmd/api/                # Main entrypoint
│   ├── internal/               # Core packages (auth, reports, map, outbreaks, etc.)
│   ├── migrations/             # SQL migration files
│   ├── go.mod
│   └── go.sum
│
├── mobile/                     # Flutter mobile application (Om)
│   ├── lib/                    # Dart source code (offline store, ui, tflite, qr)
│   ├── assets/ml/              # Bundled TFLite model, labels & manifest
│   └── pubspec.yaml
│
├── dashboard/                  # React + TypeScript government dashboard (Soham)
│   ├── src/                    # Components, pages, leaflet map, api client
│   ├── package.json
│   └── tsconfig.json
│
├── ml/                         # Machine learning workspace (Lokesh)
│   ├── mobilenetv3/            # MobileNetV3 training & evaluation scripts
│   ├── image_classifier/       # TFLite image classifier artifacts & test scripts
│   ├── xgboost/                # XGBoost outbreak risk training scripts
│   ├── outbreak_predictor/     # Outbreak risk schema & serialized models
│   ├── ml-service/             # FastAPI microservice exposing /api/v1/ml/outbreak-risk
│   ├── models/                 # Exported .tflite, .keras, and .json model bundles
│   ├── datasets/               # Dataset discovery & raw training data
│   ├── reports/                # Model evaluation logs
│   └── requirements.txt
│
└── deploy/                     # Infrastructure & orchestration (Om)
    ├── docker-compose.yml      # Local dev and demo compose orchestration
    ├── dashboard.Dockerfile    # React Vite container build
    ├── ml.Dockerfile           # FastAPI ML container build
    └── .env.example            # Environment template with placeholders
```

---

## 3. Development Gates (The Freeze Protocol)

To prevent the three developers and their AI agents from writing incompatible code against unverified assumptions, work proceeds through strict checkpoints:

```
[Phase 0: Initialization] 
          │
          ▼
   [Gate G0: Lead Approval of Foundation]
          │
          ▼
   [Contract Review Duty: docs/reviews/]
          │
          ▼
   [Gate G1: Contract Freeze (3 Sign-offs)]
          │ (CODING: UNLOCKED)
          ▼
   [P0 Execution: Feature Branches]
          │
          ▼
   [Gate G2: Core End-to-End Vertical Demo]
          │ (Farmer -> Screen -> Go -> Vet Confirm -> Dashboard Map)
          ▼
   [P1 Execution: Clusters, Alerts, QR, Health Records]
          │
          ▼
   [Gate G3: Final Integration & Rehearsal Freeze]
```

### Gate G0 — Initialization Approval
- Om inspects the foundational documents (`AGENTS.md` through `README.md` and `agents/*`).
- Confirms the technical stack, boundaries, and priorities.

### Gate G1 — Contract Freeze (Crucial Rule)
- While in `CODING: LOCKED`, no developer or AI agent writes application feature code.
- Each developer must review `API_CONTRACTS.md`, `DATABASE_SCHEMA.md`, and `ML_INTEGRATION.md` from the perspective of their module.
- Each agent outputs a review document:
  - `docs/reviews/om-contract-review.md`
  - `docs/reviews/lokesh-contract-review.md`
  - `docs/reviews/soham-contract-review.md`
- Following review triage, Om commits the finalized v1.0 contracts and flips `CODING: UNLOCKED` in `AGENTS.md`.

### Gate G2 — Core Vertical Demo Verification
- Verifies the golden thread:
  1. Farmer registers animal in Flutter.
  2. Farmer creates disease report with image & runs local MobileNetV3 screening.
  3. Report syncs to Go backend over REST.
  4. Vet logs into Dashboard, views submitted report, inspects image and screening result, and submits `confirmed` verification.
  5. Officer views confirmed case mapped on Leaflet map filtered by Satara/Phaltan.
- Once G2 is passed, P1 features (outbreaks, alerts, QR, notifications) can be merged.

### Gate G3 — Hackathon Rehearsal & Code Freeze
- 3 hours before presentation: all feature merges stop.
- Only P0 bug fixes allowed.
- Demo seed data loaded, offline mode rehearsed, presentation slides aligned.

---

## 4. Git Rules and Multi-Agent Branching

1. **`main` is protected:** No developer or AI agent may ever run `git push origin main` or commit directly to `main`.
2. **Dedicated feature branches:**
   - Om: `feature/om-mobile-backend`
   - Lokesh: `feature/lokesh-ml`
   - Soham: `feature/soham-dashboard`
3. **Small, incremental commits:** Commits must be focused and reference task IDs from `DEVELOPMENT_PLAN.md` (e.g., `feat(backend): implement POST /reports handler [O-06]`).
4. **Regular sync with `main`:** Before opening a PR or merging, rebase or merge `main` into your feature branch and verify tests pass.
5. **Never overwrite another developer's work:** Do not force-push (`--force`) to shared branches. Never resolve a merge conflict by deleting or blindly overwriting another developer's files.
6. **No secrets in Git:** Never commit `.env`, private keys, passwords, or service credentials. All secret configuration must use environment variables loaded from `.env.example`.

---

## 5. Pull Request (PR) Standard

Every integration into `main` must occur via a Pull Request. The PR description must adhere to this standard template:

```markdown
### PR Title: [TASK-ID] Short description of change

#### 1. Tasks Addressed
- Closes Task ID: `O-06` (from DEVELOPMENT_PLAN.md)

#### 2. Summary of Changes
- Implemented `POST /api/v1/reports` endpoint in Go Gin backend.
- Added validation for symptom codes and geographic coordinates.

#### 3. Contract Conformance
- [x] Conforms strictly to API_CONTRACTS.md v1.0
- [x] Conforms strictly to DATABASE_SCHEMA.md v1.0
- [ ] Required contract change (CR attached: `docs/change-requests/CR-001-...`)

#### 4. How Was It Tested? (Paste real command output)
```bash
$ go test -v ./internal/reports/...
=== RUN   TestCreateReport_Success
--- PASS: TestCreateReport_Success (0.02s)
PASS
ok      ha022/backend/internal/reports    0.035s
```

#### 5. Known Gaps / Assumptions
- Image attachment handled in separate endpoint `O-07`.
```

---

## 6. Change Request (CR) Protocol

If any developer discovers during implementation that an API endpoint, database column, or ML interface must change:

1. **Do not modify the contract or your code silently.**
2. Create a new markdown file in `docs/change-requests/CR-<number>-<short-slug>.md` using this format:

```markdown
# Change Request: CR-<number> <Title>
**Author:** <Name>
**Date:** YYYY-MM-DD
**Impacted Files:** `API_CONTRACTS.md`, `DATABASE_SCHEMA.md`, etc.
**Impacted Developers:** Om / Soham / Lokesh

### 1. Problem Description
What issue or blocker was encountered?

### 2. Proposed Change
Exact diff or proposed schema/contract adjustment.

### 3. Impact Assessment
How does this impact existing backend handlers, mobile sync, or dashboard components?

### 4. Approval
- [ ] Om Rajput (Lead Architect)
- [ ] Impacted Consumer 1 (Soham / Lokesh)
```

3. Only after required approvals are checked off does Om update the contract file, commit it, and notify the team.

---

## 7. Inter-Agent Communication Format

Because AI agents do not share live conversational context, all cross-agent handoffs, questions, and blocker reports must be written as persistent markdown files in `docs/handoffs/<yourname>-<date>-<n>.md`:

```markdown
# Handoff Note
**FROM:** Lokesh Agent
**TO:** Om Agent
**DATE:** 2026-11-03 16:30
**TASK ID:** L-04 (TFLite Export)

### Status
MobileNetV3 model exported to `ml/artifacts/mobilenetv3/mnv3s-2026.11.0/`.
Manifest, labels.json, and golden test images included.

### Verification Run
Golden test Python evaluation matched expected outputs.

### Action Required by Om
Copy `ml/artifacts/mobilenetv3/mnv3s-2026.11.0/` into `mobile/assets/ml/` and verify Flutter TFLite interpreter against golden image predictions.
```

---

## 8. Definition of Done (DoD)

A task is only marked `DONE` in `DEVELOPMENT_PLAN.md` when:
1. All acceptance criteria specified in `DEVELOPMENT_PLAN.md` are met.
2. Code adheres to `CODING_STANDARDS.md`.
3. Unit or integration tests have been executed with real output logged.
4. Product safety strings (AGENTS.md §9) are present in any user-facing UI or API outputs.
5. Code compiles and runs cleanly without breaking existing tests on `main`.
6. PR has been reviewed and merged into `main`.

