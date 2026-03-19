/// Unified message model used by both speech and ASL pipelines.
///
/// Keeping a single shape for both sources simplifies rendering, persistence,
/// and review screens.
class ChatMessage {
  static const String typeSpeech = 'speech';
  static const String typeAsl = 'asl';

  final String id;
  final String text;
  final String type;
  final String? speaker;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.createdAt,
    this.speaker,
  });

  /// Converts this message into a backend-friendly JSON payload.
  ///
  /// Returns a map with a normalized ISO-8601 timestamp field.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'speaker': speaker,
      'timestamp': createdAt.toIso8601String(),
    };
  }

  /// Builds a [ChatMessage] from server or local JSON data.
  ///
  /// Accepts either timestamp or legacy created_at keys and falls back to
  /// [DateTime.now] if parsing fails so the UI can still render safely.
  ///
  /// Parameters:
  /// - [json]: Raw message map from API/WebSocket/local cache.
  ///
  /// Returns a normalized [ChatMessage] instance.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'] ?? json['created_at'];
    final timestamp = rawTimestamp is String
        ? DateTime.tryParse(rawTimestamp)
        : null;

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      type: (json['type'] ?? typeSpeech).toString(),
      speaker: json['speaker']?.toString(),
      createdAt: timestamp ?? DateTime.now(),
    );
  }
}
