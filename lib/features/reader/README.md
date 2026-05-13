# Reader Feature

Purpose
- Capture visible text using the camera and read it aloud (OCR + TTS) for accessibility.

Main screen
- `text_reader_page.dart` — camera preview, capture still, run ML Kit OCR, speak recognized text.

Key files
- `lib/features/reader/text_reader_page.dart` — UI and flow control.
- Uses `google_mlkit_text_recognition` and `flutter_tts` packages.

Permissions
- `camera` permission is required.

Notes
- OCR is run on-device via Google ML Kit; offline performance varies by device.
- The feature currently performs in-session reads; add persistence if you want history saved.
