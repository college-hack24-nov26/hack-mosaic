# docs/reviews/lokesh-contract-review.md — Lokesh's Gate G1 Contract Review

**Module:** Machine Learning, Vision Model (TFLite) & Outbreak Risk Service (FastAPI)  
**Reviewer:** Lokesh Patil (Senior ML Engineer)  
**Date:** 2026-11-03  
**Status:** Review Complete — Feasibility Confirmed with Strict Data Guardrails

---

## 1. Module Implementation Readiness Statement

> **Statement:** I can implement my P0 tasks (`L-01` through `L-04`) and exploratory P2 tasks (`L-05` through `L-07`) from these contracts **as written, provided the dataset feasibility checkpoint and fallback protocols documented below are accepted**.

---

## 2. Issues & Proposed Contract Corrections

### BLOCKER-02: Public Dataset Availability & Anti-Hallucination Fallback Protocol
- **Affected File & Section:** `ML_INTEGRATION.md` §2.5, §2.9 and `DEVELOPMENT_PLAN.md` Task `L-01`.
- **Problem:** Slide 7 of `coepphaltan.pdf` states: *"Field interviews with vets and farmers; collect and label photo data ... Months 1–2 if supported ... nothing validated with real users yet."* Real labelled farm photographs from Maharashtra do not exist in the repo. If open-access cattle skin disease datasets (e.g. Kaggle LSD, Mendeley Data) are unverified or cannot be downloaded during the hackathon, training code could fail or an AI agent could be pressured to fake accuracy results.
- **Proposed Correction:** 
  1. Add an explicit **Fallback Pipeline Rule** in `ML_INTEGRATION.md`: If public dataset download fails or sample count per class is < 50, Lokesh must export a synthetically initialized MobileNetV3-Small TFLite graph with valid input/output tensors (`[1, 224, 224, 3]` -> `[1, N]`) and document it openly in `EVALUATION.md` as an architectural demonstration artifact.
  2. The mobile client will receive valid binary `.tflite` files and test images, allowing end-to-end integration without fabricating diagnostic accuracy numbers.
- **Responsible Developer:** Lokesh.

### HIGH-03: Embedded Image Normalization in TFLite Graph
- **Affected File & Section:** `ML_INTEGRATION.md` §2.2 and `ARCHITECTURE.md` §2.
- **Problem:** Mobile image preprocessing discrepancies between Python (e.g., standard Keras MobileNet preprocessing: divide by 127.5, subtract 1.0) and Dart in Flutter often cause silent accuracy degradation.
- **Proposed Correction:** The exported Keras model will include a `tf.keras.layers.Rescaling(scale=1./127.5, offset=-1)` layer directly at the input of the graph. Flutter will pass raw RGB bytes in the range `[0.0, 255.0]`. This eliminates Dart mathematical discrepancy and guarantees cross-platform parity.
- **Responsible Developer:** Lokesh.

### MEDIUM-02: Strict District-Level Boundary for XGBoost (Zero Taluka Hallucination)
- **Affected File & Section:** `ML_INTEGRATION.md` §3.1 and `API_CONTRACTS.md` §12.
- **Problem:** Government officials on the dashboard may request taluka-level or village-level outbreak risk forecasts. Reliable historical epidemiological case data for cattle diseases in Maharashtra is only published at state or district levels (via ICAR-NIVEDI NADRES or parliamentary reports).
- **Proposed Correction:** Maintain the strict invariant: `POST /v1/risk/predict` accepts and returns data indexed strictly by `district_id`. Any request for taluka-level risk estimates will return `422 VALIDATION_ERROR` with message `"granularity_not_supported"`.
- **Responsible Developer:** Lokesh (ML) & Soham (Dashboard UI).

---

## 3. Fields & Endpoints Needed vs. Unnecessary

- **Confirmed Interfaces:**
  - `POST /v1/risk/predict` internal schema in `API_CONTRACTS.md` §12 is complete and verified.
  - Golden test file structure in `ml/artifacts/mobilenetv3/<version>/golden/` with `expected.json` is confirmed.
- **Unnecessary Fields:**
  - Real-time weather API integration in P0/P1 is unnecessary and should remain deferred; use static seasonal indicators (`month_of_year`, `season`).

