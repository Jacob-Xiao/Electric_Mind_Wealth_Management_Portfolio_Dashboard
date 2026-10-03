# Electric Mind Portfolio

Flutter portfolio dashboard for Android and web. See [NOTES.md](NOTES.md) for
the mobile setup, API configuration, and test instructions.

## Run on web

From the repository root, start the mock API:

```powershell
node mobile/mock-server.mjs --port=4002
```

Then, from this directory, start Flutter Web:

```powershell
flutter run -d chrome --web-port=8765 --dart-define=API_BASE_URL=http://localhost:4002
```

Open <http://localhost:8765>. Use the API URL for the host browser; Android
emulators need the host-loopback address `http://10.0.2.2:4002` instead.
