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
  final List<String> mData; // NEW: Holds the 8 moisture values

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
    required this.mData,
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
      mData: List.filled(8, "0.0"),
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
      final m = RegExp("SNR=(.*?)(;|\\s|\$)").firstMatch(raw);
      return double.tryParse(m?.group(1) ?? "0") ?? 0.0;
    }

    // Parse "M_DATA=15.1,15.2,..."
    List<String> _parseMData() {
      final m = RegExp("M_DATA=(.*?);").firstMatch(raw);
      if (m != null && m.group(1) != null) {
        return m.group(1)!.split(',');
      }
      return List.filled(8, "0.0"); // Fallback
    }

    return StatusModel(
      timestamp: DateTime.now(), 
      temp: _d("T"),
      hum: _d("H"),
      emc: _d("EMC"),
      rack: _d("RACK").toInt(),
      angle: _d("ANG"),
      // FIX: Inverted logic. Assuming FAN=0 means ON (Active Low)
      fan: _d("FAN") == 0, 
      predicted: _d("PRED").toInt(),
      mode: _d("MODE").toInt(),
      rssi: _rssi(),
      snr: _snr(),
      mData: _parseMData(),
    );
  }
}