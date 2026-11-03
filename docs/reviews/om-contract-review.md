# docs/reviews/om-contract-review.md — Om's Gate G1 Contract Review

**Module:** Go Backend API & Flutter Mobile Application  
**Reviewer:** Om Rajput (Team Lead / Full-Stack & Mobile Engineer)  
**Date:** 2026-11-03  
**Status:** Review Complete — Blocker & High Priority Fixes Identified

---

## 1. Module Implementation Readiness Statement

> **Statement:** I can implement my P0 tasks (`O-01` through `O-13`) from these contracts **only after the BLOCKER and HIGH issues identified below are resolved and frozen**.

---

## 2. Issues & Proposed Contract Corrections

### BLOCKER-01: Reference Data Endpoints Require Authentication, Blocking Farmer Registration
- **Affected File & Section:** `API_CONTRACTS.md` §2 (Endpoint index #8–12) and §4.
- **Problem:** `GET /reference/locations` and other reference endpoints are marked as `Auth: any` (authenticated). However, a new farmer registering via `POST /auth/register` must select their `village_id` during registration. If `GET /reference/locations` requires a Bearer JWT, the mobile registration screen cannot load state/district/taluka/village dropdowns, making self-registration impossible.
- **Proposed Correction:** Change authentication for all reference catalog endpoints (`GET /reference/*`) to **public**.
- **Responsible Developer:** Om.

### HIGH-01: Decoupled Report Creation vs. Image Upload Creates Asynchronous Incomplete Reports
- **Affected File & Section:** `API_CONTRACTS.md` §6.1, §6.2, and `DATABASE_SCHEMA.md` §4.10.
- **Problem:** When an offline mobile client syncs, it calls `POST /reports` first, followed by `POST /reports/{id}/images`. In poor cellular network conditions, the report metadata may sync while image uploads fail. The report enters status `submitted` in Postgres with 0 images. If a veterinarian opens the review inbox immediately, they see a report with no photo.
- **Proposed Correction:** 
  1. Add an optional `expected_image_count: integer` field to `POST /reports` (default 0).
  2. In `GET /reports`, include `images_pending: boolean` (true if `len(images) < expected_image_count`).
  3. In the Dashboard Vet Review Inbox (`S-03`), display an amber tag "Photos syncing..." if `images_pending` is true, prompting the vet to wait or refresh before making a clinical decision.
- **Responsible Developer:** Om (Backend/Mobile) & Soham (Dashboard).

### HIGH-02: Workload Rebalancing for 24-Hour Hackathon
- **Affected File & Section:** `DEVELOPMENT_PLAN.md` §2 and `DECISIONS.md` D-03.
- **Problem:** Om owns Go backend APIs, PostGIS setup, Flutter mobile app (Drift SQLite offline store, outbox queue, UI screens), TFLite integration, and system orchestration. Building a mobile vet review screen on Flutter in P0 poses a severe timeline bottleneck.
- **Proposed Correction:** Formally ratify Decision **D-03**: The Veterinarian Review Inbox is **exclusively web-based (React Dashboard) for P0**. Flutter mobile in P0 is strictly farmer-facing. Mobile vet mode (QR scanner) remains P1 (`O-16`).
- **Responsible Developer:** Om.

### MEDIUM-01: Admin Location Hierarchy Resolution in Backend
- **Affected File & Section:** `DATABASE_SCHEMA.md` §4.10 (`disease_reports`).
- **Problem:** `disease_reports` has `village_id`, `taluka_id`, and `district_id` as non-null foreign keys. If a farmer submits GPS coordinates with a `village_id`, the backend must automatically resolve `taluka_id` and `district_id` by traversing `locations.parent_id`.
- **Proposed Correction:** Clarify in `DATABASE_SCHEMA.md` that on report insert, if `village_id` is supplied, the backend service layer executes a recursive CTE or cached parent lookup to automatically populate `taluka_id` and `district_id`.
- **Responsible Developer:** Om.

---

## 3. Fields & Endpoints Needed vs. Unnecessary

- **Missing Fields Needed:**
  - `expected_image_count` in `POST /reports` request.
  - `images_pending` in `Report` response object.
- **Unnecessary Fields:**
  - Redis cache configurations (deferred per D-12).
  - OpenTelemetry exporter endpoints in P0 (deferred per D-13).
