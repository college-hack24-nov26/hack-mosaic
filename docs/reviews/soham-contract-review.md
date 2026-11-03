# docs/reviews/soham-contract-review.md — Soham's Gate G1 Contract Review

**Module:** React & TypeScript Government Dashboard & Leaflet GIS Mapping  
**Reviewer:** Soham Pawar (Senior Frontend & Dashboard Engineer)  
**Date:** 2026-11-03  
**Status:** Review Complete — All Contracts Usable with Two UI Enhancements

---

## 1. Module Implementation Readiness Statement

> **Statement:** I can implement my P0 tasks (`S-01` through `S-05`) and P1 tasks (`S-06` through `S-09`) from these contracts **as written, incorporating the UI safety guardrails noted below**.

---

## 2. Issues & Proposed Contract Corrections

### HIGH-04: GeoJSON Direct Feeding for Leaflet Mapping
- **Affected File & Section:** `API_CONTRACTS.md` §7.1 (`GET /map/cases`).
- **Confirmation:** In `API_CONTRACTS.md`, `GET /map/cases` is explicitly designed **not** to be wrapped in a generic `{ "data": ... }` envelope, but returns a standard GeoJSON `FeatureCollection`:
  ```json
  {
    "type": "FeatureCollection",
    "features": [...],
    "meta": { "count": 1, "truncated": false }
  }
  ```
- **Finding:** This is an outstanding architectural choice that enables direct binding into Leaflet via `L.geoJSON(data).addTo(map)`.
- **Recommendation:** Keep this convention explicitly documented as an intentional deviation from the `{ "data": ... }` envelope to avoid breaking Leaflet native parsers.
- **Responsible Developer:** Soham & Om.

### MEDIUM-03: Vet Inbox Note Validation for Rejection/Flag
- **Affected File & Section:** `API_CONTRACTS.md` §6.6 and `DATABASE_SCHEMA.md` §4.13.
- **Finding:** The backend enforces a database `CHECK` constraint: `notes` cannot be empty if `decision != 'confirmed'`.
- **UI Requirement:** In `S-04` (Vet Decision Actions), the Dashboard form must disable the "Submit Rejection" and "Submit Flag" buttons until the veterinarian enters an explanatory note in the textarea. This prevents unnecessary HTTP 422 `VALIDATION_ERROR` responses from the Go backend.
- **Responsible Developer:** Soham.

### MEDIUM-04: Displaying Image Loading State on Submitted Reports
- **Affected File & Section:** `API_CONTRACTS.md` §6 (`Report` object).
- **Finding:** Addressing Om's review finding `HIGH-01`, the dashboard must handle cases where a farmer's report synced before image upload completed.
- **UI Requirement:** In `S-03` (Vet Inbox), if `report.images.length === 0` and `report.images_pending === true`, render an amber badge: `"Photos Uploading from Field... (Auto-refreshing in 15s)"`.
- **Responsible Developer:** Soham.

---

## 3. Fields & Endpoints Needed vs. Unnecessary

- **Confirmed Interfaces:**
  - `GET /map/cases?district_id=...&taluka_id=...` meets all geospatial filtering requirements.
  - `GET /dashboard/summary` provides all metrics required for summary cards.
  - Standardized error envelope `{ "error": { "code", "message", "details" } }` is fully integrated into the TypeScript API client.
- **Unnecessary Fields:**
  - WebSocket / SSE streaming is unnecessary for the 24-hour hackathon. HTTP polling on a 30-second interval or manual refresh buttons provide full demonstration utility without connection dropouts.

