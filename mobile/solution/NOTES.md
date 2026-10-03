# Mobile solution — notes

Flutter app for the wealth-management portfolio dashboard. Implements the
Mobile track's **Tasks 1–4**: app shell, core portfolio screen, local
persistent storage, and offline state handling & reconciliation.

## Run it

```powershell
# 1. Start the mock API (from the repository root)
node mobile/mock-server.mjs

# 2. Run the app
cd mobile/solution
flutter pub get
flutter run          # pick an Android emulator/device
```

### Mock API port note

On this machine the default mock port `4001` is occupied by another process
(Tencent QQ), so the mock was started on `4002`:

```powershell
node mobile/mock-server.mjs --port=4002
```

The app defaults to `http://10.0.2.2:4001` on Android (host loopback via the
emulator) and `http://localhost:4001` elsewhere. Point it at a different URL
at build/run time with:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4002
```

## Test it

```powershell
cd mobile/solution
flutter test
```

The tests inject fake repository / store / connectivity services, so they need
no network, mock server, or device. Coverage: shell + summary, holdings,
empty-holdings, neutral zero day-change, lazy 60-item list, pull-to-refresh,
cache-first rendering, first-launch persistence, offline banner + staleness,
distinct first-load-offline state, reconnect auto-refresh, and flapping
deduplication. Plus a `Portfolio` JSON round-trip test for the store.

## Structure

```
lib/
  main.dart                          # MaterialApp entry point
  models/holding.dart                # Holding (+ JSON)
  models/portfolio.dart              # Portfolio summary + holdings (+ JSON)
  services/portfolio_repository.dart # network fetch (abstract + HTTP impl)
  services/portfolio_store.dart      # local persistence (abstract + sqflite)
  services/connectivity_service.dart # connectivity detection (abstract + plus)
  screens/portfolio_overview_screen.dart  # primary screen (Tasks 2–4)
  widgets/portfolio_summary_card.dart     # summary card
  widgets/holding_tile.dart               # one holdings row
  widgets/offline_banner.dart             # offline banner
  utils/formatters.dart             # currency / percent formatting
  utils/portfolio_colors.dart       # gain/loss/neutral colors
```

## Persistence (Task 3)

- Store: **SQLite** via `sqflite` — a real embedded store, not in-memory state.
- Schema (table `portfolio_cache`):
  | column | type | meaning |
  | --- | --- | --- |
  | `id` | TEXT, PK | portfolio id, e.g. `P-9001` |
  | `json` | TEXT | serialized `Portfolio` (summary + holdings) |
  | `cached_at` | INTEGER | write time, ms since epoch (for staleness) |
- On cold start the screen reads this cache first and renders immediately,
  then refreshes from the network and overwrites the row.
- `sqflite` writes run off the UI thread; a storage-write failure is non-fatal
  to display.

## Offline handling (Task 4)

- Connectivity is detected with `connectivity_plus`, abstracted behind
  `ConnectivityService` so tests/dev can simulate airplane mode.
- While offline the app shows an "Offline — showing cached data" banner and a
  staleness line ("Prices as of Nm ago") derived from `cached_at`.
- On reconnect it auto re-fetches and reconciles (full replace, no merge
  leftovers). A 600 ms debounce plus a single-in-flight guard prevent duplicate
  requests and UI flicker under rapid connectivity flapping.
- If the app has never fetched and is offline on first launch, it shows a
  distinct "No connection" state (no misleading "cached data" banner).

## Assumptions / decisions

- **Currency:** money is CAD; rendered with a `$` sign and two decimals.
- **Percent units:** `dayChangePercent`/`weightPercent` are percentage points
  (`0.32` → `+0.32%`); `totalReturnSinceInception` is a ratio (`0.187` →
  `+18.7%`), per `mobile/API-CONTRACT.md`.
- **Positive/negative coloring:** North-American convention — green gains, red
  losses, neutral tone for exactly zero.
- **Staleness:** uses the local cache write time (`cached_at`), not the server
  `asOf` timestamp.
- **Portfolio ID:** hard-coded to `P-9001` for now; the store is already keyed
  by id for future multi-account support.
- **Unfinished (later tasks):** secure auth/biometric gate, notifications &
  deep links, native share sheet, account selector, holding detail view, and
  the value line chart.
