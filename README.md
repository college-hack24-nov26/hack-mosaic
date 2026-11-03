# PashuVani (पशुवाणी)

> **Offline-Capable Livestock Health Reporting & Disease Surveillance Platform**  
> *Developed for College of Engineering Phaltan Hackathon 2K26 — Theme: Healthcare*

---

## 1. Project Overview

PashuVani addresses a critical veterinary healthcare gap in rural Maharashtra (over 1.4 crore cattle), where over 65% of government veterinary posts are vacant, clinics are distant, and livestock diseases (such as Lumpy Skin Disease and Foot & Mouth Disease) spread rapidly between villages before authorities can intervene.

PashuVani connects farmers, veterinarians, and animal-husbandry officers into a unified digital workflow:

1. **Farmer Reports (Offline-First):** Farmers record symptoms and take photos of sick cattle on a Flutter mobile app. Works completely offline in the field; syncs when cellular connectivity returns.
2. **On-Device Screening:** An embedded MobileNetV3-Small TensorFlow Lite model performs preliminary image screening directly on the phone. It is explicitly decision support, **not a clinical diagnosis**.
3. **Veterinarian Verification:** Field veterinarians review submitted reports, inspect photos and screening observations, and submit authoritative decisions: **confirmed**, **rejected**, or **flagged**.
4. **Surveillance & Targeted Alerts:** Confirmed cases are automatically clustered geographically using PostGIS DBSCAN. Officers view live district/taluka maps on a React dashboard and dispatch targeted warnings to consenting nearby farmers before disease spreads.
5. **Offline QR Animal Records:** Veterinarians scan a cryptographically signed QR code on the farmer's phone to review the animal's vaccination and treatment history without internet access.

---

## 2. Technology Stack

- **Mobile:** Flutter (Dart, Material 3, Drift/SQLite offline database, TFLite Flutter runtime).
- **Backend:** Go (Gin web framework, `pgx/v5`, JWT authentication, modular monolith architecture).
- **Database:** PostgreSQL 16 with PostGIS spatial extensions.
- **Government Dashboard:** React 18, TypeScript, Vite, Tailwind CSS, Leaflet maps.
- **Machine Learning:** MobileNetV3-Small (TFLite for on-device vision), XGBoost (experimental district risk estimation via Python FastAPI).
- **Deployment:** Docker & Docker Compose.

---

## 3. Repository Structure

```
ha022/
├── AGENTS.md               # Instructions for AI coding agents & gate status
├── PROJECT_CONTEXT.md      # Problem statement, requirements traceability & PPT alignment
├── ARCHITECTURE.md         # Component interactions, data flows & offline sync architecture
├── DATABASE_SCHEMA.md      # PostgreSQL + PostGIS schema design & spatial queries
├── API_CONTRACTS.md        # Authoritative REST API contracts & error schemas
├── TEAM_WORKFLOW.md        # Team ownership, gate protocols & Git rules
├── ML_INTEGRATION.md       # MobileNetV3 TFLite & XGBoost integration specifications
├── DEVELOPMENT_PLAN.md     # Prioritised P0/P1/P2 development task breakdown
├── CODING_STANDARDS.md     # Code style & conventions across Go, Dart, TypeScript, Python
├── TESTING_STRATEGY.md     # Test pyramids, golden tests & end-to-end demo checklist
├── SECURITY.md             # Authentication, RBAC, PII privacy & consent policies
├── DECISIONS.md            # Architectural Decision Records (ADRs)
│
├── agents/                 # Instructions for AI agents (Om, Lokesh, Soham)
├── docs/                   # Contract reviews, handoffs, and change requests
├── backend/                # Go API backend
├── mobile/                 # Flutter mobile app
├── dashboard/              # React + TypeScript government dashboard
├── ml/                     # ML training, TFLite export, and FastAPI service
└── deploy/                 # Docker Compose & environment templates
```

---

## 4. Current Status: Gate G0 / G1 (Initialization Phase)

```
CURRENT PHASE:  0 — INITIALIZATION
CODING STATUS:  LOCKED (No feature implementation until Gate G1 sign-off)
NEXT GATE:      G1 — Contract Freeze (3 Sign-offs on API_CONTRACTS & DATABASE_SCHEMA)
```

Per team governance, no production code may be written until Om approves the project foundation (G0) and all three module owners complete their contract reviews in `docs/reviews/` (G1).

---

## 5. Team Ownership

- **Om Rajput (Team Lead):** System Architecture, Go Backend API, PostGIS setup, Flutter Mobile App, TFLite Integration, Final Integration.
- **Lokesh Patil (ML Engineer):** MobileNetV3 Dataset Discovery, Model Training, TFLite Export, XGBoost Outbreak Risk Model, FastAPI Service.
- **Soham Pawar (Dashboard Engineer):** React/TypeScript Dashboard, Leaflet GIS Mapping, Vet Verification Interface, Alert Dispatcher.
- **Khushi Shinde:** Cloud Deployment Support & Presentation Delivery.
- **Prof. Bhagashree Thackary:** Faculty Mentor (COEP Phaltan).

---

## 6. Local Development Setup (Post-G1)

### Prerequisites
- Docker & Docker Compose
- Go 1.22+
- Flutter 3.22+ / Dart 3.x
- Node.js 20 LTS & npm
- Python 3.10+

### Quick Start with Docker
```bash
# 1. Clone repository & enter directory
cd ha022

# 2. Copy environment template
cp deploy/.env.example deploy/.env

# 3. Start PostgreSQL with PostGIS, Go API, and ML Service
docker compose -f deploy/docker-compose.yml up -d
```
