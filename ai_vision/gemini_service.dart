import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Represents the structured output from the FIXORA AI Vision module.
class DiagnosisResult {
  final String status;
  final bool faultDetected;
  final String faultType;
  final String location;
  final String possibleCause;
  final double confidence;

  /// Allowed status values.
  static const Set<String> allowedStatuses = {'SUCCESS', 'UNKNOWN', 'ERROR'};

  /// Allowed fault types.
  static const Set<String> allowedFaultTypes = {
    'NONE',
    'DISCONNECTED_WIRE',
    'LOOSE_WIRE',
    'WRONG_CONNECTION',
    'UNKNOWN',
  };

  DiagnosisResult({
    required this.status,
    required this.faultDetected,
    required this.faultType,
    required this.location,
    required this.possibleCause,
    required this.confidence,
  });

  /// Factory constructor to parse and validate Gemini's JSON payload.
  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    // 1. Parse and sanitize status
    String parsedStatus = (json['status'] as String? ?? 'UNKNOWN').trim().toUpperCase();
    if (!allowedStatuses.contains(parsedStatus)) {
      parsedStatus = 'UNKNOWN';
    }

    // 2. Parse and sanitize fault_type
    String parsedFaultType = (json['fault_type'] as String? ?? 'UNKNOWN').trim().toUpperCase();
    if (!allowedFaultTypes.contains(parsedFaultType)) {
      parsedFaultType = 'UNKNOWN';
    }

    // 3. Parse fault_detected boolean
    bool parsedFaultDetected = false;
    final rawFault = json['fault_detected'];
    if (rawFault is bool) {
      parsedFaultDetected = rawFault;
    } else if (rawFault is String) {
      parsedFaultDetected = rawFault.toLowerCase() == 'true';
    }

    // 4. Parse confidence (clamp between 0.0 and 1.0)
    double parsedConfidence = 0.0;
    final rawConf = json['confidence'];
    if (rawConf is num) {
      parsedConfidence = rawConf.toDouble().clamp(0.0, 1.0);
    }

    // 5. Parse location and possible_cause strings
    final parsedLocation = (json['location'] as String? ?? 'Not specified').trim();
    final parsedCause = (json['possible_cause'] as String? ?? 'No description provided').trim();

    // 6. Enforce state consistency rules
    if (parsedStatus == 'UNKNOWN' || parsedStatus == 'ERROR') {
      parsedFaultDetected = false;
      parsedFaultType = 'UNKNOWN';
    } else if (parsedStatus == 'SUCCESS' && !parsedFaultDetected) {
      parsedFaultType = 'NONE';
    }

    return DiagnosisResult(
      status: parsedStatus,
      faultDetected: parsedFaultDetected,
      faultType: parsedFaultType,
      location: parsedLocation,
      possibleCause: parsedCause,
      confidence: parsedConfidence,
    );
  }

  /// Converts the model back to the contract JSON map.
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'fault_detected': faultDetected,
      'fault_type': faultType,
      'location': location,
      'possible_cause': possibleCause,
      'confidence': confidence,
    };
  }

  /// Helper factory for returning an UNKNOWN image state.
  factory DiagnosisResult.unknown({String? cause, String? location}) {
    return DiagnosisResult(
      status: 'UNKNOWN',
      faultDetected: false,
      faultType: 'UNKNOWN',
      location: location ?? 'Unclear / Obscured',
      possibleCause: cause ?? 'Image quality is insufficient to determine circuit continuity.',
      confidence: 0.0,
    );
  }

  /// Helper factory for returning an ERROR state.
  factory DiagnosisResult.error({required String message}) {
    return DiagnosisResult(
      status: 'ERROR',
      faultDetected: false,
      faultType: 'UNKNOWN',
      location: 'System Error',
      possibleCause: message,
      confidence: 0.0,
    );
  }

  @override
  String toString() {
    return 'DiagnosisResult(status: $status, faultDetected: $faultDetected, faultType: $faultType, location: $location, confidence: $confidence)';
  }
}

/// Service providing Gemini Vision multimodal circuit analysis for FIXORA.
class GeminiService {
  final String apiKey;
  final String modelName;
  final http.Client _client;

  /// Default system prompt matching prompts.txt.
  static const String diagnosisPrompt = '''
You are FIXORA AI Vision, an expert diagnostic assistant specialized in analyzing low-voltage educational electrical circuits (ESP32, solderless breadboard, switch, 220-ohm resistor, 5V LED, and jumper wires).

Your task is to visually inspect the provided circuit image and identify if there is any visible wiring or connection fault.

### INSTRUCTIONS & OPERATIONAL BOUNDARIES:
1. Analyze ONLY the visible circuit components and wire paths in the provided image.
2. Determine whether a visible electrical fault exists in the low-voltage educational setup.
3. Identify the specific fault type, approximate component location, and brief possible cause.
4. If the image is blurry, too dark, poorly cropped, or does not clearly display the circuit terminals, return status "UNKNOWN".
5. Never hallucinate components or faults that are not visible.
6. Never diagnose high-voltage AC mains electrical systems. If an image contains mains AC wiring, return status "UNKNOWN" with a safety explanation.
7. Never guarantee electrical safety based solely on visual inspection.
8. Return ONLY a single valid JSON object. Do not output Markdown code fences, backticks, or any conversational text.

### ALLOWED VALUES:
- status: "SUCCESS" | "UNKNOWN" | "ERROR"
- fault_type: "NONE" | "DISCONNECTED_WIRE" | "LOOSE_WIRE" | "WRONG_CONNECTION" | "UNKNOWN"
- confidence: numeric float between 0.0 and 1.0

### EXACT JSON OUTPUT SCHEMA:
{
  "status": "SUCCESS",
  "fault_detected": true,
  "fault_type": "DISCONNECTED_WIRE",
  "location": "Jumper wire connection between switch and breadboard terminal",
  "possible_cause": "The jumper wire appears disconnected or unseated, resulting in an open circuit.",
  "confidence": 0.92
}
''';

  /// Constructs the GeminiService.
  /// 
  /// The [apiKey] defaults to compile-time environment variable `GEMINI_API_KEY`.
  /// Supports [modelName] defaulting to `gemini-3.8-flash`.
  GeminiService({
    String? apiKey,
    this.modelName = 'gemini-3.8-flash',
    http.Client? httpClient,
  })  : apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _client = httpClient ?? http.Client();

  /// Analyzes an image of a low-voltage electrical circuit.
  /// 
  /// Accepts [imageBytes] as [Uint8List] from Flutter's camera controller or file picker.
  /// Returns a validated [DiagnosisResult] object. Never throws unhandled exceptions.
  Future<DiagnosisResult> analyzeCircuitImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    // 1. Validate image payload
    if (imageBytes.isEmpty) {
      return DiagnosisResult.error(message: 'Image byte array is empty.');
    }

    // 2. Validate API key presence
    if (apiKey.isEmpty) {
      return DiagnosisResult.error(
        message: 'GEMINI_API_KEY is not configured. Provide it via constructor or --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    try {
      // 3. Build official Gemini v1beta multimodal REST endpoint URI
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent',
      );

      // 4. Construct payload with inline base64 image and JSON generation config
      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': diagnosisPrompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(imageBytes),
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'response_mime_type': 'application/json',
          'temperature': 0.1,
        }
      });

      // 5. Dispatch POST request with timeout
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 25));

      // 6. Handle HTTP response status
      if (response.statusCode != 200) {
        return DiagnosisResult.error(
          message: 'Gemini API Error [HTTP ${response.statusCode}]: ${response.body}',
        );
      }

      // 7. Extract candidate text payload
      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return DiagnosisResult.unknown(
          cause: 'No response candidate returned by Gemini. Image may have been blocked by safety filters.',
        );
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return DiagnosisResult.unknown(cause: 'Empty response text parts from Gemini.');
      }

      final rawText = (parts[0]['text'] as String? ?? '').trim();
      if (rawText.isEmpty) {
        return DiagnosisResult.unknown(cause: 'Empty text returned in Gemini response.');
      }

      // 8. Extract clean JSON substring and parse
      final cleanedJson = _extractJsonString(rawText);
      final Map<String, dynamic> jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // 9. Return validated domain model
      return DiagnosisResult.fromJson(jsonMap);
    } on TimeoutException {
      return DiagnosisResult.error(message: 'Request timed out while contacting Gemini Vision API.');
    } on FormatException catch (e) {
      return DiagnosisResult.unknown(cause: 'Failed to parse AI output into JSON: ${e.message}');
    } catch (e) {
      return DiagnosisResult.error(message: 'Unexpected network/processing error: $e');
    }
  }

  /// Utility to extract pure JSON from potential Markdown formatting or wrapping text.
  String _extractJsonString(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return cleaned.substring(startIndex, endIndex + 1);
    }
    return cleaned;
  }
}
