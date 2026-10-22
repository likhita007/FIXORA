import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/repair_session.dart';
import '../utils/app_constants.dart';

/// Stores repair sessions. Integration point with the "Backend & Database"
/// teammate (collection name lives in AppConstants.sessionsCollection).
///
/// When Firebase is not configured the service silently keeps sessions in
/// memory so the whole app keeps working during development.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _enabled = false;
  bool get isEnabled => _enabled;

  final List<RepairSession> _local = [];

  /// Called from main() once Firebase.initializeApp succeeded.
  void enable() => _enabled = true;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(AppConstants.sessionsCollection);

  /// Creates or updates a session.
  Future<void> saveSession(RepairSession session) async {
    final i = _local.indexWhere((s) => s.id == session.id);
    if (i >= 0) {
      _local[i] = session;
    } else {
      _local.insert(0, session);
    }

    if (!_enabled) return;
    try {
      await _col
          .doc(session.id)
          .set(session.toMap())
          .timeout(AppConstants.networkTimeout);
    } catch (e) {
      debugPrint('Firestore save failed: $e');
    }
  }

  /// Most recent sessions first.
  Future<List<RepairSession>> fetchHistory() async {
    if (_enabled) {
      try {
        final snap = await _col
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get()
            .timeout(AppConstants.networkTimeout);
        return snap.docs
            .map((d) => RepairSession.fromMap(d.id, d.data()))
            .toList();
      } catch (e) {
        debugPrint('Firestore fetch failed, using local history: $e');
      }
    }
    final copy = List<RepairSession>.of(_local)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }
}
