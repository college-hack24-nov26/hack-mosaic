# agents/OM_AGENT.md — Dedicated Instructions for Om's AI Coding Agent

**Role:** Team Leader, Principal Architect, Go Backend & Flutter Mobile Engineer  
**Developer:** Om Rajput  
**Primary Assigned Modules:** System Architecture, Go Backend API, Database Migrations, Flutter Mobile App, TFLite Integration, Final System Integration

---

## 1. Responsibilities & Assigned Scope

You represent Om, the team leader and primary full-stack / mobile developer. You are responsible for:
1. Orchestrating the project architecture and serving as the final approver for Gates G0, G1, G2, and G3.
2. Building the Go backend (`backend/`) using Gin, `pgx/v5`, JWT authentication, and PostGIS spatial queries.
3. Establishing PostgreSQL migrations (`backend/migrations/`) strictly conforming to `DATABASE_SCHEMA.md`.
4. Implementing the Flutter mobile application (`mobile/`) with offline-first local storage (Drift/SQLite) and outbox synchronization.
5. Integrating the MobileNetV3 TensorFlow Lite model bundle delivered by Lokesh into Flutter (`mobile/assets/ml/`).
6. Coordinating end-to-end integration and running the Gate G2 verification scenario.

---

## 2. Permitted & Restricted Directories

### Permitted Write Directories:
- `backend/` — Entire Go backend codebase.
- `mobile/` — Entire Flutter mobile codebase.
- `deploy/` — Docker Compose, Dockerfiles, `.env.example`.
- `docs/reviews/om-contract-review.md` — Gate G1 review.
- `docs/handoffs/` — Inter-agent handoffs.
- Root documentation files (`AGENTS.md`, `DECISIONS.md`, `API_CONTRACTS.md`, `DATABASE_SCHEMA.md`) when executing approved architectural changes or gate transitions.

### Strictly Restricted Directories (READ-ONLY to Om):
- `dashboard/` — Owned exclusively by Soham. Do not modify React or TypeScript files.
- `ml/` (except `ml/artifacts/` read-only) — Owned exclusively by Lokesh. Do not modify Python ML scripts or FastAPI services directly.

---

## 3. Current Phase Rule (Gate G1 First)

You must check `AGENTS.md` §0 before writing any code:
- If `CODING: LOCKED`, you **must not** generate Go handlers, Flutter screens, or SQL migrations.
- Your immediate duty during Phase 0 is to conduct the G1 contract review and write `docs/reviews/om-contract-review.md`.
- Once Soham and Lokesh have submitted their reviews and all blockers are resolved, you commit the frozen contracts and update `AGENTS.md` to `CODING: UNLOCKED`.

---

## 4. Interfaces & Dependencies

1. **Go API Endpoints:** Must strictly implement the paths, verbs, request bodies, and error formats specified in `API_CONTRACTS.md`.
2. **Database Engine:** PostgreSQL 16 + PostGIS. Use parameterized queries only. Never use string concatenation.
3. **Mobile Outbox:** Every write in Flutter must record a local transaction in SQLite before attempting REST synchronization. Client-generated UUIDs ensure idempotent retries.
4. **TFLite Bundle Ingestion:** Ingest `model.tflite`, `labels.json`, and `manifest.json` from `ml/artifacts/mobilenetv3/<version>/` into `mobile/assets/ml/`. Run inference in a background isolate. Compare against `expected.json` golden tests.

---

## 5. Mandatory Safety & Product Strings

In all Flutter screening screens and backend error/disclaimer responses, you must strictly include:
- Screen disclaimer: *"This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report."* (and Marathi/Hindi translations).
- Alert delivery: Alerts must explicitly note that they are based on **veterinarian-confirmed** cases.

---

## 6. Git & Branching Rules

- Feature branch: `feature/om-mobile-backend`.
- Never commit or push directly to `main`.
- Each commit must reference a task ID from `DEVELOPMENT_PLAN.md` (e.g. `feat(backend): implement auth registration [O-03]`).
- Open PRs against `main` using the PR template defined in `TEAM_WORKFLOW.md` §5. Always include real test command outputs.

---

## 7. Inter-Agent Communication

- To request a change or report a blocker to Soham or Lokesh, create a durable note in `docs/handoffs/om-<date>-<n>.md`.
- When updating contracts, create a formal Change Request in `docs/change-requests/CR-<nnn>-<slug>.md` and obtain the affected developer's sign-off before modifying `API_CONTRACTS.md` or `DATABASE_SCHEMA.md`.

