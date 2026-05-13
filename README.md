# LinkBridge

LinkBridge is a Flutter accessibility app focused on real-time communication support.

## Vision and Motivation

LinkBridge is designed to support people who experience hearing or vision-related communication barriers in everyday life. The core goal is simple: help users stay independent, informed, and included in conversations and environments that often assume everyone can hear and see clearly.

The app combines multiple accessibility workflows in one place so users do not have to switch tools during daily tasks:
1. Camera-based text recognition with spoken playback for reading signs, menus, and printed information.
2. Live multi-speaker captioning for group conversations.
3. Conversation history for reviewing previously captured speech captions.

The group captioning experience was shaped by a real-world need: tracking who is speaking in fast family or social conversations can be difficult even with hearing support devices. LinkBridge addresses that by labeling speakers and presenting readable, timestamped captions in real time.

For users with visual impairments, the Reader mode converts visible text into speech on demand. This supports day-to-day independence in environments where Braille or accessible signage may not be available.

In short, LinkBridge is built to reduce communication friction, preserve important information, and make it easier for people to remain active participants in school, work, and family life.
**Platform support (important):** This project currently targets mobile devices only — Android and iOS. Key reader and TTS features rely on native plugins and are not supported on web builds.

At a high level, the app does three things well today:
1. Handles authentication with Firebase (email + password).
2. Runs live multi-speaker audio captioning through a WebSocket backend.
3. Provides assistive reading (camera OCR + text-to-speech) and educational content.

## Current Product Scope (What Users See)

After login, the Home screen exposes 4 tabs:
1. Audio
2. Reader
3. Learn
4. Account

Important note: the old camera sign translator screen is no longer shown in the app navigation.

## What Works Right Now

Working features:
1. Sign up and login with Firebase Authentication.
2. Sign out from the Account tab.
3. Group captioning session start/stop with microphone audio streaming.
4. Session finalization and conversation persistence through backend APIs.
5. Caption history list and conversation detail view.
6. Optional named-speaker identification flow before captioning.
7. Reader tab camera scan with on-device OCR and spoken playback.
8. Learn tab educational content and external links.

Known limitations and in-progress behavior:
1. Share action in caption detail shows a "coming soon" message.
2. Several debug prints are still present in streaming flows.
3. The translator screen code exists in the repository but is intentionally not reachable from Home.
4. Reader mode currently reads text aloud in-session but does not persist OCR scans to history.

## Tech Stack

Core:
1. Flutter (Dart SDK ^3.10.1)
2. Firebase Core + Firebase Auth

Device and media:
1. camera
2. google_mlkit_text_recognition
3. flutter_tts
4. record
5. permission_handler

Networking:
1. web_socket_channel
2. http

Other UI/runtime:
1. url_launcher
2. confetti

## Architecture Overview

### App startup and routing

`lib/main.dart` initializes Firebase, then launches `MaterialApp` with named routes:
1. `/login`
2. `/register`
3. `/home`

### Home shell

`lib/screens/home_screen.dart` uses an `IndexedStack` to preserve tab state while switching between:
1. `GroupCaptioningScreen` (Audio)
2. `TextReaderPage` (Reader)
3. `EducationScreen` (Learn)
4. Account summary/sign-out panel

### Live captioning flow

Primary files:
1. `lib/screens/group_captioning_screen.dart`
2. `lib/screens/speaker_setup_screen.dart`
3. `lib/screens/speaker_identification_screen.dart`
4. `lib/services/conversation_service.dart`
5. `lib/services/caption_review_service.dart`
6. `lib/services/speaker_label_mapper.dart`

How it works:
1. A conversation ID is created via `ConversationService` (`/conversations`) or generated locally if fallback is allowed.
2. The app connects to `wss://aslappserver.onrender.com/speech/ws`.
3. Microphone PCM16 chunks are streamed as base64 `audio_chunk` events.
4. Incoming `final_transcript` events are appended to in-memory captions.
5. On session end, the app sends an `end` event, stops recording, closes the socket, and calls `/speech/finalize`.
6. History screens fetch from `/conversations` and `/conversations/{id}`.

Named-speaker mode:
1. `SpeakerSetupScreen` collects 2-6 names.
2. App opens speech socket in `mode=identifying`.
3. `SpeakerIdentificationScreen` listens for `speaker_detected` and maps backend labels to user names.
4. Speaker registry is posted to `/speech/register_speakers`.
5. Flow transitions into normal captioning mode with pre-connected socket.

### Reader flow

Primary file:
1. `lib/screens/text_reader_page.dart`

How it works:
1. Requests camera permission.
2. Captures a still image from camera preview.
3. Runs OCR using Google ML Kit text recognizer.
4. Speaks recognized text using Flutter TTS.

### Learn and account

Primary files:
1. `lib/screens/education_screen.dart`
2. `lib/screens/home_screen.dart`

Behavior:
1. Learn tab presents educational content and opens external resources.
2. Account tab shows current user email and allows sign out.

## Backend Contract Used by the App

Configured host:
1. `https://aslappserver.onrender.com`

Endpoints currently referenced in Flutter code:
1. `wss://aslappserver.onrender.com/speech/ws`
2. `POST /conversations`
3. `GET /conversations`
4. `GET /conversations/{id}`
5. `POST /speech/finalize`
6. `POST /speech/register_speakers`

## Backend Bridge and Wake-Up

Group captioning uses a backend bridge by design.

Why this exists:
1. Speaker diarization/transcription capabilities were implemented in the server stack using gRPC-oriented tooling.
2. The Flutter app communicates over WebSocket for live audio streaming.
3. The backend acts as a protocol middle layer: app WebSocket in, diarization/transcription pipeline out.

Server deployment and source:
1. Deployment: `https://aslappserver.onrender.com`
2. Health check: `https://aslappserver.onrender.com/health`
3. Server repository: `https://github.com/MINTALLOYY/ASLAppServer`

Cold-start behavior (Render):
1. The backend may sleep when idle.
2. Before demoing or testing group captioning, call the health endpoint once.
3. Start captioning after the health check responds successfully.

## Setup

### Prerequisites

1. Flutter SDK compatible with Dart `^3.10.1`
2. Android Studio (Android builds)
3. Xcode (iOS builds on macOS)
4. Firebase project with Email/Password auth enabled
5. Physical device recommended for camera and microphone testing

Verify local tooling:

```bash
flutter doctor
```

### Install dependencies

```bash
flutter pub get
```

### Firebase configuration

The app expects `lib/firebase_options.dart` and platform Firebase config files.

Recommended setup using FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Documentation

Developer-facing documentation lives under the `docs/` folder. Key files:
- `docs/api_contracts.md` — WebSocket/HTTP payload shapes and examples.
- `docs/setup.md` — quick integration & run guide.
- `docs/samples/` — JSON example payloads for testing.

You can generate HTML API docs from DartDoc comments using:

```bash
dart doc
```


In Firebase Console, enable Email/Password under Authentication.

## Running the App

Android:

```bash
flutter run
```

Choose a specific device:

```bash
flutter devices
flutter run -d <device_id>
```

Emulator (Android Studio AVD):

- Use an x86_64 AVD with a **Google Play** system image so Play services and a TTS engine are available.
- In AVD Manager → Edit (pencil) → Advanced Settings, set **Back Camera** to `webcam0` (or use `VirtualScene`), and ensure the virtual microphone is enabled.
- Start the emulator with the back camera mapped to your webcam (optional):

```bash
emulator -avd <AVD_NAME> -camera-back webcam0
```

- When running the app, grant runtime permission prompts for Camera and Microphone.
- Limitations: camera quality and model downloads may be flaky on some images; the iOS Simulator does not provide a usable camera feed — use a physical device for final verification.


iOS (macOS only):

```bash
cd ios
pod install
cd ..
flutter run
```

Web (limited mic/camera behavior):

```bash
flutter run -d chrome
```

## Permissions

Runtime permissions used:
1. Microphone (Audio tab and speaker identification)
2. Camera (Reader tab)

If a feature fails unexpectedly, verify OS permissions first.

## Repository Layout

```text
lib/
    main.dart
    firebase_options.dart
    models/
        chat_message.dart
        speaker_profile.dart
    screens/
        login_screen.dart
        register_screen.dart
        home_screen.dart
        group_captioning_screen.dart
        speaker_setup_screen.dart
        speaker_identification_screen.dart
        caption_review_screen.dart
        text_reader_page.dart
        education_screen.dart
        translator_screen.dart
    services/
        conversation_service.dart
        caption_review_service.dart
        speaker_label_mapper.dart
        asl_stream_service.dart
```

## Troubleshooting

Authentication issues:
1. Re-run `flutterfire configure`.
2. Confirm `firebase_options.dart` matches your project.
3. Ensure Email/Password sign-in is enabled.

No live captions:
1. Confirm microphone permission was granted.
2. Confirm backend is reachable from device network.
3. Verify backend supports the endpoints listed above.

Reader problems:
1. Test on a physical device instead of emulator when possible.
2. Confirm camera permission.
3. Retry after closing other apps that may hold camera resources.

## Development Notes

1. `translator_screen.dart` remains in the codebase but is not currently part of the visible app flow.
2. If you re-enable it later, update `home_screen.dart` and this README together.
