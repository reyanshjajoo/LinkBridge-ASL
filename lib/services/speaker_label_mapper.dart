/// Maps raw diarization labels (e.g. 'Speaker_0') to human names.
class SpeakerLabelMapper {
  final Map<String, String> _map = {};

  /// Registers a mapping from backend speaker [label] to display [name].
  void registerLabel(String label, String name) {
    _map[label] = name;
  }

  /// Resolves a backend [label] to a user-facing name when available.
  ///
  /// Returns the original label if no mapping has been registered.
  String resolve(String label) {
    return _map[label] ?? label;
  }

  /// Returns a read-only snapshot of all known speaker mappings.
  Map<String, String> get registry => Map.unmodifiable(_map);
}
