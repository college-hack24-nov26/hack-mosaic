# DECISIONS.md — Architectural Decision Log

Status values: **Accepted** (confirmed by the PPT or the brief), **Proposed** (my recommendation; needs team approval at G0/G1), **Open** (no recommendation yet / needs external input).
Approval column is filled by Om (and consumer where required). Nothing marked *Proposed* is binding until approved.

| ID | Decision | Status | Rationale | Alternatives | Approver |
|---|---|---|---|---|---|
| D-01 | Product name: **PashuVani** | Proposed | PPT spelling; brief says "Pashu Wani" | Pashu Wani | Om |
| D-02 | Team roles follow the **brief** (Om: Flutter+Go; Soham: dashboard; Lokesh: ML). Khushi Shinde (PPT) has no assigned module; suggested support role: Docker/deploy + demo/presentation. | Proposed | PPT S9 assigns Soham to mobile and Khushi to cloud — conflicts with brief | Follow PPT roles | Om (+Soham) |
| D-03 | P0 vet review UI lives in the **dashboard**; Flutter vet mode (QR scan, offline record) is P1 | Proposed | Balances load: Om has the heaviest scope; vet can work from a laptop at a clinic | Flutter-only vet; both at P0 | Om |
| D-04 | Backend framework: **Gin** | Proposed | `net/http`-compatible, mature ecosystem, simple middleware; Fiber's fasthttp is incompatible with standard `net/http` tooling and gains are irrelevant at this scale | Fiber, chi, stdlib | Om |
| D-05 | Go + REST + JSON; no GraphQL/gRPC | Accepted | PPT S5 "Go, REST APIs" | — | — |
| D-06 | PostgreSQL + PostGIS; PostGIS only for spatial operations | Accepted (PPT) | PPT S5 | — | — |
| D-07 | Clustering in EPSG:32643 via `ST_ClusterDBSCAN` for the Satara pilot | Proposed | Metric distances, simple; UTM 43N covers ~72–78°E | Geography-only self-join | Om |
| D-08 | District/taluka filtering by **declared hierarchy ids**, not point-in-polygon | Proposed | No boundary polygons available/required for P0; simpler and deterministic | Import LGD/Survey polygons later | Om |
| D-09 | Alert delivery: P1 in-app (polling), P2 FCM, P2 SMS | Proposed | Fits time; PPT lists "SMS and alerts" only as budget | FCM at P1 | Om |
| D-10 | Gemini via Go is P2, informational only; never names a diagnosis; contract by CR before implementation | Proposed | PPT S5 lists it; safety constraints | Drop | Om |
| D-11 | QR carries a compact **Ed25519-signed snapshot**; vet app verifies offline with bundled public key; shows `snapshot_at` | Proposed | PPT: vet reads record offline; integrity needed | Unsigned payload; QR holds only an ID (not offline-readable) | Om |
| D-12 | **Redis not used** in the hackathon build | Proposed | No caching/queue/rate-limit need that Postgres or in-process code can't meet | Redis for rate limiting/jobs | Om |
| D-13 | Prometheus `/metrics` P2; Grafana/OpenTelemetry only if time remains | Proposed | Not in PPT; low demo value vs cost | Full observability | Om |
| D-14 | Deployment: Docker Compose on one VM (AWS EC2) or laptop for demo | Proposed | Simplicity | ECS/Kubernetes | Om |
| D-15 | Flutter local DB: Drift (SQLite); state management and plugin picks are Om's within `CODING_STANDARDS.md` | Proposed | Offline-first requires relational local store | sqflite, Isar, Hive | Om |
| D-16 | Auth: phone+password, JWT HS256 + rotating refresh; OTP is P2 | Proposed | Hackathon time; no SMS provider yet | OTP | Om |
| D-17 | Licence: open-source licence chosen after hackathon (PPT S8 plan) | Open | Not decided | MIT/Apache-2.0/AGPL | Team |
| D-18 | XGBoost is an experiment with a go/no-go at H+8; P0 outbreak detection is rule-based (DBSCAN) | Proposed | PPT calls it exploratory; no known training data | Treat as core | Om + Lokesh |
| D-19 | ML service is stateless; Go supplies DB-derived features; FastAPI supplies static features | Proposed | Avoids a second DB client and schema coupling | FastAPI reads DB | Om + Lokesh |
| D-20 | API contract source of truth is **API_CONTRACTS.md** (no OpenAPI file for the hackathon) | Proposed | Less duplication; Soham writes TS types from it | OpenAPI-first | Om + Soham |
| D-21 | Monorepo layout as in `TEAM_WORKFLOW.md` §2 | Proposed | Single PR flow; clear ownership dirs | Multi-repo | Om |
| D-22 | Contract freeze gate (G1) before any feature code | **Accepted** | Requested by Om: avoid three diverging assumptions | — | Om |
| D-23 | "Flag" verification means "needs follow-up/visit"; flagged cases are **not** counted as confirmed | Proposed | PPT uses "confirms, flags or rejects" without definition | Treat flag as pending | Om + vet advisor |
| D-24 | Cluster rule placeholders: ≥3 confirmed cases, 5 km, 14 days, same surveillance disease | Proposed | Needed for a demo; must be vet-validated (M-03) | Other values | Om + vet advisor |
| D-25 | Alert approval is by an officer (human-in-the-loop) | Proposed | PPT "criteria met", "consent before alerts", false-alarm risk | Auto-alerts | Om |
| D-26 | District-only XGBoost output; no taluka predictions | Proposed | No reliable taluka data (C-08) | — | Lokesh |
| D-27 | Image storage: local volume behind a `Storage` interface | Proposed | Simplest for demo | S3 | Om |
| D-28 | Dashboard libraries (Tailwind, Recharts or other) are chosen by Soham | Proposed | Frontend owner's domain; brief offers Recharts | — | Soham |
| D-29 | Languages: en + mr at P0; hi at P1; translations verified by native speaker | Proposed | PPT: Marathi/Hindi/English | all three at P0 | Om |

## Decision template

```
### D-NN <title>
Date / Proposer
Context
Decision
Consequences
Alternatives considered
Approved by / date
```

## Required approvals (priority list) → see final section of the initialization report and `TEAM_WORKFLOW.md` §9.

