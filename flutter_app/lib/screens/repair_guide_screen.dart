import 'package:flutter/material.dart';

import '../models/repair_session.dart';
import '../services/esp32_service.dart';
import '../services/firebase_service.dart';
import 'voice_screen.dart';

class RepairGuideScreen extends StatefulWidget {
  final RepairSession session;
  const RepairGuideScreen({super.key, required this.session});

  @override
  State<RepairGuideScreen> createState() => _RepairGuideScreenState();
}

class _RepairGuideScreenState extends State<RepairGuideScreen> {
  late final List<bool> _done =
      List<bool>.filled(widget.session.repairSteps.length, false);
  bool _verifying = false;

  int get _completed => _done.where((d) => d).length;
  bool get _allDone => _done.isNotEmpty && _completed == _done.length;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyWithDevice() async {
    setState(() => _verifying = true);
    try {
      final repaired = await Esp32Service.instance.verifyRepair();
      if (!mounted) return;
      if (repaired) {
        await _markRepaired();
      } else {
        _snack('The device still reports a fault. Recheck the steps.');
      }
    } catch (_) {
      _snack('Could not reach the ESP32. Check the Device screen, or mark as repaired manually.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _markRepaired() async {
    final updated = widget.session.copyWith(status: RepairSession.statusRepaired);
    await FirebaseService.instance.saveSession(updated);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Repair complete'),
        content: const Text('Great job! This repair has been saved to your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.session.repairSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair guide'),
        actions: [
          IconButton(
            tooltip: 'Ask Fixora',
            icon: const Icon(Icons.mic),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VoiceScreen(session: widget.session),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.session.diagnosis.faultName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: steps.isEmpty ? 0 : _completed / steps.length,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$_completed of ${steps.length} steps done',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: steps.isEmpty
                ? const Center(child: Text('No repair steps available.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: steps.length,
                    itemBuilder: (context, i) => CheckboxListTile(
                      value: _done[i],
                      onChanged: (v) => setState(() => _done[i] = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text('Step ${i + 1}',
                          style: theme.textTheme.labelLarge),
                      subtitle: Text(steps[i]),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: (_allDone && !_verifying) ? _verifyWithDevice : null,
                    icon: _verifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.memory),
                    label: const Text('Verify with device'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _allDone ? _markRepaired : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as repaired'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
