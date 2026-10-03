# Mobile solution — notes

Flutter app for the wealth-management portfolio dashboard. Implements the
Mobile track's **Task 1** (app shell) and **Task 2** (core portfolio screen).

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
emulator) and `http://localhost:4001` elsewhere. Point it at a different
URL at build/run time with:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4002
```

## Test it

```powershell
cd mobile/solution
flutter test
```

The widget tests inject a fake repository, so they need no network or mock
server. They cover: shell + summary rendering, per-holding market value and
gain/loss, empty-holdings state, neutral zero day-change, a lazy 60-item list,
and pull-to-refresh re-fetching.

## Structure

```
lib/
  main.dart                        # MaterialApp entry point
  models/holding.dart              # Holding
  models/portfolio.dart            # Portfolio (summary + holdings)
  services/portfolio_repository.dart  # repository interface + HTTP impl
  screens/portfolio_overview_screen.dart  # primary screen (Task 2)
  widgets/portfolio_summary_card.dart     # summary card
  widgets/holding_tile.dart               # one holdings row
  utils/formatters.dart            # currency / percent formatting
  utils/portfolio_colors.dart      # gain/loss/neutral colors
```

## Assumptions / decisions

- **Currency:** money is CAD; rendered with a `$` sign and two decimals
  (e.g. `$482,350.12`).
- **Percent units:** `dayChangePercent` and `weightPercent` are treated as
  percentage points (`0.32` → `+0.32%`); `totalReturnSinceInception` is a
  ratio (`0.187` → `+18.7%`), per `mobile/API-CONTRACT.md`.
- **Positive/negative coloring:** North-American convention — green for gains,
  red for losses, neutral tone for exactly zero.
- **Portfolio ID:** hard-coded to `P-9001` for now (single default portfolio);
  account switching is a later task.
- **Unfinished (later tasks):** local persistence, offline reconciliation,
  secure auth, notifications/deep links, share sheet, account selector,
  holding detail view, and the value line chart. The screen is structured so
  those slot in without reworking Task 2.
