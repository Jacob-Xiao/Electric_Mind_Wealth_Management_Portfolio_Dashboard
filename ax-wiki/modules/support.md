---
title: "Support Module"
summary: "The support/ module holds the fictional mock services and datasets shared by the frontend and mobile tracks: a portfolio HTTP API, a legacy CRM fixture server, shared HTTP helpers, setup/maintenance docs, and a node:test suite that validates dataset consistency, edge scenarios, HTTP errors, and CRM fault controls."
generated_by: ax-wiki
symbols:
  - "badRequest"
  - "delay"
  - "history"
  - "holdingDetail"
  - "json"
  - "options"
  - "portfolioData"
  - "readJson"
  - "round"
  - "scenarios"
  - "serve"
  - "startCrm"
  - "startPortfolioApi"
  - "templates"
symbol_summaries: [{"name":"startPortfolioApi","summary":"Creates the shared portfolio HTTP API server, handling GET routes, scenario/delay validation, simulated failures, and 404/405 responses."},{"name":"scenarios","summary":"Exported array of accepted ?scenario= names in support/portfolio-data.mjs; portfolio-api.mjs rejects any value not in this list."},{"name":"portfolioData","summary":"Builds a portfolio response (summary, holdings, allocation, history) for an ID and scenario, applying dataset variants and derived totals."},{"name":"holdingDetail","summary":"Returns per-ticker detail such as purchase date, dividend yield, 52-week range, and price history, or null when the ticker is absent."},{"name":"history","summary":"Generates date/marketValue points ending on the current UTC date, with point counts and gaps driven by the scenario."},{"name":"json","summary":"Writes a JSON response with the correct content type, guarding against already-ended or destroyed responses."},{"name":"serve","summary":"Creates the Node HTTP server: sets CORS/no-store headers, answers OPTIONS and /health, wraps the handler, and normalizes errors to { error, message }."},{"name":"options","summary":"Parses --port and --host CLI flags, rejects unknown options, and validates that the port is an integer from 1 to 65535."},{"name":"badRequest","summary":"Creates an Error tagged with status 400 so serve maps it to a bad_request JSON response."},{"name":"readJson","summary":"Reads and parses a request body, capping it at 4096 bytes and throwing a 400 for oversized or malformed JSON."},{"name":"delay","summary":"Awaits the given milliseconds but resolves early if the response closes, making simulated loading delays abort-safe."},{"name":"startCrm","summary":"Starts the legacy CRM fixture server from backend/crm-service.mjs; support/mocks.test.mjs uses it to verify fixtures, controls, and timeouts."},{"name":"templates","summary":"Internal base rows (AAPL, BND, CASH, ALT, TSLA) that portfolioData copies and mutates to construct per-scenario holdings."},{"name":"round","summary":"Small helper that rounds monetary and percentage values to two decimals for consistent fixture output."}]
sources:
  - "support/MAINTENANCE.md"
  - "support/PORTFOLIO-API.md"
  - "support/SETUP.md"
  - "support/http.mjs"
  - "support/mocks.test.mjs"
  - "support/portfolio-api.mjs"
  - "support/portfolio-data.mjs"
---

# Support Module

The `support/` module supplies the local mock backend that the frontend and mobile tracks build against. It is test harness material, not a candidate solution: `support/MAINTENANCE.md` states the tests cover the supplied materials and that `support/portfolio-data.mjs` "is not the backend track's solution." Keep the folder when sharing a track; candidate solutions should bring their own project configuration and tests.

## What lives here

- `support/portfolio-api.mjs` — the shared portfolio HTTP API used by both frontend and mobile mocks.
- `support/portfolio-data.mjs` — fictional UI fixtures, scenario definitions, and generated price histories.
- `support/http.mjs` — shared server plumbing: CORS headers, `json`, `serve`, CLI `options`, `badRequest`, `readJson`, and cancellable `delay`.
- `support/mocks.test.mjs` — the `node:test` suite that exercises both the portfolio API and the CRM service.
- `support/PORTFOLIO-API.md`, `support/SETUP.md`, `support/MAINTENANCE.md` — contracts, setup, and maintenance instructions.

The module imports from `backend/`: `support/mocks.test.mjs` pulls `startCrm` from `backend/crm-service.mjs` and reads `backend/fixtures/seed.json`. The API entry points (`frontend/mock-server.mjs`, `mobile/mock-server.mjs`) start this shared API on different ports (4000 and 4001 per `support/PORTFOLIO-API.md`); those servers live outside this folder. See [../architecture/overview.md](../architecture/overview.md) and [mobile.md](mobile.md).

## Public surface

`support/portfolio-api.mjs` exports `startPortfolioApi(options)`, which returns the Node HTTP server from `serve`. Routes handled inside it (`support/PORTFOLIO-API.md` lists the same set):

| Route | Behavior |
| --- | --- |
| `GET /` or `/scenarios` | Scenario list and route index |
| `GET /accounts` | Account summaries from each scenario portfolio |
| `GET /portfolios/:id` | Full portfolio, holdings, allocation, performance history |
| `GET /holdings/:ticker/detail` | Holding detail from `holdingDetail` |
| `GET /exchange-rate` | Fixed `{ CADtoUSD: 0.73 }` |
| `GET /notification` | Example notification payload, nothing is sent |
| `GET /health` | Handled by `serve` in `support/http.mjs` |

Only `GET` is accepted for API routes; other methods return 405 (`support/portfolio-api.mjs`). `support/http.mjs` answers `OPTIONS` with 204 and sets `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers: Content-Type, Authorization`, and `Cache-Control: no-store` on every response.

`startCrm` and the `/__control` and `/__stats` endpoints belong to `backend/crm-service.mjs`; the portfolio API does not expose them. Tests in `support/mocks.test.mjs` drive both.

## Internal flow

```
request -> serve() in http.mjs
  set CORS/no-store headers, answer OPTIONS
  GET /health -> { status: "ok", service: name }
  else handler(req, res, url)
    portfolio-api.mjs: method check -> scenario -> delayMs -> fail -> route match
      portfolioData(id, scenario, now) / holdingDetail(ticker, scenario, now)
  errors -> json(res, status, { error, message })
```

`serve` wraps the handler in a try/catch that emits `{ error, message }`: status 400 becomes `bad_request` with the thrown message, anything else with a status (for example the 503 from `fail=true`) is passed through, and an unhandled error becomes 500 `mock_error`. `serve` also listens for `EADDRINUSE` and prints a hint to retry with `--port=<next>`, setting `process.exitCode = 1` (`support/http.mjs`).

`options(defaultPort)` parses `--port=` and `--host=` from `process.argv`, rejects unknown flags, and validates the port range 1–65535. `delay(ms, res)` resolves early if the response closes, so a client abort does not hold the server. `readJson(req)` caps bodies at 4096 bytes and raises a 400 for malformed JSON; the CRM control endpoint relies on it.

## Data generation and scenarios

`portfolioData` builds holdings from a fixed `templates` list (AAPL, BND, CASH, ALT, TSLA across Equity, Fixed Income, Cash, and Alternatives), then derives `marketValue`, `gainLoss`, `dayChangeAmount`, `dayChangePercent`, `weightPercent`, per-asset-class `allocation`, and a total-market-value summary. The second portfolio `P-9002` halves the two retained rows and is labeled "Retirement Account." `history` produces 401 daily points ending on the current UTC date, reduced to 1, 2, or 60 points for `one-point`, `two-points`, and `short-history`, and filtered to create missing dates for `gaps`.

The `scenarios` array in `support/portfolio-data.mjs` is the single source of truth for accepted `?scenario=` values; unknown values return 400 (`support/portfolio-api.mjs`). `?delayMs=` accepts integers 0–10000, and `?fail=true` returns 503 so callers can test error and recovery paths. `support/PORTFOLIO-API.md` stresses applying the same scenario across account, portfolio, and detail requests, and documents the mixed percentage units (`dayChangePercent` as a percent number, `totalReturnSinceInception` as a decimal fraction). `support/mocks.test.mjs` asserts those units, including `CADtoUSD === 0.73` and null `dividendYield` for TSLA.

## Tests

Run from the repository root (`support/MAINTENANCE.md`):

```sh
node --test support/*.test.mjs
```

The helpers in `support/mocks.test.mjs` call `startPortfolioApi` or `startCrm` with `port: 0`, wait for `listening`, and close servers and connections with `t.after`. Coverage includes dataset consistency across scenarios, edge datasets (empty, large, zero, negative, gaps, single-class, tiny-allocation, all-gainers/all-losers), CORS preflight, `delayMs` timing, 404/400/405/503 errors, and CRM fixtures against `backend/fixtures/seed.json`, the every-fifth-request failure, `/__control` modes, `/__stats` counters, and timeout cancellation.

No `npm install`, database, Docker, or API key is required; Node.js 24+ is (`support/SETUP.md`). Servers bind `127.0.0.1` by default and can be moved with `--port=`/`--host=`.

## Change guidance

- Add a scenario by appending to `scenarios` and adding any branching in `portfolioData`/`history`; then extend `support/mocks.test.mjs` and the scenario table in `support/PORTFOLIO-API.md` together, since the tests assert exact counts and values.
- Keep `support/http.mjs` generic. CRM-specific controls such as `/__control` and `/__stats` stay in `backend/crm-service.mjs`; the shared `readJson` and error shape are what that service reuses.
- When the UI contract changes, update `support/PORTFOLIO-API.md` (response shape, units, routes) in the same change as `support/portfolio-data.mjs`, because the two are meant to stay in sync.
- The module is intentionally dependency-free, so prefer plain Node APIs over new packages.

Change verification: run the test command above, then start a mock server (`support/SETUP.md` walks through the per-track commands) and check `/health` and the affected route. Because no dependency graph was supplied, the exact set of external callers beyond `frontend/mock-server.mjs` and `mobile/mock-server.mjs` should be confirmed by grepping the repository for `startPortfolioApi`.

## Sources

- `support/MAINTENANCE.md`
- `support/PORTFOLIO-API.md`
- `support/SETUP.md`
- `support/http.mjs`
- `support/mocks.test.mjs`
- `support/portfolio-api.mjs`
- `support/portfolio-data.mjs`
