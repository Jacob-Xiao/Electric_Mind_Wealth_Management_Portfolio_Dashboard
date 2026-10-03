---
title: "Development Workflows"
summary: "Development workflows for this repo center on Node.js >=24 ESM mock services and a single node:test suite. Commands are defined in package.json: frontend/backend/mobile mock servers plus `npm test`, which runs support/*.test.mjs and boots the portfolio and CRM services on ephemeral ports."
generated_by: ax-wiki
symbols:
  - "acct_nickname"
  - "acct_ref"
  - "allocation"
  - "backend/crm-service.mjs"
  - "backend/fixtures/seed.json"
  - "client_record"
  - "closeTo"
  - "control"
  - "curr_val.amt"
  - "mode"
  - "package.json"
  - "performanceHistory"
  - "scenarios"
  - "service"
  - "startCrm"
  - "startPortfolioApi"
  - "stats"
  - "support/mocks.test.mjs"
  - "support/portfolio-api.mjs"
  - "support/portfolio-data.mjs"
symbol_summaries: [{"name":"package.json","summary":"Defines the private ESM package, the Node >=24 engine requirement, and the only scripts: frontend/backend/mobile mock servers plus `node --test support/*.test.mjs`."},{"name":"support/mocks.test.mjs","summary":"The sole test suite; boots the portfolio API and CRM service on ephemeral ports, asserts data consistency, HTTP edge cases, and CRM failure modes."},{"name":"support/portfolio-api.mjs","summary":"Exports startPortfolioApi, the UI-facing mock service under test that serves accounts, portfolios, holdings detail, exchange-rate, and notification endpoints."},{"name":"support/portfolio-data.mjs","summary":"Exports scenarios, the list of dataset names the first test iterates to validate per-scenario consistency."},{"name":"backend/crm-service.mjs","summary":"Exports startCrm, the legacy CRM mock service with mode switching, injected every-fifth-request failure, and stats reporting."},{"name":"backend/fixtures/seed.json","summary":"Seed portfolios and holdings that the CRM test cross-checks: per-portfolio values must equal the sum of quantity * price."},{"name":"startPortfolioApi","summary":"Factory used by tests to start the portfolio mock with options such as port 0 and a name."},{"name":"startCrm","summary":"Factory used by tests to start the CRM mock service on an ephemeral port."},{"name":"scenarios","summary":"Named dataset variants (empty, large, gaps, all-gainers, tiny-allocation, and others) that drive both test coverage and mock responses."},{"name":"service","summary":"Test helper that starts a service on port 0, waits for listening, registers t.after cleanup with closeAllConnections, and returns fetch/get wrappers."},{"name":"closeTo","summary":"Assertion helper allowing a 0.02 tolerance for floating-point comparisons of totals, holdings, and allocations."},{"name":"client_record","summary":"CRM response envelope holding accounts; its shape changes with mode, moving accounts under relationships when nested."},{"name":"curr_val.amt","summary":"Per-account current value field in CRM responses; computed as sum of quantity * price and set to null in mode=missing."},{"name":"acct_nickname","summary":"Optional account label in CRM responses that must be absent when mode=missing is used."},{"name":"acct_ref","summary":"Account reference key in CRM responses used to match a portfolioId to its account record in tests."},{"name":"control","summary":"Helper in the CRM test that POSTs a mode to /__control to force ok, error, or timeout behavior."},{"name":"stats","summary":"Result of /__stats exposing calls, callsByPortfolio, and the active mode for CRM debugging assertions."},{"name":"performanceHistory","summary":"Time series in portfolio responses; tests require strictly increasing dates and a final point dated today matching the account total."},{"name":"allocation","summary":"Asset-class breakdown in portfolio responses whose values must sum to the portfolio totalMarketValue."}]
sources:
  - "package.json"
  - "support/mocks.test.mjs"
---

# Development Workflows

This repository is a private ESM package that requires `node` >=24 (`package.json`). There is no build step, bundler, or framework toolchain declared in the evidence: scripts run plain `.mjs` files directly.

- `npm run frontend` → `node frontend/mock-server.mjs`
- `npm run backend` → `node backend/mock-crm.mjs`
- `npm run mobile` → `node mobile/mock-server.mjs`
- `npm test` → `node --test support/*.test.mjs`

Each mock is an independent process; run only the one you need. For module responsibilities see [../modules/frontend.md](../modules/frontend.md), [../modules/backend.md](../modules/backend.md), [../modules/mobile.md](../modules/mobile.md), and [../modules/probe-flutter.md](../modules/probe-flutter.md).

## Test workflow

Run the full suite with `npm test`. The concrete suite is `support/mocks.test.mjs`, and it exercises two services:

- `startPortfolioApi` from `support/portfolio-api.mjs`, driven by `scenarios` from `support/portfolio-data.mjs`.
- `startCrm` from `backend/crm-service.mjs`.

The `service(t, start)` helper in `support/mocks.test.mjs` starts each service with `{ port: 0, name: 'Test mock' }`, waits for the `'listening'` event via `once` from `node:events`, and reads the assigned port from `server.address().port`. Cleanup is registered with `t.after(...)`, which calls `server.close` and then `server.closeAllConnections()` — so tests never rely on fixed ports and shut down deterministically. Use this pattern for any new integration test rather than hardcoding a port.

Numeric assertions use the local `closeTo(actual, expected)` helper (`Math.abs(actual - expected) < 0.02`) instead of exact float equality. Follow that convention when asserting derived totals, market values, or allocations.

## What the tests guarantee

Keep these contracts in mind before changing mock data or handlers:

- Portfolio API: per-scenario consistency across `/accounts`, `/portfolios/:id`, and `/holdings/:ticker/detail` — totals, holdings sums, allocation sums, and monotonic, current-dated `performanceHistory` (`support/mocks.test.mjs`).
- Edge datasets: `empty`, `large` (60 holdings), `few-holdings` (2), `zero`, `negative`, `one-point`, `two-points`, `short-history`, `gaps`, `all-gainers`, `all-losers`, `single-class`, `tiny-allocation`, plus `single-account`.
- HTTP contract: `OPTIONS` returns 204 with `access-control-allow-origin: *`; `?fail=true` → 503; unknown IDs → 404; bad `scenario`/`delayMs` → 400; non-GET → 405; `/health` → `{ status: 'ok' }`; `?delayMs=100` actually delays (>= ~90ms).
- CRM service: `backend/fixtures/seed.json` must stay consistent with computed holdings values per portfolio; `mode=ok` returns populated records, `mode=missing` nulls `curr_val.amt` and omits `acct_nickname`, `mode=nested` moves accounts under `client_record.relationships.accounts` and removes `client_record.accounts`.
- CRM failure behavior: every fifth unmocked request fails with 503; `/__control` switches mode (`ok`/`error`/`timeout`) and rejects invalid bodies or modes with 400; `/__stats` tracks `calls`, `callsByPortfolio`, and current `mode`.

## Safe change workflow

1. Identify the owning module before editing — data fixtures, service handlers, and tests are separated by module (see [../architecture/overview.md](../architecture/overview.md)).
2. If you change `backend/fixtures/seed.json` values, re-check the CRM seed-consistency test in `support/mocks.test.mjs`; totals are recomputed as `quantity * price` per portfolio.
3. If you add a scenario, register it in `support/portfolio-data.mjs` and add coverage in `support/mocks.test.mjs`; the first test iterates `scenarios` directly.
4. Run `npm test` before and after changes; it is the only declared check. Verify manually with the matching `npm run` script when behavior is timing- or transport-related.

## Debugging

- Start the relevant mock (`npm run frontend|backend|mobile`) and hit endpoints directly; the portfolio API documents behavior through the error shape `{ error, message }` returned on 400/404/405/503.
- CRM debugging is stateful: post to `/__control` to force `error` or `timeout`, then read `/__stats` to confirm call counts and mode. Use `?mode=ok` to bypass the injected fifth-request failure.
- Test flakiness around timing: `delayMs` and abort-based assertions depend on real clocks; `support/mocks.test.mjs` uses `AbortSignal.timeout(100)` and expects `TimeoutError`, so keep artificial delays well above that window or the tests will race.

## CI and release

No CI configuration, linting, formatting, or release tooling is present in the supplied evidence, so no pipeline or publish workflow can be documented. The only repository-declared gate is `npm test` under Node >=24 (`package.json`). Verify CI/release claims by inspecting for workflow files (for example `.github/workflows/`) in the repository itself before relying on them. For first-run setup, see [../quickstart.md](../quickstart.md).

## Sources

- `package.json`
- `support/mocks.test.mjs`
