import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/status_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<StatusModel> items = [];

  Future<void> add(StatusModel m) async {
    items.add(m);
    notifyListeners();
    await _appendToCsv(m);
  }

  Future<void> clear() async {
    items.clear();
    notifyListeners();
    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> exportToCSV() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      return "Logs saved to: ${file.path}";
    } else {
      return "No logs found to export.";
    }
  }

  Future<void> openCsvFile() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      await OpenFilex.open(file.path);
    }
  }

  // --- NEW: Load all logs from disk ---
  Future<List<StatusModel>> loadAllLogs() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];

      final lines = await file.readAsLines();
      if (lines.isEmpty) return [];

      List<StatusModel> loaded = [];
      // Start at index 1 to skip the CSV Header row
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        loaded.add(StatusModel.fromCsv(lines[i]));
      }
      
      // Return reversed so newest is at the top
      return loaded.reversed.toList();
    } catch (e) {
      debugPrint("Error loading logs: $e");
      return [];
    }
  }

  // --- Internal Helpers ---

  Future<String> get _localPath async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<File> _getLocalFile() async {
    final path = await _localPath;
    return File('$path/greenhouse_log.csv');
  }

  Future<void> _appendToCsv(StatusModel m) async {
    final file = await _getLocalFile();
    bool exists = await file.exists();
    
    if (!exists) {
      await file.writeAsString("Timestamp,Temp,Hum,EMC,Rack,Fan,Pred,Mode,RSSI,SNR\n");
    }

    String csvRow = "${m.timestamp.toIso8601String()},${m.temp},${m.hum},${m.emc},${m.rack},${m.fan?1:0},${m.predicted},${m.mode},${m.rssi},${m.snr}";
    
    await file.writeAsString("$csvRow\n", mode: FileMode.append);
  }
}