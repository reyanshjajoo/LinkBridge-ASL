# Captioning Feature

Purpose
- Real-time, multi-speaker audio captioning.

Main screens
- `group_captioning_screen.dart` — live caption UI and session controls
- `speaker_setup_screen.dart` — optional named-speaker registration
- `speaker_identification_screen.dart` — run-time speaker mapping screen
- `caption_review_screen.dart` — review and finalize captions

Important flows
- WebSocket stream to `AppConfig.wsUri('/speech/ws')`.
- Send `audio_chunk` events with base64 PCM16 audio.
- Receive `final_transcript` events and append to captions.
- Call `AppConfig.httpUri('/speech/finalize')` with the conversation payload when session ends.

Permissions
- `microphone` permission is required at runtime.

Key files
- `lib/controllers/captioning_controller.dart` — main controller (audio, ws, finalize)
- `lib/models/caption.dart` — caption model
- `lib/services/speaker_label_mapper.dart` — helper for speaker mappings

Notes
- Preserve payload shapes when modifying streaming logic.
- Debug prints exist in the controller; clean them before production builds.
