import 'package:flutter/material.dart';

import '../services/esp32_service.dart';
import '../utils/app_constants.dart';
import '../widgets/status_card.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _esp = Esp32Service.instance;
  late final TextEditingController _hostController =
      TextEditingController(text: _esp.host);

  Esp32Status? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    final host = _hostController.text.trim();
    if (host.isNotEmpty) _esp.host = host;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await _esp.getStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = null;
        _error = 'Cannot reach the ESP32 at ${_esp.host}. '
            'Check Wi-Fi and the address.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      _snack(successMessage);
      await _refresh();
    } catch (e) {
      _snack('Device command failed: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final ok = await _esp.verifyRepair();
      _snack(ok ? 'Circuit verified: repair successful!' : 'Fault still present.');
    } catch (e) {
      _snack('Verify failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 device'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hostController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'ESP32 address',
              hintText: AppConstants.esp32DefaultHost,
              prefixIcon: Icon(Icons.router),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _refresh(),
          ),
          const SizedBox(height: 8),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (s != null) ...[
            StatusCard(
              title: 'Switch',
              value: s.switchOn ? 'ON' : 'OFF',
              icon: Icons.toggle_on,
              color: s.switchOn ? Colors.green : Colors.grey,
            ),
            StatusCard(
              title: 'LED',
              value: s.ledOn ? 'ON' : 'OFF',
              icon: Icons.lightbulb,
              color: s.ledOn ? Colors.amber.shade800 : Colors.grey,
            ),
            StatusCard(
              title: 'Fault',
              value: s.hasFault
                  ? (AppConstants.esp32FaultTypes[s.fault] ?? s.fault)
                  : 'No fault',
              icon: s.hasFault ? Icons.error : Icons.check_circle,
              color: s.hasFault ? Colors.red : Colors.green,
            ),
          ],
          const SizedBox(height: 20),
          Text('Create a test fault', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in AppConstants.esp32FaultTypes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () => _esp.injectFault(entry.key),
                          '${entry.value} created',
                        ),
                icon: const Icon(Icons.bug_report),
                label: Text(entry.value),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _verify,
            icon: const Icon(Icons.verified),
            label: const Text('Verify repair'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(_esp.resetFaults, 'All faults cleared'),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset circuit'),
          ),
        ],
      ),
    );
  }
}
