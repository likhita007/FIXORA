import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/repair_session.dart';
import '../models/safety_result.dart';
import '../services/firebase_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<RepairSession>> _future =
      FirebaseService.instance.fetchHistory();
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  Future<void> _reload() async {
    final next = FirebaseService.instance.fetchHistory();
    setState(() => _future = next);
    await next;
  }

  void _showDetails(RepairSession s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.diagnosis.faultName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${s.diagnosis.component} • ${_dateFormat.format(s.createdAt)}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(s.diagnosis.description),
                const SizedBox(height: 12),
                Text('Status: ${s.statusLabel}'),
                if (s.safety != null) Text('Risk: ${s.safety!.level.label}'),
                if (s.repairSteps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Repair steps', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (var i = 0; i < s.repairSteps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${i + 1}. ${s.repairSteps[i]}'),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repair history')),
      body: FutureBuilder<List<RepairSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading history...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Could not load history.',
              onRetry: _reload,
            );
          }
          final sessions = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: sessions.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('No repairs yet. Scan a fault to begin.')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      final risk = s.safety?.level;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (risk?.color ?? Colors.grey).withValues(alpha: 0.15),
                          child: Icon(risk?.icon ?? Icons.build,
                              color: risk?.color ?? Colors.grey),
                        ),
                        title: Text(s.diagnosis.faultName),
                        subtitle: Text(
                            '${_dateFormat.format(s.createdAt)} • ${s.statusLabel}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDetails(s),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
