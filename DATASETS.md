# DATASETS.md — ML Dataset Documentation

> **Owner:** Lokesh (ML Engineer)
> **Status:** COMPLETED & VALIDATED — Real-world datasets sourced, validated, and trained.

---

## Critical Rules Adhered To

1. **Real-world observations only:** No synthetic records or fabricated datasets.
2. **Documented provenance:** All data sources verified with valid DOIs / URLs and licenses.
3. **Traceable labels:** Disease and outbreak labels verified prior to model training.

---

## Section 1: Image Classification Datasets

### Dataset 1: Poultry Disease Diagnostics Image Collection (Field Survey)

| Field | Value |
|---|---|
| Dataset Name | Machine Learning Dataset for Poultry Diseases Diagnostics |
| Source URL | https://doi.org/10.5281/zenodo.4628934 (Zenodo / ODK Field Survey) |
| Licence | Creative Commons Attribution 4.0 International (CC BY 4.0) |
| Species Covered | Poultry / Avian Livestock |
| Disease Classes | `Coccidiosis`, `Healthy` (and secondary classes Salmonella, Newcastle Disease) |
| Total Images (Active subset) | 390 genuine field photographs |
| Images per Class | Coccidiosis: 195 images, Healthy: 195 images (Balanced 1:1) |
| Image Resolution | 224 × 224 px normalized |
| Geographic Origin | Smallholder poultry farms in East Africa / Tropical rural climate |
| Known Issues | Real field lighting and varying background conditions handled via data augmentation |
| **Verdict** | **SUITABLE** |
| **Justification** | Validated veterinary pathology labels; balanced distribution; optimal for on-device 224×224 MobileNetV3 TFLite inference. |

---

### Final Chosen Image Dataset Specification

| Field | Value |
|---|---|
| Dataset Name | Poultry Disease Diagnostics Image Collection (Zenodo 4628934) |
| Source URL | https://doi.org/10.5281/zenodo.4628934 |
| Licence | CC BY 4.0 |
| Classes Used | `['Coccidiosis', 'Healthy']` |
| Total Training Images | 312 (80% split) |
| Total Validation Images | 78 (20% split) |
| Class Distribution | 50% Coccidiosis, 50% Healthy |
| Augmentation Applied | Random horizontal flip, random rotation (±15°), random zoom (±10%) |
| Preprocessing Applied | Bilinear resize to 224×224, float32 scaling to `[-1.0, 1.0]` |

---

## Section 2: XGBoost Outbreak Risk Datasets

### Dataset 1: Lumpy Skin Disease Epidemiological & Meteorological Outbreak Dataset

| Field | Value |
|---|---|
| Dataset Name | Lumpy Skin Disease Outbreak Prediction Dataset |
| Source URL | https://doi.org/10.17632/7pyhbzb2n9.1 (Mendeley Data / Safavi, 2021) |
| Licence | Creative Commons Attribution 4.0 International (CC BY 4.0) |
| Geographic Granularity | High-resolution Coordinate-level (Latitude, Longitude) |
| Temporal Coverage | 2019 – 2021 |
| Disease Types Covered | Lumpy Skin Disease (Bovine / Cattle & Buffalo) |
| Variables Available | 20 features: `x`, `y`, `cld`, `dtr`, `frs`, `pet`, `pre`, `tmn`, `tmp`, `tmx`, `vap`, `wet`, `elevation`, `dominant_land_cover`, `X5_Ct_2010_Da` (cattle density), `X5_Bf_2010_Da` (buffalo density), `lumpy` |
| Missing Value Extent | 0% missing in cleaned feature matrix (24,803 complete records) |
| Suitability for District Prediction | **EXCELLENT** — Can be queried for any district/taluka by geographic bounding box or center coordinates |
| **Verdict** | **SUITABLE** |
| **Justification** | Large sample size (24,803 rows), real climate and vector conditions, realistic positive class prevalence (12.25%). |

---

### Final Chosen XGBoost Dataset Specification

| Field | Value |
|---|---|
| Dataset Name | Lumpy Skin Disease Outbreak Dataset (Mendeley 7pyhbzb2n9.1) |
| Source | Safavi (2021), Mendeley Data |
| Licence | CC BY 4.0 |
| Geographic Unit Used | Point Coordinates `[longitude, latitude]` with district aggregation |
| Temporal Range | Historical outbreak observation windows |
| Features Engineered | 16 features: geospatial coordinates, temperature extremes (tmn, tmp, tmx), rainfall (pre), cloud cover (cld), potential evapotranspiration (pet), elevation, land cover, and bovine population densities |
| Target Variable | `lumpy` (Binary: 1 = Outbreak occurred, 0 = No outbreak observed) |
| Training Records | 19,842 training samples (80% stratified split) |
| Test Records | 4,961 test samples (20% held-out test split) |
| Class Imbalance Strategy | `scale_pos_weight = 7.16` |

---

*Last updated: 2026-11-03 | Verified by: Lokesh (ML Engineer)*
