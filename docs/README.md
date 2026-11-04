# PashuVani — Technical Documentation Index

Welcome to the **PashuVani** documentation hub. All architecture specifications, API contracts, database designs, machine learning evaluation reports, development standards, security policies, and engineering review logs are organised below.

---

## 1. Documentation Directory Map

```text
docs/
├── README.md                          # This documentation index
├── project/
│   └── PROJECT_CONTEXT.md             # Domain background, requirements traceability, and assumptions
├── architecture/
│   ├── ARCHITECTURE.md                # System architecture, runtime topology, and data flows
│   ├── API_CONTRACTS.md               # Frozen REST API & internal ML service contracts (v1.0)
│   ├── DATABASE_SCHEMA.md             # PostgreSQL 16 + PostGIS 3 schema, enums, and ER diagram
│   └── DECISIONS.md                   # Architectural Decision Records (D-01 through D-29)
├── ai-ml/
│   ├── ML_INTEGRATION.md              # On-device TFLite & FastAPI XGBoost integration specification
│   ├── DATASETS.md                    # Public dataset provenance, DOIs, licences, and preprocessing
│   └── MODEL_EVALUATION.md            # Confusion matrices, ROC-AUC, precision/recall, and caveats
├── development/
│   ├── DEVELOPMENT_PLAN.md            # P0 / P1 / P2 engineering roadmap and acceptance criteria
│   ├── CODING_STANDARDS.md            # Go, Flutter/Dart, React/TypeScript, and Python conventions
│   ├── TESTING_STRATEGY.md            # Test pyramid, golden parity suite, and Gate G2 checklist
│   └── TEAM_WORKFLOW.md               # Module ownership matrix, development gates, and Git rules
├── security/
│   └── SECURITY.md                    # JWT rotation, RBAC scoping, farmer PII & consent safeguards
├── assets/
│   ├── screenshots/                   # Real mobile & dashboard screenshots
│   ├── diagrams/                      # Architecture and workflow diagrams
│   └── demo/                          # Demonstration collateral
├── reviews/                           # Gate G1 contract reviews & code quality audits
│   ├── G1_ARCHITECTURE_REVIEW.md
│   ├── MOBILE_QUALITY_REVIEW.md
│   ├── om-contract-review.md
│   ├── lokesh-contract-review.md
│   └── soham-contract-review.md
├── handoffs/                          # Inter-module engineering handoff notes
│   ├── OM_BACKEND_HANDOFF.md
│   └── OM_VETERINARIAN_MODULE_HANDOFF.md
└── change-requests/                   # Formal contract change requests
```

---

## 2. Quick Links by Audience

| Audience | Recommended Reading Order |
|---|---|
| **Hackathon Judges & Evaluators** | 1. [Root README](../README.md)<br>2. [Project Context & Traceability](project/PROJECT_CONTEXT.md)<br>3. [System Architecture](architecture/ARCHITECTURE.md)<br>4. [Model Evaluation & Metrics](ai-ml/MODEL_EVALUATION.md) |
| **Backend & Mobile Engineers** | 1. [API Contracts](architecture/API_CONTRACTS.md)<br>2. [Database Schema (PostGIS)](architecture/DATABASE_SCHEMA.md)<br>3. [Backend Handoff](handoffs/OM_BACKEND_HANDOFF.md)<br>4. [Veterinarian Module Handoff](handoffs/OM_VETERINARIAN_MODULE_HANDOFF.md) |
| **Machine Learning Engineers** | 1. [ML Integration Contract](ai-ml/ML_INTEGRATION.md)<br>2. [Dataset Provenance](ai-ml/DATASETS.md)<br>3. [Model Evaluation Report](ai-ml/MODEL_EVALUATION.md) |
| **Dashboard & GIS Engineers** | 1. [API Contracts](architecture/API_CONTRACTS.md)<br>2. [Security & PII Rules](security/SECURITY.md)<br>3. [Coding Standards](development/CODING_STANDARDS.md) |
