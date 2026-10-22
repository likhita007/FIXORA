# Fixora - Flutter App (Part 6: App & Integration)

AI-powered repair assistant: take a photo of a fault, get an AI diagnosis, pass
a safety check, follow repair steps (with voice help) and verify the repair on
an ESP32 circuit.

## Flow

```
Splash -> Home -> Camera -> Diagnosis -> Safety -> Repair Guide -> (Verify on ESP32)
                  Home -> Voice assistant | Device (ESP32) | History
```

## Project structure

```
flutter_app/
├── lib/
│   ├── main.dart                  App entry, theme, Firebase init
│   ├── firebase_options.dart      Placeholder (replace with flutterfire configure)
│   ├── models/                    Diagnosis, SafetyResult, RepairSession
│   ├── screens/                   Splash, Home, Camera, Diagnosis, Safety,
│   │                              RepairGuide, Voice, Device, History
│   ├── services/                  AI, Safety, Voice, ESP32, Firebase
│   ├── widgets/                   StatusCard, LoadingView, ErrorView
│   └── utils/app_constants.dart   Keys, URLs, collection names
├── assets/images/
├── test/
├── pubspec.yaml
└── README.md
```

## Setup (first time)

1. Install Flutter (stable) and run `flutter doctor`.
2. This repo contains `lib/`, `test/`, `assets/` and `pubspec.yaml`. Generate the
   native `android/` and `ios/` folders inside this folder:
   ```
   flutter create . --project-name fixora --org com.fixora
   ```
   (Existing files are kept.)
3. `flutter pub get`
4. Add the native permissions below.
5. Run:
   ```
   flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=ESP32_HOST=192.168.4.1
   ```
   Without `GEMINI_API_KEY` the app runs in **demo mode** with a sample diagnosis,
   so UI work never gets blocked by other modules.

### Android - `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<queries>
  <intent>
    <action android:name="android.speech.RecognitionService"/>
  </intent>
</queries>
```
On the `<application ...>` tag add `android:usesCleartextTraffic="true"` (the ESP32
speaks plain HTTP).

In `android/app/build.gradle(.kts)` set `minSdk` to **23** (Firebase + camera).

### iOS - `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key><string>Fixora needs the camera to scan faults.</string>
<key>NSMicrophoneUsageDescription</key><string>Fixora uses the microphone for voice help.</string>
<key>NSSpeechRecognitionUsageDescription</key><string>Fixora converts your speech to text.</string>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
```

## Firebase (Backend teammate)

```
dart pub global activate flutterfire_cli
flutterfire configure
```
This overwrites `lib/firebase_options.dart`. Until then the app runs in
local-only mode (history is kept in memory). Sessions are stored in the
Firestore collection `repair_sessions` (see `RepairSession.toMap()`).

## Integration points with teammates

| Module | Owner file | What to swap in |
|---|---|---|
| AI Vision & Diagnosis | `services/ai_service.dart` | Final Gemini prompts (`_diagnosisPrompt`) |
| Voice Interaction | `services/voice_service.dart`, `screens/voice_screen.dart` | Conversation flow / follow-up questions |
| ESP32 & Hardware | `services/esp32_service.dart` | Must expose the endpoints below |
| Safety & Repair Logic | `services/safety_service.dart` | `classify()` and `repairStepsFor()` |
| Backend & Database | `services/firebase_service.dart` | Collection/field names, security rules |

### ESP32 endpoint contract (all `GET`, JSON)

| Endpoint | Response |
|---|---|
| `/status` | `{"switch":"ON","led":"OFF","fault":"none"}` |
| `/fault?type=led_open` | `{"ok":true}` (types: `led_open`, `switch_stuck`, `loose_wire`) |
| `/reset` | `{"ok":true}` |
| `/verify` | `{"repaired":true}` |

## Tests

```
flutter test
flutter analyze
```

## Upload to GitHub

```
git init
git add .
git commit -m "Fixora: Flutter app, integration layer"
git branch -M main
git remote add origin https://github.com/<your-user>/<repo>.git
git push -u origin main
```
Never commit API keys; pass them with `--dart-define`.
