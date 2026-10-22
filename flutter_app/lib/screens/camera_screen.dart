import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'diagnosis_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Circuit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 100,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Position the circuit inside the camera frame.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Connect to GeminiService to retrieve circuit diagnosis
                  final diagnosis = GeminiService.getSampleDiagnosis();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiagnosisScreen(diagnosis: diagnosis),
                    ),
                  );
                },
                icon: const Icon(Icons.camera),
                label: const Text('Capture & Diagnose'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
