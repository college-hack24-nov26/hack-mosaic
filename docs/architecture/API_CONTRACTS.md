# API_CONTRACTS.md — PashuVani Shared API Contracts

**Version:** 0.1-draft · **Status:** NOT FROZEN (needs Gate G1) · **Owner:** Om · **Co-reviewer:** Soham · **ML-service review:** Lokesh (§12)
**Consumers:** Flutter app (Om), React dashboard (Soham). Internal: Go ⇄ FastAPI ML service (Lokesh).

This document is the **only** definition of the HTTP interface. If the Go code, Flutter code, or React code disagree with it, the code is wrong or a Change Request is needed.

---

## 1. Global conventions

| Topic | Rule |
|---|---|
| Base URL | `/api/v1` (dev: `http://localhost:8080/api/v1`) |
| Format | JSON (`application/json; charset=utf-8`) except image upload (`multipart/form-data`). Field names `snake_case`. |
| Auth | `Authorization: Bearer <access_token>` (JWT). Public endpoints marked **public**. |
| IDs | UUID strings (lowercase, hyphenated). |
| Timestamps | RFC 3339 UTC with `Z` (e.g. `2026-11-03T08:12:00Z`). Dates: `YYYY-MM-DD`. |
| Coordinates | JSON objects `{"lat": 17.9856, "lng": 74.4331}`. Valid ranges lat −90..90, lng −180..180. **GeoJSON responses use `[lng, lat]`** (standard). |
| Phone | E.164 `+91` + 10 digits starting 6–9. |
| Enums | Exact strings from `DATABASE_SCHEMA.md` §3. Unknown enum value → `422`. |
| Codes | Species, breeds, diseases, symptoms referenced by stable `code`. Locations by `id`. |
| Pagination | `?page=1&page_size=20` (max 100). Response `meta: {"page":1,"page_size":20,"total":57}`. |
| Sorting | Lists default `reported_at desc` / `created_at desc`. No client sort params in v1. |
| Nulls | Optional response fields are present with `null`, never omitted. |
| Idempotency | `POST /animals`, `POST /reports`, `POST /reports/{id}/images` take a **client-generated `id`**. Re-sending the same `id` by the same owner with the same content returns **200** with the existing resource (not 201). Same `id` owned by someone else → `409 CONFLICT`. |
| Rate limits | Login: 10/min per IP. Others: 120/min per user. Over → `429` with `Retry-After`. |
| Request ID | Server returns `X-Request-Id`; clients may send one. |
| Language | `Accept-Language: en|hi|mr` affects only human-readable `message` strings. Catalog responses carry all languages. |
| CORS | Dashboard origin(s) allowed via env config. |

### 1.1 Success envelope

Single resource: `{ "data": { ... } }`. List: `{ "data": [ ... ], "meta": { ... } }`. Empty success (`204`) has no body.

### 1.2 Error envelope (every non-2xx)

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [ { "field": "location.lat", "issue": "must be between -90 and 90" } ],
    "request_id": "6f1b8a2c-..."
  }
}
```

| HTTP | `code` | Meaning |
|---|---|---|
| 400 | `BAD_REQUEST` | Malformed JSON / bad query syntax |
| 401 | `UNAUTHENTICATED` | Missing/expired/invalid token (`details` may contain `{"issue":"token_expired"}`) |
| 403 | `FORBIDDEN` | Authenticated, role/scope not allowed |
| 404 | `NOT_FOUND` | Missing **or not visible** to caller (no existence leak) |
| 409 | `CONFLICT` | Duplicate/ownership/state conflict (e.g. idempotency collision, invalid status transition) |
| 413 | `PAYLOAD_TOO_LARGE` | Image > 5 MB |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | Not jpeg/png/webp |
| 422 | `VALIDATION_ERROR` | Field validation failed (`details` lists fields) |
| 429 | `RATE_LIMITED` | |
| 500 | `INTERNAL` | No internals leaked |
| 503 | `UPSTREAM_UNAVAILABLE` | ML service/other dependency down |

Clients must branch on `error.code`, not on `message`.

### 1.3 Roles

`farmer`, `vet`, `officer` (district or state), `admin`. Scope rules:

| Role | Visibility |
|---|---|
| farmer | Own profile, animals, reports, notifications |
| vet | Reports (and linked animals/records) whose `district_id` = vet's `district_id` |
| officer (district) | Everything aggregated/mapped within own district |
| officer (state) / admin | All districts |

Out-of-scope resources return `404` (item) or are filtered out (list). Wrong role for an endpoint → `403`.

## 2. Endpoint index

| # | Method | Path | Auth/role | Owner | Pri |
|---|---|---|---|---|---|
| 1 | GET | `/healthz` | public | Om | P0 |
| 2 | POST | `/auth/register` | public | Om | P0 |
| 3 | POST | `/auth/login` | public | Om | P0 |
| 4 | POST | `/auth/refresh` | public | Om | P0 |
| 5 | POST | `/auth/logout` | any | Om | P0 |
| 6 | GET | `/me` | any | Om | P0 |
| 7 | PATCH | `/me` | any | Om | P0 |
| 8 | GET | `/reference/locations` | public | Om | P0 |
| 9 | GET | `/reference/species` | public | Om | P0 |
| 10 | GET | `/reference/breeds` | public | Om | P0 |
| 11 | GET | `/reference/diseases` | public | Om | P0 |
| 12 | GET | `/reference/symptoms` | public | Om | P0 |
| 13 | POST | `/animals` | farmer | Om | P0 |
| 14 | GET | `/animals` | farmer | Om | P0 |
| 15 | GET | `/animals/{id}` | farmer(owner), vet, officer, admin | Om | P0 |
| 16 | PATCH | `/animals/{id}` | farmer(owner) | Om | P1 |
| 17 | GET | `/animals/{id}/record` | farmer(owner), vet | Om | P1 |
| 18 | GET | `/animals/{id}/qr-payload` | farmer(owner) | Om | P1 |
| 19 | POST | `/animals/{id}/health-records` | vet, farmer(owner) | Om | P1 |
| 20 | POST | `/animals/{id}/vaccinations` | vet | Om | P1 |
| 21 | POST | `/animals/{id}/treatments` | vet | Om | P1 |
| 22 | POST | `/reports` | farmer | Om | P0 |
| 23 | POST | `/reports/{id}/images` | farmer(owner) | Om | P0 |
| 24 | GET | `/reports` | farmer, vet, officer, admin (scoped) | Om | P0 |
| 25 | GET | `/reports/{id}` | scoped | Om | P0 |
| 26 | GET | `/reports/{id}/images/{image_id}` | scoped | Om | P0 |
| 27 | POST | `/reports/{id}/verifications` | vet | Om | P0 |
| 28 | POST | `/reports/{id}/claim` | vet | Om | P1 |
| 29 | GET | `/map/cases` | vet, officer, admin | Om | P0 |
| 30 | GET | `/dashboard/summary` | officer, admin (vet: own district) | Om | P0 |
| 31 | GET | `/dashboard/timeseries` | officer, admin | Om | P1 |
| 32 | GET | `/outbreaks` | officer, admin, vet | Om | P1 |
| 33 | GET | `/outbreaks/{id}` | officer, admin, vet | Om | P1 |
| 34 | PATCH | `/outbreaks/{id}` | officer, admin | Om | P1 |
| 35 | POST | `/outbreaks/recompute` | officer, admin | Om | P1 |
| 36 | POST | `/alerts` | officer, admin | Om | P1 |
| 37 | GET | `/alerts` | officer, admin | Om | P1 |
| 38 | POST | `/alerts/{id}/send` | officer, admin | Om | P1 |
| 39 | GET | `/notifications` | any | Om | P1 |
| 40 | POST | `/notifications/{id}/read` | owner | Om | P1 |
| 41 | GET | `/risk/districts` | officer, admin | Om (data: Lokesh) | P2 |
| 42 | POST | `/risk/refresh` | officer, admin | Om | P2 |
| 43 | POST | `/admin/users` | admin | Om | P1 |
| 44 | POST | `/me/devices` | any | Om | P2 |
| — | POST | `/assist/*` (Gemini) | — | Om | P2, contract **TBD** (D-10) |

"Owner" = module owner who implements the server side. Consumer-side tasks are in `DEVELOPMENT_PLAN.md`.

---

## 3. Auth

### 3.1 `POST /auth/register` — public, P0
Self-registration is **farmer only**. Vets/officers/admins are seeded or created via `POST /admin/users`.

Request:
```json
{
  "phone": "+919876543210",
  "password": "min8chars",
  "full_name": "Ramesh Jadhav",
  "preferred_language": "mr",
  "village_id": "7b0e…-uuid"
}
```
Validation: phone unique, E.164 India; password 8–72 chars; `full_name` 2–100; `village_id` must exist with level `village`.
Response `201`:
```json
{ "data": {
  "user": { "id": "…", "phone": "+919876543210", "full_name": "Ramesh Jadhav", "role": "farmer", "preferred_language": "mr" },
  "access_token": "<jwt>", "refresh_token": "<opaque>", "expires_in": 3600
} }
```
Errors: `409 CONFLICT` (phone exists), `422`.

### 3.2 `POST /auth/login` — public, P0
Request: `{ "phone": "+919876543210", "password": "…" }`. Response `200`: same shape as register. Errors: `401 UNAUTHENTICATED` (generic message; no hint which field), `429`.

### 3.3 `POST /auth/refresh` — public, P0
Request: `{ "refresh_token": "…" }`. Response `200`: `{ "data": { "access_token": "…", "refresh_token": "…(rotated)", "expires_in": 3600 } }`. Reusing a rotated token → `401` and the whole token family is revoked.

### 3.4 `POST /auth/logout` — any, P0
Request: `{ "refresh_token": "…" }`. Response `204`.

### 3.5 JWT
HS256, claims: `sub` (user id), `role`, `iat`, `exp` (access TTL 60 min), `jti`. Scope (district etc.) is **looked up server-side**, never trusted from the token. Refresh token: opaque 32-byte random, TTL 30 days, stored hashed.

### 3.6 `GET /me` — any, P0
Response `200`:
```json
{ "data": {
  "id": "…", "phone": "+91…", "full_name": "…", "role": "vet", "preferred_language": "mr",
  "profile": {
    "farmer":  { "village_id": "…", "farm_name": null, "farm_location": null, "alert_consent": false } ,
    "vet":     { "district_id": "…", "registration_number": "…", "is_para_vet": false, "clinic_name": null },
    "officer": { "level": "district", "district_id": "…", "designation": null }
  }
} }
```
Only the profile matching the role is non-null; the others are `null`.

### 3.7 `PATCH /me` — any, P0
Allowed fields (all optional): `full_name`, `preferred_language`; farmer only: `village_id`, `farm_name`, `farm_location` (`{lat,lng}`), `alert_consent` (bool). Setting `alert_consent=true` records `alert_consent_at`. Response `200` same as `GET /me`.

---

## 4. Reference data (public read-only, cache-friendly)

All reference endpoints are **public** (unauthenticated) so that unauthenticated users can load administrative hierarchy locations during self-registration. All return `{ "data": [ ... ] }` with `ETag` support. The Flutter app caches them for offline use.

| Endpoint | Query | Item |
|---|---|---|
| `GET /reference/locations` | `level` (required), `parent_id` (required unless level=`state`) | `{ "id", "level", "parent_id", "name_en", "name_mr", "name_hi", "lgd_code", "centroid": {"lat","lng"}\|null }` |
| `GET /reference/species` | — | `{ "code", "name_en", "name_mr", "name_hi" }` |
| `GET /reference/breeds` | `species_code` (required) | `{ "code", "species_code", "name_en", "name_mr", "name_hi" }` |
| `GET /reference/diseases` | `species_code` (optional) | `{ "code", "name_en", "name_mr", "name_hi", "is_surveillance" }` |
| `GET /reference/symptoms` | — | `{ "code", "name_en", "name_mr", "name_hi" }` |

---

## 5. Animals

**Animal object**
```json
{
  "id": "uuid", "farmer_id": "uuid",
  "species_code": "cattle", "breed_code": "gir",
  "name": "Gauri", "tag_number": null, "sex": "female",
  "birth_date": "2021-06-01", "markings": "white patch on forehead",
  "is_active": true, "created_at": "…", "updated_at": "…"
}
```

### 5.1 `POST /animals` — farmer, P0 (idempotent)
Request: `{ "id": "uuid", "species_code": "cattle", "breed_code": "gir"|null, "name": "Gauri"|null, "tag_number": null, "sex": "female", "birth_date": "2021-06-01"|null, "markings": null }`.
Validation: `id` valid UUID; `species_code` exists; `breed_code` belongs to species; `name` ≤ 60; `tag_number` ≤ 30 and unique; `birth_date` not in future.
Response `201` (new) / `200` (replay): `{ "data": <Animal> }`. Errors: `409` (tag number taken / id owned by another user), `422`.

### 5.2 `GET /animals` — farmer, P0
Query: `page`, `page_size`. Returns own active animals. `{ "data": [<Animal>], "meta": {…} }`.

### 5.3 `GET /animals/{id}` — P0
Farmer: own only. Vet: only if the animal has a report in the vet's district. Officer/admin: within scope. Response `{ "data": <Animal> }`; `404` otherwise.

### 5.4 `PATCH /animals/{id}` — farmer(owner), P1
Fields: `name`, `breed_code`, `tag_number`, `sex`, `birth_date`, `markings`, `is_active`. Response `200` `<Animal>`.

### 5.5 `GET /animals/{id}/record` — farmer(owner), vet, P1
Full online record:
```json
{ "data": {
  "animal": <Animal>,
  "health_records": [ { "id","record_type","recorded_at","summary","data" } ],
  "vaccinations":   [ { "id","disease_code","vaccine_name","administered_on","next_due_on","batch_number" } ],
  "treatments":     [ { "id","report_id","treatment_name","dosage","started_on","ended_on","notes" } ],
  "recent_reports": [ { "id","reported_at","status","confirmed_disease_code" } ],
  "generated_at": "2026-11-03T08:12:00Z"
} }
```

### 5.6 `GET /animals/{id}/qr-payload` — farmer(owner), P1
Returns the compact signed snapshot the farmer's phone renders as a QR code so a vet can read it **offline**.
```json
{ "data": {
  "payload": "<base64url of compact JSON, ≤ 1500 bytes>",
  "signature": "<base64url Ed25519 signature over payload bytes>",
  "key_id": "k1",
  "snapshot_at": "2026-11-03T08:12:00Z"
} }
```
Decoded payload (v1) contains: `v`, `animal_id`, `species_code`, `breed_code`, `name`, `tag_number`, `sex`, `birth_date`, `farmer_name`, up to 5 latest vaccinations, up to 3 latest treatments, `snapshot_at`. The vet app ships the **public key(s)** and verifies offline; it must display `snapshot_at` prominently (R-26). Signing scheme is **proposed** (D-11).

### 5.7 P1 writes
- `POST /animals/{id}/health-records` — `{ "record_type": "observation", "recorded_at": "…", "summary": "…", "data": {} }` → `201 {data:{…}}`.
- `POST /animals/{id}/vaccinations` (vet) — `{ "disease_code": "lumpy_skin_disease"|null, "vaccine_name": "…", "administered_on": "2026-10-01", "next_due_on": "2027-10-01"|null, "batch_number": null }`.
- `POST /animals/{id}/treatments` (vet) — `{ "report_id": null, "treatment_name": "…", "dosage": null, "started_on": "…", "ended_on": null, "notes": null }`.
Same validation rules as `DATABASE_SCHEMA.md` §4.14–4.16.

---

## 6. Disease reports

**Report object** (the same shape is returned by create, get, and list in v1)
```json
{
  "id": "uuid",
  "animal": { "id": "uuid", "name": "Gauri", "species_code": "cattle", "breed_code": "gir", "tag_number": null },
  "farmer": { "id": "uuid", "full_name": "Ramesh Jadhav", "phone": "+91…" },
  "reported_at": "2026-11-03T08:12:00Z",
  "received_at": "2026-11-03T09:40:12Z",
  "description": "Lumps on skin, not eating",
  "description_language": "mr",
  "symptom_codes": ["skin_nodules", "loss_of_appetite"],
  "location": { "lat": 17.9856, "lng": 74.4331, "accuracy_m": 12.0, "source": "gps" },
  "village_id": "uuid", "taluka_id": "uuid", "district_id": "uuid",
  "status": "submitted",
  "screening": {
    "model_version": "mnv3s-2026.11.0",
    "top_label": "lumpy_skin_disease",
    "top_confidence": 0.82,
    "inconclusive": false,
    "scores": [ { "label": "lumpy_skin_disease", "score": 0.82 }, { "label": "other", "score": 0.18 } ],
    "ran_at": "2026-11-03T08:12:30Z",
    "disclaimer": "preliminary_screening_not_a_diagnosis"
  },
  "images": [ { "id": "uuid", "url": "/api/v1/reports/<id>/images/<image_id>", "mime_type": "image/jpeg", "width": 1200, "height": 900 } ],
  "images_pending": false,
  "verification": null,
  "created_at": "…", "updated_at": "…"
}
```
- `screening` is `null` if none was supplied. The server always adds the constant `disclaimer`. (Labels in the example are **illustrative**; real labels come from the ML manifest.)
- `verification` is `null` until a vet decides, then:
```json
"verification": {
  "id": "uuid", "decision": "confirmed", "disease_code": "lumpy_skin_disease",
  "notes": null, "visit_required": false,
  "vet": { "id": "uuid", "full_name": "Dr. Patil" }, "decided_at": "…"
}
```
- `farmer` is returned to vets/officers/admin; for the farmer themself it is also returned (own data). Farmer phone is omitted (`null`) for officers (privacy: see `SECURITY.md` §6).
- `location` is `null` if the farmer had no GPS and chose village fallback → then `location` contains the village centroid with `"source": "village_centroid"`, `accuracy_m: null`.

### 6.1 `POST /reports` — farmer, P0 (idempotent)
Request:
```json
{
  "id": "uuid",
  "animal_id": "uuid",
  "reported_at": "2026-11-03T08:12:00Z",
  "description": "Lumps on skin, not eating",
  "description_language": "mr",
  "symptom_codes": ["skin_nodules", "loss_of_appetite"],
  "location": { "lat": 17.9856, "lng": 74.4331, "accuracy_m": 12.0 },
  "village_id": null,
  "expected_image_count": 1,
  "screening": {
    "model_version": "mnv3s-2026.11.0",
    "top_label": "lumpy_skin_disease",
    "top_confidence": 0.82,
    "inconclusive": false,
    "scores": [ { "label": "lumpy_skin_disease", "score": 0.82 } ],
    "ran_at": "2026-11-03T08:12:30Z"
  }
}
```
Validation:
- `id` UUID; `animal_id` must be an active animal owned by the caller.
- `reported_at` ≤ server time + 10 min; not older than 30 days.
- `description` ≤ 2000 (optional); at least one of `description`, `symptom_codes` (≥ 1), or a later image is expected, but v1 only **requires** `symptom_codes` OR `description` non-empty.
- `symptom_codes` ≤ 15 items, each an existing active code.
- `expected_image_count` optional integer (0 to 4, default 0). Used by server to compute `images_pending = (len(images) < expected_image_count)`.
- `location` optional; if absent `village_id` or the farmer's profile village is used (`source=village_centroid`). If present, `source` is set to `gps` by server. `accuracy_m` ≥ 0.
- `screening` optional; if present: `model_version` 1–50 chars, `top_label` matches `^[a-z0-9_]{1,64}$`, `top_confidence` 0..1, `scores` ≤ 20 items each 0..1, `ran_at` valid.
- The server **does not** validate screening labels and never copies them into `confirmed_*` fields.
Response `201` (new) / `200` (replay): `{ "data": <Report> }`. Errors: `404` (animal), `409`, `422`.
Status is always `submitted` on create.

### 6.2 `POST /reports/{id}/images` — farmer(owner), P0 (idempotent)
`multipart/form-data` fields: `image_id` (UUID), `file` (binary), `sha256` (hex, optional — server verifies if given).
Limits: ≤ 5 MB; `image/jpeg|png|webp`; ≤ 4 images per report; client should downscale to long edge ≤ 1600 px, JPEG quality ~85.
Response `201`/`200`: `{ "data": { "id","url","mime_type","width","height","size_bytes" } }`. Errors: `404`, `409` (id used elsewhere / limit exceeded), `413`, `415`, `422` (sha mismatch/not decodable).
Offline order for sync: `POST /animals` → `POST /reports` → `POST /reports/{id}/images`. Each step is individually retry-safe.

### 6.3 `GET /reports` — scoped, P0
Query (all optional): `status`, `animal_id`, `district_id`, `taluka_id`, `village_id`, `disease_code` (confirmed disease), `from`, `to` (on `reported_at`, RFC 3339), `page`, `page_size`.
Scope: farmer → own only (ignores `district_id` etc.); vet → own district; officer → own district (district) or any; admin → any. Out-of-scope filter values simply yield an empty list.
Response `200`: `{ "data": [<Report>], "meta": {…} }`. Vet inbox usage: `?status=submitted` (oldest first when `status=submitted`; otherwise newest first).

### 6.4 `GET /reports/{id}` — P0 · `{ "data": <Report> }` or `404`.

### 6.5 `GET /reports/{id}/images/{image_id}` — P0
Returns image bytes with `Content-Type`; same auth as report (Bearer header required; the dashboard fetches it with `fetch` + blob or authenticated `<img>` via blob URL). Cache `private, max-age=3600`.

### 6.6 `POST /reports/{id}/verifications` — vet, P0
Request:
```json
{ "decision": "confirmed", "disease_code": "lumpy_skin_disease", "notes": "Nodules consistent, visited farm", "visit_required": false }
```
Validation: `decision` ∈ `confirmed|rejected|flagged`; `disease_code` **required and an active disease iff** `decision=confirmed`, forbidden otherwise; `notes` ≤ 2000 and **required when decision ≠ confirmed**; vet's district must equal report's `district_id` (else `404`). Para-vet policy: **TBD** (M-06) — until decided, any `vet` may confirm.
Behaviour: appends a new `vet_verifications` row (previous becomes non-current), updates the report status/`confirmed_disease_id`/`confirmed_at` in one transaction, writes an audit log, creates a `report_update` notification for the farmer (P1), and triggers outbreak recompute asynchronously (P1).
Response `201`: `{ "data": <Report> }` (with updated `status` and `verification`). Errors: `403` (not a vet), `404`, `409` (e.g. identical decision already current), `422`.

### 6.7 `POST /reports/{id}/claim` — vet, P1
No body. Sets `submitted → under_review` for the vet's inbox. Response `200 <Report>`. `409` if not `submitted`.

---

## 7. Map and dashboard (primary consumer: Soham)

### 7.1 `GET /map/cases` — vet, officer, admin, P0
**Only reports with `status='confirmed'`.** Query: `district_id`, `taluka_id`, `disease_code`, `from`, `to` (on `confirmed_at`). Officers/vets are auto-scoped. Not paginated; hard cap 2000 features (response `meta.truncated: true` if exceeded).
Response `200`:
```json
{
  "type": "FeatureCollection",
  "features": [
    { "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [74.4331, 17.9856] },
      "properties": { "report_id": "uuid", "disease_code": "lumpy_skin_disease", "confirmed_at": "…", "taluka_id": "uuid", "district_id": "uuid", "location_source": "gps" } }
  ],
  "meta": { "count": 1, "truncated": false }
}
```
(Intentionally **not** wrapped in `data`, so it feeds Leaflet's `L.geoJSON` directly.) No farmer identity in properties.

### 7.2 `GET /dashboard/summary` — officer, admin (vet: own district), P0
Query: `district_id`, `taluka_id`, `from`, `to`.
```json
{ "data": {
  "scope": { "district_id": "uuid|null", "taluka_id": "uuid|null", "from": null, "to": null },
  "totals": { "reports": 120, "pending": 30, "confirmed": 70, "rejected": 15, "flagged": 5 },
  "by_disease": [ { "disease_code": "lumpy_skin_disease", "confirmed": 55 } ],
  "by_taluka": [ { "taluka_id": "uuid", "name_en": "Phaltan", "name_mr": "फलटण", "reports": 60, "confirmed": 40 } ],
  "active_outbreaks": 1,
  "generated_at": "…"
} }
```
`pending` = `submitted` + `under_review`.

### 7.3 `GET /dashboard/timeseries` — officer, admin, P1
Query: `interval` (`day`|`week`, default `day`), `from`, `to` (default last 30 days), `district_id`, `taluka_id`, `disease_code`.
`{ "data": [ { "bucket_start": "2026-11-01", "reports": 12, "confirmed": 5 } ] }`

---

## 8. Outbreaks and alerts (P1)

**Outbreak object**
```json
{
  "id": "uuid", "disease_code": "lumpy_skin_disease", "district_id": "uuid",
  "status": "suspected",
  "centroid": { "lat": 17.99, "lng": 74.43 }, "radius_m": 3200, "case_count": 4,
  "first_case_at": "…", "last_case_at": "…", "rule_version": "dbscan-5km-3cases-14d",
  "disclaimer": "derived_from_vet_confirmed_cases",
  "reviewed_by": null, "reviewed_at": null, "detected_at": "…"
}
```
- `GET /outbreaks` — query `status`, `district_id`, `disease_code`, `page`, `page_size` → `{data:[<Outbreak>], meta}`.
- `GET /outbreaks/{id}` — `{ data: { ...<Outbreak>, "cases": [ { "report_id","confirmed_at","location":{lat,lng} } ] } }`.
- `PATCH /outbreaks/{id}` — officer/admin; body `{ "status": "active"|"dismissed"|"resolved", "note": "…"? }`. Allowed: `suspected→active|dismissed`, `active→resolved|dismissed`. Else `409`. Sets `reviewed_by/at`. Returns `<Outbreak>`.
- `POST /outbreaks/recompute` — officer/admin; no body; `202 { "data": { "status": "queued" } }` (also runs automatically after each verification and every 15 min).

**Alert object**: `{ "id","outbreak_id","title","message","center":{lat,lng},"radius_m","status","sent_at","recipient_count","created_by","created_at" }`

- `POST /alerts` — officer/admin. Body `{ "outbreak_id": "uuid", "title": "…≤120", "message": "…≤1000", "radius_m": 5000, "center": {"lat","lng"}|null }` (center defaults to outbreak centroid). `radius_m` 500–25000. Outbreak must be `active` else `409`. → `201 { data: <Alert> }` (status `draft`).
- `GET /alerts` — query `status`, `outbreak_id`, paging.
- `POST /alerts/{id}/send` — officer/admin. No body. Requires draft, outbreak `active`, ≥ 1 member case still `confirmed`. Delivers one `notification` (type `alert`) to every consenting farmer within radius. → `200 { data: <Alert> }` with `recipient_count`. `409` otherwise. Idempotent: re-send of a sent alert returns `409`.

## 9. Notifications (P1)

**Notification object**: `{ "id","type","title","body","alert_id":null,"data":{},"read_at":null,"created_at" }`
- `GET /notifications?unread=true&page=1&page_size=20` → `{data:[…], meta}`. Farmers poll this (P1) and on app start; FCM push is P2.
- `POST /notifications/{id}/read` → `200 {data: <Notification>}`.
- `POST /me/devices` (P2) — `{ "token": "…", "platform": "android" }` → `204`.

## 10. Risk (P2, experimental)

**RiskPrediction object**
```json
{ "district_id": "uuid", "disease_code": "lumpy_skin_disease", "as_of_date": "2026-11-03", "horizon_days": 14,
  "risk_score": 0.37, "risk_band": "medium", "model_version": "xgb-…", "feature_schema_version": "…",
  "missing_features": ["weather_rain_mm_30d"], "generated_at": "…",
  "disclaimer": "experimental_estimate_not_a_confirmed_forecast" }
```
(Numbers illustrative.)
- `GET /risk/districts?disease_code=…&as_of_date=…` → `{ data: [<RiskPrediction>] }` (latest stored per district; empty list if none). **District-level only; no taluka endpoint exists by design.**
- `POST /risk/refresh` — officer/admin. Go builds features, calls the ML service (§12), stores results. `200 { data: [<RiskPrediction>] }`; `503 UPSTREAM_UNAVAILABLE` if the ML service is down (stored data remains readable).

## 11. Admin

- `POST /admin/users` (admin, P1): `{ "phone","password","full_name","role":"vet"|"officer"|"admin","preferred_language", "vet": { "district_id","registration_number","is_para_vet","clinic_name" }, "officer": { "level","district_id","designation" } }` → `201 {data:{user}}`. Profile object required for the matching role; forbidden for others.
- P0 alternative: seed script creates demo vet/officer/admin (no HTTP).

## 12. Internal contract: Go → FastAPI ML service (Lokesh implements)

Not reachable by Flutter/React. Auth: header `X-Internal-Token: <shared secret from env>`; network-private. Full field semantics in `ML_INTEGRATION.md` §3.

| Method | Path | Purpose |
|---|---|---|
| GET | `/healthz` | `{ "status": "ok", "model_version": "…" }` |
| GET | `/v1/model/info` | model version, feature schema, training metadata |
| POST | `/v1/risk/predict` | batch district prediction |

`POST /v1/risk/predict` request:
```json
{
  "request_id": "uuid", "disease_code": "lumpy_skin_disease", "as_of_date": "2026-11-03", "horizon_days": 14,
  "districts": [
    { "district_id": "uuid", "lgd_code": "…",
      "features": { "confirmed_cases_7d": 3, "confirmed_cases_30d": 9, "confirmed_cases_prev_30d": 2, "nearest_active_outbreak_km": 12.4 } }
  ]
}
```
Response `200`:
```json
{
  "model_version": "xgb-…", "feature_schema_version": "…", "generated_at": "…",
  "predictions": [
    { "district_id": "uuid", "risk_score": 0.37, "risk_band": "medium", "horizon_days": 14,
      "features_used": ["confirmed_cases_7d", "…"], "missing_features": ["…"] }
  ]
}
```
Errors (FastAPI service): `{ "error": { "code": "...", "message": "..." } }` with `400/401/422/500/503` using the same `code` vocabulary as §1.2. Go maps all failures to `503 UPSTREAM_UNAVAILABLE` outward, 5 s timeout, no retries beyond one.

## 13. Cross-module consistency checklist (verified before freeze)

- Enum strings identical in `DATABASE_SCHEMA.md` §3, here, and `agents/*`.
- Every field in a report's `screening` object maps to `disease_reports.screening_*` columns and to the ML manifest outputs (`ML_INTEGRATION.md` §2.6).
- `taluka_id`/`district_id` filters exist on `/reports`, `/map/cases`, `/dashboard/*` to satisfy R-23.
- No endpoint exposes XGBoost output at taluka level (C-08).
- No endpoint lets AI output set `confirmed` status.

## 14. Versioning and change policy

- `v1` frozen at Gate G1. Additive, backwards-compatible changes (new optional fields, new endpoints) after freeze need a CR approved by Om + the affected consumer and must be announced in `docs/change-requests/`. Breaking changes need all-three approval and a version bump of this document (`1.1`, `1.2`…); there is no `/v2` in this hackathon.
- Clients must ignore unknown response fields.
- Document version is mirrored in `AGENTS.md` §0.

## 15. Open API questions for G1 review

| ID | Question | Default if unanswered |
|---|---|---|
| AQ-1 | Do vets use the dashboard or the Flutter app for P0 review? | Dashboard (Soham builds vet inbox) |
| AQ-2 | Should reports list items be slimmer than the detail object? | Same object (simplicity) |
| AQ-3 | Should the dashboard fetch images via blob URLs (needs Bearer) or signed URLs? | Blob via fetch (no signed URLs) |
| AQ-4 | Is `phone` visible to officers? | No (null) |
| AQ-5 | `page_size` max 100 acceptable for map-less lists? | Yes |
| AQ-6 | QR signing scheme (Ed25519, D-11)? | Proposed as written |
