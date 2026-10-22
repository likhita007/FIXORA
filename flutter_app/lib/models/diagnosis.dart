/// Result of the AI vision analysis (produced by [AiService]).
class Diagnosis {
  final String faultName;
  final String component;
  final String description;

  /// Confidence between 0.0 and 1.0.
  final double confidence;
  final List<String> possibleCauses;

  const Diagnosis({
    required this.faultName,
    required this.component,
    required this.description,
    required this.confidence,
    this.possibleCauses = const [],
  });

  /// Sample result used when no Gemini API key is configured (demo mode).
  factory Diagnosis.demo() => const Diagnosis(
        faultName: 'Loose jumper wire',
        component: 'Breadboard wiring',
        description:
            'The jumper wire feeding the LED is not making firm contact, so '
            'the circuit is open and the LED stays off.',
        confidence: 0.86,
        possibleCauses: [
          'Wire not fully inserted into the breadboard',
          'Worn breadboard contact',
        ],
      );

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      faultName:
          (json['faultName'] ?? json['fault_name'] ?? 'Unknown fault').toString(),
      component: (json['component'] ?? 'Unknown component').toString(),
      description: (json['description'] ?? '').toString(),
      confidence: _toConfidence(json['confidence']),
      possibleCauses: (json['possibleCauses'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'faultName': faultName,
        'component': component,
        'description': description,
        'confidence': confidence,
        'possibleCauses': possibleCauses,
      };

  static double _toConfidence(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    var d = parsed ?? 0.0;
    if (d > 1) d = d / 100; // accept 0-100 as well as 0-1
    return d.clamp(0.0, 1.0).toDouble();
  }
}
