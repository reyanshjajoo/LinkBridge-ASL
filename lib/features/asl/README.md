# ASL Feature

Purpose
- Camera-based American Sign Language (ASL) translator that records short videos and sends them to the ASL inference server.

Main screen
- `asl_translator_screen.dart` — records ~4s video clips, shows processing state, displays top prediction with alternatives.

Key files
- `lib/features/asl/asl_translator_screen.dart` — UI and camera handling.
- `lib/services/asl_service.dart` — uploads video to the ASL server and parses responses.

Backend contract
- Endpoint: `POST {baseUrl}/asl/transcribe`
- Multipart field: `video` (file)
- Response JSON includes `text`, `best_prediction: {label, confidence}`, and `top_predictions`.

Permissions
- `camera` permission is required at runtime.

Notes
- Designed for short clip uploads (approx 4s). Keep video encoding/size reasonable to avoid slow uploads.
- Use `docs/samples` for example response shapes when writing tests.
