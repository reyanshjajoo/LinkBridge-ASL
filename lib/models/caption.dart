/// Represents a single caption line produced by the captioning backend.
///
/// Fields:
/// - `text`: the transcribed caption text.
/// - `speaker`: human-readable speaker label.
/// - `receivedAt`: when the caption was received locally.
/// - `source`: origin channel (defaults to `speech`).
class Caption {
  final String text;
  final String speaker;
  final DateTime receivedAt;
  final String source;

  const Caption({
    required this.text,
    required this.speaker,
    required this.receivedAt,
    this.source = 'speech',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'speaker': speaker,
      'receivedAt': receivedAt.toIso8601String(),
      'source': source,
    };
  }

  factory Caption.fromJson(Map<String, dynamic> json) {
    return Caption(
      text: (json['text'] ?? '').toString(),
      speaker: (json['speaker'] ?? 'Unknown').toString(),
      receivedAt: DateTime.parse((json['receivedAt'] ?? '').toString()),
      source: (json['source'] ?? 'speech').toString(),
    );
  }
}
