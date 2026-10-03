# Tasks 5–10 — secure access, notifications, share, accounts, holding detail, value chart

Built in parallel with Tasks 1–4. Everything lives in its own folders. `lib/main.dart` and the Task 2 overview screen are not touched.

## Layout

```
lib/
  features/
    auth/             Task 5  AuthGate, LockScreen, AuthController, PIN hashing, secure storage
    notifications/    Task 6  local "push", tap → DeepLinkBus → DeepLinkHandler
    share/            Task 7  share text builder + SharePortfolioButton
    accounts/         Task 8  AccountSelectionController + AccountSwitcher (bottom sheet)
    holding_detail/   Task 9  HoldingDetailScreen (push route) + model
    charts/           Task 10 PortfolioValueChartCard, reusable TimeValueLineChart
    shared/           formatters, small API client (/accounts, /holdings/{t}/detail, /notification)
    portfolio_features.dart   bootstrap + InheritedWidget scope
  demo/               DEMO ONLY stand-in overview screen; delete after merge
  main_tasks_5_10.dart        standalone entrypoint for the demo
test/features/        54 unit/widget tests
```

The widgets take plain values (numbers, dates, tickers), not Task 2 model classes, so they work with whatever models Tasks 2–4 define.

## Run

```powershell
node mobile/mock-server.mjs                     # repo root, separate terminal
cd mobile/solution
flutter pub get
flutter test
flutter run -t lib/main_tasks_5_10.dart         # Android emulator
# options: --dart-define=MOCK_SCENARIO=large   --dart-define=API_BASE_URL=http://<LAN-IP>:4001
```

## Design choices and assumptions

| Task | Choice |
| --- | --- |
| 5 | The app **locks on every cold launch and on resume after 30 s in the background** (`AuthController.relockAfter`). If biometrics are enrolled, the biometric prompt is tried first. Fallback is a **4-digit app PIN** that the user creates on first launch, so emulators without biometric hardware use the PIN path. The PIN is stored only as a salted PBKDF2-SHA256 hash. The mock session token (`mock-session-<random>`) and the PIN hash are stored in `flutter_secure_storage`, which on Android means AES-GCM encryption with a key wrapped by the Android Keystore. 5 wrong PINs trigger a 30 s lockout that doubles each time and survives restarts. "Forgot PIN" wipes the PIN and token, which signs the user out. The gate is installed above the Navigator, so it also covers pushed screens. Before the first unlock the portfolio widgets are not built at all. |
| 6 | `flutter_local_notifications` simulates the server push. Use the overview ⋮ menu: send now, send in 5 s (gives you time to background or close the app), or send for an unknown portfolio. Cold start reads `getNotificationAppLaunchDetails`. A tap while backgrounded or in the foreground goes through `onDidReceiveNotificationResponse`. `MainActivity` is `singleTop`, so the running app is reused. The tap is queued and only applied **after unlock**. It pops back to the overview and selects `data.portfolioId`. An unknown ID falls back to the first account and shows a SnackBar. |
| 7 | Shares a **text** summary (no image, so nothing else on screen can leak into it): account label, value, day change, total return, as-of time. No holdings or IDs are included. A dismissed sheet is a no-op, and repeated taps are ignored while the sheet is opening. |
| 8 | A pill in the header opens a **modal bottom sheet** with the selected account checked. With a single account it is a plain label (no chevron, no sheet). The demo caches and prefetches each account's portfolio, so switching is instant. |
| 9 | Standard `MaterialPageRoute` push gives the native transition and back gesture, and the list keeps its scroll position. Null fields show "—", and a null dividend yield shows "None". Empty price history shows a message instead of a chart. Account-specific quantity and gain/loss come from the holdings row (`HoldingSummaryArgs`). |
| 10 | `fl_chart`. The x-axis is real time, and gaps (> 1.5× the usual spacing) **break the line** rather than interpolate, with a caption. 1–2 point series get padded axes and visible dots. Touching or dragging snaps to the nearest point, with a tooltip and crosshair, and the header updates. Range tabs are 1M / 3M / 1Y / All. Spots are cached per range so dragging stays smooth with 401 points. |

Units follow `mobile/API-CONTRACT.md`. Money is CAD, `dayChangePercent` is in percentage points, and return and yield are ratios.

## Verifying the Definition of Done

- **5 Secure access:** Cold launch shows the PIN setup, then the PIN pad. A wrong PIN stays locked. On an emulator without fingerprints, the PIN path works and no biometric button is shown. To use biometrics, enroll a fingerprint in emulator settings and use `adb -e emu finger touch 1`. To inspect token storage:
  `adb shell run-as com.electricmind.electric_mind_portfolio ls shared_prefs` and `cat shared_prefs/FlutterSecureStorage.xml`. Values are ciphertext, and `mock-session-` does not appear in plain text anywhere.
- **6 Notifications:** ⋮ → *Simulate push in 5 s*. Background the app and tap: it opens Retirement Account (P-9002). Repeat with the app swiped away, which is a cold start: you unlock, then land on P-9002. Repeat with *unknown portfolio*: it falls back to the default account with a message.
- **7 Share:** Tap the share icon, and the system sheet shows the text. Dismiss it and the UI still works.
- **8 Accounts:** Switch via the pill. For the single-account case, run with `--dart-define=MOCK_SCENARIO=single-account`.
- **9 Detail:** Tap any holding. Use `TSLA`/`CASH` for null dividend and `CASH` for no history. Go back, and the scroll position is preserved.
- **10 Chart:** Drag on the chart. To test edge cases, run with `MOCK_SCENARIO=two-points`, `one-point`, `gaps`, or `short-history`.

## Merging with Tasks 1–4

Shared files I changed (all additive, so expect trivial conflicts at most):

| File | Change |
| --- | --- |
| `pubspec.yaml` / `pubspec.lock` | + `local_auth`, `flutter_secure_storage`, `crypto`, `flutter_local_notifications`, `share_plus`, `fl_chart`, `http`, `intl`. On a lock conflict, keep either side and run `flutter pub get`. |
| `android/app/src/main/AndroidManifest.xml` | + `USE_BIOMETRIC`, `POST_NOTIFICATIONS`, `android:allowBackup="false"` (Keystore keys are not backed up). |
| `android/app/build.gradle.kts` | + core library desugaring (required by notifications plugin). |
| `MainActivity.kt` | `FlutterActivity` → `FlutterFragmentActivity` (required by `local_auth`). |
| `android/app/src/main/res/` | new notification icon `drawable/ic_stat_portfolio.xml` + keep rule. |

Wiring steps after merge:

1. **`main.dart`:** `final features = await PortfolioFeatures.bootstrap();` before `runApp`, and wrap the app in `PortfolioFeaturesScope`.
2. **`MaterialApp`:** `builder: (c, child) => AuthGate(controller: features.auth, child: child!)` and wrap `home` in `DeepLinkHandler(deepLinks: features.deepLinks, accounts: features.accounts, child: ...)`. If Tasks 1–4 use a tab shell, wrap the shell instead.
3. **Overview screen (Task 2):** Listen to `features.accounts.selectedAccountId` and load that portfolio, keeping the previous one on screen while it loads. Then add:
   - `AccountSwitcher(controller: features.accounts)` in the header,
   - `SharePortfolioButton(snapshot: PortfolioShareSnapshot(...))` in the app bar,
   - `PortfolioValueChartCard(history: TimeValuePoint.parseList(json['performanceHistory'], valueKey: 'marketValue'))`,
   - holding `onTap` → `Navigator.push(HoldingDetailScreen.route(summary: HoldingSummaryArgs(...), loadDetail: features.api.getHoldingDetail))`.
4. Optional: pass Task 3's cached account list into `features.accounts.setAccounts(...)` for offline start, and swap `FeatureApiConfig` for Task 1's base URL config if one exists.
5. Delete `lib/demo/` and `lib/main_tasks_5_10.dart`.

The four spots to copy into the real screen are marked `── Task N ──` in `lib/demo/demo_overview_screen.dart`.

## Known limitations

- No image snapshot sharing (text was chosen; see Task 7).
- Accounts are not persisted offline. That is Task 3/4's store, and the hook is `setAccounts`.
- The "in 5 s" notification uses an in-app timer, so it only fires if the process is still alive. To test from a cold start, send the notification first, then swap the app away before tapping it.
- `local_auth` recommends an AppCompat launch theme to avoid crashes on Android 8 and below. The starter uses `Theme.Material`, which is fine on API 28+ emulators.
