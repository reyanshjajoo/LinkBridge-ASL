class SpeakerProfile {
  final String name;
  String? speakerLabel;
  bool isConfirmed;

  SpeakerProfile({
    required this.name,
    this.speakerLabel,
    this.isConfirmed = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': speakerLabel,
      };
}
