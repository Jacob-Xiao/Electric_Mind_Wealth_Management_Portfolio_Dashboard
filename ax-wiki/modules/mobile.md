---
title: "Mobile Module"
summary: "Mobile Module covers the Flutter portfolio dashboard: the `mobile/solution` app (Material 3 shell, portfolio screen, SQLite cache, offline reconciliation) plus the mock API entrypoint and shared API contract. Tasks 5-10 (auth, notifications, share, account selector, holding detail, charts) are still unfinished, and `_probe_flutter` mirrors this module's setup."
generated_by: ax-wiki
symbols:
  - "Account"
  - "ConnectivityService"
  - "Holding"
  - "HoldingDetail"
  - "MainActivity"
  - "NotificationPayload"
  - "Portfolio"
  - "PortfolioResponse"
  - "mobile/API-CONTRACT.md"
  - "mobile/REQUIREMENTS.md"
  - "mobile/START-HERE.md"
  - "mobile/fixtures/notification-unknown.json"
  - "mobile/fixtures/notification.json"
  - "mobile/mock-server.mjs"
  - "mobile/solution/NOTES.md"
  - "mobile/solution/README.md"
  - "mobile/solution/START-HERE.md"
  - "mobile/solution/analysis_options.yaml"
  - "mobile/solution/android/app/build.gradle.kts"
  - "mobile/solution/android/app/src/main/AndroidManifest.xml"
  - "mobile/solution/android/app/src/main/kotlin/com/electricmind/electric_mind_portfolio/MainActivity.kt"
  - "mobile/solution/android/build.gradle.kts"
  - "mobile/solution/android/settings.gradle.kts"
  - "mobile/solution/lib/main.dart"
  - "mobile/solution/lib/models/holding.dart"
  - "mobile/solution/lib/models/portfolio.dart"
  - "mobile/solution/lib/screens/portfolio_overview_screen.dart"
  - "mobile/solution/lib/services/connectivity_service.dart"
  - "mobile/solution/lib/services/portfolio_repository.dart"
  - "mobile/solution/lib/services/portfolio_store.dart"
  - "mobile/solution/lib/utils/formatters.dart"
  - "mobile/solution/lib/utils/portfolio_colors.dart"
  - "mobile/solution/lib/widgets/holding_tile.dart"
  - "mobile/solution/lib/widgets/offline_banner.dart"
  - "mobile/solution/lib/widgets/portfolio_summary_card.dart"
  - "mobile/solution/pubspec.yaml"
  - "mobile/solution/web/index.html"
  - "mobile/solution/web/manifest.json"
  - "portfolio_cache"
  - "startPortfolioApi"
symbol_summaries: [{"name":"mobile/mock-server.mjs","summary":"Thin entrypoint that imports startPortfolioApi and support/http.mjs options and launches the mock API on port 4001."},{"name":"startPortfolioApi","summary":"Factory from support/portfolio-api.mjs that the mobile mock server invokes to serve the contract-documented JSON routes."},{"name":"Portfolio","summary":"Model holding the portfolio summary plus its holdings, with JSON serialization used by the SQLite cache round-trip."},{"name":"Holding","summary":"Model for one position with ticker, quantity, price, market value, gain/loss, and percentage fields, plus JSON support."},{"name":"ConnectivityService","summary":"Abstract connectivity wrapper over connectivity_plus that lets tests and dev builds simulate airplane mode."},{"name":"portfolio_cache","summary":"SQLite table storing serialized Portfolio JSON keyed by portfolio id, with cached_at milliseconds used for staleness."},{"name":"mobile/solution/lib/screens/portfolio_overview_screen.dart","summary":"Primary screen implementing Tasks 2-4: summary plus holdings list, cache-first render, pull-to-refresh, and offline reconciliation."},{"name":"mobile/API-CONTRACT.md","summary":"Authoritative contract for the local mock API: routes, query parameters, TypeScript shapes, unit conventions, errors, and edge-case scenarios."},{"name":"mobile/REQUIREMENTS.md","summary":"Ten-task specification for the mobile dashboard, defining the behaviors consumers expect for shell, portfolio screen, storage, offline, auth, notifications, share, accounts, detail, and charts."},{"name":"mobile/solution/NOTES.md","summary":"Solution notes documenting Tasks 1-4, the SQLite schema, offline handling, unit assumptions, and remaining unfinished work."},{"name":"mobile/solution/pubspec.yaml","summary":"Declares the electric_mind_portfolio package, Dart >=3.5.0, and the http, connectivity_plus, path, and sqflite dependencies."},{"name":"NotificationPayload","summary":"Contract shape for notification fixtures, carrying title, body, and data with portfolioId and type."},{"name":"PortfolioResponse","summary":"Contract response for /portfolios/{portfolioId}, bundling asOf, portfolio summary, holdings, allocation, and performanceHistory."},{"name":"HoldingDetail","summary":"Contract response for /holdings/{ticker}/detail with cost basis, purchase date, dividendYield (nullable), 52-week range, and priceHistory."},{"name":"mobile/solution/android/app/src/main/AndroidManifest.xml","summary":"Android manifest enabling INTERNET and development-only cleartext traffic, with a singleTop MainActivity as launcher."},{"name":"mobile/solution/web/index.html","summary":"Flutter web host page that validates the $FLUTTER_BASE_HREF placeholder and loads flutter_bootstrap.js asynchronously."}]
sources:
  - "mobile/API-CONTRACT.md"
  - "mobile/REQUIREMENTS.md"
  - "mobile/START-HERE.md"
  - "mobile/fixtures/notification-unknown.json"
  - "mobile/fixtures/notification.json"
  - "mobile/mock-server.mjs"
  - "mobile/solution/NOTES.md"
  - "mobile/solution/README.md"
  - "mobile/solution/analysis_options.yaml"
  - "mobile/solution/android/app/build.gradle.kts"
  - "mobile/solution/android/app/src/main/AndroidManifest.xml"
  - "mobile/solution/android/app/src/main/kotlin/com/electricmind/electric_mind_portfolio/MainActivity.kt"
  - "mobile/solution/android/build.gradle.kts"
  - "mobile/solution/android/settings.gradle.kts"
  - "mobile/solution/pubspec.yaml"
  - "mobile/solution/web/index.html"
  - "mobile/solution/web/manifest.json"
---

# Mobile Module

The `mobile/` module is the Flutter implementation of the Electric Mind wealth-management portfolio dashboard. It contains the app under `mobile/solution/`, a thin mock-API entrypoint (`mobile/mock-server.mjs`), the shared API contract (`mobile/API-CONTRACT.md`), task requirements (`mobile/REQUIREMENTS.md`), and notification fixtures (`mobile/fixtures/`).

The stated implementation scope for `mobile/solution/` is Tasks 1-4 of `mobile/REQUIREMENTS.md`: app shell, core portfolio screen, local persistence, and offline handling. See `mobile/solution/NOTES.md` for the explicit list of unfinished work (secure auth, notifications/deep links, share sheet, account selector, holding detail, value line chart).

On the page graph this module sits alongside `backend.md`, `frontend.md`, and `support.md`; the mock server depends on `support/portfolio-api.mjs` per `mobile/mock-server.mjs`.

## Layout

- `mobile/solution/lib/main.dart` - MaterialApp entry point.
- `mobile/solution/lib/models/holding.dart`, `portfolio.dart` - `Holding` and `Portfolio` models with JSON round-trip.
- `mobile/solution/lib/services/portfolio_repository.dart` - network fetch (abstract + HTTP implementation).
- `mobile/solution/lib/services/portfolio_store.dart` - local persistence (abstract + `sqflite` implementation).
- `mobile/solution/lib/services/connectivity_service.dart` - connectivity detection (abstract + `connectivity_plus` implementation).
- `mobile/solution/lib/screens/portfolio_overview_screen.dart` - primary screen for Tasks 2-4.
- `mobile/solution/lib/widgets/portfolio_summary_card.dart`, `holding_tile.dart`, `offline_banner.dart`.
- `mobile/solution/lib/utils/formatters.dart`, `portfolio_colors.dart`.
- `mobile/solution/android/`, `mobile/solution/web/` - generated platform shells.

## Runtime flow

The overview screen is cache-first: on cold start it reads the SQLite cache and renders immediately, then fetches fresh data and overwrites the cached row (`mobile/solution/NOTES.md`). Persistence uses `sqflite` (a real embedded store) with table `portfolio_cache` (`id` TEXT PK, `json` TEXT, `cached_at` INTEGER ms since epoch). Writes run off the UI thread and a storage-write failure is non-fatal to display.

Offline behavior is driven by `ConnectivityService` (a `connectivity_plus` wrapper). When offline the UI shows an "Offline - showing cached data" banner plus a staleness line derived from `cached_at`. On reconnect the app auto re-fetches and replaces state wholesale; a 600 ms debounce plus a single-in-flight guard prevent duplicate requests under connectivity flapping. If the app has never fetched and is offline on first launch, a distinct "No connection" state is shown instead of a misleading cached-data banner.

```
cold start -> read sqflite cache -> render
          -> fetch via PortfolioRepository -> overwrite cache
connectivity change -> debounce -> refetch (single in-flight)
```

## Public surface and contracts

The HTTP surface the app talks to is fixed by `mobile/API-CONTRACT.md`, implemented by `support/portfolio-api.mjs` and started locally via `mobile/mock-server.mjs` (default port 4001). Routes: `/health`, `/` or `/scenarios`, `/accounts`, `/portfolios/{portfolioId}`, `/holdings/{ticker}/detail`, `/exchange-rate`, `/notification`. All are GET (OPTIONS for CORS preflight; other methods 405). Query parameters: `scenario` (default `default`), `delayMs` (0-10000), `fail=true` (simulated 503). Errors use `{ error, message }` with 400/404/405/503/500.

Type shapes the app must honor: `Account`, `Holding`, `PortfolioResponse`, `HoldingDetail`, `NotificationPayload`. Unit conventions matter: `dayChangePercent` and `weightPercent` are percentage points, `totalReturnSinceInception` and `dividendYield` are ratios, and allocation `value` fields are monetary (`mobile/API-CONTRACT.md`). Nullable fields to guard on: `TSLA`/`CASH` have `dividendYield: null`, and `CASH` has empty detail `priceHistory`.

Notification fixtures: `mobile/fixtures/notification.json` targets `P-9002`; `mobile/fixtures/notification-unknown.json` targets `P-UNKNOWN` and should fall back gracefully (`mobile/API-CONTRACT.md`).

## Configuration and platform shell

- Dependencies (`mobile/solution/pubspec.yaml`): `http ^1.2.2`, `connectivity_plus ^6.0.0`, `path ^1.9.0`, `sqflite ^2.3.0`; Dart SDK `>=3.5.0 <4.0.0`.
- Base URL defaults to `http://10.0.2.2:4001` on Android emulators, `http://localhost:4001` elsewhere, overridable with `--dart-define=API_BASE_URL=...` (`mobile/solution/NOTES.md`).
- Android manifest (`mobile/solution/android/app/src/main/AndroidManifest.xml`) declares `INTERNET` and sets `android:usesCleartextTraffic="true"`; `mobile/START-HERE.md` warns this must not carry into a production configuration. The activity uses `launchMode="singleTop"`.
- Gradle: application id `com.electricmind.electric_mind_portfolio`, Java/Kotlin target 17, plugin versions in `mobile/solution/android/settings.gradle.kts` (AGP `9.0.1`, Kotlin `2.3.20`). `MainActivity` is a plain `FlutterActivity`.
- Lints: `mobile/solution/analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- Web: `mobile/solution/web/index.html` boots via `flutter_bootstrap.js` with `$FLUTTER_BASE_HREF`, and `web/manifest.json` describes the installable app.

## Running and verifying

Per `mobile/solution/NOTES.md` and `mobile/START-HERE.md`:

```powershell
node mobile/mock-server.mjs            # default port 4001, or --port=4002
cd mobile/solution && flutter pub get && flutter run
cd mobile/solution && flutter test
```

For Flutter Web, `mobile/solution/README.md` documents `flutter run -d chrome --web-port=8765 --dart-define=API_BASE_URL=http://localhost:4002` after starting the mock API on port 4002. Tests inject fake repository/store/connectivity services, so they need no network, mock server, or device; coverage listed in `mobile/solution/NOTES.md` includes shell/summary, holdings, empty holdings, neutral zero day-change, lazy 60-item list, pull-to-refresh, cache-first rendering, first-launch persistence, offline banner/staleness, first-load-offline, reconnect refresh, flapping deduplication, and a `Portfolio` JSON round-trip.

## Change guidance

- Adding an endpoint or scenario: update `mobile/API-CONTRACT.md` and `support/portfolio-api.mjs` together; the contract table, TypeScript shapes, and error codes are the authoritative source the app codes against.
- Changing data units (percent vs ratio vs money): revisit `mobile/solution/lib/utils/formatters.dart` and the assumptions section of `mobile/solution/NOTES.md`, since display formatting encodes those units.
- Touching persistence: keep the `portfolio_cache` schema (`id`, `json`, `cached_at`) compatible or document a migration; `cached_at` is also the staleness source, not the server `asOf`.
- Touching connectivity: preserve the debounce plus single-in-flight guard, and keep the first-launch-offline state distinct from the cached-offline banner.
- Platform changes: regenerate Android scaffolding with `flutter create --platforms=android --org com.electricmind --project-name electric_mind_portfolio .` as described in `mobile/START-HERE.md`, and remember the cleartext-traffic setting is development-only.

## Uncertainty

`mobile/solution/NOTES.md` states the portfolio ID is hard-coded to `P-9001` and that the store is already keyed by id for future multi-account support, but the exact wiring of that constant in `portfolio_overview_screen.dart` is not shown in the supplied evidence. Verify by reading `mobile/solution/lib/screens/portfolio_overview_screen.dart`. Similarly, the tests' assertions are only summarized in `NOTES.md`; inspect `mobile/solution/test/` to confirm exact coverage.

## Sources

- `mobile/API-CONTRACT.md`
- `mobile/REQUIREMENTS.md`
- `mobile/START-HERE.md`
- `mobile/fixtures/notification-unknown.json`
- `mobile/fixtures/notification.json`
- `mobile/mock-server.mjs`
- `mobile/solution/NOTES.md`
- `mobile/solution/README.md`
- `mobile/solution/analysis_options.yaml`
- `mobile/solution/android/app/build.gradle.kts`
- `mobile/solution/android/app/src/main/AndroidManifest.xml`
- `mobile/solution/android/app/src/main/kotlin/com/electricmind/electric_mind_portfolio/MainActivity.kt`
- `mobile/solution/android/build.gradle.kts`
- `mobile/solution/android/settings.gradle.kts`
- `mobile/solution/pubspec.yaml`
- `mobile/solution/web/index.html`
- `mobile/solution/web/manifest.json`
