# TESTING_STRATEGY.md — Quality Assurance & Testing Strategy

**Version:** 0.1-draft · **Status:** Pending G0/G1 Approval · **Owner:** Om Rajput (Team Lead)

---

## 1. Testing Philosophy

In a 24-hour hackathon, we prioritize high-leverage verification over vanity metrics:
1. **The Golden Thread must not break:** The flow from farmer report ➔ screening ➔ sync ➔ vet verification ➔ map display is the demonstration benchmark.
2. **Safety invariants must hold:** Automated screening must never create a confirmed case or trigger alerts.
3. **Offline sync must be robust:** Network interruption and repeated requests must never corrupt state or duplicate records.
4. **No fabricated test outputs:** PR descriptions and status reports must paste real command outputs from local test runs.

---

## 2. Test Pyramid by Module

### 2.1 Backend (Go)
- **Unit Tests:**
  - Request validation logic (phone format, latitude/longitude ranges, symptom code lists).
  - RBAC authorization checks (ensuring farmers cannot access vet inbox; ensuring vets cannot verify reports outside their assigned district).
  - Outbreak DBSCAN clustering algorithm edge cases.
- **Integration Tests:**
  - HTTP handler tests against a local test database using `httptest.NewServer`.
  - Report creation and outbox idempotency: verify that submitting the same client UUID twice returns `200` with the existing report.
  - Verification transaction: verify that `POST /reports/{id}/verifications` atomically records the verification, updates report status, and writes an audit log.

### 2.2 Mobile (Flutter)
- **Unit Tests:**
  - Outbox state machine: verify transitions `pending` ➔ `syncing` ➔ `done` or `failed` with exponential backoff.
  - Image preprocessing: verify center-crop and resize logic.
  - TFLite Golden Tests: compare inference results on 5 bundled golden test images against Python reference outputs in `expected.json`. Output probabilities must match within `1e-3` tolerance per class.
- **Manual Verification:**
  - Airplane Mode Test: turn on airplane mode, create report with photo, turn off airplane mode, verify outbox drains and report reaches the backend.

### 2.3 Dashboard (React & TypeScript)
- **Unit Tests:**
  - API error envelope parser: verify that `VALIDATION_ERROR` or `UNAUTHENTICATED` are correctly extracted and displayed in UI notifications.
  - Geographic filter helpers: verify cases are properly segmented by District and Taluka.
- **Component Tests:**
  - Vet review inbox component renders submitted reports, photos, and mandatory preliminary screening disclaimers.
  - Leaflet map component initializes and mounts markers correctly from GeoJSON data.

### 2.4 Machine Learning (Python & FastAPI)
- **Parity Tests:**
  - Verify that the exported `.tflite` model produces identical predictions (within `1e-4` MSE) to the unquantized Keras/PyTorch model on test batches.
  - Preprocessing parity: verify Python image pipeline matches Dart Flutter image pipeline.
- **FastAPI Endpoint Tests:**
  - Test `/healthz` returns 200 and model version.
  - Test `POST /v1/risk/predict` with valid, empty, and partial feature dictionaries.
  - Test missing feature handling: verify districts with >50% missing data return `null` risk with `insufficient_data` note.

---

## 3. End-to-End Verification Protocol (Gate G2 Checklist)

Before Gate G2 is approved, Om will execute this end-to-end integration scenario:

| Step | Action | Expected Result | Verified By |
|---|---|---|---|
| 1 | Register Farmer Ramesh on mobile app | Account created; JWT received; stored in local secure storage | Om |
| 2 | Register Animal "Gauri" while offline | Saved in Drift DB; queued in outbox with status `pending` | Om |
| 3 | Create Disease Report with photo & symptoms while offline | MobileNetV3 runs on device; displays disclaimer; report queued in outbox | Om |
| 4 | Reconnect mobile app to backend | Outbox worker drains; animal, report, and photo sync via REST; backend logs 201/200 | Om |
| 5 | Vet Dr. Patil logs into Dashboard | Submitted report appears in Satara district vet inbox with photo and screening result | Soham |
| 6 | Vet confirms case as Lumpy Skin Disease | Backend updates status to `confirmed`; creates verification record | Soham & Om |
| 7 | Officer opens Map view on Dashboard | Confirmed case point appears at reported coordinates under Phaltan taluka filter | Soham & Om |
| 8 | Run clustering check | Case is eligible for DBSCAN clustering; appears in cluster analysis | Om |

---

## 4. Test Execution Commands

### Go Backend
```bash
# Run all unit and integration tests
cd backend && go test -v -race ./...
```

### Flutter Mobile
```bash
# Run unit and golden tests
cd mobile && flutter test
```

### React Dashboard
```bash
# Run test suite
cd dashboard && npm test -- --run
```

### Python ML Service
```bash
# Run pytest on inference service
cd ml && pytest -v tests/
```
