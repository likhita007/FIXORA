# FIXORA — AI-Powered Home Repair Assistant

> **“SEE IT. UNDERSTAND IT. FIX IT SAFELY.”**

FIXORA is an AI-assisted diagnostic tool designed to help users identify visual wiring faults in low-voltage electrical circuits. By combining computer vision with structured diagnostic reasoning, FIXORA analyzes captured circuit images, localizes anomalies with bounding boxes, and returns actionable fault information to guide safe troubleshooting.

---

## 1. Project Overview

Diagnosing open, loose, or incorrectly routed connections in prototyping circuits often requires manual tracing and multimeters. FIXORA explores how multimodal Large Language Models (LLMs) with vision capabilities can assist in visual inspection.

The system takes an image of a low-voltage circuit (such as a solderless breadboard with jumper wires, switches, resistors, and LEDs), analyzes the visible wiring paths against component connection rules, localizes faults with normalized coordinates, and generates a structured diagnosis detailing the presence, type, location, and potential cause of any visible wiring fault.

---

## 2. Key Features

- **Multimodal Visual Inspection**: Analyzes circuit images using Google Gemini Vision (`gemini-3.8-flash`) to detect visible connection issues.
- **Visual Anomaly Localization**: Generates normalized bounding box coordinates (`[ymin, xmin, ymax, xmax]`) for camera UI highlighting.
- **Structured JSON Schema**: Enforces structured JSON output via API-level schema constraints (`response_mime_type: application/json`).
- **Validated Domain Model (`DiagnosisResult`)**: Sanitizes and validates model responses into a typed Dart object with bounded confidence values (`0.0` to `1.0`).
- **Network Resilience & Retry**: Automatic exponential backoff retry loop handling transient HTTP 429 rate limits and 503 errors.
- **Defensive Error & Fallback Handling**: Safely handles blurry or uninterpretable images (`UNKNOWN` status) and network timeouts/failures (`ERROR` status) without unhandled exceptions.
- **Header-Based REST Authentication**: Direct HTTP client integration using the official `x-goog-api-key` header.
- **Automated Test Suite**: Full unit tests covering models, parsing, coordinate normalization, and mock network states.
- **Secure Key Management**: Supports compile-time configuration via Flutter's `--dart-define=GEMINI_API_KEY=...` to keep API keys out of source code.

---

## 3. System Architecture

```
[ Client Application / Camera ]
               │
               ▼  (Uint8List image bytes)
[ GeminiService.analyzeCircuitImage() ]  ───► (Exponential Backoff Retry)
               │
               ▼  (HTTP POST with x-goog-api-key)
[ Google Gemini 3.8 Flash REST API ]
               │
               ▼  (application/json response with bounding_box)
[ JSON Extraction & Sanitization ]
               │
               ▼  (fromJson factory parsing)
[ DiagnosisResult Domain Model ]
               │
               ▼
[ UI Presentation & Visual Bounding Box Overlay ]
```

---

## 4. Technology Stack

- **Language / Framework**: Dart `^3.0.0` / Flutter SDK `^3.0.0`
- **Networking**: `http: ^1.2.0`
- **Testing**: `test: ^1.24.0`
- **AI Model**: Google Gemini (`gemini-3.8-flash`) via Google AI Studio REST API (`v1beta`)
- **Data Exchange**: JSON (`application/json`)

---

## 5. Project Modules

The repository contains the following core modules and tests:

### `ai_vision/` — AI Vision & Diagnosis Module
Provides the computer-vision diagnostic engine and data models:
- **[`gemini_service.dart`](ai_vision/gemini_service.dart)**: Contains `GeminiService`, `BoundingBox`, and `DiagnosisResult` domain data models with exponential backoff retries.
- **[`prompts.txt`](ai_vision/prompts.txt)**: Defines the system prompt, diagnostic instructions, operational boundaries, and JSON schema.
- **[`sample_diagnosis.json`](ai_vision/sample_diagnosis.json)**: Contains sample JSON payloads representing success (with bounding box), normal circuit, and unknown/blurry image states.
- **[`README.md`](ai_vision/README.md)**: Detailed module-level documentation and Flutter UI integration example with custom bounding box painter.

### `test/` — Automated Test Suite
- **[`ai_vision_test.dart`](test/ai_vision_test.dart)**: Unit tests for domain models, coordinate normalization, confidence clamping, mock API parsing, and HTTP 429 retry recovery.

---

## 6. How It Works

1. **Image Input**: The client application captures an image of a low-voltage circuit and passes the image as raw bytes (`Uint8List`) to `GeminiService.analyzeCircuitImage()`.
2. **Request Construction**: `GeminiService` prepares a multimodal request containing the diagnostic prompt and base64-encoded image data, configured with `response_mime_type: 'application/json'`.
3. **API Dispatch**: An HTTP POST request is sent to `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent` authenticated via the `x-goog-api-key` header with auto-retry on transient failures.
4. **Response Parsing**: The raw JSON payload returned by Gemini is extracted, sanitized, and parsed by `DiagnosisResult.fromJson()`.
5. **Contract Enforcement**: The parsed output adheres strictly to the contract:
   - `status`: Diagnostic outcome (`SUCCESS`, `UNKNOWN`, `ERROR`).
   - `fault_detected`: Boolean flag indicating if an electrical fault was identified.
   - `fault_type`: Standardized fault classification (`NONE`, `DISCONNECTED_WIRE`, `LOOSE_WIRE`, `WRONG_CONNECTION`, `UNKNOWN`).
   - `location`: Specific breadboard terminal, row, or component location.
   - `possible_cause`: Concise explanation of the identified condition.
   - `confidence`: Numeric confidence score clamped between `0.0` and `1.0`.
   - `bounding_box`: Normalized bounding box coordinates `{ymin, xmin, ymax, xmax}` for visual UI overlay.

---

## 7. Repository Structure

```text
FIXORA/
├── README.md
├── ai_vision/
│   ├── README.md
│   ├── gemini_service.dart
│   ├── prompts.txt
│   └── sample_diagnosis.json
└── test/
    └── ai_vision_test.dart
```

---

## 8. Setup and Installation

### Prerequisites
- Dart SDK `^3.0.0` or Flutter SDK `^3.0.0`
- A Google AI Studio API key for Gemini

### Dependency Configuration
Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0

dev_dependencies:
  test: ^1.24.0
```

Install dependencies:
```bash
flutter pub get
```

---

## 9. Configuration

The module retrieves the API key at compile time from the environment.

### Setting the API Key
Pass the API key using `--dart-define` when running or building your Flutter app:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

Alternatively, pass the key directly during instantiation in code:
```dart
final service = GeminiService(apiKey: 'your_actual_api_key_here');
```

> **Security Note**: Never commit actual API keys or credentials to version control.

---

## 10. Running the Project & Tests

### Running the Test Suite
```bash
dart test test/ai_vision_test.dart
```

### Basic Dart Usage Example

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'ai_vision/gemini_service.dart';

void main() async {
  final geminiService = GeminiService(maxRetries: 2);

  // Example: Pass image bytes from camera or file
  Uint8List sampleImageBytes = Uint8List(0); // Replace with actual image data

  final DiagnosisResult result = await geminiService.analyzeCircuitImage(sampleImageBytes);

  print('Diagnosis Status: ${result.status}');
  print('Fault Detected:   ${result.faultDetected}');
  print('Fault Type:       ${result.faultType}');
  print('Location:         ${result.location}');
  print('Possible Cause:   ${result.possibleCause}');
  print('Confidence:       ${(result.confidence * 100).toStringAsFixed(1)}%');
  if (result.boundingBox != null) {
    print('Bounding Box:     ${result.boundingBox}');
  }
}
```

---

## 11. Team / Contributions

Contributions and enhancements to FIXORA are welcome.

### How to Contribute
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -m "Add new feature"`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Open a Pull Request.

---

## 12. Safety / Limitations

- **Low-Voltage Scope**: The system is intended exclusively for low-voltage educational and prototyping circuits (DC 3.3V / 5V).
- **No Safety Guarantee**: Visual inspection through computer vision cannot guarantee electrical safety, verify component internal state, or replace physical measurement instruments (e.g., multimeters).
- **Mains Electricity Restriction**: Never use this system on high-voltage alternating current (AC) household mains wiring or live electrical panels. Doing so poses severe risks of electric shock, electrocution, and fire.

---

## 13. Future Improvements

Planned areas for future development include:
- **Mobile Camera UI Integration**: Real-time camera viewfinder with dynamic bounding box overlays for detected faults.
- **Hardware Loop Verification**: IoT microcontroller integration (e.g., ESP32 continuity sensing) to verify physical circuit restoration.
- **Extended Fault Types**: Support for multi-branch circuits, reversed polarity detection, and incorrect resistor values.
- **Offline Inference**: Exploring on-device lightweight vision models for connectivity-constrained environments.

---

## 14. License

This repository does not currently have an open-source license assigned. All rights are reserved by the project contributors. Contact the repository owner for permissions and usage inquiries.
