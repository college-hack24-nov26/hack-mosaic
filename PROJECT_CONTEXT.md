# PROJECT_CONTEXT.md — PashuVani Project Context & Requirements

**Version:** 0.1-draft · **Date:** 2026-11-03 · **Status:** Pending Om's approval (Gate G0)
**Primary source:** `coepphaltan.pdf` — "PashuVani", College of Engineering Phaltan, Hackathon 2K26 (13 pages; slides labelled "1 of 10" … "10 of 10" plus *Impact* and *Research* pages). Both attached PDFs are byte-identical.
**Repository state at inspection:** completely empty, not a Git repository, no code, no docs, no dependencies.

> Naming: the PPT spells the product **PashuVani**. The brief says "Pashu Wani". These docs use **PashuVani**; confirm in `DECISIONS.md` D-01.

Legend: ✅ confirmed in PPT · 🟡 from team brief (Om's prompt), not in PPT · ⚠️ assumption/recommendation (needs approval)

---

## 1. Project understanding

**Problem (PPT S1).** Farmers in Maharashtra (~1.4 crore cattle) often cannot reach a vet in time; 3,072 of 4,685 government vet posts are vacant (2025). Late treatment lets disease spread — Lumpy Skin Disease (LSD) killed 28,227 cattle in Maharashtra in 2022 and reached 280 villages in ~5 weeks. Farmers, vets and authorities lack a shared, location-based view of case clusters.

**Solution (PPT S2).** An offline-first mobile app and web dashboard linking farmers, vets and animal-health officers:

1. Farmer reports a sick animal by **photo, symptoms (voice or text) and GPS**, in Marathi/Hindi/English.
2. The phone gives a **preliminary on-device screening (not a diagnosis)**, even offline; the report syncs when signal returns.
3. A **vet confirms, flags or rejects** the case (checking the animal's record, accessible offline via **QR**).
4. **Confirmed** cases appear on an **officer's district map**; clusters are flagged.
5. **Targeted warnings** go to nearby farms when set criteria are met; farmer **consent** before alerts.

**Objective (PPT S2).** A working demonstration of the full chain (report → vet confirmation → officer map → warning) with offline screening and QR animal records. Additionally *test whether past data can estimate outbreak risk* (explicitly an experiment).

**Users.** Dairy/cattle farmers (Phaltan–Satara belt first), para-vets and vets, district and state animal-husbandry officers.

**Build window (PPT S7).** 24-hour build on **3–4 Nov 2026**; demo of the core chain with offline screening and QR records. Maturity today: TRL 2–3; *nothing validated with real users*.

**Core invariant (PPT S4, S5, S10).** *Screening is decision support only. A vet confirms every case. Only confirmed cases trigger alerts.*

## 2. Team and ownership (per brief)

| Dev | Role | Modules |
|---|---|---|
| Om | Lead | Architecture, Flutter app, Go backend, API/DB contracts, TFLite integration, auth, integration, deployment |
| Lokesh | ML | MobileNetV3 train/eval/export, XGBoost, datasets, FastAPI ML service |
| Soham | Dashboard | React/TS dashboard, Leaflet, filtering, analytics, alerts UI, backend integration |

See contradiction C-02 below: the PPT assigns these roles differently.

## 3. Requirements traceability

| ID | Requirement | Source | Status | Module | Pri | Tasks |
|---|---|---|---|---|---|---|
| R-01 | Farmer reports a sick animal with photo, symptoms, GPS location | S2, S4 | ✅ | Flutter + Go | P0 | O-09..O-11, O-06 |
| R-02 | Symptom input by text (always available) | S5 | ✅ | Flutter | P0 | O-11 |
| R-03 | Symptom input by voice (Marathi planned; may need internet) | S2, S5, S9 | ✅ | Flutter | P2 | O-21 |
| R-04 | UI/report language: Marathi, Hindi, English | S2 | ✅ | Flutter, Dashboard | P0 (en, mr) / P1 (hi) | O-09, S-10 |
| R-05 | Offline: report, screen, save records; sync when signal returns | S2, S4, S5 | ✅ | Flutter + Go | P0 | O-10, O-11 |
| R-06 | On-device preliminary screening, TFLite + MobileNetV3, works offline | S2, S4, S5 | ✅ | ML + Flutter | P0 | L-01..L-04, O-12 |
| R-07 | Screening labelled "not a diagnosis" | S2, S4, S10 | ✅ | All UIs, Go | P0 | all |
| R-08 | Vet reviews report, history and screening; **confirms, flags or rejects** | S2, S4, Impact | ✅ | Dashboard/Flutter + Go | P0 | O-07, S-04 |
| R-09 | Confirmed cases mapped on officer's **district map** | S2, S4 | ✅ | Dashboard + Go | P0 | O-08, S-05 |
| R-10 | Clusters flagged on the map | S4, S5 | ✅ | Go (PostGIS) + Dashboard | P1 | O-14, S-07 |
| R-11 | Targeted alerts to nearby farms "when set criteria are met"; only confirmed cases trigger | S2, S5 | ✅ | Go + Flutter + Dashboard | P1 | O-15, S-07, S-09 |
| R-12 | Consent before alerts; vet confirmation before warnings (false-alarm mitigation) | S5 | ✅ | Go + Flutter | P1 | O-03, O-15 |
| R-13 | QR animal record; vet reads offline; shows last-updated date | S2, S4, S5 | ✅ | Flutter + Go | P1 | O-16 |
| R-14 | Per-animal records for continuity of care | Impact | ✅ | Go + Flutter | P0 reg. / P1 history | O-05, O-17 |
| R-15 | District **and state** officer roles | S2 | ✅ | Go + Dashboard | P0 district / P1 state | O-03 |
| R-16 | Online AI (Gemini API) **via backend** | S5 | ✅ | Go | P2 | O-21 |
| R-17 | XGBoost outbreak-risk estimate (experiment / exploratory) | S2, S5, S9 | ✅ | ML + Go + Dashboard | P2 | L-05..L-07, O-20, S-08 |
| R-18 | Pilot geography: Phaltan–Satara; Maharashtra districts later | S2, S6 | ✅ | Seed data | P0 | O-04 |
| R-19 | Stack: Flutter/Dart; Go REST; PostgreSQL+PostGIS; React+Leaflet; TFLite+MobileNetV3; Gemini; XGBoost | S5 | ✅ | All | — | — |
| R-20 | Fresh rebuild; no code reuse from SIH 2026 prototype | S7, S8 | ✅ | All | constraint | — |
| R-21 | Open-source planned; licence/copyright TBD | S8 | ✅ | Repo | P2 | D-17 |
| R-22 | Cloud hosting + database; SMS and alerts (budget lines) | S8 | ✅ | Infra | P0 host / P2 SMS | O-19 |
| R-23 | District and taluka filtering on dashboard | Brief | 🟡 | Dashboard + Go | P0 | S-04 |
| R-24 | Role-based access control, JWT auth | Brief | 🟡 | Go | P0 | O-03 |
| R-25 | Analytics and risk visualisation | Brief | 🟡 (PPT: "map of vet-confirmed cases") | Dashboard | P1 | S-06, S-08 |
| R-26 | Records stale-warning: show last-updated date on offline data | S5 | ✅ | Flutter | P1 | O-16 |
| R-27 | Prometheus, Grafana, OpenTelemetry, Redis | Brief | 🟡 not in PPT | Infra | P2/deferred | D-12, D-13 |

## 4. Contradictions and gaps found

| ID | Finding | Handling |
|---|---|---|
| **C-01** | Name: PPT "PashuVani" vs brief "Pashu Wani". | Use PashuVani; confirm (D-01). |
| **C-02** | **Roles differ.** PPT S9: Om = Go/PostGIS/integration; Khushi Shinde = cloud/Docker/presentation; **Soham = offline-first mobile, local sync, Marathi voice**; Lokesh = ML. Brief: Om = Flutter **and** Go; **Soham = React dashboard**; Khushi absent. | Follow the brief. Flag for Om (D-02): Om carries Flutter + Go + TFLite + auth + integration → bottleneck risk. Khushi is unassigned in the brief; recommended optional support: Docker/deploy (O-19) and demo script. |
| **C-03** | PPT lists **Gemini API (via backend)**; brief says "external AI if justified". | Kept as P2, behind a backend interface; may never return a disease name (D-10). |
| **C-04** | PPT frames XGBoost as an **experiment** ("exploratory"); brief treats a FastAPI XGBoost service as a core component. | Kept as P2 with a go/no-go checkpoint. P0 outbreak detection is rule-based on confirmed cases in PostGIS, not ML. |
| **C-05** | Brief adds Redis, Prometheus, Grafana, OpenTelemetry, Tailwind, Recharts, FastAPI, AWS, Material 3 — none in PPT S5. | Frontend libs are Soham's call. Redis deferred; Grafana/OTel deferred; `/metrics` P2 (D-12, D-13). |
| **C-06** | PPT says "vet **confirms, flags or rejects**" (S2) but "confirms or rejects" (S4/S5). "Flag" is undefined. | Modelled as three decisions: `confirmed`, `rejected`, `flagged` (= needs follow-up/visit). Confirm semantics with vet advisor (Q-03). |
| **C-07** | PPT: photo data to be **collected and labelled in Months 1–2 "if supported"** → no labelled dataset exists today. | MobileNetV3 must rely on public datasets. Any accuracy is reported only as measured on held-out data with domain-shift caveats. If no usable dataset: ship UI path with "screening unavailable" — no fake model. |
| **C-08** | No historical case data source identified for XGBoost; no taluka-level data source. | District-level only, feasibility checkpoint, negative result is acceptable and must be documented. **No taluka-level predictions.** |
| **C-09** | PPT S3 footnote reads *"…and we have tested these systems"* (likely missing "not"). | Outside engineering scope; flag to presenter. |
| **C-10** | Alert delivery channel unspecified (PPT: "nearby farmers' phones"; budget has "SMS and alerts"). | In-app notifications P1; FCM push P2; SMS P2 (D-09). |
| **C-11** | Which platform the **vet** uses is unspecified (QR scan implies mobile; "at a clinic" implies web possible). | Recommend: P0 vet review in the dashboard (balances load, Soham), P1 vet mode in Flutter (QR scan, offline). D-03. |
| **C-12** | The brief and PPT disagree on "district/taluka" data: no administrative boundary data (polygons) source specified. | Use declared admin hierarchy (state>district>taluka>village) instead of point-in-polygon. D-08. |

## 5. Missing information (not in PPT)

| ID | Missing | Owner to resolve |
|---|---|---|
| M-01 | Target disease/class list for screening (PPT emphasises LSD; "more diseases later"). | Lokesh + vet advisor |
| M-02 | Training dataset(s), licences, labelled counts. | Lokesh |
| M-03 | Alert criteria ("set criteria") — min cases, radius, time window. | Vet advisor / Om |
| M-04 | Alert notification channel and SMS provider. | Om |
| M-05 | Administrative boundary/LGD data source for Satara talukas/villages. | Om |
| M-06 | Whether para-vets may confirm cases. | Vet advisor |
| M-07 | Species scope (cattle only vs buffalo). | Om |
| M-08 | Ear-tag/Bharat Pashudhan ID format and whether to integrate. | Om |
| M-09 | Authority hierarchy for state officers' scope. | Om |
| M-10 | Licence choice. | Team |
| M-11 | Historical case/weather/livestock-census sources for XGBoost. | Lokesh |
| M-12 | Hosting target (AWS vs laptop demo) and demo environment. | Om (+Khushi?) |
| M-13 | Marathi/Hindi translations verified by native speakers. | Om |

## 6. Assumptions (⚠️ not confirmed — editable via decisions)

| ID | Assumption |
|---|---|
| A-01 | Species P0: `cattle` (confirmed); `buffalo` seeded as proposed. |
| A-02 | Phone number (+91) + password login for P0; OTP deferred. |
| A-03 | Alert approval is human: an officer reviews a flagged cluster and presses "send warning". Auto-alert is P2. |
| A-04 | Default cluster rule (placeholders): ≥3 confirmed cases of the same surveillance disease within 5 km within 14 days. **Not clinically validated.** |
| A-05 | Disease and symptom catalogs are proposed seed data; must be reviewed by a veterinary advisor before any real use. |
| A-06 | Images stored on local disk volume behind a storage interface for the hackathon; S3 later. |
| A-07 | Backend: Gin, Go 1.22+. Single VM / Docker Compose deployment. |
| A-08 | All demo data is synthetic. |

## 7. Scope boundaries

**In scope for the 24h demo (P0):** Farmer → register/login → animal → offline-capable report with photo/symptoms/GPS → on-device screening → backend storage → vet verification → officer dashboard with district/taluka filtering and confirmed-case map.

**P1:** Outbreak clustering, officer-approved alerts, in-app notifications, QR offline records, vet mode in Flutter, vaccinations/treatments, Hindi, state-level officers.

**P2 / stretch:** Voice input, Gemini assist, XGBoost + FastAPI risk estimate, FCM push, SMS, OTP, metrics.

**Out of scope:** real-user validation, regulatory compliance, payments, other species, multi-state rollout, any claim of diagnostic accuracy.

## 8. Glossary

See `AGENTS.md` §4.

