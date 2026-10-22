import '../models/diagnosis.dart';
import '../models/safety_result.dart';

/// Risk classification + repair knowledge base.
///
/// Integration point with the "Safety & Repair Logic" teammate: this is a
/// working rule-based version. Replace [classify] / [repairStepsFor] (or the
/// keyword lists) with their final logic - the screens only depend on the
/// method signatures.
class SafetyService {
  static const List<String> _dangerKeywords = [
    'mains', '230', '220v', '110v', 'high voltage', 'capacitor', 'spark',
    'arcing', 'smoke', 'burn', 'fire', 'shock', 'exposed', 'short circuit',
    'overheat', 'melt', 'transformer', 'swollen', 'swelling', 'liquid',
    'water damage',
  ];

  static const List<String> _cautionKeywords = [
    'loose', 'wire', 'wiring', 'relay', 'fuse', 'solder', 'power supply',
    'adapter', 'connector', 'resistor', 'polarity', 'short',
  ];

  SafetyResult classify(Diagnosis d) {
    final text = _textOf(d);

    if (_matchesAny(text, _dangerKeywords)) {
      return const SafetyResult(
        level: RiskLevel.dangerous,
        summary:
            'This fault may involve high voltage, heat or fire risk. Do not '
            'attempt to repair it yourself.',
        precautions: [
          'Unplug the device or switch off the power at the mains if it is safe to reach.',
          'Do not touch exposed wires, burnt parts or swollen batteries.',
          'Keep children and pets away from the device.',
          'Contact a qualified electrician or the manufacturer.',
        ],
      );
    }

    if (_matchesAny(text, _cautionKeywords)) {
      return const SafetyResult(
        level: RiskLevel.caution,
        summary:
            'This looks repairable, but follow the precautions carefully '
            'before touching anything.',
        precautions: [
          'Disconnect all power (USB / battery / adapter) before touching the circuit.',
          'Work only on low-voltage circuits (5V or below).',
          'Keep the workspace dry and away from metal objects.',
          'Stop immediately if anything gets hot or smells burnt.',
        ],
      );
    }

    return const SafetyResult(
      level: RiskLevel.safe,
      summary: 'Low risk. A basic check should be enough to fix this.',
      precautions: [
        'Disconnect power before changing any connection.',
        'Handle components gently and avoid bending the legs.',
      ],
    );
  }

  /// Repair knowledge base: ordered, beginner friendly steps.
  List<String> repairStepsFor(Diagnosis d) {
    final text = _textOf(d);
    for (final entry in _knowledgeBase) {
      if (entry.keys.any((k) => RegExp(r'\b' + RegExp.escape(k)).hasMatch(text))) {
        return entry.steps;
      }
    }
    return _genericSteps;
  }

  // ---------------------------------------------------------------------

  String _textOf(Diagnosis d) => [
        d.faultName,
        d.component,
        d.description,
        ...d.possibleCauses,
      ].join(' ').toLowerCase();

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any(text.contains);

  static const List<_KbEntry> _knowledgeBase = [
    _KbEntry(
      keys: ['loose', 'wire', 'jumper', 'connection'],
      steps: [
        'Disconnect the USB cable or battery from the ESP32.',
        'Find the wire shown in the diagnosis and pull it out of the breadboard.',
        'Check the metal tip is straight and clean, then push it firmly back in.',
        'Gently tug each wire to confirm it is held tightly.',
        'Reconnect power and test the circuit.',
        'Use the Device screen to verify the repair.',
      ],
    ),
    _KbEntry(
      keys: ['led'],
      steps: [
        'Disconnect power from the ESP32.',
        'Check the LED direction: the longer leg (anode) goes towards the GPIO pin, the shorter leg to GND.',
        'Make sure a resistor (about 220 ohm) is in series with the LED.',
        'Re-seat the LED and its jumper wires on the breadboard.',
        'Reconnect power and press the switch.',
        'Use the Device screen to verify the LED turns on.',
      ],
    ),
    _KbEntry(
      keys: ['switch', 'button'],
      steps: [
        'Disconnect power from the ESP32.',
        'Check the switch is pressed into the breadboard on the correct pins.',
        'Look for a stuck or bent switch pin and straighten it carefully.',
        'Confirm one side goes to the GPIO pin and the other side to GND.',
        'Reconnect power and press the switch several times.',
        'Use the Device screen to verify the switch reading.',
      ],
    ),
    _KbEntry(
      keys: ['resistor'],
      steps: [
        'Disconnect power from the ESP32.',
        'Check the resistor is placed in series with the LED.',
        'Confirm the resistor value (red-red-brown is 220 ohm).',
        'Replace the resistor if it looks burnt or discoloured.',
        'Reconnect power and test the circuit.',
        'Use the Device screen to verify the repair.',
      ],
    ),
  ];

  static const List<String> _genericSteps = [
    'Disconnect all power from the device.',
    'Inspect the highlighted component for loose, bent or damaged parts.',
    'Re-seat every connection related to the faulty component.',
    'Reconnect power and test the device.',
    'If the fault remains, stop and ask a qualified technician.',
  ];
}

class _KbEntry {
  final List<String> keys;
  final List<String> steps;
  const _KbEntry({required this.keys, required this.steps});
}
