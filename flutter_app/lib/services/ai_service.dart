import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/diagnosis.dart';
import '../utils/app_constants.dart';

/// One message in the voice / chat conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});
}

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);
  @override
  String toString() => message;
}

/// Talks to Gemini Vision. Integration point with the "AI Vision & Diagnosis"
/// teammate: replace the prompts below with their final versions.
///
/// If no GEMINI_API_KEY is provided the service runs in demo (mock) mode so
/// the rest of the app can still be built and tested.
class AiService {
  bool get isMock => AppConstants.geminiApiKey.isEmpty;

  static const String _diagnosisPrompt = '''
You are Fixora, an expert electronics and electrical repair assistant.
Look at the photo and identify the most likely fault.
Reply ONLY with JSON in exactly this shape:
{
  "faultName": "short fault title",
  "component": "the faulty component or area",
  "description": "1-2 sentence explanation a beginner understands",
  "confidence": 0.0 to 1.0,
  "possibleCauses": ["cause 1", "cause 2"]
}
If the image does not show a repairable device or circuit, set faultName to
"No fault detected" and confidence to 0.
''';

  /// Sends a camera image to Gemini Vision and returns the diagnosis.
  Future<Diagnosis> diagnoseImage(Uint8List imageBytes) async {
    if (isMock) {
      await Future.delayed(const Duration(seconds: 2));
      return Diagnosis.demo();
    }

    final body = {
      'contents': [
        {
          'parts': [
            {'text': _diagnosisPrompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      },
    };

    final text = await _generate(body);
    try {
      final decoded = jsonDecode(_stripFences(text));
      if (decoded is Map<String, dynamic>) {
        return Diagnosis.fromJson(decoded);
      }
    } catch (_) {
      // fall through to the error below
    }
    throw AiServiceException('Could not understand the AI response. Try again.');
  }

  /// Answers a spoken / typed follow-up question about the current repair.
  Future<String> chat({
    required String question,
    Diagnosis? context,
    List<ChatMessage> history = const [],
  }) async {
    if (isMock) {
      await Future.delayed(const Duration(seconds: 1));
      return 'Demo reply: add a GEMINI_API_KEY to get real answers. '
          'You asked: "$question".';
    }

    final system = StringBuffer(
      'You are Fixora, a friendly and safety-first repair assistant. '
      'Answer in at most three short sentences because your reply is read '
      'aloud. Always put safety first and tell the user to stop and call a '
      'qualified professional for anything involving mains voltage.',
    );
    if (context != null) {
      system.write(
        ' Current diagnosis: ${context.faultName} on ${context.component}. '
        '${context.description}',
      );
    }

    final contents = [
      for (final m in history)
        {
          'role': m.isUser ? 'user' : 'model',
          'parts': [
            {'text': m.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': system.toString()},
        ],
      },
      'contents': contents,
      'generationConfig': {'temperature': 0.5},
    };
    return (await _generate(body)).trim();
  }

  // ---------------------------------------------------------------------

  Future<String> _generate(Map<String, dynamic> body) async {
    final uri = Uri.parse(
      '${AppConstants.geminiEndpoint}/${AppConstants.geminiModel}:generateContent',
    );
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConstants.geminiApiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      throw AiServiceException(
        'AI request failed (error ${response.statusCode}). '
        'Check your API key and internet connection.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw AiServiceException('The AI returned no answer. Try again.');
    }
    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw AiServiceException('The AI returned an empty answer. Try again.');
    }
    return parts.map((p) => (p['text'] ?? '').toString()).join();
  }

  String _stripFences(String text) => text
      .replaceAll('```json', '')
      .replaceAll('```', '')
      .trim();
}
