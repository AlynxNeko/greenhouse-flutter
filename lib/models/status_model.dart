class StatusModel {
  double temp;
  double hum;
  double emc;
  int rack;
  bool fan;
  int predicted; 
  int rssi; // Tambahan
  double snr; // Tambahan
  int mode; // 0: Auto, 1: Semi, 2: Notify

  StatusModel({
    required this.temp,
    required this.hum,
    required this.emc,
    required this.rack,
    required this.fan,
    required this.predicted,
    required this.rssi,
    required this.snr,
    required this.mode,
  });

  // Default values are NaN to indicate "No Data"
  factory StatusModel.initial() {
    return StatusModel(
      temp: double.nan,
      hum: double.nan,
      emc: double.nan,
      rack: 0,
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
      // Handle NaN parsing if needed or default to 0
      return double.tryParse(m?.group(1) ?? "0") ?? 0.0;
    }
    
    // Khusus parsing data RSSI/SNR yang mungkin di akhir string tanpa titik koma penutup yang rapi
    int _rssi() {
      final m = RegExp("RSSI=(.*?)(;|\\s|\$)").firstMatch(raw);
      return int.tryParse(m?.group(1) ?? "0") ?? 0;
    }

    return StatusModel(
      temp: _d("T"),
      hum: _d("H"),
      emc: _d("EMC"),
      rack: _d("RACK").toInt(),
      fan: _d("FAN") == 1,
      predicted: _d("PRED").toInt(),
      mode: _d("MODE").toInt(),
      rssi: _rssi(),
      snr: _d("SNR"),
    );
  }
}