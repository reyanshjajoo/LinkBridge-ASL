# Setup & Integration Guide

Quick start for developers:

1. Install Flutter and ensure Dart SDK matches `^3.10.1`:

```bash
flutter doctor
```

2. Fetch dependencies:

```bash
flutter pub get
```

3. Firebase configuration:
- Ensure `lib/firebase_options.dart` exists and platform Google plist/json files are in `android/app` and `ios/Runner`.
- Recommended: use `flutterfire configure` to generate `firebase_options.dart`.

4. Backend endpoints:
- Ensure the backend at `https://aslappserver.onrender.com` is reachable for captioning.
- If testing locally, adjust `AppConfig.baseUrl`.

5. Generating API docs (optional):

```bash
dart doc
# Output is under `doc/api` by default
```

6. Running the app:
- For camera & microphone features use a real device.

```bash
flutter run
```

Troubleshooting
- If WebSocket connection fails, check network, CORS, and backend health endpoint `https://aslappserver.onrender.com/health`.
- The ASL server may be slow or sleeping — warm it up with a GET health check before running captioning.

Platform notes
- Web builds are not officially supported for camera/microphone flows.
- On Android 12+ ensure microphone & camera runtime permissions are granted.