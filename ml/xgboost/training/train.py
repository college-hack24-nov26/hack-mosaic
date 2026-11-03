"""
Pashu Wani — XGBoost Livestock Disease Outbreak Risk Prediction Pipeline
Trains on genuine epidemiological & meteorological outbreak data.
"""

import os
import json
import joblib
import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    classification_report,
    roc_auc_score,
    confusion_matrix,
    brier_score_loss,
    accuracy_score
)

def train_outbreak_model():
    csv_path = r"c:\HA_022\ml\datasets\raw\lumpy_skin_disease_outbreak.csv"
    models_dir = r"c:\HA_022\ml\models"
    reports_dir = r"c:\HA_022\ml\reports"
    os.makedirs(models_dir, exist_ok=True)
    os.makedirs(reports_dir, exist_ok=True)

    print(f"Loading outbreak dataset from {csv_path}...")
    df = pd.read_csv(csv_path)

    # Feature definitions
    # Geospatial: x (longitude), y (latitude), elevation, dominant_land_cover
    # Climate/Meteorological: cld, dtr, frs, pet, pre, tmn, tmp, tmx, vap, wet
    # Animal density: X5_Ct_2010_Da (Cattle density), X5_Bf_2010_Da (Buffalo density)
    feature_cols = [
        "x", "y", "cld", "dtr", "frs", "pet", "pre",
        "tmn", "tmp", "tmx", "vap", "wet", "elevation",
        "dominant_land_cover", "X5_Ct_2010_Da", "X5_Bf_2010_Da"
    ]
    target_col = "lumpy"

    # Clean & convert numeric types
    for col in feature_cols + [target_col]:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df = df.dropna(subset=feature_cols + [target_col])
    print(f"Valid dataset records after cleaning: {len(df)}")

    X = df[feature_cols]
    y = df[target_col].astype(int)

    # Calculate class weight ratio for scale_pos_weight
    neg_count = (y == 0).sum()
    pos_count = (y == 1).sum()
    scale_pos = neg_count / max(1, pos_count)
    print(f"Target distribution — Negative: {neg_count}, Positive (Outbreak): {pos_count}, Scale_pos_weight: {scale_pos:.2f}")

    # Stratified Train/Test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Train XGBoost Classifier
    print("Training XGBoost Classifier...")
    model = xgb.XGBClassifier(
        n_estimators=300,
        learning_rate=0.05,
        max_depth=5,
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=scale_pos,
        eval_metric=["logloss", "auc"],
        random_state=42
    )

    model.fit(
        X_train, y_train,
        eval_set=[(X_train, y_train), (X_test, y_test)],
        verbose=False
    )

    # Predictions & Probabilities
    y_pred_proba = model.predict_proba(X_test)[:, 1]
    y_pred = (y_pred_proba >= 0.5).astype(int)

    # Metrics
    auc = roc_auc_score(y_test, y_pred_proba)
    acc = accuracy_score(y_test, y_pred)
    brier = brier_score_loss(y_test, y_pred_proba)
    cm = confusion_matrix(y_test, y_pred).tolist()
    clf_report = classification_report(y_test, y_pred, output_dict=True)
    clf_report_text = classification_report(y_test, y_pred)

    print("\n--- Test Set Evaluation ---")
    print(f"ROC-AUC Score: {auc:.4f}")
    print(f"Accuracy: {acc:.4f}")
    print(f"Brier Score: {brier:.4f}")
    print(clf_report_text)

    # Save evaluation report
    report_file = os.path.join(reports_dir, "xgboost_evaluation.txt")
    with open(report_file, "w") as f:
        f.write(f"ROC-AUC Score: {auc:.4f}\n")
        f.write(f"Accuracy: {acc:.4f}\n")
        f.write(f"Brier Score: {brier:.4f}\n\n")
        f.write(clf_report_text)
        f.write(f"\nConfusion Matrix:\n{cm}\n")

    # Save model artifact
    model_path = os.path.join(models_dir, "outbreak_risk_xgboost.json")
    model.save_model(model_path)
    print(f"XGBoost model saved to: {model_path}")

    # Feature importance
    importance = model.get_booster().get_score(importance_type="gain")
    sorted_importance = dict(sorted(importance.items(), key=lambda item: item[1], reverse=True))

    # Feature schema & metadata
    schema = {
        "model_name": "PashuWani_Outbreak_Risk_XGBoost",
        "version": "1.0.0",
        "features": [
            {"name": "x", "type": "float", "description": "Longitude coordinate"},
            {"name": "y", "type": "float", "description": "Latitude coordinate"},
            {"name": "cld", "type": "float", "description": "Cloud cover percentage"},
            {"name": "dtr", "type": "float", "description": "Diurnal temperature range"},
            {"name": "frs", "type": "float", "description": "Frost day frequency"},
            {"name": "pet", "type": "float", "description": "Potential evapotranspiration"},
            {"name": "pre", "type": "float", "description": "Precipitation / rainfall (mm)"},
            {"name": "tmn", "type": "float", "description": "Minimum temperature (C)"},
            {"name": "tmp", "type": "float", "description": "Mean temperature (C)"},
            {"name": "tmx", "type": "float", "description": "Maximum temperature (C)"},
            {"name": "vap", "type": "float", "description": "Vapour pressure"},
            {"name": "wet", "type": "float", "description": "Wet day frequency"},
            {"name": "elevation", "type": "float", "description": "Elevation above sea level (m)"},
            {"name": "dominant_land_cover", "type": "float", "description": "Land cover classification category"},
            {"name": "X5_Ct_2010_Da", "type": "float", "description": "Cattle population density indicator"},
            {"name": "X5_Bf_2010_Da", "type": "float", "description": "Buffalo population density indicator"}
        ],
        "target": "outbreak_probability",
        "evaluation": {
            "roc_auc": auc,
            "accuracy": acc,
            "brier_score": brier,
            "classification_report": clf_report,
            "confusion_matrix": cm
        },
        "feature_importance_gain": sorted_importance,
        "risk_thresholds": {
            "LOW": "< 0.35",
            "MEDIUM": "0.35 - 0.70",
            "HIGH": ">= 0.70"
        },
        "disclaimer": "Experimental epidemiological outbreak estimation. Not an official regulatory declaration."
    }

    schema_path = os.path.join(models_dir, "outbreak_feature_schema.json")
    with open(schema_path, "w") as f:
        json.dump(schema, f, indent=2)
    print(f"Schema and metadata saved to: {schema_path}")

if __name__ == "__main__":
    train_outbreak_model()

