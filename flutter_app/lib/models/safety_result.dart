import 'package:flutter/material.dart';

enum RiskLevel { safe, caution, dangerous }

extension RiskLevelX on RiskLevel {
  String get label => switch (this) {
        RiskLevel.safe => 'SAFE',
        RiskLevel.caution => 'CAUTION',
        RiskLevel.dangerous => 'DANGEROUS',
      };

  Color get color => switch (this) {
        RiskLevel.safe => const Color(0xFF2E7D32),
        RiskLevel.caution => const Color(0xFFEF6C00),
        RiskLevel.dangerous => const Color(0xFFC62828),
      };

  IconData get icon => switch (this) {
        RiskLevel.safe => Icons.verified_user,
        RiskLevel.caution => Icons.warning_amber_rounded,
        RiskLevel.dangerous => Icons.dangerous,
      };

  static RiskLevel parse(String? value) => RiskLevel.values.firstWhere(
        (l) => l.name == value,
        orElse: () => RiskLevel.caution,
      );
}

/// Result of the safety / risk classification (produced by [SafetyService]).
class SafetyResult {
  final RiskLevel level;
  final String summary;
  final List<String> precautions;

  const SafetyResult({
    required this.level,
    required this.summary,
    this.precautions = const [],
  });

  /// Repair guidance is only allowed when the fault is not dangerous.
  bool get canProceed => level != RiskLevel.dangerous;

  factory SafetyResult.fromJson(Map<String, dynamic> json) => SafetyResult(
        level: RiskLevelX.parse(json['level']?.toString()),
        summary: (json['summary'] ?? '').toString(),
        precautions:
            (json['precautions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'summary': summary,
        'precautions': precautions,
      };
}
