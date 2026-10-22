import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../ai_vision/gemini_code/gemini_service.dart' as ai;
import '../models/diagnosis.dart';

/// Service connecting the Flutter UI to the FIXORA AI Vision & Diagnosis module.
class GeminiService {
  final ai.GeminiService _aiService;

  GeminiService({
    String? apiKey,
    http.Client? httpClient,
  }) : _aiService = ai.GeminiService(
          apiKey: apiKey,
          httpClient: httpClient,
          maxRetries: 2,
        );

  /// Analyzes raw circuit image bytes and maps to the Flutter app's Diagnosis model.
  Future<Diagnosis> diagnoseCircuit(Uint8List imageBytes) async {
    // Call the core AI Vision Gemini 3.8 Flash module
    final ai.DiagnosisResult result = await _aiService.analyzeCircuitImage(imageBytes);

    // Map AI Vision result to the Flutter app's Diagnosis domain model
    final String confidenceLabel = result.confidence >= 0.8
        ? 'High'
        : result.confidence >= 0.5
            ? 'Medium'
            : 'Low';

    final String safetyRiskLabel = result.status == 'UNKNOWN'
        ? 'Unknown / Obscured (Do not attempt unverified repair)'
        : result.faultDetected
            ? 'Low-Voltage Educational Setup (Turn off power before repairing)'
            : 'Low-Voltage (Normal Operation)';

    return Diagnosis(
      faultDetected: result.faultDetected,
      faultType: result.faultType == 'DISCONNECTED_WIRE'
          ? 'Disconnected / Loose Jumper Wire'
          : result.faultType,
      location: result.location,
      possibleCause: result.possibleCause,
      confidence: confidenceLabel,
      safetyRisk: safetyRiskLabel,
    );
  }

  /// Returns sample diagnostic data for development or offline testing.
  static Diagnosis getSampleDiagnosis({int scenarioIndex = 0}) {
    if (scenarioIndex == 1) {
      return Diagnosis(
        faultDetected: false,
        faultType: 'None',
        location: 'Circuit loop intact',
        possibleCause: 'All visible jumper wire connections appear properly seated.',
        confidence: 'High',
        safetyRisk: 'Low-Voltage (Normal Operation)',
      );
    } else if (scenarioIndex == 2) {
      return Diagnosis(
        faultDetected: false,
        faultType: 'Unknown',
        location: 'Unclear / Obscured',
        possibleCause: 'Image quality is insufficient to determine circuit continuity.',
        confidence: 'Low',
        safetyRisk: 'Unknown (Do not attempt unverified repair)',
      );
    }

    // Default: Primary Review scenario (Disconnected Jumper Wire)
    return Diagnosis(
      faultDetected: true,
      faultType: 'Disconnected / Loose Jumper Wire',
      location: 'Switch terminal to breadboard connection point',
      possibleCause: 'Incomplete circuit connection caused by an unseated jumper wire.',
      confidence: 'High',
      safetyRisk: 'Low-Voltage Educational Setup',
    );
  }
}
