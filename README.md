# FIXORA

**AI-Powered Home Repair Assistant – Flutter App, AI, ESP32 and Backend Integration**

> *“SEE IT. UNDERSTAND IT. FIX IT SAFELY.”*

---

## Overview

FIXORA is an AI-powered home repair assistant designed to guide users through diagnosing and resolving household and electrical faults safely. It combines multimodal computer vision, automated safety checks, guided step-by-step repair instructions, and IoT hardware continuity verification.

---

## Project Structure

`	ext
FIXORA/
├── README.md              # Project overview & architecture documentation
└── ai_vision/             # AI Vision & Circuit Diagnosis module
    ├── README.md          # Module documentation & integration guide
    ├── sample_diagnosis.json # Sample JSON contract payloads
    ├── gemini_service.dart   # Dart service & domain model (Gemini REST API)
    └── prompts.txt        # Diagnostic system prompt & schema
`

---

## Modules

*   **[i_vision/](ai_vision/)**: Computer-vision-based circuit fault detection using Google Gemini (gemini-3.8-flash) multimodal REST API with x-goog-api-key header authentication.
*   **Flutter Mobile Application**: User interface for camera capture, diagnostic display, and interactive repair guidance.
*   **Safety & Risk Classification Engine**: DIY vs. Professional lockout decision matrix and safety checklists.
*   **ESP32 Hardware Testbed**: Digital continuity sensing and physical repair state verification.