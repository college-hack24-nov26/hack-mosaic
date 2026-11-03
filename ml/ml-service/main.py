"""
Pashu Wani — ML FastAPI Inference Microservice
Port: 8001
Provides REST inference endpoints for XGBoost Outbreak Risk Prediction.
"""

import os
import json
from typing import Optional, List
import pandas as pd
import xgboost as xgb
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(
    title="Pashu Wani — ML Inference Service",
    description="Livestock Disease Outbreak Risk Prediction and Preliminary Screening API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_PATH = r"c:\HA_022\ml\models\outbreak_risk_xgboost.json"
SCHEMA_PATH = r"c:\HA_022\ml\models\outbreak_feature_schema.json"

booster = None
model_schema = None

@app.on_event("startup")
def load_artifacts():
    global booster, model_schema
    if os.path.exists(MODEL_PATH):
        booster = xgb.Booster()
        booster.load_model(MODEL_PATH)
        print("XGBoost Outbreak Risk model successfully loaded.")
    else:
        print(f"Warning: Model artifact not found at {MODEL_PATH}")

    if os.path.exists(SCHEMA_PATH):
        with open(SCHEMA_PATH, "r") as f:
            model_schema = json.load(f)

class OutbreakRiskRequest(BaseModel):
    x: float = Field(..., description="Longitude coordinate (e.g., 73.8567)")
    y: float = Field(..., description="Latitude coordinate (e.g., 18.5204)")
    cld: float = Field(40.0, description="Cloud cover percentage")
    dtr: float = Field(12.0, description="Diurnal temperature range")
    frs: float = Field(0.0, description="Frost day frequency")
    pet: float = Field(2.5, description="Potential evapotranspiration")
    pre: float = Field(50.0, description="Precipitation / rainfall (mm)")
    tmn: float = Field(18.0, description="Minimum temperature (C)")
    tmp: float = Field(25.0, description="Mean temperature (C)")
    tmx: float = Field(32.0, description="Maximum temperature (C)")
    vap: float = Field(16.0, description="Vapour pressure")
    wet: float = Field(5.0, description="Wet day frequency")
    elevation: float = Field(550.0, description="Elevation (meters)")
    dominant_land_cover: float = Field(2.0, description="Dominant land cover type")
    cattle_density: float = Field(15000.0, description="Estimated cattle density in area", alias="X5_Ct_2010_Da")
    buffalo_density: float = Field(3500.0, description="Estimated buffalo density in area", alias="X5_Bf_2010_Da")

    class Config:
        populate_by_name = True

class OutbreakRiskResponse(BaseModel):
    outbreak_probability: float
    risk_level: str
    risk_thresholds: dict
    model_version: str
    coordinates: dict
    disclaimer: str

@app.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    return {
        "status": "healthy",
        "service": "Pashu Wani ML Engine",
        "model_loaded": booster is not None,
        "version": "1.0.0"
    }

@app.post("/api/v1/ml/outbreak-risk", response_model=OutbreakRiskResponse)
def predict_outbreak_risk(req: OutbreakRiskRequest):
    if booster is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Outbreak prediction model is not loaded yet."
        )

    features = [
        "x", "y", "cld", "dtr", "frs", "pet", "pre",
        "tmn", "tmp", "tmx", "vap", "wet", "elevation",
        "dominant_land_cover", "X5_Ct_2010_Da", "X5_Bf_2010_Da"
    ]
    data_dict = {
        "x": req.x,
        "y": req.y,
        "cld": req.cld,
        "dtr": req.dtr,
        "frs": req.frs,
        "pet": req.pet,
        "pre": req.pre,
        "tmn": req.tmn,
        "tmp": req.tmp,
        "tmx": req.tmx,
        "vap": req.vap,
        "wet": req.wet,
        "elevation": req.elevation,
        "dominant_land_cover": req.dominant_land_cover,
        "X5_Ct_2010_Da": req.cattle_density,
        "X5_Bf_2010_Da": req.buffalo_density
    }

    df_in = pd.DataFrame([data_dict])[features]
    dmatrix = xgb.DMatrix(df_in)
    prob = float(booster.predict(dmatrix)[0])

    if prob < 0.35:
        level = "LOW"
    elif prob < 0.70:
        level = "MEDIUM"
    else:
        level = "HIGH"

    return OutbreakRiskResponse(
        outbreak_probability=round(prob, 4),
        risk_level=level,
        risk_thresholds={
            "LOW": "< 0.35",
            "MEDIUM": "0.35 - 0.70",
            "HIGH": ">= 0.70"
        },
        model_version="1.0.0",
        coordinates={"longitude": req.x, "latitude": req.y},
        disclaimer="Preliminary epidemiological risk assessment. Not a veterinary diagnostic determination."
    )

