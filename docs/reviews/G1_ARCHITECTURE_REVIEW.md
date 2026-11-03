# docs/reviews/G1_ARCHITECTURE_REVIEW.md — Master Architecture & Contract Audit

**Gate:** G1 (Architecture & Contract Freeze)  
**Lead Auditor:** Principal Software Architect & Engineering Lead  
**Participants:** Om Rajput (Lead / Mobile & Backend), Lokesh Patil (ML), Soham Pawar (Dashboard)  
**Date:** 2026-11-03  
**Status:** **AUDIT COMPLETE — PENDING OM'S G1 SIGN-OFF**

---

## 1. Executive Summary

This architecture and contract review verifies the technical foundation of PashuVani across all 18 foundational artifacts. The audit evaluated:
1. Requirements traceability from the project presentation (`coepphaltan.pdf`).
2. Consistency between `DATABASE_SCHEMA.md`, `API_CONTRACTS.md`, and `ML_INTEGRATION.md`.
3. Independent developer lane clarity (`agents/*` and `TEAM_WORKFLOW.md`).
4. Offline synchronization robustness and PostGIS geospatial correctness.
5. Feasibility of execution within the 24-hour hackathon timeframe.

**Audit Verdict:** The architecture is exceptionally sound, modular, and defensible. Two **BLOCKERS** and four **HIGH**-priority contract/workflow refinements were detected during the cross-module audit. Resolving these issues immediately will prevent breaking changes during parallel implementation.

---

## 2. Comprehensive Consistency Audit Findings

Every issue has been classified by severity: **BLOCKER**, **HIGH**, **MEDIUM**, or **LOW**.

| Issue ID | Severity | Affected Document | Exact Issue | Proposed Correction | Responsible Developer |
|---|---|---|---|---|---|
| **ISSUE-01** | **BLOCKER** | `API_CONTRACTS.md` §2, §4 | Reference catalog endpoints (`GET /reference/*`) are marked as requiring authentication (`Auth: any`). A new farmer registering via `POST /auth/register` must supply a valid `village_id` during registration, but cannot retrieve locations while unauthenticated. | Change all `GET /reference/*` endpoints to **public** access. Update `API_CONTRACTS.md` and router definitions. | Om |
| **ISSUE-02** | **BLOCKER** | `ML_INTEGRATION.md` §2.5, §2.9; `DEVELOPMENT_PLAN.md` L-01 | PPT Slide 7 notes that field photograph data is to be collected in Months 1–2; no labelled dataset exists in the repo. If public datasets (Kaggle/Mendeley) are inaccessible, Lokesh's agent could stall or hallucinate training numbers. | Enforce explicit **Anti-Hallucination & Fallback Protocol**: If public sample counts are insufficient (<50/class) at H+4, Lokesh delivers an architectural mock TFLite bundle with valid tensor shapes (`[1, 224, 224, 3]` -> `[1, N]`) and documents it as a pipeline placeholder. | Lokesh |
| **ISSUE-03** | **HIGH** | `API_CONTRACTS.md` §6.1, §6.2; `DATABASE_SCHEMA.md` §4.10 | Decoupled report submission (`POST /reports`) and image upload (`POST /reports/{id}/images`) means network interruptions can leave a report in Postgres with 0 images, confusing veterinarians in the inbox. | Add optional `expected_image_count` to `POST /reports` and `images_pending: boolean` to `Report` responses. In Dashboard inbox (`S-03`), display an amber tag: *"Photos syncing from field..."* | Om & Soham |
| **ISSUE-04** | **HIGH** | `DEVELOPMENT_PLAN.md` §2; `DECISIONS.md` D-03 | Om carries an extreme workload (Go API, PostGIS, Flutter offline DB, outbox sync, UI screens, TFLite integration). Adding mobile vet mode to P0 introduces a fatal critical-path bottleneck. | Ratify Decision **D-03**: Vet review is **exclusively on Soham's React Dashboard for P0**. Flutter in P0 is strictly farmer-facing. Mobile vet mode (QR scan) is placed in P1. | Om |
| **ISSUE-05** | **HIGH** | `ML_INTEGRATION.md` §2.2 | Inconsistent image normalization between Python (e.g. `(x / 127.5) - 1.0`) and Dart Flutter can silently corrupt MobileNetV3 inference accuracy. | Embed a `Rescaling(scale=1./127.5, offset=-1)` layer directly at the input of the exported TFLite graph. Flutter passes raw RGB pixel values (`0.0 - 255.0`). | Lokesh |
| **ISSUE-06** | **HIGH** | `API_CONTRACTS.md` §7.1 | `GET /map/cases` deviates from the `{ "data": ... }` response envelope by returning a direct GeoJSON `FeatureCollection`. | Formally confirm and document that `GET /map/cases` intentionally outputs direct GeoJSON to allow native binding to Leaflet (`L.geoJSON(data).addTo(map)`). | Om & Soham |
| **ISSUE-07** | **MEDIUM** | `DATABASE_SCHEMA.md` §4.10 | Non-null `taluka_id` and `district_id` foreign keys on `disease_reports` must be populated when a farmer only submits `village_id` and GPS coordinates. | Go backend service layer must automatically resolve parent `taluka_id` and `district_id` by traversing `locations.parent_id` upon report creation. | Om |
| **ISSUE-08** | **MEDIUM** | `API_CONTRACTS.md` §6.6; `DATABASE_SCHEMA.md` §4.13 | The database enforces a `CHECK` constraint that `notes` must not be empty if a verification decision is `rejected` or `flagged`. | Dashboard form (`S-04`) must validate that `notes` are non-empty before enabling "Submit Rejection" or "Submit Flag" buttons, preventing HTTP 422 errors. | Soham |
| **ISSUE-09** | **MEDIUM** | `DATABASE_SCHEMA.md` §5; `ARCHITECTURE.md` §7 | PostGIS `ST_ClusterDBSCAN` uses `EPSG:32643` (UTM 43N), valid only between 72°E and 78°E. Coordinates outside this range introduce metric distortion. | Explicitly document in seed fixtures that all demo coordinates must reside within Satara / Phaltan (74.0°E–74.6°E), where UTM 43N distortion is negligible. | Om |
| **ISSUE-10** | **LOW** | `deploy/.env.example` | Web dashboard origin (`http://localhost:5173`) requires explicit CORS preflight handling in Gin router. | Include Gin CORS middleware allowing `OPTIONS`, `GET`, `POST`, `PATCH`, and headers `Authorization`, `Content-Type`. | Om |

---

## 3. Implementation Feasibility Validation

### 3.1 Flutter Offline Reporting Workflow
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:** The combination of SQLite (Drift) with an append-only `outbox` table and client-generated UUIDs guarantees offline safety. A farmer can add animals, record symptoms, capture photos, and run on-device screening with airplane mode enabled. When connectivity returns, the outbox worker replays requests idempotently (`POST /animals`, `POST /reports`, `POST /reports/{id}/images`).

### 3.2 TFLite Specifications
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:** Fixed input shape `[1, 224, 224, 3]`, embedded normalization, and output tensor `[1, N]` with Softmax provide unambiguous requirements. The golden test suite (`golden/` images + `expected.json`) provides a deterministic verification mechanism for Flutter unit tests (`tolerance = 1e-3`).

### 3.3 Go Backend & Dashboard Workflows
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:** The REST API covers every user journey: authentication, reference catalog distribution, animal registration, report ingestion, vet verification, summary analytics, and GeoJSON case mapping.

### 3.4 PostGIS Geographic Functionality
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:** Storing points as `geography(Point, 4326)` with GiST indexing provides sub-millisecond proximity queries (`ST_DWithin`) for alert targeting. Transforming to `EPSG:32643` inside `ST_ClusterDBSCAN` provides meter-based distance clustering ($eps = 5000\text{ m}$) across Satara without heavy geospatial libraries.

### 3.5 ML Service Contracts
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:** `POST /v1/risk/predict` is completely stateless. The Go backend passes dynamic case history and outbreak proximity; the FastAPI service joins static district census features. If the ML service is unavailable, the Go backend returns cached `risk_predictions` or HTTP 503 without degrading core reporting.

### 3.6 Multi-Agent Parallel Independence
* **Feasibility: FULLY VALIDATED.**
* **Mechanism:**
  * **Om** works exclusively in `backend/` and `mobile/`.
  * **Lokesh** works exclusively in `ml/` and outputs export bundles to `ml/artifacts/`.
  * **Soham** works exclusively in `dashboard/` consuming mock or live JSON schemas.
  * No developer edits another's directory; shared schemas are protected by contract freeze.

---

## 4. Contract Adjustments Required for v1.0 Freeze

To freeze contracts cleanly at Gate G1, the following immediate adjustments are applied to `API_CONTRACTS.md` and `DATABASE_SCHEMA.md`:

1. **`API_CONTRACTS.md` §2 and §4:** Mark endpoints 8–12 (`GET /reference/*`) as **public** (unauthenticated).
2. **`API_CONTRACTS.md` §6.1:** Add optional `expected_image_count: integer` to `POST /reports` request schema.
3. **`API_CONTRACTS.md` §6:** Add `images_pending: boolean` to `Report` response object.
4. **`API_CONTRACTS.md` §7.1:** Note that `GET /map/cases` intentionally returns a direct GeoJSON `FeatureCollection`.
5. **`DATABASE_SCHEMA.md` §4.10:** Add note on automatic server-side resolution of `taluka_id` and `district_id` from `village_id`.

---

## 5. Architectural Decisions Requiring Om's G1 Approval

Before updating `AGENTS.md` to `CODING: UNLOCKED`, Om must formally approve:

1. **Approval 1 (Decision D-01):** Product name confirmed as **PashuVani**.
2. **Approval 2 (Decision D-02):** Module ownership confirmed per prompt brief:
   * Om: Go Backend + Flutter Mobile App + System Architecture.
   * Lokesh: Machine Learning (MobileNetV3 + XGBoost) + FastAPI Service.
   * Soham: React Dashboard + Leaflet GIS + Vet Review Inbox.
3. **Approval 3 (Decision D-03):** P0 Vet Review Inbox is hosted on the React Dashboard; mobile vet mode is deferred to P1.
4. **Approval 4 (Contract Adjustments):** Approval of the 5 contract adjustments listed in §4 above.
5. **Approval 5 (Gate G1 Transition):** Authorization to update `AGENTS.md` status to `PHASE: 1 — IMPLEMENTATION`, `CODING: UNLOCKED`, and begin parallel execution on feature branches.

