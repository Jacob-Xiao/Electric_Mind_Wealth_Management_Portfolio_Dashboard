---
title: "Backend Module"
summary: "The backend/ module is a from-scratch wealth-management portfolio dashboard exercise that lives in backend/solution/ and depends on a supplied mock CRM and fixtures. This page maps the supplied files (START-HERE, REQUIREMENTS, CRM, mock-crm.mjs, crm-service.mjs, seed.json, generate-history.mjs), the ten tasks, and the CRM mapping/caching/ledger flows."
generated_by: ax-wiki
symbols:
  - "/__control"
  - "/__stats"
  - "/crm/portfolios/:id"
  - "CADtoUSD"
  - "GET /clients/:clientId/household-summary"
  - "GET /clients/:clientId/portfolios"
  - "GET /holdings/:ticker/detail"
  - "GET /portfolios/:id"
  - "GET /portfolios/:id/allocation"
  - "GET /portfolios/:id/holdings"
  - "GET /portfolios/:id/performance-history"
  - "accounts"
  - "acct_nickname"
  - "acct_ref"
  - "averageCostBasisPerShare"
  - "behavior"
  - "cachedAt"
  - "calls"
  - "callsByPortfolio"
  - "chg_1d"
  - "client_record"
  - "clients"
  - "curr_val"
  - "currentQuantity"
  - "holdingDetails"
  - "holdings"
  - "ledgerCases"
  - "meta.retrieved_at"
  - "metadata"
  - "modes"
  - "outOfOrder"
  - "oversell"
  - "portfolios"
  - "relationships"
  - "since_inception_pct"
  - "stale"
  - "startCrm"
  - "transactions"
symbol_summaries: [{"name":"startCrm","summary":"Factory exported by crm-service.mjs that returns the mock CRM HTTP handler; it tracks mode, call count, and per-portfolio call counts and simulates the auto failure pattern."},{"name":"metadata","summary":"CRM fixture values in crm-service.mjs mapping P-9001/2/EMPTY/SINGLE to {amt, change, pct, inception}; explicitly labeled fixture data, not candidate valuation code."},{"name":"modes","summary":"The allowed CRM modes array ['auto','ok','error','timeout','missing','nested'] validated by POST /__control and per-request ?mode=."},{"name":"behavior","summary":"Computed per CRM call: 'auto' selects timeout on multiples of 10, error on multiples of 5, else ok; explicit modes pass through."},{"name":"accounts","summary":"The CRM returns every account for the client; callers must select the requested one by acct_ref rather than taking the first entry."},{"name":"CADtoUSD","summary":"Seed rate (0.73) used for the Task 7 display-currency conversion between CAD and USD."},{"name":"ledgerCases","summary":"Seed section providing oversell and outOfOrder transaction fixtures for Task 10 ledger replay edge cases."},{"name":"currentQuantity","summary":"Task 10 replay output: net shares after applying all BUY/SELL transactions chronologically."},{"name":"averageCostBasisPerShare","summary":"Task 10 replay output: weighted average cost of currently held shares under standard average-cost accounting; SELLs do not change it."},{"name":"stale","summary":"Task 9 addition to GET /portfolios/:id: true when a cached value is served past TTL because the CRM failed."},{"name":"cachedAt","summary":"Task 9 addition recording the ISO datetime when the cached portfolio value was originally fetched from the CRM."}]
sources:
  - "backend/CRM.md"
  - "backend/REQUIREMENTS.md"
  - "backend/START-HERE.md"
  - "backend/crm-service.mjs"
  - "backend/fixtures/generate-history.mjs"
  - "backend/fixtures/seed.json"
  - "backend/mock-crm.mjs"
---

# Backend Module

The `backend/` module is the task specification and test harness for a from-scratch wealth-management portfolio API. Candidate code does not exist yet: `backend/START-HERE.md` says the service "starts from scratch in `backend/solution/`", so this page describes the supplied evidence (requirements, mock CRM, fixtures) and the flows a compliant service must implement.

## Layout of the supplied files

| Path | Role |
|---|---|
| `backend/START-HERE.md` | Onboarding: start mock CRM, port choices, supplied assets, fixture table. |
| `backend/REQUIREMENTS.md` | Ten numbered tasks defining routes, schemas, edge cases, DoD. |
| `backend/CRM.md` | External mock CRM contract: shapes, `?mode=` controls, failure pattern, cache-test recipe. |
| `backend/mock-crm.mjs` | Entry point: calls `startCrm(options(4002))`. |
| `backend/crm-service.mjs` | Mock CRM implementation (`startCrm`), reads `fixtures/seed.json`. |
| `backend/fixtures/seed.json` | Seed clients/portfolios/holdings/details/CADtoUSD/transactions plus `ledgerCases`. |
| `backend/fixtures/generate-history.mjs` | Optional generator for `performance-history.json` ending today. |
| `backend/requests.http` | Referenced example requests (not shown in evidence). |

## Public surface (routes the solution must expose)

All portfolio routes are gated by auth (Task 4) and defined in `backend/REQUIREMENTS.md`:

- `GET /portfolios/:id` — CRM-backed metadata mapping; supports `?currency=CAD|USD`; returns `stale` and `cachedAt` per Task 9.
- `GET /portfolios/:id/holdings` — server-computed `marketValue`, `weightPercent`, `unrealizedGainLoss`, `dayChangeAmount`, `dayChangePercent`; currency-aware.
- `GET /portfolios/:id/performance-history?range=1D|1M|YTD|1Y|All` — invalid range → 400; currency-aware.
- `GET /portfolios/:id/allocation` — aggregates by `assetClass` with `value` and `percent`.
- `GET /clients/:clientId/portfolios` and `GET /clients/:clientId/household-summary` — list plus value-weighted aggregate; unknown client → 404.
- `GET /holdings/:ticker/detail` — extended detail including `dividendYield` (nullable) and `priceHistory`.

## Internal flow: Task 1 CRM integration and caching

`backend/START-HERE.md` directs implementers to "Start with Task 1: implement your own `GET /portfolios/:id` endpoint. Inside it, call the CRM's `GET /crm/portfolios/:id`, then map its response into your schema."

```
client -> solution GET /portfolios/:id
            |  auth check (Task 4)
            |  cache lookup by portfolio id (Task 9)
            v
     GET http://localhost:4002/crm/portfolios/:id
            |  response | timeout | 5xx
            v
   map legacy shape -> clean schema -> respond
```

`backend/crm-service.mjs` shows the external shape and the fixtures behind it. Two behaviors matter for mapping:

- The CRM returns **all accounts for the client**, not just the requested one. The comment reads "Return the client's other accounts too; callers must select by acct_ref." `backend/CRM.md` echoes this: "Find the requested account by `acct_ref`; do not assume it is the first one."
- The `nested` mode deletes `client_record.accounts` and instead sets `record.relationships = { accounts }`, an "explicit alternative fixture for the documented inconsistent nesting."

The mapping fields enumerated in `backend/REQUIREMENTS.md` Task 1 are `acct_ref→portfolioId`, `client_id→clientId`, `acct_nickname→label`, `curr_val.ccy→currency`, `curr_val.amt→totalMarketValue`, `chg_1d.amt→dayChangeAmount`, `chg_1d.pct→dayChangePercent`, `since_inception_pct→totalReturnSinceInception`, `meta.retrieved_at→asOf`. Task 9 adds `stale: boolean` and `cachedAt` on the mapped object.

### Failure model driven by crm-service.mjs

`crm-service.mjs` computes `behavior = selected === 'auto' ? (calls % 5 === 0 ? (calls % 10 === 0 ? 'timeout' : 'error') : 'ok') : selected`. The timeout branch does `await delay(10000, res)` then returns 504 with message "CRM took 10 seconds. Your backend should time out sooner." The error branch returns 503 `legacy_unavailable`. `backend/CRM.md` documents the identical pattern: "request 5 returns 503, request 10 waits 10 seconds then returns 504, and the pattern repeats."

The control and observability routes (not part of the candidate surface) are also in `crm-service.mjs`: `GET /__stats` returns `{ mode, calls, callsByPortfolio }`, `POST /__control` accepts a body whose `mode` must be in `modes`, and `GET /` lists routes. The 405 path instructs "Use GET, or POST /__control." Modes are `['auto','ok','error','timeout','missing','nested']`.

## Internal flow: fixtures, currency, and ledger

`backend/fixtures/seed.json` supplies `clients`, `portfolios`, `holdings`, `holdingDetails`, `CADtoUSD: 0.73`, `transactions`, and `ledgerCases`. `backend/START-HERE.md` states using it is optional but recommended, and lists which fixtures exercise which edge cases (`P-EMPTY` has no holdings or history, `ZERO`/`NEW` have no dividend/price history, etc.).

Task 7's conversion uses `CADtoUSD` in seed; the requirements emphasize consistency: non-monetary fields are unaffected and rounding should keep converted totals internally consistent.

Task 10's replay is data-driven: `transactions` in seed include multiple `BUY`s at different prices for `h1` followed by a partial `SELL`, a closed position (`h3`), and `ledgerCases.oversell` / `ledgerCases.outOfOrder` for the required edge cases. Task 10's output is `currentQuantity` and `averageCostBasisPerShare` derived entirely from the transaction list.

Performance history in `backend/fixtures/generate-history.mjs` is generated with per-portfolio counts: `['P-9001',401,48930], ['P-9002',60,500], ['P-EMPTY',0,0], ['P-SINGLE',60,2275]`, with dates ending today. The script's header comment clarifies it "does not filter or serve candidate endpoints" — YTD filtering is the solution's job (Task 3).

## Dependencies and boundaries

- The solution is language- and framework-agnostic; `backend/START-HERE.md` requires Node.js installed via `../support/SETUP.md` only to run the supplied mock tooling.
- The solution must run on a different port (the START-HERE example uses 3000) while the mock CRM runs on 4002.
- `crm-service.mjs` imports `serve, json, readJson, delay, badRequest` from `../support/http.mjs`; that helper is owned by the support module and is not part of the candidate surface (see [support.md](support.md)).
- The mock CRM "has no authentication. Your backend must implement its own authentication" (`backend/CRM.md`) — Task 4 requires a mock token and 401 for missing/malformed headers.
- The mock "does not map, cache, convert currencies, or serve your required endpoints" (`backend/CRM.md`), reinforcing that all mapping, caching, conversion, and routing live in the solution.

## Change guidance

- Changing CRM shapes: update `backend/fixtures/seed.json` and `metadata` in `backend/crm-service.mjs` together; `metadata` is labeled "CRM fixture values, not candidate valuation/calculation code" and supplies `amt/change/pct/inception` independently of the seed's `holdings` prices.
- Changing behavior modes: the `modes` array in `crm-service.mjs` is the single source; also mirror it in `backend/CRM.md`'s mode table so docs stay accurate.
- Touching currency conversion: changing `CADtoUSD` in seed affects all three currency-aware endpoints; verify converted holdings sum to the converted portfolio total as Task 7 requires.
- Regenerating history: `backend/fixtures/generate-history.mjs` writes `performance-history.json` next to itself and must be regenerated when the current year changes so YTD tests stay valid.

## Uncertain / open details

- `backend/solution/` contents are not part of the supplied evidence; endpoints above are requirements, not observed implementations. Verify by inspecting the built solution.
- `backend/requests.http` and `backend/fixtures/performance-history.json` are referenced by the docs but their contents are not in the evidence; check the repository files directly.
- The exact rounding convention for converted monetary fields (Task 7) is left to the implementer to document.

## Related pages

- [Repository Quickstart](../quickstart.md)
- [Architecture Overview](../architecture/overview.md)
- [Development Workflows](../development/workflows.md)
- [Support Module](support.md)
- [Frontend Module](frontend.md)

## Sources

- `backend/CRM.md`
- `backend/REQUIREMENTS.md`
- `backend/START-HERE.md`
- `backend/crm-service.mjs`
- `backend/fixtures/generate-history.mjs`
- `backend/fixtures/seed.json`
- `backend/mock-crm.mjs`
