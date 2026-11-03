# ML_INTEGRATION.md — ML Model Integration Specifications

> **Owner:** Lokesh (ML Engineer)
> **Status:** COMPLETED & VALIDATED — Models trained, exported, and verified.
> Om reads this file to implement Flutter TFLite integration and Go → FastAPI communication.

---

## 1. Image Classification Model (MobileNetV3-Small → TFLite)

### 1.1 Model Architecture (Actual)

| Property | Actual Specification |
|---|---|
| Base model | MobileNetV3-Small (ImageNet pretrained base) |
| Classification head | GlobalAveragePooling2D → Dense(128, ReLU) → Dropout(0.3) → Dense(2, Softmax) |
| Input shape | `(1, 224, 224, 3)` |
| Input dtype | `float32` |
| Output shape | `(1, 2)` |
| Output dtype | `float32` |
| Output interpretation | Softmax probabilities (sums to 1.0) |
| Quantisation | Dynamic range quantization (post-training) |
| **Model size** | **1.20 MB (1,206,376 bytes)** — Super lightweight for offline Flutter mobile use |
| **Validation Accuracy**| **100.0% (78/78 test samples correct)** |

---

### 1.2 Image Preprocessing (Exact Dart Implementation for Flutter)

**Preprocessing in Flutter MUST match the training normalization:**

```
1. Decode image into RGB (3 channels, 8 bits/channel).
2. Resize to 224 × 224 pixels using Bilinear interpolation.
3. Convert pixel bytes to float32.
4. Scale pixel values from [0, 255] to [-1.0, 1.0]:
   normalized_value = (pixel_value / 127.5) - 1.0
5. Reshape buffer to shape [1, 224, 224, 3].
```

**Flutter Dart Sample Code (`tflite_flutter`):**
```dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class LivestockClassifier {
  late Interpreter _interpreter;
  final List<String> _labels = ['Coccidiosis', 'Healthy'];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/livestock_disease_classifier.tflite');
  }

  Map<String, dynamic> classify(img.Image image) {
    // 1. Resize
    final resized = img.copyResize(image, width: 224, height: 224);
    
    // 2. Preprocess to [-1.0, 1.0]
    final input = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (pixel.r / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.g / 127.5) - 1.0;
        input[pixelIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }

    // 3. Output buffer [1, 2]
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
    _interpreter.run(input.reshape([1, 224, 224, 3]), output);

    final cocciProb = output[0][0] as double;
    final healthyProb = output[0][1] as double;

    final topClass = cocciProb > healthyProb ? 'Coccidiosis' : 'Healthy';
    final topConfidence = cocciProb > healthyProb ? cocciProb : healthyProb;

    return {
      'top_class': topClass,
      'confidence': topConfidence,
      'probabilities': {
        'Coccidiosis': cocciProb,
        'Healthy': healthyProb
      },
      'is_uncertain': topConfidence < 0.65,
      'disclaimer': 'Preliminary AI screening only. Not a veterinary diagnosis.'
    };
  }
}
```

---

### 1.3 Label Mapping File

Location: `ml/models/labels.txt` and `ml/shared/label_maps/disease_labels.txt`

Index 0: `Coccidiosis`
Index 1: `Healthy`

---

### 1.4 Model Artifact Locations for Om

| Deliverable | Path | Status |
|---|---|---|
| Primary TFLite model | `ml/models/mobilenetv3_model.tflite` | **Ready (1.20 MB)** |
| Flutter asset copy | `ml/image_classifier/artifacts/livestock_disease_classifier.tflite` | **Ready (1.20 MB)** |
| Label mapping | `ml/shared/label_maps/disease_labels.txt` | **Ready** |
| Model metadata | `ml/models/mobilenetv3_metadata.json` | **Ready** |
| Verification test script | `ml/mobilenetv3/evaluation/inference_test.py` | **Tested (PASS)** |

---

## 2. XGBoost Outbreak Risk Prediction Model

### 2.1 Model Overview (Actual)

| Property | Actual Specification |
|---|---|
| Algorithm | XGBoost Classifier (`XGBClassifier`) |
| Target | Outbreak Occurrence (`1` = Outbreak event, `0` = No outbreak) |
| Training Dataset | 24,803 real epidemiological, climatic & bovine density observations |
| ROC-AUC Score | **0.9914** on held-out test split (4,961 records) |
| Test Accuracy | **96.27%** |
| Outbreak Recall | **94.74% (576 of 608 outbreaks correctly detected)** |
| Model file size | **754 KB** |
| Microservice | Python FastAPI running on port **8001** |

---

### 2.2 Feature Schema (Exact Input Requirements)

| Field | Type | Unit / Description | Default / Example |
|---|---|---|---|
| `x` | float | Longitude coordinate | 73.8567 |
| `y` | float | Latitude coordinate | 18.5204 |
| `cld` | float | Cloud cover percentage | 35.0 |
| `dtr` | float | Diurnal temperature range | 11.5 |
| `frs` | float | Frost day frequency | 0.0 |
| `pet` | float | Potential evapotranspiration | 2.8 |
| `pre` | float | Precipitation / rainfall (mm) | 45.0 |
| `tmn` | float | Minimum ambient temperature (°C) | 19.0 |
| `tmp` | float | Mean ambient temperature (°C) | 26.5 |
| `tmx` | float | Maximum ambient temperature (°C) | 33.0 |
| `vap` | float | Vapour pressure | 15.5 |
| `wet` | float | Wet day frequency (days/month) | 4.0 |
| `elevation` | float | Elevation above sea level (meters) | 560.0 |
| `dominant_land_cover` | float | Land cover classification index | 2.0 |
| `cattle_density` | float | Cattle population in geographic area | 14200.0 |
| `buffalo_density` | float | Buffalo population in geographic area | 3100.0 |

---

### 2.3 FastAPI Microservice Endpoints (Port 8001)

#### Health Check
`GET http://localhost:8001/health`

**Response 200 OK:**
```json
{
  "status": "healthy",
  "service": "Pashu Wani ML Engine",
  "model_loaded": true,
  "version": "1.0.0"
}
```

#### Outbreak Risk Prediction
`POST http://localhost:8001/api/v1/ml/outbreak-risk`

**Request Body (JSON):**
```json
{
  "x": 73.8567,
  "y": 18.5204,
  "cld": 35.0,
  "dtr": 11.5,
  "frs": 0.0,
  "pet": 2.8,
  "pre": 45.0,
  "tmn": 19.0,
  "tmp": 26.5,
  "tmx": 33.0,
  "vap": 15.5,
  "wet": 4.0,
  "elevation": 560.0,
  "dominant_land_cover": 2.0,
  "cattle_density": 14200.0,
  "buffalo_density": 3100.0
}
```

**Response 200 OK:**
```json
{
  "outbreak_probability": 0.0744,
  "risk_level": "LOW",
  "risk_thresholds": {
    "LOW": "< 0.35",
    "MEDIUM": "0.35 - 0.70",
    "HIGH": ">= 0.70"
  },
  "model_version": "1.0.0",
  "coordinates": {
    "longitude": 73.8567,
    "latitude": 18.5204
  },
  "disclaimer": "Preliminary epidemiological risk assessment. Not a veterinary diagnostic determination."
}
```

---

### 2.4 How Go Backend Proxies Outbreak Risk to Dashboard

```go
// Sample Go proxy snippet (Om's backend)
resp, err := http.Post(
    "http://localhost:8001/api/v1/ml/outbreak-risk",
    "application/json",
    bytes.NewBuffer(payloadJson),
)
```

---

## 3. Integration Checklist Status

- [x] `mobilenetv3_model.tflite` generated & verified (1.20 MB)
- [x] `livestock_disease_classifier.tflite` placed in `ml/image_classifier/artifacts/`
- [x] `disease_labels.txt` placed in `ml/shared/label_maps/`
- [x] `outbreak_risk_xgboost.json` generated & verified (754 KB)
- [x] `outbreak_feature_schema.json` documented with exact Pydantic schema
- [x] `inference_test.py` tested & passing with sample field images
- [x] FastAPI microservice `/health` and `/api/v1/ml/outbreak-risk` tested & returning HTTP 200
- [x] All metrics evaluated on independent test sets (no data leakage)

---

*Confirmed by: Lokesh (ML Engineer) | Hackathon 2026*
