import 'diagnosis.dart';
import 'safety_result.dart';

/// One full diagnose -> safety -> repair run. Stored in Firebase / history.
class RepairSession {
  static const String statusDiagnosed = 'diagnosed';
  static const String statusInProgress = 'in_progress';
  static const String statusRepaired = 'repaired';

  final String id;
  final DateTime createdAt;
  final String? imagePath;
  final Diagnosis diagnosis;
  final SafetyResult? safety;
  final List<String> repairSteps;
  final String status;

  const RepairSession({
    required this.id,
    required this.createdAt,
    required this.diagnosis,
    this.imagePath,
    this.safety,
    this.repairSteps = const [],
    this.status = statusDiagnosed,
  });

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  String get statusLabel => switch (status) {
        statusInProgress => 'In progress',
        statusRepaired => 'Repaired',
        _ => 'Diagnosed',
      };

  RepairSession copyWith({
    SafetyResult? safety,
    List<String>? repairSteps,
    String? status,
  }) =>
      RepairSession(
        id: id,
        createdAt: createdAt,
        imagePath: imagePath,
        diagnosis: diagnosis,
        safety: safety ?? this.safety,
        repairSteps: repairSteps ?? this.repairSteps,
        status: status ?? this.status,
      );

  Map<String, dynamic> toMap() => {
        'createdAt': createdAt.toIso8601String(),
        'imagePath': imagePath,
        'diagnosis': diagnosis.toJson(),
        'safety': safety?.toJson(),
        'repairSteps': repairSteps,
        'status': status,
      };

  factory RepairSession.fromMap(String id, Map<String, dynamic> map) {
    final safetyMap = map['safety'];
    return RepairSession(
      id: id,
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      imagePath: map['imagePath'] as String?,
      diagnosis: Diagnosis.fromJson(
          Map<String, dynamic>.from(map['diagnosis'] as Map)),
      safety: safetyMap is Map
          ? SafetyResult.fromJson(Map<String, dynamic>.from(safetyMap))
          : null,
      repairSteps:
          (map['repairSteps'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      status: (map['status'] ?? statusDiagnosed).toString(),
    );
  }
}
