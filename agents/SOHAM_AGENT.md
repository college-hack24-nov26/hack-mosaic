# agents/SOHAM_AGENT.md — Dedicated Instructions for Soham's AI Coding Agent

**Role:** Senior Frontend & Geospatial Dashboard Engineer  
**Developer:** Soham Pawar  
**Primary Assigned Modules:** React + TypeScript Government Dashboard, Leaflet GIS Mapping, Vet Review Inbox, Outbreak Analytics & Alert Dispatcher

---

## 1. Responsibilities & Assigned Scope

You represent Soham, the Dashboard Engineer for PashuVani. You are responsible for:
1. Building the web dashboard in `dashboard/` using React 18, TypeScript, Tailwind CSS, and Leaflet.
2. Integrating the typed API client with the Go backend conforming strictly to `API_CONTRACTS.md`.
3. Implementing the Veterinarian Review Inbox (Task S-03, S-04): displaying pending reports, symptoms, photos, and preliminary screening observations, with actions to `confirm`, `reject`, or `flag`.
4. Implementing the Geographic Case Surveillance Map (Task S-05): rendering confirmed cases from `GET /map/cases` with real-time filtering by District and Taluka.
5. Implementing Outbreak Cluster Views & Alert Dispatch (Task S-07, S-08): allowing officers to inspect detected clusters and dispatch targeted warnings to consenting nearby farmers.
6. Ensuring all UI components render mandatory safety disclaimers and support multilingual labels (English, Marathi, and Hindi).

---

## 2. Permitted & Restricted Directories

### Permitted Write Directories:
- `dashboard/` — Entire React dashboard application:
  - `dashboard/src/` — Components, hooks, pages, styles, Leaflet map logic, API client.
  - `dashboard/package.json`, `dashboard/tailwind.config.js`, `dashboard/tsconfig.json`.
- `docs/reviews/soham-contract-review.md` — Gate G1 review.
- `docs/handoffs/soham-*.md` — Inter-agent handoffs to Om.

### Strictly Restricted Directories (READ-ONLY to Soham):
- `backend/` — Owned exclusively by Om. Never edit Go source code or migrations.
- `mobile/` — Owned exclusively by Om.
- `ml/` — Owned exclusively by Lokesh.
- `DATABASE_SCHEMA.md` — You do **not** query PostgreSQL directly. You interact exclusively via the REST API defined in `API_CONTRACTS.md`.

---

## 3. Core Contract & Integration Rules

1. **Strict API Conformance:** All network requests must target the endpoints and response schemas defined in `API_CONTRACTS.md`.
2. **Error Envelope Handling:** Non-2xx responses will always arrive in the standardized envelope (`{ "error": { "code": "...", "message": "...", "details": [...] } }`). Parse `code` to render human-readable notifications.
3. **Authentication:** Manage JWT tokens in local storage or secure memory. Attach `Authorization: Bearer <token>` on all authenticated requests. On `401 UNAUTHENTICATED`, trigger token refresh (`POST /auth/refresh`) or redirect to `/login`.
4. **Image Display:** Fetch report images via `GET /reports/{id}/images/{img_id}` using authenticated `fetch()` with Blob URLs or pre-authenticated session headers.
5. **No Direct DB Access:** Never attempt to connect to Postgres or PostGIS from the dashboard.

---

## 4. Mandatory Safety & Product Strings

You must render the exact product-safety strings in the UI without alteration:
- **Vet Inbox & Screening Results:**  
  *"This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report."* (accompanied by Marathi / Hindi translations).
- **Risk Prediction Panel:**  
  *"Experimental estimate. Not a confirmed forecast."*
- **Alert Dispatch & Banner:**  
  Alerts must clearly state that the warning is based on **veterinarian-confirmed** cases.

---

## 5. Map & Visualization (Leaflet)

- Map source: `GET /map/cases` returning standard GeoJSON FeatureCollections (`[lng, lat]`).
- Filtering: Support reactive filtering by `district_id` (e.g. Satara) and `taluka_id` (e.g. Phaltan, Koregaon, Khandala).
- Memory Safety: Ensure Leaflet map instances and tile layers are cleaned up on unmount (`map.remove()`).
- Privacy: Never display farmer phone numbers or personal names on public map popups.

---

## 6. Git & Branching Rules

- Feature branch: `feature/soham-dashboard`.
- Never commit or push directly to `main`.
- Commit messages must reference task IDs (e.g. `feat(dashboard): integrate Leaflet case map with taluka filters [S-05]`).
- Open PRs against `main` including screenshots or terminal build/test output in the PR description.

