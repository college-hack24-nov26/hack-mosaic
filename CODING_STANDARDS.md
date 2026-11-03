# CODING_STANDARDS.md — Language Conventions & Quality Standards

**Version:** 0.1-draft · **Status:** Pending G0/G1 Approval · **Owner:** Om Rajput (Team Lead)

---

## 1. General Principles (All Languages)

1. **Clarity over cleverness:** Code is read by multiple team members and AI agents. Write simple, explicit, readable code.
2. **Zero secrets in code:** Never commit API keys, passwords, JWT secrets, database connection strings, or service tokens. Use environment variables with sensible defaults only for local test dummies.
3. **Product safety strings are mandatory:** Any UI displaying an automated screening result, risk estimate, or alert must use the exact wording defined in `AGENTS.md` §9.
4. **Preserve comments and docstrings:** When refactoring or updating code, preserve all existing comments and documentation unless instructed otherwise.
5. **No dead or commented-out code:** Do not commit commented-out code blocks or unreferenced files.

---

## 2. Go Coding Standards (Backend)

- **Go Version:** Go 1.22+
- **Formatting:** Standard `gofmt` and `goimports`. Run before committing.
- **Project Structure:**
  - `cmd/api/main.go`: Application entrypoint, wires config, database pool, HTTP router, and graceful shutdown.
  - `internal/<module>/`: Business logic grouped by domain (e.g., `auth`, `reports`, `verifications`, `outbreaks`).
  - No logic in `main.go`. Handlers parse requests and delegate to services. Services call repositories.
- **Error Handling:**
  - Never discard errors (`_ = err`). Always handle or wrap: `fmt.Errorf("fetching report %s: %w", id, err)`.
  - Never `panic()` in request handlers. Recover gracefully and return an internal error with `X-Request-Id`.
  - Return HTTP errors matching the envelope in `API_CONTRACTS.md` §1.2.
- **Database Access:**
  - Use `pgx/v5` connection pool.
  - Always use parameterized queries (`$1, $2`). Never concatenate or format strings into SQL queries.
  - Multi-table writes (e.g., creating a report and linking symptoms; adding a verification and updating report status) must run inside a single database transaction (`tx.Begin()`, `tx.Commit()`, `defer tx.Rollback()`).
- **Concurrency & Context:**
  - Always pass `context.Context` to database calls, HTTP client calls, and background jobs. Respect timeouts.
  - When spawning goroutines (e.g., debounced outbreak clustering), handle panics and track completion with `sync.WaitGroup` or controlled worker pools.

---

## 3. Flutter & Dart Standards (Mobile)

- **Dart/Flutter Version:** Dart 3.x / Flutter 3.22+
- **Formatting:** `dart format .` with line length 100.
- **Design System:** Material 3 with accessible touch targets (minimum 48x48dp for buttons, essential for rural farmers).
- **State Management & Architecture:**
  - Feature-first folder structure: `lib/features/<feature>/{presentation, domain, data}/`.
  - Separation of UI from state and offline storage.
  - Database access (Drift/SQLite) wrapped behind clean repository interfaces.
- **Offline & Concurrency Rules:**
  - TFLite image inference must run inside a background isolate (`compute()` or dedicated worker isolate). Never block the Flutter UI thread.
  - Image resizing and decoding must occur before saving to outbox to reduce disk and bandwidth load.
  - All write operations (creating animals, submitting reports) write to local SQLite first and enqueue an outbox job. The UI immediately reflects local state.
- **Localization (i18n):**
  - Never hardcode user-facing strings in widgets. Use Flutter `.arb` localization files (`intl`).
  - Supported languages: Marathi (`mr`), Hindi (`hi`), English (`en`). Default to Marathi.
  - Verify Devanagari text displays correctly without clipping or overflow on small phone screens.

---

## 4. TypeScript & React Standards (Dashboard)

- **Node/TS Version:** Node 20 LTS, TypeScript 5.x.
- **Compiler Configuration:** Strict mode enabled (`"strict": true`, `"noImplicitAny": true`).
- **Styling:** Tailwind CSS with semantic utility classes. Clean typography for dense tabular information.
- **Component Architecture:**
  - Functional components with React hooks.
  - Colocate components, custom hooks, and types where appropriate.
  - Separate data fetching hooks from presentation UI.
- **API Client:**
  - Typed API layer conforming strictly to `API_CONTRACTS.md`.
  - Shared types for models (`Report`, `Verification`, `Animal`, `Outbreak`).
  - Centralized Axios/fetch client attaching `Authorization: Bearer <token>` and handling `401` refresh.
- **Map & Visualization (Leaflet):**
  - Always clean up Leaflet map instances on component unmount (`map.remove()`) to avoid browser memory leaks.
  - Filter confirmed cases client-side or server-side without altering raw GeoJSON coordinates.
  - Display disease labels, verification status, and timestamps cleanly in tooltips/popups.

---

## 5. Python & FastAPI Standards (Machine Learning)

- **Python Version:** Python 3.10+
- **Code Style:** PEP 8 compliance, formatted with `black` and `ruff`.
- **Validation & Schemas:**
  - All FastAPI request and response models must use Pydantic v2.
  - Reject unknown fields or invalid types with HTTP 422.
- **Reproducibility & Honesty:**
  - Explicit random seeds for all data splits, NumPy, PyTorch/TensorFlow, and XGBoost training runs.
  - Log evaluation metrics to persistent markdown files (`EVALUATION.md`) rather than ephemeral console output.
  - Explicitly document data provenance and licences in `ml/datasets/DATASETS.md`.
- **Stateless Service:**
  - The FastAPI service in `ml/service/` must be completely stateless. It does not connect to Postgres.
  - Read static reference features (e.g. livestock census by district) from bundled read-only parquet/csv files.

---

## 6. Shared Interface Conventions

| Domain | Rule |
|---|---|
| **JSON Keys** | All JSON property names must be `snake_case`. |
| **URL Paths** | All endpoint paths must be lowercase, kebab-case or snake_case as specified in `API_CONTRACTS.md`. |
| **Timestamps** | All API timestamps must be ISO 8601 / RFC 3339 UTC strings ending in `Z` (`2026-11-03T14:00:00Z`). |
| **Coordinates** | API JSON coordinates are `{ "lat": 17.9856, "lng": 74.4331 }`. GeoJSON uses `[lng, lat]`. |
| **UUIDs** | UUIDs must be lowercase canonical string format (`550e8400-e29b-41d4-a716-446655440000`). |

