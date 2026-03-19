/// Represents a participant in a captioning session.
///
/// The app starts with a human-friendly [name], then optionally binds that
/// profile to a backend diarization [speakerLabel] (for example, Speaker_1)
/// once identification is complete.
class SpeakerProfile {
  final String name;
  String? speakerLabel;
  bool isConfirmed;

  SpeakerProfile({
    required this.name,
    this.speakerLabel,
    this.isConfirmed = false,
  });

  /// Serializes this profile to the payload expected by the backend.
  ///
  /// Returns a map with the display name and current speaker label.
  Map<String, dynamic> toJson() => {
        'name': name,
        'label': speakerLabel,
      };
}
