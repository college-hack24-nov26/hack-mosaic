# AGENTS.md — Global Instructions for Every AI Coding Agent

> Applies to **all** agents working on PashuVani (Om's, Lokesh's, Soham's). Read this file first, every session.

---

## 0. CURRENT PHASE (edited only by Om)

```
PHASE:            1 — IMPLEMENTATION (P0/P1/P2)
CODING:           UNLOCKED (post-G1)
CONTRACTS:        docs/architecture/API_CONTRACTS.md v1.0 — FROZEN
                  docs/architecture/DATABASE_SCHEMA.md v1.0 — FROZEN
                  docs/ai-ml/ML_INTEGRATION.md v1.0 — FROZEN
NEXT GATE:        G3 (System Integration & Final Demo Verification)
```

**While `CODING: LOCKED`, you may only:** read the docs, write a contract review (see §6), set up your own local tooling, and do dataset discovery notes (Lokesh). You may **not** create Flutter screens, Go handlers, React components, ML training code, SQL migrations, or any other production code, and you may not "start early" against an assumption.

When Om changes the block above to `CODING: UNLOCKED (post-G1)`, you may start work on your assigned P0 tasks in `docs/development/DEVELOPMENT_PLAN.md`.

---

## 1. Mandatory reading order (before you touch anything)

1. `AGENTS.md` (this file)
2. `docs/project/PROJECT_CONTEXT.md` — what we are building, confirmed requirements vs assumptions
3. Your agent file: `agents/OM_AGENT.md`, `agents/LOKESH_AGENT.md` or `agents/SOHAM_AGENT.md`
4. `docs/development/TEAM_WORKFLOW.md` — ownership, gates, Git rules
5. Contracts relevant to you: `docs/architecture/API_CONTRACTS.md`, `docs/architecture/DATABASE_SCHEMA.md`, `docs/ai-ml/ML_INTEGRATION.md`, `docs/architecture/ARCHITECTURE.md`
6. `docs/development/DEVELOPMENT_PLAN.md` (your tasks), `docs/development/CODING_STANDARDS.md`, `docs/development/TESTING_STRATEGY.md`, `docs/security/SECURITY.md`, `docs/architecture/DECISIONS.md`

If you have not read these, you must not write code. State in your first message which files you read.

## 2. Source-of-truth hierarchy

1. The team's explicit written approvals (`docs/architecture/DECISIONS.md`, approved change requests).
2. The attached project PPT (`coepphaltan.pdf`, "PashuVani", Hackathon 2K26) for **what** the product is.
3. The frozen contracts for **how** modules talk to each other.
4. Everything else (including your own preferences) is lowest priority.

If these conflict, **stop and report the conflict** (see §7). Never resolve it by silently changing a doc, a contract, or your code.

## 3. Hard rules (non-negotiable)

1. **Stay in your lane.** Edit only the directories listed in your agent file. Everything else is read-only to you.
2. **Never redefine shared things.** Database schema, API contracts, auth logic, ML manifest format, and error format belong to the contracts. Propose changes through a Change Request (`TEAM_WORKFLOW.md` §6); do not implement a "better" variant locally.
3. **AI is not a diagnosis.** Any output of MobileNetV3, XGBoost, or Gemini must be labelled as a *preliminary screening / estimate / information* and must never be worded or stored as a confirmed diagnosis. Only a `vet_verifications` row with `decision = confirmed` creates a confirmed case. Alerts and outbreak clusters are computed **only** from confirmed cases.
4. **Never fabricate.** No invented datasets, accuracy numbers, predictions, test results, benchmark figures, or "it works" claims. Report real command output. If you could not run something, say so.
5. **No secrets in Git.** No API keys, passwords, tokens, `.env` files, keystores, service-account files. Only `.env.example` with placeholders.
6. **No code reuse from the earlier SIH 2026 prototype** (PPT slides 7–8: "fresh rebuild, no reused code"). Do not paste or import from it.
7. **No unnecessary dependencies or technologies.** Adding a dependency needs a one-line justification in your PR. Adding a new *service/technology* needs a Decision (`DECISIONS.md`).
8. **Never commit to `main`.** Work on your branch, open a PR (`TEAM_WORKFLOW.md` §4).
9. **Never overwrite or revert another developer's work.** Report merge conflicts instead of resolving anything destructive.
10. **Real data only in the right places.** Demo/seed data must be clearly synthetic. No real farmer data is used in this hackathon.
11. **Do not delete or move existing files** without documenting why in your PR and getting Om's approval.

## 4. Vocabulary (use exactly these terms in code, docs, and UI strings)

| Term | Meaning |
|---|---|
| **Screening result** | On-device MobileNetV3 output. *Preliminary, not a diagnosis.* |
| **Disease report** | A farmer's submission about one animal (photo, symptoms, location). |
| **Verification** | A vet's decision on a report: `confirmed`, `rejected`, or `flagged`. |
| **Confirmed case** | A report whose current verification is `confirmed`. |
| **Outbreak cluster** | PostGIS-derived group of nearby confirmed cases of the same surveillance disease. |
| **Alert** | An officer-approved warning sent to consenting nearby farmers about a cluster. |
| **Risk estimate** | XGBoost experimental, district-level output. Never a prediction of certainty. |

Roles: `farmer`, `vet`, `officer`, `admin`. Languages: `en`, `hi`, `mr`. Report statuses: `submitted`, `under_review`, `confirmed`, `rejected`, `flagged`.

## 5. Definition of done (any task)

- Implements exactly the acceptance criteria in `DEVELOPMENT_PLAN.md` for that task ID.
- Conforms to frozen contracts (field names, enums, error shape).
- Relevant tests were **run**; actual results are pasted in the PR description.
- No secrets, no unrelated changes, no formatting churn in files you don't own.
- Docs updated **only** if an approved CR changed a contract.
- PR description states: task ID, what changed, how it was tested (with output), known gaps/assumptions.

## 6. Contract review duty (Gate G1)

Before freeze, every agent reviews the contracts from its own module's perspective and writes `docs/reviews/<name>-contract-review.md` containing:

- **BLOCKER** — I cannot implement my module correctly without this change.
- **SHOULD** — ambiguity or missing field likely to cause rework.
- **NICE** — optional improvements.
- For each item: file + section, the problem, the exact proposed change.
- A list of every field/endpoint your module needs that does not exist, and every field defined that you believe is unnecessary.
- Statement: "I can implement my P0 tasks from these contracts as written / only after BLOCKERS are resolved."

Do not edit the contract files directly during review. Om triages reviews, resolves them in one PR, and the freeze PR requires an `APPROVED v1.0` comment from all three developers.

## 7. Reporting blockers, conflicts, and assumptions

When blocked, post (PR comment or `docs/handoffs/<yourname>-<date>-<n>.md`) in this format:

```
TYPE: BLOCKER | CONFLICT | ASSUMPTION | QUESTION
TASK: <task id>
WHAT I FOUND: <facts, with file/section references>
IMPACT: <who/what is affected>
OPTIONS: <A / B, with trade-offs>
MY RECOMMENDATION: <one line>
NEEDS DECISION FROM: <Om | Om+Soham | Om+Lokesh | all>
```

Then continue with unblocked work. Do not guess on shared contracts.

## 8. Communicating with other agents

Agents do not share a live channel. Communicate only through durable artifacts:

- PR descriptions and PR comments.
- `docs/handoffs/` notes (new files only; never edit someone else's note).
- `docs/change-requests/CR-<nnn>-<slug>.md` for any contract change.
- Delivered artifacts at agreed paths (e.g. ML model bundle in `ml/artifacts/`).

Never edit another developer's directory "to help". Ask via a handoff note.

## 9. Product-safety strings (must appear in UI)

- Farmer app, after screening: *"This is a preliminary check from your phone, not a diagnosis. A veterinarian will review your report."* (and `mr`/`hi` equivalents, translations verified by a native speaker).
- Dashboard risk panel: *"Experimental estimate. Not a confirmed forecast."*
- Alerts: must say the cluster is based on **veterinarian-confirmed** cases.

## 10. Quick reference

| Question | Answer |
|---|---|
| Who approves contract changes? | Om, plus the affected consumer (Soham for API/dashboard, Lokesh for ML). |
| Who owns the DB schema? | Om. Lokesh/Soham may request changes via CR. |
| Where do ML artifacts go? | `ml/artifacts/...` (Lokesh). Om copies them into `mobile/` in his own PR. |
| Can I run `git push origin main`? | No. |
| Can I add a library? | Yes, if justified in the PR and not a new service. |

