import 'dart:io';

import 'package:flutter/material.dart';

import '../models/repair_session.dart';
import '../models/safety_result.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import '../services/safety_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_card.dart';
import 'safety_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  final String imagePath;
  const DiagnosisScreen({super.key, required this.imagePath});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _ai = AiService();
  final _safety = SafetyService();

  RepairSession? _session;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final diagnosis = await _ai.diagnoseImage(bytes);
      final safety = _safety.classify(diagnosis);
      final session = RepairSession(
        id: RepairSession.newId(),
        createdAt: DateTime.now(),
        imagePath: widget.imagePath,
        diagnosis: diagnosis,
        safety: safety,
        repairSteps: safety.canProceed ? _safety.repairStepsFor(diagnosis) : [],
      );
      await FirebaseService.instance.saveSession(session);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Diagnosis failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI diagnosis')),
      body: _loading
          ? const LoadingView(message: 'Analysing image...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _analyze)
              : _buildResult(context, _session!),
    );
  }

  Widget _buildResult(BuildContext context, RepairSession session) {
    final theme = Theme.of(context);
    final d = session.diagnosis;
    final risk = session.safety!.level;
    final percent = (d.confidence * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_ai.isMock)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Demo mode: no GEMINI_API_KEY set, so this is a sample result.',
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(widget.imagePath),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        StatusCard(
          title: 'Detected fault',
          value: d.faultName,
          icon: Icons.build,
          color: theme.colorScheme.primary,
          subtitle: 'Component: ${d.component}',
        ),
        StatusCard(
          title: 'Risk level',
          value: risk.label,
          icon: risk.icon,
          color: risk.color,
        ),
        const SizedBox(height: 8),
        Text('Confidence: $percent%', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: d.confidence, minHeight: 10),
        ),
        const SizedBox(height: 16),
        Text('What is wrong', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(d.description),
        if (d.possibleCauses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Possible causes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final cause in d.possibleCauses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(cause)),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SafetyScreen(session: session)),
          ),
          icon: const Icon(Icons.health_and_safety),
          label: const Text('Continue to safety check'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Retake photo'),
        ),
      ],
    );
  }
}
