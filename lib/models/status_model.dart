// lib/models/status_model.dart
class StatusModel {
  double temp;
  double hum;
  double emc;
  int rack;
  bool fan;
  int predicted; // minutes

  StatusModel({
    required this.temp,
    required this.hum,
    required this.emc,
    required this.rack,
    required this.fan,
    required this.predicted,
  });

  // New Factory to create a safe, initial/default model
  factory StatusModel.initial() {
    return StatusModel(
      temp: 0.0,
      hum: 0.0,
      emc: 0.0,
      rack: 0,
      fan: false,
      predicted: 0,
    );
  }

  factory StatusModel.fromPacket(String raw) {
    double _d(String key) {
      final m = RegExp("$key=(.*?);").firstMatch(raw);
      return double.tryParse(m?.group(1) ?? "0") ?? 0;
    }

    return StatusModel(
      temp: _d("T"),
      hum: _d("H"),
      emc: _d("EMC"),
      rack: _d("RACK").toInt(),
      fan: _d("FAN") == 1,
      predicted: _d("PRED").toInt(),
    );
  }
}