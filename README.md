# LinkBridge

LinkBridge is a Flutter accessibility app focused on real-time communication support.

## Vision and Motivation

LinkBridge is an all-in-one accessibility toolkit designed to help individuals experiencing hearing or vision-related barriers to communication with accessible, easy-to-use methods of navigating everyday life. The main objective is to help users maintain their independence, receive needed information, and participate in all conversations and environments based upon the assumption that everyone can hear and see clearly. LinkBridge has been developed to combine several accessibility workflows in one location, which eliminates the need for users to switch between applications during typical daily activities. 

## Features

1. **ASL Translator**
   A camera-based American Sign Language (ASL) translator. Unlike standard wrappers, this utilizes a custom Random Forest model we trained locally at home. The app records short videos (~4s) and sends them to our ASL inference server, returning the top sign prediction along with confidence scores and alternative predictions to bridge communication gaps precisely.

2. **Smart Assistive Reader**
   A camera-based OCR (Optical Character Recognition) system to help visually impaired users "read" signs, menus, and documents. To solve the problem of blurry or angled scans, the app uses real-time gyroscope and tilt data to ensure the text-to-speech output is highly accurate. 
   - **Single Scan Mode:** Guides the user to level their phone before taking a scan.
   - **On the Go Mode:** Designed for walking and continuous mobility. Features automated scanning every 15 seconds, a mute button, and auto-scrolling text for seamless assistance.

3. **Multi-Speaker Live Captioning**
   Designed to meet a common problem experienced by individuals using hearing aids or cochlear implants, this feature captures live audio and provides a timestamped transcript. It resolves the difficulty of identifying who is speaking in fast-paced conversations by utilizing **Google Chirp's** model for state-of-the-art speech-to-text and diarization capabilities. Available in two configurations:
   - **General:** Standard real-time speaker separation (Speaker_1, Speaker_2).
   - **Named Speakers:** An integrated identification flow to assign custom names to specific identified voice profiles.

4. **Conversation History & Review**
   All captions are saved locally and fully accessible, allowing users to go back and review important details from a prior lecture, family meeting, or social event.

5. **Learn & Education**
   Provides users with trivia, factual history, and educational materials about deaf and hard-of-hearing culture, making accessibility more transparent to everyone.

**Platform support:** This project currently targets mobile devices only — Android and iOS. Key reader, camera, and TTS features rely on native plugins and are not supported on web builds.

## Current Product Scope (What Users See)

After login, the Home screen exposes a persistent bottom navigation with 4 tabs:
1. **Audio** (Live Group Captioning)
2. **Reader** (Smart Assistive OCR + TTS)
3. **Learn** (Education and Trivia)
4. **Account** (Account summary and Sign-out)

*Note: ASL Translator is accessible via its respective flow within the application architecture.*

## Tech Stack

Core:
- Flutter (Dart SDK ^3.10.1)
- Firebase Core + Firebase Auth

Device and Media Plugins:
- `camera`
- `google_mlkit_text_recognition`
- `flutter_tts`
- `record`
- `permission_handler`
- `sensors_plus`

Networking:
- `web_socket_channel`
- `http`

Other UI/Runtime:
- `url_launcher`
- `confetti`

## Architecture Overview

We utilize a feature-first architectural approach to organize code logic efficiently:

### App startup and routing

`lib/main.dart` initializes Firebase, sets up theming constants (via `lib/constants/`), and then launches `MaterialApp` with named routes:
- `/login`
- `/register`
- `/home`

### Home shell

`lib/features/home/home_screen.dart` uses an `IndexedStack` to preserve tab state while switching between tools without losing in-progress work.

### Repository Layout & Structure

```text
lib/
    main.dart
    firebase_options.dart
    constants/               # Application-level styling (AppColors, AppTheme) & config variables
    controllers/             # Logic handlers bridging UI and Services (e.g., captioning_controller.dart)
    features/                # Core Application Features (Domain Driven)
        asl/                 # ASL Translator feature handling video record + custom RF model inference
        auth/                # Login and Registration flows using Firebase
        captioning/          # Live group audio, multi-speaker captioning & review screens
        education/           # Informational widgets, trivia, history
        home/                # Shell layout & bottom navigation
        reader/              # On-device ML Kit OCR & TTS integration
    models/                  # Pure data objects (Caption, ChatMessage, SpeakerProfile)
    providers/               # InheritedWidgets and state injection containers
    services/                # Backend API, formatting, session caching and external comms
        asl_service.dart
        asl_stream_service.dart
        auth_service.dart
        caption_review_service.dart
        conversation_service.dart
        session_manager.dart
        speaker_label_mapper.dart
    utils/                   # Animation tools, environment config (app_config.dart)
    widgets/                 # Reusable sub-components (CaptionTile, AslResultCard, Custom Buttons)
```

## Backend Contract Used by the App

Configured host:
- `linkbridgetsa.org`

Endpoints currently referenced:
- `wss://linkbridgetsa.org/speech/ws`
- `POST /conversations`
- `GET /conversations/{id}`
- `POST /speech/finalize`
- `POST /speech/register_speakers`
- `wss://linkbridgetsa.org/asl/ws` (For ASL Stream)
- `POST https://linkbridgetsa.org/asl/transcribe` (For ASL Upload)

## Backend Bridge and Wake-Up

Group captioning uses a backend bridge by design.

Why this exists:
1. Speaker diarization/transcription capabilities were implemented in the server stack using gRPC-oriented tooling.
2. The Flutter app communicates over WebSocket for live audio streaming.
3. The backend acts as a protocol middle layer: app WebSocket in, diarization/transcription pipeline out.

Server deployment and source:
1. Deployment: `linkbridgetsa.org`
2. Health check: `linkbridgetsa.org/health`
3. Server repository: `https://github.com/MINTALLOYY/ASLAppServer`

## Setup & Prerequisites

1. Flutter SDK compatible with Dart `^3.10.1`
2. Android Studio (Android builds) or Xcode (iOS builds on macOS)
3. Firebase project with Email/Password auth enabled
4. Physical device strongly recommended for camera, ASL module, and microphone testing

Verify local tooling:
```bash
flutter doctor
```

Install dependencies:
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

Ensure Email/Password sign-in is enabled in your Firebase console.

## Running the App

Choose a specific device (ensure a physical device is selected for ideal performance):
```bash
flutter devices
flutter run -d <device_id>
```

If using an Emulator (Android Studio AVD):
- Use an x86_64 AVD with a **Google Play** system image.
- Set **Back Camera** to `webcam0` and enable the virtual microphone.
- Grant runtime permission prompts for Camera and Microphone safely.
- *Limitations: ML Kit OCR & live camera inference can be flaky on virtualized feeds.*

## Permissions

Runtime permissions required:
- **Microphone** (Audio tab & Speaker Identification)
- **Camera** (Reader tab & ASL Translator)

If a feature fails unexpectedly, verify OS permissions immediately.

## Troubleshooting

- **Authentication issues**: Re-run `flutterfire configure`.
- **No live captions**: Check microphone permissions, check if the backend is reachable (`linkbridgetsa.org/health`).
- **Feature bugs in Simulator**: Test on a physical device, many features mandate native hardware APIs.
