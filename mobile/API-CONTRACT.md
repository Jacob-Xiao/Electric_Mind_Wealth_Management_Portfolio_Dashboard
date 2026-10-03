# Mobile API contract

This contract describes the fictional local API implemented by `mobile/mock-server.mjs` and `support/portfolio-api.mjs`. The server listens on `127.0.0.1:4001` by default, serves JSON, allows cross-origin requests, and disables response caching. It requires no authentication. For an Android Studio emulator use `http://10.0.2.2:4001`; for a physical phone use the computer's LAN address and start the server with `--host=0.0.0.0`.

## Conventions

- All endpoints are `GET` unless stated otherwise. `OPTIONS` is supported for CORS preflight (204); other methods return 405.
- Successful responses use `Content-Type: application/json; charset=utf-8`.
- Errors have shape `{ "error": "code", "message": "Human-readable explanation" }`.
- Data is fictional and is regenerated on every request. There are no ETags or server-side caches.
- Money and prices are CAD. `dayChangePercent` and `weightPercent` are percentage points (`2.4` means 2.4%). `totalReturnSinceInception` and `dividendYield` are ratios (`0.187` means 18.7%, `0.005` means 0.5%). Allocation `value` fields are monetary amounts, not percentages.
- Send the same `scenario` query parameter to related account, portfolio, and detail requests so the datasets remain consistent.

## Routes

| Method and path | Success response | Notes |
| --- | --- | --- |
| `GET /health` | `{ status: "ok", service: string }` | Liveness check. |
| `GET /` or `GET /scenarios` | `{ scenarios: string[], routes: string[] }` | Route/scenario discovery. |
| `GET /accounts` | `Account[]` | Account summaries for the selected scenario. |
| `GET /portfolios/{portfolioId}` | `PortfolioResponse` | `portfolioId` is `P-9001` or `P-9002` unless the scenario restricts accounts. |
| `GET /holdings/{ticker}/detail` | `HoldingDetail` | Details are selected by ticker. Use the portfolio row for account-specific quantity and gain/loss. |
| `GET /exchange-rate` | `{ "CADtoUSD": number }` | Fixed fictional rate, currently 0.73. |
| `GET /notification` | `NotificationPayload` | Returns an example only; does not send a notification. |

### Query parameters

All data routes accept the following optional parameters:

| Parameter | Values / behavior |
| --- | --- |
| `scenario` | Defaults to `default`. One of `default`, `empty`, `large`, `zero`, `negative`, `large-value`, `single-account`, `single-class`, `tiny-allocation`, `few-holdings`, `all-gainers`, `all-losers`, `one-point`, `two-points`, `gaps`, `short-history`. Unknown values return 400. |
| `delayMs` | Integer from 0 to 10000; delays the response. Invalid values return 400. |
| `fail=true` | Simulates HTTP 503 with `unavailable`; remove it to recover. This does not simulate device connectivity loss. |

### TypeScript shapes

```ts
export type Account = {
  accountId: string;       // Also the portfolio ID, e.g. P-9001
  label: string;
  totalMarketValue: number; // CAD
};

export type Holding = {
  ticker: string;
  name: string;
  assetClass: string;
  sector: string;
  quantity: number;
  price: number;            // CAD per unit
  costBasisPerShare: number; // CAD per unit
  marketValue: number;      // CAD
  gainLoss: number;         // CAD
  dayChangeAmount: number;  // CAD
  dayChangePercent: number; // percentage points: 2.4 means 2.4%
  weightPercent: number;    // percentage points: 5.66 means 5.66%
};

export type PortfolioResponse = {
  asOf: string; // UTC ISO-8601 timestamp, advances on every request
  portfolio: {
    portfolioId: string;
    accountId: string;
    clientId: string;
    label: string;
    currency: "CAD";
    totalMarketValue: number;
    dayChangeAmount: number;
    dayChangePercent: number; // percentage points
    totalReturnSinceInception: number; // ratio: 0.187 means 18.7%
  };
  holdings: Holding[];
  allocation: Array<{ assetClass: string; value: number }>;
  performanceHistory: Array<{ date: string; marketValue: number }>;
};

export type HoldingDetail = {
  ticker: string;
  name: string;
  sector: string;
  assetClass: string;
  price: number; // CAD per unit
  costBasisPerShare: number; // CAD per unit
  purchaseDate: string; // YYYY-MM-DD
  dividendYield: number | null; // ratio: 0.005 means 0.5%; null means none
  fiftyTwoWeekLow: number; // CAD per unit
  fiftyTwoWeekHigh: number; // CAD per unit
  priceHistory: Array<{ date: string; price: number }>;
};

export type NotificationPayload = {
  title: string;
  body: string;
  data: { portfolioId: string; type: string };
};
```

### Errors

| HTTP status | Error code | When |
| --- | --- | --- |
| 400 | `invalid_scenario`, `invalid_delay`, or `bad_request` | Unknown scenario, malformed/out-of-range delay, or invalid request input. |
| 404 | `not_found` | Unknown route, portfolio/account ID, or holding ticker. |
| 405 | `method_not_allowed` | Method other than GET (OPTIONS preflight is supported). |
| 503 | `unavailable` | `fail=true` is supplied. |
| 500 | `mock_error` | Unexpected mock server error. |

## Data and edge-case guarantees

- `default`: two accounts; P-9001 has five holdings and four asset classes. `asOf` is current UTC time.
- `empty`: holdings/allocation are empty and summary values are zero.
- `large`: 60 holdings (`DEMO01`–`DEMO60`), each with detail data.
- `zero` and `negative`: neutral or negative day movement; negative also has a negative inception return.
- `single-account`: only P-9001 is listed; requesting P-9002 returns 404.
- `one-point`, `two-points`, `short-history`: history has 1, 2, or 60 points. Default history has 401 points. `gaps` omits dates.
- `TSLA` and `CASH` have `dividendYield: null`; `CASH` has empty detail `priceHistory`.
- Notification fixture `mobile/fixtures/notification.json` targets P-9002; `notification-unknown.json` targets P-UNKNOWN and should fall back gracefully in the app.
- For an unknown portfolio or holding, expect 404 rather than an empty successful object.

## Examples

```sh
curl http://localhost:4001/health
curl http://localhost:4001/accounts
curl 'http://localhost:4001/portfolios/P-9001?scenario=large'
curl 'http://localhost:4001/holdings/TSLA/detail'
curl 'http://localhost:4001/portfolios/P-9001?scenario=default&delayMs=2000'
curl 'http://localhost:4001/portfolios/P-9001?fail=true'
```
