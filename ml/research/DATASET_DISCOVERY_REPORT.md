# PASHU WANI — PHASE 1 & 2: DATASET DISCOVERY & VALIDATION REPORT

## 1. Government Platforms & Public Data Investigation

### data.gov.in & api.data.gov.in
- **Investigation:** Analyzed datasets related to livestock population (20th Livestock Census, DAHD) and animal disease outbreaks reported under NADRS (National Animal Disease Reporting System).
- **Finding:** Macro-level state-wise and species-wise annual statistics are available (attacks/deaths for Foot and Mouth Disease, Black Quarter, Anthrax, PPR). However, micro-level geospatial coordinates (latitude/longitude) per outbreak are restricted or aggregated at annual state/district totals.
- **API Status:** Requires individual developer API keys from `data.gov.in`. Public catalog REST feeds provide historical counts.

### NJDG (National Judicial Data Grid)
- **Verdict:** Unrelated to livestock epidemiology. Excluded per Phase 1 instructions.

### eDistrict & NDHM / UIDAI
- **Verdict:** Human health records (NDHM) and administrative certificates (eDistrict) do not contain animal disease pathology. Excluded.

---

## 2. Real Datasets Discovered and Validated

### Dataset 1: Geospatial & Meteorological Livestock Disease Outbreak Dataset
- **Dataset Name:** Lumpy Skin Disease Outbreak Dataset (Epidemiological & Meteorological)
- **Source / DOI:** Mendeley Data (`10.17632/7pyhbzb2n9.1`) / Safavi (2021)
- **Species:** Bovine / Cattle & Buffalo
- **Target Variable:** `lumpy` (1 = Outbreak occurred, 0 = No outbreak observed)
- **Sample Count:** **24,803 structured records**
- **Class Distribution:** 3,039 positive outbreak events, 21,764 negative observations (~12.2% positive prevalence).
- **Features (20 columns):**
  - Geospatial: `x` (Longitude), `y` (Latitude), `elevation`, `dominant_land_cover`
  - Temporal: `reportingDate`
  - Meteorological / Climate:
    - `tmp` (Mean temperature)
    - `tmn` (Minimum temperature)
    - `tmx` (Maximum temperature)
    - `pre` (Precipitation / Rainfall)
    - `pet` (Potential Evapotranspiration)
    - `vap` (Vapour pressure)
    - `cld` (Cloud cover)
    - `wet` (Wet day frequency)
    - `dtr` (Diurnal temperature range)
    - `frs` (Frost day frequency)
  - Livestock density indicators: `X5_Ct_2010_Da` (Cattle density), `X5_Bf_2010_Da` (Buffalo density)
- **Suitability for XGBoost:** **EXCELLENT**. Real-world ground truth observations with exact environmental and geographical features directly matching the hackathon objectives.
- **Local Path:** `c:\HA_022\ml\datasets\raw\lumpy_skin_disease_outbreak.csv`

---

### Dataset 2: Livestock Disease Computer Vision Image Dataset
- **Dataset Name:** Poultry Diseases Diagnostics Image Dataset (PCR-Validated)
- **Source / DOI:** Zenodo (`10.5281/zenodo.4628934`) / ODK Field Survey
- **Species:** Poultry / Avian Livestock (major rural livestock in Maharashtra & India)
- **Disease Categories:**
  - `Coccidiosis` (195 images)
  - `Healthy` (195 images)
  - Additional classes: `Salmonella`, `Newcastle Disease` (accessible via full Zenodo archive)
- **Image Properties:** Real field photographs from smallholder livestock farms.
- **Suitability for MobileNetV3-Small:** **EXCELLENT**. High quality, clean binary/multiclass separation suitable for 224x224 transfer learning and TFLite edge deployment.
- **Local Path:** `c:\HA_022\ml\datasets\raw\poultry_diseases\Chicken-fecal-images`

---

## 3. Next Implementation Steps
1. MobileNetV3-Small pipeline in `c:\HA_022\ml\mobilenetv3\` for offline TFLite export.
2. XGBoost risk predictor pipeline in `c:\HA_022\ml\xgboost\` using the 24,803 outbreak records.
3. FastAPI microservice in `c:\HA_022\ml\fastapi\` for real-time risk scoring.

