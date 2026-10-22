import 'package:flutter_test/flutter_test.dart';
import 'package:fixora/models/diagnosis.dart';
import 'package:fixora/models/safety_result.dart';
import 'package:fixora/services/safety_service.dart';

void main() {
  final service = SafetyService();

  test('mains / exposed wiring is classified as dangerous', () {
    const d = Diagnosis(
      faultName: 'Exposed mains cable',
      component: 'Power cord',
      description: 'Bare 230V wire is visible.',
      confidence: 0.9,
    );
    final result = service.classify(d);
    expect(result.level, RiskLevel.dangerous);
    expect(result.canProceed, isFalse);
  });

  test('loose wire is classified as caution', () {
    final result = service.classify(Diagnosis.demo());
    expect(result.level, RiskLevel.caution);
    expect(result.canProceed, isTrue);
  });

  test('plain LED fault is classified as safe', () {
    const d = Diagnosis(
      faultName: 'LED not glowing',
      component: 'LED',
      description: 'The LED does not light up when the switch is pressed.',
      confidence: 0.8,
    );
    expect(service.classify(d).level, RiskLevel.safe);
    expect(service.repairStepsFor(d), isNotEmpty);
  });

  test('Diagnosis JSON round trip keeps values', () {
    final original = Diagnosis.demo();
    final copy = Diagnosis.fromJson(original.toJson());
    expect(copy.faultName, original.faultName);
    expect(copy.confidence, original.confidence);
    expect(copy.possibleCauses, original.possibleCauses);
  });

  test('confidence given as percentage is normalised', () {
    final d = Diagnosis.fromJson({'faultName': 'x', 'confidence': 85});
    expect(d.confidence, closeTo(0.85, 0.0001));
  });
}
