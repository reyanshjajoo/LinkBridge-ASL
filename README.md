# LinkBridge (ASL + Accessibility App)

LinkBridge is a Flutter application designed to improve accessibility and communication. It provides:

- Secure login and sign-up (Firebase Authentication)
- Camera-based ASL translator screen (camera preview with recognition placeholder logic)
- Group captioning with live speech-to-text via WebSocket backend
- Educational resources about ASL and accessibility
- Caption history review

------------------------------------------------------------

TECH STACK

- Flutter (Dart SDK ^3.10.1)
- Firebase
  - firebase_core
  - firebase_auth
- Device Capabilities
  - camera
  - record (microphone)
  - permission_handler
- Networking
  - http
  - web_socket_channel
- External Links
  - url_launcher

------------------------------------------------------------

GETTING STARTED

1) Prerequisites

Install:
- Flutter SDK (compatible with Dart ^3.10.1)
- Android Studio (for Android)
- Xcode (for iOS on macOS)
- A physical device recommended for camera + microphone testing

Verify setup:

    flutter doctor

------------------------------------------------------------

2) Clone the Repository

    git clone https://github.com/reyanshjajoo/LinkBridge-ASL.git
    cd LinkBridge-ASL
    flutter pub get

------------------------------------------------------------

FIREBASE SETUP (Required for Authentication)

The app initializes Firebase at startup and requires a generated firebase_options.dart file.

Recommended Method: FlutterFire CLI

Install FlutterFire CLI:

    dart pub global activate flutterfire_cli

Configure Firebase:

    flutterfire configure

This generates:
- lib/firebase_options.dart
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist (if iOS configured)

Firebase Console Checklist:
1. Go to Authentication
2. Enable Email/Password sign-in method

------------------------------------------------------------

RUNNING THE APP

Android:

    flutter run

If multiple devices:

    flutter devices
    flutter run -d <device_id>

iOS (macOS only):

    cd ios
    pod install
    cd ..
    flutter run

Web (optional, limited camera/mic support):

    flutter run -d chrome

------------------------------------------------------------

HOW TO USE THE APP

AUTHENTICATION

Create Account:
1. Tap "Create an Account"
2. Enter email and password
3. Tap "Sign Up"
4. You will be redirected to Home

Log In:
1. Enter email and password
2. Tap "Login"
3. You will be redirected to Home

Sign Out:
1. Go to Account tab
2. Tap "Sign Out"

------------------------------------------------------------

HOME SCREEN TABS

After login, you will see four tabs:

1. Camera
2. Audio
3. Learn
4. Account

------------------------------------------------------------

CAMERA TAB (ASL Translator)

What It Does:
- Opens camera preview
- Processes frames
- Displays recognition status text

How To Use:
1. Grant camera permission
2. Hold hand signs in view
3. Recognition text appears on screen
4. Tap "Clear" to reset

Developer Note:
Recognition logic is currently a placeholder.
Camera streaming and processing hooks exist, but ML integration is not implemented yet.

------------------------------------------------------------

AUDIO TAB (Group Captioning)

What It Does:
- Requests microphone permission
- Streams audio via WebSocket
- Displays live captions
- Saves sessions to caption history

How To Use:
1. Grant microphone permission
2. Tap "Start Captioning"
3. Speak normally
4. Live captions appear
5. End session to finalize and save
6. View saved sessions in caption history

------------------------------------------------------------

BACKEND REQUIREMENT (IMPORTANT)

Group captioning requires a backend server.

Current endpoints:

WebSocket:
https://aslappserver.onrender.com/speech/ws

Finalize:
https://aslappserver.onrender.com/speech/finalize

Save captions:
https://aslappserver.onrender.com/speech/save

List conversations:
https://aslappserver.onrender.com/speech/conversations

Get captions:
https://aslappserver.onrender.com/speech/captions/<conversationId>

If hosting your own backend:
Update URLs in:
- lib/screens/group_captioning_screen.dart
- lib/services/caption_review_service.dart

------------------------------------------------------------

LEARN TAB

- Displays ASL and accessibility educational content
- External links open in browser
- Scroll and explore resources

------------------------------------------------------------

ACCOUNT TAB

- Shows logged-in user email
- Allows sign out

------------------------------------------------------------

PERMISSIONS

Required:
- Camera (Camera tab)
- Microphone (Audio tab)

If features are not working:
- Verify OS-level permissions
- Ensure no other app is using camera
- Test on a real device

------------------------------------------------------------

PROJECT STRUCTURE

```
lib/
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── translator_screen.dart
│   ├── group_captioning_screen.dart
│   ├── education_screen.dart
│   └── caption_review_screen.dart
└── services/
    └── caption_review_service.dart
```

------------------------------------------------------------

TROUBLESHOOTING

Firebase Initialization Errors:
- Run flutterfire configure again
- Confirm firebase_options.dart exists
- Enable Email/Password in Firebase Console

Camera Not Working:
- Use a physical device
- Check permissions
- Restart app

No Captions Appearing:
- Confirm microphone permission
- Ensure backend is reachable
- Verify endpoint URLs

------------------------------------------------------------

Built with accessibility and inclusion in mind.
