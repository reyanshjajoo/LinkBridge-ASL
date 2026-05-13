# API Contracts

This document summarizes the API contracts (HTTP + WebSocket) that the app relies on.

## WebSocket: Live captioning

- URL: `wss://aslappserver.onrender.com/speech/ws`
- Query parameters:
  - `conversation_id` (string): required to associate messages with a conversation.
  - `num_speakers` (int, optional): if present, backend will expect named-speaker mode.
  - `mode` (string, optional): e.g. `identifying` / `normal`.

### Outgoing events (from app to server)
- `audio_chunk` (object): send base64-encoded PCM audio frames.
  - JSON example:
    ```json
    {"event": "audio_chunk", "data": "<base64_pcm>"}
    ```

- `end` (object): signal end of capture before finalize.
  - JSON example:
    ```json
    {"event": "end"}
    ```

- `begin_captioning` (object): optional control event to request server-side behavior.

### Incoming events (from server to app)
- `final_transcript` (object): a finalized transcript for display.
  - Fields: `event: "final_transcript"`, `text` (string), `speaker` (string)
  - Example:
    ```json
    {"event": "final_transcript", "text": "Hello everyone", "speaker": "Speaker_1"}
    ```

- `speaker_detected` (object): used during speaker-identification flows.

- Other control events: `error`, `info`, etc. Always treat unknown events as non-fatal.


## HTTP: Finalize session

- Endpoint: `POST https://aslappserver.onrender.com/speech/finalize`
- Purpose: send the finalized conversation/payload after `end` event and close.

### Request body (example)

```json
{
  "conversation_id": "conv_1680000000000",
  "captions": [
    { "text": "Hello", "speaker": "Speaker 1", "receivedAt": "2026-05-12T12:00:00.000Z", "source": "speech" }
  ],
  "speaker_map": { "Speaker_1": "Alice" }
}
```

### Response
- `200 OK` with saved conversation metadata.
- Other 4xx/5xx indicate errors; client should surface a friendly message and persist locally if needed.


## HTTP: ASL transcription (video)

- Endpoint: `POST {baseUrl}/asl/transcribe`
- Form field: multipart `video` file
- Response: JSON containing:
  - `text`: overall textual description
  - `best_prediction`: `{label, confidence}`
  - `top_predictions`: array of `{label, confidence, index}`


---

Keep this file updated whenever the backend protocol changes. For precise validation and tests, see `docs/samples/` for example payloads.