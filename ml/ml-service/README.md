# ml-service — FastAPI Outbreak Risk Prediction Service

> **Owner:** Lokesh (ML Engineer)
> **Port:** 8001
> **Branch:** lokesh-ai-ml

---

## Overview

This FastAPI service exposes the XGBoost outbreak risk prediction model to the Go backend.

The Go backend calls `POST /api/v1/ml/outbreak-risk` internally (port 8001).
This service is NOT directly internet-facing.

---

## Setup

```bash
cd ml/ml-service
python -m venv .venv
.venv\Scripts\activate    # Windows
source .venv/bin/activate # Linux/Mac
pip install -r requirements.txt
```

Create your `.env` from the template:
```bash
cp .env.example .env
# Edit .env with your actual values
```

---

## Running the Service

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check — confirms model is loaded |
| `POST` | `/api/v1/ml/outbreak-risk` | XGBoost outbreak risk prediction |
| `POST` | `/api/v1/ml/gemini-screen` | Gemini multimodal screening (P2) |

---

## Testing

```bash
# Health check
curl http://localhost:8001/health

# Prediction
curl -X POST http://localhost:8001/api/v1/ml/outbreak-risk \
  -H "Content-Type: application/json" \
  -d '{"district_id":"pune","month":11,"cases_last_30_days":10,"cases_last_90_days":35}'
```

---

## Model Artifacts Required

Place trained model artifacts in `ml/outbreak_predictor/artifacts/` before starting the service:
- `outbreak_risk_model.json` — trained XGBoost model
- `preprocessor.pkl` — sklearn preprocessing pipeline
- `feature_schema.json` — feature definitions

The service will fail to start with a clear error if artifacts are missing.

---

*Lokesh fills in actual setup instructions after the service is implemented.*

