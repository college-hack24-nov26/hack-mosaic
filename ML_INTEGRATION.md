# ML_INTEGRATION.md — ML Models and Integration Contracts

**Version:** 0.1-draft · **Status:** NOT FROZEN (needs Gate G1) · **Owner:** Lokesh (models, service) · **Integrators:** Om (Flutter TFLite, Go client)

> **Honesty rules (binding on Lokesh's agent and everyone else):**
> - No fabricated datasets, accuracy, predictions, or evaluation results — anywhere (docs, UI, slides, demo).
> - Every number in this document that looks like a result is **illustrative** and marked as such.
> - Any reported metric must state: dataset name + licence, split method, sample counts per class, and that it was measured on that split only.
> - ML output is a **preliminary screening / experimental estimate**, never a diagnosis (PPT S4, S10).

---

## 1. Where ML sits in the system

| # | Capability | Runs where | Network? | Output goes to | Priority |
|---|---|---|---|---|---|
| 1 | **Image screening** (MobileNetV3-Small, TFLite) | Phone (Flutter) | **No** (offline) | Shown to farmer; attached to the report as `screening` | P0 |
| 2 | **Risk estimate** (XGBoost, FastAPI) | Server (Python) | Yes (Go → FastAPI) | `risk_predictions`; dashboard district panel | P2 (experiment) |
| 3 | **Gemini assistance** (via Go) | Third-party | Yes | Informational text only | P2, TBD (D-10) |

The three are independent. #1 and #2 can never create a confirmed case, trigger an alert, or change a report's status. Only a vet verification can.

---

## 2. MobileNetV3 on-device screening

### 2.1 Model
- Architecture: **MobileNetV3-Small** (per PPT S5), transfer learning. Switching to MobileNetV3-Large requires a Decision if the artifact exceeds the size budget (§2.9).
- Export: **TensorFlow Lite**. Quantisation (float16 or dynamic-range) allowed if the evaluation on the held-out set is re-run **on the exported `.tflite`** and reported. Default: float32 unless size/latency requires otherwise.

### 2.2 Input contract (fixed unless a CR changes it)

| Property | Value |
|---|---|
| Tensor | 1 input, shape `[1, 224, 224, 3]` (NHWC) |
| Dtype | `float32` |
| Channel order | RGB |
| Value range fed by Flutter | **raw pixel values 0.0–255.0** (no division, no mean/std) |
| Normalisation | **Embedded in the exported model** (Keras `MobileNetV3` built-in preprocessing / a `Rescaling` layer), so Flutter does no model-specific maths. If Lokesh cannot embed it, he must change `manifest.json` `input.normalization` and notify Om via CR before freeze. |
| Resize | Center-crop to square on the shorter side, then bilinear resize to 224×224. Aspect ratio never stretched. |
| Orientation | Apply EXIF orientation before cropping (phone photos). |
| Colour space | sRGB; drop alpha. |

Flutter must run exactly this pipeline; Lokesh must train/evaluate with the **same** pipeline (his Python reference preprocessing is documented in `ml/mobilenet/README.md` and golden-tested, §2.8).

### 2.3 Output contract

| Property | Value |
|---|---|
| Tensor | 1 output, shape `[1, N]`, `float32` |
| Meaning | Softmax probabilities summing to ≈ 1 over `N` classes (softmax is part of the exported graph) |
| Class order | Defined only by `labels.json` (§2.5); index `i` ↔ `labels[i]` |

### 2.4 Confidence handling (decision-support only)

Flutter computes:
1. `top_label`, `top_confidence` = argmax and its probability.
2. `inconclusive = top_confidence < manifest.thresholds.min_confidence` **or** margin (`top1 − top2`) `< manifest.thresholds.min_margin`.
3. The UI shows the label only when `inconclusive=false`, always with the fixed disclaimer; when `inconclusive=true` it shows "The photo could not be screened reliably; please retake it or continue to submit the report".
4. Thresholds are **empirically chosen by Lokesh from validation data** and written to the manifest with the method used. Until measured: placeholder `null` → Flutter treats all results as inconclusive (fail-safe). **No guessed thresholds.**
5. The UI must never use the words "diagnosis", "you have…", or display confidence as medical certainty. Allowed: "Possible signs consistent with: Lumpy Skin Disease (preliminary)".
6. A screening result never blocks submitting a report.

### 2.5 Labels and mapping — `labels.json`

```json
{
  "labels_version": "1",
  "labels": [
    { "index": 0, "code": "<label_code>", "display": { "en": "…", "mr": "…", "hi": "…" }, "disease_code": "<diseases.code or null>", "is_non_disease": false }
  ]
}
```
- `code` matches `^[a-z0-9_]{1,64}$` and is what Flutter sends as `screening.top_label`.
- `disease_code` links to `diseases.code` in the DB when the label corresponds to a catalog disease; `null` otherwise. (This is informational; the backend never auto-confirms from it.)
- **Final class set is unresolved (Q-01, M-01).** The PPT emphasises Lumpy Skin Disease and says more diseases are added later. Lokesh proposes a class set **based on what public data actually supports**, with a vet advisor's review, in `docs/handoffs/lokesh-*-class-proposal.md`. A `healthy`/`normal_skin` class is permitted only if the dataset genuinely supports it and the UI wording is "no visible signs detected in this photo" — never "healthy animal".
- If no suitable dataset exists (C-07), the P0 path ships with the screening step marked **unavailable** (the report flow still works) rather than a model with unknown quality.

### 2.6 Mapping into the API

Flutter → `POST /reports` `screening` (see `API_CONTRACTS.md` §6.1):

| Manifest/inference value | API field | DB column |
|---|---|---|
| `manifest.model_version` | `model_version` | `screening_model_version` |
| argmax label `code` | `top_label` | `screening_top_label` |
| argmax probability | `top_confidence` | `screening_top_confidence` |
| computed per §2.4 | `inconclusive` | `screening_inconclusive` |
| all `[code, score]` (top 5 max) | `scores` | `screening_scores` |
| time of inference | `ran_at` | `screening_ran_at` |

### 2.7 Artifact bundle and versioning

Path: `ml/artifacts/mobilenetv3/<model_version>/` containing:
- `model.tflite`
- `labels.json`
- `manifest.json`
- `EVALUATION.md` (measured results only, §2.9)
- `golden/` — ≥ 5 test images + `expected.json` (output probabilities from the Python TFLite interpreter)

`manifest.json`:
```json
{
  "model_version": "mnv3s-YYYY.MM.PATCH",
  "architecture": "MobileNetV3-Small",
  "framework": "tensorflow-lite",
  "sha256": "<hex of model.tflite>",
  "input":  { "shape": [1,224,224,3], "dtype": "float32", "channel_order": "RGB", "value_range": [0,255], "normalization": "embedded", "resize": "center_crop_then_bilinear" },
  "output": { "shape": [1, "<N>"], "dtype": "float32", "activation": "softmax" },
  "thresholds": { "min_confidence": null, "min_margin": null, "method": "<how chosen, from validation set X>" },
  "labels_file": "labels.json",
  "training": { "dataset_names": ["<name + licence>"], "split": "<method>", "seed": 0 },
  "created_at": "…",
  "created_by": "lokesh"
}
```
(`<…>` and `null` are placeholders to be filled with real values.)
Versioning: `mnv3s-<year>.<month>.<patch>`. A change in input/output shape, preprocessing, or label order **is a breaking change** → CR + Om approval. Retraining with identical contract = non-breaking.
Hand-off: Lokesh commits to `ml/artifacts/`; **Om** copies the approved bundle into `mobile/assets/ml/` in his own PR (Lokesh never edits `mobile/`).

### 2.8 Flutter integration requirements (Om)
- Load via a TFLite Flutter plugin (candidate `tflite_flutter`; choose and verify compatibility at implementation time — don't assume a version).
- Inference in a background isolate; UI must not jank. Model loaded lazily once.
- Preprocessing exactly per §2.2. Unit-test it against `golden/` images: output probabilities must match `expected.json` within **1e-3 per class**; mismatch = integration bug, reported to Lokesh.
- Read `labels.json` and `manifest.json` at runtime — **no hard-coded labels/thresholds**.
- Store the screening result with the offline report (outbox) and include `model_version`.
- Show the disclaimer string (AGENTS.md §9) on every screening result.
- If the model fails to load: report flow continues without `screening` (null).
- Do not upload images for screening; inference stays on device.

### 2.9 Training, evaluation, and size budget (Lokesh)
- **Datasets:** Only datasets with a verifiable source and licence. Record in `ml/datasets/DATASETS.md`: name, URL, licence, collection method, class counts, known biases (e.g. lab/clean images vs field photos → domain shift). Raw data is **not** committed to Git (gitignored); a download script or instructions are.
- **Split:** stratified train/val/test **by animal/source image group where known** to avoid leakage (duplicate/near-duplicate images across splits invalidates results). Fixed seed.
- **Metrics (reported on the test split, and on the exported `.tflite`):** per-class precision/recall/F1, confusion matrix, macro-F1, plus sample counts. Report calibration (e.g. reliability plot/ECE) if thresholds are used.
- **Honest limitations section** in `EVALUATION.md`: domain shift, small dataset, no field validation (PPT S7: "nothing validated with real users"), not a diagnostic device.
- **Budget (targets, not guarantees):** model file ≤ 10 MB; inference on a mid-range Android phone ≲ 300 ms. Measured numbers only.
- **Do not claim** accuracy in the demo unless `EVALUATION.md` contains the measurement and the slide cites it with caveats.

---

## 3. XGBoost risk estimate (experiment)

**Status:** PPT S2/S5/S9 call this an *experiment* — "test whether past data can estimate outbreak risk". The honest outcome might be "insufficient data". That is an acceptable deliverable.

### 3.1 Scope limits
- **Granularity: district only.** Taluka-level or village-level predictions are **not** produced (C-08) unless a reliable taluka-level dataset is found and documented via CR.
- **Disease:** one surveillance disease first (LSD, per PPT), chosen after data discovery.
- **Horizon:** `horizon_days` ∈ {14} default. Definition of the target (e.g. "≥ 1 vet-confirmed case in the district within the next 14 days") is set by Lokesh after data discovery and recorded in `ml/xgboost/README.md`.
- UI label (non-negotiable): "Experimental estimate. Not a confirmed forecast."

### 3.2 Candidate features (use **only** those backed by a real, documented source)

| Feature | Source | Who supplies | Availability today |
|---|---|---|---|
| `confirmed_cases_7d`, `_30d`, `_prev_30d` | PashuVani DB (vet-confirmed reports per district) | Go (in request) | **Near zero history at launch** — only synthetic demo data exists; cannot train on this |
| `nearest_active_outbreak_km` | PostGIS | Go | Same limitation |
| `month_of_year`, `season` | `as_of_date` | FastAPI computes | Always |
| Historical district-level LSD cases | **Unknown** — candidates: government/NADRES publications, parliamentary replies, papers (PPT refs [5],[7],[10]) | Lokesh | **Unverified (M-11)** |
| Weather (rainfall, temperature, humidity) | **Unknown** — candidate public meteorological datasets | Lokesh | **Unverified** |
| Livestock density per district | Livestock census (public) | Lokesh bundles with model | **Unverified** |
| Vaccination coverage | e.g. NADCP/LHDCP reports | Lokesh | **Unverified**, likely not available at district granularity |
| Distance to neighbouring-district outbreaks | Derived | Lokesh/Go | Depends on historical data |

Rule: a feature is added to the schema only after Lokesh documents its source, licence, temporal/spatial resolution, and missing-rate in `ml/xgboost/FEATURES.md`. Features without a source are **not** included.

**Data reality check (go/no-go at plan task L-05):** If by hour H+8 no historical district-level case dataset with a usable licence has been found, Lokesh reports it and the XGBoost workstream stops; the dashboard shows "risk estimate unavailable — insufficient historical data". Lokesh then supports MobileNet evaluation and testing instead. **Never train on synthetic data and present it as a real model.** (If a synthetic-data pipeline demo is shown, it must be labelled as a technical demo with no predictive meaning.)

### 3.3 Missing data
- XGBoost handles `NaN`. Missing features are sent as `null`; FastAPI converts to `NaN` and lists them in `missing_features` in the response.
- If more than the configured fraction (default 50 %) of the model's features are missing for a district, the service returns that district with `risk_score: null, risk_band: null, note: "insufficient_data"` — not a guess.
- No imputation with invented values; any imputation (median, etc.) must be done at training time, documented, and bundled with the model.

### 3.4 Training and evaluation methodology
- **Temporal split** (train on earlier periods, test on later) — no random split for time-dependent data.
- Compare against simple baselines (e.g. "same as last period", prevalence). A model that does not beat the baseline is reported as such.
- Metrics appropriate to class imbalance (PR-AUC, recall at fixed precision, Brier score) with confidence intervals if sample size allows.
- Document sample counts, positive rate, date ranges, and limitations in `ml/xgboost/EVALUATION.md`.
- Risk bands: `low/medium/high` thresholds derived from validation results, stored in the model metadata, not hard-coded.

### 3.5 Model versioning
`xgb-<disease_code>-<YYYY.MM.PATCH>`; `feature_schema_version` = `fs-<n>`. Artifacts: `ml/artifacts/xgboost/<model_version>/{model.json|ubj, metadata.json, static_features.parquet|csv, EVALUATION.md}`. `metadata.json` lists features (name, dtype, source, required/optional), thresholds, training date ranges, metrics.

### 3.6 FastAPI service contract (Lokesh owns; Om consumes)

Authoritative wire format is `API_CONTRACTS.md` §12. Additional behavioural requirements:

| Endpoint | Behaviour |
|---|---|
| `GET /healthz` | 200 when the model loaded, else 503 |
| `GET /v1/model/info` | `{ model_version, feature_schema_version, features:[{name,dtype,source,required}], trained_on:{from,to}, metrics_ref }` |
| `POST /v1/risk/predict` | Validates against Pydantic schema; unknown feature names → 422; batch ≤ 50 districts; p95 latency target < 500 ms **(measured, not assumed)** |
| Errors | `{ "error": { "code","message" } }`; no stack traces |
| Auth | `X-Internal-Token` required on all `/v1/*`; 401 otherwise |
| Statelessness | No DB access. Go computes DB-derived features; FastAPI joins **static** features (census, climatology) from the model bundle by `lgd_code`. |
| Deployment | Docker image, one worker is enough; port 8001 (dev) |

### 3.7 Go backend integration (Om)
- A `risk` client in Go with 5 s timeout, one retry, circuit-break on repeated failure.
- Feature builder queries confirmed cases per district (SQL) → request. On success persists to `risk_predictions` (idempotent on the unique key).
- If the service is down: `/risk/refresh` → `503`; `/risk/districts` still serves stored rows. Dashboard handles empty/failed states.
- Triggered manually (`POST /risk/refresh`) and optionally daily. Never in the report-submission path.

---

## 4. Gemini (external AI, P2, undecided)

PPT S5 lists "Gemini API, via the backend". Justified only for **informational** assistance (e.g. translating/summarising symptom text, general husbandry guidance). Constraints if built:
- Called only from Go; the API key never reaches the apps.
- The prompt and output may **not** name a disease as the animal's diagnosis; responses carry the same disclaimer.
- No farmer PII in prompts.
- Failure must never block report submission.
- A contract for `/assist/*` will be written via CR **before** any implementation (D-10).

---

## 5. Responsibilities

| Item | Owner | Reviewer |
|---|---|---|
| Datasets discovery & licences | Lokesh | Om |
| MobileNetV3 training, export, manifest, labels, evaluation | Lokesh | Om |
| TFLite loader, preprocessing, golden-test in Flutter | Om | Lokesh |
| XGBoost data discovery, training, evaluation | Lokesh | — (go/no-go to Om) |
| FastAPI service + Docker image | Lokesh | Om |
| Go ML client and feature builder | Om | Lokesh |
| Dashboard risk panel | Soham | Om |

## 6. Open ML questions

| ID | Question | Needed by |
|---|---|---|
| ML-1 | Class set and label codes (Q-01) | G1 (labels shape), L-02 (final) |
| ML-2 | Dataset(s) and licences (M-02) | L-01 report by H+4 |
| ML-3 | Is normalisation embeddable in the TFLite graph? | G1 |
| ML-4 | Historical district data available for XGBoost? (M-11) | H+8 go/no-go |
| ML-5 | Target definition and horizon | after ML-4 |
| ML-6 | Alert thresholds are *not* ML-based in P0 (rule-based clustering); confirm | G1 |

