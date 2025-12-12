import 'package:flutter/material.dart';

class StatusModel {
  final DateTime timestamp; 
  final double temp;
  final double hum;
  final double emc;       // Equilibrium Moisture Content (Target)
  final double avgMoisture; // <-- NEW: Average of current rack moistures
  final int rack;
  final double angle;
  final bool fan;
  final int predicted; 
  final int rssi;
  final double snr;
  final int mode;
  final int alertCode;

  StatusModel({
    required this.timestamp,
    required this.temp,
    required this.hum,
    required this.emc,
    required this.avgMoisture, // <-- NEW
    required this.rack,
    required this.angle,
    required this.fan,
    required this.predicted,
    required this.rssi,
    required this.snr,
    required this.mode,
    required this.alertCode,
  });

  factory StatusModel.initial() {
    return StatusModel(
      timestamp: DateTime.now(),
      temp: double.nan,
      hum: double.nan,
      emc: double.nan,
      avgMoisture: 0.0, // Default
      rack: 0,
      angle: 0.0,
      fan: false,
      predicted: 0,
      rssi: 0,
      snr: 0.0,
      mode: 0,
      alertCode: 0,
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

    // --- Parse M_DATA for Average ---
    double _parseAvgMoisture() {
      try {
        final m = RegExp("M_DATA=(.*?)(;|\\s|\$)").firstMatch(raw);
        if (m != null && m.group(1) != null) {
          final parts = m.group(1)!.split(',');
          if (parts.isEmpty) return 0.0;
          
          double sum = 0.0;
          int count = 0;
          for (var p in parts) {
            double? val = double.tryParse(p);
            if (val != null) {
              sum += val;
              count++;
            }
          }
          return count > 0 ? sum / count : 0.0;
        }
      } catch (e) {
        debugPrint("Error parsing M_DATA: $e");
      }
      return 0.0;
    }

    return StatusModel(
      timestamp: DateTime.now(), 
      temp: _d("T"),
      hum: _d("H"),
      emc: _d("EMC"),
      avgMoisture: _parseAvgMoisture(), // <-- Calculate Average
      rack: _d("RACK").toInt(),
      angle: _d("ANG"),
      fan: _d("FAN") == 1,
      predicted: _d("PRED").toInt(),
      mode: _d("MODE").toInt(),
      alertCode: _d("ALERT").toInt(),
      rssi: _rssi(),
      snr: _snr(),
    );
  }

  // --- Parse from CSV Line ---
  factory StatusModel.fromCsv(String line) {
    try {
      final p = line.split(',');
      // Old CSV: 10 columns. New CSV: 12 columns (added Alert, AvgMoist)
      if (p.length < 10) return StatusModel.initial();

      return StatusModel(
        timestamp: DateTime.parse(p[0]),
        temp: double.tryParse(p[1]) ?? 0.0,
        hum: double.tryParse(p[2]) ?? 0.0,
        emc: double.tryParse(p[3]) ?? 0.0,
        rack: int.tryParse(p[4]) ?? 0,
        angle: 0.0, 
        fan: p[5] == '1',
        predicted: int.tryParse(p[6]) ?? 0,
        mode: int.tryParse(p[7]) ?? 0,
        rssi: int.tryParse(p[8]) ?? 0,
        snr: double.tryParse(p[9]) ?? 0.0,
        // Handle backward compatibility for old logs
        alertCode: (p.length > 10) ? (int.tryParse(p[10]) ?? 0) : 0,
        avgMoisture: (p.length > 11) ? (double.tryParse(p[11]) ?? 0.0) : 0.0,
      );
    } catch (e) {
      debugPrint("Error parsing CSV line: $e");
      return StatusModel.initial();
    }
  }

  List<dynamic> toList() {
    return [
      timestamp.toIso8601String(),
      temp, hum, emc, rack, fan ? 1 : 0, predicted, mode, rssi, snr, 
      alertCode, avgMoisture // <-- Append new field to CSV
    ];
  }
}