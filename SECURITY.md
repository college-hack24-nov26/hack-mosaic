# SECURITY.md — Security, Privacy & Data Protection Policies

**Version:** 0.1-draft · **Status:** Pending G0/G1 Approval · **Owner:** Om Rajput (Team Lead)

---

## 1. Authentication & Session Security

- **Password Storage:** Passwords hashed using bcrypt (cost 12) or Argon2id. Never store plain text or MD5/SHA1 hashes.
- **Access Tokens:** Short-lived JWTs (60-minute expiry) signed with HMAC-SHA256. Tokens carry only `sub` (user_id), `role`, `iat`, `exp`, and `jti`.
- **Refresh Tokens:** High-entropy cryptographically random 32-byte tokens (30-day expiry). Stored in the database as SHA-256 hashes (`token_hash`).
- **Token Rotation & Family Revocation:** When a refresh token is used, it is rotated. If a previously invalidated refresh token is reused, the entire token family for that user is immediately revoked (compromise defense).
- **Internal Service Auth:** The FastAPI ML inference service is not exposed to the public internet. Calls from the Go backend require an internal shared token in the `X-Internal-Token` header.

---

## 2. Role-Based Access Control (RBAC) & Scoping

Access control is enforced at the backend service layer via middleware and scoped SQL queries:

| Role | Permissions & Scoping Rules |
|---|---|
| **Farmer** | Access only own profile, animals, disease reports, and incoming notifications. Cannot view other farmers' reports or access veterinary/officer endpoints. |
| **Veterinarian** | Review reports and submit verifications **only** for reports located within their assigned `district_id`. Access animal medical histories for animals in their district. |
| **District Officer** | View aggregated surveillance maps, cluster alerts, and summary stats **only** within their assigned `district_id`. Can draft and trigger alerts within their district. |
| **State Officer / Admin**| View cross-district analytics and global outbreak reports. Manage user provisioning (`POST /admin/users`). |

**Hard Rule:** Out-of-scope resource requests must return `404 NOT_FOUND` rather than `403 FORBIDDEN` to prevent resource ID enumeration.

---

## 3. Privacy, Farmer Consent & PII Protection

1. **Farmer Consent for Alerts (PPT S5):** Alerts are sent **only** to farmers who have explicitly opted in (`alert_consent = true`). The option is configurable in farmer profile settings.
2. **Alert Anonymity:** Alerts sent to nearby farmers state only that verified cases have occurred within the specified radius. **Alerts must never disclose the name, phone number, or specific farm coordinates of the reporting farmer.**
3. **Surveillance Map Privacy:** `GET /map/cases` returns coordinates and disease types to officers and vets. Farmer phone numbers and personal names are excluded from map GeoJSON properties.
4. **Synthetic Data for Hackathon:** All demonstration datasets, phone numbers, and names must be synthetic. No real farmer records or PII are used or committed.

---

## 4. Input Validation & Injection Defenses

- **SQL Injection:** All PostgreSQL interactions must use parameterized queries (`$1, $2`) via `pgx`. Dynamic SQL query building via string concatenation is strictly forbidden.
- **File Upload Security:**
  - Files accepted only via `POST /reports/{id}/images`.
  - Allowed MIME types strictly validated: `image/jpeg`, `image/png`, `image/webp`.
  - Max upload size: 5 MB per image.
  - Image files stored under randomized UUID storage keys on local disk or S3. Never use client-supplied filenames to prevent path traversal (`../../`).
- **Data Constraints:**
  - Phone numbers strictly validated to E.164 India standard: `^\+91[6-9][0-9]{9}$`.
  - Coordinates validated: Latitude `[-90, 90]`, Longitude `[-180, 180]`.
  - Text fields have maximum character limits enforced by database `CHECK` constraints.

---

## 5. Secret Management

1. **No Committed Secrets:** `.env` files, keystores, SSH keys, TLS certificates, and API tokens must never be committed to Git.
2. **Environment Configuration:** All secrets must be injected via environment variables at runtime.
3. **Template Provided:** `deploy/.env.example` provides documentation of all required variables with dummy values.
4. **QR Code Integrity:** The backend holds an Ed25519 private key to cryptographically sign offline animal health snapshots. The Flutter app ships only the corresponding public key to verify signatures offline.

