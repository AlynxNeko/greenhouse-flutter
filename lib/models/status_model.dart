class StatusModel {
  final DateTime timestamp; 
  final double temp;
  final double hum;
  final double emc;
  final int rack;
  final double angle;
  final bool fan;
  final int predicted; 
  final int rssi;
  final double snr;
  final int mode;

  StatusModel({
    required this.timestamp,
    required this.temp,
    required this.hum,
    required this.emc,
    required this.rack,
    required this.angle,
    required this.fan,
    required this.predicted,
    required this.rssi,
    required this.snr,
    required this.mode,
  });

  factory StatusModel.initial() {
    return StatusModel(
      timestamp: DateTime.now(),
      temp: double.nan,
      hum: double.nan,
      emc: double.nan,
      rack: 0,
      angle: 0.0,
      fan: false,
      predicted: 0,
      rssi: 0,
      snr: 0.0,
      mode: 0,
    );
  }

  factory StatusModel.fromPacket(String raw) {
    double _d(String key) {
      final m = RegExp("$key=(.*?);").firstMatch(raw);
      return double.tryParse(m?.group(1) ?? "0") ?? 0.0;
    }
    
    int _rssi() {
      // Handles trailing semicolon OR end of string
      final m = RegExp("RSSI=(.*?)(;|\\s|\$)").firstMatch(raw);
      return int.tryParse(m?.group(1) ?? "0") ?? 0;
    }

    double _snr() {
      // UPDATED: Handles trailing semicolon OR end of string
      final m = RegExp("SNR=(.*?)(;|\\s|\$)").firstMatch(raw);
      return double.tryParse(m?.group(1) ?? "0") ?? 0.0;
    }

    return StatusModel(
      timestamp: DateTime.now(), 
      temp: _d("T"),
      hum: _d("H"),
      emc: _d("EMC"),
      rack: _d("RACK").toInt(),
      angle: _d("ANG"),
      fan: _d("FAN") == 1,
      predicted: _d("PRED").toInt(),
      mode: _d("MODE").toInt(),
      rssi: _rssi(),
      snr: _snr(), // Use the new safe parser
    );
  }

  // Helper for CSV
  List<dynamic> toList() {
    return [
      timestamp.toIso8601String(),
      temp, hum, emc, rack, fan ? 1 : 0, predicted, mode, rssi, snr
    ];
  }
}