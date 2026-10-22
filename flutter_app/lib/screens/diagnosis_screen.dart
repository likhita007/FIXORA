import 'package:flutter/material.dart';
import '../models/diagnosis.dart';
import 'safety_screen.dart';

class DiagnosisScreen extends StatelessWidget {
  final Diagnosis? diagnosis;

  const DiagnosisScreen({super.key, this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final String faultTitle = (diagnosis != null && diagnosis!.faultType.isNotEmpty)
        ? diagnosis!.faultType
        : 'Disconnected / Loose Jumper Wire';

    final String faultLocation = (diagnosis != null && diagnosis!.location.isNotEmpty)
        ? diagnosis!.location
        : 'Detected connection point';

    final String faultCause = (diagnosis != null && diagnosis!.possibleCause.isNotEmpty)
        ? diagnosis!.possibleCause
        : 'Incomplete circuit connection';

    final String faultConfidence = (diagnosis != null && diagnosis!.confidence.isNotEmpty)
        ? diagnosis!.confidence
        : 'High';

    final String faultRisk = (diagnosis != null && diagnosis!.safetyRisk.isNotEmpty)
        ? diagnosis!.safetyRisk
        : 'Low-Voltage Educational Setup';

    final bool isFaultDetected = diagnosis?.faultDetected ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnosis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFaultDetected ? 'FAULT IDENTIFIED' : 'CIRCUIT NORMAL',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isFaultDetected ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faultTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text('Location: $faultLocation'),
                    const SizedBox(height: 6),

                    Text('Possible Cause: $faultCause'),
                    const SizedBox(height: 6),

                    Text('Confidence: $faultConfidence'),
                    const SizedBox(height: 6),

                    Text(
                      'Risk: $faultRisk',
                      style: TextStyle(
                        color: faultRisk.contains('High') || faultRisk.contains('Unknown')
                            ? Colors.red
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SafetyScreen(),
                    ),
                  );
                },
                child: const Text('Continue to Safety Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
