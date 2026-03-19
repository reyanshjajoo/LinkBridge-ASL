/// Maps raw diarization labels (e.g. 'Speaker_0') to human names.
class SpeakerLabelMapper {
  final Map<String, String> _map = {};

  void registerLabel(String label, String name) {
    _map[label] = name;
  }

  String resolve(String label) {
    return _map[label] ?? label;
  }

  Map<String, String> get registry => Map.unmodifiable(_map);
}
