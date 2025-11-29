import 'package:flutter/material.dart';

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
      final m = RegExp("RSSI=(.*?)(;|\\s|\$)").firstMatch(raw);
      return int.tryParse(m?.group(1) ?? "0") ?? 0;
    }

    double _snr() {
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
      snr: _snr(),
    );
  }

  // --- NEW: Parse from CSV Line ---
  factory StatusModel.fromCsv(String line) {
    try {
      final p = line.split(',');
      // CSV Format: Timestamp,Temp,Hum,EMC,Rack,Fan,Pred,Mode,RSSI,SNR
      if (p.length < 10) return StatusModel.initial();

      return StatusModel(
        timestamp: DateTime.parse(p[0]),
        temp: double.tryParse(p[1]) ?? 0.0,
        hum: double.tryParse(p[2]) ?? 0.0,
        emc: double.tryParse(p[3]) ?? 0.0,
        rack: int.tryParse(p[4]) ?? 0,
        angle: 0.0, // Angle isn't saved in CSV currently
        fan: p[5] == '1',
        predicted: int.tryParse(p[6]) ?? 0,
        mode: int.tryParse(p[7]) ?? 0,
        rssi: int.tryParse(p[8]) ?? 0,
        snr: double.tryParse(p[9]) ?? 0.0,
      );
    } catch (e) {
      debugPrint("Error parsing CSV line: $e");
      return StatusModel.initial();
    }
  }

  List<dynamic> toList() {
    return [
      timestamp.toIso8601String(),
      temp, hum, emc, rack, fan ? 1 : 0, predicted, mode, rssi, snr
    ];
  }
}