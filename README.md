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

After login, the Home screen exposes a persistent bottom navigation with 5 tabs:
1. **Audio** (Live Group Captioning)
2. **Reader** (Smart Assistive OCR + TTS)
3. **ASL** (Trained ASL Translator)
4. **Learn** (Education and Trivia)
5. **Account** (Account summary and Sign-out)

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

## Technical Feature Flow

This section details the architecture, data flow, and technical implementation of each core feature.

### 1. ASL Translator

**User Flow:**
1. User navigates to ASL tab
2. Taps "Record" button → camera activates
3. Records 4-second video of sign language
4. Video is encoded and sent to backend
5. Custom Random Forest model processes the video
6. Backend returns top prediction + confidence score + alternatives
7. Results displayed with visual confidence indicators

**Technical Architecture:**
- **Frontend:** `lib/features/asl/` contains video recording logic via `camera` plugin
- **Data Format:** MP4 video stream sent via WebSocket (`wss://linkbridgetsa.org/asl/ws`) or HTTP POST (`/asl/transcribe`)
- **Model:** Custom-trained Random Forest classifier (trained on local ASL dataset)
- **Backend:** Python inference server running model prediction pipeline
- **Response Format:** JSON with `top_prediction`, `confidence`, `alternatives` array
- **State Management:** `AslController` manages recording state, buffering, and result caching

**Key Services:**
- `asl_service.dart` - Handles HTTP transcription requests
- `asl_stream_service.dart` - Manages WebSocket connection for real-time streaming

---

### 2. Smart Assistive Reader (OCR + TTS)

**User Flow:**

**Single Scan Mode:**
1. User enters Reader tab → "Single Scan" selected
2. Phone displays level indicator (using accelerometer/gyroscope)
3. User levels phone until indicator shows "Ready"
4. Captures image
5. ML Kit OCR processes image
6. Extracted text is read aloud via TTS
7. User can replay, adjust speed, or rescan

**On the Go Mode:**
1. User selects "On the Go" mode
2. App auto-scans every 15 seconds
3. Continuous OCR pipeline runs in background
4. Text is buffered and read incrementally
5. Mute button stops speech output temporarily
6. Auto-scroll displays current text line

**Technical Architecture:**
- **Frontend:** `lib/features/reader/` contains camera and ML Kit integration
- **Image Processing:** Google ML Kit Text Recognition (`google_mlkit_text_recognition` plugin)
- **TTS Engine:** Flutter TTS plugin with configurable speed (0.5x - 2.0x)
- **Sensor Integration:** `sensors_plus` for real-time gyroscope/accelerometer data
  - Single Scan: Calculates phone tilt angle (X/Y axis) and displays level UI
  - On the Go: Validates device orientation before triggering auto-scan
- **Frame Rate:** Captures frame every 15 seconds in On the Go mode
- **Memory Optimization:** Resizes images before OCR to reduce processing overhead
- **State Management:** `ReaderController` manages scan state, TTS queue, and sensor data

**Key Services:**
- Services in `lib/services/` contain OCR formatting and response caching

---

### 3. Multi-Speaker Live Captioning

**User Flow:**

**General Mode:**
1. User enters Audio tab → "General Captioning" selected
2. Taps "Start Listening"
3. App requests microphone permission and begins streaming audio chunks
4. Real-time captions appear as Speaker_1, Speaker_2, etc.
5. Timestamps are recorded alongside each caption
6. User can pause/resume or end session
7. Conversation is saved locally

**Named Speakers Mode:**
1. User selects "Named Speakers"
2. Pre-registration screen allows user to assign names to voice profiles
3. User initiates listening session
4. System uses voice fingerprinting to identify named speakers
5. Captions display speaker names instead of generic labels
6. Transcript saved with named speaker attribution

**Technical Architecture:**
- **Frontend:** `lib/features/captioning/` manages UI and audio capture state
- **Audio Streaming:** `record` plugin captures PCM audio (16-bit, 16kHz sample rate)
- **Protocol:** WebSocket connection to `wss://linkbridgetsa.org/speech/ws`
- **Backend Processing:**
  - Audio chunks streamed to backend in real-time
  - Google Chirp model performs speech-to-text inference
  - Diarization pipeline identifies speaker boundaries
  - Results streamed back to client via same WebSocket
- **Latency:** Typically 1-2 seconds end-to-end
- **Speaker Diarization:** Backend gRPC pipeline clusters voice embeddings; tracks speaker continuity
- **Data Models:** `Caption` object stores `speaker_id`, `text`, `timestamp`, `confidence`
- **State Management:** `CaptioningController` manages WebSocket lifecycle, audio buffering, and UI sync

**Key Services:**
- `conversation_service.dart` - Handles conversation CRUD operations
- `caption_review_service.dart` - Retrieves and formats saved captions
- `speaker_label_mapper.dart` - Maps speaker IDs to user-assigned names
- `session_manager.dart` - Manages WebSocket connection state

---

### 4. Conversation History & Review

**User Flow:**
1. User navigates to Captioning History
2. Lists all past conversations (sorted by date)
3. User selects a conversation
4. Displays full timestamped transcript with speaker names
5. User can replay captions, adjust playback speed, or export

**Technical Architecture:**
- **Storage:** Local SQLite database
- **Data Schema:** `Conversation` table stores metadata; `Caption` table stores individual captions
- **Queries:** Efficient pagination for large transcript retrieval
- **Export:** JSON or CSV export via `share` plugin

**Key Services:**
- `caption_review_service.dart` - Query and format historical data

---

### 5. Learn & Education

**User Flow:**
1. User navigates to Learn tab
2. Browses trivia, history, and educational content
3. Each module includes text, images, and optional video embeds
4. User can bookmark favorite content for later review

**Technical Architecture:**
- **Content Storage:** Bundled locally as JSON or simple data files
- **UI:** Simple list/card-based navigation via `lib/features/education/`
- **Offline-First:** All content available without internet connection

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

## Download Release Build

### Android (Recommended)

**Download:** [app-release.apk](./app-release.apk)

#### Installation Steps:

1. **Enable Developer Mode** on your Android phone:
   - Go to **Settings → About Phone**
   - Tap **Build Number** 7 times until you see "You are now a developer!"
   - Return to **Settings** and open **Developer Options**
   - Enable **USB Debugging** (and **Install via USB** if available)

2. **Install the APK:**
   - Download `app-release.apk` to your computer
   - Connect your Android phone via USB
   - Run:
     ```bash
     adb install app-release.apk
     ```
   - Or transfer the file to your phone and use a file manager to tap and install

3. **Launch the app** from your phone's app drawer

#### Android Permissions:
- **Camera:** Required for ASL Translator and Smart Reader features
- **Microphone:** Required for Live Captioning
- You will be prompted to grant these at first launch

### iOS (Not Supported)

⚠️ **Apple Security Restriction:** The LinkBridge app **cannot be installed on iOS devices** through this release APK file. Apple's iOS ecosystem requires all apps to be distributed through:
- The **Apple App Store** (official channel)
- **TestFlight** (beta testing)
- **Enterprise certificates** (for organizational deployment)

Directly sideloading unsigned APKs on iOS is not possible due to Apple's closed ecosystem and code signing requirements.

**Workaround:** To test on iOS, you must:
1. Build from source: `flutter run -d <ios_device_id>`
2. Have Xcode and a valid Apple Developer account
3. Configure signing in Xcode before running

## Permissions

Runtime permissions required:
- **Microphone** (Audio tab & Speaker Identification)
- **Camera** (Reader tab & ASL Translator)

If a feature fails unexpectedly, verify OS permissions immediately.

## Troubleshooting

- **Authentication issues**: Re-run `flutterfire configure`.
- **No live captions**: Check microphone permissions, check if the backend is reachable (`linkbridgetsa.org/health`).
- **Feature bugs in Simulator**: Test on a physical device, many features mandate native hardware APIs.

