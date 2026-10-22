import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_constants.dart';

/// Live state reported by the ESP32.
class Esp32Status {
  final bool switchOn;
  final bool ledOn;

  /// 'none' when healthy, otherwise the active fault key.
  final String fault;

  const Esp32Status({
    required this.switchOn,
    required this.ledOn,
    required this.fault,
  });

  bool get hasFault => fault.isNotEmpty && fault.toLowerCase() != 'none';

  factory Esp32Status.fromJson(Map<String, dynamic> json) => Esp32Status(
        switchOn: _asBool(json['switch']),
        ledOn: _asBool(json['led']),
        fault: (json['fault'] ?? 'none').toString(),
      );

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    return const ['on', 'true', '1', 'high'].contains('$v'.toLowerCase());
  }
}

/// HTTP client for the ESP32 firmware (Hardware teammate).
///
/// Agreed endpoint contract (all GET, JSON responses):
///   /status            -> {"switch":"ON","led":"OFF","fault":"none"}
///   /fault?type=<key>  -> {"ok":true}   (keys: see AppConstants.esp32FaultTypes)
///   /reset             -> {"ok":true}   (clears every fault)
///   /verify            -> {"repaired":true}
class Esp32Service {
  Esp32Service._();
  static final Esp32Service instance = Esp32Service._();

  /// Host or host:port, e.g. "192.168.4.1" or "192.168.1.50:80".
  String host = AppConstants.esp32DefaultHost;

  Future<Esp32Status> getStatus() async =>
      Esp32Status.fromJson(await _getJson('/status'));

  Future<void> injectFault(String type) async {
    await _getJson('/fault', {'type': type});
  }

  Future<void> resetFaults() async {
    await _getJson('/reset');
  }

  /// Asks the ESP32 whether the circuit now works.
  Future<bool> verifyRepair() async {
    final json = await _getJson('/verify');
    final v = json['repaired'];
    return v == true || '$v'.toLowerCase() == 'true';
  }

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.http(host, path, query);
    final response = await http.get(uri).timeout(AppConstants.networkTimeout);
    if (response.statusCode != 200) {
      throw Exception('ESP32 responded with ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
