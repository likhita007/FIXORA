import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import 'camera_screen.dart';
import 'device_screen.dart';
import 'history_screen.dart';
import 'voice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What needs fixing today?',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppConstants.tagline, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _HomeTile(
                      title: 'Scan fault',
                      subtitle: 'Take a photo',
                      icon: Icons.photo_camera,
                      color: const Color(0xFF1565C0),
                      onTap: () => _open(context, const CameraScreen()),
                    ),
                    _HomeTile(
                      title: 'Voice help',
                      subtitle: 'Ask Fixora',
                      icon: Icons.mic,
                      color: const Color(0xFF6A1B9A),
                      onTap: () => _open(context, const VoiceScreen()),
                    ),
                    _HomeTile(
                      title: 'Device',
                      subtitle: 'ESP32 circuit',
                      icon: Icons.memory,
                      color: const Color(0xFF00897B),
                      onTap: () => _open(context, const DeviceScreen()),
                    ),
                    _HomeTile(
                      title: 'History',
                      subtitle: 'Past repairs',
                      icon: Icons.history,
                      color: const Color(0xFFEF6C00),
                      onTap: () => _open(context, const HistoryScreen()),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(AppConstants.safetyDisclaimer,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 12),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
