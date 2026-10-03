---
title: "Frontend Module"
summary: "The frontend/ module is a challenge scaffold: it defines the wealth-management dashboard specification (REQUIREMENTS.md), on-ramp instructions (START-HERE.md), and a thin mock-server.mjs that delegates to the shared support module. Implementation lives in frontend/solution/, which is not present in the evidence."
generated_by: ax-wiki
symbols:
  - "frontend/REQUIREMENTS.md"
  - "frontend/START-HERE.md"
  - "frontend/mock-server.mjs"
  - "frontend/solution/"
  - "options"
  - "startPortfolioApi"
  - "support/PORTFOLIO-API.md"
  - "support/SETUP.md"
  - "support/http.mjs"
  - "support/portfolio-api.mjs"
symbol_summaries: [{"name":"startPortfolioApi","summary":"Server factory imported from ../support/portfolio-api.mjs; called by the frontend mock launcher to start the portfolio API on the configured port."},{"name":"options","summary":"Helper from ../support/http.mjs that produces HTTP/port configuration; called as options(4000) to bind the frontend mock API to port 4000."},{"name":"frontend/mock-server.mjs","summary":"Three-line entry point that starts the shared portfolio API on port 4000 labelled 'Frontend mock API'; run with node frontend/mock-server.mjs."},{"name":"frontend/REQUIREMENTS.md","summary":"Fixed spec of 10 dashboard tasks (shell, summary card, holdings table, charts, range selector, currency toggle, account selector, holding detail, top movers), each with edge cases and a Definition of Done."},{"name":"frontend/START-HERE.md","summary":"Setup instructions for the exercise: install Node, run the mock server, verify /health and /portfolios/P-9001, and build the app in frontend/solution/."},{"name":"support/portfolio-api.mjs","summary":"Owning module of the mock portfolio server that frontend/mock-server.mjs starts; source of the routes and scenarios the frontend consumes."},{"name":"support/http.mjs","summary":"Provides the options() helper used to derive the frontend mock server's port and HTTP configuration."},{"name":"support/PORTFOLIO-API.md","summary":"Referenced by frontend/START-HERE.md as the guide for mock routes, field units, and test datasets used by the dashboard."},{"name":"frontend/solution/","summary":"Designated build location for the dashboard app (or an app/ folder inside it); no framework is prescribed, and it is absent from the supplied evidence."}]
sources:
  - "frontend/REQUIREMENTS.md"
  - "frontend/START-HERE.md"
  - "frontend/mock-server.mjs"
---

# Frontend Module

The `frontend/` module is a **task scaffold**, not a finished application. It contains three files:

- `frontend/REQUIREMENTS.md` — the fixed functional spec for a wealth management portfolio dashboard, split into 10 numbered tasks (shell, summary card, holdings table, line chart, allocation chart, date-range selector, currency toggle, account selector, holding detail, top movers widget).
- `frontend/START-HERE.md` — the on-ramp: how to start the mock backend, where to build the app, and where the data contract lives.
- `frontend/mock-server.mjs` — a three-line executable that starts the shared mock API on port 4000.

Implementation code is expected under `frontend/solution/` (or `frontend/solution/app/`), per `frontend/START-HERE.md`. **That directory is not present in the supplied repository evidence**, so this page documents the spec, the mock entry point, and the integration contract rather than concrete components.

## Public surface

| Surface | Path | Notes |
|---|---|---|
| Functional spec | `frontend/REQUIREMENTS.md` | 10 tasks, each with Inputs / Expected Behaviour / Edge Cases / Definition of Done. Described as fixed and not updated after work starts (`frontend/START-HERE.md`). |
| Build location | `frontend/solution/` | Framework-agnostic; no framework or tooling is mandated. |
| Mock API launcher | `frontend/mock-server.mjs` | `node frontend/mock-server.mjs` → API on `http://localhost:4000`. |

There are no exported symbols from this module's own files: `frontend/mock-server.mjs` only imports and calls shared helpers.

## Runtime flow

`frontend/mock-server.mjs` does three things in order:

```js
import { startPortfolioApi } from '../support/portfolio-api.mjs';
import { options } from '../support/http.mjs';
startPortfolioApi({ ...options(4000), name: 'Frontend mock API' });
```

1. `options(4000)` builds the HTTP configuration for port 4000 (including whatever CORS behaviour lets a local app call it — `frontend/START-HERE.md` states browser requests from your local app are allowed and no login is required).
2. The options are spread and a `name` label is added (`Frontend mock API`) so the shared server identifies itself distinctly from other callers.
3. `startPortfolioApi(...)` starts the server.

Everything else — routes, datasets, scenarios — is owned by `support/`; see [Support Module](support.md).

```
node frontend/mock-server.mjs
        │
        ▼
  support/http.mjs  options(4000)
        │
        ▼
  support/portfolio-api.mjs  startPortfolioApi({ port: 4000, name: 'Frontend mock API' })
        │
        ▼
  localhost:4000  →  /health, /accounts, /portfolios/:id?scenario=...
        │
        ▼
  frontend/solution/  (your app: fetch, render, sort, chart, toggle)
```

## Data contract and integration

Per `frontend/START-HERE.md`:

- Health check: `GET /health` returns `"status": "ok"`.
- Start with `/accounts`, then fetch `/portfolios/P-9001`.
- Pass the same `scenario` query parameter across related requests so the datasets stay consistent.
- Test scenarios named in the evidence: `?scenario=empty` and `?scenario=large` for table testing; omit `scenario` for the normal dataset.
- Field units, remaining routes, and the full test-dataset list live in `support/PORTFOLIO-API.md` (see [Support Module](support.md)).

The `frontend/` module therefore reads as: **spec + launcher**, with the actual server in `support/` and the actual UI in `frontend/solution/`.

## Spec structure worth knowing when implementing

Several requirements impose **cross-cutting state** rather than per-component behaviour:

- **Currency toggle (Task 7)** — all data is native CAD; the toggle must convert *every* dollar figure (summary, table, charts, widgets) using a single exchange rate, must not create rounding mismatches, and must **preserve other UI state** (sort order, selected range, selected account). This argues for one shared currency/formatting concern rather than per-component conversions.
- **Account selector (Task 8)** — switching accounts must refresh summary, holdings, and charts without a page reload.
- **Date-range selector (Task 6)** — `1D / 1M / YTD / 1Y / All`, where `YTD` is computed from **January 1 of the current year**, not from the dataset start, and short datasets must degrade to "show what's available".
- **Holding detail (Task 9)** — opened from a table row; closing it must not lose the table's sort state; `null` optional fields (e.g. `dividendYield`) must render gracefully.
- **Sorting (Task 3)** — at minimum market value, weight %, gain/loss, with ascending/descending toggle; empty array and 50+ rows must both be handled.
- **Neutral zero (Task 2)** — a zero day change is neither positive-styled nor negative-styled.

These constraints mean a shared state/formatting layer (currency, scenario, selected account, selected range, sort) is the natural shape of the solution, even though no framework is prescribed.

## Dependencies

- `support/portfolio-api.mjs` — `startPortfolioApi`, the mock server factory.
- `support/http.mjs` — `options(port)`, the HTTP/port/CORS configuration helper.
- `support/PORTFOLIO-API.md` — the authoritative field/unit/route documentation referenced by `frontend/START-HERE.md`.
- `support/SETUP.md` — Node.js install and terminal setup.

This module has **no dependencies on `backend/`, `mobile/`, or `_probe_flutter/`** in the supplied evidence; the only inbound coupling is the mock API shared with sibling tasks. See [Architecture Overview](../architecture/overview.md) and [Backend Module](backend.md) for the neighboring surfaces.

## Change guidance

- **Changing behaviour?** First check whether it is already pinned by a Definition of Done in `frontend/REQUIREMENTS.md`. The file is treated as frozen for the exercise (`frontend/START-HERE.md`), so prefer adapting the implementation over editing the spec; if the spec must change, call it out explicitly and re-check every task's DoD.
- **Adding routes or datasets?** Do it in `support/portfolio-api.mjs` / `support/PORTFOLIO-API.md`, not in `frontend/mock-server.mjs` — that file is deliberately a three-line launcher.
- **Changing the port?** It is hardcoded as `options(4000)` in `frontend/mock-server.mjs` and echoed in the docs at `frontend/START-HERE.md`; both must change together.
- **Renaming the server label?** `name: 'Frontend mock API'` is a display/identification string only; downstream tooling that greps logs for it would need updating.
- **Implementing the UI?** Add files under `frontend/solution/`; keep the conversion/formatting/state concerns centralized so Tasks 6, 7, 8, and 9 can all preserve each other's state.

## Uncertainty

The actual frontend implementation is absent from the evidence, so no components, state containers, or charting choices can be named. Verify by listing `frontend/solution/`; if it is empty, the module is still at the scaffold stage described above. Exact CORS headers, error shapes, and scenario names beyond `empty`/`large` are owned by `support/` and should be verified against `support/portfolio-api.mjs` and `support/PORTFOLIO-API.md`.

## Sources

- `frontend/REQUIREMENTS.md`
- `frontend/START-HERE.md`
- `frontend/mock-server.mjs`
