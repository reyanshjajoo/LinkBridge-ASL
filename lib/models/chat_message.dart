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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'speaker': speaker,
      'timestamp': createdAt.toIso8601String(),
    };
  }

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
