import 'package:flutter/material.dart';
import 'verification_screen.dart';

class RepairScreen extends StatelessWidget {
  const RepairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Guidance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Reconnect the loose jumper wire.',
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 16),

            const Text(
              'Re-insert the jumper pin into the detected '
              'connection point and ensure that the wire '
              'is firmly connected.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            const Text(
              'Important:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              'Keep the power disconnected while performing the repair.',
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(),
                    ),
                  );
                },
                child: const Text('Check Repair'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
