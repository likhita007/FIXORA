import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around speech-to-text and text-to-speech.
/// Integration point with the "Voice Interaction" teammate.
class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;

  bool get isAvailable => _sttReady;
  bool get isListening => _stt.isListening;

  /// Returns true when speech recognition is available on this device.
  Future<bool> init({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _sttReady = await _stt.initialize(
      onStatus: onStatus,
      onError: (e) => onError?.call(e.errorMsg),
    );
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    return _sttReady;
  }

  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
  }) async {
    if (!_sttReady) return;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> stopListening() => _stt.stop();

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    await _stt.cancel();
    await _tts.stop();
  }
}
