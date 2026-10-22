import 'package:flutter/material.dart';

import '../models/repair_session.dart';
import '../models/safety_result.dart';
import '../services/firebase_service.dart';
import 'repair_guide_screen.dart';

class SafetyScreen extends StatefulWidget {
  final RepairSession session;
  const SafetyScreen({super.key, required this.session});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _acknowledged = false;

  Future<void> _startRepair() async {
    final updated =
        widget.session.copyWith(status: RepairSession.statusInProgress);
    await FirebaseService.instance.saveSession(updated);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RepairGuideScreen(session: updated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safety = widget.session.safety!;
    final color = safety.level.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(safety.level.icon, size: 64, color: color),
                const SizedBox(height: 8),
                Text(
                  safety.level.label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(safety.summary, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Safety precautions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in safety.precautions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (safety.canProceed) ...[
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('I have read the precautions and power is disconnected.'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _acknowledged ? _startRepair : null,
              icon: const Icon(Icons.handyman),
              label: const Text('Start repair guide'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Repair guidance is disabled for dangerous faults. '
                'Please contact a qualified electrician.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text('Back to home'),
            ),
          ],
        ],
      ),
    );
  }
}
