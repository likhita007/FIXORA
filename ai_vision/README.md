# FIXORA — AI Vision & Diagnosis Module

**Tagline:** *SEE IT. UNDERSTAND IT. FIX IT SAFELY.*  
**Project:** B.Tech Engineering Clinics — FIXORA (Review-II / Final Review)

---

## 1. Purpose

The **AI Vision & Diagnosis** module provides computer-vision-based fault identification for the FIXORA Home Repair Assistant. It takes camera image bytes captured by the Flutter mobile application, dispatches a multimodal diagnostic prompt to the **Google Gemini Vision API** (`gemini-3.8-flash`), and returns a validated, strongly typed `DiagnosisResult` object to guide user repair workflows.

The primary educational testbed scenario is a **low-voltage circuit** composed of an ESP32, solderless breadboard, manual toggle switch, 220Ω resistor, and 5V LED, where a **disconnected or loose jumper wire** is identified.

---

## 2. Architecture & Data Flow

```
Flutter Camera Viewfinder
         │
         ▼
Raw Image Bytes (Uint8List)
         │
         ▼
GeminiService.analyzeCircuitImage()
         │
         ▼
Google Gemini Multimodal REST API (v1beta / gemini-3.8-flash)
         │
         ▼
Structured JSON Response
         │
         ▼
DiagnosisResult Domain Model
         │
         ▼
Flutter Diagnosis Screen ───► Safety & Guidance Engine ───► ESP32 Hardware
```

---

## 3. Folder Structure

```
ai_vision/
├── README.md              # Complete developer documentation & integration guide
├── sample_diagnosis.json  # Valid JSON samples for all primary diagnostic states
├── gemini_service.dart    # Dart service & DiagnosisResult domain model
└── prompts.txt            # System prompt and JSON contract for Gemini Vision
```

---

## 4. JSON Contract

All Gemini Vision outputs conform to the following schema:

```json
{
  "status": "SUCCESS",
  "fault_detected": true,
  "fault_type": "DISCONNECTED_WIRE",
  "location": "Jumper wire connection between switch and breadboard",
  "possible_cause": "The jumper wire appears disconnected from the breadboard, creating an open circuit.",
  "confidence": 0.92
}
```

### Field Definitions & Allowed Values

| JSON Key | Dart Property | Type | Allowed Values / Description |
|---|---|---|---|
| `status` | `status` | `String` | `"SUCCESS"`, `"UNKNOWN"`, `"ERROR"` |
| `fault_detected` | `faultDetected` | `bool` | `true` if an open/faulty connection exists, `false` otherwise |
| `fault_type` | `faultType` | `String` | `"NONE"`, `"DISCONNECTED_WIRE"`, `"LOOSE_WIRE"`, `"WRONG_CONNECTION"`, `"UNKNOWN"` |
| `location` | `location` | `String` | Approximate breadboard row, terminal, or component location |
| `possible_cause` | `possibleCause` | `String` | Concise root-cause explanation for the diagnosis screen |
| `confidence` | `confidence` | `double` | Numeric score between `0.0` and `1.0` |

---

## 5. Sample Responses

### A. SUCCESS — Disconnected Wire Fault (Primary Review-II Scenario)
```json
{
  "status": "SUCCESS",
  "fault_detected": true,
  "fault_type": "DISCONNECTED_WIRE",
  "location": "Jumper wire connection between switch and breadboard",
  "possible_cause": "The jumper wire appears disconnected from the breadboard, creating an open circuit.",
  "confidence": 0.92
}
```

### B. SUCCESS — Normal Closed Circuit (No Fault)
```json
{
  "status": "SUCCESS",
  "fault_detected": false,
  "fault_type": "NONE",
  "location": "Circuit loop intact",
  "possible_cause": "All visible jumper wire connections between ESP32, switch, 220-ohm resistor, and LED appear properly seated with no visible open connection.",
  "confidence": 0.95
}
```

### C. UNKNOWN — Blurry or Obscured Image
```json
{
  "status": "UNKNOWN",
  "fault_detected": false,
  "fault_type": "UNKNOWN",
  "location": "Unclear / Obscured",
  "possible_cause": "The captured image is blurry, poorly illuminated, or does not clearly display the breadboard terminals.",
  "confidence": 0.0
}
```

---

## 6. Required Dependencies

The module uses the standard Flutter `http` client to interface directly with the official Gemini v1beta REST endpoint:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
```

Run in terminal:
```bash
flutter pub get
```

---

## 7. Supported Model

*   **`gemini-3.8-flash`** *(Default)*: Optimized for multimodal circuit analysis, fast latency, and supports structured JSON output using response_mime_type: application/json.

---

## 8. API Key Configuration

To keep your Google AI Studio API key secure and prevent accidental GitHub commits, configure the key using Flutter's compile-time `--dart-define` flag.

### Running with compile-time definition:
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
```

### Building release APK:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
```

In Dart, `GeminiService` automatically retrieves this key via:
```dart
const String.fromEnvironment('GEMINI_API_KEY')
```

---

## 9. Minimal Flutter Integration Example

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'ai_vision/gemini_service.dart';

class CircuitDiagnosisScreen extends StatefulWidget {
  final Uint8List capturedImageBytes;

  const CircuitDiagnosisScreen({super.key, required this.capturedImageBytes});

  @override
  State<CircuitDiagnosisScreen> createState() => _CircuitDiagnosisScreenState();
}

class _CircuitDiagnosisScreenState extends State<CircuitDiagnosisScreen> {
  final GeminiService _geminiService = GeminiService();
  DiagnosisResult? _diagnosisResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    // Call the AI Vision module
    final result = await _geminiService.analyzeCircuitImage(widget.capturedImageBytes);

    setState(() {
      _diagnosisResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing circuit with Gemini Vision...'),
            ],
          ),
        ),
      );
    }

    final res = _diagnosisResult!;

    return Scaffold(
      appBar: AppBar(title: const Text('FIXORA AI Diagnosis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${res.status}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: res.status == 'SUCCESS' ? Colors.green : Colors.orange,
              ),
            ),
            const Divider(),
            Text('Fault Detected: ${res.faultDetected ? "YES" : "NO"}'),
            Text('Fault Type: ${res.faultType}'),
            Text('Location: ${res.location}'),
            Text('Confidence: ${(res.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(res.possibleCause),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Navigate to next module in FIXORA pipeline
              },
              child: const Text('Proceed to Safety Checklist'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 10. Error & Edge Case Handling

1. **Empty / Corrupted Image**: Returns `DiagnosisResult.error(message: 'Image byte array is empty.')` immediately without calling the API.
2. **Missing API Key**: Returns an `ERROR` state advising developer to pass `--dart-define=GEMINI_API_KEY=...`.
3. **HTTP / Network Failures**: Evaluates HTTP status codes and handles timeout/connection exceptions, returning `DiagnosisResult.error(...)` to guarantee the Flutter app **never crashes**.
4. **Markdown / Malformed JSON**: The service isolates JSON `{ ... }` before decoding. If parsing fails, it safely falls back to `DiagnosisResult.unknown()`.
5. **Blurry / Unclear Image**: Gemini returns `status: "UNKNOWN"`, mapping `faultDetected = false` and `faultType = "UNKNOWN"`.

---

## 11. Safety Limitation Notice

> [!IMPORTANT]
> **Educational Prototype Only**:
> This AI Vision module performs visual pattern inspection on low-voltage educational circuits (DC 3.3V / 5V). Visual inspection alone **cannot certify electrical safety**. This module strictly excludes high-voltage household AC mains electricity.

---

## 12. Module Integration Boundaries

*   **AI Vision Module (This module)**: Inspects image frames, identifies visible open wire terminals, and outputs structured JSON / `DiagnosisResult`.
*   **Safety & Risk Module (Teammate)**: Receives `DiagnosisResult`, checks DIY safety classification, and triggers safety checklists or lockout warnings.
*   **ESP32 Hardware Module (Teammate)**: Senses digital pin continuity on the physical testbed to verify whether the repair was physically completed.
*   **Flutter Application (Main App)**: Coordinates camera frame capture, displays diagnosis and guidance screens, and listens to the ESP32 verification stream.
