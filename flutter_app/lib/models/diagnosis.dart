class Diagnosis {
  final bool faultDetected;
  final String faultType;
  final String location;
  final String possibleCause;
  final String confidence;
  final String safetyRisk;

  Diagnosis({
    required this.faultDetected,
    required this.faultType,
    required this.location,
    required this.possibleCause,
    required this.confidence,
    required this.safetyRisk,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      faultDetected: json['fault_detected'] ?? false,
      faultType: json['fault_type'] ?? '',
      location: json['location'] ?? '',
      possibleCause: json['possible_cause'] ?? '',
      confidence: json['confidence'] ?? '',
      safetyRisk: json['safety_risk'] ?? '',
    );
  }
}
