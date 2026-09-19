import 'package:flutter/material.dart';
import 'repair_screen.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield,
              size: 70,
            ),

            const SizedBox(height: 20),

            const Text(
              'Low-Voltage Safe for DIY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Before making any repair, disconnect the power '
              'and verify that the circuit is not energized.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            const Text(
              'Safety Precautions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '• Disconnect power before touching wiring.',
            ),

            const Text(
              '• Check the circuit before reconnecting.',
            ),

            const Text(
              '• Follow the repair instructions carefully.',
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RepairScreen(),
                    ),
                  );
                },
                child: const Text('Continue to Repair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
